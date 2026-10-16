#!/usr/bin/env bash
# Prove della fase 4a (taxon in più e cultivar) sulla copia locale: rifiuti, file alterato, ordine sbagliato, ripresa
# dopo un lotto fallito, caricamento, rilancio, rollback rifiutato ed eseguito, nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase4a.sh URL_COPIA CARTELLA_ESPORTA CARTELLA      (CARTELLA nuova a ogni giro)
#   CARTELLA_ESPORTA = cartella scritta da cultivar_esporta.sh (sottocartelle taxa e cultivar). La copia deve essere
#   allo stato della fase 3 con la migration delle colonne della fase 4 applicata e cultivar vuota.
# Uscita 0 = tutte le prove passate; alla fine la copia contiene il caricamento completo.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; E=${2:?manca CARTELLA_ESPORTA}; OUT=${3:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
[ ! -e "$OUT" ] || { echo "La cartella $OUT esiste già: usarne una nuova" >&2; exit 1; }
D=scripts/tassonomia
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
conta() { "${PSQL[@]}" -tAc "select (select count(*) from public.cultivar) || ' ' || (select count(*) from public.mappa_specie m
  where m.cultivar_id is not null or exists (select 1 from public.specie s where s.id = m.vecchia_specie_id and s.nome_scientifico like '%''%'))
  || ' ' || (select count(*) from public.taxa where nota = 'importato nella fase 4 (cultivar)')"; }
NUOVI=$(awk -F'\t' '{ s += $2 } END { print s }' "$E/taxa/manifest.tsv")
CULTIVAR=$(awk -F'\t' '$1 ~ /^cultivar_/ { s += $2 } END { print s }' "$E/cultivar/manifest.tsv")
MAPPA=$(awk -F'\t' '$1 == "mappa.csv" { print $2 }' "$E/cultivar/manifest.tsv")
LOTTO1=$(awk -F'\t' '$1 == "cultivar_01.csv" { print $2 }' "$E/cultivar/manifest.tsv")
VUOTO="0 0 0"
PIENO="$CULTIVAR $MAPPA $NUOVI"
[ "$(conta)" = "$VUOTO" ] || fallita preparazione "la copia non è nello stato della fase 3 ($(conta)): prima rollback_fase4a.sql"
carica() {  # carica CARTELLA PROVA: taxon in più e poi cultivar, con log in OUT
  bash $D/carica_taxa.sh "$URL" "$E/taxa" "$OUT/$1_taxa" > "$OUT/$1_taxa.log" 2>&1 || fallita "$2" "carica_taxa: $(tail -3 "$OUT/$1_taxa.log")"
  bash $D/carica_cultivar.sh "$URL" "$E/cultivar" "$OUT/$1_cultivar" > "$OUT/$1_cultivar.log" 2>&1 \
    || fallita "$2" "carica_cultivar: $(tail -3 "$OUT/$1_cultivar.log")"
  [ "$(tail -1 "$OUT/$1_cultivar.log")" = 'CARICAMENTO CULTIVAR OK' ] || fallita "$2" "$(tail -3 "$OUT/$1_cultivar.log")"
}

