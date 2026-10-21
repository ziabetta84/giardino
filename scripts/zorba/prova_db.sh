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

# Storico: l'owner e i progetti a cui puntano i fili (riga "-- progetti:" scritta dal generatore) vanno creati nella copia
ST=supabase/migrations/20261022110000_zorba_storico.sql
"${PSQL[@]}" -c "insert into auth.users values ('fc227422-ece8-4dca-b706-956ec7ca9e6e') on conflict do nothing"
for p in $(sed -n 's/^-- progetti: //p' "$ST" | tr ',' ' '); do
  "${PSQL[@]}" -c "insert into public.progetti (id, owner_id, titolo) values ('$p', 'fc227422-ece8-4dca-b706-956ec7ca9e6e', 'prova')"
done
"${PSQL[@]}" -f "$ST"
test "$("${PSQL[@]}" -tAc "select count(*) from public.zorba_fili where importato")" = 43 || { echo "STORICO: numero di fili errato" >&2; exit 1; }
test "$("${PSQL[@]}" -tAc "select count(*) from public.zorba_consumi where owner_id = 'fc227422-ece8-4dca-b706-956ec7ca9e6e'")" = 0 || { echo "STORICO: consumi" >&2; exit 1; }
test "$("${PSQL[@]}" -tAc "select count(*) from public.zorba_fili where importato and tipo = 'segnalazione_scheda' and segnalazione_stato <> 'accolta'")" = 0 || { echo "STORICO: segnalazioni" >&2; exit 1; }
echo "PROVA STORICO OK"
