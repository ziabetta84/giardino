#!/usr/bin/env bash
# Backup completo (schema + dati) del database Supabase "Il Giardino di
# Zorba" in un file locale cifrato, mai versionato (vedi .gitignore -> backups/).
# Contiene i dati di tutti gli utenti: per questo e' cifrato con age e ruota
# (la pagina Privacy promette che le copie si distruggono entro 30 giorni).
#
# Uso:
#   1. Prendi la stringa di connessione dal dashboard Supabase
#      (Project Settings -> Database -> Connection string, tab "URI";
#      usa la "Session pooler" se sei dietro NAT/IPv4-only, altrimenti
#      quella diretta).
#   2. Mettila in .env.local (alla radice del repo, gia' escluso da git):
#        SUPABASE_DB_URL=postgresql://postgres.xxxx:LA-TUA-PASSWORD@...
#   3. La prima volta crea la chiave di cifratura (brew install age):
#        mkdir -p ~/.config/giardino && chmod 700 ~/.config/giardino
#        age-keygen -o ~/.config/giardino/backup-age.key
#      e metti la riga "Public key: age1..." che stampa in .env.local:
#        BACKUP_AGE_RECIPIENT=age1...
#      La chiave privata resta nel file e va copiata anche nel gestore di
#      password: senza di lei i backup non si aprono piu'. Mai nel repository.
#   4. Esegui: ./scripts/backup-db.sh
#
# Ripristino: age -d -i ~/.config/giardino/backup-age.key FILE.sql.age | psql ...
# e subito dopo bash scripts/backup/riapplica_eliminazioni.sh, che rifa' le
# eliminazioni degli account successive al backup.
#
# Rotazione (scripts/backup/rotazione.mjs): l'ultimo backup di ogni giorno per
# 7 giorni, l'ultimo di ogni settimana per 4 settimane, niente oltre 30 giorni.
# I dump "completo_*.dump" degli script della tassonomia non ruotano.
#
# Consigliato prima di ogni sessione con scritture massicce (batch di
# importazione fonti, migration su piu' righe) -- e' il momento a piu'
# rischio, come dimostrato dall'incidente del 2026-08-27 (vedi
# fonti/criterio-importazione.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_LOCAL="$REPO_ROOT/.env.local"
BACKUP_DIR="$REPO_ROOT/backups"
PG_DUMP="${PG_DUMP:-/opt/homebrew/opt/postgresql@17/bin/pg_dump}"
PSQL="${PSQL:-/opt/homebrew/opt/postgresql@17/bin/psql}"
REGISTRO="$BACKUP_DIR/account_eliminati.tsv"

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

if ! command -v age >/dev/null; then
  echo "age non trovato. Installa con: brew install age" >&2
  exit 1
fi
if [ -z "${BACKUP_AGE_RECIPIENT:-}" ]; then
  echo "Manca BACKUP_AGE_RECIPIENT in $ENV_LOCAL: vedi le istruzioni in cima a questo script (passo 3)." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$BACKUP_DIR/giardino_zorba_${TIMESTAMP}.sql.age"

# Registro degli account eliminati, tenuto fuori dai backup (solo id e data):
# dopo un ripristino serve a riapplica_eliminazioni.sh. Si aggiunge, non si
# sovrascrive, cosi' resta completo anche se il database torna indietro.
if [ "$("$PSQL" "$SUPABASE_DB_URL" -X -A -t -c "select to_regclass('public.account_eliminati') is not null")" = "t" ]; then
  touch "$REGISTRO"
  { cat "$REGISTRO"; "$PSQL" "$SUPABASE_DB_URL" -X -q -c "\\copy (select id, eliminato_il from public.account_eliminati) to stdout"; } \
    | sort -u -k1,1 > "$REGISTRO.nuovo"
  mv "$REGISTRO.nuovo" "$REGISTRO"
  echo "Registro degli account eliminati: $(wc -l < "$REGISTRO" | tr -d ' ') righe"
fi

echo "Backup in corso -> $OUT_FILE"
trap 'rm -f "$OUT_FILE"' ERR
"$PG_DUMP" "$SUPABASE_DB_URL" --no-owner --no-privileges | age -r "$BACKUP_AGE_RECIPIENT" -o "$OUT_FILE"
trap - ERR
echo "Fatto: $(du -h "$OUT_FILE" | cut -f1)"

node "$REPO_ROOT/scripts/backup/rotazione.mjs" "$BACKUP_DIR" | while IFS= read -r f; do
  echo "Rotazione: cancello $(basename "$f")"
  rm -- "$f"
done
