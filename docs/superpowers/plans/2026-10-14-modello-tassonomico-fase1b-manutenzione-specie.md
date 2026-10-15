# Modello tassonomico — fase 1b: manutenzione di `specie` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** compattare la tabella `public.specie` sul database Supabase reale (da circa 351 MB a circa 153 MB, somma dei database da circa 384 a circa 186 MB) senza cambiare un solo dato, così che le fasi 2–4 stiano nel piano gratuito.

**Architecture:** la compattazione è `VACUUM FULL`, preceduta dalla rimozione dei 4 indici trigram (abbassa il picco di spazio da circa 537 a circa 465 MB) e seguita dalla loro ricreazione identica. Un'"impronta" di `specie` (numero di righe, hash di tutte le righe in ordine di `id`, definizioni di indici, vincoli, trigger, policy, permessi) si calcola prima e dopo e deve coincidere. Tutto si prova prima su una copia locale ripristinata dal backup completo, comprese le interruzioni a metà; il database reale si tocca solo nell'ultimo task, dopo il via esplicito dell'utente.

**Tech Stack:** PostgreSQL 17 su Supabase (progetto `ncuhhsvtjwcolhpdxbkt`, piano gratuito), `psql`/`pg_dump`/`pg_restore`/`initdb`/`pg_ctl` 17 in `/opt/homebrew/opt/postgresql@17/bin/`, bash.

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md` (sezioni "Fasi", punto 1b, e "Decisioni sullo spazio"); numeri in `docs/ricerche/2026-10-14-stima-spazio.md`.

## Global Constraints

- I dati di `public.specie` non cambiano: l'impronta prima e dopo deve essere identica, riga per riga. Nessuna altra tabella viene toccata.
- I 4 indici trigram ricreati sono identici a quelli di `supabase/migrations/20261010100000_specie_indici_ricerca.sql` (stessi nomi, stesse colonne, `extensions.gin_trgm_ops`).
- Limite del piano gratuito: 500 MB come somma di tutti i database (template compresi). La compattazione parte solo se la somma è al massimo 400 MB e il WAL al massimo 300 MB (picco atteso circa 465 MB).
- Connessione: `SUPABASE_DB_URL` (pooler in modalità sessione, porta 5432). Mai la 6543 (`DATABASE_URL`, modalità transazione): `VACUUM` non può stare in una transazione e le impostazioni di sessione resterebbero sul server condiviso.
- Sul pooler vale un `statement_timeout` di 2 minuti (misurato il 14/10: `show statement_timeout` = `2min`, non viene da `pg_db_role_setting`; `PGOPTIONS` non passa dal pooler). Ogni impostazione di sessione va annullata alla fine, anche in caso di errore.
- `lock_timeout` di 2 s per togliere gli indici e per la compattazione: mentre una richiesta di blocco esclusivo aspetta, le letture dell'app si accodano dietro di lei e con la chiave pubblica scadono dopo 3 s (misurato in locale); se l'app sta leggendo `specie`, l'operazione si ritira prima.
- Backup completo con `pg_dump` 17 in formato custom (`-Fc`), con i permessi, nome fuori dal glob di rotazione `giardino_zorba_*.sql`: `backups/completo_<data>_pre_manutenzione_specie.dump`. `backups/` è esclusa da git.
- Le prove girano sulla copia locale (`127.0.0.1:55440`), mai sul database reale; sul reale, prima del Task 4, solo letture.
- Nessuna applicazione al database reale senza il via esplicito dell'utente in chat. Nessun push senza richiesta esplicita.
- Si lavora su `main`, come per la fase 1 (solo script e documentazione nel repository).
- Revisione completa dei Task 1–3 da parte di un revisore nuovo **prima** del Task 4, non dopo: il Task 4 è l'unico che cambia il database reale.

## Review Focus

1. Compattazione che non ottiene il blocco (l'app sta leggendo `specie`) o viene interrotta a metà (terminale chiuso, Ctrl-C, timeout dello strumento): `specie` deve restare com'era, i 4 indici trigram devono tornare e le impostazioni di sessione devono essere annullate. Prove `blocco_iniziale`, `blocco_meta` e `interruzione` nel Task 3.
2. Script lanciato sul database sbagliato o nel modo sbagliato (reale senza conferma, porta 6543): deve rifiutarsi prima di connettersi. Prova `rifiuti` nel Task 3.
3. Database già vicino al limite al momento del lancio: non deve partire, perché il picco supererebbe 500 MB e il database andrebbe in sola lettura. Prova `spazio` nel Task 3.
4. `specie` cambiata dopo il backup: il backup non sarebbe più una copia di sicurezza valida, quindi la manutenzione deve fermarsi. Prova `backup_superato` nel Task 3.
5. Impronta che non si accorge di una modifica: darebbe un falso "dati invariati". Prova di sensibilità nel Task 2.

## File

- Create: `scripts/tassonomia/impronta_specie.sql` — impronta di `specie` (sola lettura).
- Create: `scripts/tassonomia/verifica_manutenzione_specie.sql` — controllo finale: 9 indici validi, trigram presenti, `specie` compattata.
- Create: `scripts/tassonomia/copia_locale.sh` — crea e ferma la copia locale di `specie` e `generi` da un backup completo (servirà anche alle fasi 2–4).
- Create: `scripts/tassonomia/copia_locale_prep.sql` — ruoli, schema ed estensioni di Supabase che la copia richiede.
- Create: `scripts/tassonomia/manutenzione_specie_controlli.sql` — misure e controllo dello spazio prima di partire.
- Create: `scripts/tassonomia/manutenzione_specie_1_togli_indici.sql`
- Create: `scripts/tassonomia/manutenzione_specie_2_compatta.sql`
- Create: `scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql` — anche procedura di ripristino se la manutenzione si interrompe.
- Create: `scripts/tassonomia/manutenzione_specie.sh` — esegue controlli, impronta, passi 1–3, impronta, verifica.
- Create: `scripts/tassonomia/prova_manutenzione_specie.sh` — prove sulla copia locale.
- Modify: `CLAUDE.md` — sezione "Modello tassonomico" (Task 4).

Tutti i comandi si lanciano dalla radice del repository. I blocchi di comandi usano queste variabili di shell, da reimpostare in ogni shell nuova: `PG=/opt/homebrew/opt/postgresql@17/bin`; `SCRATCH` = la cartella temporanea della sessione (scratchpad); `SUPABASE_DB_URL` da `.env.local` (`set -a; source .env.local; set +a`); `TS` e `BK` dal Task 2, Step 1; `COPIA=postgresql://postgres@127.0.0.1:55440/giardino` dal Task 2, Step 4. L'URL del database contiene la password: non va mai stampato.

