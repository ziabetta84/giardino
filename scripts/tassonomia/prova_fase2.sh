#!/usr/bin/env bash
# Prove della fase 2 (caricamento di taxa) sulla copia locale: rifiuti, lotto alterato, spazio, interruzione e ripresa,
# rilancio a caricamento finito, altra versione di COL, rollback (anche rifiutato) e nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase2.sh URL_COPIA CARTELLA_LOTTI CARTELLA      (CARTELLA nuova a ogni giro)
# Uscita 0 = tutte le prove passate; alla fine taxa della copia contiene il caricamento completo.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; LOTTI=${2:?manca CARTELLA_LOTTI}; OUT=${3:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
[ ! -e "$OUT" ] || { echo "La cartella $OUT esiste già: usarne una nuova" >&2; exit 1; }
D=scripts/tassonomia
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
righe_col() { "${PSQL[@]}" -tAc "select count(*) from public.taxa where origine = 'col'"; }
ATTESE=$(awk -F'\t' '{ s += $2 } END { print s }' "$LOTTI/manifest.tsv")
PRIMO=$(head -1 "$LOTTI/manifest.tsv" | cut -f2)
LOTTI_N=$(wc -l < "$LOTTI/manifest.tsv" | tr -d ' ')
[ "$(righe_col)" = 0 ] || fallita preparazione "taxa della copia non è vuota: prima rollback_fase2.sql"

# 1. Rifiuti, prima di qualsiasi connessione: reale senza conferma, pooler in modalità transazione.
out=$(bash $D/carica_taxa.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$LOTTI" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_taxa.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$LOTTI" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. Lotto alterato (un carattere in più): rifiuto prima di scrivere.
cp -R "$LOTTI" "$OUT/lotti_alterati"
printf 'x' >> "$OUT/lotti_alterati/lotto_02.csv"
out=$(bash $D/carica_taxa.sh "$URL" "$OUT/lotti_alterati" "$OUT/r3" 2>&1) && fallita lotto_alterato "nessun errore"
grep -qF 'RIFIUTATO: lotto_02.csv diverso da quello del manifesto' <<<"$out" || fallita lotto_alterato "$out"
[ "$(righe_col)" = 0 ] || fallita lotto_alterato "caricate righe"
echo "PROVA lotto_alterato OK"

# 3. Spazio insufficiente: si ferma prima di caricare.
out=$(SOGLIA_MB=1 bash $D/carica_taxa.sh "$URL" "$LOTTI" "$OUT/r4" 2>&1) && fallita spazio "nessun errore"
grep -qF 'ERROR:  spazio insufficiente per caricare' <<<"$out" || fallita spazio "$out"
grep -qF 'FERMATO: spazio insufficiente prima di inizio' <<<"$out" || fallita spazio "$out"
[ "$(righe_col)" = 0 ] || fallita spazio "caricate righe"
echo "PROVA spazio OK"

# 4. Interruzione durante la pausa dopo il primo lotto (come un terminale chiuso), poi ripresa con lo stesso comando.
set -m
PAUSA_S=60 bash $D/carica_taxa.sh "$URL" "$LOTTI" "$OUT/r5" > "$OUT/r5.log" 2>&1 &
pid=$!
set +m
n=0
until grep -q 'pausa' "$OUT/r5/tempi.txt" 2>/dev/null; do
  n=$((n + 1)); [ "$n" -lt 1200 ] || fallita ripresa "pausa mai raggiunta: $(cat "$OUT/r5.log")"
  sleep 0.1
done
kill -TERM -- -"$pid"
if wait "$pid"; then fallita ripresa "uscita 0 dopo l'interruzione"; fi
[ "$(righe_col)" = "$PRIMO" ] || fallita ripresa "dopo l'interruzione $(righe_col) righe (attese $PRIMO, il primo lotto)"
bash $D/carica_taxa.sh "$URL" "$LOTTI" "$OUT/r6" > "$OUT/r6.log" 2>&1 || fallita ripresa "$(cat "$OUT/r6.log")"
[ "$(tail -1 "$OUT/r6.log")" = 'CARICAMENTO TAXA OK' ] || fallita ripresa "$(cat "$OUT/r6.log")"
grep -qF 'lotto_01.csv già caricato' "$OUT/r6/tempi.txt" || fallita ripresa "il primo lotto non è stato saltato"
[ "$(righe_col)" = "$ATTESE" ] || fallita ripresa "$(righe_col) righe (attese $ATTESE)"
awk '/WAL/ { if ($(NF - 1) + 0 > 100) bad = 1 } END { exit bad }' "$OUT/r5/tempi.txt" "$OUT/r6/tempi.txt" \
  || fallita ripresa "un passo ha superato 100 MB di WAL"
echo "PROVA ripresa OK"

# 5. Rilancio a caricamento finito: salta tutti i lotti, nessuna pausa, verifica superata.
bash $D/carica_taxa.sh "$URL" "$LOTTI" "$OUT/r7" > "$OUT/r7.log" 2>&1 || fallita rilancio "$(cat "$OUT/r7.log")"
[ "$(grep -c 'già caricato' "$OUT/r7/tempi.txt")" = "$LOTTI_N" ] || fallita rilancio "lotti non saltati"
! grep -q 'pausa' "$OUT/r7/tempi.txt" || fallita rilancio "pausa senza lotti da caricare"
[ "$(righe_col)" = "$ATTESE" ] || fallita rilancio "righe cambiate"
echo "PROVA rilancio OK"

# 6. Lotti di un'altra versione di COL con taxa già caricata: rifiuto.
cp -R "$LOTTI" "$OUT/lotti_altra"
echo 'COL26.10 XR' > "$OUT/lotti_altra/versione.txt"
out=$(bash $D/carica_taxa.sh "$URL" "$OUT/lotti_altra" "$OUT/r8" 2>&1) && fallita altra_versione "nessun errore"
grep -qF "RIFIUTATO: taxa contiene $ATTESE righe di un'altra versione di COL" <<<"$out" || fallita altra_versione "$out"
echo "PROVA altra_versione OK"

# 7. Rollback: rifiutato se taxa è già usata (qui un nome comune in una transazione mai confermata), poi eseguito,
#    poi un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' \
        -c "insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) select id, 'it', 'prova', '{prova}' from public.taxa limit 1" \
        -f $D/rollback_fase2.sql 2>&1) && fallita rollback "rollback accettato con taxa in uso"
