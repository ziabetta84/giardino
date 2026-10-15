# Modello tassonomico — fase 2: importazione di Catalogue of Life in `taxa` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** caricare nella tabella `public.taxa` del database reale i taxon di Catalogue of Life Extended Release (COL26.9 XR) che servono ai nomi di `specie` e `generi`: 236.291 righe, circa 73 MB. Nessun'altra tabella cambia.

**Architecture:** COL completo (8,5 milioni di nomi) si carica solo in una copia locale, nello schema `col`. Lì una selezione SQL sceglie i taxon necessari e assegna le chiavi uuid definitive:
- le corrispondenze esatte dei nostri nomi in Plantae;
- i loro accettati;
- la catena dei padri fino a *Eukaryota*;
- i sinonimi degli accettati e dei loro generi.

La selezione si esporta in lotti CSV con i valori definitivi (padri e accettati già risolti) e con un manifesto di controllo. Lo script di caricamento li porta in `taxa` un lotto per transazione:
- controlla lo spazio prima di ogni passo e fa pause di 10 minuti sul reale;
- toglie gli indici secondari prima del caricamento e li ricrea dopo;
- si può rilanciare dopo un'interruzione.

Tutto si prova sulla copia locale. Il database reale si tocca solo nell'ultimo task, dopo il via esplicito dell'utente.

**Tech Stack:** PostgreSQL 17 (Supabase, progetto `ncuhhsvtjwcolhpdxbkt`, piano gratuito; copia locale con i binari in `/opt/homebrew/opt/postgresql@17/bin/`), bash, curl, unzip, il formato ColDP di COL.

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md`: sezioni "taxa", "Fasi" (punto 2), "Decisioni dopo la verifica" (punti 1, 2, 4, 5, 10) e "Decisioni sullo spazio" (punti 1, 5, 6). Le misure dello spazio sono in `docs/ricerche/2026-10-14-stima-spazio.md`.

## Global Constraints

- **Versione di riferimento:** COL26.9 XR (`version: 2026-09-25 XR`, ChecklistBank 316441, DOI 10.48580/dgz9s). Il file `xr_latest_coldp.zip` (1.416.328.110 byte, sha256 `1510f2f76d5d3e02fa2dfde778b81daa3a3a842134fc2a0336b521b0c6509b6b`) è in `~/giardino-dati/col/`, fuori dal repository (decisione 3 della specifica). Non va riscaricato: se COL pubblica una versione nuova, questa fase continua con la 26.9.
- **Che cosa entra in `taxa` ("solo il necessario", definito qui):**
  - i semi: i nomi delle righe di `specie` senza apici (cioè non cultivar) e i nomi di `generi`, confrontati con una chiave che ignora il segno d'ibrido (× o x) e il suffisso " spp."; vale solo la corrispondenza esatta e solo in Plantae, perché *Prunella* è anche un genere di uccelli;
  - gli accettati dei semi;
  - la catena dei padri fino alla radice *Eukaryota*;
  - i sinonimi (`synonym`, `ambiguous synonym`) degli accettati e dei generi della catena;
  - i nomi `misapplied`, solo se sono proprio il nome di una nostra riga.
  
  Nient'altro di COL entra. I nomi non trovati sono il lavoro della fase 3.
- **Valori in `taxa`:**
  - `origine` = `col`; `versione_col` = `COL26.9 XR`;
  - `rango`, `stato`, `nome_scientifico`, `autore` come in COL;
  - `notho` in minuscolo (COL lo scrive in maiuscolo, per esempio `SPECIFIC`); per l'unico valore doppio, `GENERIC,SPECIFIC`, vale il primo;
  - `accettato_id` solo per sinonimi e misapplied; `padre_id` solo per gli accettati; `padre_id` vuoto solo per *Eukaryota*;
  - chiavi uuid nostre (decisione 1 della specifica); `col_id` resta un attributo.
- **Solo `taxa` cambia.** L'impronta di `specie` (`scripts/tassonomia/impronta_specie.sql`) deve essere identica prima e dopo; le altre tabelle non si toccano.
- **Spazio:**
  - prima di ogni passo sul reale, somma dei database ≤ 400 MB e WAL ≤ 300 MB, altrimenti ci si ferma;
  - attesi circa 73 MB per `taxa` e una somma di circa 261 MB su 500 (oggi 187,8);
  - se dopo la fase la somma supera 450 MB ci si ferma e si passa al piano Pro (specifica, "Decisioni sullo spazio", punto 1).
- **Caricamento:**
  - un lotto per transazione: prima gli accettati (21.664 righe), poi i sinonimi in lotti da al massimo 110.000 righe (circa 40 MB di WAL ciascuno; il limite della specifica è circa 100 MB);
  - pause di 10 minuti tra un lotto e l'altro sul reale;
  - i 3 indici secondari di `taxa` (`taxa_padre_id_idx`, `taxa_accettato_id_idx`, `taxa_nome_scientifico_trgm_idx`) si tolgono prima e si ricreano dopo; nessun aggiornamento di massa.
- **Connessione:**
  - sul reale si usa solo `SUPABASE_DB_URL` (pooler in modalità sessione, porta 5432), mai la 6543;
  - il pooler ha uno `statement_timeout` di 2 minuti: ogni lotto lo alza solo dentro la sua transazione (`set local`).
- **Prove:** girano sulla copia locale (`127.0.0.1:55440`). COL completo non entra mai nel database reale; sul reale, prima del Task 4, solo letture.
- **Regole di lavoro:**
  - nessuna applicazione al database reale senza il via esplicito dell'utente in chat;
  - nessun push senza richiesta esplicita;
  - l'URL del database contiene la password: non si stampa mai, nemmeno con `ps` (si elencano solo pid e nome dei processi).
- **Permessi di Claude Code:** il controllo automatico dei permessi può bloccare i comandi che scrivono sul reale. In quel caso si dà all'utente il comando da lanciare nel suo terminale, come per la fase 1b, e si riprende dalle misure.
- **Revisione e ramo:**
  - si lavora su `main`, come per le fasi 1 e 1b (solo script e documentazione nel repository);
  - revisione dei Task 1–3 da parte di revisori nuovi prima del Task 4.

## Review Focus

1. **Caricamento interrotto a metà** (terminale chiuso, Ctrl-C durante una pausa o un lotto): rilanciando lo stesso comando si riparte senza righe doppie né mancanti, e gli indici tornano. Prove `ripresa` e `rilancio` nel Task 3.
2. **Lotti diversi da quelli provati** (un file alterato o rigenerato con chiavi diverse): il caricamento si rifiuta prima di scrivere. Prova `lotto_alterato` nel Task 3.
3. **Database già vicino al limite o WAL alto:** il caricamento si ferma prima del lotto, senza caricare niente in quel passo. Prova `spazio` nel Task 3.
4. **Omonimi tra regni o righe fuori da Plantae** (*Prunella* è anche un uccello): non devono mai entrare in `taxa`. `prova_col_selezione.sql` nel Task 2 e `verifica_fase2.sql` nel Task 3.
5. **`taxa` con righe di un'altra versione di COL**, per esempio se si rilancia con lotti preparati da un file più nuovo: rifiuto, perché mescolare versioni rompe il confronto tra rilasci. Prova `altra_versione` nel Task 3.

## Misure del prototipo (15/10/2026, copia locale)

| Misura | Valore |
|---|---|
| NameUsage.tsv | 8.479.599 righe (1,2 GB in Postgres) |
| Nomi distinti nostri | 18.023, di cui 16.918 trovati |
| Selezione | 236.291 righe: 21.610 accepted, 54 provisionally accepted, 199.831 synonym, 14.742 ambiguous synonym, 54 misapplied |
| `taxa` dopo il caricamento | 36,8 MB di heap e 36,3 MB di indici, 73,1 MB in tutto |
| WAL | 83,5 MB in un colpo solo, più 12,9 MB per gli indici |
| Copertura delle 15.678 righe non cultivar di `specie` | 12.236 con un accettato, 2.351 solo come sinonimo, 1.091 non trovate (526 nomi irregolari, 440 binomi, 124 ibridi, 1 genere) |

## File

- Modify: `scripts/tassonomia/copia_locale.sh` — la copia contiene anche le 5 tabelle del modello (`taxa`, `nomi_comuni`, `cultivar`, `schede`, `mappa_specie`).
- Create: `scripts/tassonomia/col_scarica.sh` — scarica COL XR (ColDP) e ne verifica l'integrità.
- Create: `scripts/tassonomia/col_carica_locale.sh` — carica le colonne utili di NameUsage nello schema `col` della copia locale.
- Create: `scripts/tassonomia/col_selezione.sql` — la selezione con le chiavi uuid.
- Create: `scripts/tassonomia/prova_col_selezione.sql` — prove della selezione.
- Create: `scripts/tassonomia/col_esporta_lotti.sh` — lotti CSV, manifesto, nomi non trovati.
- Create: `scripts/tassonomia/controlli_spazio.sql` — misure e soglie di spazio per le fasi 2–4.
- Create: `scripts/tassonomia/carica_taxa.sh` — il caricamento a lotti.
- Create: `scripts/tassonomia/verifica_fase2.sql` — controllo di `taxa` dopo il caricamento.
- Create: `scripts/tassonomia/rollback_fase2.sql`
- Create: `scripts/tassonomia/prova_fase2.sh` — prove del caricamento sulla copia locale.
- Modify: `CLAUDE.md` — sezione "Modello tassonomico" (Task 4).

Tutti i comandi si lanciano dalla radice del repository. In ogni shell nuova vanno impostate queste variabili:
- `PG=/opt/homebrew/opt/postgresql@17/bin`;
- `SCRATCH` = la cartella temporanea della sessione (scratchpad);
- `COLDIR=$HOME/giardino-dati/col`;
- `LOTTI=$COLDIR/lotti_fase2`;
- `COPIA=postgresql://postgres@127.0.0.1:55440/giardino` (dal Task 1, Step 3);
- `SUPABASE_DB_URL` da `.env.local` (`set -a; source .env.local; set +a`);
- `TS` e `BK` dal Task 4, Step 1.

