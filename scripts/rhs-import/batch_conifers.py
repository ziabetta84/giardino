import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from genera_sql import gen_block

PAIRS = [
    ("Abies alba", "abies-alba"),
    ("Abies balsamea", "abies-balsamea"),
    ("Abies lasiocarpa", "abies-lasiocarpa"),
    ("Cedrus deodara", "cedrus-deodara"),
    ("Larix decidua", "larix-decidua"),
    ("Picea abies", "picea-abies"),
    ("Picea mariana", "picea-mariana"),
    ("Picea pungens", "picea-pungens"),
    ("Picea smithiana", "picea-smithiana"),
    ("Pinus cembra", "pinus-cembra"),
    ("Pinus mugo", "pinus-mugo"),
    ("Pinus nigra", "pinus-nigra"),
    ("Pinus pinaster", "pinus-pinaster"),
    ("Pinus sylvestris", "pinus-sylvestris"),
    ("Pseudotsuga menziesii", "pseudotsuga-menziesii"),
    ("Tsuga canadensis", "tsuga-canadensis"),
    ("Tsuga heterophylla", "tsuga-heterophylla"),
    ("Ginkgo biloba", "ginkgo-biloba"),
    ("Taxus baccata", "taxus-baccata"),
    ("Chamaecyparis lawsoniana", "chamaecyparis-lawsoniana"),
    ("Chamaecyparis obtusa", "chamaecyparis-obtusa"),
    ("Chamaecyparis pisifera", "chamaecyparis-pisifera"),
    ("Chamaecyparis thyoides", "chamaecyparis-thyoides"),
    ("Cryptomeria japonica", "cryptomeria-japonica"),
    ("Cupressus sempervirens", "cupressus-sempervirens"),
    ("Juniperus chinensis", "juniperus-chinensis"),
    ("Juniperus procumbens", "juniperus-procumbens"),
    ("Juniperus recurva", "juniperus-recurva"),
    ("Juniperus sabina", "juniperus-sabina"),
    ("Juniperus squamata", "juniperus-squamata"),
    ("Thuja occidentalis", "thuja-occidentalis"),
    ("Thuja orientalis", "thuja-orientalis"),
    ("Platycladus orientalis", "thuja-orientalis"),
    ("Xanthocyparis nootkatensis", "chamaecyparis-nootkatensis"),
]

header = """-- RHS Fase 5, batch 02: conifere (Abies, Cedrus, Larix, Picea, Pinus,
-- Pseudotsuga, Tsuga, Ginkgo, Taxus, Chamaecyparis, Cryptomeria,
-- Cupressus, Juniperus, Thuja). Stessa pipeline/convenzioni del batch 01
-- (vedi scripts/rhs-import/README.md): testo libero RHS in inglese
-- originale marcato come tale, campi strutturati tradotti in esigenze,
-- stato_verifica='verificato' solo con contenuto specifico sulla specie.
-- Sinonimi: Platycladus orientalis e Xanthocyparis nootkatensis sono i
-- nomi oggi accettati per Thuja orientalis e Chamaecyparis nootkatensis
-- (gia' in catalogo con questi nomi) -- entrambe le pagine RHS scaricate
-- sotto i due nomi vengono quindi appese alla stessa riga, ciascuna con
-- la propria fonte.

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
    print("\n\n-- MANCANTI:", missing, file=sys.stderr)