grep -qF 'Rollback fase 2 rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(righe_col)" = "$ATTESE" ] || fallita rollback "righe tolte da un rollback rifiutato"
"${PSQL[@]}" -1 -f $D/rollback_fase2.sql
"${PSQL[@]}" -c 'vacuum full public.taxa'
[ "$(righe_col)" = 0 ] || fallita rollback "righe rimaste dopo il rollback"
bash $D/carica_taxa.sh "$URL" "$LOTTI" "$OUT/r9" > "$OUT/r9.log" 2>&1 || fallita rollback "nuovo caricamento: $(cat "$OUT/r9.log")"
[ "$(righe_col)" = "$ATTESE" ] || fallita rollback "$(righe_col) righe dopo il nuovo caricamento"
echo "PROVA rollback OK"

# 8. Rollback dopo un caricamento interrotto, con gli indici secondari già tolti da carica_taxa.sh: deve riuscire in
#    pochi secondi (senza gli indici le chiavi esterne di taxa verso se stessa fanno una scansione completa per ogni
#    riga cancellata e la DELETE va in timeout), poi un nuovo caricamento completo.
"${PSQL[@]}" -c 'drop index public.taxa_padre_id_idx, public.taxa_accettato_id_idx, public.taxa_nome_scientifico_trgm_idx'
inizio=$(date +%s)
"${PSQL[@]}" -1 -f $D/rollback_fase2.sql || fallita rollback_senza_indici "rollback non riuscito"
durata=$(( $(date +%s) - inizio ))
[ "$durata" -lt 120 ] || fallita rollback_senza_indici "rollback durato $durata s"
"${PSQL[@]}" -c 'vacuum full public.taxa'
[ "$(righe_col)" = 0 ] || fallita rollback_senza_indici "righe rimaste"
[ "$("${PSQL[@]}" -tAc "select count(*) from pg_indexes where schemaname = 'public' and tablename = 'taxa'")" = 5 ] \
  || fallita rollback_senza_indici "dopo il rollback taxa non ha i suoi 5 indici"
bash $D/carica_taxa.sh "$URL" "$LOTTI" "$OUT/r10" > "$OUT/r10.log" 2>&1 || fallita rollback_senza_indici "nuovo caricamento: $(cat "$OUT/r10.log")"
echo "PROVA rollback_senza_indici OK"
echo "PROVE FASE 2 OK"
