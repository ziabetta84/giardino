"""Lotto 13: generi Anthurium e Hydrangea, la cui riga "spp." ha già un nome italiano (lotto 4) ma `generi.nome` no.

generi.nome = nome della riga di genere ("Anturio", "Ortensia"); poi le cultivar "Genere 'Epiteto'" lo usano come nel lotto 11.
Escluso Exacum ("Violetta persiana" è il nome di una sola specie). One-shot.
"""
from genera_lotto3 import QUI
from genera_lotto11 import NUOVO, FORMA

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261011120000_nomi_italiani_lotto13_anturio_ortensia.sql"
ROLLBACK = QUI / "rollback_lotto13.sql"
GENERI = [("Anthurium", "Anturio"), ("Hydrangea", "Ortensia")]
LISTA = ", ".join(f"'{g}'" for g, _ in GENERI)


def main():
    vals = ", ".join(f"('{g}', '{n}')" for g, n in GENERI)
    MIGRATION.write_text(
        "-- Lotto 13: Anturio e Ortensia (nomi già sulle righe di genere dal lotto 4) diventano il nome dei generi\n"
        "-- e le cultivar \"Genere 'Epiteto'\" li usano. Rollback: scripts/nomi-italiani/rollback_lotto13.sql\n"
        f"update generi g set nome = v.nome from (values {vals}) as v(sci, nome)\n"
        "where g.nome_scientifico = v.sci and g.nome = g.nome_scientifico;\n\n"
        "update specie c set nome = " + NUOVO + "\n"
        "from generi g\n"
        "where g.id = c.genere_id\n"
        "  and g.nome_scientifico in (" + LISTA + ")\n"
        "  and c.specie_padre_id is not null\n"
        "  and c.nome = c.nome_scientifico\n"
        "  and g.nome <> g.nome_scientifico\n"
        "  and " + FORMA + "\n"
        "  and not exists (select 1 from specie o where o.nome = " + NUOVO + ");\n", encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback lotto 13: le cultivar di Anthurium e Hydrangea tornano al nome scientifico, poi i generi.\n"
        "-- Eseguire PRIMA di rollback_lotto11.sql.\n"
        "update specie c set nome = c.nome_scientifico\n"
        "from generi g\n"
        "where g.id = c.genere_id and g.nome_scientifico in (" + LISTA + ") and c.specie_padre_id is not null\n"
        "  and c.nome <> c.nome_scientifico and left(c.nome, length(g.nome) + 1) = g.nome || ' ' and g.nome <> g.nome_scientifico;\n\n"
        "update generi set nome = nome_scientifico where nome_scientifico in (" + LISTA + ");\n", encoding="utf-8")
    print("ok")


if __name__ == "__main__":
    main()
