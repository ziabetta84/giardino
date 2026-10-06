"""Lotto 4: gruppo B, specie che hanno già un nome italiano diverso dal nome preferito di iNaturalist.

Input: out/inat_gruppoB.json (145 record con `nome_it` diverso da `nome_db`, da scarica_inat.py).
- SOSTITUISCI: il nome attuale è solo il genere in latino (o ha il nome scientifico tra parentesi) e non è
  già un nome italiano d'uso: `nome` diventa il nome iNaturalist, il vecchio nome va in `nomi_alternativi`.
- AGGIUNGI: in tutti gli altri casi `nome` non cambia e il nome iNaturalist si aggiunge a `nomi_alternativi`
  (se non c'è già, in nessuna grafia, e non coincide col nome).
"""
import json
import re
import subprocess
import os
from collections import Counter

from genera_lotto3 import QUI, OUT, SEP, n, scarto
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261006140000_nomi_italiani_lotto4.sql"
ROLLBACK = QUI / "rollback_lotto4.sql"

# Nomi attuali che sono solo il genere in latino (o con parentesi): scelti a mano dall'elenco dei 145.
SOSTITUISCI = {
    "anthurium", "arbutus", "cyclamen", "exacum", "helleborus", "hyacinthus", "hydrangea", "jasminum",
    "zantedeschia", "fatsia-japonica",
}


def maiuscola(s):
    return s[0].upper() + s[1:]


def carica_db():
    url = os.environ.get("DATABASE_URL") or [l.split("=", 1)[1].strip().strip('"')
        for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]
    q = ("select slug, nome, coalesce(nomi_alternativi,'') from specie "
         "where specie_padre_id is null and nome <> nome_scientifico")
    righe = subprocess.run(["psql", url, "-At", "-F", "\t", "-c", q], capture_output=True, text=True,
                           check=True).stdout.splitlines()
    db = {r.split("\t")[0]: (r.split("\t")[1], r.split("\t")[2]) for r in righe}
    esistenti = Counter(n(r.split("\t")[1]) for r in righe)
    return db, esistenti


def main():
    db, esistenti = carica_db()
    recs = json.load(open(OUT / "inat_gruppoB.json", encoding="utf-8"))
    sost, agg = [], []
    for r in recs:
        if r["slug"] not in db or not r.get("nome_it"):
            continue
        nome, alt = db[r["slug"]]
        if nome != r["nome_db"]:
            continue  # cambiata nel frattempo
        inat = maiuscola(r["nome_it"].strip())
        elenco = [a for a in alt.split(SEP) if a]
        if r["slug"] in SOSTITUISCI:
            if scarto(inat, r["sci"], esistenti):
                print("saltata:", r["slug"], inat)
                continue
            nuovi = [nome] + [a for a in elenco if n(a) != n(inat)]
            sost.append((r["slug"], nome, alt, inat, SEP.join(nuovi)))
        else:
            if n(inat) == n(nome) or n(inat) in [n(a) for a in elenco]:
                continue
            agg.append((r["slug"], alt, SEP.join(elenco + [inat])))
    cont = Counter(n(x[3]) for x in sost)
    assert all(v == 1 for v in cont.values())

    migl = []
    if sost:
        v = ",\n  ".join(f"({sql_str(s)}, {sql_str(vn)}, {sql_str(av)}, {sql_str(inat)}, {sql_str(an)})"
                         for s, vn, av, inat, an in sost)
        migl.append("with v(slug, nome_vecchio, alt_vecchi, nome, alt_nuovi) as (values\n  " + v + "\n)\n"
                    "update specie s set nome = v.nome, nomi_alternativi = v.alt_nuovi from v\n"
                    "where s.slug = v.slug and s.specie_padre_id is null and s.nome = v.nome_vecchio\n"
                    "  and coalesce(s.nomi_alternativi,'') = v.alt_vecchi\n"
                    "  and not exists (select 1 from specie o where o.nome = v.nome);\n")
    if agg:
        v = ",\n  ".join(f"({sql_str(s)}, {sql_str(av)}, {sql_str(an)})" for s, av, an in agg)
        migl.append("with v(slug, alt_vecchi, alt_nuovi) as (values\n  " + v + "\n)\n"
                    "update specie s set nomi_alternativi = v.alt_nuovi from v\n"
                    "where s.slug = v.slug and s.specie_padre_id is null\n"
                    "  and coalesce(s.nomi_alternativi,'') = v.alt_vecchi;\n")
    MIGRATION.write_text(
        f"-- Nomi italiani lotto 4 (gruppo B): {len(sost)} nomi sostituiti, {len(agg)} nomi iNaturalist aggiunti a nomi_alternativi.\n"
        "-- Si applica solo se la riga è ancora com'era. Rollback: scripts/nomi-italiani/rollback_lotto4.sql\n"
        + "\n".join(migl), encoding="utf-8")

    rb = []
    if sost:
        v = ",\n  ".join(f"({sql_str(s)}, {sql_str(vn)}, {sql_str(av)}, {sql_str(inat)})" for s, vn, av, inat, _ in sost)
        rb.append("with v(slug, nome_vecchio, alt_vecchi, nome) as (values\n  " + v + "\n)\n"
                  "update specie s set nome = v.nome_vecchio, nomi_alternativi = nullif(v.alt_vecchi,'') from v\n"
                  "where s.slug = v.slug and s.nome = v.nome;\n")
    if agg:
        v = ",\n  ".join(f"({sql_str(s)}, {sql_str(av)}, {sql_str(an)})" for s, av, an in agg)
        rb.append("with v(slug, alt_vecchi, alt_nuovi) as (values\n  " + v + "\n)\n"
                  "update specie s set nomi_alternativi = nullif(v.alt_vecchi,'') from v\n"
                  "where s.slug = v.slug and s.nomi_alternativi = v.alt_nuovi;\n")
    ROLLBACK.write_text("-- Rollback lotto 4: ripristina nomi e nomi alternativi di prima.\n" + "\n".join(rb), encoding="utf-8")
    for s, vn, _, inat, _ in sost:
        print(f"sostituisci: {vn} → {inat}")
    print(len(sost), "sostituzioni,", len(agg), "aggiunte a nomi_alternativi")


if __name__ == "__main__":
    main()
