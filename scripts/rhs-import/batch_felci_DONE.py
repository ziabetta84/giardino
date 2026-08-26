import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from genera_sql import gen_block

# (nome RHS, slug esistente in specie)
PAIRS = [
    ("Adiantum capillus-veneris", "adiantum-capillus-veneris"),
    ("Adiantum hispidulum", "adiantum-hispidulum"),
    ("Adiantum pedatum", "adiantum-pedatum"),
    ("Adiantum peruvianum", "adiantum-peruvianum"),
    ("Adiantum raddianum", "adiantum-raddianum"),
    ("Adiantum tenerum", "adiantum-tenerum"),
    ("Adiantum venustum", "adiantum-venustum"),
    ("Asplenium adiantum-nigrum", "asplenium-adiantum-nigrum"),
    ("Asplenium antiquum", "asplenium-antiquum"),
    ("Asplenium ceterach", "asplenium-ceterach"),
    ("Asplenium daucifolium", "asplenium-daucifolium"),
    ("Asplenium marinum", "asplenium-marinum"),
    ("Asplenium ruta-muraria", "asplenium-ruta-muraria"),
    ("Asplenium scolopendrium", "asplenium-scolopendrium"),
    ("Asplenium septentrionale", "asplenium-septentrionale"),
    ("Asplenium trichomanes", "asplenium-trichomanes"),
    ("Asplenium viride", "asplenium-viride"),
    ("Athyrium distentifolium", "athyrium-distentifolium"),
    ("Athyrium filix-femina", "athyrium-filix-femina"),
    ("Blechnum brasiliense", "blechnum-brasiliense"),
    ("Blechnum gibbum", "blechnum-gibbum"),
    ("Blechnum penna-marina", "blechnum-penna-marina"),
    ("Blechnum spicant", "blechnum-spicant"),
    ("Cheilanthes lanosa", "cheilanthes-lanosa"),
    ("Cibotium barometz", "cibotium-barometz"),
    ("Cibotium glaucum", "cibotium-glaucum"),
    ("Cibotium schiedei", "cibotium-schiedei"),
    ("Alsophila australis", "cyathea-australis"),
    ("Alsophila tricolor", "cyathea-dealbata"),
    ("Sphaeropteris cooperi", "cyathea-cooperi"),
    ("Sphaeropteris medullaris", "cyathea-medullaris"),
    ("Cyrtomium falcatum", "cyrtomium-falcatum"),
    ("Cyrtomium fortunei", "cyrtomium-fortunei"),
    ("Cystopteris dickieana", "cystopteris-dickiana"),
    ("Cystopteris fragilis", "cystopteris-fragilis"),
    ("Davallia canariensis", "davallia-canariensis"),
    ("Davallia mariesii", "davallia-mariesii"),
    ("Dennstaedtia punctilobula", "dennstaedtia-punctilobula"),
    ("Dicksonia antarctica", "dicksonia-antarctica"),
    ("Dicksonia fibrosa", "dicksonia-fibrosa"),
    ("Dicksonia squarrosa", "dicksonia-squarrosa"),
    ("Didymochlaena truncatula", "didymochlaena-truncatula"),
    ("Doryopteris nobilis", "doryopteris-nobilis"),
    ("Doryopteris pedata", "doryopteris-pedata"),
    ("Dryopteris carthusiana", "dryopteris-carthusiana"),
    ("Dryopteris cristata", "dryopteris-cristata"),
    ("Dryopteris dilatata", "dryopteris-dilatata"),
    ("Dryopteris filix-mas", "dryopteris-filix-mas"),
    ("Dryopteris pseudomas", "dryopteris-pseudomas"),
    ("Gymnocarpium dryopteris", "gymnocarpium-dryopteris"),
    ("Gymnocarpium robertianum", "gymnocarpium-robertianum"),
    ("Humata tyermanii", "humata-tyermannii"),
    ("Matteuccia orientalis", "matteuccia-orientalis"),
    ("Matteuccia pensylvanica", "matteuccia-pensylvanica"),
    ("Matteuccia struthiopteris", "matteuccia-struthiopteris"),
    ("Microlepia speluncae", "microlepia-speluncae"),
    ("Nephrolepis cordifolia", "nephrolepis-cordifolia"),
    ("Nephrolepis duffii", "nephrolepis-duffii"),
    ("Onoclea sensibilis", "onoclea-sensibilis"),
    ("Osmunda cinnamomea", "osmunda-cinnamomea"),
    ("Osmunda claytoniana", "osmunda-claytoniana"),
    ("Osmunda regalis", "osmunda-regalis"),
    ("Pellaea atropurpurea", "pellaea-atropurpurea"),
    ("Pellaea falcata", "pellaea-falcata"),
    ("Pellaea rotundifolia", "pellaea-rotundifolia"),
    ("Pellaea viridis", "pellaea-viridis"),
    ("Phlebodium aureum", "phlebodium-aureum"),
    ("Pilularia globulifera", "pilularia-globulifera"),
    ("Pilularia minuta", "pilularia-minuta"),
    ("Platycerium grande", "platycerium-grande"),
    ("Niphidium crassifolium", "polypodium-crassifolium"),
    ("Polypodium interjectum", "polypodium-interjectum"),
    ("Goniophlebium subauriculatum", "polypodium-subauriculatum"),
    ("Polypodium vulgare", "polypodium-vulgare"),
    ("Polystichum acrostichoides", "polystichum-acrostichoides"),
    ("Polystichum aculeatum", "polystichum-aculeatum"),
    ("Polystichum lonchitis", "polystichum-lonchitis"),
    ("Polystichum makinoi", "polystichum-makinoi"),
    ("Polystichum munitum", "polystichum-munitum"),
    ("Polystichum setiferum", "polystichum-setiferum"),
    ("Polystichum tsussimense", "polystichum-tsus-sinense"),
    ("Pteridium aquilinum", "pteridium-aquilinum"),
    ("Pteris cretica", "pteris-cretica"),
    ("Pteris ensiformis", "pteris-ensiformis"),
    ("Pteris multifida", "pteris-multifida"),
    ("Pteris quadriaurita", "pteris-quadriaurita"),
    ("Pteris tremula", "pteris-tremula"),
    ("Salvinia auriculata", "salvinia-auriculata"),
    ("Phegopteris hexagonoptera", "thelypteris-hexagonoptera"),
    ("Parathelypteris novae-boracensis", "thelypteris-noveboracensis"),
    ("Oreopteris limbosperma", "thelypteris-oreopteris"),
    ("Thelypteris palustris", "thelypteris-palustris"),
    ("Phegopteris connectilis", "thelypteris-phegopteris"),
    ("Woodsia alpina", "woodsia-alpina"),
    ("Woodsia ilvensis", "woodsia-ilvensis"),
    ("Woodsia obtusa", "woodsia-obtusa"),
    ("Woodsia scopulina", "woodsia-scopulina"),
    ("Woodwardia areolata", "woodwardia-areolata"),
    ("Woodwardia fimbriata", "woodwardia-fimbriata"),
    ("Woodwardia radicans", "woodwardia-radicans"),
    ("Woodwardia virginica", "woodwardia-virginica"),
]

