"""Genera la migration che popola specie.sinonimi_botanici e specie.nome_accettato da GBIF.

Legge out/gbif.jsonl (scarica_gbif.py). Usa solo le corrispondenze EXACT. Per le specie che GBIF
considera sinonimo di un altro nome, nome_accettato è il nome oggi valido e finisce anche in
sinonimi_botanici (così la ricerca lo trova). Tetto di MAX_SINONIMI nomi per specie.
"""
import json
from pathlib import Path

from nomi import sql_str

QUI = Path(__file__).parent
OUT = QUI / "out"
MIGRATION = QUI.parent.parent / "supabase" / "migrations" / "20261006110000_specie_sinonimi_botanici_dati.sql"
SEP = " | "
MAX_SINONIMI = 15


def prepara(rec):
    """Da un record GBIF a (slug, sinonimi, accettato) o None se non utilizzabile."""
    if rec.get("match") != "EXACT" or not rec.get("key"):
        return None
    sci = rec["sci"]
    accettato = None
    if rec.get("stato") in ("SYNONYM", "HETEROTYPIC_SYNONYM") and rec.get("accettato"):
        if rec["accettato"].lower() != sci.lower():
            accettato = rec["accettato"]
    elif rec.get("stato") not in ("ACCEPTED", "DOUBTFUL"):
        return None
    nomi = ([accettato] if accettato else []) + list(rec.get("sinonimi") or [])
    visti, finali = {sci.lower()}, []
    for n in nomi:
        if SEP.strip() in n or n.lower() in visti:
            continue
        visti.add(n.lower())
        finali.append(n)
    finali = finali[:MAX_SINONIMI]
    if not finali:
        return None
    return rec["slug"], SEP.join(finali), accettato


def main():
    righe = [json.loads(l) for l in open(OUT / "gbif.jsonl", encoding="utf-8")]
    valori = [v for v in (prepara(r) for r in righe) if v]
    nulla = lambda a: sql_str(a) if a else "null"
    elenco = ",\n  ".join(f"({sql_str(s)}, {sql_str(n)}, {nulla(a)})" for s, n, a in valori)
    sql = (
        f"-- Sinonimi botanici da GBIF per {len(valori)} specie (non cultivar, corrispondenza esatta del nome).\n"
        "-- nome_accettato solo dove GBIF considera la riga un sinonimo di un altro nome.\n"
        "with v(slug, sin, acc) as (values\n  " + elenco + "\n)\n"
        "update specie s set sinonimi_botanici = v.sin, nome_accettato = v.acc\n"
        "from v\n"
        "where s.slug = v.slug and s.specie_padre_id is null and s.sinonimi_botanici is null;\n"
    )
    MIGRATION.write_text(sql, encoding="utf-8")
    (QUI / "rollback_sinonimi_botanici.sql").write_text(
        "-- Rollback: svuota le due colonne (o eliminale, vedi migration 20261006100000).\n"
        "update specie set sinonimi_botanici = null, nome_accettato = null\n"
        "where sinonimi_botanici is not null or nome_accettato is not null;\n",
        encoding="utf-8",
    )
    con_acc = sum(1 for _, _, a in valori if a)
    print(len(valori), "specie in migration;", con_acc, "con nome accettato diverso")


if __name__ == "__main__":
    main()
