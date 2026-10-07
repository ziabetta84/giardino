-- Lotto 9: cultivar delle 55 madri del lotto 2 confermate da GBIF prendono il nome italiano della madre.
-- Rollback: scripts/nomi-italiani/rollback_lotto9.sql
update specie c set nome = p.nome || ' ' || substr(c.nome, length(p.nome_scientifico) + 2)
from specie p
where p.id = c.specie_padre_id
  and p.nome <> p.nome_scientifico
  and c.nome = c.nome_scientifico
  and left(c.nome, length(p.nome_scientifico) + 1) = p.nome_scientifico || ' '
  and substr(c.nome, length(p.nome_scientifico) + 2) ~ '^''[^'']+''$'
  and p.slug in (
    'abies-fraseri',
    'andromeda-polifolia',
    'androsace-septentrionalis',
    'betula-medwediewii',
    'betula-nana',
    'bupleurum-longifolium',
    'cephalaria-alpina',
    'cephalaria-gigantea',
    'cirsium-rivulare',
    'clematis-tangutica',
    'cotinus-obovatus',
    'cotoneaster-adpressus',
    'cotoneaster-bullatus',
    'cylindropuntia-imbricata',
    'dioscorea-japonica',
    'geranium-asphodeloides',
    'geranium-bohemicum',
    'helianthus-decapetalus',
    'hydrocotyle-sibthorpioides',
    'iberis-amara',
    'juniperus-scopulorum',
    'larix-occidentalis',
    'larix-sibirica',
    'malva-alcea',
    'malva-verticillata',
    'oenanthe-javanica',
    'pennisetum-setaceum',
    'pentaglottis-sempervirens',
    'persicaria-orientalis',
    'pieris-japonica',
    'pinus-aristata',
    'pinus-banksiana',
    'pinus-contorta',
    'pinus-flexilis',
    'pinus-koraiensis',
    'pinus-lambertiana',
    'pinus-monticola',
    'pinus-muricata',
    'polygala-calcarea',
    'rosa-multiflora',
    'rosa-rugosa',
    'rubus-laciniatus',
    'rubus-odoratus',
    'salix-myrtilloides',
    'sarracenia-purpurea',
    'saururus-cernuus',
    'scilla-forbesii',
    'solidago-nemoralis',
    'ulmus-americana',
    'veronica-austriaca',
    'veronica-prostrata',
    'viola-cucullata',
    'waldsteinia-geoides',
    'waldsteinia-ternata',
    'zelkova-sicula'
  )
  and not exists (select 1 from specie o where o.nome = p.nome || ' ' || substr(c.nome, length(p.nome_scientifico) + 2));