header = """-- RHS Fase 5, batch 01: felci (Adiantum, Asplenium, Athyrium, Blechnum,
-- Cheilanthes, Cibotium, Cyathea, Cyrtomium, Cystopteris, Davallia,
-- Dennstaedtia, Dicksonia, Didymochlaena, Doryopteris, Dryopteris,
-- Gymnocarpium, Humata, Matteuccia, Microlepia, Nephrolepis, Onoclea,
-- Osmunda, Pellaea, Phlebodium, Pilularia, Platycerium, Polypodium,
-- Polystichum, Pteridium, Pteris, Salvinia, Thelypteris, Woodsia,
-- Woodwardia). Fonte: RHS (rhs.org.uk), 1211 pagine scaricate localmente
-- dall'utente in fonti/rhs-varieta/ (specie + tutte le cultivar reperibili),
-- poi estratte con script Python (parse_rhs.py + aggregate_rhs.py) che
-- isola i campi strutturati (Position/Soil/Moisture/pH/Hardiness/Max
-- Height/Spread) e le sezioni di testo libero (Cultivation, Propagation,
-- Pruning, Pests, Diseases) di ogni pagina RHS.
--
-- Decisioni applicate (concordate con l'utente):
-- - Granularita' riga: SOLO la specie base riceve/arricchisce una riga;
--   le cultivar (fino a 127 per una singola specie, es. Acer palmatum in
--   batch successivi) sono riassunte in descrizione (conteggio, range di
--   altezza/diffusione, nomi di esempio), non una riga per cultivar.
-- - Testo libero RHS (descrizione, parassiti, malattie, potatura,
--   propagazione) tenuto in inglese originale e marcato come tale in
--   alert/descrizione, stessa convenzione gia' usata per i rischi PFAF:
--   evita il rischio di traduzione errata su migliaia di frasi.
-- - Campi strutturati (posizione/luce, suolo, pH, umidita') tradotti in
--   italiano e scritti in esigenze (merge non distruttivo: i valori PFAF
--   gia' presenti vincono in caso di conflitto di chiave).
-- - RHS e' fonte primaria (regola 3 del criterio di importazione): ogni
--   riga arricchita in questo batch passa a stato_verifica='verificato'.
-- - Sinonimi RHS diversi dal nome gia' in catalogo (es. Alsophila
--   australis = Cyathea australis, Sphaeropteris cooperi = Cyathea
--   cooperi, Goniophlebium/Niphidium = Polypodium, Phegopteris/
--   Parathelypteris/Oreopteris = Thelypteris, Humata tyermanii = tyermannii)
--   mappati manualmente verificando la corrispondenza in query preliminari.

"""

blocks = [header]
missing = []
for rhs_name, slug in PAIRS:
    b = gen_block(rhs_name, slug)
    if not b:
        missing.append((rhs_name, slug))
        continue
    blocks.append(b)

print("\n".join(blocks))
if missing:
    import sys as _s
    print("\n\n-- MANCANTI:", missing, file=_s.stderr)
