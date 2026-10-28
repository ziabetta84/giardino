// Carica i template di supabase/templates/ sul progetto Supabase reale con la
// Management API (le mail ospitate non leggono config.toml).
//   SUPABASE_ACCESS_TOKEN=sbp_... node scripts/mail/applica_template.mjs --prova
//   SUPABASE_ACCESS_TOKEN=sbp_... node scripts/mail/applica_template.mjs
// Il token personale si crea su https://supabase.com/dashboard/account/tokens e
// non va mai salvato nel repository. Prima di scrivere salva i template attuali
// in backups/ (git-ignorata); per tornare indietro: --ripristina backups/<file>.json
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const PROGETTO = 'ncuhhsvtjwcolhpdxbkt'
const radice = join(dirname(fileURLToPath(import.meta.url)), '../..')
const cartella = join(radice, 'supabase/templates')
const api = `https://api.supabase.com/v1/projects/${PROGETTO}/config/auth`

const token = process.env.SUPABASE_ACCESS_TOKEN
if (!token) {
  console.error('Manca SUPABASE_ACCESS_TOKEN (token personale da https://supabase.com/dashboard/account/tokens).')
  process.exit(1)
}
const intestazioni = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }
const prova = process.argv.includes('--prova')
const iRipristino = process.argv.indexOf('--ripristina')

async function chiama(metodo, corpo) {
  const r = await fetch(api, { method: metodo, headers: intestazioni, body: corpo && JSON.stringify(corpo) })
  if (!r.ok) throw new Error(`${metodo} ${r.status}: ${await r.text()}`)
  return r.json()
}

let modifiche
if (iRipristino > 0) {
  modifiche = JSON.parse(readFileSync(process.argv[iRipristino + 1], 'utf8'))
} else {
  const oggetti = JSON.parse(readFileSync(join(cartella, 'oggetti.json'), 'utf8'))
  modifiche = {}
  for (const [chiave, oggetto] of Object.entries(oggetti)) {
    modifiche[`mailer_subjects_${chiave}`] = oggetto
    modifiche[`mailer_templates_${chiave}_content`] = readFileSync(join(cartella, `${chiave}.html`), 'utf8')
  }
}

const attuale = await chiama('GET')
const diverse = Object.keys(modifiche).filter((k) => attuale[k] !== modifiche[k])
console.log(`Progetto ${PROGETTO}, Site URL attuale: ${attuale.site_url}`)
console.log(diverse.length ? `Da aggiornare:\n  ${diverse.join('\n  ')}` : 'Niente da aggiornare.')
if (prova || !diverse.length) process.exit(0)

mkdirSync(join(radice, 'backups'), { recursive: true })
const copia = join(radice, 'backups', `template_mail_${new Date().toISOString().replace(/[:.]/g, '-')}.json`)
writeFileSync(copia, JSON.stringify(Object.fromEntries(diverse.map((k) => [k, attuale[k]])), null, 2))
console.log(`Template attuali salvati in ${copia}`)

await chiama('PATCH', Object.fromEntries(diverse.map((k) => [k, modifiche[k]])))
console.log('Fatto.')
