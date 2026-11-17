// Minisito /scopri/: il sentiero che unisce le tappe e si disegna scorrendo,
// e le cure dimostrative che si possono segnare. Senza JavaScript la pagina
// resta completa: le pietre delle tappe si vedono comunque, manca solo la
// traccia che le unisce.

const giro = document.querySelector('.giro')
const svg = giro?.querySelector('.sentiero')
const traccia = svg?.querySelector('.sentiero__traccia')
const rivela = svg?.querySelector('.sentiero__rivela')
const fermo = window.matchMedia('(prefers-reduced-motion: reduce)')

let lunghezza = 0

function centro(el, base) {
  const r = el.getBoundingClientRect()
  return { x: r.left + r.width / 2 - base.left, y: r.top + r.height / 2 - base.top }
}

// Una curva morbida da una pietra all'altra: le maniglie verticali danno al
// sentiero l'andatura di chi cammina, non quella di una linea tecnica.
function disegna() {
  if (!giro || !svg) return
  const base = giro.getBoundingClientRect()
  const pietre = [...giro.querySelectorAll('.tappa__pietra')]
  if (pietre.length < 2) return
  const punti = pietre.map((p) => centro(p, base))
  // Prima del cancello il sentiero scende dritto lungo la sua colonna e
  // solo all'ultimo piega verso Zorba, senza tagliare il testo della tappa.
  if (punti.length > 2) {
    const ultimo = punti[punti.length - 1]
    const prima = punti[punti.length - 2]
    if (Math.abs(ultimo.x - prima.x) > 24) punti.splice(punti.length - 1, 0, { x: prima.x, y: ultimo.y - 56 })
  }
  const primo = { x: punti[0].x, y: 0 }
  let d = `M ${primo.x} ${primo.y}`
  let prima = primo
  for (const p of punti) {
    const dy = p.y - prima.y
    d += ` C ${prima.x} ${prima.y + dy * 0.55}, ${p.x} ${p.y - dy * 0.55}, ${p.x} ${p.y}`
    prima = p
  }
  svg.setAttribute('width', base.width)
  svg.setAttribute('height', base.height)
  svg.setAttribute('viewBox', `0 0 ${base.width} ${base.height}`)
  traccia.setAttribute('d', d)
  rivela.setAttribute('d', d)
  lunghezza = rivela.getTotalLength()
  rivela.style.strokeDasharray = `${lunghezza} ${lunghezza}`
  avanza()
}

// Il sentiero arriva fin dove sta guardando chi legge, un po' più avanti.
function avanza() {
  if (!lunghezza) return
  if (fermo.matches) { rivela.style.strokeDashoffset = '0'; return }
  const r = giro.getBoundingClientRect()
  const visto = window.innerHeight * 0.78 - r.top
  const quota = Math.min(1, Math.max(0, visto / r.height))
  rivela.style.strokeDashoffset = String(lunghezza * (1 - quota))
}

let attesa = 0
function alScorrere() {
  if (attesa) return
  attesa = requestAnimationFrame(() => { attesa = 0; avanza() })
}

if (giro && svg) {
  new ResizeObserver(() => disegna()).observe(giro)
  window.addEventListener('scroll', alScorrere, { passive: true })
  fermo.addEventListener?.('change', avanza)
  document.fonts?.ready.then(disegna)
}

// Le cure dimostrative: «Fatto» segna la cura come nell'app.
for (const bottone of document.querySelectorAll('.cura .fatto')) {
  const riga = bottone.closest('.cura')
  const cosa = riga.querySelector('.cura__cosa')
  const testo = cosa.textContent
  const tipo = testo.split(' · ')[0]
  bottone.setAttribute('aria-pressed', 'false')
  bottone.addEventListener('click', () => {
    const fatta = riga.classList.toggle('is-fatta')
    bottone.setAttribute('aria-pressed', String(fatta))
    bottone.textContent = fatta ? 'Segnata' : 'Fatto'
    cosa.textContent = fatta ? `${tipo} · registrata oggi` : testo
  })
}
