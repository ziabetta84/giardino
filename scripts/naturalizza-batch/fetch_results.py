#!/usr/bin/env python3
"""Attende il completamento di un batch (scrittura o verifica) e ne salva i
risultati indicizzati per custom_id. Logga esplicitamente errori/scadute, cosa
che segnala un problema di budget/rate-limit a metà elaborazione.

Uso:
  python3 fetch_results.py --batch-id msgbatch_xxx --out write_results.json
"""
import argparse
from pathlib import Path

from common import load_env, anthropic_client, poll_batch_until_done, save_json


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch-id", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    load_env()
    client = anthropic_client()
    print(f"Attendo il batch {args.batch_id}...")
    poll_batch_until_done(client, args.batch_id)

    results = {}
    counts = {"succeeded": 0, "errored": 0, "canceled": 0, "expired": 0}
    for entry in client.messages.batches.results(args.batch_id):
        counts[entry.result.type] = counts.get(entry.result.type, 0) + 1
        if entry.result.type == "succeeded":
            message = entry.result.message
            tool_use = next((b for b in message.content if b.type == "tool_use"), None)
            results[entry.custom_id] = {"ok": True, "output": tool_use.input if tool_use else None}
        else:
            results[entry.custom_id] = {"ok": False, "tipo": entry.result.type}

    save_json(Path(args.out), results)
    print(f"Risultati: {counts}")
    print(f"Salvati in {args.out}")
    if counts["errored"] or counts["expired"]:
        print(
            f"⚠️  {counts['errored']} errori + {counts['expired']} scadute — quelle righe "
            "non verranno scritte. Se il motivo è un budget esaurito, ricontrolla la "
            "console Anthropic: le righe rimaste si possono riprendere più tardi con "
            "un nuovo giro di export_rows.py (la query è auto-correttiva, pesca solo "
            "ciò che manca ancora)."
        )


if __name__ == "__main__":
    main()
