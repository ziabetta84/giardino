import { test } from 'node:test'
import assert from 'node:assert/strict'
import { payload, accessoRecente, blocchiFile, FINESTRA_SECONDI } from './accesso.js'

const jwt = (corpo) => `x.${Buffer.from(JSON.stringify(corpo)).toString('base64url')}.y`
const ADESSO = 1_800_000_000_000

test('payload legge il JWT e rifiuta i token malformati', () => {
  assert.deepEqual(payload(jwt({ sub: 'a', nome: 'Zorbà' })), { sub: 'a', nome: 'Zorbà' })
  assert.equal(payload('senza-punti'), null)
  assert.equal(payload('x.!!!.y'), null)
  assert.equal(payload(undefined), null)
})

test('accessoRecente vuole una password riscritta da poco', () => {
  const s = ADESSO / 1000
  assert.equal(accessoRecente({ amr: [{ method: 'password', timestamp: s - 30 }] }, ADESSO), true)
  assert.equal(accessoRecente({ amr: [{ method: 'password', timestamp: s - FINESTRA_SECONDI - 1 }] }, ADESSO), false)
  // un link di recupero o un token rinnovato non bastano
  assert.equal(accessoRecente({ amr: [{ method: 'otp', timestamp: s }] }, ADESSO), false)
  assert.equal(accessoRecente({ amr: [{ method: 'recovery', timestamp: s }, { method: 'password', timestamp: s - 86400 }] }, ADESSO), false)
  // un momento nel futuro è un token falsificato o un orologio sbagliato
  assert.equal(accessoRecente({ amr: [{ method: 'password', timestamp: s + 3600 }] }, ADESSO), false)
  assert.equal(accessoRecente({}, ADESSO), false)
  assert.equal(accessoRecente(null, ADESSO), false)
})

test('blocchiFile raggruppa per bucket e taglia a blocchi', () => {
  const righe = [
    { bucket: 'galleria', percorso: 'u/p/1.webp' }, { bucket: 'zorba-foto', percorso: 'u/f/m.jpg' },
    { bucket: 'galleria', percorso: 'u/p/2.webp' }, { bucket: 'galleria', percorso: 'u/p/3.webp' },
  ]
  assert.deepEqual(blocchiFile(righe, 2), [
    { bucket: 'galleria', percorsi: ['u/p/1.webp', 'u/p/2.webp'] },
    { bucket: 'galleria', percorsi: ['u/p/3.webp'] },
    { bucket: 'zorba-foto', percorsi: ['u/f/m.jpg'] },
  ])
  assert.deepEqual(blocchiFile([]), [])
  assert.deepEqual(blocchiFile(null), [])
})
