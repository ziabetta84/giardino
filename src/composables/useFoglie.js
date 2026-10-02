import { watch, onUnmounted } from 'vue'

// "Vento d'autunno" per HeroAiuola.vue: foglie piatte nei colori della
// palette che cadono in diagonale verso destra (la direzione della luce nella
// tela autunno), su un canvas sovrapposto al dipinto. Ogni tanto una foglia
// "speciale" scende fino alla testa di Zorba, ci resta un istante (il
// chiamante gli fa scodinzolare la coda via onAtterra) e scivola via.
// Lavora in pixel CSS del riquadro: le velocità e i raggi scalano con
// l'altezza, così la striscia bassa della Home resta rada quanto lo splash.
const COLORI = [
  ['#cc6e6e', '#a85454'],
  ['#e0b84a', '#b8902c'],
  ['#9aaa5a', '#7a8a42'],
  ['#d98f5c', '#b06a3c'],
]
const CADE_MS = 5200
const RESTA_MS = 1600
const VIA_MS = 1100
const PRIMA_SPECIALE_MS = 2500
const PAUSA_SPECIALE_MS = 9000

const rnd = (a, b) => a + Math.random() * (b - a)

function disegnaFoglia(ctx, x, y, r, rot, col, alpha) {
  ctx.save()
  ctx.globalAlpha = alpha
  ctx.translate(x, y)
  ctx.rotate(rot)
  ctx.fillStyle = col[0]
  ctx.beginPath()
  ctx.moveTo(0, -r)
  ctx.quadraticCurveTo(r * 0.85, 0, 0, r)
  ctx.quadraticCurveTo(-r * 0.85, 0, 0, -r)
  ctx.fill()
  ctx.fillStyle = col[1]
  ctx.globalAlpha = alpha * 0.5
  ctx.beginPath()
  ctx.ellipse(r * 0.15, r * 0.25, r * 0.28, r * 0.5, 0, 0, 6.28)
  ctx.fill()
  ctx.restore()
}

// canvasEl: ref al <canvas>; attivo: ref booleano (false = fermo e pulito);
// dim: () => ({ w, h }) dimensioni CSS del riquadro; testa: () => ({ x, y }) | null
// punto d'atterraggio della foglia speciale, in pixel del riquadro.
export function useFoglie({ canvasEl, attivo, dim, testa, onAtterra }) {
  let raf = 0
  let ultimo = 0
  let t0 = 0
  let foglie = []
  let speciale = null
  let prossimaSpeciale = PRIMA_SPECIALE_MS
  let k = 1

  function nuova(p, iniziale, w, h) {
    p.x = iniziale ? rnd(-40, w * 0.85) : rnd(-60, w * 0.6)
    p.y = iniziale ? rnd(-20, h) : rnd(-60, -20) * k
    p.vx = rnd(14, 30) * k
    p.vy = rnd(26, 48) * k
    p.ph = rnd(0, 6.28)
    p.sw = rnd(0.9, 1.8)
    p.rot = rnd(0, 6.28)
    p.vr = rnd(-1.4, 1.4)
    p.r = rnd(6, 11) * k
    p.col = COLORI[(Math.random() * COLORI.length) | 0]
    return p
  }

  function ridimensiona() {
    const c = canvasEl.value
    if (!c) return null
    const { w, h } = dim()
    if (!w || !h) return null
    const dpr = Math.min(window.devicePixelRatio || 1, 2)
    if (c.width !== Math.round(w * dpr) || c.height !== Math.round(h * dpr)) {
      c.width = Math.round(w * dpr)
      c.height = Math.round(h * dpr)
    }
    const ctx = c.getContext('2d')
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    return { ctx, w, h }
  }

  function passo(ora) {
    raf = requestAnimationFrame(passo)
    const m = ridimensiona()
    if (!m) return
    const { ctx, w, h } = m
    const dt = Math.min(0.05, (ora - ultimo) / 1000)
    ultimo = ora
    const t = ora - t0
    k = Math.max(0.45, Math.min(1, h / 700))
    const n = Math.round(9 * k)
    while (foglie.length < n) foglie.push(nuova({}, true, w, h))
    foglie.length = n

    ctx.clearRect(0, 0, w, h)
    // Compaiono con la rivelazione della scena, non di colpo sopra lo schermo carta.
    const ingresso = Math.min(1, t / 1000)
    foglie.forEach((p) => {
      p.ph += dt * p.sw
      p.x += (p.vx + Math.sin(p.ph) * 22 * k) * dt
      p.y += p.vy * dt
      p.rot += p.vr * dt
      if (p.y > h + 30 || p.x > w + 30) nuova(p, false, w, h)
      disegnaFoglia(ctx, p.x, p.y, p.r, p.rot + Math.sin(p.ph) * 0.5, p.col, 0.95 * ingresso)
    })

    const hd = testa()
    if (!speciale && hd && t > prossimaSpeciale) {
      speciale = { inizio: ora, x0: w * rnd(0.43, 0.59), y0: -30 * k, atterrata: false }
    }
    if (!speciale) return
    const e = ora - speciale.inizio
    const r = 10 * k
    let x, y, rot, a = 1
    if (e < CADE_MS) {
      const q = e / CADE_MS
      const ease = 1 - Math.pow(1 - q, 2)
      x = speciale.x0 + (hd.x - speciale.x0) * ease + Math.sin((e / 1000) * 2.2) * 26 * k * (1 - q)
      y = speciale.y0 + (hd.y - speciale.y0) * q
      rot = Math.sin((e / 1000) * 2.2) * 0.9
    } else if (e < CADE_MS + RESTA_MS) {
      x = hd.x; y = hd.y; rot = 0.5
      if (!speciale.atterrata) { speciale.atterrata = true; onAtterra?.() }
    } else if (e < CADE_MS + RESTA_MS + VIA_MS) {
      const q = (e - CADE_MS - RESTA_MS) / VIA_MS
      x = hd.x + q * 26 * k; y = hd.y + q * q * 60 * k; rot = 0.5 + q * 1.6; a = 1 - q
    } else {
      speciale = null
      prossimaSpeciale = t + PAUSA_SPECIALE_MS
      return
    }
    disegnaFoglia(ctx, x, y, r, rot, COLORI[0], a)
  }

  function avvia() {
    if (raf) return
    foglie = []
    speciale = null
    prossimaSpeciale = PRIMA_SPECIALE_MS
    ultimo = t0 = performance.now()
    raf = requestAnimationFrame(passo)
  }
  function ferma() {
    cancelAnimationFrame(raf)
    raf = 0
    const c = canvasEl.value
    c?.getContext('2d')?.clearRect(0, 0, c.width, c.height)
  }

  watch(attivo, (v) => (v ? avvia() : ferma()), { immediate: true, flush: 'post' })
  onUnmounted(ferma)
}