---

### Task 1: Impronta e verifica finale

**Files:**
- Create: `scripts/tassonomia/verifica_manutenzione_specie.sql`
- Create: `scripts/tassonomia/impronta_specie.sql`

**Interfaces:**
- Produces: `impronta_specie.sql`, da lanciare con `psql URL -X -q -v ON_ERROR_STOP=1 -f`; stampa 9 righe, ognuna `<etichetta> <valore>`, con le etichette `righe`, `dati`, `indici`, `vincoli`, `trigger`, `policy`, `rls`, `permessi`, `opzioni`. Su due database con gli stessi dati l'uscita è identica, a prescindere da come le righe sono disposte su disco. `verifica_manutenzione_specie.sql`: uscita 0 se `specie` ha 9 indici validi, i 4 trigram, e occupa al massimo 175 MB; altrimenti errore con il motivo.

- [ ] **Step 1: Scrivere la verifica finale (il test che deve fallire oggi)**

`scripts/tassonomia/verifica_manutenzione_specie.sql`:

```sql
-- Fase 1b: controllo dopo la manutenzione di public.specie. Sola lettura.
-- Errore se mancano indici, se un indice non è valido o se la tabella non è compattata
-- (attesi circa 153 MB dopo la compattazione, 351 MB prima: docs/ricerche/2026-10-14-stima-spazio.md).
do $$
declare
  n_indici int;
  n_validi int;
  n_trgm int;
  dim bigint;
  somma bigint;
begin
  select count(*), count(*) filter (where indisvalid and indisready)
    into n_indici, n_validi
    from pg_index where indrelid = 'public.specie'::regclass;
  if n_indici <> 9 or n_validi <> 9 then
    raise exception 'indici di specie: % presenti, % validi (attesi 9 e 9)', n_indici, n_validi;
  end if;
  select count(*) into n_trgm from pg_indexes
   where schemaname = 'public' and tablename = 'specie'
     and indexname in ('specie_nome_trgm_idx', 'specie_nome_scientifico_trgm_idx',
                       'specie_nomi_alternativi_trgm_idx', 'specie_sinonimi_botanici_trgm_idx');
  if n_trgm <> 4 then
    raise exception 'indici trigram di specie: % su 4', n_trgm;
  end if;
  dim := pg_total_relation_size('public.specie');
  if dim > 175000000 then
    raise exception 'specie ancora da compattare: % MB (attesi circa 153)', round(dim / 1e6);
  end if;
  select sum(pg_database_size(datname)) into somma from pg_database;
  raise notice 'specie % MB, somma dei database % MB', round(dim / 1e6, 1), round(somma / 1e6, 1);
end $$;
```

- [ ] **Step 2: Lanciarla sul database reale (sola lettura) e vederla fallire**

```bash
set -a; source .env.local; set +a
$PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/verifica_manutenzione_specie.sql; echo "uscita $?"
```

Expected: `ERROR:  specie ancora da compattare: 351 MB (attesi circa 153)` e `uscita 3`.

- [ ] **Step 3: Lanciare il controllo dell'impronta prima che esista**

Il controllo: due impronte di fila sul database reale, ciascuna di 9 righe con `righe 212066`, identiche tra loro.

```bash
for x in a b; do
  $PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/impronta_specie.sql > "$SCRATCH/impronta_$x.txt"
done
grep -qx 'righe 212066' "$SCRATCH/impronta_a.txt" && [ "$(wc -l < "$SCRATCH/impronta_a.txt")" -eq 9 ] \
  && diff "$SCRATCH/impronta_a.txt" "$SCRATCH/impronta_b.txt" && echo IDENTICHE || echo "IMPRONTA NON VALIDA"
```

Expected: `No such file or directory` e `IMPRONTA NON VALIDA`.

