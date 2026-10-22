// Genera supabase/functions/zorba/regole/testi.js dai file .md delle regole (la fonte resta nei .md).
// Serve perché il deploy delle Edge Function non porta i file .md a runtime: la funzione importa i testi come modulo.
// Uso: node scripts/zorba/genera_regole.mjs (dopo ogni modifica a regole/*.md, prima del deploy; npm test lo controlla).
import { readFileSync, writeFileSync } from 'node:fs'
import { FILE_REGOLE } from '../../supabase/functions/zorba/lib/regole.js'

const cartella = new URL('../../supabase/functions/zorba/regole/', import.meta.url)
const testi = Object.fromEntries(FILE_REGOLE.map(f => [f, readFileSync(new URL(f, cartella), 'utf8')]))
writeFileSync(new URL('testi.js', cartella),
  `// Generato da scripts/zorba/genera_regole.mjs dai file .md accanto: non modificare a mano.\nexport const TESTI = ${JSON.stringify(testi, null, 2)}\n`)
console.log(`${FILE_REGOLE.length} file di regole scritti in regole/testi.js`)
