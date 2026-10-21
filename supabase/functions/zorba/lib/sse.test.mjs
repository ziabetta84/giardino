import { test } from 'node:test'
import assert from 'node:assert/strict'
import { formattaEvento, creaEmettitore } from './sse.js'

test('formato SSE', () => {
  assert.equal(formattaEvento('testo', { t: 'a\nb' }), 'event: testo\ndata: {"t":"a\\nb"}\n\n')
})

test('dopo la disconnessione gli eventi si scartano senza errori', () => {
  let n = 0
  const controller = { enqueue() { n++; if (n > 1) throw new TypeError('stream closed') }, close() { throw new TypeError('closed') } }
  const e = creaEmettitore(controller)
  e.emetti('stato', { t: 'uno' })
  e.emetti('stato', { t: 'due' })
  e.emetti('stato', { t: 'tre' })
  assert.equal(e.connesso, false)
  assert.equal(n, 2)
  e.chiudi()
})
