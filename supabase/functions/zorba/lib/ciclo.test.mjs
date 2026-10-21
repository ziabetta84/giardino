import { test } from 'node:test'
import assert from 'node:assert/strict'
import { eseguiCiclo } from './ciclo.js'

const testo = (t) => ({ type: 'text', text: t })
const uso = (id, name, input = {}) => ({ type: 'tool_use', id, name, input })
const msg = (stop_reason, content) => ({ stop_reason, content, model: 'claude-sonnet-5-5', usage: { input_tokens: 1, output_tokens: 1 } })

function chiamaDa(risposte) {
  const ricevute = []
  return { ricevute, chiama: async (params, hooks) => {
    ricevute.push(structuredClone(params))
    const r = risposte.shift()
    for (const b of r.content) if (b.type === 'text') hooks.onTesto(b.text)
    return r
  } }
}

test('strumento poi risposta: risultati in un solo messaggio utente, contenuto dell\'assistente intero', async () => {
  const { chiama, ricevute } = chiamaDa([
    msg('tool_use', [{ type: 'thinking', thinking: '', signature: 's' }, uso('u1', 'meteo'), uso('u2', 'progetti')]),
    msg('end_turn', [testo('Piove domani.')]),
  ])
  const eventi = []
  const r = await eseguiCiclo({ chiama, richiesta: { messages: [{ role: 'user', content: 'meteo?' }] },
    eseguiStrumento: async (n) => ({ contenuto: `{"da":"${n}"}`, errore: false }), emetti: (n, d) => eventi.push([n, d]) })
  assert.equal(r.esito, 'completata')
  assert.equal(r.testo, 'Piove domani.')
  const secondi = ricevute[1].messages
  assert.equal(secondi.at(-2).role, 'assistant')
  assert.equal(secondi.at(-2).content[0].type, 'thinking')
  assert.deepEqual(secondi.at(-1).content.map(b => b.tool_use_id), ['u1', 'u2'])
  assert.ok(eventi.some(([n]) => n === 'stato'))
  assert.deepEqual(r.strumenti, [{ nome: 'meteo', errore: false }, { nome: 'progetti', errore: false }])
})

test('testo prima di uno strumento: annullato nell\'interfaccia', async () => {
  const { chiama } = chiamaDa([msg('tool_use', [testo('Vediamo…'), uso('u1', 'meteo')]), msg('end_turn', [testo('Fatto.')])])
  const eventi = []
  await eseguiCiclo({ chiama, richiesta: { messages: [] }, eseguiStrumento: async () => ({ contenuto: '{}', errore: false }), emetti: (n) => eventi.push(n) })
  assert.ok(eventi.indexOf('annulla_testo') > eventi.indexOf('testo'))
})

test('all\'ultimo passaggio tool_choice none', async () => {
  const risposte = Array.from({ length: 3 }, (_, i) => msg('tool_use', [uso(`u${i}`, 'meteo')]))
  risposte.push(msg('end_turn', [testo('Basta così.')]))
  const { chiama, ricevute } = chiamaDa(risposte)
  const r = await eseguiCiclo({ chiama, richiesta: { messages: [] }, eseguiStrumento: async () => ({ contenuto: '{}', errore: false }), emetti: () => {}, maxPassaggi: 3 })
  assert.equal(ricevute[3].tool_choice.type, 'none')
  assert.equal(ricevute[2].tool_choice, undefined)
  assert.equal(r.testo, 'Basta così.')
})

test('pause_turn riprende, refusal e max_tokens sono errori', async () => {
  let c = chiamaDa([msg('pause_turn', [testo('…')]), msg('end_turn', [testo('ok')])])
  assert.equal((await eseguiCiclo({ chiama: c.chiama, richiesta: { messages: [] }, eseguiStrumento: null, emetti: () => {} })).testo, 'ok')
  c = chiamaDa([msg('refusal', [])])
  const rif = await eseguiCiclo({ chiama: c.chiama, richiesta: { messages: [] }, eseguiStrumento: null, emetti: () => {} })
  assert.deepEqual([rif.esito, rif.codice], ['errore', 'rifiuto'])
  c = chiamaDa([msg('max_tokens', [testo('tronc')])])
  assert.equal((await eseguiCiclo({ chiama: c.chiama, richiesta: { messages: [] }, eseguiStrumento: null, emetti: () => {} })).codice, 'troppo_lunga')
})

test('risposta finale vuota: errore', async () => {
  const c = chiamaDa([msg('end_turn', [])])
  assert.equal((await eseguiCiclo({ chiama: c.chiama, richiesta: { messages: [] }, eseguiStrumento: null, emetti: () => {} })).esito, 'errore')
})

test('pause_turn oltre maxPassaggi: errore', async () => {
  const risposte = Array.from({ length: 4 }, () => msg('pause_turn', [testo('…')]))
  const { chiama, ricevute } = chiamaDa(risposte)
  const r = await eseguiCiclo({ chiama, richiesta: { messages: [] }, eseguiStrumento: null, emetti: () => {}, maxPassaggi: 3 })
  assert.deepEqual([r.esito, r.codice], ['errore', 'interno'])
  assert.equal(ricevute.length, 4, 'deve fare al massimo 4 chiamate (passi 0-3)')
})

test('pause_turn vuota: errore', async () => {
  const c = chiamaDa([msg('pause_turn', [])])
  const r = await eseguiCiclo({ chiama: c.chiama, richiesta: { messages: [] }, eseguiStrumento: null, emetti: () => {} })
  assert.deepEqual([r.esito, r.codice], ['errore', 'interno'])
})

test('tool_use senza blocchi strumenti: errore', async () => {
  const c = chiamaDa([msg('tool_use', [testo('Vediamo…')])])
  const r = await eseguiCiclo({ chiama: c.chiama, richiesta: { messages: [] }, eseguiStrumento: null, emetti: () => {} })
  assert.deepEqual([r.esito, r.codice], ['errore', 'interno'])
})
