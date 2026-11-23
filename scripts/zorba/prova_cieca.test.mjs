import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, readFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { leggiRisposta, scriviPagina } from './prova_cieca.mjs'

const flusso = (testo) => new ReadableStream({ start(c) { c.enqueue(new TextEncoder().encode(testo.slice(0, 30))); c.enqueue(new TextEncoder().encode(testo.slice(30))); c.close() } })
const ev = (n, d) => `event: ${n}\ndata: ${JSON.stringify(d)}\n\n`

test('leggiRisposta: filo, testo dopo annulla_testo, fine', async () => {
  const e = await leggiRisposta(flusso(ev('filo', { id: 'f1' }) + ev('testo', { t: 'bozza' }) + ev('annulla_testo', {}) + ev('testo', { t: 'Ciao ' }) + ev('testo', { t: 'Roberta' }) + ev('fine', { rimaste: null })))
  assert.equal(e.filo, 'f1')
  assert.equal(e.testo, 'Ciao Roberta')
  assert.equal(e.errore, null)
})

test('leggiRisposta: errore', async () => {
  const e = await leggiRisposta(flusso(ev('filo', { id: 'f1' }) + ev('errore', { codice: 'interno', messaggio: 'no' })))
  assert.equal(e.errore, 'interno: no')
})

test('scriviPagina: pagina con tutte le risposte, senza nomi dei modelli in chiaro nell\'ordine', () => {
  const d = mkdtempSync(join(tmpdir(), 'pc-'))
  scriviPagina(d, { risposte: [
    { domanda: 0, tipo: 'altro', testo_domanda: 'Domanda </script>', con_foto: false, modello: 'predefinito', modello_effettivo: 'claude-sonnet-5-5', risposta: 'uno', secondi: 3, costo_usd: 0.05 },
    { domanda: 0, tipo: 'altro', testo_domanda: 'Domanda </script>', con_foto: false, modello: 'ovh:qwen3.6-35b-a3b', modello_effettivo: 'ovh:qwen3.6-35b-a3b', risposta: 'due', secondi: 4, costo_usd: 0.006 },
  ] })
  const html = readFileSync(join(d, 'pagina.html'), 'utf8')
  assert.match(html, /"uno"/)
  assert.match(html, /"due"/)
  assert.equal(html.includes('Domanda </script>'), false)
})
