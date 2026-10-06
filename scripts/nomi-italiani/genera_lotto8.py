"""Lotto 8: madri del lotto 2 (nome da PlantNet) verificate su iNaturalist, e loro cultivar.

Input: out/inat_lotto2.jsonl (scarica_inat.cerca per le 438 madri del lotto 2 con cultivar).
- nome iNaturalist uguale al nostro (100 madri): le cultivar prendono il nome della madre.
- nome iNaturalist diverso (5 madri): `nome` della madre diventa quello di iNaturalist (il vecchio resta in
  nomi_alternativi) e poi le cultivar prendono il nuovo nome.
- iNaturalist senza nome italiano o specie non trovata: né madre né cultivar cambiano.
"""
import json
import os
import subprocess
from pathlib import Path

from genera_lotto3 import QUI, OUT, SEP, n
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261006180000_nomi_italiani_lotto8.sql"
ROLLBACK = QUI / "rollback_lotto8.sql"


def classifica(rec):
    """'uguale' | 'diverso' | None."""
    if not rec.get("trovato") or not rec.get("nome_it"):
        return None
    return "uguale" if n(rec["nome_it"]) == n(rec["nome_db"]) else "diverso"


def alt_attuali(slugs):
    url = os.environ.get("DATABASE_URL") or [l.split("=", 1)[1].strip().strip('"')
        for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]
    q = "select slug, coalesce(nomi_alternativi,'') from specie where slug in (" + ",".join(f"'{x}'" for x in slugs) + ")"
    r = subprocess.run(["psql", url, "-At", "-F", "\t", "-c", q], capture_output=True, text=True, check=True).stdout
    return dict(l.split("\t", 1) for l in r.splitlines())


def nuovi_alt(vecchio, nuovo, alt):
    """Vecchio nome in testa, nuovo nome tolto (ora è il nome principale)."""
    resto = [a for a in alt.split(SEP) if a and n(a) != n(nuovo) and n(a) != n(vecchio)]
    return SEP.join([vecchio] + resto)


def main():
    recs = [json.loads(l) for l in open(OUT / "inat_lotto2.jsonl", encoding="utf-8")]
    uguali = [r["slug"] for r in recs if classifica(r) == "uguale"]
    diversi = [(r["slug"], r["nome_db"], r["nome_it"].strip()[0].upper() + r["nome_it"].strip()[1:])
               for r in recs if classifica(r) == "diverso"]
    att = alt_attuali([d[0] for d in diversi])
    diversi = [(sl, v, nu, att[sl], nuovi_alt(v, nu, att[sl])) for sl, v, nu in diversi]
    slugs = ",\n    ".join(f"'{s}'" for s in sorted(uguali + [d[0] for d in diversi]))
    vals = ",\n  ".join(f"({sql_str(s)}, {sql_str(v)}, {sql_str(nu)}, {sql_str(ao)}, {sql_str(an)})"
                      for s, v, nu, ao, an in diversi)
    nuovo = "p.nome || ' ' || substr(c.nome, length(p.nome_scientifico) + 2)"
    MIGRATION.write_text(
        f"-- Lotto 8: {len(uguali)} madri del lotto 2 confermate da iNaturalist e {len(diversi)} con nome iNaturalist diverso\n"
        "-- (il nome principale diventa quello di iNaturalist, il vecchio va in nomi_alternativi); poi le cultivar di tutte\n"
        "-- queste madri prendono il nome italiano della madre. Rollback: scripts/nomi-italiani/rollback_lotto8.sql\n"
        "with v(slug, vecchio, nuovo, alt_vecchi, alt_nuovi) as (values\n  " + vals + "\n)\n"
        "update specie s set nome = v.nuovo, nomi_alternativi = v.alt_nuovi\n"
        "from v where s.slug = v.slug and s.specie_padre_id is null and s.nome = v.vecchio\n"
        "  and coalesce(s.nomi_alternativi, '') = v.alt_vecchi\n"
        "  and not exists (select 1 from specie o where o.nome = v.nuovo);\n\n"
        "update specie c set nome = " + nuovo + "\n"
        "from specie p\n"
        "where p.id = c.specie_padre_id\n"
        "  and p.nome <> p.nome_scientifico\n"
        "  and c.nome = c.nome_scientifico\n"
        "  and left(c.nome, length(p.nome_scientifico) + 1) = p.nome_scientifico || ' '\n"
        "  and substr(c.nome, length(p.nome_scientifico) + 2) ~ '^''[^'']+''$'\n"
        "  and p.slug in (\n    " + slugs + "\n  )\n"
        "  and not exists (select 1 from specie o where o.nome = " + nuovo + ");\n",
        encoding="utf-8")
    rv = vals
    ROLLBACK.write_text(
        "-- Rollback lotto 8: le cultivar delle madri coinvolte tornano al nome scientifico; le madri col nome cambiato\n"
        "-- ritrovano il vecchio nome e tolgono il vecchio nome dai nomi_alternativi.\n"
        "update specie c set nome = c.nome_scientifico from specie p\n"
        "where p.id = c.specie_padre_id and c.nome <> c.nome_scientifico and p.slug in (\n    " + slugs + "\n  );\n\n"
        "with v(slug, vecchio, nuovo, alt_vecchi, alt_nuovi) as (values\n  " + rv + "\n)\n"
        "update specie s set nome = v.vecchio, nomi_alternativi = nullif(v.alt_vecchi, '')\n"
        "from v where s.slug = v.slug and s.nome = v.nuovo;\n", encoding="utf-8")
    print(len(uguali), "madri uguali,", len(diversi), "diverse:", [(d[1], d[2]) for d in diversi])


if __name__ == "__main__":
    main()
