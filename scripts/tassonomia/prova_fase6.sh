#!/usr/bin/env bash
# Prove della fase 6 (funzioni del catalogo) sulla copia locale: migration e collegamento della sansevieria, prova delle funzioni, rollback rifiutato se
# una pianta non ha più la vecchia specie, rollback, di nuovo la migration. Serve la public.piante minima collegata di
# prova_fase5.sh (lanciarla prima).
# Uso: bash scripts/tassonomia/prova_fase6.sh URL_COPIA      Uscita 0 e ultima riga PROVE FASE 6 OK = riuscite.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
D=scripts/tassonomia
M=supabase/migrations/20261021100000_tassonomia_fase6_catalogo.sql
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
funzioni() { "${PSQL[@]}" -tAc "select count(*) from pg_proc where proname in ('catalogo_voci', 'catalogo_mie_piante', 'cerca_catalogo')"; }
[ "$("${PSQL[@]}" -tAc 'select count(*) from public.piante where num_nonnulls(taxon_id, cultivar_id) = 1')" = 122 ] \
  || fallita preparazione "le piante della copia non sono collegate: lanciare prima prova_fase5.sh"
[ "$(funzioni)" = 0 ] || fallita preparazione "funzioni già presenti"
[ "$("${PSQL[@]}" -tAc "select count(*) from information_schema.column_privileges where grantee = 'anon' and table_name = 'cultivar'")" -gt 0 ] \
  || fallita preparazione "la copia non ha i permessi pubblici delle fasi 1 e 4: rieseguire le righe revoke/grant delle migration"

out=$("${PSQL[@]}" -1 -f $M 2>&1) || fallita migration "$out"
out=$("${PSQL[@]}" -1 -f $D/sansevieria_fase6.sql 2>&1) || fallita sansevieria "$out"
grep -qF 'SANSEVIERIA COLLEGATA' <<<"$out" || fallita sansevieria "$out"
out=$("${PSQL[@]}" -f $D/prova_fase6.sql 2>&1) || fallita catalogo "$out"
grep -qF 'PROVA CATALOGO OK' <<<"$out" || fallita catalogo "$out"
echo "PROVA catalogo OK"

out=$("${PSQL[@]}" -c 'begin' -c "update public.piante set specie = null where id = (select min(id) from public.piante)" \
      -f $D/rollback_fase6.sql 2>&1) && fallita rollback "accettato con una pianta senza vecchia specie"
grep -qF 'Rollback fase 6 rifiutato' <<<"$out" || fallita rollback "$out"
"${PSQL[@]}" -1 -f $D/rollback_sansevieria_fase6.sql
"${PSQL[@]}" -1 -f $D/rollback_fase6.sql
[ "$(funzioni)" = 0 ] || fallita rollback "funzioni ancora presenti"
[ "$("${PSQL[@]}" -tAc "select is_nullable from information_schema.columns where table_name = 'piante' and column_name = 'specie'")" = NO ] \
  || fallita rollback "specie ancora facoltativa"
out=$("${PSQL[@]}" -1 -f $M 2>&1) || fallita rilancio "$out"
out=$("${PSQL[@]}" -1 -f $D/sansevieria_fase6.sql 2>&1) || fallita rilancio "$out"
[ "$(funzioni)" = 3 ] || fallita rilancio "funzioni: $(funzioni)"
echo "PROVA rollback OK"
echo "PROVE FASE 6 OK"
