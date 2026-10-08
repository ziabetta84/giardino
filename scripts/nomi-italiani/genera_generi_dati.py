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
        ns = gbif.get(g, {}).get("n_specie")
        # la chiave GBIF vale solo con un conteggio da corrispondenza esatta (n_specie non nullo)
        k = gbif.get(g, {}).get("gbif_key") if ns is not None else None
        righe.append((g, k, ns, nome))
    vals = ",\n  ".join(
        f"({sql_str(g)}, {k if k else 'null'}, {ns if ns is not None else 'null'}, {sql_str(nome) if nome else 'null'})"
        for g, k, ns, nome in righe)
    MIGRATION.write_text(
        f"-- Dati dei generi usati: specie accettate GBIF (rilevate il {oggi}) e nome italiano iNaturalist.\n"
        "-- Si applica solo ai generi ancora senza dati GBIF; il nome italiano solo se il nome e' ancora quello scientifico e libero.\n"
        "-- I dati GBIF solo con conteggio valido (n_specie non nullo). Rollback: rollback_generi_dati.sql\n"
        "with v(genere, gbif_key, n_specie, nome) as (values\n  " + vals + "\n)\n"
        "update generi g set\n"
        "  gbif_key = case when g.gbif_rilevato_il is null and v.n_specie is not null then v.gbif_key else g.gbif_key end,\n"
        "  specie_gbif = case when g.gbif_rilevato_il is null and v.n_specie is not null then v.n_specie else g.specie_gbif end,\n"
        f"  gbif_rilevato_il = case when g.gbif_rilevato_il is null and v.n_specie is not null then date '{oggi}' else g.gbif_rilevato_il end,\n"
        "  nome = case when v.nome is not null and g.nome = g.nome_scientifico\n"
        "    and not exists (select 1 from generi o where o.nome = v.nome and o.id <> g.id) then v.nome else g.nome end\n"
        "from v where g.nome_scientifico = v.genere and (\n"
        "  (g.gbif_rilevato_il is null and v.n_specie is not null)\n"
        "  or (v.nome is not null and g.nome = g.nome_scientifico\n"
        "    and not exists (select 1 from generi o where o.nome = v.nome and o.id <> g.id)));\n",
        encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback dati generi: azzera i dati GBIF e riporta il nome al nome scientifico.\n"
        "update generi set gbif_key = null, specie_gbif = null, gbif_rilevato_il = null, nome = nome_scientifico;\n",
        encoding="utf-8")
    print(len(righe), "generi,", sum(1 for r in righe if r[3]), "con nome italiano")


if __name__ == "__main__":
    main()
