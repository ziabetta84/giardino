"""One-shot: toglie i doppioni "bozza" con slug botanico delle specie con slug italiano (aglio, pomodoro…).

Un doppione si cancella solo se: bozza, slug con trattino, stesso nome scientifico di una riga con slug senza trattino
e già verificata, nessuna pianta e nessuna cultivar. Gli slug italiani restano (decisione dell'utente).
Avocado: la riga italiana ha la descrizione vuota, quella del doppione passa lì prima della cancellazione.
Il rollback reinserisce le righe dal JSON salvato qui (data/ non serve: è nel file di rollback).
Non si può rieseguire dopo l'applicazione.
"""
import json
import os
import subprocess

from genera_lotto3 import QUI
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261011140000_doppioni_slug_botanico.sql"
ROLLBACK = QUI / "rollback_doppioni_slug.sql"

SELEZIONE = """
from specie b join specie a on a.nome_scientifico = b.nome_scientifico and a.id <> b.id
where b.stato_verifica = 'bozza' and b.slug ~ '-' and b.specie_padre_id is null
  and a.slug !~ '-' and a.specie_padre_id is null and a.stato_verifica = 'verificato'
  and not exists (select 1 from piante p where p.specie = b.slug)
  and not exists (select 1 from specie c where c.specie_padre_id = b.id)"""


def psql(q):
    url = os.environ.get("DATABASE_URL") or [l.split("=", 1)[1].strip().strip('"')
        for l in open(QUI.parent.parent / ".env.local") if l.startswith("DATABASE_URL=")][0]
    return subprocess.run(["psql", url, "-At", "-c", q], capture_output=True, text=True, check=True).stdout


def main():
    slugs = sorted(psql("select b.slug " + SELEZIONE).split())
    assert len(slugs) == len(set(slugs))
    elenco = ", ".join(sql_str(s) for s in slugs)
    righe = psql(f"select coalesce(json_agg(s), '[]') from specie s where slug in ({elenco})").strip()
    assert len(json.loads(righe)) == len(slugs)
    MIGRATION.write_text(
        f"-- Toglie {len(slugs)} doppioni 'bozza' con slug botanico di righe con slug italiano già verificate (senza piante né cultivar).\n"
        "-- Rollback: scripts/nomi-italiani/rollback_doppioni_slug.sql\n"
        "update specie a set descrizione = b.descrizione, lingua_descrizione = b.lingua_descrizione\n"
        "from specie b where a.slug = 'avocado' and b.slug = 'persea-americana'\n"
        "  and coalesce(a.descrizione, '') = '' and coalesce(b.descrizione, '') <> '';\n\n"
        f"delete from specie where slug in ({elenco})\n"
        "  and stato_verifica = 'bozza' and specie_padre_id is null\n"
        "  and not exists (select 1 from piante p where p.specie = specie.slug)\n"
        "  and not exists (select 1 from specie c where c.specie_padre_id = specie.id);\n", encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback doppioni slug: reinserisce le righe cancellate (la descrizione di 'avocado' resta quella copiata).\n"
        "insert into specie select * from json_populate_recordset(null::specie, $json$" + righe + "$json$::json)\n"
        "on conflict do nothing;\n", encoding="utf-8")
    print(len(slugs), "doppioni:", ", ".join(slugs))


if __name__ == "__main__":
    main()
