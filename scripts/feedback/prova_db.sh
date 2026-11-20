#!/usr/bin/env bash
# Prova della migration del feedback della beta su un database usa e getta (mai sul reale): lo crea, carica il minimo
# di Supabase (stub degli account), applica le migration dell'eliminazione dell'account e questa, poi esegue
# prova_db.sql e lo cancella. Ultima riga PROVA FEEDBACK OK.
# Uso: bash scripts/feedback/prova_db.sh  (PGHOST/PGPORT/PGUSER per il server locale; predefinito quello di prova_db di Zorba)
set -euo pipefail
cd "$(dirname "$0")/../.."
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-55440}" PGUSER="${PGUSER:-postgres}"
BIN="${PGBIN:-$(dirname "$(command -v psql)")}"
DB=feedback_prova
"$BIN/dropdb" --if-exists "$DB"
"$BIN/createdb" "$DB"
trap '"$BIN/dropdb" --if-exists "$DB"' EXIT
PSQL=("$BIN/psql" -d "$DB" -X -q -v ON_ERROR_STOP=1)
"${PSQL[@]}" -f scripts/account/stub_supabase.sql
"${PSQL[@]}" -f scripts/feedback/stub_auth.sql
"${PSQL[@]}" -1 -f supabase/migrations/20261030120000_elimina_account.sql
"${PSQL[@]}" -1 -f supabase/migrations/20261030130000_account_eliminati.sql
"${PSQL[@]}" -1 -f supabase/migrations/20261120100000_feedback_beta.sql
"${PSQL[@]}" -f scripts/feedback/prova_db.sql
