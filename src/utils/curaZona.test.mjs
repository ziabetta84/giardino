import { test } from 'node:test'
import assert from 'node:assert/strict'
import { classificaCuraZona, concimeAdatto, pianteDellaZona } from './curaZona.js'
import { stagione } from '../../supabase/functions/zorba/condivisi/cure.js'

const S = stagione()
const giorniFa = n => new Date(Date.now() - n * 86400000).toISOString().split('T')[0]
const scheda = (irr, conc = 'ogni 30 giorni', npk = null, calcio = null) => ({
  nome: 'x',
  manutenzione: {
    irrigazione: { [S]: irr }, concimazione: { [S]: conc },
    ...(npk ? { npk: { [S]: npk } } : {}),
    ...(calcio ? { calcio: { [S]: calcio } } : {}),
  },
})
const schede = {
  ortiva: scheda('ogni 2 giorni', 'ogni 14 giorni', '10-5-10', 'ogni 30 giorni'),
  rosa: scheda('ogni 10 giorni', 'ogni 30 giorni', '4-8-12'),
  succulenta: scheda('non necessario', 'mai'),
  senzaDati: { nome: 'y', manutenzione: {} },
}
const piante = {
  pomodoro: { zona: 'Est', sottozona: 'Orto', voce: 'ortiva', ultima_cura: { irrigazione: giorniFa(3), concimazione: giorniFa(20) } },
  rosaFresca: { zona: 'Est', sottozona: null, voce: 'rosa', ultima_cura: { irrigazione: giorniFa(2), concimazione: giorniFa(2) } },
  rosaMeta: { zona: 'Est', sottozona: null, voce: 'rosa', ultima_cura: { irrigazione: giorniFa(5), concimazione: giorniFa(16) } },
  aloe: { zona: 'Est', sottozona: null, voce: 'succulenta', ultima_cura: {} },
  pothos: { zona: 'Est', sottozona: null, voce: 'rosa', coltivato_in: 'acqua', ultima_cura: {} },
  ignota: { zona: 'Est', sottozona: null, voce: 'senzaDati', ultima_cura: {} },
  altrove: { zona: 'Ovest', sottozona: null, voce: 'ortiva', ultima_cura: {} },
}
const base = { piante, zona: 'Est', vocePianta: p => schede[p.voce], nomePianta: p => p.voce }
const trova = (g, id) => [...g.daFare, ...g.possono, ...g.escluse].find(i => i.piantaId === id)
const gruppoDi = (g, id) => Object.keys(g).find(k => g[k].some(i => i.piantaId === id))

test('piante della zona e della sottozona', () => {
  assert.equal(pianteDellaZona(piante, 'Est').length, 6)
  assert.deepEqual(pianteDellaZona(piante, 'Est', 'Orto').map(([id]) => id), ['pomodoro'])
})

test('irrigazione: da fare, possono, escluse', () => {
  const g = classificaCuraZona({ ...base, tipo: 'irrigazione' })
  assert.equal(gruppoDi(g, 'pomodoro'), 'daFare')
  assert.equal(trova(g, 'pomodoro').spuntata, true)
  assert.equal(trova(g, 'pomodoro').motivo, 'Scaduta da 1 gg')
  // 5 giorni su 10: metà intervallo, spuntata
  assert.equal(gruppoDi(g, 'rosaMeta'), 'possono')
  assert.equal(trova(g, 'rosaMeta').spuntata, true)
  // 2 giorni su 10: troppo presto
  assert.equal(trova(g, 'rosaFresca').spuntata, false)
  assert.match(trova(g, 'rosaFresca').motivo, /^Troppo presto/)
  // in riposo e in acqua: escluse
  assert.equal(gruppoDi(g, 'aloe'), 'escluse')
  assert.match(trova(g, 'aloe').motivo, /riposo/)
  assert.equal(gruppoDi(g, 'pothos'), 'escluse')
  // scheda senza cadenza: si può spuntare a mano
  assert.equal(gruppoDi(g, 'ignota'), 'possono')
  assert.equal(trova(g, 'ignota').spuntata, false)
  // le piante di altre zone non compaiono
  assert.equal(trova(g, 'altrove'), undefined)
})

test('irrigazione automatica esclusa', () => {
  const programmi = { giardino: null, zone: {}, sottozone: { 'Est|Orto': { ogniGiorni: 2 } }, piante: {} }
  const g = classificaCuraZona({ ...base, tipo: 'irrigazione', programmi })
  assert.equal(gruppoDi(g, 'pomodoro'), 'escluse')
  assert.equal(trova(g, 'pomodoro').motivo, 'Irrigazione automatica ogni 2 gg')
  assert.equal(gruppoDi(g, 'rosaMeta'), 'possono')
})

test('concimazione con concime scelto: chi ha un fabbisogno diverso resta senza spunta', () => {
  const concimi = {
    universale: { nome: 'Universale', npk: { n: 10, p: 5, k: 10 } },
    fioriti: { nome: 'Fioriti', npk: { n: 4, p: 8, k: 12 } },
  }
  const g = classificaCuraZona({ ...base, tipo: 'concimazione', concimi, concimeId: 'universale' })
  assert.equal(gruppoDi(g, 'pomodoro'), 'daFare')
  assert.equal(trova(g, 'pomodoro').spuntata, true)
  assert.equal(trova(g, 'pomodoro').avviso, null)
  // 16 giorni su 30, ma fabbisogno 4-8-12: senza spunta, con il consiglio
  assert.equal(trova(g, 'rosaMeta').spuntata, false)
  assert.equal(trova(g, 'rosaMeta').avviso, 'Fabbisogno diverso (4-8-12): meglio Fioriti (4-8-12)')
  // scheda «mai»: esclusa anche dalla concimazione
  assert.equal(gruppoDi(g, 'aloe'), 'escluse')
  // senza concime scelto non si giudica il fabbisogno
  const senza = classificaCuraZona({ ...base, tipo: 'concimazione', concimi })
  assert.equal(trova(senza, 'rosaMeta').spuntata, true)
})

test('calcio solo per le piante che lo prevedono', () => {
  const g = classificaCuraZona({ ...base, tipo: 'calcio' })
  assert.equal(gruppoDi(g, 'pomodoro'), 'daFare')
  assert.equal(gruppoDi(g, 'rosaMeta'), 'escluse')
  assert.equal(trova(g, 'rosaMeta').motivo, 'La scheda non prevede apporti di calcio')
})

test('concime adatto: vicino, lontano, non giudicabile', () => {
  assert.equal(concimeAdatto('10-5-10', { npk: { n: 20, p: 10, k: 20 } }), true)
  assert.equal(concimeAdatto('10-5-10', { npk: { n: 0, p: 20, k: 0 } }), false)
  assert.equal(concimeAdatto(null, { npk: { n: 1, p: 1, k: 1 } }), null)
  assert.equal(concimeAdatto('10-5-10', { npk: { n: null, p: null, k: 8 } }), null)
})