- [ ] **Step 4: Scrivere l'impronta**

`scripts/tassonomia/impronta_specie.sql`:

```sql
-- Impronta di public.specie: dati e struttura, in sola lettura. Due database con gli stessi dati danno la stessa
-- uscita anche se le righe sono disposte diversamente su disco (si ordina per id): serve a dimostrare che la
-- compattazione (fase 1b) e il ripristino dal backup non cambiano nulla. Le impostazioni di formato sono fissate
-- perché l'uscita non dipenda dal server (fuso orario, formato delle date, schemi visibili).
\pset tuples_only on
\pset format unaligned
begin transaction isolation level repeatable read read only;
set local timezone = 'UTC';
set local datestyle = 'ISO, YMD';
set local intervalstyle = 'postgres';
set local extra_float_digits = 1;
set local bytea_output = 'hex';
set local search_path = public, extensions;
set local statement_timeout = '10min';
select 'righe ' || count(*) from public.specie;
select 'dati ' || md5(string_agg(md5(s::text), '' order by s.id)) from public.specie s;
select 'indici ' || string_agg(pg_get_indexdef(i.indexrelid)
                               || case when i.indisvalid and i.indisready then '' else ' NON VALIDO' end,
                               ' | ' order by c.relname)
  from pg_index i join pg_class c on c.oid = i.indexrelid
 where i.indrelid = 'public.specie'::regclass;
select 'vincoli ' || string_agg(conname || ' ' || pg_get_constraintdef(oid), ' | ' order by conname)
  from pg_constraint where conrelid = 'public.specie'::regclass;
select 'trigger ' || coalesce(string_agg(pg_get_triggerdef(oid) || ' stato ' || tgenabled::text, ' | ' order by tgname), '')
  from pg_trigger where tgrelid = 'public.specie'::regclass and not tgisinternal;
select 'policy ' || coalesce(string_agg(polname || ' ' || polcmd::text || ' ' || polroles::regrole[]::text || ' '
                                        || coalesce(pg_get_expr(polqual, polrelid), '')
                                        || ' ' || coalesce(pg_get_expr(polwithcheck, polrelid), ''),
                                        ' | ' order by polname), '')
  from pg_policy where polrelid = 'public.specie'::regclass;
select 'rls ' || relrowsecurity || ' ' || relforcerowsecurity from pg_class where oid = 'public.specie'::regclass;
select 'permessi ' || coalesce(relacl::text, '') from pg_class where oid = 'public.specie'::regclass;
select 'opzioni ' || coalesce(reloptions::text, '') from pg_class where oid = 'public.specie'::regclass;
commit;
```

- [ ] **Step 5: Rilanciare il controllo dello Step 3**

Stesso blocco di comandi dello Step 3, poi `cut -c1-120 "$SCRATCH/impronta_a.txt"`.

Expected: `IDENTICHE`; la riga `indici` con 9 definizioni (5 btree e 4 gin), nessun `NON VALIDO`. Annotare quanto impiega un'impronta (se più di 2 minuti, c'è un problema: il limite è 10).

- [ ] **Step 6: Commit**

```bash
git add scripts/tassonomia/impronta_specie.sql scripts/tassonomia/verifica_manutenzione_specie.sql
git commit -m "Tassonomia fase 1b: impronta di specie e verifica dopo la manutenzione"
```

---

### Task 2: Backup completo e copia locale

**Files:**
- Create: `scripts/tassonomia/copia_locale_prep.sql`
- Create: `scripts/tassonomia/copia_locale.sh`

**Interfaces:**
- Consumes: `impronta_specie.sql` (Task 1).
- Produces: il backup `backups/completo_<TS>_pre_manutenzione_specie.dump` e la sua impronta `backups/completo_<TS>_pre_manutenzione_specie.impronta.txt` (usata dal Task 4); `copia_locale.sh crea BACKUP CARTELLA` che stampa l'URL `postgresql://postgres@127.0.0.1:55440/giardino` e `copia_locale.sh ferma CARTELLA`; la copia locale accesa, con `specie` e `generi`, usata dal Task 3.

- [ ] **Step 1: Backup completo e sua impronta**

```bash
set -a; source .env.local; set +a
TS=$(date +%Y%m%d_%H%M%S)
BK=backups/completo_${TS}_pre_manutenzione_specie.dump
$PG/pg_dump "$SUPABASE_DB_URL" -Fc -f "$BK"
$PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/impronta_specie.sql > "${BK%.dump}.impronta.txt"
ls -l "$BK"; head -1 "${BK%.dump}.impronta.txt"
for t in 'public specie' 'public generi' 'public piante' 'public zone' 'public sottozone' 'public progetti' \
         'public tappe' 'public concimi' 'public settings' 'auth users'; do
  $PG/pg_restore -l "$BK" | grep -q "TABLE DATA $t " || echo "MANCA $t"
done
$PG/pg_restore -f /dev/null "$BK" && echo BACKUP LEGGIBILE
```

Expected: un file `.dump` di decine di MB; `righe 212066`; nessuna riga `MANCA`; `BACKUP LEGGIBILE`. L'elenco (`-l`) legge solo l'indice del file e passa anche su un backup troncato; la lettura completa (`-f /dev/null`) no (verificato in locale). Annotare il valore di `TS`: il Task 4 lo usa.

