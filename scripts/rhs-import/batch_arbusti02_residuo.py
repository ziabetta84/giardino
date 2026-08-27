import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from genera_sql import gen_block

# The 20 pairs from batch_arbusti01.py that never actually got applied on
# 2026-08-27 (a hand-typed, unguarded UPDATE statement broke the submission
# partway through and corrupted the whole table -- see
# 20260827040000_repair_incident_stato_verifica.sql for the cleanup). Redone
# here the safe way: this script's stdout is read back verbatim and applied
# without manual retyping.
PAIRS = [
    ("Amelanchier laevis", "amelanchier-laevis"),
    ("Amelanchier lamarckii", "amelanchier-lamarckii"),
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

header = """-- Fase 5, RHS varieta, batch arbusti 02 (residuo): le 20 specie del
-- batch arbusti 01 che non avevano ricevuto il contenuto RHS reale a causa
-- dell'incidente del 2026-08-27 (query troncata durante la trascrizione
-- manuale). Stessa pipeline/convenzioni delle Fase 5 originale. Sinonimo:
-- "Vesalea floribunda" e' il nome oggi accettato da RHS per Kolkwitzia
-- amabilis (gia' in catalogo con questo nome).

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
