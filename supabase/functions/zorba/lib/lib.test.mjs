import { test } from 'node:test'
import assert from 'node:assert/strict'
import { costoRisposte } from './costi.js'
import { validaRichiesta } from './ingresso.js'
import { messaggiDalFilo, contestoSistema, testoFinale } from './filo.js'

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]).toString('base64')
const PNG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 1, 2, 3]).toString('base64')
const U = 'beeaf4ef-49a3-4898-9521-f7c2947a130d'

test('costo per modello, con cache, e ripiego al prezzo più alto', () => {
  const r = { model: 'claude-opus-5-5', usage: { input_tokens: 1_000_000, output_tokens: 100_000, cache_read_input_tokens: 1_000_000, cache_creation_input_tokens: 1_000_000 } }
  assert.equal(costoRisposte([r]).costo.toFixed(2), (4 + 2 + 0.2 + 5).toFixed(2))
  const s = { model: 'claude-sonnet-5-5', usage: { input_tokens: 1_000_000, output_tokens: 0 } }
  assert.equal(costoRisposte([r, s]).costo.toFixed(2), (11.2 + 2).toFixed(2))
  const ign = { model: 'claude-ignoto', usage: { input_tokens: 1_000_000, output_tokens: 0 } }
  assert.equal(costoRisposte([ign]).costo, 10)
  const it = { model: 'claude-sonnet-5-5', usage: { input_tokens: 0, output_tokens: 0, iterations: [
    { model: 'claude-sonnet-5-5', input_tokens: 1_000_000, output_tokens: 0 }, { model: 'claude-opus-5-5', input_tokens: 1_000_000, output_tokens: 0 }] } }
  assert.equal(costoRisposte([it]).costo, 6)
  assert.equal(costoRisposte([it]).modello, 'claude-opus-5-5')
})

test('ingresso: casi validi', () => {
  assert.equal(validaRichiesta({ nuovo: { tipo: 'identifica_specie' }, foto: JPEG }).ok, true)
  assert.equal(validaRichiesta({ nuovo: { tipo: 'segnalazione_scheda', voce: `t:${U}` }, testo: 'dice -5 °C' }).ok, true)
  assert.equal(validaRichiesta({ nuovo: { tipo: 'pianifica_progetto', titolo_progetto: 'Orto' }, testo: 'semine' }).ok, true)
  assert.equal(validaRichiesta({ filo_id: U, testo: 'e poi?' }).ok, true)
  assert.equal(validaRichiesta({ filo_id: U, riprova: true }).ok, true)
})

test('ingresso: rifiuti', () => {
  const r = (c) => validaRichiesta(c).codice
  assert.equal(r({ nuovo: { tipo: 'identifica_specie' }, foto: PNG }), 'foto_non_valida')
  assert.equal(r({ nuovo: { tipo: 'identifica_specie' } }), 'foto_mancante')
  assert.equal(r({ nuovo: { tipo: 'altro' }, testo: 'x'.repeat(4001) }), 'testo_troppo_lungo')
  assert.equal(r({ nuovo: { tipo: 'altro' }, foto: Buffer.alloc(1_572_865, 0xff).toString('base64') }), 'foto_troppo_grande')
  assert.equal(r({ nuovo: { tipo: 'segnalazione_scheda', voce: 'hedera-helix' }, testo: 'x' }), 'richiesta_non_valida')
  assert.equal(r({ nuovo: { tipo: 'pianifica_progetto' }, testo: 'x' }), 'richiesta_non_valida')
  assert.equal(r({ nuovo: { tipo: 'pianifica_progetto', progetto_id: 'progetto-1' }, testo: 'x' }), 'richiesta_non_valida')
  assert.equal(r({ nuovo: { tipo: 'boh' }, testo: 'x' }), 'richiesta_non_valida')
  assert.equal(r({ filo_id: 'x', testo: 'x' }), 'richiesta_non_valida')
  assert.equal(r({ filo_id: U }), 'testo_mancante')
  assert.equal(r({ nuovo: { tipo: 'consiglio_cura' } }), 'testo_mancante')
})

test('filo per Claude: solo testo delle risposte riuscite, foto prima del testo', () => {
  const m = messaggiDalFilo([
    { ruolo: 'utente', testo: null, fotoBase64: 'AAA' },
    { ruolo: 'zorba', testo: 'Pare aglio.', esito: 'completata' },
    { ruolo: 'utente', testo: 'sicuro?' },
    { ruolo: 'zorba', testo: null, esito: 'errore' },
    { ruolo: 'zorba', testo: null, esito: 'in_corso' },
  ])
  assert.deepEqual(m.map(x => x.role), ['user', 'assistant', 'user'])
  assert.equal(m[0].content[0].type, 'image')
  assert.equal(m[0].content[1].text, '(solo foto, nessun testo)')
  assert.equal(m[1].content, 'Pare aglio.')
})

test('contesto di sistema: data e stagione di Roma, tipo, voce, PlantNet', () => {
  const t = contestoSistema({ adesso: new Date('2026-11-30T23:30:00Z'), tipo: 'segnalazione_scheda', nomeVoce: 'Rosa', voce: `t:${U}`, plantnet: 'Allium sativum (0,62)' })
  assert.match(t, /1 dicembre 2026/)
  assert.match(t, /inverno/)
  assert.match(t, /segnalazione_scheda/)
  assert.match(t, /Rosa/)
  assert.match(t, /Allium sativum/)
})

test('testo finale: solo dopo l\'ultimo ripiego', () => {
  assert.equal(testoFinale([{ type: 'text', text: 'Ciao' }, { type: 'text', text: ' mondo' }]), 'Ciao mondo')
  assert.equal(testoFinale([{ type: 'text', text: 'rifiutato a metà' }, { type: 'fallback' }, { type: 'thinking' }, { type: 'text', text: 'Risposta' }]), 'Risposta')
})