- [ ] **Step 2: Lanciare il confronto con la copia locale prima che lo script esista**

```bash
bash scripts/tassonomia/copia_locale.sh crea "$BK" "$SCRATCH/copia_fase1b"; echo "uscita $?"
```

Expected: `No such file or directory` e uscita diversa da 0.

- [ ] **Step 3: Scrivere la preparazione e lo script della copia locale**

`scripts/tassonomia/copia_locale_prep.sql`:

```sql
-- Oggetti di Supabase richiesti dalle tabelle ripristinate nella copia locale (copia_locale.sh):
-- ruoli dei permessi, schema extensions con pg_trgm (indici trigram) e moddatetime (trigger di data).
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema extensions;
create extension pg_trgm schema extensions;
create extension moddatetime schema extensions;
alter database giardino set search_path = "$user", public, extensions;
```

`scripts/tassonomia/copia_locale.sh`:

```bash
#!/usr/bin/env bash
# Copia locale di public.specie e public.generi presa da un backup completo (pg_dump -Fc), per provare le
# operazioni in blocco del modello tassonomico senza toccare il database reale (specifica, "Decisioni sullo
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
      | grep -E '^[0-9]+; [0-9]+ [0-9]+ (TABLE|TABLE DATA|CONSTRAINT|FK CONSTRAINT|INDEX|TRIGGER|POLICY|ROW SECURITY) public (specie|generi)[ _]' \
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
```

- [ ] **Step 4: Creare la copia e confrontare l'impronta con quella del backup**

```bash
COPIA=$(bash scripts/tassonomia/copia_locale.sh crea "$BK" "$SCRATCH/copia_fase1b" | tail -1)
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/impronta_specie.sql > "$SCRATCH/impronta_copia.txt"
diff <(grep -v '^permessi ' "${BK%.dump}.impronta.txt") <(grep -v '^permessi ' "$SCRATCH/impronta_copia.txt") && echo RIPRISTINO IDENTICO
```

Expected: `RIPRISTINO IDENTICO`. La riga `permessi` è esclusa perché la copia è ripristinata senza permessi; tutte le altre (righe, dati, indici, vincoli, trigger, policy, rls, opzioni) devono coincidere.

- [ ] **Step 5: Prova di sensibilità dell'impronta (una modifica di un carattere deve vedersi)**

```bash
P=($PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1)
"${P[@]}" -c 'alter table public.specie disable trigger user' \
          -c "update public.specie set nome = nome || '~' where slug = 'pomodoro'"
"${P[@]}" -f scripts/tassonomia/impronta_specie.sql > "$SCRATCH/impronta_modificata.txt"
diff "$SCRATCH/impronta_copia.txt" "$SCRATCH/impronta_modificata.txt" | grep '^[<>] ' | cut -d' ' -f2 | sort | uniq -c
"${P[@]}" -c "update public.specie set nome = left(nome, -1) where slug = 'pomodoro'" \
          -c 'alter table public.specie enable trigger user'
"${P[@]}" -f scripts/tassonomia/impronta_specie.sql | diff "$SCRATCH/impronta_copia.txt" - && echo RIPRISTINATA
```

Expected: `2 dati` (cambia solo la riga `dati`, nelle due impronte), poi `RIPRISTINATA`. Se esce vuoto, la riga `pomodoro` non esiste o l'impronta non vede la modifica: la prova è fallita. Il trigger di data viene disattivato durante la prova perché altrimenti cambierebbe anche `aggiornata_il` e la copia non tornerebbe identica.

- [ ] **Step 6: Commit (il backup resta fuori da git)**

```bash
git add scripts/tassonomia/copia_locale.sh scripts/tassonomia/copia_locale_prep.sql
git commit -m "Tassonomia fase 1b: copia locale di specie e generi da un backup completo"
```

La copia locale resta accesa per il Task 3.

---

### Task 3: Manutenzione e prove sulla copia locale

**Files:**
- Create: `scripts/tassonomia/prova_manutenzione_specie.sh`
- Create: `scripts/tassonomia/manutenzione_specie_controlli.sql`
- Create: `scripts/tassonomia/manutenzione_specie_1_togli_indici.sql`
- Create: `scripts/tassonomia/manutenzione_specie_2_compatta.sql`
- Create: `scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql`
- Create: `scripts/tassonomia/manutenzione_specie.sh`

**Interfaces:**
- Consumes: `impronta_specie.sql`, `verifica_manutenzione_specie.sql` (Task 1); `COPIA` e `BK` (Task 2).
- Produces: `manutenzione_specie.sh URL CARTELLA [IMPRONTA_BACKUP]`, uscita 0 e ultima riga `MANUTENZIONE SPECIE OK` se tutto è riuscito; in `CARTELLA` i file `controlli_prima.txt`, `impronta_prima.txt`, `impronta_dopo.txt`, `controlli_dopo.txt`, `tempi.txt`. `manutenzione_specie_controlli.sql` con le variabili psql facoltative `soglia_mb` e `soglia_wal_mb` (o tutte e due o nessuna). `prova_manutenzione_specie.sh URL_COPIA CARTELLA`, ultima riga `PROVE FASE 1B OK`.

