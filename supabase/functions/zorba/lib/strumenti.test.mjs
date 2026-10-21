import { test } from 'node:test'
import assert from 'node:assert/strict'
import { DEFINIZIONI_STRUMENTI, eseguiStrumento, pulisciHtml, programmaPerPianta } from './strumenti.js'

// Client supabase finto: registra le chiamate e restituisce dati preparati per tabella o rpc
function dbFinto(dati) {
  const chiamate = []
  const query = (nome) => {
    const q = { _nome: nome, _filtri: [] }
    for (const m of ['select', 'eq', 'neq', 'ilike', 'in', 'order', 'limit', 'or']) q[m] = (...a) => { q._filtri.push([m, ...a]); return q }
    q.maybeSingle = () => Promise.resolve({ data: (dati[nome] ?? [])[0] ?? null, error: null })
    q.then = (ok, ko) => Promise.resolve({ data: dati[nome] ?? [], error: null }).then(ok, ko)
    return q
  }
  return {
    chiamate,
    from: (t) => { chiamate.push(['from', t]); return query(t) },
    rpc: (f, args) => { chiamate.push(['rpc', f, args]); return Promise.resolve(dati[`rpc:${f}`] ?? { data: null, error: null }) },
  }
}

const ctxBase = (db, extra = {}) => ({ db, filo: { id: 'f1', tipo: 'altro', progetto_id: null, titolo_progetto: null },
  adesso: new Date('2026-04-10T10:00:00Z'), fetch: async () => { throw new Error('rete') }, collegaProgetto: async () => {}, emetti: () => {}, ...extra })

test('definizioni: ordine fisso, strict, nessuno strumento che cancella', () => {
  assert.deepEqual(DEFINIZIONI_STRUMENTI.map(d => d.name),
    ['piante_giardino', 'pianta', 'cerca_catalogo', 'consiglia_concime', 'meteo', 'progetti', 'conversazioni_precedenti', 'salva_piano'])
  for (const d of DEFINIZIONI_STRUMENTI) {
    assert.equal(d.strict, true)
    assert.equal(d.input_schema.additionalProperties, false)
  }
})

test('pulisciHtml lascia solo p, b, strong, i, em senza attributi', () => {
  assert.equal(pulisciHtml('<p class="x">Ciao <b>forte</b> <img src=x onerror=alert(1)><script>alert(1)</script></p>'),
    '<p>Ciao <b>forte</b> &lt;img src=x onerror=alert(1)&gt;</p>') // i tag non ammessi diventano testo escapato, non si perdono
  assert.equal(pulisciHtml('<P><EM>a</EM></P><a href="javascript:x">b</a>'), '<p><em>a</em></p>&lt;a href="javascript:x"&gt;b&lt;/a&gt;')
})

test('programma di irrigazione: pianta, poi sottozona, poi zona, poi giardino', () => {
  const righe = [{ ogni_giorni: 7 }, { zona_id: 'z', ogni_giorni: 5 }, { sottozona_id: 's', ogni_giorni: 3 }]
  assert.equal(programmaPerPianta(righe, { id: 'p', zona_id: 'z', sottozona_id: 's' }), 3)
  assert.equal(programmaPerPianta(righe, { id: 'p', zona_id: 'z', sottozona_id: null }), 5)
  assert.equal(programmaPerPianta(righe, { id: 'p', zona_id: 'altra' }), 7)
  assert.equal(programmaPerPianta([...righe, { pianta_id: 'p', ogni_giorni: 2 }], { id: 'p', zona_id: 'z' }), 2)
  assert.equal(programmaPerPianta([], { id: 'p' }), null)
})

test('consiglia_concime usa il fabbisogno della stagione di Roma e la dispensa', async () => {
  const db = dbFinto({
    piante: [{ id: 'p1', taxon_id: 'T', cultivar_id: null }],
    'rpc:catalogo_voci': { data: { 't:T': { nome: 'Rosa', manutenzione: { npk: { primavera: '5-10-10' } } } }, error: null },
    concimi: [{ id: 'c1', nome: 'Fiori', npk: { n: 5, p: 10, k: 10 }, disponibile: true }, { id: 'c2', nome: 'Verde', npk: { n: 20, p: 5, k: 5 }, disponibile: true }],
  })
  const r = await eseguiStrumento('consiglia_concime', { pianta_id: 'p1' }, ctxBase(db))
  const j = JSON.parse(r.contenuto)
  assert.equal(r.errore, false)
  assert.equal(j.stagione, 'primavera')
  assert.equal(j.fabbisogno, '5-10-10')
  assert.equal(j.consigliato.nome, 'Fiori')
})

test('salva_piano rifiutato fuori da pianifica_progetto', async () => {
  const r = await eseguiStrumento('salva_piano', { descrizione: null, zona: null, tappe: [], esiti: [] }, ctxBase(dbFinto({})))
  assert.equal(r.errore, true)
})

