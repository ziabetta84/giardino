import { test } from 'node:test'
import assert from 'node:assert/strict'
import { separaModello, messaggiOpenAI, richiestaOpenAI, creaFiltroPensiero, leggiStream, chiamaOpenAI } from './openai.js'
import { eseguiCiclo } from './ciclo.js'
import { costoRisposte } from './costi.js'
import { validaRichiesta } from './ingresso.js'

const flusso = (righe) => new ReadableStream({
  start(c) { for (const r of righe) c.enqueue(new TextEncoder().encode(r)); c.close() },
})
const sse = (...eventi) => eventi.map(e => `data: ${JSON.stringify(e)}\n\n`).concat('data: [DONE]\n\n')

test('separaModello: Claude senza prefisso, gli altri «fornitore:nome»', () => {
  assert.deepEqual(separaModello('claude-sonnet-5-5'), { fornitore: 'anthropic', nome: 'claude-sonnet-5-5' })
  assert.deepEqual(separaModello('ovh:qwen3.6-35b-a3b'), { fornitore: 'ovh', nome: 'qwen3.6-35b-a3b' })
})

test('messaggiOpenAI: un solo system in testa, foto come data URL, strumenti e risultati tradotti', () => {
  const out = messaggiOpenAI([{ type: 'text', text: 'REGOLE' }], [
    { role: 'user', content: [{ type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: 'QUJD' } }, { type: 'text', text: 'cos\'è?' }] },
    { role: 'assistant', content: 'Una rosa.' },
    { role: 'user', content: [{ type: 'text', text: 'e come la curo?' }] },
    { role: 'system', content: 'Oggi è il 23 novembre.' },
    { role: 'assistant', content: [{ type: 'thinking', thinking: 'x' }, { type: 'tool_use', id: 't1', name: 'meteo', input: {} }] },
    { role: 'user', content: [{ type: 'tool_result', tool_use_id: 't1', content: '{"pioggia":0}' }, { type: 'tool_result', tool_use_id: 't2', content: 'no', is_error: true }] },
  ])
  assert.deepEqual(out[0], { role: 'system', content: 'REGOLE\n\nOggi è il 23 novembre.' })
  assert.equal(out.filter(m => m.role === 'system').length, 1)
  assert.deepEqual(out[1].content[0], { type: 'image_url', image_url: { url: 'data:image/jpeg;base64,QUJD' } })
  assert.deepEqual(out[2], { role: 'assistant', content: 'Una rosa.' })
  assert.equal(out[3].content, 'e come la curo?')
  assert.deepEqual(out[4], { role: 'assistant', content: null, tool_calls: [{ id: 't1', type: 'function', function: { name: 'meteo', arguments: '{}' } }] })
  assert.deepEqual(out[5], { role: 'tool', tool_call_id: 't1', content: '{"pioggia":0}' })
  assert.deepEqual(out[6], { role: 'tool', tool_call_id: 't2', content: 'ERRORE: no' })
  assert.equal(out.length, 7)
})

test('richiestaOpenAI: nome senza prefisso, strumenti come function, tool_choice none, niente parametri solo Anthropic', () => {
  const c = richiestaOpenAI({ model: 'ovh:qwen3.6-35b-a3b', max_tokens: 8000, thinking: { type: 'adaptive' }, cache_control: {}, fallbacks: 'default',
    system: [{ type: 'text', text: 'R' }], messages: [{ role: 'user', content: 'ciao' }], tool_choice: { type: 'none' },
    tools: [{ name: 'meteo', strict: true, description: 'Meteo', input_schema: { type: 'object', properties: {} } }] })
  assert.equal(c.model, 'qwen3.6-35b-a3b')
  assert.deepEqual(c.tools, [{ type: 'function', function: { name: 'meteo', description: 'Meteo', parameters: { type: 'object', properties: {} } } }])
  assert.equal(c.tool_choice, 'none')
  assert.equal(c.stream, true)
  for (const k of ['thinking', 'cache_control', 'fallbacks', 'system']) assert.equal(k in c, false)
})

test('filtro del ragionamento: toglie <think>…</think> anche spezzato tra pezzi', () => {
  const f = creaFiltroPensiero()
  const pezzi = ['<thi', 'nk>penso', ' ancora</th', 'ink>\nCiao ', 'Roberta <', 'b>!']
  assert.equal(pezzi.map(p => f(p)).join('') + f('', true), '\nCiao Roberta <b>!')
})

test('leggiStream: testo a pezzi, uso dei token, fine normale', async () => {
  const visti = []
  const msg = await leggiStream(flusso(sse(
    { choices: [{ delta: { content: 'Ciao ' } }] },
    { choices: [{ delta: { content: 'Roberta' }, finish_reason: 'stop' }] },
    { choices: [], usage: { prompt_tokens: 1000, completion_tokens: 50, prompt_tokens_details: { cached_tokens: 400 } } },
  )), { modello: 'ovh:qwen3.6-35b-a3b', onTesto: t => visti.push(t) })
  assert.deepEqual(visti, ['Ciao ', 'Roberta'])
  assert.deepEqual(msg.content, [{ type: 'text', text: 'Ciao Roberta' }])
  assert.equal(msg.stop_reason, 'end_turn')
  assert.deepEqual(msg.usage, { input_tokens: 600, output_tokens: 50, cache_read_input_tokens: 400, cache_creation_input_tokens: 0 })
})

