-- 18 generi risolti su GBIF (genere vegetale con più di una specie accettata): dati GBIF in `generi` e righe 'Genere spp.'.
-- Rollback: scripts/nomi-italiani/rollback_generi_risolti.sql
update generi g set gbif_key = v.k, specie_gbif = v.n, gbif_rilevato_il = date '2026-10-11'
from (values
  ('Artemisia', 3120641, 573),
  ('Calceolaria', 3172125, 308),
  ('Callisia', 2763692, 42),
  ('Cryptanthus', 2694346, 76),
  ('Euphorbia', 11397237, 2351),
  ('Fittonia', 3233835, 2),
  ('Goeppertia', 7304686, 247),
  ('Hedera', 3036021, 51),
  ('Helleborus', 2741682, 28),
  ('Hepatica', 3033655, 12),
  ('Hosta', 9342215, 27),
  ('Kniphofia', 2780618, 79),
  ('Nematanthus', 3233474, 34),
  ('Roscoea', 2757354, 27),
  ('Schlumbergera', 3084040, 11),
  ('Streptocarpus', 3233500, 209),
  ('Vriesea', 2699764, 308),
  ('Watsonia', 2747139, 64)
) as v(genere, k, n)
where g.nome_scientifico = v.genere and g.gbif_rilevato_il is null;

update specie s set nome_scientifico = v.genere || ' spp.'
from (values
  ('artemisia', 'Artemisia', 'Artemisia'),
  ('calceolaria', 'Calceolaria', 'Calceolaria'),
  ('callisia', 'Callisia', 'Callisia'),
  ('cryptanthus', 'Cryptanthus', 'Cryptanthus'),
  ('euphorbia', 'Euphorbia', 'Euphorbia'),
  ('fittonia', 'Fittonia albivenis', 'Fittonia'),
  ('goeppertia', 'Goeppertia', 'Goeppertia'),
  ('hedera', 'Hedera', 'Hedera'),
  ('helleborus', 'Helleborus niger', 'Helleborus'),
  ('hepatica', 'Hepatica', 'Hepatica'),
  ('hosta', 'Hosta', 'Hosta'),
  ('kniphofia', 'Kniphofia', 'Kniphofia'),
  ('nematanthus', 'Nematanthus', 'Nematanthus'),
  ('roscoea', 'Roscoea', 'Roscoea'),
  ('schlumbergera', 'Schlumbergera', 'Schlumbergera'),
  ('streptocarpus', 'Streptocarpus rexii', 'Streptocarpus'),
  ('vriesea', 'Vriesea splendens', 'Vriesea'),
  ('watsonia', 'Watsonia', 'Watsonia')
) as v(slug, vecchio, genere)
where s.slug = v.slug and s.nome_scientifico = v.vecchio and s.specie_padre_id is null;

update specie set nome = 'Elleboro' where slug = 'helleborus' and nome = 'Elleboro nero'
  and not exists (select 1 from specie o where o.nome = 'Elleboro');
