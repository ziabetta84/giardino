import { test } from 'node:test'
import assert from 'node:assert/strict'
import { pezziGrassetto } from './grassetto.js'

test('grassetto: pezzi tra doppi asterischi, il resto invariato', () => {
  assert.deepEqual(pezziGrassetto('Annaffia **domani mattina**, non oggi.'),
    [{ t: 'Annaffia ', b: false }, { t: 'domani mattina', b: true }, { t: ', non oggi.', b: false }])
  assert.deepEqual(pezziGrassetto('**Tutto**'), [{ t: 'Tutto', b: true }])
  assert.deepEqual(pezziGrassetto('- **Pomodoro**: sì\n- **Basilico**: no'),
    [{ t: '- ', b: false }, { t: 'Pomodoro', b: true }, { t: ': sì\n- ', b: false }, { t: 'Basilico', b: true }, { t: ': no', b: false }])
})

test('grassetto: asterischi senza chiusura o vuoti restano testo, HTML resta testo', () => {
  assert.deepEqual(pezziGrassetto('Sto scrivendo **qualcosa'), [{ t: 'Sto scrivendo **qualcosa', b: false }])
  assert.deepEqual(pezziGrassetto('2 ** 3 e **  **'), [{ t: '2 ** 3 e **  **', b: false }])
  assert.deepEqual(pezziGrassetto('**<b>x</b>**'), [{ t: '<b>x</b>', b: true }])
  assert.deepEqual(pezziGrassetto(''), [])
  assert.deepEqual(pezziGrassetto(null), [])
})
