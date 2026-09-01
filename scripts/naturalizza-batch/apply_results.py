#!/usr/bin/env python3
"""Incrocia risultati di scrittura + verifica, genera gli UPDATE SQL per le righe
PASS (o già corrette) e li applica via psql. Le righe FAIL/errored/troncate restano
intatte e finiscono in un report per revisione manuale o un giro successivo (la
query di export_rows.py è auto-correttiva: le riprende da sola).

Uso:
  python3 apply_results.py --rows prototipo.json --write-results write_results.json \
      --verify-results verify_results.json --sql-out update.sql --report-out report.json [--apply]
"""
import argparse
import json
from pathlib import Path

from common import load_env, run_psql_file, save_json


def sql_string(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def sql_text_array(values) -> str:
    escaped = ", ".join(sql_string(v) for v in values)
    return f"array[{escaped}]::text[]"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--rows", required=True)
    parser.add_argument("--write-results", required=True)
    parser.add_argument("--verify-results", default=None, help="opzionale: se assente, scrive tutto ciò che non è FAIL/troncato/già corretto senza doppio controllo")
    parser.add_argument("--sql-out", default="update.sql")
    parser.add_argument("--report-out", default="report.json")
    parser.add_argument("--apply", action="store_true", help="applica subito il file SQL via psql")
    args = parser.parse_args()

    load_env()
    rows = {r["id"]: r for r in json.loads(Path(args.rows).read_text())}
    write_results = json.loads(Path(args.write_results).read_text())
    verify_results = json.loads(Path(args.verify_results).read_text()) if args.verify_results else {}

    to_write = []
    report = {"scritte": [], "saltate_fail": [], "saltate_errore_scrittura": [],
              "saltate_troncate": [], "gia_corrette": []}

    for row_id, result in write_results.items():
        if row_id not in rows:
            continue
        if not result.get("ok"):
            report["saltate_errore_scrittura"].append({"id": row_id, "tipo": result.get("tipo")})
            continue
        output = result["output"] or {}
        if output.get("gia_corretto"):
            report["gia_corrette"].append(row_id)
            continue
        if output.get("fonte_troncata"):
            report["saltate_troncate"].append({"id": row_id, "slug": rows[row_id]["slug"]})
            continue
        verdict = verify_results.get(row_id)
        if verdict is not None:
            verdict_ok = verdict.get("ok") and verdict.get("output", {}).get("verdetto") == "PASS"
            if not verdict_ok:
                report["saltate_fail"].append({
                    "id": row_id, "slug": rows[row_id]["slug"],
                    "problemi": verdict.get("output", {}).get("problemi") if verdict.get("ok") else [f"verifica {verdict.get('tipo')}"],
                })
                continue
        to_write.append((row_id, output))
        report["scritte"].append(row_id)

    lines = []
    for row_id, output in to_write:
        descrizione = sql_string(output["descrizione_riscritta"])
        alert = sql_text_array(output["alert_riscritto"])
        lines.append(
            f"update specie set descrizione = {descrizione}, alert = {alert} where id = '{row_id}';"
        )

    Path(args.sql_out).write_text("\n".join(lines) + ("\n" if lines else ""))
    save_json(Path(args.report_out), report)

    print(f"Righe da scrivere: {len(to_write)}")
    print(f"Saltate (FAIL verifica): {len(report['saltate_fail'])}")
    print(f"Saltate (errore/scaduto nel batch di scrittura): {len(report['saltate_errore_scrittura'])}")
    print(f"Saltate (fonte troncata, per revisione manuale): {len(report['saltate_troncate'])}")
    print(f"Già corrette, nessuna modifica: {len(report['gia_corrette'])}")
    print(f"SQL scritto in {args.sql_out}, report in {args.report_out}")

    if args.apply:
        if not to_write:
            print("Niente da applicare.")
            return
        print("Applico il file SQL via psql...")
        run_psql_file(Path(args.sql_out))
        print("Fatto.")
    else:
        print("Rilancia con --apply per scrivere davvero su Supabase (esegui prima ./scripts/backup-db.sh).")


if __name__ == "__main__":
    main()
