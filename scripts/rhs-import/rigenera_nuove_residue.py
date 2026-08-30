"""
Rigenera i file nuove_008 e nuove_011..017 (i chunk non ancora applicati
dopo l'errore di unique constraint su "nome" incontrato durante l'apply,
vedi issue #153) scartando le righe il cui `nome` collide con una specie
gia' presente nel catalogo -- controllo che genera_sql_sitemaps.py non
faceva perche' il matching originale (aggregate_sitemaps.py) confrontava
solo `nome_scientifico`/slug, non la colonna `nome` (che ha un proprio
UNIQUE constraint e a volte differisce, es. righe di genere con
nome_scientifico vuoto).
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import genera_sql_sitemaps as gss
import genera_sql as gs

CHUNK_SIZE = 400
REMAINING = [8, 11, 12, 13, 14, 15, 16, 17]

nomi_esistenti = set(l.strip() for l in open(os.path.join(HERE, "specie_nomi_esistenti.tsv"), encoding="utf-8"))

data = json.load(open(os.path.join(HERE, "rhs_sitemaps_full_aggregato.json"), encoding="utf-8"))
nuove = [d for d in data if d["stato_match"] == "nuova"]
chunks = [nuove[i:i + CHUNK_SIZE] for i in range(0, len(nuove), CHUNK_SIZE)]

totale_scartate = 0
for idx in REMAINING:
    chunk = chunks[idx - 1]
    tenute, scartate = [], []
    for d in chunk:
        if d["specie_base"] in nomi_esistenti:
            scartate.append(d["specie_base"])
        else:
            tenute.append(d)
    totale_scartate += len(scartate)
    path = os.path.join(HERE, "sql_sitemaps", f"nuove_{idx:03d}.sql")
    with open(path, "w", encoding="utf-8") as out:
        for d in tenute:
            out.write(gss.gen_insert(d))
    print(f"chunk {idx}: {len(chunk)} totali, {len(scartate)} scartate per nome duplicato, {len(tenute)} riscritte")
    if scartate:
        print("   scartate:", ", ".join(scartate))

print(f"\nTotale scartate per collisione su nome: {totale_scartate}")
