#!/usr/bin/env bash
# Copia locale di public.specie, public.generi e delle tabelle del modello tassonomico (taxa, nomi_comuni, cultivar,
# schede, mappa_specie) presa da un backup completo (pg_dump -Fc), per provare le operazioni in blocco del modello
# tassonomico senza toccare il database reale (specifica, "Decisioni sullo
# spazio", punto 5). Cluster Postgres 17 temporaneo su 127.0.0.1:55440, senza password: contiene solo il
# catalogo, che è già pubblico. Stesso statement_timeout del pooler di Supabase (2 minuti) e messaggi in inglese.
# Uso:
#   bash scripts/tassonomia/copia_locale.sh crea BACKUP.dump CARTELLA   (stampa l'URL della copia)
#   bash scripts/tassonomia/copia_locale.sh ferma CARTELLA              (ferma il cluster e cancella CARTELLA)
set -euo pipefail
cd "$(dirname "$0")/../.."
BIN=/opt/homebrew/opt/postgresql@17/bin
PORTA=55440
URL="postgresql://postgres@127.0.0.1:$PORTA/giardino"

case "${1:-}" in
  crea)
    dump=${2:?manca BACKUP}; dir=${3:?manca CARTELLA}
    [ -f "$dump" ] || { echo "Backup non trovato: $dump" >&2; exit 1; }
    [ ! -e "$dir" ] || { echo "La cartella $dir esiste già" >&2; exit 1; }
    mkdir -p "$dir"
    "$BIN/initdb" -D "$dir/dati" -U postgres --auth=trust -E UTF8 --locale=en_US.UTF-8 > "$dir/initdb.log"
    "$BIN/pg_ctl" -D "$dir/dati" -l "$dir/server.log" -w start \
      -o "-c listen_addresses=127.0.0.1 -c unix_socket_directories='' -p $PORTA -c statement_timeout=2min -c lc_messages=C" > /dev/null
    "$BIN/createdb" -h 127.0.0.1 -p "$PORTA" -U postgres giardino
    "$BIN/psql" "$URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/copia_locale_prep.sql
    "$BIN/pg_restore" -l "$dump" \
      | grep -E '^[0-9]+; [0-9]+ [0-9]+ (TABLE|TABLE DATA|CONSTRAINT|FK CONSTRAINT|INDEX|TRIGGER|POLICY|ROW SECURITY) public (specie|generi|taxa|nomi_comuni|cultivar|schede|mappa_specie)[ _]' \
      > "$dir/elenco.txt"
    "$BIN/pg_restore" --exit-on-error --no-owner --no-privileges -d "$URL" -L "$dir/elenco.txt" "$dump"
    "$BIN/psql" "$URL" -X -q -v ON_ERROR_STOP=1 -c 'vacuum analyze public.specie, public.generi'
    echo "$URL"
    ;;
  ferma)
    dir=${2:?manca CARTELLA}
    [ -d "$dir/dati" ] || { echo "Nessuna copia in $dir" >&2; exit 1; }
    "$BIN/pg_ctl" -D "$dir/dati" -w stop -m fast > /dev/null
    rm -rf -- "$dir"
    ;;
  *)
    echo "Uso: $0 crea BACKUP.dump CARTELLA | ferma CARTELLA" >&2; exit 1 ;;
esac
