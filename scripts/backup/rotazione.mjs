// Rotazione dei backup del database (scripts/backup-db.sh): quali file tenere e quali cancellare.
// Regole (pagina Privacy: le copie si distruggono entro 30 giorni):
//   - l'ultimo di ogni giorno degli ultimi 7 giorni;
//   - l'ultimo di ogni settimana degli ultimi 28 giorni;
//   - mai nulla oltre i 30 giorni; il più recente resta sempre, se non è più vecchio di così.
// Uso: node scripts/backup/rotazione.mjs CARTELLA  → stampa i percorsi da cancellare, uno per riga.
// Prove: node --test scripts/backup/rotazione.test.mjs
import { readdirSync } from 'node:fs'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

const NOME = /^giardino_zorba_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.sql(\.age)?$/
const GIORNO = 86400000

function data(nome) {
  const m = NOME.exec(nome)
  return m ? new Date(+m[1], m[2] - 1, +m[3], +m[4], +m[5], +m[6]) : null
}

// Lunedì della settimana, a mezzanotte: la chiave della settimana.
function settimana(d) {
  const l = new Date(d.getFullYear(), d.getMonth(), d.getDate())
  l.setDate(l.getDate() - ((l.getDay() + 6) % 7))
  return l.getTime()
}

export function daCancellare(nomi, adesso = new Date()) {
  const backup = nomi.map(nome => ({ nome, d: data(nome) })).filter(b => b.d)
    .sort((a, b) => b.d - a.d)
  const tenuti = new Set()
  const giorni = new Set()
  const settimane = new Set()
  for (const b of backup) {
    const eta = adesso - b.d
    if (eta > 30 * GIORNO) continue
    const g = b.d.toDateString()
    const s = settimana(b.d)
    if (tenuti.size === 0) tenuti.add(b.nome)
    if (eta <= 7 * GIORNO && !giorni.has(g)) tenuti.add(b.nome)
    if (eta <= 28 * GIORNO && !settimane.has(s)) tenuti.add(b.nome)
    giorni.add(g)
    settimane.add(s)
  }
  return backup.filter(b => !tenuti.has(b.nome)).map(b => b.nome)
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const cartella = process.argv[2]
  if (!cartella) { console.error('Uso: node scripts/backup/rotazione.mjs CARTELLA'); process.exit(1) }
  for (const nome of daCancellare(readdirSync(cartella))) console.log(join(cartella, nome))
}
