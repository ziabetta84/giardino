#!/usr/bin/env python3
"""Costruisce e sottomette il batch di verifica indipendente (Haiku 4.5) confrontando
ogni riga originale con la riscrittura prodotta dal batch di scrittura. Le righe già
segnalate `gia_corretto` non vengono verificate (non è stato cambiato nulla).

Uso:
  python3 submit_verify_batch.py --rows prototipo.json --write-results write_results.json --out verify_batch_id.txt
"""
import argparse
import json
from pathlib import Path

from common import load_env, anthropic_client

MODEL = "claude-haiku-4-5"

SYSTEM_PROMPT = """Sei il revisore di fedeltà fattuale per un catalogo botanico italiano. Ti do il testo ORIGINALE (con eventuale inglese) e la RISCRITTURA proposta (traduzione + naturalizzazione). Verifica che la riscrittura non abbia perso, ammorbidito o alterato nessun fatto dell'originale: numeri, colori, periodi di fioritura (ogni periodo è un fatto a sé, mai fondere in un falso continuum), aree di origine, usi, costituenti chimici, voci di `alert` che dovevano essere tradotte.

ECCEZIONI CONSAPEVOLI — NON sono perdita di informazione:
- Nomi comuni non-cultivar omessi di proposito.
- "Famiglia botanica: X. Portamento: Y." reso in prosa naturale invece che come label.
- Citazioni-elenco di cultivar rimosse dalla prosa (i nomi esistono come righe figlie nel database) — a meno che manchi un tratto DISTINTIVO di una cultivar specifica.
- Codici di rusticità RHS tradotti in temperatura invece del codice nudo, se plausibile per il codice.
- Voci di `alert` NON marcate "testo originale in inglese" lasciate invariate.

Segnala come problema reale: numeri diversi, esigenze/aree/usi omessi o alterati, periodi di fioritura fusi impropriamente, traduzioni imprecise dei rischi/parassiti/malattie tradotti, invenzioni non presenti nei dati forniti.

Usa sempre lo strumento fornito per rispondere."""

TOOL = {
    "name": "verdetto",
    "description": "Restituisce il verdetto di fedeltà fattuale",
    "input_schema": {
        "type": "object",
        "properties": {
            "verdetto": {"type": "string", "enum": ["PASS", "FAIL"]},
            "problemi": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["verdetto", "problemi"],
    },
}


def build_request(row: dict, write_output: dict) -> dict:
    payload = {
        "famiglia_botanica": row.get("famiglia_botanica"),
        "ciclo_vitale": row.get("ciclo_vitale"),
        "esigenze": row.get("esigenze"),
        "alert_originale": row.get("alert"),
        "descrizione_originale": row.get("descrizione"),
        "alert_riscritto": write_output.get("alert_riscritto"),
        "descrizione_riscritta": write_output.get("descrizione_riscritta"),
    }
    return {
        "custom_id": row["id"],
        "params": {
            "model": MODEL,
            "max_tokens": 1000,
            "system": SYSTEM_PROMPT,
            "tools": [TOOL],
            "tool_choice": {"type": "tool", "name": TOOL["name"]},
            "messages": [
                {"role": "user", "content": json.dumps(payload, ensure_ascii=False)}
            ],
        },
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--rows", required=True)
    parser.add_argument("--write-results", required=True)
    parser.add_argument("--out", default="verify_batch_id.txt")
    args = parser.parse_args()

    load_env()
    rows = {r["id"]: r for r in json.loads(Path(args.rows).read_text())}
    write_results = json.loads(Path(args.write_results).read_text())

    requests = []
    for row_id, result in write_results.items():
        if not result.get("ok") or row_id not in rows:
            continue
        output = result["output"] or {}
        if output.get("gia_corretto") or output.get("fonte_troncata"):
            continue  # niente da verificare / da non scrivere comunque
        requests.append(build_request(rows[row_id], output))

    if not requests:
        print("Nessuna riga da verificare (tutte già corrette, troncate o senza risultato utile).")
        return

    client = anthropic_client()
    batch = client.messages.batches.create(requests=requests)
    Path(args.out).write_text(batch.id)
    print(f"Batch di verifica sottomesso: {batch.id} ({len(requests)} richieste) -> id salvato in {args.out}")


if __name__ == "__main__":
    main()
