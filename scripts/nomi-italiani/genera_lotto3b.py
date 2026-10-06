"""Lotto 3b: le specie con nome preferito di iNaturalist diverso da tutti i nomi alternativi (PlantNet).

Qui si segue iNaturalist da solo: `nome` = nome preferito, `nomi_alternativi` resta invariato (i candidati
PlantNet restano ricercabili). Stesse esclusioni del lotto 3: genere, famiglia, nome già in uso o proposto due volte.
"""
import json
from collections import Counter

from genera_lotto3 import OUT, QUI, n, scarto, carica_db
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261006130000_nomi_italiani_lotto3b.sql"
ROLLBACK = QUI / "rollback_lotto3b.sql"


def main():
    alt, esistenti = carica_db()
    scelte, scartate = [], []
    for l in open(OUT / "inat.jsonl", encoding="utf-8"):
        rec = json.loads(l)
        if rec["gruppo"] != "A" or rec["slug"] not in alt or not rec.get("nome_it"):
            continue
        nome = rec["nome_it"][0].upper() + rec["nome_it"][1:]
        if n(nome) in [n(a) for a in alt[rec["slug"]]]:
            continue  # già coperto dal lotto 3
        motivo = scarto(nome, rec["sci"], esistenti)
        (scartate if motivo else scelte).append((rec["slug"], nome, motivo))
    cont = Counter(n(x[1]) for x in scelte)
    dup = [x for x in scelte if cont[n(x[1])] > 1]
    scelte = [x for x in scelte if cont[n(x[1])] == 1]
    for x in scartate + [(s, nm, "proposto due volte") for s, nm, _ in dup]:
        print("scartata:", x)
    valori = ",\n  ".join(f"({sql_str(s)}, {sql_str(nome)})" for s, nome, _ in scelte)
    MIGRATION.write_text(
        f"-- Nomi italiani lotto 3b: {len(scelte)} specie, nome principale = nome preferito di iNaturalist\n"
        "-- (diverso da tutti i nomi alternativi PlantNet, che restano invariati). Solo righe ancora senza nome italiano\n"
        "-- e con nome non già in uso. Rollback: scripts/nomi-italiani/rollback_lotto3b.sql\n"
        "with v(slug, nome) as (values\n  " + valori + "\n)\n"
        "update specie s set nome = v.nome\n"
        "from v\n"
        "where s.slug = v.slug and s.specie_padre_id is null and s.nome = s.nome_scientifico\n"
        "  and not exists (select 1 from specie o where o.nome = v.nome);\n",
        encoding="utf-8")
    rb = ",\n  ".join(f"({sql_str(s)}, {sql_str(nome)})" for s, nome, _ in scelte)
    ROLLBACK.write_text(
        "-- Rollback lotto 3b: ripristina il nome scientifico come nome.\n"
        "with v(slug, nome) as (values\n  " + rb + "\n)\n"
        "update specie s set nome = s.nome_scientifico from v where s.slug = v.slug and s.nome = v.nome;\n",
        encoding="utf-8")
    print(len(scelte), "specie nel lotto 3b")


if __name__ == "__main__":
    main()
