-- Toglie 32 doppioni 'bozza' con slug botanico di righe con slug italiano già verificate (senza piante né cultivar).
-- Rollback: scripts/nomi-italiani/rollback_doppioni_slug.sql
update specie a set descrizione = b.descrizione, lingua_descrizione = b.lingua_descrizione
from specie b where a.slug = 'avocado' and b.slug = 'persea-americana'
  and coalesce(a.descrizione, '') = '' and coalesce(b.descrizione, '') <> '';

delete from specie where slug in ('allium-cepa', 'allium-sativum', 'asparagus-officinalis', 'brassica-oleracea', 'camellia-japonica', 'capsicum-annuum', 'cucumis-sativus', 'cucurbita-moschata', 'cucurbita-pepo', 'dendranthema-indicum', 'duchesnea-indica', 'helianthus-annuus', 'lactuca-sativa', 'laurus-nobilis', 'lavandula-angustifolia', 'lobularia-maritima', 'lythrum-salicaria', 'matthiola-incana', 'nertera-granadensis', 'ocimum-basilicum', 'olea-europaea', 'origanum-vulgare', 'persea-americana', 'petroselinum-crispum', 'phaseolus-vulgaris', 'pisum-sativum', 'rosmarinus-officinalis', 'solanum-lycopersicum', 'solanum-melongena', 'solanum-tuberosum', 'spinacia-oleracea', 'zea-mays')
  and stato_verifica = 'bozza' and specie_padre_id is null
  and not exists (select 1 from piante p where p.specie = specie.slug)
  and not exists (select 1 from specie c where c.specie_padre_id = specie.id);
