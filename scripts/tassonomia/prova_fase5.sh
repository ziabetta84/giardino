#!/usr/bin/env bash
# Prove della fase 5 (collegamento delle piante) sulla copia locale: rifiuto se il file non coincide con le piante o se
# una pianta ha cambiato specie, collegamento, rilancio, rollback rifiutato se una pianta è collegata diversamente,
# rollback eseguito, nuovo collegamento. Sulla copia public.piante non c'è (dati dell'utente): la prova ne crea una
# minima con gli id e gli slug del file, con le stesse chiavi esterne e lo stesso vincolo del reale.
# Uso: bash scripts/tassonomia/prova_fase5.sh URL_COPIA      Uscita 0 e ultima riga PROVE FASE 5 OK = riuscite.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
D=scripts/tassonomia
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
stato() { "${PSQL[@]}" -tAc "select count(*) filter (where taxon_id is not null) || ' ' || count(*) filter (where cultivar_id is not null) || ' ' || (select epiteto from public.cultivar where slug = 'capsicum-annuum-piccante-calabrese') from public.piante"; }
"${PSQL[@]}" -c 'drop table if exists public.piante' \
  -c 'create table public.piante (id text primary key, specie text not null, taxon_id uuid references public.taxa (id) on delete restrict,
        cultivar_id uuid references public.cultivar (id) on delete restrict, constraint piante_taxon_o_cultivar check (num_nonnulls(taxon_id, cultivar_id) <= 1))' \
  -c "create temp table f (pianta text, vecchio_slug text, taxon_id uuid, cultivar_id uuid, destinazione text, motivo text)" \
  -c "\copy f from '$D/dati/fase5_piante.tsv' with (format text, header true)" \
  -c 'insert into public.piante (id, specie) select pianta, vecchio_slug from f' \
  -c "update public.cultivar set epiteto = 'Piccante Calabresé' where slug = 'capsicum-annuum-piccante-calabrese'"
TOT=$(($(wc -l < $D/dati/fase5_piante.tsv) - 1))
VUOTO="0 0 Piccante Calabresé"
[ "$(stato)" = "$VUOTO" ] || fallita preparazione "$(stato)"
PIENO="$(awk -F'\t' 'NR > 1 && $3 != "\\N"' $D/dati/fase5_piante.tsv | wc -l | tr -d ' ') $(awk -F'\t' 'NR > 1 && $4 != "\\N"' $D/dati/fase5_piante.tsv | wc -l | tr -d ' ') Piccante Calabrese"

# 1. Rifiuti: una pianta in meno, una pianta che ha cambiato specie (transazioni mai confermate).
out=$("${PSQL[@]}" -c 'begin' -c "delete from public.piante where id = (select min(id) from public.piante)" -f $D/piante_collega.sql 2>&1) && fallita rifiuti "accettato un file che non coincide"
grep -qF 'il file e le piante di oggi non coincidono' <<<"$out" || fallita rifiuti "$out"
out=$("${PSQL[@]}" -c 'begin' -c "update public.piante set specie = 'pomodoro' where id = (select min(id) from public.piante)" -f $D/piante_collega.sql 2>&1) && fallita rifiuti "accettata una pianta con un'altra specie"
grep -qF 'hanno cambiato specie' <<<"$out" || fallita rifiuti "$out"
[ "$(stato)" = "$VUOTO" ] || fallita rifiuti "stato cambiato: $(stato)"
echo "PROVA rifiuti OK"

# 2. Collegamento e rilancio.
out=$("${PSQL[@]}" -1 -f $D/piante_collega.sql 2>&1) || fallita collegamento "$out"
grep -qF "PIANTE COLLEGATE: $TOT" <<<"$out" || fallita collegamento "$out"
[ "$(stato)" = "$PIENO" ] || fallita collegamento "stato $(stato) invece di $PIENO"
out=$("${PSQL[@]}" -1 -f $D/piante_collega.sql 2>&1) || fallita rilancio "$out"
[ "$(stato)" = "$PIENO" ] || fallita rilancio "stato $(stato)"
echo "PROVA collegamento OK"

# 3. Una pianta collegata a qualcos'altro: collegamento e rollback rifiutati.
altro="update public.piante set taxon_id = (select id from public.taxa where rango = 'genus' limit 1), cultivar_id = null where id = (select min(id) from public.piante)"
out=$("${PSQL[@]}" -c 'begin' -c "$altro" -f $D/piante_collega.sql 2>&1) && fallita rifiuti "collegamento accettato su una pianta collegata diversamente"
grep -qF 'già collegate a qualcos' <<<"$out" || fallita rifiuti "$out"
out=$("${PSQL[@]}" -c 'begin' -c "$altro" -f $D/rollback_fase5.sql 2>&1) && fallita rollback "rollback accettato con una pianta collegata diversamente"
grep -qF 'Rollback fase 5 rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(stato)" = "$PIENO" ] || fallita rollback "stato cambiato: $(stato)"

# 4. Rollback eseguito, poi di nuovo il collegamento.
"${PSQL[@]}" -1 -f $D/rollback_fase5.sql
[ "$(stato)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(stato)"
"${PSQL[@]}" -1 -f $D/piante_collega.sql > /dev/null 2>&1 || fallita rollback "nuovo collegamento fallito"
[ "$(stato)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo collegamento: $(stato)"
echo "PROVA rollback OK"
echo "PROVE FASE 5 OK"
