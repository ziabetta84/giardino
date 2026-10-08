"""Migration con i dati GBIF e il nome italiano (iNaturalist) dei generi."""
import json
from collections import Counter
from datetime import date

from genera_lotto3 import QUI, OUT, n
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261008110000_generi_dati.sql"
ROLLBACK = QUI / "rollback_generi_dati.sql"


def carica(nome):
    return {r["genere"]: r for r in (json.loads(l) for l in open(OUT / nome, encoding="utf-8"))}


def main():
    gbif, inat = carica("gbif_generi.jsonl"), carica("inat_generi.jsonl")
    oggi = date.today().isoformat()
    # nomi italiani unici fra i generi (generi.nome è UNIQUE)
    conta = Counter(n(r["nome_it"]) for r in inat.values() if r["nome_it"])
    righe = []
    for g in sorted(set(gbif) | set(inat)):
        nome = inat.get(g, {}).get("nome_it")
        if nome and conta[n(nome)] > 1:
            nome = None
        righe.append((g, gbif.get(g, {}).get("gbif_key"), gbif.get(g, {}).get("n_specie"), nome))
    vals = ",\n  ".join(
        f"({sql_str(g)}, {k if k else 'null'}, {ns if ns is not None else 'null'}, {sql_str(nome) if nome else 'null'})"
        for g, k, ns, nome in righe)
    MIGRATION.write_text(
        f"-- Dati dei generi usati: specie accettate GBIF (rilevate il {oggi}) e nome italiano iNaturalist.\n"
        "-- Si applica solo ai generi ancora senza dati; il nome italiano solo se libero. Rollback: rollback_generi_dati.sql\n"
        "with v(genere, gbif_key, n_specie, nome) as (values\n  " + vals + "\n)\n"
        "update generi g set gbif_key = v.gbif_key, specie_gbif = v.n_specie,\n"
        f"  gbif_rilevato_il = date '{oggi}', nome = coalesce(v.nome, g.nome)\n"
        "from v where g.nome_scientifico = v.genere and g.gbif_rilevato_il is null\n"
        "  and (v.nome is null or not exists (select 1 from generi o where o.nome = v.nome and o.id <> g.id));\n",
        encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback dati generi: azzera i dati GBIF e riporta il nome al nome scientifico.\n"
        "update generi set gbif_key = null, specie_gbif = null, gbif_rilevato_il = null, nome = nome_scientifico;\n",
        encoding="utf-8")
    print(len(righe), "generi,", sum(1 for r in righe if r[3]), "con nome italiano")


if __name__ == "__main__":
    main()
