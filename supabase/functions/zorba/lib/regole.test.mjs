import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { componiSistema, FILE_REGOLE } from './regole.js'
import { riscontroPlantNet } from './plantnet.js'
import { TIPI } from './ingresso.js'

const leggi = (f) => readFileSync(new URL(`../regole/${f}`, import.meta.url), 'utf8')

test('il prompt contiene tono, ambito e una procedura per ogni tipo, senza istruzioni da terminale', () => {
  const procedure = Object.fromEntries(TIPI.map(t => [t, leggi(`${t}.md`)]))
  const s = componiSistema({ tono: leggi('tono.md'), ambito: leggi('ambito.md'), procedure })
  for (const t of TIPI) assert.match(s, new RegExp(`Procedura \`${t}\``))
  for (const vietato of ['execute_sql', 'apply_migration', 'richieste-agente.json', 'PlantNet', 'PLANTNET_API_KEY', 'commit', 'risposta.messaggio']) {
    assert.equal(s.includes(vietato), false, `il prompt contiene «${vietato}»`)
  }
  assert.deepEqual(FILE_REGOLE.sort(), ['ambito.md', 'tono.md', ...TIPI.map(t => `${t}.md`)].sort())
})

test('PlantNet: candidati sopra 0,2, nessuna fonte nominata, errori silenziosi', async () => {
  const fetchOk = async (url, opz) => {
    assert.match(url, /identify\/all/)
    assert.ok(opz.body instanceof FormData)
    return { ok: true, json: async () => ({ results: [
      { score: 0.62, species: { scientificNameWithoutAuthor: 'Allium sativum' } },
      { score: 0.1, species: { scientificNameWithoutAuthor: 'Allium cepa' } }] }) }
  }
  const t = await riscontroPlantNet({ tipo: 'identifica_specie', fotoBytes: new Uint8Array([1]), chiave: 'k', fetch: fetchOk })
  assert.equal(t, 'candidati: Allium sativum (62%)')
  assert.equal(await riscontroPlantNet({ tipo: 'identifica_specie', fotoBytes: new Uint8Array([1]), chiave: 'k', fetch: async () => { throw new Error('x') } }), null)
  const fetchMalattie = async (url) => {
    assert.match(url, /diseases\/identify/)
    return { ok: true, json: async () => ({ results: [{ name: 'PHYTIN', description: 'Peronospora', score: 0.4 }] }) }
  }
  assert.equal(await riscontroPlantNet({ tipo: 'diagnosi', fotoBytes: new Uint8Array([1]), chiave: 'k', fetch: fetchMalattie }), 'possibili problemi: Peronospora (40%)')
  assert.equal(await riscontroPlantNet({ tipo: 'altro', fotoBytes: new Uint8Array([1]), chiave: 'k', fetch: fetchOk }), null)
})
