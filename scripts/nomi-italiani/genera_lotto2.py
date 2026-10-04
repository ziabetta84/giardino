"""Genera la migration del lotto 2 (nomi italiani da PlantNet, specie con un solo nome).

Legge out/abbinate.txt (slug|nome|nome_scientifico, prodotto da prepara_dry_run.py +
esporta_*.sql, già privo di collisioni con il catalogo e di omonimi scientifici),
applica ESCLUSI e NORMALIZZAZIONI e scrive la migration + il rollback guardato.
"""
from pathlib import Path

from nomi import genera_migration

QUI = Path(__file__).parent
OUT = QUI / "out"
MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261004130000_nomi_italiani_lotto2.sql"
ROLLBACK = QUI / "rollback_lotto2.sql"

# Revisione manuale dei 1.234 abbinamenti: nomi che sono in realtà un altro taxon o una
# cultivar, in lingua straniera, refusi, troppo generici (il nome del genere) o dubbi.
ESCLUSI = set("""
abies-recurvata acalypha-wilkesiana acanthus-hungaricus acer-x-freemanii acis-autumnalis
actinidia-polygama adromischus-cooperi adromischus-cristatus agave-salmiana aglaonema-modestum
alocasia-micholitziana aloe-humilis aloe-perfoliata aloe-rauhii aloiampelos-striatula
ambrosia-trifida amsinckia-lycopsoides anemone-blanda anthurium-crystallinum aphelandra-squarrosa
archontophoenix-alexandrae artemisia-cina artemisia-ludoviciana artemisia-schmidtiana
asparagus-asparagoides astrophytum-capricorne astrophytum-ornatum begonia-maculata begonia-rex
betonica-hirsuta bombax-ceiba brachychiton-acerifolius brunfelsia-pauciflora bursera-simaruba
callirhoe-involucrata callisia-repens campanula-rotundifolia carpesium-abrotanoides
cercis-griffithii cereus-hildmannianus cereus-repandus clematis-virginiana cleome-houtteana
x-fatshedera-lizei cobaea-scandens coleus-caninus cotoneaster-x-suecicus crataegus-orientalis
crinum-bulbispermum crinum-moorei crocus-x-luteus ctenanthe-lubbersiana cyrtanthus-elatus
dactylorhiza-elata daphne-tangutica dasylirion-serratifolium davallia-canariensis
delosperma-echinatum dendrobium-anosmum desmodium-triflorum diascia-rigescens dietes-bicolor
dietes-grandiflora digitalis-minor dioscorea-alata dodonaea-viscosa dracaena-surculosa
dryopteris-oreades dudleya-edulis durio-zibethinus echeveria-colorata echeveria-elegans
echeveria-secunda elsholtzia-ciliata embothrium-coccineum encephalartos-villosus
eschscholzia-caespitosa eucharis-amazonica euphorbia-meloformis euphorbia-tithymaloides
exochorda-racemosa faucaria-tigrina ferocactus-glaucescens festuca-gautieri ficus-cyathistipula
fragaria-chiloensis gasteria-carinata geranium-phaeum geranium-renardii glandora-prostrata
goeppertia-kegeljanii goeppertia-lietzei goeppertia-louisae gunnera-magellanica gunnera-tinctoria
gymnocalycium-baldianum gymnocalycium-pflanzii gymnocladus-dioica haemanthus-coccineus
hatiora-salicornioides haworthia-retusa helichrysum-arenarium heracleum-sosnowskyi
homalanthus-populifolius hosta-lancifolia hylocereus-undatus hylotelephium-sieboldii
iris-ensata iris-lactea justicia-brandegeeana kleinia-neriifolia leucanthemum-graminifolium
leucophyta-brownii lithops-pseudotruncatella lysichiton-americanus mammillaria-bombycina
mammillaria-prolifera mollugo-verticillata monstera-standleyana morisia-monanthos
muntingia-calabura murraya-koenigii myoporum-tetrandrum myriophyllum-heterophyllum
narcissus-triandrus nassella-trichotoma nepenthes-alata nothofagus-antarctica
pachycereus-pringlei pandanus-tectorius papaver-setiferum passiflora-alata peltandra-virginica
peperomia-polybotrya philadelphus-inodorus philadelphus-lewisii philodendron-hastatum
philodendron-xanadu phytolacca-esculenta pinus-longaeva pleioblastus-viridistriatus
podocarpus-neriifolius polyscias-guilfoylei populus-euphratica populus-simonii prunus-americana
prunus-salicina prunus-triloba psidium-cattleianum quercus-rysophylla rauvolfia-serpentina
rebutia-canigueralii rhododendron-catawbiense rhodotypos-scandens roldana-petasitis
rosa-centifolia rosa-moyesii rosa-villosa salix-discolor salix-myrsinites salvia-lanigera
salvia-mellifera salvia-verticillata sambucus-mexicana sanvitalia-procumbens
sarracenia-oreophila sauromatum-venosum saxifraga-hypnoides scaevola-aemula
schizanthus-pinnatus sedum-adolphi sedum-anglicum sedum-makinoi sedum-spathulifolium
sempervivum-ciliosum sideritis-syriaca solanum-quitoense solanum-torvum
sphagneticola-trilobata spiraea-thunbergii spondias-purpurea stapelia-gigantea
streptopus-amplexifolius symphyotrichum-laeve tagetes-tenuifolia teucrium-hircanicum
thalia-dealbata thalictrum-delavayi thymus-pulegioides tilia-x-euchlora tillandsia-stricta
trifolium-ochroleucon trollius-asiaticus tropaeolum-tuberosum tulipa-kaufmanniana ulmus-alata
vanda-insignis vatricania-guentheri vitis-amurensis vitis-californica zanthoxylum-americanum
""".split())

