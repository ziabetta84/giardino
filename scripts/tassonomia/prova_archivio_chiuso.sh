#!/usr/bin/env bash
# Prova della chiusura dell'archivio sulla copia locale: rimette sulla copia i permessi del reale di oggi (il backup è
# senza privilegi), verifica che fallisca, migration, verifica, rollback (permessi e policy di prima), di nuovo la
# migration e infine il rollback, per lasciare la copia com'era.
# Uso: bash scripts/tassonomia/prova_archivio_chiuso.sh URL_COPIA   Ultima riga PROVA ARCHIVIO CHIUSO OK = riuscita.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
D=scripts/tassonomia
M=supabase/migrations/20261021140000_tassonomia_archivio_chiuso.sql
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
stato() { "${PSQL[@]}" -tAc "select (select string_agg(grantee || ':' || table_name || ':' || privilege_type, ',' order by grantee, table_name, privilege_type)
  from information_schema.role_table_grants where table_schema = 'public' and table_name in ('specie', 'generi')
  and grantee in ('anon', 'authenticated', 'service_role')) || ' | ' || (select string_agg(tablename || ':' || policyname || ':' || cmd || ':' || qual, ','
  order by tablename) from pg_policies where tablename in ('specie', 'generi'))"; }
"${PSQL[@]}" -c 'grant all on public.specie, public.generi to anon, authenticated, service_role'
PRIMA=$(stato)
out=$("${PSQL[@]}" -f $D/verifica_archivio_chiuso.sql 2>&1) && fallita rosso "verifica riuscita prima della migration"
grep -qF 'ha ancora permessi' <<<"$out" || grep -qF 'policy ancora presenti' <<<"$out" || fallita rosso "$out"
"${PSQL[@]}" -1 -f $M
out=$("${PSQL[@]}" -f $D/verifica_archivio_chiuso.sql 2>&1) || fallita verifica "$out"
grep -qF 'VERIFICA ARCHIVIO CHIUSO OK' <<<"$out" || fallita verifica "$out"
"${PSQL[@]}" -1 -f $D/rollback_archivio_chiuso.sql
[ "$(stato)" = "$PRIMA" ] || fallita rollback "permessi o policy diversi da prima: $(stato)"
"${PSQL[@]}" -1 -f $M
"${PSQL[@]}" -f $D/verifica_archivio_chiuso.sql >/dev/null
"${PSQL[@]}" -1 -f $D/rollback_archivio_chiuso.sql
echo "PROVA ARCHIVIO CHIUSO OK"
