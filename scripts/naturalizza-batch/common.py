"""Utility condivise per il batch di naturalizzazione/traduzione via Anthropic
Message Batches API. Vedi .claude/commands/naturalizza-descrizioni.md per le
regole di stile e lo scope, e la memoria di progetto "naturalizzazione-descrizioni"
per la decisione di passare a questo script (costo troppo alto via agenti Claude Code).
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
ENV_LOCAL = HERE.parent.parent / ".env.local"


def load_env():
    """Carica SUPABASE_DB_URL e ANTHROPIC_API_KEY da .env.local nell'ambiente."""
    if not ENV_LOCAL.exists():
        return
    for line in ENV_LOCAL.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


def run_psql_json(query: str):
    """Esegue una query che produce un unico JSON (json_agg/row_to_json) e la ritorna parsata."""
    db_url = os.environ.get("SUPABASE_DB_URL")
    if not db_url:
        sys.exit("Manca SUPABASE_DB_URL in .env.local")
    result = subprocess.run(
        ["psql", db_url, "-t", "-A", "-c", query],
        capture_output=True, text=True, check=True,
    )
    text = result.stdout.strip()
    return json.loads(text) if text else []


def run_psql_file(sql_file: Path):
    """Applica un file .sql via psql, in un'unica transazione, fermandosi al primo errore."""
    db_url = os.environ.get("SUPABASE_DB_URL")
    if not db_url:
        sys.exit("Manca SUPABASE_DB_URL in .env.local")
    subprocess.run(
        ["psql", "-v", "ON_ERROR_STOP=1", "-1", db_url, "-f", str(sql_file)],
        check=True,
    )


def anthropic_client():
    from anthropic import Anthropic
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        sys.exit("Manca ANTHROPIC_API_KEY in .env.local")
    return Anthropic(api_key=api_key)


def poll_batch_until_done(client, batch_id: str, poll_seconds: int = 30):
    """Interroga lo stato del batch finché non è 'ended', stampando avanzamento."""
    while True:
        batch = client.messages.batches.retrieve(batch_id)
        counts = batch.request_counts
        print(
            f"  stato={batch.processing_status} "
            f"completate={counts.succeeded} errori={counts.errored} "
            f"annullate={counts.canceled} scadute={counts.expired} "
            f"in_corso={counts.processing}"
        )
        if batch.processing_status == "ended":
            return batch
        time.sleep(poll_seconds)


def save_json(path: Path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1))


def load_json(path: Path):
    return json.loads(Path(path).read_text())