- [ ] **Step 1: Scrivere le prove**

`scripts/tassonomia/prova_manutenzione_specie.sh`:

```bash
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
```

- [ ] **Step 2: Lanciarle e vederle fallire**

```bash
bash scripts/tassonomia/prova_manutenzione_specie.sh "$COPIA" "$SCRATCH/prove_fase1b" > "$SCRATCH/prove_fase1b.log" 2>&1; echo "uscita $?"; tail -3 "$SCRATCH/prove_fase1b.log"
```

Expected: `uscita 1` e `PROVA rifiuti FALLITA: bash: scripts/tassonomia/manutenzione_specie.sh: No such file or directory`.

- [ ] **Step 3: Scrivere i controlli e i tre passi**

`scripts/tassonomia/manutenzione_specie_controlli.sql`:

```sql
-- Fase 1b: misure prima e dopo la manutenzione di specie. Sola lettura.
-- orfani_mb = spazio del database non attribuito a nessuna relazione: deve restare uguale prima e dopo. Se cresce,
-- una compattazione interrotta da un riavvio del server ha lasciato file orfani, che contano nel limite.
-- Con le variabili psql soglia_mb e soglia_wal_mb (sempre insieme) si ferma con un errore se la somma dei database
-- o il WAL le superano: la compattazione affianca per qualche minuto una seconda copia di specie (circa 120 MB) e
-- scrive circa 140 MB di WAL; oltre 500 MB il database va in sola lettura, e il disco di Supabase è di 1 GB.
\pset tuples_only on
\pset format unaligned
select 'somma_db_mb ' || round(sum(pg_database_size(datname)) / 1e6, 1) from pg_database;
select 'specie_mb ' || round(pg_total_relation_size('public.specie') / 1e6, 1);
select 'wal_mb ' || round(coalesce(sum(size), 0) / 1e6, 1) from pg_ls_waldir();
select 'orfani_mb ' || round((pg_database_size(current_database())
         - (select sum(pg_relation_size(c.oid, 'main') + pg_relation_size(c.oid, 'fsm')
                       + pg_relation_size(c.oid, 'vm') + pg_relation_size(c.oid, 'init'))
              from pg_class c
             where c.relkind in ('r', 'i', 't', 'm', 'S') and c.reltablespace = 0 and not c.relisshared)) / 1e6, 1);
\if :{?soglia_mb}
  \echo 'soglia_mb' :soglia_mb 'soglia_wal_mb' :soglia_wal_mb
  select (select sum(pg_database_size(datname)) from pg_database) > :soglia_mb::numeric * 1e6
      or (select coalesce(sum(size), 0) from pg_ls_waldir()) > :soglia_wal_mb::numeric * 1e6 as spazio_insufficiente \gset
  \if :spazio_insufficiente
    do $$ begin raise exception 'spazio insufficiente per la compattazione'; end $$;
  \endif
\endif
```

`scripts/tassonomia/manutenzione_specie_1_togli_indici.sql`:

```sql
-- Fase 1b, passo 1: toglie i 4 indici trigram di specie, così il picco di spazio della compattazione resta
-- sotto 500 MB (circa 465 invece di 537). Si esegue con psql -1; il passo 3 li ricrea.
-- lock_timeout di 2 s: mentre aspetta il blocco, le letture dell'app si mettono in coda dietro questa richiesta, e
-- per la chiave pubblica scadono dopo 3 s; se l'app sta leggendo specie, ci si ritira prima.
set local lock_timeout = '2s';
drop index public.specie_nome_trgm_idx;
drop index public.specie_nome_scientifico_trgm_idx;
drop index public.specie_nomi_alternativi_trgm_idx;
drop index public.specie_sinonimi_botanici_trgm_idx;
```

`scripts/tassonomia/manutenzione_specie_2_compatta.sql`:

```sql
-- Fase 1b, passo 2: compatta public.specie (riscrive tabella, TOAST e indici; i dati non cambiano).
-- VACUUM non può stare in una transazione, quindi le impostazioni sono di sessione: vengono annullate anche se la
-- compattazione fallisce, perché sul pooler in modalità sessione la connessione al server può essere riusata.
-- lock_timeout di 2 s per lo stesso motivo del passo 1. Uscita 3 se la compattazione fallisce: in quel caso specie
-- resta com'era (VACUUM FULL è tutto o niente). Se cade la connessione, il server può finire la compattazione da solo.
\set ON_ERROR_STOP 0
set statement_timeout = 0;
set lock_timeout = '2s';
vacuum (full, analyze) public.specie;
\set fallita :ERROR
reset statement_timeout;
reset lock_timeout;
\set ON_ERROR_STOP 1
select 'dopo: statement_timeout=' || current_setting('statement_timeout')
       || ' lock_timeout=' || current_setting('lock_timeout') as impostazioni \gset
\echo :impostazioni
\if :fallita
  do $$ begin raise exception 'COMPATTAZIONE FALLITA: specie è rimasta com''era'; end $$;
\endif
```

`scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql`:

