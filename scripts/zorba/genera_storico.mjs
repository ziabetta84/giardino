// Genera supabase/migrations/20261022110000_zorba_storico.sql da public/data/richieste-agente.json.
// Uso: node scripts/zorba/genera_storico.mjs "<id progetti esistenti separati da virgola>"
// Gli id dei progetti esistenti si leggono prima dal reale (MCP execute_sql: select string_agg(id::text, ',') from progetti).
import { readFileSync, writeFileSync } from 'node:fs'
import { sqlStorico } from './storico.js'

const OWNER = 'fc227422-ece8-4dca-b706-956ec7ca9e6e'
const progetti = new Set((process.argv[2] ?? '').split(',').filter(Boolean))
const voci = Object.entries(JSON.parse(readFileSync('public/data/richieste-agente.json', 'utf8')))
  .sort(([, a], [, b]) => a.creata.localeCompare(b.creata))
writeFileSync('supabase/migrations/20261022110000_zorba_storico.sql', sqlStorico(voci, OWNER, progetti))
console.log(`${voci.length} fili scritti`)
