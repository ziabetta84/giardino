-- Nomi italiani lotto 3b: 31 specie, nome principale = nome preferito di iNaturalist
-- (diverso da tutti i nomi alternativi PlantNet, che restano invariati). Solo righe ancora senza nome italiano
-- e con nome non già in uso. Rollback: scripts/nomi-italiani/rollback_lotto3b.sql
with v(slug, nome) as (values
  ('acacia-longifolia', 'Acacia a foglie lunghe'),
  ('allium-ampeloprasum', 'Aglio ampelopraso'),
  ('crataegus-crus-galli', 'Biancospino piè di gallo'),
  ('euphorbia-hypericifolia', 'Euforbia con foglie d''iperico'),
  ('ficus-benjamina', 'Fico benjamin'),
  ('ficus-elastica', 'Fico del caucciù'),
  ('iris-orientalis', 'Giaggiolo orientale'),
  ('lawsonia-inermis', 'Henné'),
  ('mirabilis-nyctaginea', 'Allionia comune'),
  ('myosotis-arvensis', 'Non ti scordar di me minore'),
  ('onosma-echioides', 'Viperina echioide'),
  ('opuntia-robusta', 'Fico d''India robusto'),
  ('pilosella-officinarum', 'Pelosella pelosetta'),
  ('pimpinella-anisum', 'Anice comune'),
  ('platanus-occidentalis', 'Platano americano'),
  ('polygonum-aviculare', 'Erba curzola'),
  ('primula-latifolia', 'Primula a foglie larghe'),
  ('psidium-guajava', 'Guava'),
  ('pulmonaria-officinalis', 'Polmonaria'),
  ('quercus-frainetto', 'Farnetto'),
  ('rubus-saxatilis', 'Mora rossa'),
  ('rumex-arifolius', 'Romice alpestre'),
  ('rumex-hydrolapathum', 'Romice di palude'),
  ('rumex-pulcher', 'Romice bello'),
  ('saxifraga-caesia', 'Sassifraga verde-azzurra'),
  ('securigera-varia', 'Erba ginestrina'),
  ('sicyos-angulatus', 'Zucca spinosa'),
  ('valerianella-locusta', 'Valerianella comune'),
  ('vicia-tenuifolia', 'Veccia a foglie fini'),
  ('vitellaria-paradoxa', 'Carité'),
  ('washingtonia-robusta', 'Palma a ventaglio messicana')
)
update specie s set nome = v.nome
from v
where s.slug = v.slug and s.specie_padre_id is null and s.nome = s.nome_scientifico
  and not exists (select 1 from specie o where o.nome = v.nome);
