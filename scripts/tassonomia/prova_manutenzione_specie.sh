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
# Lancia lo script in background in un gruppo di processi suo (per mandare segnali al gruppo, come un terminale chiuso o
# un Ctrl-C) e aspetta che scriva $3 nei tempi. Argomenti: CARTELLA, redirezione di stderr ('log' o 'chiuso'), passo.
avvia() {
  set -m
  if [ "$2" = chiuso ]; then
    bash $D/manutenzione_specie.sh "$URL" "$OUT/$1" > "$OUT/$1.log" 2< /dev/null &
  else
    bash $D/manutenzione_specie.sh "$URL" "$OUT/$1" > "$OUT/$1.log" 2>&1 &
  fi
  pid=$!
  set +m
  local n=0
  until grep -q "$3" "$OUT/$1/tempi.txt" 2>/dev/null; do
    n=$((n + 1)); [ "$n" -lt 600 ] || fallita "$1" "$3 mai raggiunto"
    sleep 0.05
  done
}
# Il COMMIT del passo 1 viene trattenuto chiedendo una replica sincrona che non esiste; libera_commit lo lascia andare.
libera_commit() {
  "${PSQL[@]}" -c 'alter system reset synchronous_standby_names' -c 'select pg_reload_conf()' > /dev/null 2>&1 || true
}
trap libera_commit EXIT
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

# 6b. Terminale chiuso: HUP e uscita d'errore non più scrivibile. I messaggi falliscono, il ripristino no.
avvia r6b chiuso 'passo 2'
kill -HUP -- -"$pid"
if wait "$pid"; then fallita interruzione_muta "uscita 0 dopo l'interruzione"; fi
[ "$(indici_trgm)" = 4 ] || fallita interruzione_muta "indici non ricreati"
grep -qF 'indici trigram ricreati: 4 su 4' "$OUT/r6b/tempi.txt" || fallita interruzione_muta "stato finale non scritto in tempi.txt"
impronta_invariata interruzione_muta
echo "PROVA interruzione_muta OK"

# 6c. Secondo TERM mentre il ripristino ricrea gli indici: il passo 3 aspetta che la compattazione rimasta attiva sul
#     server finisca, lo script sembra appeso e riceve un altro segnale. Il ripristino non deve interrompersi.
avvia r6c log 'passo 2'
kill -TERM -- -"$pid"
n=0
until grep -q 'manutenzione interrotta' "$OUT/r6c.log"; do
  n=$((n + 1)); [ "$n" -lt 200 ] || fallita interruzione_doppia "ripristino mai partito"
  sleep 0.01
done
sleep 0.3
kill -TERM -- -"$pid" 2> /dev/null || fallita interruzione_doppia "script già finito al secondo TERM: prova non significativa"
if wait "$pid"; then fallita interruzione_doppia "uscita 0 dopo l'interruzione"; fi
[ "$(indici_trgm)" = 4 ] || fallita interruzione_doppia "indici non ricreati: $(cat "$OUT/r6c.log")"
impronta_invariata interruzione_doppia
echo "PROVA interruzione_doppia OK"

# 6d. Interruzione mentre il COMMIT del passo 1 è in volo: sul server gli indici sono già tolti, lo script non lo sa.
"${PSQL[@]}" -c "alter system set synchronous_standby_names = 'nessuna'" -c 'select pg_reload_conf()' > /dev/null
avvia r6d log 'passo 1'
n=0
until [ "$("${PSQL[@]}" -tAc "select count(*) from pg_stat_activity where backend_type = 'client backend' and wait_event = 'SyncRep'")" -ge 1 ]; do
  n=$((n + 1)); [ "$n" -lt 600 ] || fallita interruzione_passo1 "COMMIT del passo 1 mai trattenuto"
  sleep 0.05
done
kill -TERM -- -"$pid"
sleep 0.5
libera_commit
if wait "$pid"; then fallita interruzione_passo1 "uscita 0 dopo l'interruzione"; fi
[ "$(indici_trgm)" = 4 ] || fallita interruzione_passo1 "indici non ricreati: $(cat "$OUT/r6d.log")"
impronta_invariata interruzione_passo1
echo "PROVA interruzione_passo1 OK"

# 7. Compattazione riuscita: impronta identica, soglie applicate, verifica superata.
bash $D/manutenzione_specie.sh "$URL" "$OUT/r7" "$OUT/impronta_iniziale.txt" > "$OUT/r7.log" 2>&1 \
  || fallita compattazione "$(cat "$OUT/r7.log")"
[ "$(tail -1 "$OUT/r7.log")" = 'MANUTENZIONE SPECIE OK' ] || fallita compattazione "$(cat "$OUT/r7.log")"
grep -qx 'soglia_mb 400 soglia_wal_mb 100000' "$OUT/r7/controlli_prima.txt" || fallita compattazione "soglie non passate ai controlli"
echo "PROVA compattazione OK"
echo "PROVE FASE 1B OK"