```sql
-- Fase 1b, passo 3: ricrea i 4 indici trigram di specie, identici a
-- supabase/migrations/20261010100000_specie_indici_ricerca.sql. Si esegue con psql -1.
-- È anche il ripristino se la manutenzione si è interrotta dopo il passo 1: si può rieseguire senza danni.
-- Nessun lock_timeout: se una compattazione rimasta attiva sul server tiene ancora specie, si aspetta che finisca.
set local statement_timeout = 0;
create index if not exists specie_nome_trgm_idx on public.specie using gin (nome extensions.gin_trgm_ops);
create index if not exists specie_nome_scientifico_trgm_idx on public.specie using gin (nome_scientifico extensions.gin_trgm_ops);
create index if not exists specie_nomi_alternativi_trgm_idx on public.specie using gin (nomi_alternativi extensions.gin_trgm_ops);
create index if not exists specie_sinonimi_botanici_trgm_idx on public.specie using gin (sinonimi_botanici extensions.gin_trgm_ops);
```

- [ ] **Step 4: Scrivere lo script principale**

`scripts/tassonomia/manutenzione_specie.sh`:

```bash
#!/usr/bin/env bash
# Fase 1b del modello tassonomico: compatta public.specie (VACUUM FULL) senza cambiare i dati.
# Controlla lo spazio, calcola l'impronta, toglie i 4 indici trigram, compatta, li ricrea, ricalcola l'impronta
# e la confronta. Dopo il passo 1 gli indici vengono ricreati in ogni caso: se la compattazione fallisce, se un
# comando fallisce o se lo script viene interrotto (TERM, INT, HUP); non con kill -9.
# Uso: bash scripts/tassonomia/manutenzione_specie.sh URL CARTELLA [IMPRONTA_BACKUP]
#   URL              connessione in modalità sessione: SUPABASE_DB_URL (porta 5432) o la copia locale
#   CARTELLA         dove scrivere misure, impronte e tempi
#   IMPRONTA_BACKUP  se data, l'impronta di partenza deve coincidere: il backup è ancora una copia valida
# Sul database reale serve CONFERMO_MANUTENZIONE_REALE=si. Uscita 0 e ultima riga MANUTENZIONE SPECIE OK = riuscita.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; OUT=${2:?manca CARTELLA}; IMPRONTA_BACKUP=${3:-}
D=scripts/tassonomia
SOGLIA_WAL_MB=100000   # copia locale: il WAL resta sul disco del Mac
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATA: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_MANUTENZIONE_REALE:-} == si ]] || { echo "RIFIUTATA: database reale senza CONFERMO_MANUTENZIONE_REALE=si" >&2; exit 1; }
  SOGLIA_WAL_MB=300    # disco di Supabase da 1 GB
fi
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
tempo() { echo "$(date +%T) $1" >> "$OUT/tempi.txt"; }
indici_ok=0
ripristina() {
  [ "$indici_ok" = 1 ] && return
  echo "ATTENZIONE: manutenzione interrotta dopo il passo 1: ricreo gli indici trigram (passo 3)" >&2
  "${PSQL[@]}" -1 -f $D/manutenzione_specie_3_ricrea_indici.sql >&2 \
    || echo "ATTENZIONE: ricreazione non riuscita. Rieseguire: psql URL -X -1 -v ON_ERROR_STOP=1 -f $D/manutenzione_specie_3_ricrea_indici.sql" >&2
}

"${PSQL[@]}" -v soglia_mb=400 -v soglia_wal_mb=$SOGLIA_WAL_MB -f $D/manutenzione_specie_controlli.sql | tee "$OUT/controlli_prima.txt"
tempo "impronta prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_prima.txt"
if [ -n "$IMPRONTA_BACKUP" ] && ! diff -q "$IMPRONTA_BACKUP" "$OUT/impronta_prima.txt" > /dev/null; then
  echo "FERMATA: specie è cambiata dopo il backup; rifare il backup prima della manutenzione" >&2; exit 1
fi

tempo "passo 1: togli indici trigram"
"${PSQL[@]}" -1 -f $D/manutenzione_specie_1_togli_indici.sql
trap ripristina EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
tempo "passo 2: compatta"
esito=0
"${PSQL[@]}" -f $D/manutenzione_specie_2_compatta.sql || esito=$?
tempo "passo 3: ricrea indici trigram"
"${PSQL[@]}" -1 -f $D/manutenzione_specie_3_ricrea_indici.sql
indici_ok=1
tempo "fine"

"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_dopo.txt"
diff "$OUT/impronta_prima.txt" "$OUT/impronta_dopo.txt" >&2 || { echo "FALLITA: l'impronta di specie è cambiata" >&2; exit 1; }
[ "$esito" -eq 0 ] || { echo "FALLITA: compattazione non riuscita; dati e indici come prima" >&2; exit 1; }
"${PSQL[@]}" -f $D/manutenzione_specie_controlli.sql | tee "$OUT/controlli_dopo.txt"
"${PSQL[@]}" -f $D/verifica_manutenzione_specie.sql
echo "MANUTENZIONE SPECIE OK"
```

- [ ] **Step 5: Lanciare le prove e vederle passare, due volte di fila**

La seconda esecuzione serve a dimostrare che le prove non dipendono dallo stato lasciato dalla prima (WAL accumulato, cartelle, indici).

