import { test } from 'node:test'
import assert from 'node:assert/strict'
import { dataRoma, stagioneRoma, inizioMeseRoma } from './date.js'
import { concimeConsigliato, classificaConcimiPerFabbisogno } from './concimi.js'
import { valutaCura, tipiCuraPianta, ultimaPioggiaUtile } from './cure.js'

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

const giornoFa = (n) => new Date(Date.now() - n * 86400000).toISOString().slice(0, 10)
const ogni10 = { primavera: 'ogni 10 giorni', estate: 'ogni 10 giorni', autunno: 'ogni 10 giorni', inverno: 'ogni 10 giorni' }
const specie10 = { manutenzione: { irrigazione: ogni10 } }

test('pioggia caduta: conta il giorno più recente con almeno 5 mm', () => {
  assert.equal(ultimaPioggiaUtile([{ data: '2026-11-18', pioggia: '12.0' }, { data: '2026-11-20', pioggia: '4.9' }, { data: '2026-11-19', pioggia: '5.0' }]), '2026-11-19')
  assert.equal(ultimaPioggiaUtile([{ data: '2026-11-20', pioggia: '1.0' }]), null)
  assert.equal(ultimaPioggiaUtile(null), null)
})

test('pioggia caduta: dopo uno spostamento conta solo quella dei giorni successivi', () => {
  const giorni = [{ data: '2026-11-18', pioggia: '12.0' }, { data: '2026-11-20', pioggia: '8.0' }]
  assert.equal(ultimaPioggiaUtile(giorni, '2026-11-19'), '2026-11-20')
  assert.equal(ultimaPioggiaUtile(giorni, '2026-11-20'), null)
  assert.equal(ultimaPioggiaUtile(giorni, null), '2026-11-20')
})

test('irrigazione: una pianta appena riportata fuori non conta la pioggia di quando era in casa', () => {
  const pioggiaCaduta = [{ data: giornoFa(3), pioggia: '15.0' }]
  const pianta = { ultima_cura: { irrigazione: giornoFa(12) } }
  assert.equal(valutaCura(pianta, specie10, 'irrigazione', { esterno: true, pioggiaCaduta }).urgente, false)
  const spostata = { ...pianta, spostata_il: giornoFa(1) }
  assert.equal(valutaCura(spostata, specie10, 'irrigazione', { esterno: true, pioggiaCaduta }).urgente, true)
})

test('pioggia caduta: all\'aperto fa ripartire la cadenza dell\'irrigazione', () => {
  const pianta = { ultima_cura: { irrigazione: giornoFa(30) } }
  const pioggiaCaduta = [{ data: giornoFa(2), pioggia: '18.4' }]
  const fuori = valutaCura(pianta, specie10, 'irrigazione', { esterno: true, pioggiaCaduta })
  assert.equal(fuori.urgente, false)
  assert.equal(fuori.giorni, 8)
  assert.equal(fuori.pioggia, giornoFa(2))
  assert.match(fuori.label, /^irrigazione — tra 8 gg \(ha piovuto il \d\d\/\d\d\)$/)
  // In casa, o in acqua, la pioggia non conta
  assert.equal(valutaCura(pianta, specie10, 'irrigazione', { esterno: false, pioggiaCaduta }).urgente, true)
  assert.equal(valutaCura({ ...pianta, coltivato_in: 'acqua' }, specie10, 'irrigazione', { esterno: true, pioggiaCaduta }).urgente, true)
  // Mai irrigata ma è piovuto: conta la pioggia
  assert.equal(valutaCura({}, specie10, 'irrigazione', { esterno: true, pioggiaCaduta }).giorni, 8)
})

test('pioggia caduta: un\'irrigazione registrata dopo la pioggia vince', () => {
  const pianta = { ultima_cura: { irrigazione: giornoFa(1) } }
  const c = valutaCura(pianta, specie10, 'irrigazione', { esterno: true, pioggiaCaduta: [{ data: giornoFa(3), pioggia: '20' }] })
  assert.equal(c.giorni, 9)
  assert.equal(c.pioggia, null)
  assert.doesNotMatch(c.label, /piovuto/)
})
