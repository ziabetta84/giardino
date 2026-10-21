import { test } from 'node:test'
import assert from 'node:assert/strict'
import { creaLettoreSSE } from './sse.js'

test('eventi spezzati tra più pezzi', () => {
  const visti = []
  const leggi = creaLettoreSSE((nome, dati) => visti.push([nome, dati]))
  leggi('event: testo\nda')
  leggi('ta: {"t":"Ciao"}\n\nevent: fine\ndata: {}\n')
  leggi('\n')
  assert.deepEqual(visti, [['testo', { t: 'Ciao' }], ['fine', {}]])
})

test('righe malformate ignorate', () => {
  const visti = []
  const leggi = creaLettoreSSE((nome, dati) => visti.push([nome, dati]))
  leggi('event: testo\ndata: {non json\n\n: commento\n\n')
  assert.deepEqual(visti, [])
})
