import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from genera_sql import gen_block

PAIRS = [
    ("Abelia chinensis", "abelia-chinensis"),
    ("Abelia schumannii", "abelia-schumannii"),
    ("Abelia triflora", "abelia-triflora"),
    ("Abelia × grandiflora", "abelia-x-grandiflora"),
    ("Amelanchier arborea", "amelanchier-arborea"),
    ("Amelanchier canadensis", "amelanchier-canadensis"),
    ("Amelanchier laevis", "amelanchier-laevis"),
    ("Amelanchier lamarckii", "amelanchier-lamarckii"),
    ("Amelanchier ovalis", "amelanchier-ovalis"),
    ("Amorpha canescens", "amorpha-canescens"),
    ("Amorpha fruticosa", "amorpha-fruticosa"),
    ("Aronia arbutifolia", "aronia-arbutifolia"),
    ("Aronia melanocarpa", "aronia-melanocarpa"),
    ("Berberis aggregata", "berberis-aggregata"),
    ("Berberis buxifolia", "berberis-buxifolia"),
    ("Berberis darwinii", "berberis-darwinii"),
    ("Berberis julianae", "berberis-julianae"),
    ("Berberis koreana", "berberis-koreana"),
    ("Berberis linearifolia", "berberis-linearifolia"),
    ("Berberis thunbergii", "berberis-thunbergii"),
    ("Berberis vulgaris", "berberis-vulgaris"),
    ("Berberis × lologensis", "berberis-x-lologensis"),
    ("Berberis × stenophylla", "berberis-x-stenophylla"),
    ("Buddleja alternifolia", "buddleja-alternifolia"),
    ("Buddleja davidii", "buddleja-davidii"),
    ("Buddleja × weyeriana", "buddleja-x-weyeriana"),
    ("Vesalea floribunda", "kolkwitzia-amabilis"),
]

header = """-- Fase 5, RHS varieta, batch arbusti 01: prima parte delle pagine RHS
-- scaricate per le specie importate da "Il giardino di arbusti" (Edicart,
-- 1995) ancora in bozza (fonti/rhs-varieta/, 218 file datati 2026-08-27).
-- Stessa pipeline/convenzioni della Fase 5 originale (vedi
-- scripts/rhs-import/README.md): testo libero RHS in inglese originale
-- marcato come tale, campi strutturati tradotti in esigenze, merge non
-- distruttivo, stato_verifica='verificato' solo con contenuto specifico
-- sulla specie. Copre da Abelia a Buddleja alfabeticamente.
-- Sinonimo: "Vesalea floribunda" e' il nome oggi accettato da RHS per
-- Kolkwitzia amabilis (gia' in catalogo con questo nome) -- la pagina
-- viene appesa alla riga esistente kolkwitzia-amabilis.
-- Abelia floribunda: nessuna pagina RHS scaricata in questo batch, resta
-- bozza in attesa di un download futuro.

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