test('leggiStream: chiamate a strumenti a pezzi, anche con finish_reason stop', async () => {
  const msg = await leggiStream(flusso([
    ...sse(
      { choices: [{ delta: { tool_calls: [{ index: 0, id: 'c1', function: { name: 'pianta', arguments: '{"id":' } }] } }] },
      { choices: [{ delta: { tool_calls: [{ index: 0, function: { arguments: '"rosa-1"}' } }, { index: 1, id: 'c2', function: { name: 'meteo', arguments: '' } }] } }] },
      { choices: [{ delta: {}, finish_reason: 'stop' }] },
    ),
  ]), { modello: 'ovh:x' })
  assert.equal(msg.stop_reason, 'tool_use')
  assert.deepEqual(msg.content, [
    { type: 'tool_use', id: 'c1', name: 'pianta', input: { id: 'rosa-1' } },
    { type: 'tool_use', id: 'c2', name: 'meteo', input: {} },
  ])
})

test('leggiStream: righe spezzate a metà, length → max_tokens, errore del fornitore', async () => {
  const testo = sse({ choices: [{ delta: { content: 'abc' }, finish_reason: 'length' }] }).join('')
  const msg = await leggiStream(flusso([testo.slice(0, 17), testo.slice(17)]), { modello: 'ovh:x' })
  assert.equal(msg.stop_reason, 'max_tokens')
  await assert.rejects(leggiStream(flusso(sse({ error: { message: 'quota' } })), { modello: 'ovh:x' }), /fornitore: quota/)
})

test('chiamaOpenAI: HTTP non riuscito diventa un errore leggibile', async () => {
  const fetch = async () => new Response('chiave non valida', { status: 401 })
  await assert.rejects(chiamaOpenAI({ url: 'https://x/v1/', chiave: 'k', params: { model: 'ovh:x', messages: [] }, fetch }), /HTTP 401 chiave non valida/)
})

test('ciclo completo con un fornitore OpenAI: strumento, poi risposta; costo al prezzo del modello', async () => {
  const chiamate = []
  const fetch = async (url, init) => {
    chiamate.push({ url, corpo: JSON.parse(init.body) })
    const eventi = chiamate.length === 1
      ? [{ choices: [{ delta: { tool_calls: [{ index: 0, id: 'c1', function: { name: 'meteo', arguments: '{}' } }] }, finish_reason: 'tool_calls' }] },
         { choices: [], usage: { prompt_tokens: 30000, completion_tokens: 100 } }]
      : [{ choices: [{ delta: { content: 'Domani piove: rimanda.' }, finish_reason: 'stop' }] },
         { choices: [], usage: { prompt_tokens: 31000, completion_tokens: 900 } }]
    return new Response(flusso(sse(...eventi)))
  }
  const risposte = []
  const esito = await eseguiCiclo({
    richiesta: { model: 'ovh:qwen3.6-35b-a3b', max_tokens: 8000, system: [{ type: 'text', text: 'R' }], tools: [{ name: 'meteo', description: '', input_schema: {} }],
      messages: [{ role: 'user', content: [{ type: 'text', text: 'annaffio?' }] }] },
    chiama: async (params, hooks) => { const m = await chiamaOpenAI({ url: 'https://x/v1', chiave: 'k', params, fetch, onTesto: hooks.onTesto }); risposte.push(m); return m },
    eseguiStrumento: async () => ({ contenuto: '{"pioggia_mm":12}' }),
    emetti: () => {},
  })
  assert.equal(esito.esito, 'completata')
  assert.equal(esito.testo, 'Domani piove: rimanda.')
  assert.equal(chiamate[0].url, 'https://x/v1/chat/completions')
  assert.deepEqual(chiamate[1].corpo.messages.at(-1), { role: 'tool', tool_call_id: 'c1', content: '{"pioggia_mm":12}' })
  const c = costoRisposte(risposte)
  assert.equal(c.modello, 'ovh:qwen3.6-35b-a3b')
  assert.equal(c.costo, Math.round((61000 * 0.2 + 1000 * 1.3) / 1e6 * 1e5) / 1e5)
})

test('validaRichiesta: modello in prova solo tra quelli ammessi', () => {
  const ok = validaRichiesta({ nuovo: { tipo: 'altro', modello: 'ovh:qwen3.6-35b-a3b' }, testo: 'ciao' })
  assert.equal(ok.valore.nuovo.modello, 'ovh:qwen3.6-35b-a3b')
  assert.equal(validaRichiesta({ nuovo: { tipo: 'altro', modello: 'gpt-9' }, testo: 'ciao' }).codice, 'richiesta_non_valida')
  assert.equal('modello' in validaRichiesta({ nuovo: { tipo: 'altro' }, testo: 'ciao' }).valore.nuovo, false)
})