# Correzioni di formato (maiuscole, refusi, preposizioni articolate).
NORMALIZZAZIONI = {
    "acer-truncatum": "Acero troncato",
    "aesculus-chinensis": "Ippocastano cinese",
    "aesculus-parviflora": "Ippocastano a fiori piccoli",
    "aesculus-sylvatica": "Ippocastano della Carolina",
    "aloe-striata": "Aloe corallo",
    "aspalathus-linearis": "Tè rosso del Sudafrica",
    "carpobrotus-glaucescens": "Unghie di strega",
    "cassia-grandis": "Cassia a grandi frutti",
    "casimiroa-edulis": "Sapote bianco",
    "ceanothus-thyrsiflorus": "Lillà californiano",
    "commelina-virginica": "Erba miseria americana",
    "doronicum-austriacum": "Doronico austriaco",
    "eragrostis-spectabilis": "Erba dell'amore",
    "euonymus-alatus": "Evonimo alato",
    "ferocactus-pilosus": "Barile di fuoco messicano",
    "fraxinus-velutina": "Frassino dell'Arizona",
    "gleditsia-japonica": "Gleditsia giapponese",
    "hoya-australis": "Pianta di cera",
    "ilex-crenata": "Agrifoglio giapponese",
    "lycoris-radiata": "Giglio ragno rosso",
    "mentha-x-villosa": "Menta pelosa",
    "monotropa-uniflora": "Fiore fantasma",
    "oreomecon-alpina": "Papavero alpino",
    "panax-quinquefolius": "Ginseng americano",
    "picea-likiangensis": "Abete di Likiang",
    "pinus-ayacahuite": "Pino bianco del Messico",
    "prunus-davidiana": "Pesco di David",
    "prunus-sargentii": "Ciliegio di Sargent",
    "vachellia-seyal": "Acacia seyal",
    "vigna-radiata": "Fagiolo mungo",
    "zelkova-sicula": "Zelkova siciliana",
}

def main():
    righe = [r.split("|") for r in (OUT / "abbinate.txt").read_text(encoding="utf-8").splitlines() if r.strip()]
    presenti = {s for s, _, _ in righe}
    assert ESCLUSI <= presenti, f"ESCLUSI non presenti: {sorted(ESCLUSI - presenti)}"
    assert set(NORMALIZZAZIONI) <= presenti - ESCLUSI, "NORMALIZZAZIONI su slug assenti o esclusi"

    coppie = sorted((s, NORMALIZZAZIONI.get(s, n)) for s, n, _ in righe if s not in ESCLUSI)
    chiavi = [n.lower() for _, n in coppie]
    doppi = sorted({n for n in chiavi if chiavi.count(n) > 1})
    assert not doppi, f"nomi duplicati (violerebbero specie_nome_key): {doppi}"

    up, down = genera_migration(coppie, "lotto2")
    intestazione = (
        f"-- Lotto 2: {len(coppie)} nomi italiani da PlantNet (specie con un solo nome comune italiano).\n"
        f"-- Abbinati per nome scientifico; {len(ESCLUSI)} abbinamenti scartati dopo revisione manuale\n"
        "-- (altro taxon, cultivar, lingua straniera, refusi, troppo generici).\n"
        "-- Controllato prima dell'apply: nessuna collisione con specie_nome_key.\n"
    )
    MIGRATION.write_text(intestazione + up.replace("(lotto2): sostituisce nome con il nome comune italiano da Wikidata", "(lotto2)"), encoding="utf-8")
    ROLLBACK.write_text(down, encoding="utf-8")
    print(len(righe), "abbinati,", len(ESCLUSI), "esclusi,", len(NORMALIZZAZIONI), "normalizzati ->", len(coppie), "coppie")


if __name__ == "__main__":
    main()
