import { test } from 'node:test'
import assert from 'node:assert/strict'
import { partiNomeScientifico, nomeComuneVoce } from './nomeScientifico.js'

const forma = parti => parti.map(p => p.corsivo ? `<${p.testo}>` : p.testo).join('')

test('specie, genere e cultivar', () => {
  assert.equal(forma(partiNomeScientifico('Phalaenopsis')), '<Phalaenopsis>')
  assert.equal(forma(partiNomeScientifico('Laurus nobilis')), '<Laurus nobilis>')
  assert.equal(forma(partiNomeScientifico("Carex oshimensis 'Evergold'")), "<Carex oshimensis> 'Evergold'")
  assert.equal(forma(partiNomeScientifico("Echinacea 'Meditation Pink'")), "<Echinacea> 'Meditation Pink'")
  assert.equal(forma(partiNomeScientifico("Capsicum annuum 'Piccante Calabrese'")), "<Capsicum annuum> 'Piccante Calabrese'")
})

test('ranghi, ibridi, spp. in tondo', () => {
  assert.equal(forma(partiNomeScientifico('Phedimus spurius subsp. spurius')), '<Phedimus spurius> subsp. <spurius>')
  assert.equal(forma(partiNomeScientifico('Olea europaea var. sylvestris')), '<Olea europaea> var. <sylvestris>')
  assert.equal(forma(partiNomeScientifico('Citrus × aurantium')), '<Citrus> × <aurantium>')
  assert.equal(forma(partiNomeScientifico('× Fatshedera lizei')), '× <Fatshedera lizei>')
  assert.equal(forma(partiNomeScientifico('Rosa spp.')), '<Rosa> spp.')
})

test('grex e Gruppi in tondo', () => {
  assert.equal(forma(partiNomeScientifico("Paphiopedilum Maudiae 'Femma'")), "<Paphiopedilum> Maudiae 'Femma'")
  assert.equal(forma(partiNomeScientifico('Brassica oleracea Acephala Group')), '<Brassica oleracea> Acephala Group')
})

test('il testo non cambia', () => {
  for (const n of ["Citrus × aurantium", "Carex oshimensis 'Evergold'", 'Phedimus spurius subsp. spurius'])
    assert.equal(partiNomeScientifico(n).map(p => p.testo).join(''), n)
  assert.deepEqual(partiNomeScientifico(''), [])
  assert.deepEqual(partiNomeScientifico(null), [])
})

test('nome comune sotto il titolo', () => {
  assert.equal(nomeComuneVoce({ tipo: 'taxon', nome: 'Falenopside', specie: 'Phalaenopsis' }), 'Falenopside')
  assert.equal(nomeComuneVoce({ tipo: 'taxon', nome: 'Aeonium', specie: 'Aeonium' }), '')
  assert.equal(nomeComuneVoce({ tipo: 'taxon', nome: 'Spiraea × arguta', specie: 'Spiraea × arguta' }), '')
  assert.equal(nomeComuneVoce({ tipo: 'cultivar', nome: "Carice 'Evergold'", specie: "Carex oshimensis 'Evergold'" }), 'Carice')
  assert.equal(nomeComuneVoce({ tipo: 'cultivar', nome: "Echinacea 'Meditation Pink'", specie: "Echinacea 'Meditation Pink'" }), '')
  assert.equal(nomeComuneVoce({ tipo: 'cultivar', nome: "Fico del caucciù 'Belize'", specie: "Ficus elastica 'Belize'" }), 'Fico del caucciù')
  assert.equal(nomeComuneVoce(null), '')
})
