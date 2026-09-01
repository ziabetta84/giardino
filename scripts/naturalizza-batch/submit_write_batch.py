#!/usr/bin/env python3
"""Costruisce e sottomette il batch di scrittura (Sonnet 5) che naturalizza/traduce
le righe esportate da export_rows.py. Regole di stile complete in
.claude/commands/naturalizza-descrizioni.md — qui sotto solo la versione compatta
per il prompt.

Uso:
  python3 submit_write_batch.py --in prototipo.json --out write_batch_id.txt
"""
import argparse
import json
from pathlib import Path

from common import load_env, anthropic_client

MODEL = "claude-sonnet-5"

SYSTEM_PROMPT = """Riscrivi la descrizione di specie botaniche per un catalogo italiano ("Giardino di Rob"), traducendo l'inglese residuo e applicando uno stile narrativo naturale, seguendo queste regole non negoziabili:

1. ZERO PERDITA DI INFORMAZIONI: ogni fatto, numero, colore, periodo di fioritura (ogni periodo elencato è un fatto a sé, non fonderli in un falso continuum), areale, uso alimentare/medicinale/industriale, costituente chimico presente nel testo originale deve comparire nel riscritto.
2. ZERO INVENZIONE: non aggiungere aggettivi, giudizi di valore o dettagli non presenti nei dati forniti. Se il materiale è scarso, va bene una riscrittura breve.
3. NIENTE LABEL "Famiglia botanica: X. Portamento: Y.": sono già colonne proprie del database (famiglia_botanica, ciclo_vitale), quindi ometterle come dump non è perdita — ma puoi comunque menzionarle in prosa naturale (es. "arbusto della famiglia delle Rosaceae"). Se il tipo comune coincide col nome della famiglia (es. "orchidea"/Orchidaceae) usa un termine neutro ("pianta della famiglia delle Orchidaceae") per non essere ridondante.
4. NOMI COMUNI: escludili sempre, a meno che non siano nomi di cultivar/varietà specifici (tra apici singoli) o nomi comuni realmente diffusi anche in italiano (es. "Rambutan", "Durian", "Mango"). Non inventare mai una traduzione italiana di un nome comune inglese che non esiste davvero in italiano — in quel caso usa il nome scientifico come soggetto della frase.
5. RUSTICITÀ RHS (H1a-H7): traducila SEMPRE in una temperatura testuale, mai il codice nudo, secondo questa tabella ufficiale (rhs.org.uk/advice/rhs-hardiness-rating): H1a oltre 15°C (serra riscaldata, tropicale); H1b 10-15°C (serra riscaldata, subtropicale); H1c 5-10°C (serra riscaldata, temperato caldo); H2 1-5°C (delicata, serra fresca/priva di gelo); H3 da -5 a 1°C (poco rustica, serra non riscaldata/riparo); H4 da -10 a -5°C (rustica, inverno medio); H5 da -15 a -10°C (rustica, inverno freddo); H6 da -20 a -15°C (molto rustica, inverno molto freddo); H7 sotto -20°C (estremamente rustica). Non aggiungere interpretazioni oltre questa tabella.
6. NIENTE CITAZIONI-ELENCO DI CULTIVAR tipo "RHS elenca N cultivar coltivate (tra cui 'A', 'B')": i nomi esistono già come righe figlie nel database, ometterli non è perdita. Se una cultivar ha un tratto DISTINTIVO proprio descritto nel testo (es. un colore diverso dei fiori), menzionalo comunque brevemente nella narrativa della specie madre (non creare qui righe separate).
7. NIENTE TIC DA IA: mai "non solo... ma anche", "un vero e proprio", "regalando/regalandoci", "cornice ideale", "vero gioiello". Varia la struttura delle frasi.
8. CAMPO `alert`: contiene voci già strutturate (dati verificati). Alcune voci hanno testo inglese marcato con la dicitura "(testo originale in inglese...)" — quelle SI vanno tradotte in italiano (rimuovendo quella dicitura, ormai falsa, ma mantenendo il prefisso semantico come "Parassiti:", "Malattie:", "Potatura:", "Propagazione:", "Rischi segnalati dalla fonte:"). Le altre voci (nome comune inglese, rusticità con codice, dimensioni RHS, disclaimer "scheda in bozza") vanno restituite ESATTAMENTE come sono, senza modificarle. Restituisci l'intero array `alert`, nello stesso ordine e con lo stesso numero di voci dell'originale, con solo le voci pertinenti tradotte.
9. Se il testo originale della fonte è chiaramente troncato a metà frase, NON completarlo di tua iniziativa: traduci fedelmente fino al punto di interruzione e segnala il troncamento nel campo `fonte_troncata`.
10. Se `descrizione` è già in italiano corretto e non contiene affatto inglese da tradurre, restituiscila invariata (stessa cosa per `alert`) e segnala `gia_corretto: true`.

Usa sempre lo strumento fornito per rispondere, in un'unica chiamata."""

TOOL = {
    "name": "restituisci_riscrittura",
    "description": "Restituisce la descrizione riscritta, l'array alert aggiornato e i flag di controllo qualità",
    "input_schema": {
        "type": "object",
        "properties": {
            "descrizione_riscritta": {"type": "string"},
            "alert_riscritto": {"type": "array", "items": {"type": "string"}},
            "fonte_troncata": {"type": "boolean"},
            "gia_corretto": {"type": "boolean"},
        },
        "required": ["descrizione_riscritta", "alert_riscritto", "fonte_troncata", "gia_corretto"],
    },
}


def build_request(row: dict) -> dict:
    user_payload = {
        "nome": row.get("nome"),
        "famiglia_botanica": row.get("famiglia_botanica"),
        "ciclo_vitale": row.get("ciclo_vitale"),
        "esigenze": row.get("esigenze"),
        "alert": row.get("alert"),
        "descrizione": row.get("descrizione"),
    }
    return {
        "custom_id": row["id"],
        "params": {
            "model": MODEL,
            "max_tokens": 2000,
            "system": SYSTEM_PROMPT,
            "tools": [TOOL],
            "tool_choice": {"type": "tool", "name": TOOL["name"]},
            "messages": [
                {"role": "user", "content": json.dumps(user_payload, ensure_ascii=False)}
            ],
        },
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--in", dest="infile", required=True)
    parser.add_argument("--out", default="write_batch_id.txt")
    args = parser.parse_args()

    load_env()
    rows = json.loads(Path(args.infile).read_text())
    requests = [build_request(r) for r in rows]

    client = anthropic_client()
    batch = client.messages.batches.create(requests=requests)
    Path(args.out).write_text(batch.id)
    print(f"Batch di scrittura sottomesso: {batch.id} ({len(requests)} richieste) -> id salvato in {args.out}")
    print("Usa fetch_results.py per attendere e scaricare i risultati.")


if __name__ == "__main__":
    main()
