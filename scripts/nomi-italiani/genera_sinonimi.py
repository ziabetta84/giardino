"""Genera la migration che popola specie.nomi_alternativi con i nomi italiani di PlantNet.

Per ogni specie PlantNet abbinata per nome scientifico a una riga non cultivar senza omonimi,
salva in nomi_alternativi tutti i nomi diversi da specie.nome (anche quelli di cui il lotto 2
ha scelto uno come principale: gli altri restano ricercabili). Non tocca specie.nome.
Salta le specie in ESCLUSI (abbinamenti scartati a mano: il loro nome non è affidabile).
"""
import csv
from pathlib import Path

from genera_lotto2 import ESCLUSI
from nomi import sql_str

QUI = Path(__file__).parent
OUT = QUI / "out"
MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261004150000_specie_nomi_alternativi_dati.sql"
SEP = " | "


def main():
    righe = list(csv.DictReader(open(OUT / "plantnet.csv", encoding="utf-8")))
    valori = []
    for r in righe:
        # "<pianta> del Perù" è un segnaposto ricorrente di PlantNet, non un nome reale
        nomi = [n for n in r["nomi"].split(SEP) if "|" not in n and not n.endswith(" del Perù")]
        if nomi:
            valori.append((r["sci"], SEP.join(nomi)))
    scartate = len(righe) - len(valori)
    elenco = ",\n  ".join(f"({sql_str(s)}, {sql_str(n)})" for s, n in valori)
    esclusi = ", ".join(sql_str(s) for s in sorted(ESCLUSI))
    sql = (
        f"-- Nomi alternativi da PlantNet per {len(valori)} specie (nome scientifico abbinato, non cultivar,\n"
        "-- nessun omonimo). Esclude i nomi uguali al nome principale e le specie con abbinamento scartato.\n"
        "with v(sci, alt) as (values\n  " + elenco + "\n),\n"
        "omonimi as (\n"
        "  select lower(s.nome_scientifico) k, count(*) n from specie s\n"
        "  join v on lower(s.nome_scientifico) = lower(v.sci) group by 1\n"
        "),\n"
        "calcolati as (\n"
        "  select s.id, (select string_agg(x, ' | ') from unnest(string_to_array(v.alt, ' | ')) x\n"
        "                where lower(x) <> lower(s.nome)) as alt\n"
        "  from specie s\n"
        "  join v on lower(s.nome_scientifico) = lower(v.sci)\n"
        "  join omonimi o on o.k = lower(s.nome_scientifico) and o.n = 1\n"
        "  where s.specie_padre_id is null and s.nomi_alternativi is null\n"
        f"    and s.slug <> all (array[{esclusi}])\n"
        ")\n"
        "update specie s set nomi_alternativi = c.alt from calcolati c\n"
        "where s.id = c.id and c.alt is not null;\n"
    )
    MIGRATION.write_text(sql, encoding="utf-8")
    (QUI / "rollback_sinonimi.sql").write_text(
        "-- Rollback: svuota nomi_alternativi (o elimina la colonna, vedi migration 20261004140000).\n"
        "update specie set nomi_alternativi = null where nomi_alternativi is not null;\n",
        encoding="utf-8",
    )
    print(len(valori), "specie PlantNet in migration;", scartate, "scartate per separatore")


if __name__ == "__main__":
    main()