---

### Task 1: Copia locale con le tabelle del modello e COL in locale

**Files:**
- Modify: `scripts/tassonomia/copia_locale.sh` (filtro dell'elenco di `pg_restore` e intestazione)
- Create: `scripts/tassonomia/col_scarica.sh`
- Create: `scripts/tassonomia/col_carica_locale.sh`

**Interfaces:**
- Consumes: il backup completo `backups/completo_20261015_062051_pre_manutenzione_specie.dump` (fase 1b; contiene le tabelle del modello vuote; `specie` ha gli stessi dati di oggi).
- Produces:
  - `copia_locale.sh crea BACKUP CARTELLA`, che ora ripristina anche `taxa`, `nomi_comuni`, `cultivar`, `schede` e `mappa_specie`;
  - `col_scarica.sh CARTELLA`, che stampa `versione COL26.9 XR`;
  - `col_carica_locale.sh ZIP URL_COPIA`, che crea `col.nome_uso (id, parent_id, status, nome, autore, rango, notho, codice, regno)`, tutto `text`, con chiave primaria su `id` e indice su `parent_id`, e stampa `righe 8479599`. I campi vuoti restano stringhe vuote, non NULL.

- [ ] **Step 1: Prova della copia con le tabelle del modello (deve fallire oggi)**

```bash
BK0=backups/completo_20261015_062051_pre_manutenzione_specie.dump
COPIA=$(bash scripts/tassonomia/copia_locale.sh crea "$BK0" "$SCRATCH/copia_fase2" | tail -1)
$PG/psql "$COPIA" -X -qAt \
  -c "select 'tabelle ' || count(*) from pg_tables where schemaname = 'public' and tablename in ('specie','generi','taxa','nomi_comuni','cultivar','schede','mappa_specie')" \
  -c "select 'indici_taxa ' || count(*) from pg_indexes where schemaname = 'public' and tablename = 'taxa'"
bash scripts/tassonomia/copia_locale.sh ferma "$SCRATCH/copia_fase2"
```

Expected: `tabelle 2` e `indici_taxa 0`.

- [ ] **Step 2: Estendere la copia locale**

In `scripts/tassonomia/copia_locale.sh` sostituire le righe 2 e 3 dell'intestazione:

```bash
# Copia locale di public.specie e public.generi presa da un backup completo (pg_dump -Fc), per provare le
# operazioni in blocco del modello tassonomico senza toccare il database reale (specifica, "Decisioni sullo
```

con:

```bash
# Copia locale di public.specie, public.generi e delle tabelle del modello tassonomico (taxa, nomi_comuni, cultivar,
# schede, mappa_specie) presa da un backup completo (pg_dump -Fc), per provare le operazioni in blocco del modello
# tassonomico senza toccare il database reale (specifica, "Decisioni sullo
```

e il filtro dell'elenco:

```bash
      | grep -E '^[0-9]+; [0-9]+ [0-9]+ (TABLE|TABLE DATA|CONSTRAINT|FK CONSTRAINT|INDEX|TRIGGER|POLICY|ROW SECURITY) public (specie|generi)[ _]' \
```

con:

```bash
      | grep -E '^[0-9]+; [0-9]+ [0-9]+ (TABLE|TABLE DATA|CONSTRAINT|FK CONSTRAINT|INDEX|TRIGGER|POLICY|ROW SECURITY) public (specie|generi|taxa|nomi_comuni|cultivar|schede|mappa_specie)[ _]' \
```

La chiave esterna di `piante` verso `taxa` ha l'etichetta `public piante` e resta fuori, come `piante`.

- [ ] **Step 3: Rilanciare la prova dello Step 1 e lasciare la copia accesa**

Stesso blocco dello Step 1, senza l'ultima riga (`ferma`): la copia serve per il resto della fase.

Expected: `tabelle 7` e `indici_taxa 5`.

- [ ] **Step 4: Prova dello scaricamento prima che lo script esista**

```bash
bash scripts/tassonomia/col_scarica.sh "$COLDIR"; echo "uscita $?"
```

Expected: `No such file or directory`, uscita 127.

- [ ] **Step 5: Scrivere `scripts/tassonomia/col_scarica.sh`**

```bash
#!/usr/bin/env bash
# Scarica Catalogue of Life Extended Release in formato ColDP (specifica, "Fonti e regole adottate") in una cartella
# fuori dal repository (decisione 3), riprendendo da dove si è fermato, e ne verifica l'integrità. Se il file c'è già
# non si riscarica: una versione nuova di COL è un reimport, da pianificare a parte (spostare prima il file vecchio).
# Il sito di download vuole un browser: user agent da browser e cookie.
# Uso: bash scripts/tassonomia/col_scarica.sh CARTELLA        (stampa: versione <alias di metadata.yaml>)
set -euo pipefail
DIR=${1:?manca CARTELLA}
SORGENTE=https://download.checklistbank.org/col/xr_latest_coldp.zip
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36"
mkdir -p "$DIR"
cd "$DIR"
CURL=(curl -sS -L --fail -A "$UA" -c cj.txt -b cj.txt)
if [ -f xr_latest_coldp.zip ]; then
  echo "già scaricato"
else
  tot=$("${CURL[@]}" -I "$SORGENTE" | tr -d '\r' | awk 'tolower($1) == "content-length:" { n = $2 } END { print n }')
  [[ $tot =~ ^[0-9]+$ ]] || { echo "Dimensione del file sul server non disponibile" >&2; exit 1; }
  # un file parziale di un'altra versione non si può riprendere
  [ "$(cat xr_latest_coldp.zip.dimensione 2>/dev/null)" = "$tot" ] || rm -f xr_latest_coldp.zip.part
  echo "$tot" > xr_latest_coldp.zip.dimensione
  for tentativo in 1 2 3 4 5 6 7 8 9 10; do
    [ -f xr_latest_coldp.zip.part ] && [ "$(stat -f %z xr_latest_coldp.zip.part)" -ge "$tot" ] && break
    "${CURL[@]}" -C - --speed-limit 20000 --speed-time 60 -o xr_latest_coldp.zip.part "$SORGENTE" \
      || echo "tentativo $tentativo interrotto, riprendo" >&2
  done
  [ "$(stat -f %z xr_latest_coldp.zip.part)" -eq "$tot" ] || { echo "Scaricamento incompleto" >&2; exit 1; }
  mv xr_latest_coldp.zip.part xr_latest_coldp.zip
  rm -f xr_latest_coldp.zip.dimensione
fi
unzip -tq xr_latest_coldp.zip > /dev/null
shasum -a 256 xr_latest_coldp.zip > xr_latest_coldp.zip.sha256
unzip -p xr_latest_coldp.zip metadata.yaml | awk -F': ' '$1 == "alias" { print "versione " $2 }'
```

- [ ] **Step 6: Lanciarlo sul file già scaricato**

```bash
bash scripts/tassonomia/col_scarica.sh "$COLDIR"; echo "uscita $?"; cut -d' ' -f1 "$COLDIR/xr_latest_coldp.zip.sha256"
```

Expected: `già scaricato`, `versione COL26.9 XR`, `uscita 0`, poi `1510f2f76d5d3e02fa2dfde778b81daa3a3a842134fc2a0336b521b0c6509b6b`. Se lo sha256 è diverso, il file non è quello del prototipo: fermarsi e riferire.

- [ ] **Step 7: Prova del caricamento locale prima che lo script esista**

```bash
bash scripts/tassonomia/col_carica_locale.sh "$COLDIR/xr_latest_coldp.zip" "$COPIA"; echo "uscita $?"
```

Expected: `No such file or directory`, uscita 127.

- [ ] **Step 8: Scrivere `scripts/tassonomia/col_carica_locale.sh`**

```bash
#!/usr/bin/env bash
# Carica nello schema col della copia locale le colonne di NameUsage.tsv (COL XR, formato ColDP) che servono alla
# selezione della fase 2: ID, parentID, status, scientificName, authorship, rank, notho, code, kingdom. Sono circa
# 8,5 milioni di righe (1,2 GB): COL completo non entra mai nel database reale. Il file è un TSV senza virgolette,
# con le sole sequenze \t \n \\ (stesso formato di COPY text). I campi vuoti restano stringhe vuote.
# Uso: bash scripts/tassonomia/col_carica_locale.sh ZIP URL_COPIA
set -euo pipefail
cd "$(dirname "$0")/../.."
ZIP=${1:?manca ZIP}; URL=${2:?manca URL della copia locale}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "COL si carica solo nella copia locale" >&2; exit 1; }
[ -f "$ZIP" ] || { echo "File non trovato: $ZIP" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)

# Le colonne si cercano per nome e devono comparire in quest'ordine (lo stesso della tabella col.nome_uso).
intestazione=$(unzip -p "$ZIP" NameUsage.tsv | head -1 || true)
trovate=$(tr '\t' '\n' <<<"$intestazione" | grep -nxE 'col:(ID|parentID|status|scientificName|authorship|rank|notho|code|kingdom)' || true)
[ "$(cut -d: -f3 <<<"$trovate" | paste -sd, -)" = "ID,parentID,status,scientificName,authorship,rank,notho,code,kingdom" ] \
  || { echo "Formato di NameUsage.tsv inatteso: $(cut -d: -f3 <<<"$trovate" | paste -sd, -)" >&2; exit 1; }
posizioni=$(cut -d: -f1 <<<"$trovate" | paste -sd, -)

"${PSQL[@]}" -c 'drop schema if exists col cascade' -c 'create schema col' \
  -c 'create table col.nome_uso (id text, parent_id text, status text, nome text, autore text, rango text, notho text, codice text, regno text)'
unzip -p "$ZIP" NameUsage.tsv | tail -n +2 | cut -f"$posizioni" \
  | "${PSQL[@]}" -c 'set statement_timeout = 0' -c 'copy col.nome_uso from stdin'
"${PSQL[@]}" -c 'set statement_timeout = 0' -c 'alter table col.nome_uso add primary key (id)' \
  -c 'create index nome_uso_parent_id_idx on col.nome_uso (parent_id)' -c 'analyze col.nome_uso'
"${PSQL[@]}" -tAc "select 'righe ' || count(*) from col.nome_uso"
```

- [ ] **Step 9: Caricare COL nella copia e controllare**

Il caricamento dura circa 5 minuti in tutto: 2 per i dati, 3 per gli indici.

```bash
bash scripts/tassonomia/col_carica_locale.sh "$COLDIR/xr_latest_coldp.zip" "$COPIA"; echo "uscita $?"
$PG/psql "$COPIA" -X -qAt -c "select status || ' ' || count(*) from col.nome_uso group by status order by count(*) desc" \
  -c "select 'backslash ' || count(*) from col.nome_uso where nome like '%\\%' or autore like '%\\%'" \
  -c "select 'notho ' || string_agg(distinct notho, ',') from col.nome_uso where notho <> ''"
```

Expected:
- `righe 8479599`, `uscita 0`;
- `accepted 5072330`, `synonym 3095168`, `provisionally accepted 165171`, `ambiguous synonym 140450`, `misapplied 6480`;
- `backslash 0`;
- `notho` con i valori `GENERIC`, `GENERIC,SPECIFIC`, `INFRASPECIFIC`, `SPECIFIC`, in un ordine qualsiasi.

- [ ] **Step 10: Commit**

```bash
chmod +x scripts/tassonomia/col_scarica.sh scripts/tassonomia/col_carica_locale.sh
git add scripts/tassonomia/copia_locale.sh scripts/tassonomia/col_scarica.sh scripts/tassonomia/col_carica_locale.sh
git commit -m "Tassonomia fase 2: copia locale con le tabelle del modello, scaricamento e caricamento locale di COL XR"
```

---

### Task 2: Selezione dei taxon e lotti da caricare

**Files:**
- Create: `scripts/tassonomia/prova_col_selezione.sql`
- Create: `scripts/tassonomia/col_selezione.sql`
- Create: `scripts/tassonomia/col_esporta_lotti.sh`

**Interfaces:**
- Consumes: `col.nome_uso` (Task 1), `public.specie` e `public.generi` della copia.
- Produces:
  - **funzione** `col.chiave(text) returns text`;
  - **tabelle:**
    - `col.nostri (chiave)`;
    - `col.corrispondenze (id, status, parent_id, chiave)`;
    - `col.accettati (id)`;
    - `col.catena (id)`;
    - `col.sinonimi (id)`;
    - `col.selezione (col_id text primary key, id uuid unique)`;
  - **riepilogo** di `col_selezione.sql`: righe `nomi`, `nomi_trovati`, `accettati`, `sinonimi`, `selezione`;
  - **`col_esporta_lotti.sh URL_COPIA CARTELLA VERSIONE`** scrive in `CARTELLA`:
    - `versione.txt`;
    - `manifest.tsv` (una riga per lotto: file, righe, sha256, primo `col_id`, separati da tab, nell'ordine di caricamento);
    - `lotto_01.csv`, `lotto_02.csv`, … in CSV con intestazione e le colonne `id, origine, col_id, versione_col, rango, nome_scientifico, autore, notho, stato, accettato_id, padre_id`;
    - `non_trovati.tsv` (slug e nome scientifico delle righe non trovate, per la fase 3).

- [ ] **Step 1: Scrivere le prove della selezione**

`scripts/tassonomia/prova_col_selezione.sql`:

```sql
-- Prove della selezione della fase 2 (col_selezione.sql), sulla copia locale. Errore al primo controllo che fallisce.
-- I numeri valgono per COL26.9 XR e per specie e generi del 15/10/2026 (fase 2, misure del prototipo).
do $$
declare
  n bigint;
begin
  if col.chiave('Laburnum x watereri') <> 'Laburnum watereri' or col.chiave('Petunia spp.') <> 'Petunia'
     or col.chiave('x Fatshedera lizei') <> 'Fatshedera lizei' or col.chiave('×Fatshedera') <> 'Fatshedera'
     or col.chiave('× Burrageara') <> 'Burrageara' or col.chiave('Mentha × piperita') <> 'Mentha piperita'
     or col.chiave('  Rosa   canina ') <> 'Rosa canina'
     or col.chiave('Apium graveolens var. dulce') <> 'Apium graveolens var. dulce' then
    raise exception 'col.chiave non normalizza come atteso';
  end if;
  select count(*) into n from col.selezione;
  if n <> 236291 then raise exception 'selezione: % righe (attese 236291)', n; end if;
  -- chiusura: il padre di ogni accettato e l'accettato di ogni sinonimo sono nella selezione
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id
   where u.parent_id <> '' and not exists (select 1 from col.selezione p where p.col_id = u.parent_id);
  if n > 0 then raise exception 'selezione non chiusa: % righe con il padre o l''accettato fuori', n; end if;
  -- solo piante: gli accettati sono in Plantae, tranne Eukaryota e Plantae stessa (il regno vuoto in COL)
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id
   where u.status in ('accepted', 'provisionally accepted') and u.regno <> 'Plantae' and u.nome not in ('Eukaryota', 'Plantae');
  if n > 0 then raise exception 'accettati fuori da Plantae: %', n; end if;
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id where u.nome = 'Prunella';
  if n <> 1 then raise exception 'Prunella: % righe (attesa 1, il genere delle piante)', n; end if;
  -- misapplied solo se corrispondono direttamente a un nostro nome
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id
   where u.status = 'misapplied' and not exists (select 1 from col.nostri x where x.chiave = col.chiave(u.nome));
  if n > 0 then raise exception 'misapplied senza corrispondenza diretta: %', n; end if;
  perform 1 from col.selezione s join col.nome_uso u on u.id = s.col_id where u.nome = 'Lycopersicon esculentum' and u.status = 'synonym';
  if not found then raise exception 'manca il sinonimo Lycopersicon esculentum'; end if;
  perform 1 from col.selezione s join col.nome_uso u on u.id = s.col_id where u.nome = 'Fatshedera' and u.rango = 'genus';
  if not found then raise exception 'manca il genere Fatshedera'; end if;
  select count(*) - count(distinct id) into n from col.selezione;
  if n > 0 then raise exception 'chiavi uuid doppie: %', n; end if;
  raise notice 'SELEZIONE CORRETTA: % righe', (select count(*) from col.selezione);
end $$;
```

- [ ] **Step 2: Lanciarle e vederle fallire**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_col_selezione.sql; echo "uscita $?"
```

Expected: `ERROR:  function col.chiave(unknown) does not exist` (o `relation "col.selezione" does not exist`), uscita 3.

- [ ] **Step 3: Scrivere `scripts/tassonomia/col_selezione.sql`**

```sql
-- Fase 2: sceglie in COL XR (schema col della copia locale) i taxon che servono e assegna loro la chiave definitiva.
-- Semi: i nomi delle righe di specie senza apici (non cultivar) e di generi, confrontati con col.chiave, che ignora il
-- segno d'ibrido (× o x, COL scrive "Mentha × piperita" ma "Fatshedera" senza segno) e " spp."; solo in Plantae
-- (Prunella è anche un genere di uccelli; per i sinonimi il regno è quello del loro accettato). Dai semi: i loro
-- accettati, la catena dei padri fino alla radice (Eukaryota), i sinonimi degli accettati e dei generi della catena.
-- I misapplied entrano solo se sono il nome stesso di una nostra riga. Il resto di COL non entra.
-- Si rilancia senza danni: ricrea le tabelle col.* e assegna chiavi nuove (i lotti vanno rigenerati).
-- Uso: psql URL_COPIA -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/col_selezione.sql
set statement_timeout = 0;
create or replace function col.chiave(n text) returns text language sql immutable parallel safe as $$
  select btrim(regexp_replace(
           regexp_replace(
             regexp_replace(n, '\s+spp\.?\s*$', ''),
             '(^|\s)[×x](\s+|(?=[A-Z]))', ' ', 'g'),
           '\s+', ' ', 'g'))
$$;
-- l'indice dipende dal corpo della funzione: si ricrea a ogni esecuzione (circa 80 secondi)
drop index if exists col.nome_uso_chiave_idx;
create index nome_uso_chiave_idx on col.nome_uso (col.chiave(nome));
analyze col.nome_uso;

drop table if exists col.nostri, col.corrispondenze, col.accettati, col.catena, col.sinonimi, col.selezione;
create table col.nostri as
  select distinct col.chiave(nome_scientifico) as chiave from public.specie where nome_scientifico !~ ''''
  union select col.chiave(nome_scientifico) from public.generi;
create table col.corrispondenze as
  select u.id, u.status, u.parent_id, n.chiave
    from col.nostri n
    join col.nome_uso u on col.chiave(u.nome) = n.chiave
    left join col.nome_uso p on p.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym', 'misapplied')
   where coalesce(nullif(u.regno, ''), p.regno) = 'Plantae';
create index corrispondenze_chiave_idx on col.corrispondenze (chiave);
create table col.accettati as
  select distinct case when status in ('accepted', 'provisionally accepted') then id else parent_id end as id
    from col.corrispondenze;
create table col.catena as
  with recursive c(id) as (
    select id from col.accettati
    union
    select u.parent_id from col.nome_uso u join c on u.id = c.id where u.parent_id <> '')
  select id from c;
create table col.sinonimi as
  select u.id from col.nome_uso u
   where u.status in ('synonym', 'ambiguous synonym')
     and u.parent_id in (select id from col.accettati
                         union
                         select c.id from col.catena c join col.nome_uso g on g.id = c.id where g.rango = 'genus');
create table col.selezione (col_id text primary key, id uuid not null unique default gen_random_uuid());
insert into col.selezione (col_id)
  select id from col.catena union select id from col.corrispondenze union select id from col.sinonimi;
analyze col.selezione;

\pset tuples_only on
\pset format unaligned
select 'nomi ' || count(*) from col.nostri;
select 'nomi_trovati ' || count(distinct chiave) from col.corrispondenze;
select 'accettati ' || count(*) from col.selezione s join col.nome_uso u on u.id = s.col_id
 where u.status in ('accepted', 'provisionally accepted');
select 'sinonimi ' || count(*) from col.selezione s join col.nome_uso u on u.id = s.col_id
 where u.status not in ('accepted', 'provisionally accepted');
select 'selezione ' || count(*) from col.selezione;
```

- [ ] **Step 4: Eseguire la selezione e rilanciare le prove**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/col_selezione.sql; echo "uscita $?"
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_col_selezione.sql; echo "uscita $?"
```

Expected (circa 2 minuti):
- `nomi 18023`, `nomi_trovati 16918`, `accettati 21664`, `sinonimi 214627`, `selezione 236291`, `uscita 0`;
- poi `NOTICE:  SELEZIONE CORRETTA: 236291 righe` e `uscita 0`.

- [ ] **Step 5: Prova dell'esportazione prima che lo script esista**

```bash
bash scripts/tassonomia/col_esporta_lotti.sh "$COPIA" "$LOTTI" 'COL26.9 XR'; echo "uscita $?"
```

Expected: `No such file or directory`, uscita 127.

- [ ] **Step 6: Scrivere `scripts/tassonomia/col_esporta_lotti.sh`**

```bash
#!/usr/bin/env bash
# Fase 2: scrive i lotti da caricare in public.taxa a partire da col.selezione (copia locale). I CSV contengono i
# valori definitivi: chiavi uuid, padri e accettati già risolti, così il caricamento è un solo passaggio senza
# aggiornamenti (specifica, "Decisioni sullo spazio", punto 5). lotto_01.csv = gli accettati (la classificazione: i
# padri stanno tutti nello stesso lotto), poi i sinonimi in lotti da al massimo 110.000 righe, circa 40 MB di WAL
# ciascuno: i sinonimi puntano agli accettati del lotto 1. manifest.tsv (file, righe, sha256, primo col_id) fissa i
# lotti provati; non_trovati.tsv elenca le righe di specie senza corrispondenza, per la fase 3.
# Uso: bash scripts/tassonomia/col_esporta_lotti.sh URL_COPIA CARTELLA VERSIONE      (VERSIONE es. "COL26.9 XR")
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}; VERSIONE=${3:?manca VERSIONE}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I lotti si preparano solo dalla copia locale" >&2; exit 1; }
[[ $VERSIONE =~ ^COL[0-9.]+\ XR$ ]] || { echo "Versione non valida: $VERSIONE" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i lotti provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
MASSIMO=110000
mkdir -p "$DIR"
echo "$VERSIONE" > "$DIR/versione.txt"

"${PSQL[@]}" -c 'set statement_timeout = 0' -c 'drop table if exists col.lotti' -c "
  create table col.lotti as
  with sin as (select s.col_id from col.selezione s join col.nome_uso u on u.id = s.col_id
                where u.status not in ('accepted', 'provisionally accepted')),
       parti as (select ceil(count(*)::numeric / $MASSIMO)::int as n from sin)
  select s.col_id, 1 as lotto from col.selezione s join col.nome_uso u on u.id = s.col_id
   where u.status in ('accepted', 'provisionally accepted')
  union all
  select col_id, 1 + ntile((select n from parti)) over (order by col_id) from sin"

SELEZIONE="select s.id, 'col' as origine, s.col_id, '$VERSIONE' as versione_col, u.rango, u.nome as nome_scientifico,
                  nullif(u.autore, '') as autore, nullif(split_part(lower(u.notho), ',', 1), '') as notho, u.status as stato,
                  case when u.status in ('synonym', 'ambiguous synonym', 'misapplied') then p.id end as accettato_id,
                  case when u.status in ('accepted', 'provisionally accepted') then p.id end as padre_id
             from col.selezione s
             join col.nome_uso u on u.id = s.col_id
             join col.lotti l on l.col_id = s.col_id
             left join col.selezione p on p.col_id = nullif(u.parent_id, '')"
ultimo=$("${PSQL[@]}" -tAc 'select max(lotto) from col.lotti')
for k in $(seq 1 "$ultimo"); do
  file=$(printf 'lotto_%02d.csv' "$k")
  "${PSQL[@]}" -c 'set statement_timeout = 0' \
    -c "copy ($SELEZIONE where l.lotto = $k order by s.col_id) to stdout with (format csv, header)" > "$DIR/$file"
  righe=$(( $(wc -l < "$DIR/$file") - 1 ))
  primo=$(sed -n 2p "$DIR/$file" | cut -d, -f3)
  [[ $primo =~ ^[A-Za-z0-9]+$ ]] || { echo "col_id inatteso nel primo record di $file: $primo" >&2; exit 1; }
  printf '%s\t%s\t%s\t%s\n' "$file" "$righe" "$(shasum -a 256 "$DIR/$file" | cut -d' ' -f1)" "$primo" >> "$DIR/manifest.tsv"
done
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select s.slug, s.nome_scientifico from public.specie s
         where s.nome_scientifico !~ ''''
           and not exists (select 1 from col.corrispondenze c where c.chiave = col.chiave(s.nome_scientifico))
         order by s.nome_scientifico, s.slug) to stdout with (format text, header)" > "$DIR/non_trovati.tsv"
cat "$DIR/manifest.tsv" | cut -f1,2,4
echo "non_trovati $(( $(wc -l < "$DIR/non_trovati.tsv") - 1 ))"
```

- [ ] **Step 7: Esportare e controllare**

```bash
bash scripts/tassonomia/col_esporta_lotti.sh "$COPIA" "$LOTTI" 'COL26.9 XR'; echo "uscita $?"
head -1 "$LOTTI/lotto_01.csv"; cat "$LOTTI/versione.txt"
python3 - "$LOTTI" <<'PY'
import csv, os, sys
d = sys.argv[1]
for f in sorted(x for x in os.listdir(d) if x.startswith('lotto_')):
    righe = list(csv.DictReader(open(os.path.join(d, f), encoding='utf-8')))
    accettati = [r for r in righe if r['stato'] in ('accepted', 'provisionally accepted')]
    altri = [r for r in righe if r['stato'] not in ('accepted', 'provisionally accepted')]
    print(f, len(righe), 'accettati', len(accettati), 'senza padre', sum(not r['padre_id'] for r in accettati),
          'sinonimi senza accettato', sum(not r['accettato_id'] for r in altri))
PY
```

Expected:
- `lotto_01.csv 21664 …`, `lotto_02.csv 107314 …`, `lotto_03.csv 107313 …`; poi `non_trovati 1091` e `uscita 0`;
- l'intestazione `id,origine,col_id,versione_col,rango,nome_scientifico,autore,notho,stato,accettato_id,padre_id`, poi `COL26.9 XR`;
- dal controllo in Python:
  - `lotto_01.csv 21664 accettati 21664 senza padre 1 sinonimi senza accettato 0` (l'unico senza padre è *Eukaryota*);
  - `lotto_02.csv 107314 accettati 0 senza padre 0 sinonimi senza accettato 0`;
  - `lotto_03.csv 107313 accettati 0 senza padre 0 sinonimi senza accettato 0`.

Rilanciando lo script sulla stessa cartella deve rifiutarsi con `La cartella … esiste già`, perché i lotti provati non si sovrascrivono.

- [ ] **Step 8: Commit (i lotti restano fuori dal repository)**

```bash
chmod +x scripts/tassonomia/col_esporta_lotti.sh
git add scripts/tassonomia/col_selezione.sql scripts/tassonomia/prova_col_selezione.sql scripts/tassonomia/col_esporta_lotti.sh
git commit -m "Tassonomia fase 2: selezione dei taxon COL necessari e lotti da caricare"
```

---

### Task 3: Caricamento a lotti, verifica, rollback e prove sulla copia locale

**Files:**
- Create: `scripts/tassonomia/prova_fase2.sh`
- Create: `scripts/tassonomia/controlli_spazio.sql`
- Create: `scripts/tassonomia/carica_taxa.sh`
- Create: `scripts/tassonomia/verifica_fase2.sql`
- Create: `scripts/tassonomia/rollback_fase2.sql`

**Interfaces:**
- Consumes: i lotti del Task 2 (`$LOTTI`); `impronta_specie.sql` (fase 1b); la copia locale con `taxa` vuota (Task 1).
- Produces:
  - `carica_taxa.sh URL CARTELLA_LOTTI CARTELLA_MISURE`: uscita 0 e ultima riga `CARICAMENTO TAXA OK`. In `CARTELLA_MISURE` scrive:
    - `tempi.txt`, con righe `<ora> lotto_NN.csv: caricate R righe, WAL W MB`, `<ora> lotto_NN.csv già caricato`, `<ora> pausa di S s`;
    - `controlli_*.txt`;
    - `impronta_specie_prima.txt` e `impronta_specie_dopo.txt`.
  - `controlli_spazio.sql`: righe `somma_db_mb`, `wal_mb`, `taxa_mb`; con le variabili psql `soglia_mb` e `soglia_wal_mb` si ferma con `ERROR:  spazio insufficiente per caricare`.
  - `verifica_fase2.sql`: variabili psql `righe_attese` e `versione`.
  - `rollback_fase2.sql`: da lanciare con `psql -1`.
  - `prova_fase2.sh URL_COPIA CARTELLA_LOTTI CARTELLA`: ultima riga `PROVE FASE 2 OK`; alla fine `taxa` della copia contiene il caricamento completo.

- [ ] **Step 1: Scrivere le prove**

`scripts/tassonomia/prova_fase2.sh`:

```bash
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
echo "PROVE FASE 2 OK"
```

- [ ] **Step 2: Lanciarle e vederle fallire**

```bash
bash scripts/tassonomia/prova_fase2.sh "$COPIA" "$LOTTI" "$SCRATCH/prove_fase2_0" > "$SCRATCH/prove_fase2_0.log" 2>&1; echo "uscita $?"; tail -2 "$SCRATCH/prove_fase2_0.log"
```

Expected: `uscita 1` e `PROVA rifiuti FALLITA: bash: scripts/tassonomia/carica_taxa.sh: No such file or directory`.

- [ ] **Step 3: Scrivere i controlli di spazio, la verifica e il rollback**

`scripts/tassonomia/controlli_spazio.sql`:

```sql
-- Misure di spazio per i caricamenti del modello tassonomico (fasi 2-4). Sola lettura.
-- Con le variabili psql soglia_mb e soglia_wal_mb (sempre insieme) si ferma con un errore se la somma dei database
-- o il WAL le superano: oltre 500 MB il database va in sola lettura e il disco di Supabase è di 1 GB (specifica,
-- "Decisioni sullo spazio").
\pset tuples_only on
\pset format unaligned
select 'somma_db_mb ' || round(sum(pg_database_size(datname)) / 1e6, 1) from pg_database;
select 'wal_mb ' || round(coalesce(sum(size), 0) / 1e6, 1) from pg_ls_waldir();
select 'taxa_mb ' || round(pg_total_relation_size('public.taxa') / 1e6, 1);
\if :{?soglia_mb}
  \echo 'soglia_mb' :soglia_mb 'soglia_wal_mb' :soglia_wal_mb
  select (select sum(pg_database_size(datname)) from pg_database) > :soglia_mb::numeric * 1e6
      or (select coalesce(sum(size), 0) from pg_ls_waldir()) > :soglia_wal_mb::numeric * 1e6 as spazio_insufficiente \gset
  \if :spazio_insufficiente
    do $$ begin raise exception 'spazio insufficiente per caricare'; end $$;
  \endif
\endif
```

`scripts/tassonomia/verifica_fase2.sql`:

```sql
-- Fase 2: controllo di public.taxa dopo il caricamento di COL XR. Sola lettura.
-- Variabili psql: righe_attese (somma delle righe del manifesto dei lotti) e versione (es. COL26.9 XR).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_attese=N -v versione='COL26.9 XR' -f scripts/tassonomia/verifica_fase2.sql
select set_config('fase2.righe_attese', :'righe_attese', false), set_config('fase2.versione', :'versione', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase2.righe_attese')::bigint;
  versione text := current_setting('fase2.versione');
  n bigint;
begin
  select count(*) into n from public.taxa where origine = 'col';
  if n <> attese then raise exception 'taxa: % righe di COL, attese %', n, attese; end if;
  select count(*) into n from public.taxa where origine = 'col' and versione_col is distinct from versione;
  if n > 0 then raise exception 'taxa: % righe con una versione diversa da %', n, versione; end if;
  -- una sola radice della classificazione: Eukaryota
  select count(*) into n from public.taxa where stato in ('accepted', 'provisionally accepted') and padre_id is null;
  if n <> 1 or not exists (select 1 from public.taxa where padre_id is null and stato = 'accepted'
                                                      and nome_scientifico = 'Eukaryota' and rango = 'domain') then
    raise exception 'radici della classificazione: % (attesa una sola, Eukaryota)', n;
  end if;
  -- sinonimi e misapplied: hanno un accettato valido e nessun padre
  select count(*) into n from public.taxa s left join public.taxa a on a.id = s.accettato_id
   where s.stato in ('synonym', 'ambiguous synonym', 'misapplied')
     and (s.padre_id is not null or a.id is null or a.stato not in ('accepted', 'provisionally accepted'));
  if n > 0 then raise exception 'sinonimi senza un accettato valido: %', n; end if;
  -- un solo regno, Plantae, e ogni accettato sotto il regno ci arriva risalendo i padri
  select count(*) into n from public.taxa where rango = 'kingdom';
  if n <> 1 or not exists (select 1 from public.taxa where rango = 'kingdom' and nome_scientifico = 'Plantae') then
    raise exception 'regni in taxa: % (atteso solo Plantae)', n;
  end if;
  with recursive su(id, partenza, nome, rango) as (
    select id, id, nome_scientifico, rango from public.taxa where stato in ('accepted', 'provisionally accepted')
    union all
    select p.id, su.partenza, p.nome_scientifico, p.rango
      from su join public.taxa t on t.id = su.id join public.taxa p on p.id = t.padre_id),
  in_plantae as (select distinct partenza from su where rango = 'kingdom' and nome = 'Plantae')
  select count(*) into n from public.taxa t left join in_plantae b on b.partenza = t.id
   where t.stato in ('accepted', 'provisionally accepted') and t.rango not in ('domain', 'kingdom') and b.partenza is null;
  if n > 0 then raise exception 'taxon accettati fuori da Plantae: %', n; end if;
  -- i 5 indici, validi
  select count(*) into n from pg_index i join pg_class c on c.oid = i.indexrelid
   where i.indrelid = 'public.taxa'::regclass and i.indisvalid and i.indisready
     and c.relname in ('taxa_pkey', 'taxa_col_id_key', 'taxa_padre_id_idx', 'taxa_accettato_id_idx', 'taxa_nome_scientifico_trgm_idx');
  if n <> 5 then raise exception 'indici di taxa validi: % su 5', n; end if;
  -- casi noti
  perform 1 from public.taxa where nome_scientifico = 'Solanum lycopersicum' and autore = 'L.' and stato = 'accepted' and rango = 'species';
  if not found then raise exception 'manca Solanum lycopersicum L. accettato'; end if;
  perform 1 from public.taxa s join public.taxa a on a.id = s.accettato_id
   where s.nome_scientifico = 'Lycopersicon esculentum' and a.nome_scientifico = 'Solanum lycopersicum';
  if not found then raise exception 'Lycopersicon esculentum non porta a Solanum lycopersicum'; end if;
  perform 1 from public.taxa where nome_scientifico = 'Mentha × piperita' and ibrido and notho = 'specific' and stato = 'accepted';
  if not found then raise exception 'manca Mentha × piperita come ibrido accettato'; end if;
  perform 1 from public.taxa g join public.taxa p on p.id = g.padre_id
   where g.nome_scientifico = 'Rosa' and g.rango = 'genus' and g.stato = 'accepted' and p.nome_scientifico = 'Roseae';
  if not found then raise exception 'Rosa non ha come padre la tribù Roseae'; end if;
  select count(*) into n from public.taxa where nome_scientifico = 'Prunella';
  if n <> 1 then raise exception 'Prunella: % righe (attesa 1, il genere delle piante)', n; end if;
  raise notice 'taxa: % righe, % MB; somma dei database % MB', attese,
    round(pg_total_relation_size('public.taxa') / 1e6, 1),
    (select round(sum(pg_database_size(datname)) / 1e6, 1) from pg_database);
end $$;
```

`scripts/tassonomia/rollback_fase2.sql`:

```sql
-- Rollback della fase 2: toglie da taxa le righe di COL. Si rifiuta se taxa è già usata (fasi 3-6) o se contiene
-- taxon locali. Non TRUNCATE: piante ha una chiave esterna verso taxa e TRUNCATE ... CASCADE svuoterebbe piante.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase2.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.taxa'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar)
     or exists (select 1 from public.schede) or exists (select 1 from public.mappa_specie where taxon_id is not null)
     or exists (select 1 from public.piante where taxon_id is not null)
     or exists (select 1 from public.taxa where origine = 'locale') then
    raise exception 'Rollback fase 2 rifiutato: taxa è già usata da altre tabelle o contiene taxon locali';
  end if;
end $$;
delete from public.taxa where origine = 'col';
```

`piante` non è nella copia locale: nella prova del rollback la riga `public.piante` darebbe errore. Lo script di rollback vale per il database reale, che ha `piante`. Per la copia locale la prova crea una `public.piante` minima prima del rollback: vedi lo Step 4.

- [ ] **Step 4: Rendere la copia locale adatta al rollback**

`rollback_fase2.sql` legge `public.piante`, che la copia non ha. Nella copia si crea una tabella `piante` minima e vuota, solo con la colonna che il rollback legge. Così lo script resta quello del reale.

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -c 'create table if not exists public.piante (taxon_id uuid references public.taxa (id) on delete restrict)'
```

Expected: nessun errore.

- [ ] **Step 5: Scrivere lo script di caricamento**

`scripts/tassonomia/carica_taxa.sh`:

```bash
#!/usr/bin/env bash
# Fase 2 del modello tassonomico: carica in public.taxa i lotti preparati da col_esporta_lotti.sh, uno per transazione.
# Regole sullo spazio (specifica, "Decisioni sullo spazio", punto 5):
# - prima di ogni passo controlla la somma dei database e il WAL;
# - tra un lotto e l'altro fa una pausa (10 minuti sul reale, perché il WAL venga riciclato);
# - i 3 indici secondari di taxa si tolgono prima e si ricreano dopo.
# Si può rilanciare dopo un'interruzione: ogni lotto è una transazione (c'è tutto o niente) e quelli già caricati
# vengono saltati. Le altre tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_taxa.sh URL CARTELLA_LOTTI CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 400 MB di database, 300 MB di WAL.
#   Sulla copia locale: PAUSA_S (secondi, predefinito 0), SOGLIA_MB e SOGLIA_WAL_MB (predefiniti 100000).
# Uscita 0 e ultima riga CARICAMENTO TAXA OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; LOTTI=${2:?manca CARTELLA_LOTTI}; OUT=${3:?manca CARTELLA_MISURE}
D=scripts/tassonomia
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATO: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_CARICAMENTO_REALE:-} == si ]] || { echo "RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si" >&2; exit 1; }
  PAUSA_S=600; SOGLIA_MB=400; SOGLIA_WAL_MB=300
else
  PAUSA_S=${PAUSA_S:-0}; SOGLIA_MB=${SOGLIA_MB:-100000}; SOGLIA_WAL_MB=${SOGLIA_WAL_MB:-100000}
fi
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
tempo() { echo "$(date +%T) $1" >> "$OUT/tempi.txt"; }
controlla() {
  "${PSQL[@]}" -v soglia_mb="$SOGLIA_MB" -v soglia_wal_mb="$SOGLIA_WAL_MB" -f $D/controlli_spazio.sql > "$OUT/controlli_$1.txt" \
    || { cat "$OUT/controlli_$1.txt" >&2; echo "FERMATO: spazio insufficiente prima di $1; in questo passo non è stato caricato niente" >&2; exit 1; }
}
caricato() { [ "$("${PSQL[@]}" -tAc "select count(*) from public.taxa where col_id = '$1'")" = 1 ]; }
primo_passo=1
pausa() {
  if [ "$primo_passo" = 1 ]; then primo_passo=0
  elif [ "$PAUSA_S" -gt 0 ]; then tempo "pausa di $PAUSA_S s"; sleep "$PAUSA_S"; fi
}

# 1. I lotti sono quelli provati (sha256 del manifesto) e della versione dichiarata.
VERSIONE=$(cat "$LOTTI/versione.txt")
[[ $VERSIONE =~ ^COL[0-9.]+\ XR$ ]] || { echo "RIFIUTATO: versione non valida in versione.txt" >&2; exit 1; }
while IFS=$'\t' read -r file righe sha primo <&3; do
  [[ $file =~ ^lotto_[0-9]{2}\.csv$ && $righe =~ ^[0-9]+$ && $primo =~ ^[A-Za-z0-9]+$ ]] \
    || { echo "RIFIUTATO: riga del manifesto non valida: $file" >&2; exit 1; }
  [ "$(shasum -a 256 "$LOTTI/$file" | cut -d' ' -f1)" = "$sha" ] \
    || { echo "RIFIUTATO: $file diverso da quello del manifesto" >&2; exit 1; }
done 3< "$LOTTI/manifest.tsv"
ATTESE=$(awk -F'\t' '{ s += $2 } END { print s }' "$LOTTI/manifest.tsv")
altre=$("${PSQL[@]}" -tAc "select count(*) from public.taxa where origine = 'col' and versione_col <> '$VERSIONE'")
[ "$altre" = 0 ] || { echo "RIFIUTATO: taxa contiene $altre righe di un'altra versione di COL" >&2; exit 1; }
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Indici secondari tolti solo se c'è qualcosa da caricare.
da_caricare=0
while IFS=$'\t' read -r file righe sha primo <&3; do
  caricato "$primo" || da_caricare=$((da_caricare + 1))
done 3< "$LOTTI/manifest.tsv"
if [ "$da_caricare" -gt 0 ]; then
  tempo "tolgo gli indici secondari di taxa ($da_caricare lotti da caricare)"
  "${PSQL[@]}" -c 'drop index if exists public.taxa_padre_id_idx, public.taxa_accettato_id_idx, public.taxa_nome_scientifico_trgm_idx'
fi

# 3. Un lotto per transazione; il conteggio si controlla dentro la transazione, prima del commit.
while IFS=$'\t' read -r file righe sha primo <&3; do
  if caricato "$primo"; then tempo "$file già caricato"; continue; fi
  pausa
  controlla "$file"
  prima=$("${PSQL[@]}" -tAc 'select count(*) from public.taxa')
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "$file: carico $righe righe"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.taxa (id, origine, col_id, versione_col, rango, nome_scientifico, autore, notho, stato, accettato_id, padre_id) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.taxa) <> $((prima + righe)) then raise exception 'lotto $file incompleto'; end if; end \$\$" \
    < "$LOTTI/$file"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "$file: caricate $righe righe, WAL $wal MB"
done 3< "$LOTTI/manifest.tsv"

# 4. Indici secondari (identici alla migration della fase 1) e statistiche.
pausa
controlla indici
lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
tempo "ricreo gli indici secondari di taxa"
"${PSQL[@]}" -1 -c 'set local statement_timeout = 0' \
  -c 'create index if not exists taxa_padre_id_idx on public.taxa (padre_id)' \
  -c 'create index if not exists taxa_accettato_id_idx on public.taxa (accettato_id)' \
  -c 'create index if not exists taxa_nome_scientifico_trgm_idx on public.taxa using gin (nome_scientifico extensions.gin_trgm_ops)'
"${PSQL[@]}" -c 'analyze public.taxa'
wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
tempo "indici ricreati, WAL $wal MB"

# 5. specie invariata, taxa corretta, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_attese="$ATTESE" -v versione="$VERSIONE" -f $D/verifica_fase2.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO TAXA OK"
```

La pausa del punto 4 si fa solo se in questo giro è stato caricato almeno un lotto. Se tutti i lotti erano già caricati, `pausa` passa alla prima chiamata senza aspettare.

- [ ] **Step 6: Lanciare le prove, due volte di fila**

Prima del secondo giro va fatto il rollback, perché le prove partono da `taxa` vuota. Durano qualche minuto a giro, per l'attesa di 60 s della prova `ripresa`.

```bash
chmod +x scripts/tassonomia/carica_taxa.sh scripts/tassonomia/prova_fase2.sh
for giro in 1 2; do
  bash scripts/tassonomia/prova_fase2.sh "$COPIA" "$LOTTI" "$SCRATCH/prove_fase2_$giro" > "$SCRATCH/prove_fase2_$giro.log" 2>&1
  echo "giro $giro uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase2_$giro.log"
  [ "$giro" = 2 ] || { $PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase2.sql && $PG/psql "$COPIA" -X -q -c 'vacuum full public.taxa'; }
done
cat "$SCRATCH/prove_fase2_1/r6/tempi.txt" "$SCRATCH/prove_fase2_1/r6/controlli_fine.txt"
```

Expected, per tutti e due i giri:
- `uscita 0`;
- `PROVA rifiuti OK`, `PROVA lotto_alterato OK`, `PROVA spazio OK`, `PROVA ripresa OK`, `PROVA rilancio OK`, `PROVA altra_versione OK`, `PROVA rollback OK`, `PROVE FASE 2 OK`.

In `r6/tempi.txt`:
- `lotto_01.csv già caricato`;
- `lotto_02.csv: caricate 107314 righe, WAL … MB` e `lotto_03.csv: caricate 107313 righe, WAL … MB`, ciascuno sotto 100 MB (attesi circa 40);
- `indici ricreati`.

In `controlli_fine.txt`, `taxa_mb` circa 73.

- [ ] **Step 7: Prove di mutazione (tre difetti messi apposta devono essere scoperti)**

Per ogni mutazione:
1. copia di sicurezza dello script;
2. modifica;
3. rollback della copia, perché le prove partono da `taxa` vuota;
4. prove;
5. ripristino dello script.

```bash
vuota() { $PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase2.sql && $PG/psql "$COPIA" -X -q -c 'vacuum full public.taxa'; }
muta() {  # muta ESPRESSIONE_SED NOME
  cp scripts/tassonomia/carica_taxa.sh "$SCRATCH/carica_taxa.bak"
  sed -i '' "$1" scripts/tassonomia/carica_taxa.sh
  cmp -s scripts/tassonomia/carica_taxa.sh "$SCRATCH/carica_taxa.bak" && echo "MUTAZIONE $2 NON APPLICATA"
  vuota
  bash scripts/tassonomia/prova_fase2.sh "$COPIA" "$LOTTI" "$SCRATCH/mut2_$2" > "$SCRATCH/mut2_$2.log" 2>&1
  echo "mutazione $2: uscita $? — $(grep -E 'FALLITA' "$SCRATCH/mut2_$2.log" | head -1 | cut -c1-90)"
  cp "$SCRATCH/carica_taxa.bak" scripts/tassonomia/carica_taxa.sh
}
muta 's/\[ "$(shasum -a 256 "$LOTTI\/$file" | cut -d. . -f1)" = "$sha" \]/true/' sha
muta 's/if caricato "$primo"; then tempo/if false; then tempo/' salta
muta 's/^controlla inizio$//' soglia
git status --short scripts/tassonomia/
vuota
bash scripts/tassonomia/prova_fase2.sh "$COPIA" "$LOTTI" "$SCRATCH/prove_dopo_mutazioni" > "$SCRATCH/prove_dopo_mutazioni.log" 2>&1; echo "uscita $?"; tail -1 "$SCRATCH/prove_dopo_mutazioni.log"
```

Expected:
- nessuna riga `NON APPLICATA`;
- `mutazione sha: uscita 1 — PROVA lotto_alterato FALLITA: …`;
- `mutazione salta: uscita 1 — PROVA ripresa FALLITA: …`;
- `mutazione soglia: uscita 1 — PROVA spazio FALLITA: …`;
- `git status` mostra solo i file nuovi del Task 3 (`??`), nessuno modificato;
- infine `uscita 0` e `PROVE FASE 2 OK`.

Con la mutazione `soglia` il primo controllo di spazio salta, ma il caricamento si ferma comunque al controllo prima del lotto 1, con `FERMATO: spazio insufficiente prima di lotto_01.csv`. La prova `spazio` lo scopre perché richiede il messaggio `prima di inizio`: con questa mutazione gli indici sarebbero già stati tolti.

- [ ] **Step 8: Commit**

```bash
git add scripts/tassonomia/prova_fase2.sh scripts/tassonomia/controlli_spazio.sql scripts/tassonomia/carica_taxa.sh \
        scripts/tassonomia/verifica_fase2.sql scripts/tassonomia/rollback_fase2.sql
git commit -m "Tassonomia fase 2: caricamento di taxa a lotti con controlli di spazio, verifica, rollback e prove sulla copia locale"
```

**Prima del Task 4:** revisione dei commit dei Task 1–3 da parte di revisori nuovi (vedi Global Constraints). Le correzioni importanti si fanno con una prova che fallisce prima; poi si rilancia `prova_fase2.sh`, dopo un rollback della copia.

---

### Task 4: Caricamento sul database reale e documentazione

**Files:**
- Modify: `CLAUDE.md` (sezione "Modello tassonomico")

**Interfaces:**
- Consumes: `carica_taxa.sh`, `verifica_fase2.sql`, `rollback_fase2.sql` (Task 3); i lotti `$LOTTI` (Task 2), gli stessi provati nel Task 3.

- [ ] **Step 1: Backup completo e controllo di partenza (solo letture)**

```bash
set -a; source .env.local; set +a
TS=$(date +%Y%m%d_%H%M%S)
BK=backups/completo_${TS}_pre_fase2.dump
$PG/pg_dump "$SUPABASE_DB_URL" -Fc -f "$BK"
$PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/impronta_specie.sql > "${BK%.dump}.impronta.txt"
$PG/pg_restore -f /dev/null "$BK" && echo BACKUP LEGGIBILE
diff backups/completo_20261015_062051_pre_manutenzione_specie.impronta.txt "${BK%.dump}.impronta.txt" && echo "SPECIE COME NEI LOTTI"
$PG/psql "$SUPABASE_DB_URL" -X -q -f scripts/tassonomia/controlli_spazio.sql
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c "select 'taxa righe ' || count(*) from public.taxa"
```

Expected:
- `BACKUP LEGGIBILE`;
- `SPECIE COME NEI LOTTI`: `specie` è la stessa da cui sono stati preparati i lotti. Se no, fermarsi e riferire: i nomi da abbinare sono cambiati;
- `somma_db_mb` circa 188, `wal_mb` sotto 300, `taxa_mb` sotto 1;
- `taxa righe 0`.

- [ ] **Step 2: Via esplicito dell'utente**

Chiedere in chat il via per il caricamento sul database reale, dicendo:
- **durata:** circa 35 minuti, di cui 30 di pause (3 da 10 minuti);
- **effetto sull'app:** nessuno, perché l'app non legge ancora `taxa`;
- **spazio:** circa 73 MB in più, per arrivare a circa 261 MB su 500;
- **dati:** non cambia niente fuori da `taxa`;
- **ripresa:** se si interrompe basta rilanciare lo stesso comando;
- **rollback:** pronto, con `rollback_fase2.sql` e poi `vacuum full public.taxa`.

Senza un sì esplicito ci si ferma qui.

- [ ] **Step 3: Eseguire il caricamento**

Va lanciato dalla sessione principale in background (strumento Bash con `run_in_background`): continua tra un turno e l'altro e avvisa quando finisce. Non va lanciato da un subagente e non va fermato. Se il controllo dei permessi lo blocca, dare all'utente lo stesso comando da incollare nel suo terminale e chiedergli di scrivere quando compare la riga `uscita …`. Per sapere se è ancora attivo, usare `pgrep -f carica_taxa.sh`, che stampa solo il pid: mai elencare la riga di comando, perché contiene l'URL con la password.

```bash
set -a; source .env.local; set +a
OUT=backups/fase2_taxa_$(date +%Y%m%d_%H%M%S)
CONFERMO_CARICAMENTO_REALE=si bash scripts/tassonomia/carica_taxa.sh "$SUPABASE_DB_URL" "$HOME/giardino-dati/col/lotti_fase2" "$OUT" > "$OUT.log" 2>&1; echo "uscita $?"
```

Expected:
- `uscita 0`;
- nel log la NOTICE `taxa: 236291 righe, circa 73 MB; somma dei database circa 261 MB`, poi `CARICAMENTO TAXA OK`;
- in `$OUT/tempi.txt` i tre lotti con WAL sotto 100 MB ciascuno, le tre pause e `indici ricreati`.

Se l'uscita non è 0, prima di tutto (sola lettura) `$PG/psql "$SUPABASE_DB_URL" -X -q -f scripts/tassonomia/controlli_spazio.sql` e il conteggio delle righe di `taxa`. Poi:
- **`FERMATO: spazio insufficiente`:** niente caricato in quel passo. Riferire all'utente con i valori: se il WAL è alto, aspettare e rilanciare lo stesso comando.
- **Interrotto (log senza riga finale, terminale chiuso):** rilanciare lo stesso comando, che salta i lotti già caricati e ricrea gli indici.
- **`RIFIUTATO`:** non è stato scritto niente; riferire.
- **`FALLITO: specie è cambiata` o un errore di `verifica_fase2.sql`:** fermarsi, non rilanciare, e riferire all'utente con il messaggio. Il rollback si decide insieme.
- **`somma dei database` sopra 450 MB:** fermarsi e riferire. È il punto 1 delle decisioni sullo spazio, cioè il passaggio a Pro.

- [ ] **Step 4: Controlli finali con la chiave pubblica (lettura)**

```bash
set -a; source .env; set +a
curl -s -w ' %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/taxa?select=nome_scientifico,autore,rango,stato&nome_scientifico=eq.Solanum%20lycopersicum" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
curl -s -w ' %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/taxa?select=col_id&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
curl -s -o /dev/null -w 'ricerca %{http_code} %{time_total}s\n' "$VITE_SUPABASE_URL/rest/v1/taxa?select=id,nome_scientifico&nome_scientifico=ilike.*lycopers*&limit=50" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c 'show statement_timeout' -c 'show lock_timeout'
```

Expected:
- la prima risposta elenca due righe *Solanum lycopersicum* (`L.` accepted, `Blanco` synonym), codice `200`;
- la seconda dà un errore `42501` (colonna interna non leggibile), codice `401`;
- `ricerca 200` sotto 1 s;
- `2min` e `0`: nessuna impostazione rimasta sul pooler.

- [ ] **Step 5: Fermare la copia locale e aggiornare CLAUDE.md**

```bash
bash scripts/tassonomia/copia_locale.sh ferma "$SCRATCH/copia_fase2"
```

Il file di COL e i lotti restano in `~/giardino-dati/col/` per le fasi 3 e 4.

In `CLAUDE.md` vanno fatte due modifiche:
1. il titolo "### Modello tassonomico (in corso, fasi 1 e 1b di 7 applicate)" diventa "### Modello tassonomico (in corso, fasi 1, 1b e 2 di 7 applicate)";
2. in fondo alla sezione va aggiunto questo paragrafo, con le misure reali al posto di quelle attese se sono diverse:

```markdown
La fase 2 (piano `docs/superpowers/plans/2026-10-15-modello-tassonomico-fase2-import-col.md`) ha caricato in `taxa` 236.291 righe di Catalogue of Life, versione COL26.9 XR del 25/09/2026. Il file è in `~/giardino-dati/col/`, fuori dal repository, e non va riscaricato per questa fase.
- **Che cosa c'è:**
  - 21.664 taxon accettati: le corrispondenze esatte in Plantae dei nomi di `specie` (righe senza apici) e di `generi`, più la catena dei padri fino a *Eukaryota*;
  - 214.627 sinonimi degli accettati e dei loro generi; i «misapplied» solo se sono il nome di una nostra riga.
- **Chiavi:** uuid nostri, con `col_id` e `versione_col` come attributi.
- **Copertura:** 14.587 delle 15.678 righe non cultivar di `specie` hanno una corrispondenza esatta, accettata o come sinonimo. Le 1.091 restanti sono il lavoro della fase 3 (elenco in `~/giardino-dati/col/lotti_fase2/non_trovati.tsv`).
- **Spazio:** `taxa` circa 73 MB; somma dei database circa 261 MB su 500.
- **Script, tutti in `scripts/tassonomia/`:**
  - `col_scarica.sh` e `col_carica_locale.sh`: COL completo solo nella copia locale, schema `col`;
  - `col_selezione.sql`, con le prove in `prova_col_selezione.sql`;
  - `col_esporta_lotti.sh`: lotti CSV con un manifesto sha256;
  - `carica_taxa.sh`: un lotto per transazione, pause di 10 minuti e controllo dello spazio sul reale; si può rilanciare dopo un'interruzione;
  - `verifica_fase2.sql`;
  - `rollback_fase2.sql`, da eseguire con `psql -1` e poi `vacuum full public.taxa`. Mai TRUNCATE, perché `piante` ha una chiave esterna verso `taxa`.
- **Prove:** `bash scripts/tassonomia/prova_fase2.sh URL_COPIA CARTELLA_LOTTI CARTELLA`, su una copia con `taxa` vuota. Nella copia locale serve una `public.piante` minima (vedi il piano, Task 3, Step 4).
```

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "Tassonomia fase 2 applicata: taxa con 236.291 righe di COL26.9 XR, CLAUDE.md"
```

Nessun push senza richiesta dell'utente.
