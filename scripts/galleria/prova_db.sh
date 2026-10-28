#!/usr/bin/env bash
# Prova della migration della galleria su un database usa e getta (mai sul reale): lo crea, carica il minimo di
# Supabase (stub_supabase.sql), applica la migration, esegue prova_db.sql e lo cancella. Ultima riga PROVA GALLERIA OK.
# Uso: bash scripts/galleria/prova_db.sh  (PGHOST/PGPORT/PGUSER per il server locale; predefinito quello di prova_db di Zorba)
set -euo pipefail
cd "$(dirname "$0")/../.."
export PGHOST="${PGHOST:-127.0.0.1}" PGPORT="${PGPORT:-55440}" PGUSER="${PGUSER:-postgres}"
BIN="${PGBIN:-$(dirname "$(command -v psql)")}"
DB=galleria_prova
"$BIN/dropdb" --if-exists "$DB"
"$BIN/createdb" "$DB"
trap '"$BIN/dropdb" --if-exists "$DB"' EXIT
PSQL=("$BIN/psql" -d "$DB" -X -q -v ON_ERROR_STOP=1)
"${PSQL[@]}" -f scripts/galleria/stub_supabase.sql
"${PSQL[@]}" -1 -f supabase/migrations/20261028120000_galleria_foto.sql
"${PSQL[@]}" -f scripts/galleria/prova_db.sql
