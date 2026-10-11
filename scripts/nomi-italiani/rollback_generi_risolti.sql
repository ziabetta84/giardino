-- Rollback generi risolti su GBIF.
update specie set nome = 'Elleboro nero' where slug = 'helleborus' and nome = 'Elleboro';

update specie s set nome_scientifico = v.vecchio
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
where s.slug = v.slug and s.nome_scientifico = v.genere || ' spp.' and s.specie_padre_id is null;

update generi set gbif_key = null, specie_gbif = null, gbif_rilevato_il = null
where nome_scientifico in ('Artemisia', 'Calceolaria', 'Callisia', 'Cryptanthus', 'Euphorbia', 'Fittonia', 'Goeppertia', 'Hedera', 'Helleborus', 'Hepatica', 'Hosta', 'Kniphofia', 'Nematanthus', 'Roscoea', 'Schlumbergera', 'Streptocarpus', 'Vriesea', 'Watsonia') and gbif_rilevato_il = date '2026-10-11';
