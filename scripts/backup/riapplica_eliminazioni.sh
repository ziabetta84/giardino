#!/usr/bin/env bash
# Dopo il ripristino di un backup: rifà le eliminazioni degli account fatte dopo quel backup, leggendo il registro
# tenuto fuori dai backup (backups/account_eliminati.tsv, aggiornato da scripts/backup-db.sh). Senza questo passo un
# ripristino riporterebbe in vita account e giardini che l'utente aveva cancellato.
# Uso: bash scripts/backup/riapplica_eliminazioni.sh  (legge SUPABASE_DB_URL da .env.local, come backup-db.sh)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRO="$REPO_ROOT/backups/account_eliminati.tsv"
PSQL="${PSQL:-/opt/homebrew/opt/postgresql@17/bin/psql}"
[ -x "$PSQL" ] || PSQL="$(command -v psql)"

if [ -f "$REPO_ROOT/.env.local" ]; then set -a; source "$REPO_ROOT/.env.local"; set +a; fi
: "${SUPABASE_DB_URL:?Manca SUPABASE_DB_URL in .env.local}"
if [ ! -s "$REGISTRO" ]; then echo "Registro vuoto o assente ($REGISTRO): nessuna eliminazione da rifare."; exit 0; fi

"$PSQL" "$SUPABASE_DB_URL" -X -q -1 -v ON_ERROR_STOP=1 <<SQL
create temp table registro (id uuid primary key, eliminato_il timestamptz not null);
\copy registro from '$REGISTRO'
\i $REPO_ROOT/scripts/backup/riapplica_eliminazioni.sql
SQL
