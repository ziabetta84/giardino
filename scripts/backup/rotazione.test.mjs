import { test } from 'node:test'
import assert from 'node:assert/strict'
import { daCancellare } from './rotazione.mjs'

const adesso = new Date(2026, 9, 30, 22, 0, 0)  // venerdì 30/10/2026
const nome = (g, m, ora = '120000', age = true) => `giardino_zorba_2026${String(m).padStart(2, '0')}${String(g).padStart(2, '0')}_${ora}.sql${age ? '.age' : ''}`

test('negli ultimi 7 giorni tiene l\'ultimo di ogni giorno', () => {
  const nomi = [nome(30, 10, '080000'), nome(30, 10, '210000'), nome(29, 10), nome(24, 10)]
  assert.deepEqual(daCancellare(nomi, adesso), [nome(30, 10, '080000')])
})

test('dopo 7 giorni tiene solo l\'ultimo della settimana', () => {
  // 13, 14 e 15/10 sono martedì, mercoledì e giovedì della stessa settimana
  const nomi = [nome(30, 10), nome(13, 10), nome(14, 10), nome(15, 10)]
  assert.deepEqual(daCancellare(nomi, adesso).sort(), [nome(13, 10), nome(14, 10)].sort())
})

test('oltre 30 giorni cancella tutto, anche l\'unico backup', () => {
  assert.deepEqual(daCancellare([nome(20, 9)], adesso), [nome(20, 9)])
})

test('il più recente resta sempre se ha meno di 30 giorni', () => {
  assert.deepEqual(daCancellare([nome(5, 10)], adesso), [])
})

test('ruotano anche i vecchi file in chiaro; gli altri nomi non si toccano', () => {
  const nomi = [nome(1, 9, '120000', false), 'completo_20261015_062051_pre_manutenzione_specie.dump', 'account_eliminati.tsv']
  assert.deepEqual(daCancellare(nomi, adesso), [nome(1, 9, '120000', false)])
})
