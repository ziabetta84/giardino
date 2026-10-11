"""One-shot: 18 generi prima 'rivedere' (omonimi GBIF nel regno animale/fungino), ora risolti con il genere vegetale
della famiglia giusta (dati/gbif_generi_risolti.json) e più di una specie accettata: riga 'Genere spp.' + dati GBIF in `generi`.
Restano 'rivedere' i generi che GBIF considera sinonimi di un altro genere (Anagallis, Consolida, Distictis, Duchesnea, Gaura,
Glandularia, Odontoglossum, Pennisetum, Rhodohypoxis, Spartina) e Oreomecon (0 specie accettate).
Helleborus: il nome della riga 'Elleboro nero' (di una specie) diventa 'Elleboro', il nome del genere usato dalle cultivar.
"""
import csv
import json

from genera_lotto3 import QUI
from nomi import sql_str

MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261011130000_generi_risolti_gbif.sql"
ROLLBACK = QUI / "rollback_generi_risolti.sql"
DATA = "2026-10-11"


def main():
    gbif = json.load(open(QUI / "dati" / "gbif_generi_risolti.json", encoding="utf-8"))
    righe = {r["genere"]: r for r in csv.DictReader(open(QUI / "dati" / "righe_genere_da_rivedere.csv", encoding="utf-8"))
             if r["decisione"] == "rivedere"}
    ok = {g: v for g, v in gbif.items() if g in righe and v.get("status") in ("ACCEPTED", "DOUBTFUL") and (v.get("n") or 0) > 1}
    assert len(ok) == 18, sorted(ok)
    gv = ",\n  ".join(f"({sql_str(g)}, {v['key']}, {v['n']})" for g, v in sorted(ok.items()))
    sv = ",\n  ".join(f"({sql_str(righe[g]['slug'])}, {sql_str(righe[g]['nome_scientifico'])}, {sql_str(g)})" for g in sorted(ok))
    MIGRATION.write_text(
        "-- 18 generi risolti su GBIF (genere vegetale con più di una specie accettata): dati GBIF in `generi` e righe 'Genere spp.'.\n"
        "-- Rollback: scripts/nomi-italiani/rollback_generi_risolti.sql\n"
        "update generi g set gbif_key = v.k, specie_gbif = v.n, gbif_rilevato_il = date '" + DATA + "'\n"
        "from (values\n  " + gv + "\n) as v(genere, k, n)\n"
        "where g.nome_scientifico = v.genere and g.gbif_rilevato_il is null;\n\n"
        "update specie s set nome_scientifico = v.genere || ' spp.'\n"
        "from (values\n  " + sv + "\n) as v(slug, vecchio, genere)\n"
        "where s.slug = v.slug and s.nome_scientifico = v.vecchio and s.specie_padre_id is null;\n\n"
        "update specie set nome = 'Elleboro' where slug = 'helleborus' and nome = 'Elleboro nero'\n"
        "  and not exists (select 1 from specie o where o.nome = 'Elleboro');\n", encoding="utf-8")
    ROLLBACK.write_text(
        "-- Rollback generi risolti su GBIF.\n"
        "update specie set nome = 'Elleboro nero' where slug = 'helleborus' and nome = 'Elleboro';\n\n"
        "update specie s set nome_scientifico = v.vecchio\n"
        "from (values\n  " + sv + "\n) as v(slug, vecchio, genere)\n"
        "where s.slug = v.slug and s.nome_scientifico = v.genere || ' spp.' and s.specie_padre_id is null;\n\n"
        "update generi set gbif_key = null, specie_gbif = null, gbif_rilevato_il = null\n"
        "where nome_scientifico in (" + ", ".join(sql_str(g) for g in sorted(ok)) + ") and gbif_rilevato_il = date '" + DATA + "';\n",
        encoding="utf-8")
    print(len(ok), "generi")


if __name__ == "__main__":
    main()
