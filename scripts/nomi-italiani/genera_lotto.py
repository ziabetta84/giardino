"""Genera la migration dei nomi italiani (lotto 1) dalle righe lette dal DB.

Uso (dalla radice del repo):
    python3 scripts/nomi-italiani/genera_lotto.py

Input (in scripts/nomi-italiani/out/):
- proposte.csv: nome_scientifico, nuovo_nome, criterio (da Wikidata)
- r*.txt: righe del DB con nome scientifico presente in proposte.csv, una per
  riga nel formato `slug|nome_scientifico|curata` (curata = 1 se nome <> nome_scientifico)

Nota: out/r*.txt e proposte.csv sono git-ignored; i dump r*.txt sono stati trascritti a mano
da query SELECT sul DB, quindi l'artefatto riproducibile e' la migration SQL committata,
non questo script.

Output:
- out/righe_db.json, out/righe_curate.json (intermedi)
- supabase/migrations/20261004120000_nomi_italiani_lotto1.sql
- rollback_lotto1.sql (tracciato, con guardia sul nome)
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

# Slug esclusi dal lotto: nomi sbagliati o dubbi emersi dalla revisione.
# Restano con il nome scientifico.
ESCLUSI = {
    "argyranthemum", "lonicera", "actaea-spicata", "encephalartos-villosus",
    "fritillaria", "dianthus", "anacardium-occidentale", "althaea-officinalis",
    "mentha-spicata", "vincetoxicum-hirundinaria", "pistacia-vera",
    "helianthus-tuberosus", "ribes-alpinum",
    "fritillaria-affinis", "lavandula-dentata", "geranium-asphodeloides",
    "abies-bracteata", "chenopodium-opulifolium", "echinops-ritro", "rosa-canina",
    "acer-opalus", "geranium-phaeum", "geranium-pusillum", "campanula-medium",
    "carduus-nutans",
    # Seconda revisione: "Oppio" e' Acer campestre (sarebbe "Viburno oppio"); "Mella bianca"
    # e' un nome dialettale (standard "Storace"); gli ultimi cinque per prudenza (bassa fiducia):
    # acer-saccharinum si confonde con A. saccharum, "Banyan" e' un prestito inglese.
    "viburnum-opulus", "styrax-officinalis", "cirsium-heterophyllum", "galeopsis-ladanum",
    "galium-mollugo", "acer-saccharinum", "ficus-benghalensis",
}

# Solo correzioni di formato del testo Wikidata (maiuscole, accenti, primo di "X o Y"),
# mai nomi nuovi. slug -> (nome attuale della proposta, nome finale).
NORMALIZZAZIONI = {
    "arabidopsis-thaliana": ("Arabetta Comune", "Arabetta comune"),
    "fagopyrum-esculentum": ("Grano Saraceno", "Grano saraceno"),
    "mirabilis-jalapa": ("Bella di Notte", "Bella di notte"),
    "euphorbia-amygdaloides": ("Euforbia delle Faggete", "Euforbia delle faggete"),
    "echinocactus-grusonii": ("Cuscino della Suocera", "Cuscino della suocera"),
    "ophrys-tenthredinifera": ("Ofride fior di Vespa", "Ofride fior di vespa"),
    "carpinus": ("Càrpino", "Carpino"),
    "lamium-purpureum": ("Làmio porporino", "Lamio porporino"),
    "artemisia-dracunculus": ("Dragoncello o estragone", "Dragoncello"),
    "carthamus-tinctorius": ("Cartamo o zafferanone", "Cartamo"),
}

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
presenti = {s for s, _ in coppie}
assert ESCLUSI <= presenti, f"ESCLUSI non presenti: {ESCLUSI - presenti}"
coppie = [c for c in coppie if c[0] not in ESCLUSI]
_nomi = dict(coppie)
for _slug, (_vecchio, _nuovo) in NORMALIZZAZIONI.items():
    assert _slug in _nomi, f"normalizzazione per slug assente: {_slug}"
    assert _nomi[_slug] == _vecchio, f"normalizzazione obsoleta {_slug}: {_nomi[_slug]!r} != {_vecchio!r}"
coppie = [(s, NORMALIZZAZIONI[s][1] if s in NORMALIZZAZIONI else n) for s, n in coppie]

print(f"righe DB: {len(righe)} (curate: {len(curate)})")
print(f"coppie: {len(coppie)}; omonimi saltati: {len(saltati)}; scartate perche' curate: {scartate}")
print("omonimi:", saltati)

if not coppie:
    sys.exit("Nessuna coppia: migration non generata")

up, down = genera_migration(coppie, "lotto1")
intestazione = (
    "-- Rollback: scripts/nomi-italiani/rollback_lotto1.sql (stessa lista VALUES, ripristina\n"
    "-- nome = nome_scientifico solo dove nome e' ancora quello impostato qui).\n"
    f"-- Omonimi saltati ({len(saltati)}), per nome scientifico: {', '.join(saltati)}.\n"
    f"-- Slug esclusi dopo la revisione (nomi sbagliati o dubbi): {len(ESCLUSI)}.\n"
)
up = intestazione + up
open(MIGRATION, "w", encoding="utf-8").write(up)
open(os.path.join(BASE, "rollback_lotto1.sql"), "w", encoding="utf-8").write(down)
json.dump(coppie, open(os.path.join(OUT, "coppie_lotto1.json"), "w"), ensure_ascii=False)
