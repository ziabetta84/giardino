"""Genera il lotto 3 dei nomi italiani: nome principale da iNaturalist per le specie senza nome italiano.

Per ogni specie del gruppo A di out/inat.jsonl (nome = nome scientifico, con nomi_alternativi) imposta
`nome` al nome preferito di iNaturalist solo se coincide con uno dei nomi alternativi già presenti
(due fonti d'accordo: PlantNet e iNaturalist), non è già in uso, non è un genere/famiglia e non è
proposto due volte. Il nome scelto viene tolto da nomi_alternativi (resta tra gli altri nomi solo ciò che è diverso).
"""
import json
import os
import re
import subprocess
import unicodedata
from collections import Counter
from pathlib import Path

from nomi import sql_str

QUI = Path(__file__).parent
OUT = QUI / "out"
MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261006120000_nomi_italiani_lotto3.sql"
ROLLBACK = QUI / "rollback_lotto3.sql"
SEP = " | "


def n(s):
    """Forma di confronto: minuscolo, senza accenti, trattini e apostrofi come spazi."""
    s = unicodedata.normalize("NFD", s.lower())
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", re.sub(r"[-’']", " ", s)).strip()


def scarto(nome_it, sci, esistenti):
    """Motivo per cui il nome di iNaturalist non va usato, o None."""
    if n(nome_it) == n(sci.split(" ")[0]):
        return "uguale al genere"
    if " " not in nome_it and re.search(r"(acee|aceae|idee)$", n(nome_it)):
        return "nome di famiglia"
    if esistenti[n(nome_it)] > 0:
        return "già in uso"
    return None


def scegli(rec, alternativi, esistenti):
    """(nome, alternativi_vecchi, alternativi_nuovi) oppure None se la specie non va nel lotto."""
    if not rec.get("nome_it") or not alternativi:
        return None
    nome = rec["nome_it"][0].upper() + rec["nome_it"][1:]
    if scarto(nome, rec["sci"], esistenti):
        return None
    if n(nome) not in [n(a) for a in alternativi]:
        return None
    restanti = [a for a in alternativi if n(a) != n(nome)]
    return nome, SEP.join(alternativi), (SEP.join(restanti) if restanti else None)


def carica_db():
    url = os.environ.get("DATABASE_URL")
    if not url:
        url = [l.split("=", 1)[1].strip().strip('"')
               for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]

    def psql(q):
        return subprocess.run(["psql", url, "-At", "-F", "\t", "-c", q], capture_output=True, text=True,
                              check=True).stdout.splitlines()

    alt = {r.split("\t")[0]: r.split("\t")[1].split(SEP) for r in
           psql("select slug, nomi_alternativi from specie where specie_padre_id is null and nome = nome_scientifico "
                "and nomi_alternativi is not null")}
    esistenti = Counter(n(r) for r in psql("select nome from specie"))
    return alt, esistenti


def main():
    alt, esistenti = carica_db()
    righe = [json.loads(l) for l in open(OUT / "inat.jsonl", encoding="utf-8")]
    scelte = []
    for rec in righe:
        if rec["gruppo"] != "A" or rec["slug"] not in alt:
            continue
        s = scegli(rec, alt[rec["slug"]], esistenti)
        if s:
            scelte.append((rec["slug"], *s))
    # un nome proposto per due specie non va a nessuna delle due
    cont = Counter(n(x[1]) for x in scelte)
    scelte = [x for x in scelte if cont[n(x[1])] == 1]
    assert len({x[1] for x in scelte}) == len(scelte)

    nulla = lambda a: sql_str(a) if a else "null"
    valori = ",\n  ".join(f"({sql_str(s)}, {sql_str(nome)}, {sql_str(vecchi)}, {nulla(nuovi)})"
                          for s, nome, vecchi, nuovi in scelte)
    MIGRATION.write_text(
        f"-- Nomi italiani lotto 3: {len(scelte)} specie, nome principale da iNaturalist confermato dai nomi alternativi\n"
        "-- (PlantNet). Si applica solo se la riga è ancora senza nome italiano e con gli stessi nomi alternativi,\n"
        "-- e se il nome non è già in uso. Rollback: scripts/nomi-italiani/rollback_lotto3.sql\n"
        "with v(slug, nome, alt_vecchi, alt_nuovi) as (values\n  " + valori + "\n)\n"
        "update specie s set nome = v.nome, nomi_alternativi = v.alt_nuovi\n"
        "from v\n"
        "where s.slug = v.slug and s.specie_padre_id is null and s.nome = s.nome_scientifico\n"
        "  and s.nomi_alternativi = v.alt_vecchi\n"
        "  and not exists (select 1 from specie o where o.nome = v.nome);\n",
        encoding="utf-8")
    rb = ",\n  ".join(f"({sql_str(s)}, {sql_str(nome)}, {sql_str(vecchi)})" for s, nome, vecchi, _ in scelte)
    ROLLBACK.write_text(
        "-- Rollback lotto 3: ripristina il nome scientifico come nome e i nomi alternativi di prima.\n"
        "with v(slug, nome, alt_vecchi) as (values\n  " + rb + "\n)\n"
        "update specie s set nome = s.nome_scientifico, nomi_alternativi = v.alt_vecchi\n"
        "from v where s.slug = v.slug and s.nome = v.nome;\n",
        encoding="utf-8")
    print(len(scelte), "specie nel lotto 3")


if __name__ == "__main__":
    main()
