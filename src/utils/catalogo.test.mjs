import { test } from 'node:test'
import assert from 'node:assert/strict'
import { chiavePianta, colonneDaChiave, slugDaNome, creditoFoto, etichettaLivello, varietaNelTitolo } from './catalogo.js'

const U = '0b6c2f4e-1f2a-4c3b-9d8e-7f6a5b4c3d2e'

test('chiave dalla riga di piante', () => {
  assert.equal(chiavePianta({ taxon_id: U, cultivar_id: null }), `t:${U}`)
  assert.equal(chiavePianta({ taxon_id: null, cultivar_id: U }), `c:${U}`)
  assert.equal(chiavePianta({}), null)
})

test('colonne dalla chiave', () => {
  assert.deepEqual(colonneDaChiave(`t:${U}`), { taxon_id: U, cultivar_id: null })
  assert.deepEqual(colonneDaChiave(`c:${U}`), { taxon_id: null, cultivar_id: U })
  assert.equal(colonneDaChiave('hedera-helix'), null)
  assert.equal(colonneDaChiave(''), null)
  assert.equal(colonneDaChiave(null), null)
})

test('slug per l\'id delle piante nuove', () => {
  assert.equal(slugDaNome("Carex oshimensis 'Evergold'"), 'carex-oshimensis-evergold')
  assert.equal(slugDaNome('Citrus × aurantium'), 'citrus-aurantium')
  assert.equal(slugDaNome('Lillà'), 'lilla')
  assert.equal(slugDaNome(''), 'pianta')
})

test('credito della foto secondo la licenza', () => {
  const img = { url: 'https://upload.wikimedia.org/x.jpg', attribuzione: 'Mario Rossi', licenza: 'CC BY-SA 3.0',
    licenza_url: 'https://creativecommons.org/licenses/by-sa/3.0', fonte_pagina: 'https://commons.wikimedia.org/wiki/File:Hedera_helix_01.jpg' }
  assert.deepEqual(creditoFoto(img), { titolo: 'Hedera helix 01', autore: 'Mario Rossi', licenza: 'CC BY-SA 3.0',
    pagina: img.fonte_pagina, licenzaUrl: img.licenza_url })
  assert.equal(creditoFoto({ ...img, licenza: 'CC BY-SA 4.0' }).titolo, null)
  assert.equal(creditoFoto({ ...img, licenza: 'CC BY 2.5' }).titolo, 'Hedera helix 01')
  assert.equal(creditoFoto({ ...img, licenza: 'Public domain' }).titolo, null)
  assert.equal(creditoFoto({ ...img, fonte_pagina: 'https://commons.wikimedia.org/wiki/File:Fiore%20d%27arancio.png' }).titolo, "Fiore d'arancio")
  assert.equal(creditoFoto({ url: 'u' }).autore, null)
  assert.equal(creditoFoto(null), null)
  assert.equal(creditoFoto({}), null)
})

test('etichetta del livello', () => {
  assert.equal(etichettaLivello({ rango: 'genus', nome: 'Hedera' }), 'del genere Hedera')
  assert.equal(etichettaLivello({ rango: 'species', nome: 'Carex oshimensis' }), 'della specie Carex oshimensis')
  assert.equal(etichettaLivello({ rango: 'variety', nome: 'X y var. z' }), 'della varietà X y var. z')
  assert.equal(etichettaLivello({ rango: 'grex', nome: 'Phalaenopsis Abc' }), 'del grex Phalaenopsis Abc')
  assert.equal(etichettaLivello({ rango: 'lusus', nome: 'X' }), 'di X')
  assert.equal(etichettaLivello(null), '')
})

test('varietà nel titolo', () => {
  assert.equal(varietaNelTitolo({ tipo: 'cultivar' }, 'Meditation Pink'), '')
  assert.equal(varietaNelTitolo({ tipo: 'taxon' }, 'nano'), 'nano')
  assert.equal(varietaNelTitolo(null, 'nano'), 'nano')
  assert.equal(varietaNelTitolo({ tipo: 'taxon' }, null), '')
})
