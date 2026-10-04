"""Genera la migration dei nomi italiani (lotto 1) dalle righe lette dal DB.

Uso (dalla radice del repo):
    python3 scripts/nomi-italiani/genera_lotto.py

Input (in scripts/nomi-italiani/out/):
- proposte.csv: nome_scientifico, nuovo_nome, criterio (da Wikidata)
- r*.txt: righe del DB con nome scientifico presente in proposte.csv, una per
  riga nel formato `slug|nome_scientifico|curata` (curata = 1 se nome <> nome_scientifico)

Output:
- out/righe_db.json, out/righe_curate.json (intermedi)
- supabase/migrations/20261004120000_nomi_italiani_lotto1.sql
- out/rollback_lotto1.sql
"""
import csv
import glob
import json
import os
import sys

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)
from nomi import abbina_slug, genera_migration  # noqa: E402

OUT = os.path.join(BASE, "out")
MIGRATION = os.path.join(BASE, "..", "..", "supabase", "migrations", "20261004120000_nomi_italiani_lotto1.sql")

proposte = {
    r["nome_scientifico"].strip().lower(): r["nuovo_nome"]
    for r in csv.DictReader(open(os.path.join(OUT, "proposte.csv"), encoding="utf-8"))
}

righe, curate = [], set()
for f in sorted(glob.glob(os.path.join(OUT, "r[0-9]*.txt"))):
    for riga in open(f, encoding="utf-8").read().splitlines():
        if not riga.strip():
            continue
        slug, sci, flag = riga.rsplit("|", 2)
        righe.append({"slug": slug, "nome_scientifico": sci})
        if flag == "1":
            curate.add(slug)

json.dump(righe, open(os.path.join(OUT, "righe_db.json"), "w"), ensure_ascii=False, indent=1)
json.dump(sorted(curate), open(os.path.join(OUT, "righe_curate.json"), "w"), ensure_ascii=False, indent=1)

coppie_tutte, saltati = abbina_slug(proposte, righe)
coppie = [c for c in coppie_tutte if c[0] not in curate]
scartate = len(coppie_tutte) - len(coppie)

print(f"righe DB: {len(righe)} (curate: {len(curate)})")
print(f"coppie: {len(coppie)}; omonimi saltati: {len(saltati)}; scartate perche' curate: {scartate}")
print("omonimi:", saltati)

if not coppie:
    sys.exit("Nessuna coppia: migration non generata")

up, down = genera_migration(coppie, "lotto1")
open(MIGRATION, "w", encoding="utf-8").write(up)
open(os.path.join(OUT, "rollback_lotto1.sql"), "w", encoding="utf-8").write(down)
json.dump(coppie, open(os.path.join(OUT, "coppie_lotto1.json"), "w"), ensure_ascii=False)
