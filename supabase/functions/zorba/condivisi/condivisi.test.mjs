import { test } from 'node:test'
import assert from 'node:assert/strict'
import { dataRoma, stagioneRoma, inizioMeseRoma } from './date.js'
import { concimeConsigliato, classificaConcimiPerFabbisogno } from './concimi.js'
import { valutaCura, tipiCuraPianta } from './cure.js'

test('data e stagione nel fuso di Roma, non in UTC', () => {
  // 30 novembre 23:30 UTC = 1 dicembre 00:30 a Roma: già inverno
  const t = new Date('2026-11-30T23:30:00Z')
  assert.equal(dataRoma(t).getDate(), 1)
  assert.equal(stagioneRoma(t), 'inverno')
  assert.equal(inizioMeseRoma(t), '2026-12')
  assert.equal(stagioneRoma(new Date('2026-07-10T12:00:00Z')), 'estate')
})

test('il concime più vicino per rapporto, entro la soglia', () => {
  const concimi = { a: { nome: 'Fiori', npk: { n: 5, p: 10, k: 10 } }, b: { nome: 'Verde', npk: { n: 20, p: 5, k: 5 } } }
  assert.equal(concimeConsigliato('10-20-20', concimi).nome, 'Fiori')
  assert.equal(concimeConsigliato('1-1-30', concimi), null)
  assert.deepEqual(classificaConcimiPerFabbisogno('20-5-5', concimi).map(c => c.nome), ['Verde', 'Fiori'])
})

test('cure: tipi per una pianta in acqua e cura mai registrata', () => {
  const voce = { manutenzione: { concimazione: { primavera: 'ogni 2 settimane', estate: 'ogni 2 settimane', autunno: 'ogni 2 settimane', inverno: 'ogni 2 settimane' } } }
  assert.deepEqual(tipiCuraPianta({ coltivato_in: 'acqua' }, voce), ['cambio_acqua', 'concimazione'])
  const r = valutaCura({ ultima_cura: {} }, voce, 'concimazione')
  assert.equal(r.urgente, true)
  assert.match(r.label, /mai registrata/)
})
