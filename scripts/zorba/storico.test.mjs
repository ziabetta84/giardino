import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mappaRichiesta, testoVecchioFormato, sqlStorico } from './storico.js'

const U = 'beeaf4ef-49a3-4898-9521-f7c2947a130d'

test('richiesta completata normale', () => {
  const m = mappaRichiesta('r-1', { tipo: 'consiglio_cura', messaggio: 'Come?', stato: 'completata', creata: '2026-09-01T10:00:00Z',
    risposta: { messaggio: 'Così.', elaborata: '2026-09-01T12:00:00Z' } }, new Set())
  assert.equal(m.filo.tipo, 'consiglio_cura')
  assert.equal(m.filo.stato, 'chiuso')
  assert.deepEqual(m.messaggi.map(x => [x.ruolo, x.testo, x.esito]), [['utente', 'Come?', null], ['zorba', 'Così.', 'completata']])
  assert.equal(m.messaggi[1].creato, '2026-09-01T12:00:00Z')
})

test('revisione_specie diventa segnalazione accolta', () => {
  const m = mappaRichiesta('r-2', { tipo: 'revisione_specie', voce: `t:${U}`, nome_voce: 'Rosa', messaggio: '', stato: 'completata',
    creata: '2026-09-01T10:00:00Z', risposta: { messaggio: 'Fatto.' } }, new Set())
  assert.equal(m.filo.tipo, 'segnalazione_scheda')
  assert.equal(m.filo.segnalazione_stato, 'accolta')
  assert.equal(m.filo.voce, `t:${U}`)
  assert.equal(m.messaggi[0].testo, null)
})

test('progetto non uuid o inesistente: id nullo, titolo conservato', () => {
  const r = { tipo: 'pianifica_progetto', progetto: 'progetto-1785205019885', titolo_progetto: null, messaggio: 'Talee',
    stato: 'completata', creata: '2026-08-01T10:00:00Z', risposta: { messaggio: 'Ok' } }
  const m = mappaRichiesta('r-3', r, new Set())
  assert.equal(m.filo.progetto_id, null)
  assert.equal(m.filo.titolo_progetto, 'progetto-1785205019885')
  const esiste = mappaRichiesta('r-4', { ...r, progetto: U }, new Set([U]))
  assert.equal(esiste.filo.progetto_id, U)
})

test('errore con messaggio e vecchio formato', () => {
  const e = mappaRichiesta('r-5', { tipo: 'identifica_specie', messaggio: 'Identifica', stato: 'errore', creata: '2026-07-16T10:28:32Z',
    risposta: { messaggio: 'Foto illeggibile.' } }, new Set())
  assert.equal(e.messaggi[1].esito, 'errore')
  const t = testoVecchioFormato({ candidati: [{ nome: 'Aglio', specieBotanica: 'Allium sativum', confidenza: 'media', note: 'Germoglio.' },
    { nome: 'Cipolla', specieBotanica: 'Allium cepa', confidenza: 'bassa', note: 'Simile.' }], schedaTop: { nome: 'Aglio' } })
  assert.equal(t, 'Candidati più probabili:\n- Aglio (Allium sativum), confidenza media: Germoglio.\n- Cipolla (Allium cepa), confidenza bassa: Simile.')
})

test('SQL con apici raddoppiati e owner esplicito', () => {
  const sql = sqlStorico([['r-6', { tipo: 'altro', messaggio: "l'orto", stato: 'completata', creata: '2026-09-01T10:00:00Z',
    risposta: { messaggio: 'Bene' } }]], 'fc227422-ece8-4dca-b706-956ec7ca9e6e', new Set())
  assert.match(sql, /'l''orto'/)
  assert.match(sql, /'fc227422-ece8-4dca-b706-956ec7ca9e6e'/)
  assert.match(sql, /importato/)
  assert.match(sql, /^-- progetti: $/m)
})