```bash
chmod +x scripts/tassonomia/copia_locale.sh scripts/tassonomia/manutenzione_specie.sh scripts/tassonomia/prova_manutenzione_specie.sh
for giro in 1 2; do
  bash scripts/tassonomia/prova_manutenzione_specie.sh "$COPIA" "$SCRATCH/prove_fase1b_$giro" > "$SCRATCH/prove_fase1b_$giro.log" 2>&1
  echo "giro $giro uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase1b_$giro.log"
done
cat "$SCRATCH/prove_fase1b_1/r7/tempi.txt" "$SCRATCH/prove_fase1b_1/r7/controlli_dopo.txt"
```

Expected, per tutti e due i giri: `uscita 0`, poi `PROVA rifiuti OK`, `PROVA spazio OK`, `PROVA blocco_iniziale OK`, `PROVA blocco_meta OK`, `PROVA backup_superato OK`, `PROVA interruzione OK`, `PROVA compattazione OK`, `PROVE FASE 1B OK`. In `controlli_dopo.txt` `specie_mb` circa 153 e `orfani_mb` uguale a quello di `controlli_prima.txt`. Annotare i tempi dei passi: sul database reale saranno più lunghi (la tabella è gonfia e il server è piccolo).

- [ ] **Step 6: Prove di mutazione (le prove devono accorgersi di tre difetti messi apposta)**

Per ciascuna mutazione: copia di sicurezza del file, modifica, prove, ripristino del file. Dopo ogni giro gli indici vengono ricreati per sicurezza (il passo 3 si può rieseguire senza danni).

```bash
muta() {  # muta FILE ESPRESSIONE_SED NOME
  cp "$1" "$SCRATCH/mutazione.bak"
  sed -i '' "$2" "$1"
  cmp -s "$1" "$SCRATCH/mutazione.bak" && echo "MUTAZIONE $3 NON APPLICATA"
  bash scripts/tassonomia/prova_manutenzione_specie.sh "$COPIA" "$SCRATCH/mut_$3" > "$SCRATCH/mut_$3.log" 2>&1
  echo "mutazione $3: uscita $? — $(grep -E 'FALLITA' "$SCRATCH/mut_$3.log" | head -1 | cut -c1-90)"
  cp "$SCRATCH/mutazione.bak" "$1"
  $PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql 2> /dev/null
}
muta scripts/tassonomia/manutenzione_specie.sh 's/ || esito=\$?$//' esito
muta scripts/tassonomia/manutenzione_specie.sh 's/^trap ripristina EXIT$//' trap
muta scripts/tassonomia/manutenzione_specie.sh 's/ -v soglia_mb=400 -v soglia_wal_mb=\$SOGLIA_WAL_MB//' soglie
git status --short scripts/tassonomia/
bash scripts/tassonomia/prova_manutenzione_specie.sh "$COPIA" "$SCRATCH/prove_dopo_mutazioni" > "$SCRATCH/prove_dopo_mutazioni.log" 2>&1; echo "uscita $?"; tail -1 "$SCRATCH/prove_dopo_mutazioni.log"
```

Expected: nessuna riga `NON APPLICATA`; `mutazione esito: uscita 1 — PROVA blocco_meta FALLITA: …`; `mutazione trap: uscita 1 — PROVA interruzione FALLITA: …`; `mutazione soglie: uscita 1 — PROVA compattazione FALLITA: soglie non passate ai controlli`; `git status` mostra solo file nuovi (`??`), nessuno modificato rispetto a quanto scritto negli Step 3–4; infine `uscita 0` e `PROVE FASE 1B OK`.

- [ ] **Step 7: Commit**

```bash
git add scripts/tassonomia/prova_manutenzione_specie.sh scripts/tassonomia/manutenzione_specie.sh \
        scripts/tassonomia/manutenzione_specie_controlli.sql scripts/tassonomia/manutenzione_specie_1_togli_indici.sql \
        scripts/tassonomia/manutenzione_specie_2_compatta.sql scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql
git commit -m "Tassonomia fase 1b: manutenzione di specie (togli trigram, VACUUM FULL, ricrea) con prove sulla copia locale"
```

**Prima del Task 4:** revisione completa dei commit dei Task 1–3 da parte di un revisore nuovo (vedi Global Constraints); le correzioni importanti si fanno con una prova che fallisce prima, poi si rilancia `prova_manutenzione_specie.sh` su una copia locale nuova.

---

### Task 4: Esecuzione sul database reale e documentazione

**Files:**
- Modify: `CLAUDE.md` (sezione "Modello tassonomico")

**Interfaces:**
- Consumes: `manutenzione_specie.sh` (Task 3), `BK` e la sua impronta (Task 2), `copia_locale.sh ferma` (Task 2).

- [ ] **Step 1: Via esplicito dell'utente**

Chiedere in chat il via per la manutenzione sul database reale, dicendo: durata attesa (da qualche decina di secondi a qualche minuto, più la ricreazione dei 4 indici), effetto sull'app (per quei minuti la ricerca delle specie può non rispondere e il caricamento ripiega su `specie.json`; meglio non usare l'app), nessun cambiamento ai dati, e l'unico rischio non coperto: se il server di Supabase si riavviasse proprio durante la compattazione, i file della copia a metà resterebbero sul disco e conterebbero nel limite (circa 120 MB, misurato in locale con un arresto immediato), senza un modo per toglierli dal nostro ruolo. Senza un sì esplicito ci si ferma qui.