test('salva_piano: progetto del filo, HTML pulito, collegamento del progetto nuovo', async () => {
  const db = dbFinto({ 'rpc:zorba_salva_piano': { data: 'P9', error: null }, progetti: [{ id: 'P9', titolo: 'Talee' }] })
  let collegato = null; const eventi = []
  const ctx = ctxBase(db, { filo: { id: 'f1', tipo: 'pianifica_progetto', progetto_id: null, titolo_progetto: 'Talee' },
    collegaProgetto: async (id) => { collegato = id }, emetti: (n, d) => eventi.push([n, d]) })
  const r = await eseguiStrumento('salva_piano', { descrizione: '<p onclick="x">Piano</p>', zona: 'Orto',
    tappe: [{ data: '2026-11-01', descrizione: 'ripresa', esito: 'atteso' }], esiti: [] }, ctx)
  assert.equal(r.errore, false)
  const [, , args] = db.chiamate.find(c => c[1] === 'zorba_salva_piano')
  assert.equal(args.p_progetto, null)
  assert.equal(args.p_titolo, 'Talee')
  assert.equal(args.p_descrizione, '<p>Piano</p>')
  assert.equal(collegato, 'P9')
  assert.equal(ctx.filo.progetto_id, 'P9')
  assert.deepEqual(eventi[0], ['progetto', { id: 'P9', titolo: 'Talee' }])
})

test('conversazioni precedenti esclude il filo corrente e dà domanda e risposta', async () => {
  const db = dbFinto({
    zorba_messaggi: [
      { filo_id: 'f1', creato: '2026-10-01' },
      { filo_id: 'f0', creato: '2026-09-01' }],
    zorba_fili: [{ id: 'f0', tipo: 'diagnosi', creato: '2026-09-01T08:00:00Z', zorba_messaggi: [
      { ruolo: 'zorba', testo: 'Carenza di ferro', esito: 'completata', creato: '2026-09-01T08:01:00Z' },
      { ruolo: 'utente', testo: 'foglie gialle sul limone', esito: null, creato: '2026-09-01T08:00:00Z' }] }],
  })
  const r = await eseguiStrumento('conversazioni_precedenti', { testo: 'foglie gialle' }, ctxBase(db))
  const j = JSON.parse(r.contenuto)
  assert.equal(j.length, 1)
  assert.deepEqual(j[0], { filo_id: 'f0', data: '2026-09-01', tipo: 'diagnosi', domanda: 'foglie gialle sul limone', risposta: 'Carenza di ferro' })
  const qm = db.chiamate.filter(c => c[0] === 'from')
  assert.deepEqual(qm.map(c => c[1]), ['zorba_messaggi', 'zorba_fili'])
})

test('conversazioni precedenti: messaggio di sola foto (testo null) non dà errore', async () => {
  const db = dbFinto({
    zorba_messaggi: [{ filo_id: 'f0', creato: '2026-09-01' }],
    zorba_fili: [{ id: 'f0', tipo: 'diagnosi', creato: '2026-09-01T08:00:00Z', zorba_messaggi: [
      { ruolo: 'utente', testo: null, esito: null, creato: '2026-09-01T08:00:00Z' },
      { ruolo: 'zorba', testo: 'Sembra oidio', esito: 'completata', creato: '2026-09-01T08:01:00Z' }] }],
  })
  const r = await eseguiStrumento('conversazioni_precedenti', { testo: 'oidio' }, ctxBase(db))
  assert.equal(r.errore, false)
  const j = JSON.parse(r.contenuto)
  assert.equal(j[0].domanda, null)
  assert.equal(j[0].risposta, 'Sembra oidio')
})

test('pulisciHtml: nessun tag non ammesso sopravvive a nidificazioni e tag non chiusi', () => {
  for (const x of ['<<x>img src=x onerror=alert(1)>', '<img src=x onerror=alert(1)', '<scr<script>x</script>ipt>alert(1)</script>']) {
    const out = pulisciHtml(x)
    assert.ok(!/<img/i.test(out) && !/<script/i.test(out), out)
    assert.ok(!/<(?!\/?(p|b|strong|i|em)>)/i.test(out), out)
  }
})

test('pianta: giorni trascorsi per ogni cura', async () => {
  const stag = { primavera: 'ogni 10 giorni', estate: 'ogni 10 giorni', autunno: 'ogni 10 giorni', inverno: 'ogni 10 giorni' }
  const db = dbFinto({
    piante: [{ id: 'p1', taxon_id: 'T', cultivar_id: null, coltivato_in: 'vaso', ultima_cura: { concimazione: '2026-04-01' } }],
    'rpc:catalogo_voci': { data: { 't:T': { nome: 'Rosa', manutenzione: { concimazione: stag, irrigazione: stag } } }, error: null },
    programmi_irrigazione: [],
  })
  const j = JSON.parse((await eseguiStrumento('pianta', { id: 'p1' }, ctxBase(db))).contenuto)
  const c = j.cure.find(x => x.tipo === 'concimazione')
  assert.equal(typeof c.giorni_trascorsi, 'number')
})

test('strumento sconosciuto o errore del database: risultato di errore, non eccezione', async () => {
  assert.equal((await eseguiStrumento('cancella_tutto', {}, ctxBase(dbFinto({})))).errore, true)
  const db = dbFinto({ 'rpc:cerca_catalogo': { data: null, error: { message: 'boom' } } })
  assert.equal((await eseguiStrumento('cerca_catalogo', { testo: 'rosa' }, ctxBase(db))).errore, true)
})
