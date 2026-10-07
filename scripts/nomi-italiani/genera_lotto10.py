"""Lotto 10: cultivar delle 55 madri del lotto 2 confermate da EPPO (seconda fonte, nome italiano uguale al nostro).

Input: out/conferma_eppo_lotto2.json (elenco di slug). Le madri non cambiano; le cultivar con nome = nome
scientifico prendono il nome italiano della madre ("Nome madre 'Epiteto'"). Rollback: cultivar di quelle madri
al nome scientifico.
"""
import json

from genera_lotto3 import QUI, OUT

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261006200000_nomi_italiani_lotto10.sql"
ROLLBACK = QUI / "rollback_lotto10.sql"


def main():
    slugs = sorted(json.load(open(OUT / "conferma_eppo_lotto2.json", encoding="utf-8")))
    elenco = ",\n    ".join(f"'{s}'" for s in slugs)
    nuovo = "p.nome || ' ' || substr(c.nome, length(p.nome_scientifico) + 2)"
    MIGRATION.write_text(
        f"-- Lotto 10: cultivar delle {len(slugs)} madri del lotto 2 confermate da EPPO prendono il nome italiano della madre.\n"
        "-- Rollback: scripts/nomi-italiani/rollback_lotto10.sql\n"
        "update specie c set nome = " + nuovo + "\n"
        "from specie p\n"
        "where p.id = c.specie_padre_id\n"
        "  and p.nome <> p.nome_scientifico\n"
        "  and c.nome = c.nome_scientifico\n"
        "  and left(c.nome, length(p.nome_scientifico) + 1) = p.nome_scientifico || ' '\n"
        "  and substr(c.nome, length(p.nome_scientifico) + 2) ~ '^''[^'']+''$'\n"
        "  and p.slug in (\n    " + elenco + "\n  )\n"
        "  and not exists (select 1 from specie o where o.nome = " + nuovo + ");\n", encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback lotto 10: le cultivar delle madri coinvolte tornano al nome scientifico.\n"
        "update specie c set nome = c.nome_scientifico from specie p\n"
        "where p.id = c.specie_padre_id and c.nome <> c.nome_scientifico and p.slug in (\n    " + elenco + "\n  );\n",
        encoding="utf-8")
    print(len(slugs), "madri")


if __name__ == "__main__":
    main()