- [ ] **Step 2: Eseguire la manutenzione**

Va lanciata in background (strumento Bash con `run_in_background`), non in primo piano: un timeout dello strumento interromperebbe lo script. Lo script ricrea comunque gli indici se interrotto (prova `interruzione`), ma è meglio non arrivarci.

```bash
set -a; source .env.local; set +a
OUT=backups/manutenzione_specie_$(date +%Y%m%d_%H%M%S)
CONFERMO_MANUTENZIONE_REALE=si bash scripts/tassonomia/manutenzione_specie.sh \
  "$SUPABASE_DB_URL" "$OUT" "backups/completo_${TS}_pre_manutenzione_specie.impronta.txt" > "$OUT.log" 2>&1; echo "uscita $?"
tail -12 "$OUT.log"; cat "$OUT/tempi.txt"
```

Expected: `uscita 0`; nel log `controlli_prima` con `somma_db_mb` circa 384, `specie_mb` circa 351 e `soglia_mb 400 soglia_wal_mb 300`; alla fine `specie_mb` circa 153, `somma_db_mb` circa 186, `orfani_mb` uguale a quello di partenza (±1), la NOTICE della verifica e `MANUTENZIONE SPECIE OK`.

Se l'uscita non è 0:
- `FERMATA: specie è cambiata dopo il backup` → rifare i passi 1 del Task 2 (nuovo backup e impronta) e rilanciare.
- `FALLITA: compattazione non riuscita` con `lock timeout` → l'app stava leggendo; riprovare una volta dopo un minuto. Se fallisce ancora, fermarsi e riferire all'utente.
- `FALLITA: l'impronta di specie è cambiata` → fermarsi, non toccare niente e riferire all'utente con il diff: un eventuale ripristino dal backup si decide insieme.
- `RIFIUTATA` o errore `spazio insufficiente` → non è cambiato niente; riferire all'utente con i valori di `controlli_prima.txt`.
- Il log contiene `ATTENZIONE: ricreazione non riuscita` → rieseguire subito il passo 3 (`$PG/psql "$SUPABASE_DB_URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql`), poi `verifica_manutenzione_specie.sql`, poi riferire.
- `orfani_mb` cresciuto di decine di MB → il server si è riavviato durante la compattazione: fermarsi e riferire all'utente (lo spazio non si recupera dal nostro ruolo).

- [ ] **Step 3: Controllare la ricerca dell'app con la chiave pubblica**

```bash
set -a; source .env; set +a
for col in nome nome_scientifico nomi_alternativi sinonimi_botanici; do
  curl -s -o /dev/null -w "$col %{http_code} %{time_total}s\n" \
    "$VITE_SUPABASE_URL/rest/v1/specie?select=slug&$col=ilike.*rosmar*&limit=50" \
    -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
done
$PG/psql "$SUPABASE_DB_URL" -X -q -c "begin read only; explain select slug from public.specie where nome ilike '%rosmar%' limit 50; rollback;"
```

Expected: 4 righe con codice `200` e tempo sotto 1 s (il limite di `anon` è 3 s); il piano usa `specie_nome_trgm_idx` (Bitmap Index Scan).

- [ ] **Step 4: Fermare la copia locale e aggiornare CLAUDE.md**

```bash
bash scripts/tassonomia/copia_locale.sh ferma "$SCRATCH/copia_fase1b"
```

In `CLAUDE.md`, sezione "### Modello tassonomico (in corso, fase 1 di 7 applicata)": cambiare il titolo in "### Modello tassonomico (in corso, fasi 1 e 1b di 7 applicate)" e aggiungere, dopo la frase sul rollback della fase 1, questo paragrafo (con le misure reali al posto di quelle attese, se diverse):

```markdown
La fase 1b (14/10/2026, piano `docs/superpowers/plans/2026-10-14-modello-tassonomico-fase1b-manutenzione-specie.md`) ha compattato `specie` con `VACUUM FULL` dopo aver tolto i 4 indici trigram, ricreati subito dopo identici: `specie` da 351 a circa 153 MB, somma dei database da 384 a circa 186 MB su 500 (piano gratuito; le decisioni sullo spazio sono nella specifica). I dati non sono cambiati: l'impronta (`scripts/tassonomia/impronta_specie.sql`) è identica prima e dopo. Fino alla fine della fase 4 niente modifiche a lotti su `specie`: ricreerebbero lo spazio sprecato. Le prove delle operazioni in blocco si fanno su una copia locale di `specie` e `generi` presa da un backup completo: `bash scripts/tassonomia/copia_locale.sh crea BACKUP.dump CARTELLA` (e `ferma CARTELLA`); prove della fase 1b: `bash scripts/tassonomia/prova_manutenzione_specie.sh URL_COPIA CARTELLA`. Se una manutenzione si interrompe dopo aver tolto gli indici: `psql "$SUPABASE_DB_URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/manutenzione_specie_3_ricrea_indici.sql`.
```

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "Tassonomia fase 1b applicata: specie compattata, CLAUDE.md"
```

Nessun push senza richiesta dell'utente.
