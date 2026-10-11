"""Lotto 12: le 136 madri del lotto 2 senza conferma di una seconda fonte, approvate dall'utente dopo revisione.

Input: dati/madri_lotto2_136_approvate.csv (nome_attuale_plantnet = nome approvato; 5 nomi corretti a mano
dall'utente rispetto a PlantNet: deroga al criterio "nome iNaturalist, altrimenti scientifico") e
out/madri_lotto2_136.csv (nomi PlantNet originali). One-shot: legge lo stato del database di quel momento.
Passi: (1) nome della madre aggiornato dove l'utente lo ha corretto; (2) cultivar "<scientifico> 'Epiteto'" col nome della madre.
"""
import csv
import os
import subprocess

from genera_lotto3 import QUI, OUT
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261011110000_nomi_italiani_lotto12.sql"
ROLLBACK = QUI / "rollback_lotto12.sql"


def psql(q):
    url = os.environ.get("DATABASE_URL") or [l.split("=", 1)[1].strip().strip('"')
        for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]
    return subprocess.run(["psql", url, "-At", "-F", "\t", "-c", q], capture_output=True, text=True, check=True).stdout


def main():
    nuovi = {r["slug"]: r["nome_attuale_plantnet"] for r in csv.DictReader(open(QUI / "dati" / "madri_lotto2_136_approvate.csv", encoding="utf-8-sig"))}
    vecchi = {r["slug"]: r["nome_attuale_plantnet"] for r in csv.DictReader(open(OUT / "madri_lotto2_136.csv", encoding="utf-8"))}
    assert set(nuovi) == set(vecchi) and len(nuovi) == 136
    slugs = ",".join(sql_str(s) for s in nuovi)
    db = {r.split("\t")[0]: r.split("\t")[1] for r in psql(f"select slug, nome from specie where slug in ({slugs})").splitlines()}
    assert set(db) == set(nuovi), set(nuovi) - set(db)
    assert all(db[s] == vecchi[s] for s in nuovi), [s for s in nuovi if db[s] != vecchi[s]]
    cambi = [(s, vecchi[s], nuovi[s]) for s in nuovi if nuovi[s] != vecchi[s]]
    assert len(cambi) == 5
    in_uso = {r for r in psql("select nome from specie").splitlines()}
    for s, v, n in cambi:
        assert n not in in_uso, ("nome già in uso", n)

    elenco = ",\n    ".join(f"'{s}'" for s in sorted(nuovi))
    vals = ",\n  ".join(f"({sql_str(s)}, {sql_str(v)}, {sql_str(n)})" for s, v, n in cambi)
    nuovo = "p.nome || ' ' || substr(c.nome, length(p.nome_scientifico) + 2)"
    MIGRATION.write_text(
        "-- Lotto 12: le 136 madri del lotto 2 senza conferma di una seconda fonte, approvate dall'utente.\n"
        "-- (1) 5 madri cambiano nome (correzioni dell'utente); (2) le loro cultivar prendono il nome della madre.\n"
        "-- Rollback: scripts/nomi-italiani/rollback_lotto12.sql\n"
        "with v(slug, vecchio, nuovo) as (values\n  " + vals + "\n)\n"
        "update specie s set nome = v.nuovo from v\n"
        "where s.slug = v.slug and s.specie_padre_id is null and s.nome = v.vecchio\n"
        "  and not exists (select 1 from specie o where o.nome = v.nuovo);\n\n"
        "update specie c set nome = " + nuovo + "\n"
        "from specie p\n"
        "where p.id = c.specie_padre_id\n"
        "  and p.nome <> p.nome_scientifico\n"
        "  and c.nome = c.nome_scientifico\n"
        "  and left(c.nome, length(p.nome_scientifico) + 1) = p.nome_scientifico || ' '\n"
        "  and substr(c.nome, length(p.nome_scientifico) + 2) ~ '^''[^'']+''$'\n"
        "  and p.slug in (\n    " + elenco + "\n  )\n"
        "  and not exists (select 1 from specie o where o.nome = " + nuovo + ");\n", encoding="utf-8")
    vals_rb = ",\n  ".join(f"({sql_str(s)}, {sql_str(v)}, {sql_str(n)})" for s, v, n in cambi)
    ROLLBACK.write_text(
        "-- Rollback lotto 12: le cultivar delle 136 madri tornano al nome scientifico, le 5 madri al nome PlantNet.\n"
        "update specie c set nome = c.nome_scientifico from specie p\n"
        "where p.id = c.specie_padre_id and c.nome <> c.nome_scientifico and p.slug in (\n    " + elenco + "\n  );\n\n"
        "with v(slug, vecchio, nuovo) as (values\n  " + vals_rb + "\n)\n"
        "update specie s set nome = v.vecchio from v where s.slug = v.slug and s.nome = v.nuovo;\n", encoding="utf-8")
    print(len(nuovi), "madri;", len(cambi), "rinominate:", [(s, n) for s, _, n in cambi])


if __name__ == "__main__":
    main()
