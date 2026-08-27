#!/usr/bin/env bash
# Backup completo (schema + dati) del database Supabase "Il Giardino di
# Zorba" in un file locale, mai versionato (vedi .gitignore -> backups/).
#
# Uso:
#   1. Prendi la stringa di connessione dal dashboard Supabase
#      (Project Settings -> Database -> Connection string, tab "URI";
#      usa la "Session pooler" se sei dietro NAT/IPv4-only, altrimenti
#      quella diretta).
#   2. Mettila in .env.local (alla radice del repo, gia' escluso da git):
#        SUPABASE_DB_URL=postgresql://postgres.xxxx:LA-TUA-PASSWORD@...
#   3. Esegui: ./scripts/backup-db.sh
#
# Consigliato prima di ogni sessione con scritture massicce (batch di
# importazione fonti, migration su piu' righe) -- e' il momento a piu'
# rischio, come dimostrato dall'incidente del 2026-08-27 (vedi
# fonti/criterio-importazione.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_LOCAL="$REPO_ROOT/.env.local"
BACKUP_DIR="$REPO_ROOT/backups"
PG_DUMP="/opt/homebrew/opt/postgresql@17/bin/pg_dump"

if [ ! -x "$PG_DUMP" ]; then
  echo "pg_dump non trovato in $PG_DUMP. Installa con: brew install postgresql@17" >&2
  echo "(deve corrispondere alla versione del server Supabase, attualmente Postgres 17)" >&2
  exit 1
fi

if [ -f "$ENV_LOCAL" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_LOCAL"
  set +a
fi

if [ -z "${SUPABASE_DB_URL:-}" ]; then
  echo "Manca SUPABASE_DB_URL. Aggiungila a $ENV_LOCAL, es.:" >&2
  echo "  SUPABASE_DB_URL=postgresql://postgres.xxxx:password@aws-0-eu-north-1.pooler.supabase.com:5432/postgres" >&2
  echo "(la trovi in Supabase dashboard -> Project Settings -> Database -> Connection string)" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$BACKUP_DIR/giardino_zorba_${TIMESTAMP}.sql"

echo "Backup in corso -> $OUT_FILE"
"$PG_DUMP" "$SUPABASE_DB_URL" --no-owner --no-privileges -f "$OUT_FILE"
echo "Fatto: $(du -h "$OUT_FILE" | cut -f1)"

# Tiene solo gli ultimi 20 backup per non far crescere la cartella all'infinito.
ls -1t "$BACKUP_DIR"/giardino_zorba_*.sql 2>/dev/null | tail -n +21 | while IFS= read -r f; do rm -- "$f"; done
