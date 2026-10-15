#!/usr/bin/env bash
# Prove della fase 1b (manutenzione di specie) sulla copia locale creata con copia_locale.sh: rifiuti, controllo
# dello spazio, blocco all'inizio e a metà, backup superato, interruzione, compattazione riuscita.
# Uso: bash scripts/tassonomia/prova_manutenzione_specie.sh URL_COPIA_LOCALE CARTELLA
# Uscita 0 = tutte le prove passate.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; OUT=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "Le prove girano solo sulla copia locale" >&2; exit 1; }
BIN=/opt/homebrew/opt/postgresql@17/bin
D=scripts/tassonomia
PSQL=("$BIN/psql" "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"

fallita() { echo "PROVA $1 FALLITA: $2" >&2; exit 1; }
indici_trgm() {
  "${PSQL[@]}" -tAc "select count(*) from pg_indexes where schemaname = 'public' and tablename = 'specie' and indexname like '%trgm%'"
}
impronta_invariata() {
  "${PSQL[@]}" -f $D/impronta_specie.sql | diff -q "$OUT/impronta_iniziale.txt" - > /dev/null || fallita "$1" "impronta cambiata"
}
# Una sessione che legge la relazione $1 e tiene aperta la transazione, come una richiesta lenta dell'app.
# Su public.specie blocca già il passo 1 (togliere gli indici). Sulla tabella TOAST di specie blocca solo il passo 2:
# VACUUM FULL, dopo aver preso specie, deve prendere in esclusiva anche la sua TOAST; DROP INDEX non la tocca.
blocca() {
  PGAPPNAME=prova_blocco "$BIN/psql" "$URL" -X -q \
    -c "begin; select count(*) from $1; select pg_sleep(120);" > /dev/null 2>&1 &
  local n=0
  until [ "$("${PSQL[@]}" -tAc "select count(*) from pg_locks l join pg_stat_activity a using (pid)
              where a.application_name = 'prova_blocco' and l.relation = '$1'::regclass and l.granted")" -ge 1 ]; do
    n=$((n + 1)); [ "$n" -lt 50 ] || fallita blocca "nessun blocco su $1 dopo 10 s"
    sleep 0.2
  done
}
sblocca() {
  "${PSQL[@]}" -tAc "select count(pg_terminate_backend(pid)) from pg_stat_activity where application_name = 'prova_blocco'" > /dev/null
  wait || true
}
TOAST=$("${PSQL[@]}" -tAc "select reltoastrelid::regclass from pg_class where oid = 'public.specie'::regclass")

"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_iniziale.txt"

# 1. Rifiuti, prima di qualsiasi connessione: reale senza conferma, pooler in modalità transazione.
out=$(bash $D/manutenzione_specie.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATA: database reale senza CONFERMO_MANUTENZIONE_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_MANUTENZIONE_REALE=si bash $D/manutenzione_specie.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATA: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. Spazio insufficiente: una soglia di 1 MB sui database, o di 0 MB sul WAL, ferma tutto.
out=$("${PSQL[@]}" -v soglia_mb=1 -v soglia_wal_mb=100000 -f $D/manutenzione_specie_controlli.sql 2>&1) \
  && fallita spazio "database: nessun errore"
grep -qF 'ERROR:  spazio insufficiente per la compattazione' <<<"$out" || fallita spazio "$out"
out=$("${PSQL[@]}" -v soglia_mb=100000 -v soglia_wal_mb=0 -f $D/manutenzione_specie_controlli.sql 2>&1) \
  && fallita spazio "WAL: nessun errore"
grep -qF 'ERROR:  spazio insufficiente per la compattazione' <<<"$out" || fallita spazio "$out"
echo "PROVA spazio OK"

# 3. Blocco all'inizio: gli indici non si tolgono entro 2 s, la manutenzione si ferma e non cambia niente.
blocca public.specie
out=$(bash $D/manutenzione_specie.sh "$URL" "$OUT/r3" 2>&1) && { sblocca; fallita blocco_iniziale "nessun errore"; }
sblocca
grep -qF 'canceling statement due to lock timeout' <<<"$out" || fallita blocco_iniziale "$out"
[ "$(indici_trgm)" = 4 ] || fallita blocco_iniziale "indici trigram mancanti"
impronta_invariata blocco_iniziale
echo "PROVA blocco_iniziale OK"

# 4. Blocco a metà, con lo script completo: gli indici si tolgono, la compattazione non ottiene il blocco della
#    TOAST; le impostazioni di sessione vengono annullate e il passo 3 ricrea comunque gli indici.
blocca "$TOAST"
out=$(bash $D/manutenzione_specie.sh "$URL" "$OUT/r4" 2>&1) && { sblocca; fallita blocco_meta "nessun errore"; }
sblocca
grep -qF 'canceling statement due to lock timeout' <<<"$out" || fallita blocco_meta "$out"
grep -qF 'ERROR:  COMPATTAZIONE FALLITA' <<<"$out" || fallita blocco_meta "$out"
grep -qF 'dopo: statement_timeout=2min lock_timeout=0' <<<"$out" || fallita blocco_meta "impostazioni non annullate: $out"
grep -qF 'FALLITA: compattazione non riuscita' <<<"$out" || fallita blocco_meta "$out"
[ "$(indici_trgm)" = 4 ] || fallita blocco_meta "indici non ricreati"
impronta_invariata blocco_meta
echo "PROVA blocco_meta OK"

# 5. Backup superato: se l'impronta di partenza non è quella del backup, la manutenzione non parte.
echo 'righe 0' > "$OUT/impronta_finta.txt"
out=$(bash $D/manutenzione_specie.sh "$URL" "$OUT/r5" "$OUT/impronta_finta.txt" 2>&1) && fallita backup_superato "nessun errore"
grep -qF 'FERMATA: specie è cambiata dopo il backup' <<<"$out" || fallita backup_superato "$out"
[ "$(indici_trgm)" = 4 ] || fallita backup_superato "indici trigram mancanti"
echo "PROVA backup_superato OK"

# 6. Interruzione durante la compattazione (terminale chiuso, Ctrl-C, timeout dello strumento): lo script e il suo
#    psql ricevono TERM come gruppo; prima di uscire lo script deve ricreare gli indici trigram.
set -m
bash $D/manutenzione_specie.sh "$URL" "$OUT/r6" > "$OUT/r6.log" 2>&1 &
pid=$!
set +m
n=0
until grep -q 'passo 2' "$OUT/r6/tempi.txt" 2>/dev/null; do
  n=$((n + 1)); [ "$n" -lt 600 ] || fallita interruzione "passo 2 mai raggiunto"
  sleep 0.05
done
kill -TERM -- -"$pid"
if wait "$pid"; then fallita interruzione "uscita 0 dopo l'interruzione"; fi
grep -qF 'ATTENZIONE: manutenzione interrotta' "$OUT/r6.log" || fallita interruzione "$(cat "$OUT/r6.log")"
[ "$(indici_trgm)" = 4 ] || fallita interruzione "indici non ricreati"
impronta_invariata interruzione
echo "PROVA interruzione OK"

# 7. Compattazione riuscita: impronta identica, soglie applicate, verifica superata.
bash $D/manutenzione_specie.sh "$URL" "$OUT/r7" "$OUT/impronta_iniziale.txt" > "$OUT/r7.log" 2>&1 \
  || fallita compattazione "$(cat "$OUT/r7.log")"
[ "$(tail -1 "$OUT/r7.log")" = 'MANUTENZIONE SPECIE OK' ] || fallita compattazione "$(cat "$OUT/r7.log")"
grep -qx 'soglia_mb 400 soglia_wal_mb 100000' "$OUT/r7/controlli_prima.txt" || fallita compattazione "soglie non passate ai controlli"
echo "PROVA compattazione OK"
echo "PROVE FASE 1B OK"
