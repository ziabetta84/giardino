#!/usr/bin/env bash
# Prove della fase 7 (piante.specie tolta) sulla copia locale, allo stato della fase 6 (prova_fase6.sh): fotografia degli
# slug, migration, prova, rollback (slug e colonna di nuovo come prima), di nuovo la migration.
# Uso: bash scripts/tassonomia/prova_fase7.sh URL_COPIA      Uscita 0 e ultima riga PROVE FASE 7 OK = riuscite.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
D=scripts/tassonomia
M=supabase/migrations/20261021120000_tassonomia_fase7_piante_specie.sql
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
foto() { "${PSQL[@]}" -tAc "select md5(string_agg(id || '=' || coalesce(specie, '∅'), ',' order by id)) from public.piante"; }
[ "$("${PSQL[@]}" -tAc "select count(*) from information_schema.columns where table_name = 'piante' and column_name = 'specie'")" = 1 ] \
  || fallita preparazione "la copia non è allo stato della fase 6"
PRIMA=$(foto)
"${PSQL[@]}" -c 'drop table if exists public.prima_fase7' -c 'create table public.prima_fase7 as select id, specie from public.piante'
out=$("${PSQL[@]}" -1 -f $M 2>&1) || fallita migration "$out"
out=$("${PSQL[@]}" -f $D/prova_fase7.sql 2>&1) || fallita fase7 "$out"
grep -qF 'PROVA FASE 7 OK' <<<"$out" || fallita fase7 "$out"
out=$("${PSQL[@]}" -c 'begin' -f $D/rollback_fase6.sql 2>&1) && fallita rollback6 "rollback della fase 6 accettato dopo la fase 7"
grep -qF 'prima rollback_fase7.sql' <<<"$out" || fallita rollback6 "$out"
echo "PROVA fase 7 OK"
"${PSQL[@]}" -1 -f $D/rollback_fase7.sql
[ "$(foto)" = "$PRIMA" ] || fallita rollback "slug diversi dopo il rollback"
[ "$("${PSQL[@]}" -tAc "select count(*) from pg_class where relname = 'piante_vecchie_specie'")" = 0 ] || fallita rollback "tabella ancora presente"
out=$("${PSQL[@]}" -1 -f $M 2>&1) || fallita rilancio "$out"
"${PSQL[@]}" -1 -f $D/rollback_fase7.sql
"${PSQL[@]}" -c 'drop table public.prima_fase7'
echo "PROVA rollback OK"
echo "PROVE FASE 7 OK"
