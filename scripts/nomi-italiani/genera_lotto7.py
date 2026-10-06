"""Lotto 7: nomi italiani delle cultivar, dalla specie madre.

Una cultivar con nome = "<scientifico madre> 'Epiteto'" prende "<nome italiano madre> 'Epiteto'", se la madre ha
già un nome italiano. Sono escluse le madri del lotto 2 (nome da PlantNet) finché non vengono verificate su
iNaturalist, e le cultivar il cui nuovo nome è già in uso. Migration a regola (un solo update con join sulla madre);
rollback esatto perché prima nessuna cultivar aveva un nome diverso dallo scientifico.
"""
import re
from pathlib import Path

QUI = Path(__file__).parent
MIGRATIONS = QUI.parent.parent / "supabase" / "migrations"
MIGRATION = MIGRATIONS / "20261006170000_nomi_italiani_lotto7_cultivar.sql"
ROLLBACK = QUI / "rollback_lotto7.sql"


def slug_lotto2():
    slugs = set()
    for f in sorted(MIGRATIONS.glob("*nomi_italiani_lotto2*.sql")):
        slugs |= set(re.findall(r"\('([a-z0-9-]+)',\s*'", f.read_text(encoding="utf-8")))
    return sorted(slugs)


def main():
    esclusi = ",\n    ".join(f"'{s}'" for s in slug_lotto2())
    nuovo = "p.nome || ' ' || substr(c.nome, length(p.nome_scientifico) + 2)"
    MIGRATION.write_text(
        "-- Nomi italiani lotto 7: cultivar con il nome italiano della specie madre (\"Pomodoro 'Ibis'\").\n"
        "-- Solo cultivar con nome = \"<scientifico madre> 'Epiteto'\" e madre con nome italiano; escluse le madri\n"
        "-- del lotto 2 (PlantNet) e i nomi già in uso. Rollback: scripts/nomi-italiani/rollback_lotto7.sql\n"
        "update specie c set nome = " + nuovo + "\n"
        "from specie p\n"
        "where p.id = c.specie_padre_id\n"
        "  and p.nome <> p.nome_scientifico\n"
        "  and c.nome = c.nome_scientifico\n"
        "  and left(c.nome, length(p.nome_scientifico) + 1) = p.nome_scientifico || ' '\n"
        "  and substr(c.nome, length(p.nome_scientifico) + 2) ~ '^''[^'']+''$'\n"
        "  and p.slug not in (\n    " + esclusi + "\n  )\n"
        "  and not exists (select 1 from specie o where o.nome = " + nuovo + ");\n",
        encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback lotto 7: le cultivar tornano al nome scientifico (prima nessuna aveva un nome diverso).\n"
        "update specie set nome = nome_scientifico where specie_padre_id is not null and nome <> nome_scientifico;\n",
        encoding="utf-8")
    print(len(slug_lotto2()), "madri escluse (lotto 2)")


if __name__ == "__main__":
    main()
