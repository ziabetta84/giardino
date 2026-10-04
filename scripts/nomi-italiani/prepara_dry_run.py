"""Prepara out/dry_run.sql: abbina per nome scientifico le specie PlantNet con un solo nome.

Esclude i nomi che compaiono su più specie PlantNet (collisione UNIQUE certa).
Il SQL è di sola lettura: restituisce le righe del catalogo che verrebbero aggiornate.
"""
import csv
from collections import Counter
from pathlib import Path

from nomi import sql_str

OUT = Path(__file__).parent / "out"

righe = list(csv.DictReader(open(OUT / "plantnet.csv", encoding="utf-8")))
singoli = [r for r in righe if r["n_nomi"] == "1"]
ripetuti = {n for n, v in Counter(r["nomi"].lower() for r in singoli).items() if v > 1}
proposte = [(r["sci"], r["nomi"]) for r in singoli if r["nomi"].lower() not in ripetuti]
def sql_per(blocco, esporta=False):
    valori = ",".join(f"({sql_str(s)},{sql_str(n)})" for s, n in blocco)
    return (
    "with v(sci, nome) as (values " + valori + "),\n"
    "omonimi as (\n"
    "  select lower(s.nome_scientifico) k, count(*) n from specie s join v on lower(s.nome_scientifico) = lower(v.sci) group by 1\n"
    "),\n"
    "gia as (\n"
    "  select lower(o.nome) k, count(*) n from specie o join v on lower(o.nome) = lower(v.nome) group by 1\n"
    "),\n"
    "m as (\n"
    "  select s.slug, v.nome, s.nome_scientifico, coalesce(g.n, 0) as conflitti\n"
    "  from specie s join v on lower(s.nome_scientifico) = lower(v.sci)\n"
    "  join omonimi on omonimi.k = lower(s.nome_scientifico) and omonimi.n = 1\n"
    "  left join gia g on g.k = lower(v.nome)\n"
    "  where s.nome = s.nome_scientifico and s.specie_padre_id is null\n"
    ")\n"
    + ("select slug || '|' || nome || '|' || nome_scientifico from m where conflitti = 0 order by slug"
       if esporta else
    "select (select count(*) from m) as abbinate,\n"
    "  (select count(*) from m where conflitti > 0) as con_conflitti,\n"
    "  (select count(*) from v) as proposte,\n"
    "  (select json_agg(json_build_array(slug, nome)) from (select slug, nome from m where conflitti = 0 order by md5(slug) limit 40) c) as campione,\n"
    "  (select json_agg(json_build_array(slug, nome)) from (select slug, nome from m where conflitti > 0 limit 15) c) as conflitti_es")
    )


BLOCCHI = 4
passo = -(-len(proposte) // BLOCCHI)
for i in range(BLOCCHI):
    blocco = proposte[i * passo:(i + 1) * passo]
    (OUT / f"dry_run_{i + 1}.sql").write_text(sql_per(blocco), encoding="utf-8")
    (OUT / f"esporta_{i + 1}.sql").write_text(sql_per(blocco, esporta=True), encoding="utf-8")
(OUT / "proposte_singolo.csv").write_text(
    "sci,nome\n" + "\n".join(f"{s},{n}" for s, n in proposte), encoding="utf-8")
print(len(proposte), "proposte in", BLOCCHI, "blocchi;", len(ripetuti), "nomi ripetuti scartati")
