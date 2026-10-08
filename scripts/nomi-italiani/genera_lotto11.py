"""Lotto 11: cultivar "Genere 'Epiteto'" prendono il nome italiano del genere (generi.nome)."""
from genera_lotto3 import QUI

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261008130000_nomi_italiani_lotto11_cultivar_genere.sql"
ROLLBACK = QUI / "rollback_lotto11.sql"

NUOVO = "g.nome || ' ' || substr(c.nome, length(g.nome_scientifico) + 2)"
FORMA = ("left(c.nome_scientifico, length(g.nome_scientifico) + 2) = g.nome_scientifico || ' ''' "
         "and substr(c.nome_scientifico, length(g.nome_scientifico) + 2) ~ '^''[^'']+''$'")


def main():
    MIGRATION.write_text(
        "-- Lotto 11: cultivar nominate \"Genere 'Epiteto'\" prendono il nome italiano del genere (generi.nome).\n"
        "-- Solo se il genere ha un nome italiano e il nome nuovo non è già in uso. Rollback: rollback_lotto11.sql\n"
        "update specie c set nome = " + NUOVO + "\n"
        "from generi g\n"
        "where g.id = c.genere_id\n"
        "  and c.specie_padre_id is not null\n"
        "  and c.nome = c.nome_scientifico\n"
        "  and g.nome <> g.nome_scientifico\n"
        "  and " + FORMA + "\n"
        "  and not exists (select 1 from specie o where o.nome = " + NUOVO + ");\n", encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback lotto 11: le cultivar \"Genere 'Epiteto'\" tornano al nome scientifico.\n"
        "-- ATTENZIONE: eseguire PRIMA di rollback_generi_nomi_scelti.sql (usa generi.nome per riconoscere le cultivar).\n"
        "update specie c set nome = c.nome_scientifico\n"
        "from generi g\n"
        "where g.id = c.genere_id and c.specie_padre_id is not null and c.nome <> c.nome_scientifico\n"
        "  and " + FORMA + "\n"
        "  and left(c.nome, length(g.nome) + 1) = g.nome || ' ' and g.nome <> g.nome_scientifico;\n", encoding="utf-8")


if __name__ == "__main__":
    main()
