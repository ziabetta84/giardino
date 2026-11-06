import { test } from 'node:test'
import assert from 'node:assert/strict'
import { albaTramonto, luceDelMomento } from './sole.js'

const FANO = { lat: 43.84, lon: 13.02 }
const minuti = (d) => d.getUTCHours() * 60 + d.getUTCMinutes()

test('sole: alba e tramonto a Fano entro pochi minuti dai valori di riferimento', () => {
  // 6 novembre 2026: alba ~05:55 UTC, tramonto ~15:52 UTC (NOAA)
  const { alba, tramonto } = albaTramonto(new Date(2026, 10, 6, 12), FANO.lat, FANO.lon)
  assert.ok(Math.abs(minuti(alba) - (5 * 60 + 55)) <= 5, alba.toISOString())
  assert.ok(Math.abs(minuti(tramonto) - (15 * 60 + 52)) <= 5, tramonto.toISOString())
  // 21 giugno: alba ~03:21 UTC, tramonto ~18:57 UTC
  const estate = albaTramonto(new Date(2026, 5, 21, 12), FANO.lat, FANO.lon)
  assert.ok(Math.abs(minuti(estate.alba) - (3 * 60 + 21)) <= 5, estate.alba.toISOString())
  assert.ok(Math.abs(minuti(estate.tramonto) - (18 * 60 + 57)) <= 5, estate.tramonto.toISOString())
})

test('sole: la luce usa le ore di Open-Meteo se ci sono, altrimenti il calcolo', () => {
  const sera = new Date(Date.UTC(2026, 10, 6, 18, 30))
  const mattina = new Date(Date.UTC(2026, 10, 6, 9, 0))
  assert.equal(luceDelMomento(sera, {}, FANO), 'notte')
  assert.equal(luceDelMomento(mattina, {}, FANO), 'giorno')
  assert.equal(luceDelMomento(sera, { alba: '2026-11-06T05:00Z', tramonto: '2026-11-06T20:00Z' }, FANO), 'giorno')
  // Senza posizione si ripiega su una stima, che resta notte alle 18:30 UTC
  assert.equal(luceDelMomento(sera), 'notte')
})

test('sole: notte polare', () => {
  assert.equal(albaTramonto(new Date(2026, 11, 21, 12), 80, 15), null)
  assert.equal(luceDelMomento(new Date(2026, 11, 21, 12), {}, { lat: 80, lon: 15 }), 'notte')
})
