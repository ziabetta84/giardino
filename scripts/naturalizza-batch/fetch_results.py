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

# $/MTok, prezzi standard (lo sconto Batches del 50% si applica sotto su tutto).
RATES = {
    "claude-sonnet-5": {"input": 2.0, "output": 10.0},
    "claude-haiku-4-5": {"input": 1.0, "output": 5.0},
}


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
    usage_totali = {}  # model -> {input, cache_read, cache_creation, output}
    for entry in client.messages.batches.results(args.batch_id):
        counts[entry.result.type] = counts.get(entry.result.type, 0) + 1
        if entry.result.type == "succeeded":
            message = entry.result.message
            tool_use = next((b for b in message.content if b.type == "tool_use"), None)
            results[entry.custom_id] = {"ok": True, "output": tool_use.input if tool_use else None}
            u = message.usage
            acc = usage_totali.setdefault(
                message.model, {"input": 0, "cache_read": 0, "cache_creation": 0, "output": 0}
            )
            acc["input"] += u.input_tokens or 0
            acc["cache_read"] += getattr(u, "cache_read_input_tokens", 0) or 0
            acc["cache_creation"] += getattr(u, "cache_creation_input_tokens", 0) or 0
            acc["output"] += u.output_tokens or 0
        else:
            results[entry.custom_id] = {"ok": False, "tipo": entry.result.type}

    save_json(Path(args.out), results)
    print(f"Risultati: {counts}")
    print(f"Salvati in {args.out}")

    if usage_totali:
        print("\nUso token (prezzi pieni, poi sconto Batches 50% applicato al totale):")
        costo_totale = 0.0
        for model, u in usage_totali.items():
            # I risultati batch riportano lo snapshot datato (es. "...-20251001");
            # la tariffa e per famiglia di modello, non cambia tra gli snapshot.
            rate = RATES.get(model) or next(
                (r for prefix, r in RATES.items() if model.startswith(prefix)), None
            )
            print(
                f"  {model}: input={u['input']} cache_read={u['cache_read']} "
                f"cache_creation={u['cache_creation']} output={u['output']}"
            )
            if not rate:
                print(f"    (prezzo sconosciuto per {model}, salto la stima $)")
                continue
            costo = (
                u["input"] * rate["input"]
                + u["cache_read"] * rate["input"] * 0.1
                + u["cache_creation"] * rate["input"] * 2  # ttl 1h -> premio 2x
                + u["output"] * rate["output"]
            ) / 1_000_000
            costo_totale += costo
        if costo_totale:
            print(f"  Stima costo reale (con sconto Batches 50%): ${costo_totale * 0.5:.4f}")
            if usage_totali:
                tot_input = sum(u["input"] + u["cache_read"] + u["cache_creation"] for u in usage_totali.values())
                tot_hit = sum(u["cache_read"] for u in usage_totali.values())
                if tot_input:
                    print(f"  Cache hit rate sul prefisso: {tot_hit / tot_input * 100:.1f}%")
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
