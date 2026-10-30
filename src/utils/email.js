// Controlli leggeri sull'indirizzo email del modulo di registrazione e di
// accesso: formato plausibile e refusi nei domini più usati in Italia
// («gmial.com» → «gmail.com»). Solo un suggerimento: l'utente può sempre
// tenere quello che ha scritto (critica del 30/10/2026).

const DOMINI_COMUNI = [
  'gmail.com', 'libero.it', 'hotmail.it', 'hotmail.com', 'outlook.it', 'outlook.com',
  'live.it', 'live.com', 'yahoo.it', 'yahoo.com', 'icloud.com', 'me.com',
  'virgilio.it', 'alice.it', 'tim.it', 'tiscali.it', 'fastwebnet.it', 'email.it',
  'proton.me', 'protonmail.com', 'pm.me', 'aruba.it', 'pec.it',
  // Domini veri vicini a quelli sopra: senza, «tin.it» diventerebbe «tim.it».
  'tin.it', 'inwind.it', 'msn.com', 'ymail.com', 'gmx.it', 'gmx.com', 'katamail.com', 'mail.com',
]

export function emailValida(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(String(email ?? '').trim())
}

// Distanza di Damerau-Levenshtein ristretta (le lettere scambiate contano 1:
// «gmial» è un solo errore, non due).
function distanza(a, b) {
  const d = Array.from({ length: a.length + 1 }, (_, i) => [i, ...Array(b.length).fill(0)])
  for (let j = 1; j <= b.length; j++) d[0][j] = j
  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      const costo = a[i - 1] === b[j - 1] ? 0 : 1
      d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + costo)
      if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) {
        d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + 1)
      }
    }
  }
  return d[a.length][b.length]
}

// L'indirizzo corretto da proporre, o null se il dominio è già uno di quelli
// noti, è troppo diverso da tutti o l'indirizzo non è completo.
export function suggerisciEmail(email) {
  const testo = String(email ?? '').trim()
  const at = testo.lastIndexOf('@')
  if (at < 1) return null
  const dominio = testo.slice(at + 1).toLowerCase()
  if (dominio.length < 4 || DOMINI_COMUNI.includes(dominio)) return null
  let migliore = null
  let minima = Infinity
  for (const noto of DOMINI_COMUNI) {
    const dist = distanza(dominio, noto)
    if (dist < minima) { minima = dist; migliore = noto }
  }
  // Due errori sono il massimo credibile, e solo su domini non cortissimi:
  // «pm.me» a due lettere da «me.com» non è un refuso.
  const soglia = migliore.length >= 8 ? 2 : 1
  return minima > 0 && minima <= soglia ? testo.slice(0, at + 1) + migliore : null
}