# 1. Rifiuti, prima di qualsiasi connessione.
out=$(bash $D/carica_cultivar.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$E/cultivar" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_cultivar.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$E/cultivar" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. File alterato: rifiuto prima di scrivere.
cp -R "$E/cultivar" "$OUT/cultivar_alterata"
printf 'x' >> "$OUT/cultivar_alterata/cultivar_02.csv"
out=$(bash $D/carica_cultivar.sh "$URL" "$OUT/cultivar_alterata" "$OUT/r3" 2>&1) && fallita alterato "nessun errore"
grep -qF 'RIFIUTATO: cultivar_02.csv diverso da quello del manifesto' <<<"$out" || fallita alterato "$out"
[ "$(conta)" = "$VUOTO" ] || fallita alterato "caricato qualcosa: $(conta)"
echo "PROVA alterato OK"

# 3. Ordine sbagliato (cultivar prima dei taxon nuovi): le cultivar delle specie nuove sono nel primo lotto, che non
#    entra (chiave esterna); non entra niente.
out=$(bash $D/carica_cultivar.sh "$URL" "$E/cultivar" "$OUT/r4" 2>&1) && fallita ordine "nessun errore"
grep -qF 'violates foreign key constraint' <<<"$out" || fallita ordine "$out"
[ "$(conta)" = "$VUOTO" ] || fallita ordine "stato inatteso: $(conta)"
echo "PROVA ordine OK"

# 4. Ripresa: il secondo lotto fallisce (una riga con lo stesso slug della sua prima riga, già presente); il primo
#    resta. Tolta la riga, il rilancio salta il primo lotto e carica il resto.
bash $D/carica_taxa.sh "$URL" "$E/taxa" "$OUT/r5_taxa" > "$OUT/r5_taxa.log" 2>&1 || fallita ripresa "carica_taxa: $(tail -3 "$OUT/r5_taxa.log")"
"${PSQL[@]}" -c "insert into public.cultivar (slug, taxon_id, epiteto, fonti)
                 select slug, taxon_id, 'Prova', '{prova}' from (select split_part(l, ',', 2) as slug, split_part(l, ',', 3)::uuid as taxon_id
                   from (select '$(sed -n 2p "$E/cultivar/cultivar_02.csv" | cut -d, -f1-3)'::text as l) x) y"
out=$(bash $D/carica_cultivar.sh "$URL" "$E/cultivar" "$OUT/r5" 2>&1) && fallita ripresa "nessun errore con il secondo lotto in conflitto"
grep -qF 'duplicate key value' <<<"$out" || fallita ripresa "$out"
[ "$("${PSQL[@]}" -tAc "select count(*) from public.cultivar where epiteto <> 'Prova'")" = "$LOTTO1" ] \
  || fallita ripresa "dopo il lotto fallito ci sono $("${PSQL[@]}" -tAc 'select count(*) from public.cultivar') cultivar"
"${PSQL[@]}" -c "delete from public.cultivar where epiteto = 'Prova' and fonti = '{prova}'"
bash $D/carica_cultivar.sh "$URL" "$E/cultivar" "$OUT/r6" > "$OUT/r6.log" 2>&1 || fallita ripresa "rilancio: $(tail -3 "$OUT/r6.log")"
grep -qF 'cultivar_01.csv già caricato' "$OUT/r6/tempi.txt" || fallita ripresa "primo lotto ricaricato"
[ "$(conta)" = "$PIENO" ] || fallita ripresa "stato inatteso: $(conta) invece di $PIENO"
echo "PROVA ripresa OK"

# 5. Rilancio: tutto saltato, stato invariato.
carica r7 rilancio
grep -qF 'cultivar_02.csv già caricato' "$OUT/r7_cultivar/tempi.txt" || fallita rilancio "lotto delle cultivar ricaricato"
grep -qF 'righe di mappa delle cultivar già caricate' "$OUT/r7_cultivar/tempi.txt" || fallita rilancio "mappa ricaricata"
[ "$(conta)" = "$PIENO" ] || fallita rilancio "stato cambiato: $(conta)"
echo "PROVA rilancio OK"

# 6. Rollback: rifiutato se la fase 4b ha già una scheda di cultivar (in una transazione mai confermata), poi eseguito
#    e seguito da un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' \
        -c "insert into public.schede (cultivar_id, fonti) select id, '{prova}' from public.cultivar limit 1" \
        -f $D/rollback_fase4a.sql 2>&1) && fallita rollback "rollback accettato con la fase 4b iniziata"
grep -qF 'Rollback fase 4a rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback "un rollback rifiutato ha tolto righe: $(conta)"
"${PSQL[@]}" -1 -f $D/rollback_fase4a.sql
"${PSQL[@]}" -c 'vacuum full public.mappa_specie' -c 'vacuum full public.cultivar' -c 'vacuum full public.taxa'
[ "$(conta)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(conta) invece di $VUOTO"
carica r8 rollback
[ "$(conta)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo caricamento: $(conta)"
echo "PROVA rollback OK"
echo "PROVE FASE 4A OK"
