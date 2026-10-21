#!/usr/bin/env bash
# Prova della migration di Zorba su un database usa e getta nel server locale (mai sul reale): lo crea, carica il minimo
# di Supabase (stub_supabase.sql), applica la migration, esegue prova_db.sql e lo cancella. Ultima riga PROVA ZORBA DB OK.
# Uso: bash scripts/zorba/prova_db.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
BIN=/opt/homebrew/opt/postgresql@17/bin
SRV=(-h 127.0.0.1 -p 55440 -U postgres)
DB=zorba_prova
"$BIN/dropdb" "${SRV[@]}" --if-exists "$DB"
"$BIN/createdb" "${SRV[@]}" "$DB"
trap '"$BIN/dropdb" "${SRV[@]}" --if-exists "$DB"' EXIT
PSQL=("$BIN/psql" "${SRV[@]}" -d "$DB" -X -q -v ON_ERROR_STOP=1)
"${PSQL[@]}" -f scripts/zorba/stub_supabase.sql
"${PSQL[@]}" -1 -f supabase/migrations/20261022100000_zorba_agente.sql
"${PSQL[@]}" -f scripts/zorba/prova_db.sql
