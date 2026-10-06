-- Rollback lotto 4: ripristina nomi e nomi alternativi di prima.
with v(slug, nome_vecchio, alt_vecchi, nome) as (values
  ('anthurium', 'Anthurium', 'Anturio | Calla', 'Anturio'),
  ('arbutus', 'Arbutus', '', 'Corbezzolo'),
  ('cyclamen', 'Cyclamen', 'Ciclamino | Ciclamino persiano | Ciclamino di Persia', 'Ciclamino persiano'),
  ('exacum', 'Exacum', '', 'Violetta persiana'),
  ('fatsia-japonica', 'Aralia (Fatsia japonica)', 'Aralia giapponese | Aralia | Fatsia giapponese | Falso ricino', 'Fatsia giapponese'),
  ('helleborus', 'Helleborus', '', 'Elleboro nero'),
  ('hyacinthus', 'Hyacinthus', '', 'Giacinto comune'),
  ('hydrangea', 'Hydrangea', '', 'Ortensia'),
  ('jasminum', 'Jasminum', '', 'Gelsomino comune')
)
update specie s set nome = v.nome_vecchio, nomi_alternativi = nullif(v.alt_vecchi,'') from v
where s.slug = v.slug and s.nome = v.nome;

with v(slug, alt_vecchi, alt_nuovi) as (values
  ('acacia', '', 'Mimosa'),
  ('alisso', '', 'Filigrana comune'),
  ('amaranthus-viridis', '', 'Amaranto comune'),
  ('aquilegia', '', 'Aquilegia comune'),
  ('aspalathus-linearis', 'Tè rosso de Sudafrica', 'Tè rosso de Sudafrica | Rooibos'),
  ('asparago', '', 'Asparago comune'),
  ('avena-barbata', '', 'Avena Barbata'),
  ('calancola', '', 'Calandiva'),
  ('calendula-arvensis', '', 'Calendula dei campi'),
  ('camelia', '', 'Camelia del Giappone'),
  ('carex-divulsa', '', 'Carice a spighe separate'),
  ('cavolo-ornamentale', '', 'Cavolo'),
  ('daphne-sericea', '', 'Dafne olivella'),
  ('euonymus-japonicus', '', 'Evonimo giapponese'),
  ('fico-di-mare', '', 'Fico degli Ottentotti'),
  ('ficus-ginseng', 'Fico bonsai | Ficus | Salvo | Fico della capretta', 'Fico bonsai | Ficus | Salvo | Fico della capretta | Ficus a frutti piccoli'),
  ('fragaria-moschata', '', 'Fragolina muschiata'),
  ('geranio-parigino', '', 'Geranio edera'),
  ('hydrocotyle-ranunculoides', '', 'Idrocotile ranunculoide'),
  ('ixora', 'Buvardia', 'Buvardia | Fiamma della giungla'),
  ('kalanchoe', '', 'Calandiva'),
  ('lavanda', '', 'Lavanda officinale'),
  ('linnaea-borealis', '', 'Linnaea'),
  ('linum-grandiflorum', '', 'Lino a fiori grandi'),
  ('melilotus-officinalis', '', 'Meliloto comune'),
  ('origano', '', 'Origano comune'),
  ('panicum-virgatum', '', 'Panico verga'),
  ('passiflora', '', 'Fiore della passione'),
  ('potentilla-erecta', 'Cinquefoglie tormentilla | Tormentilla', 'Cinquefoglie tormentilla | Tormentilla | Cinquefoglia eretta'),
  ('primula', '', 'Primula comune'),
  ('rubus-bifrons', '', 'Rovo bifronte'),
  ('ruta', '', 'Ruta comune'),
  ('sansevieria', '', 'Sanseveria'),
  ('saponaria', '', 'Saponaria di roccia'),
  ('scirpus-sylvaticus', '', 'Lisca delle selve'),
  ('soldanella-alpina', '', 'Soldanella'),
  ('timo-serpillo', '', 'Serpillo'),
  ('ulivo', '', 'Olivo'),
  ('vicia-monantha', '', 'Veccia articolata'),
  ('violaciocca', '', 'Violaciocca rossa'),
  ('woodsia-alpina', '', 'Felce alpina'),
  ('zucca', '', 'Zucca moscata'),
  ('zucchina', '', 'Zucca e Zucchina')
)
update specie s set nomi_alternativi = nullif(v.alt_vecchi,'') from v
where s.slug = v.slug and s.nomi_alternativi = v.alt_nuovi;
