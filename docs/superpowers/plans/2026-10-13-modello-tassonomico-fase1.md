# Modello tassonomico — fase 1: tabelle nuove vuote — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** creare nel database Supabase le tabelle vuote del nuovo modello (`taxa`, `nomi_comuni`, `cultivar`, `schede`, `mappa_specie`) e due colonne facoltative su `piante`, con permessi espliciti, senza toccare `specie`, `generi` né il comportamento dell'app.

**Architecture:** una sola migration SQL additiva, applicata con `psql -1` (tutto o niente), più un file di rollback che si rifiuta di agire se le tabelle contengono dati. Le prove sono script SQL eseguiti dentro una transazione che si chiude sempre con `rollback`: applicano la migration, verificano struttura, vincoli e permessi (anche impersonando i ruoli `anon` e `authenticated`), eseguono il rollback e verificano che tutto torni com'era. Il database reale viene modificato solo nell'ultimo task, dopo il via esplicito dell'utente.

**Tech Stack:** PostgreSQL 17 su Supabase (progetto `ncuhhsvtjwcolhpdxbkt`), `psql`, `pg_dump` 17 (`/opt/homebrew/opt/postgresql@17/bin/pg_dump`), bash.

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md` (sezioni "Modello dati", "Permessi", "Decisioni dopo la verifica").

## Global Constraints

- Nessuna modifica a `public.specie` e `public.generi` (né dati né schema).
- Su `public.piante` solo l'aggiunta di `taxon_id` e `cultivar_id`, facoltative, con al più una delle due valorizzata (`num_nonnulls(...) <= 1`): l'app attuale non le compila e deve continuare a creare piante.
- Chiave di `taxa`: uuid nostro; `col_id` è un attributo.
- Rango e stato di `taxa` con i vocabolari di COL in inglese, così come sono: per il rango tutti i valori di api.checklistbank.org/vocab/rank tranne cultivar, cultivar group e grex (che stanno in `cultivar`), perché la catena dei padri di COL XR contiene domain, subkingdom e subclass e i sinonimi usano subvariety, proles e lusus.
- La fonte non si mostra mai: le colonne `fonti`, `nota`, `col_id`, `versione_col`, `origine`, `importato_il`, `descrizione_originale`, `verificata_da`, `vecchia_specie_id` non sono leggibili da `anon` e `authenticated`; `mappa_specie` non è leggibile per niente dai client.
- I privilegi di colonna nascondono solo le colonne interne, non le fonti citate dentro il contenuto. Nelle righe madri di `specie` le fonti compaiono anche in `alert` (15.467 righe su 15.723), in `descrizione` (5.368) e in `immagine.fonte`/`fonte_pagina` (7.722), e queste colonne di `schede` sono leggibili con la chiave pubblica. La fase 1 crea tabelle vuote; il piano della fase 4 deve togliere quelle citazioni o spostarle in una colonna interna prima di popolare `schede`, e decidere con l'utente quali campi di `immagine` restano pubblici (l'attribuzione è richiesta dalle licenze CC BY/BY-SA).
- Nessuna scrittura per `anon` e `authenticated` sulle tabelle nuove.
- Permessi scritti in modo esplicito (`revoke all` da anon, authenticated e service_role, poi `grant` mirati), senza affidarsi ai privilegi di default di Supabase (che cambiano il 30/10/2026) né all'event trigger `ensure_rls` (non versionato); `enable row level security` esplicito.
- Nomi delle tabelle e delle colonne in italiano, come nel resto dello schema; nomi delle tabelle sempre qualificati con `public.`; indici trigram con `extensions.gin_trgm_ops`; trigger di data con `extensions.moddatetime`.
- La migration non contiene `begin`/`commit` (si applica con `psql -1`).
- Backup con `pg_dump` 17 e nome fuori dal glob di rotazione `giardino_zorba_*.sql`.
- Nessun push senza richiesta esplicita dell'utente. Nessuna applicazione al database senza il via esplicito dell'utente in chat.

## Review Focus

1. Una pianta nuova creata dall'app dopo la fase 1 (insert senza `taxon_id`/`cultivar_id`, come fa `salvaPianta`) deve essere accettata: prova nel Task 4.
2. Chi interroga `schede` con la chiave pubblica e `select=*` (la forma più ovvia) non deve ricevere la colonna `fonti`: deve ricevere un errore di permesso (42501), non i dati (le citazioni delle fonti dentro `alert`, `descrizione` e `immagine` sono un vincolo della fase 4, vedi Global Constraints). Prova nel Task 3.
3. La migration applicata prima o dopo il 30/10/2026 deve dare gli stessi permessi: le prove controllano i privilegi effettivi colonna per colonna, non la presenza di una policy. Prove nei Task 1–3.
4. Il rollback lanciato quando le tabelle contengono già dati (dalla fase 2 in poi) deve rifiutarsi, non cancellarli: prova negativa nel Task 5.
5. La migration lanciata una seconda volta su un database dove è già applicata deve fallire senza lasciare nulla a metà: prova negativa nel Task 5.

## File

- Create: `supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql` — la migration (una sezione per tabella, aggiunte task per task).
- Create: `scripts/tassonomia/rollback_fase1.sql` — rollback con protezione dei dati.
- Create: `scripts/tassonomia/prova_fase1.sql` — prova principale in transazione annullata (una sezione per task).
- Create: `scripts/tassonomia/prova_fase1_guardia.sql` — prova negativa: rollback con dati presenti.
- Create: `scripts/tassonomia/prova_fase1_doppia.sql` — prova negativa: migration applicata due volte.
- Create: `scripts/tassonomia/prova_fase1.sh` — esegue le tre prove e dice OK o FALLITA.
- Create: `scripts/tassonomia/verifica_fase1.sql` — controlli di sola lettura dopo l'applicazione reale.
- Modify: `CLAUDE.md` — sezione sul modello tassonomico (Task 6).

Tutte le prove si lanciano dalla radice del repository con `bash scripts/tassonomia/prova_fase1.sh`. Lo script legge `DATABASE_URL` da `.env.local`.

---

### Task 1: Prova di base, rollback e tabella `taxa`

**Files:**
- Create: `scripts/tassonomia/prova_fase1.sh`
- Create: `scripts/tassonomia/prova_fase1.sql`
- Create: `scripts/tassonomia/rollback_fase1.sql`
- Create: `supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql`

**Interfaces:**
- Produces: tabella `public.taxa` (colonne e vincoli sotto, FK chiamate `taxa_padre_fk` e `taxa_accettato_fk`); script `prova_fase1.sh` che i task successivi estendono aggiungendo sezioni a `prova_fase1.sql` prima del marcatore `-- FINE SEZIONI`; variabile psql `:proprietario` (uuid del proprietario delle piante, testo).

- [ ] **Step 1: Scrivere lo script che lancia le prove**

`scripts/tassonomia/prova_fase1.sh`:

```bash
#!/usr/bin/env bash
# Prove della fase 1 del modello tassonomico. Ogni prova gira in una transazione che non viene mai confermata:
# il database non cambia. Uscita 0 = tutte le prove passate.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=$(grep '^DATABASE_URL=' .env.local | cut -d= -f2- | tr -d '"')
PSQL=(psql "$URL" -X -q -v ON_ERROR_STOP=1)

"${PSQL[@]}" -f scripts/tassonomia/prova_fase1.sql

for prova in guardia doppia; do
  file="scripts/tassonomia/prova_fase1_${prova}.sql"
  [ -f "$file" ] || { echo "PROVA $prova FALLITA: manca $file"; exit 1; }
  atteso=$(head -1 "$file" | sed 's/^-- ATTESO: //')
  if out=$("${PSQL[@]}" -f "$file" 2>&1); then
    echo "PROVA $prova FALLITA: doveva dare errore"; exit 1
  fi
  # il messaggio deve stare nella riga di errore, non in un NOTICE
  if ! grep -qF "ERROR:  $atteso" <<<"$out"; then
    echo "PROVA $prova FALLITA: errore diverso da quello atteso"; echo "$out"; exit 1
  fi
  echo "PROVA $prova OK"
done
echo "PROVE FASE 1 OK"
```

- [ ] **Step 2: Scrivere la prova principale con la sezione `taxa`**

`scripts/tassonomia/prova_fase1.sql`:

```sql
-- Prova della fase 1: applica migration e rollback in una transazione che viene sempre annullata.
begin;

create temp table _prima as
select (select count(*) from public.specie) as specie,
       (select count(*) from public.piante) as piante,
       (select count(*) from public.generi) as generi;
select owner_id::text as proprietario from public.piante limit 1 \gset
-- piante del proprietario: serve mentre si impersona authenticated, che non può leggere _prima
select set_config('prova.piante_proprietario', (select count(*)::text from public.piante where owner_id::text = :'proprietario'), false);

\i supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql

-- ===== Sezione taxa =====
savepoint s_taxa;
do $$
declare g uuid; s uuid;
begin
  assert (select relrowsecurity from pg_class where oid = 'public.taxa'::regclass), 'taxa: RLS non attiva';
  assert exists (select 1 from pg_policies where tablename = 'taxa' and policyname = 'taxa: lettura pubblica' and cmd = 'SELECT'),
    'taxa: manca la policy di lettura';

  -- inserimenti validi (come postgres)
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, autore, stato)
    values ('col', 'PROVA1', '26.9 XR', 'genus', 'Hedera', 'L.', 'accepted') returning id into g;
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, autore, stato, padre_id)
    values ('col', 'PROVA2', '26.9 XR', 'species', 'Hedera helix', 'L.', 'accepted', g) returning id into s;
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato, accettato_id)
    values ('col', 'PROVA3', '26.9 XR', 'species', 'Hedera canariensis', 'synonym', s);
  insert into public.taxa (origine, rango, nome_scientifico, stato, nota)
    values ('locale', 'genus', 'Fatshedera', 'accepted', 'notogenere non marcato in COL');

  -- ibrido calcolato
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, notho, stato)
    values ('col', 'PROVA4', '26.9 XR', 'species', 'Mentha × piperita', 'specific', 'accepted');
  assert (select ibrido from public.taxa where col_id = 'PROVA4'), 'ibrido non calcolato da notho';
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato)
    values ('col', 'PROVA5', '26.9 XR', 'genus', '× Chitalpa', 'accepted');
  assert (select ibrido from public.taxa where col_id = 'PROVA5'), 'ibrido non calcolato dal segno ×';
  assert not (select ibrido from public.taxa where col_id = 'PROVA2'), 'Hedera helix risulta ibrido';
  -- ibridi scritti con la x semplice (ammessa dal codice ICN, 138 righe madri attuali): riconosciuti anche nei taxon locali
  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'species', 'Abelia x grandiflora', 'accepted');
  assert (select ibrido from public.taxa where nome_scientifico = 'Abelia x grandiflora'), 'ibrido con x semplice non riconosciuto';
  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'genus', 'x Fatshedera', 'accepted');
  assert (select ibrido from public.taxa where nome_scientifico = 'x Fatshedera'), 'notogenere con x semplice non riconosciuto';
  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'species', 'Rosa xanthina', 'accepted');
  assert not (select ibrido from public.taxa where nome_scientifico = 'Rosa xanthina'), 'epiteto che inizia per x scambiato per ibrido';

  -- ranghi presenti in COL XR nella catena dei padri (Rosa canina, Pinus mugo) e nei sinonimi (Rosa canina)
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato)
    values ('col', 'PROVA6', '26.9 XR', 'domain', 'Eukaryota', 'accepted'),
           ('col', 'PROVA7', '26.9 XR', 'subkingdom', 'Pteridobiotina', 'accepted'),
           ('col', 'PROVA8', '26.9 XR', 'subclass', 'Pinidae', 'accepted');
  insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato, accettato_id)
    values ('col', 'PROVA9', '26.9 XR', 'subvariety', 'Rosa canina subvar. aciphylla', 'synonym', s),
           ('col', 'PROVA10', '26.9 XR', 'proles', 'Rosa communis prol. canina', 'synonym', s),
           ('col', 'PROVA11', '26.9 XR', 'lusus', 'Rosa spuria lusus benacensis', 'synonym', s);

  -- vincoli che devono rifiutare
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato) values ('col', 'genus', 'Senza id', 'accepted');
    raise exception 'ATTESO ERRORE: taxon col senza col_id';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, col_id, rango, nome_scientifico, stato) values ('locale', 'X1', 'genus', 'Locale con id', 'accepted');
    raise exception 'ATTESO ERRORE: taxon locale con col_id';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'cultivar', 'Hedera helix ''Goldchild''', 'accepted');
    raise exception 'ATTESO ERRORE: rango cultivar in taxa';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'species', 'Stato inventato', 'dubbio');
    raise exception 'ATTESO ERRORE: stato fuori vocabolario';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato, accettato_id) values ('locale', 'species', 'Accettato con rinvio', 'accepted', s);
    raise exception 'ATTESO ERRORE: accettato con accettato_id';
  exception when check_violation then null; end;
  begin
    insert into public.taxa (origine, col_id, versione_col, rango, nome_scientifico, stato) values ('col', 'PROVA1', '26.9 XR', 'genus', 'Doppione', 'accepted');
    raise exception 'ATTESO ERRORE: col_id duplicato';
  exception when unique_violation then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato, padre_id) values ('locale', 'species', 'Padre inesistente', 'accepted', gen_random_uuid());
    set constraints taxa_padre_fk immediate;
    raise exception 'ATTESO ERRORE: padre inesistente';
  exception when foreign_key_violation then null; end;
end $$;

-- permessi effettivi, colonna per colonna
do $$
begin
  assert has_column_privilege('anon', 'public.taxa', 'nome_scientifico', 'SELECT'), 'anon non legge taxa.nome_scientifico';
  assert has_column_privilege('anon', 'public.taxa', 'padre_id', 'SELECT'), 'anon non legge taxa.padre_id';
  assert not has_column_privilege('anon', 'public.taxa', 'col_id', 'SELECT'), 'anon legge taxa.col_id';
  assert not has_column_privilege('anon', 'public.taxa', 'nota', 'SELECT'), 'anon legge taxa.nota';
  assert not has_column_privilege('authenticated', 'public.taxa', 'origine', 'SELECT'), 'authenticated legge taxa.origine';
  assert not has_table_privilege('anon', 'public.taxa', 'INSERT'), 'anon può inserire in taxa';
  assert not has_table_privilege('authenticated', 'public.taxa', 'UPDATE'), 'authenticated può aggiornare taxa';
  assert not has_table_privilege('authenticated', 'public.taxa', 'DELETE'), 'authenticated può cancellare da taxa';
  assert has_table_privilege('service_role', 'public.taxa', 'INSERT'), 'service_role non può inserire in taxa';
end $$;

-- comportamento reale impersonando anon
set local role anon;
do $$
begin
  assert (select count(*) from (select id, nome_scientifico from public.taxa) t) >= 5, 'anon non vede le righe di taxa';
  begin
    perform col_id from public.taxa limit 1;
    raise exception 'ATTESO ERRORE: anon legge col_id';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'genus', 'Da anon', 'accepted');
    raise exception 'ATTESO ERRORE: anon inserisce';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback to savepoint s_taxa;

-- FINE SEZIONI

\i scripts/tassonomia/rollback_fase1.sql

do $$
begin
  assert to_regclass('public.taxa') is null, 'rollback: taxa esiste ancora';
  assert (select specie from _prima) = (select count(*) from public.specie), 'specie è cambiata';
  assert (select piante from _prima) = (select count(*) from public.piante), 'piante è cambiata';
  assert (select generi from _prima) = (select count(*) from public.generi), 'generi è cambiata';
end $$;

select 'PROVA PRINCIPALE OK' as esito;
rollback;
```

- [ ] **Step 3: Eseguire la prova e verificare che fallisca**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: errore di psql `supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql: No such file or directory` e uscita diversa da 0.

- [ ] **Step 4: Scrivere la migration con la tabella `taxa`**

`supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql`:

```sql
-- Modello tassonomico, fase 1: tabelle nuove e vuote (spec docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md).
-- Non tocca specie né generi; aggiunge a piante due colonne facoltative (taxon_id, cultivar_id).
-- Permessi scritti in modo esplicito: lettura pubblica senza le colonne interne (la fonte non si mostra mai),
-- nessuna scrittura per anon e authenticated, mappa_specie non leggibile dai client.
-- Si applica con: psql -1 -v ON_ERROR_STOP=1 -f <questo file>. Rollback: psql -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql
-- Prove: bash scripts/tassonomia/prova_fase1.sh

-- ===== taxa: nomi scientifici e gerarchia da Catalogue of Life (origine col) più i taxon locali =====
create table public.taxa (
  id uuid primary key default gen_random_uuid(),
  origine text not null default 'col' check (origine in ('col', 'locale')),
  col_id text unique,
  versione_col text,
  -- vocabolario dei ranghi di ChecklistBank (api.checklistbank.org/vocab/rank), senza cultivar, cultivar group e grex (stanno in cultivar)
  rango text not null check (rango in ('superdomain', 'domain', 'subdomain', 'infradomain', 'empire', 'realm', 'subrealm',
    'superkingdom', 'kingdom', 'subkingdom', 'infrakingdom', 'superphylum', 'phylum', 'subphylum', 'infraphylum', 'parvphylum',
    'microphylum', 'nanophylum', 'claudius', 'gigaclass', 'megaclass', 'superclass', 'class', 'subclass', 'infraclass',
    'subterclass', 'parvclass', 'superdivision', 'division zoology', 'subdivision', 'infradivision', 'superlegion', 'legion',
    'sublegion', 'infralegion', 'megacohort', 'supercohort', 'cohort', 'subcohort', 'infracohort', 'gigaorder', 'magnorder',
    'grandorder', 'mirorder', 'superorder', 'order', 'nanorder', 'hypoorder', 'minorder', 'suborder', 'infraorder', 'parvorder',
    'supersection zoology', 'section zoology', 'subsection zoology', 'superseries zoology', 'series zoology',
    'subseries zoology', 'falanx', 'gigafamily', 'megafamily', 'grandfamily', 'superfamily', 'epifamily', 'family',
    'subfamily', 'infrafamily', 'supertribe', 'tribe', 'subtribe', 'infratribe', 'suprageneric name', 'supergenus', 'genus',
    'subgenus', 'infragenus', 'division botany', 'supersection botany', 'section botany', 'subsection botany',
    'superseries botany', 'series botany', 'subseries botany', 'infrageneric name', 'species aggregate', 'species',
    'infraspecific name', 'klepton', 'subspecies', 'convariety', 'infrasubspecific name', 'proles', 'natio', 'aberration',
    'morph', 'supervariety', 'variety', 'subvariety', 'superform', 'form', 'subform', 'pathovar', 'biovar', 'chemovar',
    'morphovar', 'phagovar', 'serovar', 'chemoform', 'forma specialis', 'lusus', 'mutatio', 'strain', 'other', 'unranked')),
  nome_scientifico text not null check (btrim(nome_scientifico) <> ''),
  autore text,
  notho text check (notho in ('generic', 'infrageneric', 'specific', 'infraspecific')),
  -- ibrido: parte ibrida dichiarata da COL (notho), oppure segno × o x semplice isolata nel nome (ICN ammette entrambi)
  ibrido boolean generated always as (notho is not null or nome_scientifico like '%×%' or nome_scientifico ~ '(^|\s)x\s') stored,
  stato text not null check (stato in ('accepted', 'provisionally accepted', 'synonym', 'ambiguous synonym', 'misapplied', 'bare name')),
  accettato_id uuid,
  padre_id uuid,
  nota text,
  importato_il timestamptz not null default now(),
  constraint taxa_col_ha_id check ((origine = 'col') = (col_id is not null)),
  constraint taxa_col_ha_versione check ((origine = 'col') = (versione_col is not null)),
  constraint taxa_accettato_solo_sinonimi check (accettato_id is null or stato in ('synonym', 'ambiguous synonym', 'misapplied')),
  constraint taxa_non_se_stesso check (accettato_id <> id and padre_id <> id),
  constraint taxa_accettato_fk foreign key (accettato_id) references public.taxa (id) on delete restrict deferrable initially deferred,
  constraint taxa_padre_fk foreign key (padre_id) references public.taxa (id) on delete restrict deferrable initially deferred
);
create index taxa_padre_id_idx on public.taxa (padre_id);
create index taxa_accettato_id_idx on public.taxa (accettato_id);
create index taxa_nome_scientifico_trgm_idx on public.taxa using gin (nome_scientifico extensions.gin_trgm_ops);

alter table public.taxa enable row level security;
create policy "taxa: lettura pubblica" on public.taxa for select using (true);
revoke all on public.taxa from anon, authenticated, service_role;
grant select, insert, update, delete on public.taxa to service_role;
grant select (id, rango, nome_scientifico, autore, notho, ibrido, stato, accettato_id, padre_id) on public.taxa to anon, authenticated;
```

- [ ] **Step 5: Scrivere il rollback**

`scripts/tassonomia/rollback_fase1.sql`:

```sql
-- Rollback della fase 1 del modello tassonomico: rimuove le tabelle nuove e le colonne aggiunte a piante.
-- Si rifiuta se le tabelle nuove contengono dati: dalla fase 2 in poi va prima eseguito il rollback della fase corrispondente.
-- Controllo e cancellazione sono un'unica istruzione: se il controllo o una cancellazione falliscono non cambia nulla,
-- anche se il file viene lanciato senza -1 o senza ON_ERROR_STOP.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql
do $$
begin
  lock table public.taxa in access exclusive mode;
  if exists (select 1 from public.taxa) then
    raise exception 'Rollback fase 1 rifiutato: le tabelle nuove contengono dati';
  end if;

  drop table public.taxa;
end $$;
```

- [ ] **Step 6: Eseguire la prova e verificare che passi**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: ultime righe `PROVA PRINCIPALE OK` e `PROVE FASE 1 OK`, uscita 0.

- [ ] **Step 7: Verificare che il database non sia cambiato**

Run: `psql "$(grep '^DATABASE_URL=' .env.local | cut -d= -f2- | tr -d '"')" -At -c "select to_regclass('public.taxa')"`
Expected: riga vuota (la tabella non esiste: la prova è stata annullata).

- [ ] **Step 8: Commit**

```bash
git add scripts/tassonomia/prova_fase1.sh scripts/tassonomia/prova_fase1.sql scripts/tassonomia/rollback_fase1.sql supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
git commit -m "Tassonomia fase 1: tabella taxa (non applicata), rollback e prova in transazione annullata"
```

---

### Task 2: Tabelle `nomi_comuni` e `cultivar`

**Files:**
- Modify: `scripts/tassonomia/prova_fase1.sql` (nuova sezione prima di `-- FINE SEZIONI`, nuova asserzione dopo il rollback)
- Modify: `supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql` (in fondo)
- Modify: `scripts/tassonomia/rollback_fase1.sql`

**Interfaces:**
- Consumes: `public.taxa(id)`.
- Produces: `public.nomi_comuni`, `public.cultivar` (con `cultivar.id` uuid, usato da `schede` e `piante`).

- [ ] **Step 1: Aggiungere la sezione di prova**

In `scripts/tassonomia/prova_fase1.sql`, subito prima della riga `-- FINE SEZIONI`, inserire:

```sql
-- ===== Sezione nomi_comuni e cultivar =====
savepoint s_nomi_cultivar;
do $$
declare t uuid; t2 uuid;
begin
  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'species', 'Hedera helix', 'accepted') returning id into t;
  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'genus', 'Hedera', 'accepted') returning id into t2;

  insert into public.nomi_comuni (taxon_id, lingua, nome, preferito, fonti) values (t, 'it', 'Edera comune', true, array['iNaturalist']);
  insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) values (t, 'it', 'Ellera', array['PlantNet', 'Wikidata']);
  insert into public.nomi_comuni (taxon_id, lingua, nome, preferito, fonti) values (t2, 'it', 'Edera', true, array['curatore']);
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, preferito, fonti) values (t, 'it', 'Abbracciabosco', true, array['PlantNet']);
    raise exception 'ATTESO ERRORE: due preferiti per lo stesso taxon e lingua';
  exception when unique_violation then null; end;
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) values (t, 'it', 'Ellera', array['EPPO']);
    raise exception 'ATTESO ERRORE: nome ripetuto per lo stesso taxon e lingua';
  exception when unique_violation then null; end;
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) values (t, 'ita', 'Edera', array['COL']);
    raise exception 'ATTESO ERRORE: lingua a tre lettere';
  exception when check_violation then null; end;
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, fonti) values (t, 'it', 'Senza fonte', '{}');
    raise exception 'ATTESO ERRORE: nome senza fonti';
  exception when check_violation then null; end;

  insert into public.cultivar (slug, taxon_id, epiteto, fonti) values ('prova-hedera-helix-goldchild', t, 'Goldchild', array['RHS (rhs.org.uk)']);
  insert into public.cultivar (slug, taxon_id, epiteto, categoria, fonti) values ('prova-hedera-gruppo', t2, 'Prova', 'gruppo', array['RHS (rhs.org.uk)']);
  begin
    insert into public.cultivar (slug, taxon_id, epiteto, fonti) values ('prova-apici', t, '''Goldchild''', array['RHS (rhs.org.uk)']);
    raise exception 'ATTESO ERRORE: epiteto con apici';
  exception when check_violation then null; end;
  begin
    insert into public.cultivar (slug, taxon_id, epiteto, fonti) values ('prova-hedera-helix-goldchild', t, 'Altro', array['RHS (rhs.org.uk)']);
    raise exception 'ATTESO ERRORE: slug duplicato';
  exception when unique_violation then null; end;
  begin
    insert into public.cultivar (slug, taxon_id, epiteto, categoria, fonti) values ('prova-cat', t, 'X', 'varietà', array['RHS (rhs.org.uk)']);
    raise exception 'ATTESO ERRORE: categoria fuori elenco';
  exception when check_violation then null; end;
  begin
    delete from public.taxa where id = t;
    raise exception 'ATTESO ERRORE: cancellato un taxon con nomi e cultivar';
  exception when foreign_key_violation then null; end;

  assert has_column_privilege('anon', 'public.nomi_comuni', 'nome', 'SELECT'), 'anon non legge nomi_comuni.nome';
  assert not has_column_privilege('anon', 'public.nomi_comuni', 'fonti', 'SELECT'), 'anon legge nomi_comuni.fonti';
  assert not has_column_privilege('anon', 'public.nomi_comuni', 'nota', 'SELECT'), 'anon legge nomi_comuni.nota';
  assert has_column_privilege('anon', 'public.cultivar', 'epiteto', 'SELECT'), 'anon non legge cultivar.epiteto';
  assert not has_column_privilege('anon', 'public.cultivar', 'fonti', 'SELECT'), 'anon legge cultivar.fonti';
  assert not has_column_privilege('anon', 'public.cultivar', 'vecchia_specie_id', 'SELECT'), 'anon legge cultivar.vecchia_specie_id';
  assert not has_table_privilege('authenticated', 'public.nomi_comuni', 'INSERT'), 'authenticated scrive nomi_comuni';
  assert not has_table_privilege('authenticated', 'public.cultivar', 'INSERT'), 'authenticated scrive cultivar';
  assert (select relrowsecurity from pg_class where oid = 'public.nomi_comuni'::regclass), 'nomi_comuni: RLS non attiva';
  assert (select relrowsecurity from pg_class where oid = 'public.cultivar'::regclass), 'cultivar: RLS non attiva';
end $$;

set local role anon;
do $$
begin
  assert (select count(*) from (select nome, preferito from public.nomi_comuni) n) = 3, 'anon non vede i nomi comuni';
  assert (select count(*) from (select epiteto from public.cultivar) c) = 2, 'anon non vede le cultivar';
  begin
    perform fonti from public.nomi_comuni limit 1;
    raise exception 'ATTESO ERRORE: anon legge le fonti dei nomi';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback to savepoint s_nomi_cultivar;
```

Nel blocco finale di asserzioni dopo `\i scripts/tassonomia/rollback_fase1.sql`, aggiungere:

```sql
do $$
begin
  assert to_regclass('public.nomi_comuni') is null, 'rollback: nomi_comuni esiste ancora';
  assert to_regclass('public.cultivar') is null, 'rollback: cultivar esiste ancora';
end $$;
```

- [ ] **Step 2: Eseguire la prova e verificare che fallisca**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: errore `relation "public.nomi_comuni" does not exist`, uscita diversa da 0.

- [ ] **Step 3: Aggiungere le tabelle alla migration**

In fondo a `supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql`:

```sql

-- ===== nomi_comuni: un nome per riga, con le fonti (interne) =====
create table public.nomi_comuni (
  id uuid primary key default gen_random_uuid(),
  taxon_id uuid not null references public.taxa (id) on delete restrict,
  lingua text not null check (lingua ~ '^[a-z]{2}$'),
  nome text not null check (btrim(nome) <> ''),
  preferito boolean not null default false,
  fonti text[] not null check (cardinality(fonti) > 0),
  nota text,
  creato_il timestamptz not null default now(),
  constraint nomi_comuni_unico unique (taxon_id, lingua, nome)
);
create unique index nomi_comuni_preferito_idx on public.nomi_comuni (taxon_id, lingua) where preferito;
create index nomi_comuni_nome_trgm_idx on public.nomi_comuni using gin (nome extensions.gin_trgm_ops);

alter table public.nomi_comuni enable row level security;
create policy "nomi_comuni: lettura pubblica" on public.nomi_comuni for select using (true);
revoke all on public.nomi_comuni from anon, authenticated, service_role;
grant select, insert, update, delete on public.nomi_comuni to service_role;
grant select (id, taxon_id, lingua, nome, preferito) on public.nomi_comuni to anon, authenticated;

-- ===== cultivar: dati nostri (RHS), assegnate al taxon più basso noto (ICNCP) =====
create table public.cultivar (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  taxon_id uuid not null references public.taxa (id) on delete restrict,
  categoria text not null default 'cultivar' check (categoria in ('cultivar', 'gruppo', 'grex')),
  epiteto text not null check (btrim(epiteto) <> '' and left(epiteto, 1) <> '''' and right(epiteto, 1) <> ''''),
  gruppo text,
  nome_commerciale text,
  fonti text[] not null check (cardinality(fonti) > 0),
  vecchia_specie_id uuid unique,
  creata_il timestamptz not null default now()
);
create index cultivar_taxon_id_idx on public.cultivar (taxon_id);
create index cultivar_epiteto_trgm_idx on public.cultivar using gin (epiteto extensions.gin_trgm_ops);
create index cultivar_nome_commerciale_trgm_idx on public.cultivar using gin (nome_commerciale extensions.gin_trgm_ops);

alter table public.cultivar enable row level security;
create policy "cultivar: lettura pubblica" on public.cultivar for select using (true);
revoke all on public.cultivar from anon, authenticated, service_role;
grant select, insert, update, delete on public.cultivar to service_role;
grant select (id, slug, taxon_id, categoria, epiteto, gruppo, nome_commerciale) on public.cultivar to anon, authenticated;
```

- [ ] **Step 4: Aggiornare il rollback**

Sostituire l'intero contenuto di `scripts/tassonomia/rollback_fase1.sql` con:

```sql
-- Rollback della fase 1 del modello tassonomico: rimuove le tabelle nuove e le colonne aggiunte a piante.
-- Si rifiuta se le tabelle nuove contengono dati: dalla fase 2 in poi va prima eseguito il rollback della fase corrispondente.
-- Controllo e cancellazione sono un'unica istruzione: se il controllo o una cancellazione falliscono non cambia nulla,
-- anche se il file viene lanciato senza -1 o senza ON_ERROR_STOP.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql
do $$
begin
  lock table public.cultivar, public.nomi_comuni, public.taxa in access exclusive mode;
  if exists (select 1 from public.taxa) or exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar) then
    raise exception 'Rollback fase 1 rifiutato: le tabelle nuove contengono dati';
  end if;

  drop table public.cultivar, public.nomi_comuni, public.taxa;
end $$;
```

- [ ] **Step 5: Eseguire la prova e verificare che passi**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: `PROVA PRINCIPALE OK`, `PROVE FASE 1 OK`, uscita 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/tassonomia/prova_fase1.sql scripts/tassonomia/rollback_fase1.sql supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
git commit -m "Tassonomia fase 1: tabelle nomi_comuni e cultivar (non applicate), con prove"
```

---

### Task 3: Tabelle `schede` e `mappa_specie`

**Files:**
- Modify: `scripts/tassonomia/prova_fase1.sql`
- Modify: `supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql`
- Modify: `scripts/tassonomia/rollback_fase1.sql`

**Interfaces:**
- Consumes: `public.taxa(id)`, `public.cultivar(id)`.
- Produces: `public.schede` (trigger `schede_set_aggiornata_il`), `public.mappa_specie` (chiave `vecchia_specie_id` uuid senza FK).

- [ ] **Step 1: Aggiungere la sezione di prova**

Prima di `-- FINE SEZIONI`:

```sql
-- ===== Sezione schede e mappa_specie =====
savepoint s_schede_mappa;
do $$
declare t uuid; c uuid; sc uuid; prima timestamptz;
begin
  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'species', 'Hedera helix', 'accepted') returning id into t;
  insert into public.cultivar (slug, taxon_id, epiteto, fonti) values ('prova-goldchild', t, 'Goldchild', array['RHS (rhs.org.uk)']) returning id into c;

  insert into public.schede (taxon_id, fonti, descrizione, stato_verifica, mostrata, vecchia_specie_id, aggiornata_il)
    values (t, array['RHS (rhs.org.uk) — Hedera helix', 'Il giardino di arbusti (Edicart, 1995)'], 'Rampicante sempreverde.', 'verificato', true, gen_random_uuid(), '2000-01-01')
    returning id, aggiornata_il into sc, prima;
  insert into public.schede (taxon_id, fonti, descrizione) values (t, array['Plants For A Future (pfaf.org)'], 'Seconda scheda, non mostrata.');
  insert into public.schede (cultivar_id, fonti, descrizione, mostrata) values (c, array['RHS (rhs.org.uk)'], 'Foglie screziate.', true);

  begin
    insert into public.schede (taxon_id, fonti, mostrata) values (t, array['PFAF'], true);
    raise exception 'ATTESO ERRORE: due schede mostrate per lo stesso taxon';
  exception when unique_violation then null; end;
  begin
    insert into public.schede (taxon_id, cultivar_id, fonti) values (t, c, array['RHS']);
    raise exception 'ATTESO ERRORE: scheda su taxon e cultivar insieme';
  exception when check_violation then null; end;
  begin
    insert into public.schede (fonti) values (array['RHS']);
    raise exception 'ATTESO ERRORE: scheda senza taxon né cultivar';
  exception when check_violation then null; end;
  begin
    insert into public.schede (taxon_id, fonti, stato_verifica) values (t, array['RHS'], 'approvata');
    raise exception 'ATTESO ERRORE: stato_verifica fuori elenco';
  exception when check_violation then null; end;

  update public.schede set descrizione = 'Rampicante sempreverde, rustico.' where id = sc;
  assert (select aggiornata_il from public.schede where id = sc) > prima, 'aggiornata_il non gestita dal trigger';
  assert exists (select 1 from pg_trigger where tgname = 'schede_set_aggiornata_il' and tgrelid = 'public.schede'::regclass),
    'manca il trigger schede_set_aggiornata_il';

  -- mappa_specie: righe ancora da elaborare, abbinate, e cancellate (senza FK verso specie)
  insert into public.mappa_specie (vecchia_specie_id, vecchio_slug, vecchio_nome_scientifico) values (gen_random_uuid(), 'prova-da-elaborare', 'Hedera helix');
  insert into public.mappa_specie (vecchia_specie_id, vecchio_slug, vecchio_nome_scientifico, taxon_id, esito)
    values (gen_random_uuid(), 'prova-abbinata', 'Hedera helix', t, 'esatto');
  insert into public.mappa_specie (vecchia_specie_id, vecchio_slug, vecchio_nome_scientifico, origine, esito)
    values (gen_random_uuid(), 'prova-cancellata', 'Daucus carota', 'rollback', 'non trovato');
  begin
    insert into public.mappa_specie (vecchia_specie_id, vecchio_slug, vecchio_nome_scientifico, taxon_id, cultivar_id, esito)
      values (gen_random_uuid(), 'prova-doppia', 'X', t, c, 'esatto');
    raise exception 'ATTESO ERRORE: mappa con taxon e cultivar insieme';
  exception when check_violation then null; end;
  begin
    insert into public.mappa_specie (vecchia_specie_id, vecchio_slug, vecchio_nome_scientifico, taxon_id)
      values (gen_random_uuid(), 'prova-senza-esito', 'X', t);
    raise exception 'ATTESO ERRORE: abbinamento senza esito';
  exception when check_violation then null; end;
  begin
    insert into public.mappa_specie (vecchia_specie_id, vecchio_slug, vecchio_nome_scientifico, esito)
      values (gen_random_uuid(), 'prova-esito', 'X', 'forse');
    raise exception 'ATTESO ERRORE: esito fuori elenco';
  exception when check_violation then null; end;
  begin
    insert into public.mappa_specie (vecchia_specie_id, vecchio_slug, vecchio_nome_scientifico) values (gen_random_uuid(), 'prova-abbinata', 'X');
    raise exception 'ATTESO ERRORE: vecchio_slug duplicato';
  exception when unique_violation then null; end;

  -- permessi
  assert has_column_privilege('anon', 'public.schede', 'descrizione', 'SELECT'), 'anon non legge schede.descrizione';
  assert has_column_privilege('anon', 'public.schede', 'stato_verifica', 'SELECT'), 'anon non legge schede.stato_verifica';
  assert not has_column_privilege('anon', 'public.schede', 'fonti', 'SELECT'), 'anon legge schede.fonti';
  assert not has_column_privilege('anon', 'public.schede', 'descrizione_originale', 'SELECT'), 'anon legge schede.descrizione_originale';
  assert not has_column_privilege('anon', 'public.schede', 'verificata_da', 'SELECT'), 'anon legge schede.verificata_da';
  assert not has_column_privilege('anon', 'public.schede', 'vecchia_specie_id', 'SELECT'), 'anon legge schede.vecchia_specie_id';
  assert not has_table_privilege('authenticated', 'public.schede', 'INSERT'), 'authenticated scrive schede';
  assert not has_table_privilege('anon', 'public.mappa_specie', 'SELECT'), 'anon legge mappa_specie';
  assert not has_table_privilege('authenticated', 'public.mappa_specie', 'SELECT'), 'authenticated legge mappa_specie';
  assert not exists (select 1 from pg_policies where tablename = 'mappa_specie'), 'mappa_specie ha una policy';
  assert (select relrowsecurity from pg_class where oid = 'public.schede'::regclass), 'schede: RLS non attiva';
  assert (select relrowsecurity from pg_class where oid = 'public.mappa_specie'::regclass), 'mappa_specie: RLS non attiva';
end $$;

set local role anon;
do $$
begin
  assert (select count(*) from (select descrizione, mostrata from public.schede) s) = 3, 'anon non vede le schede';
  -- Review Focus 2: select * con la chiave pubblica non deve restituire le fonti
  begin
    perform * from public.schede limit 1;
    raise exception 'ATTESO ERRORE: anon esegue select * su schede';
  exception when insufficient_privilege then null; end;
  begin
    perform 1 from public.mappa_specie limit 1;
    raise exception 'ATTESO ERRORE: anon legge mappa_specie';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback to savepoint s_schede_mappa;
```

Nel blocco dopo il rollback aggiungere:

```sql
do $$
begin
  assert to_regclass('public.schede') is null, 'rollback: schede esiste ancora';
  assert to_regclass('public.mappa_specie') is null, 'rollback: mappa_specie esiste ancora';
end $$;
```

- [ ] **Step 2: Eseguire la prova e verificare che fallisca**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: errore `relation "public.schede" does not exist`, uscita diversa da 0.

- [ ] **Step 3: Aggiungere le tabelle alla migration**

In fondo alla migration:

```sql

-- ===== schede: il contenuto, una per fonte di origine, legata a un taxon o a una cultivar =====
create table public.schede (
  id uuid primary key default gen_random_uuid(),
  taxon_id uuid references public.taxa (id) on delete restrict,
  cultivar_id uuid references public.cultivar (id) on delete restrict,
  fonti text[] not null check (cardinality(fonti) > 0),
  descrizione text,
  descrizione_originale text,
  lingua_descrizione text check (lingua_descrizione in ('it', 'en', 'mixed', 'stub', 'nd')),
  esigenze jsonb,
  manutenzione jsonb,
  ciclo_colturale jsonb,
  ciclo_vitale text check (ciclo_vitale in ('annuale', 'biennale', 'perenne')),
  vaso jsonb,
  alert text[],
  immagine jsonb,
  stato_verifica text not null default 'bozza' check (stato_verifica in ('bozza', 'verificato')),
  verificata_il timestamptz,
  verificata_da text,
  mostrata boolean not null default false,
  vecchia_specie_id uuid unique,
  creata_il timestamptz not null default now(),
  aggiornata_il timestamptz not null default now(),
  constraint schede_taxon_o_cultivar check (num_nonnulls(taxon_id, cultivar_id) = 1)
);
create index schede_taxon_id_idx on public.schede (taxon_id);
create index schede_cultivar_id_idx on public.schede (cultivar_id);
create unique index schede_mostrata_taxon_idx on public.schede (taxon_id) where mostrata and taxon_id is not null;
create unique index schede_mostrata_cultivar_idx on public.schede (cultivar_id) where mostrata and cultivar_id is not null;
create trigger schede_set_aggiornata_il before update on public.schede
  for each row execute procedure extensions.moddatetime(aggiornata_il);

alter table public.schede enable row level security;
create policy "schede: lettura pubblica" on public.schede for select using (true);
revoke all on public.schede from anon, authenticated, service_role;
grant select, insert, update, delete on public.schede to service_role;
grant select (id, taxon_id, cultivar_id, descrizione, lingua_descrizione, esigenze, manutenzione, ciclo_colturale,
  ciclo_vitale, vaso, alert, immagine, stato_verifica, verificata_il, mostrata) on public.schede to anon, authenticated;

-- ===== mappa_specie: da ogni riga della vecchia specie (anche cancellata) al nuovo modello. Solo uso interno. =====
create table public.mappa_specie (
  vecchia_specie_id uuid primary key,
  vecchio_slug text not null unique,
  vecchio_nome_scientifico text not null,
  origine text not null default 'specie' check (origine in ('specie', 'rollback')),
  taxon_id uuid references public.taxa (id) on delete restrict,
  cultivar_id uuid references public.cultivar (id) on delete restrict,
  esito text check (esito in ('esatto', 'variante', 'sinonimo', 'rango superiore', 'ambiguo', 'ibrido', 'non trovato', 'deciso dall''utente')),
  nota text,
  creata_il timestamptz not null default now(),
  aggiornata_il timestamptz not null default now(),
  constraint mappa_specie_al_piu_uno check (num_nonnulls(taxon_id, cultivar_id) <= 1),
  constraint mappa_specie_abbinata_ha_esito check (num_nonnulls(taxon_id, cultivar_id) = 0 or esito is not null)
);
create index mappa_specie_taxon_id_idx on public.mappa_specie (taxon_id);
create index mappa_specie_cultivar_id_idx on public.mappa_specie (cultivar_id);
create trigger mappa_specie_set_aggiornata_il before update on public.mappa_specie
  for each row execute procedure extensions.moddatetime(aggiornata_il);

alter table public.mappa_specie enable row level security;
revoke all on public.mappa_specie from anon, authenticated, service_role;
grant select, insert, update, delete on public.mappa_specie to service_role;
```

- [ ] **Step 4: Aggiornare il rollback**

Sostituire l'intero contenuto di `scripts/tassonomia/rollback_fase1.sql` con:

```sql
-- Rollback della fase 1 del modello tassonomico: rimuove le tabelle nuove e le colonne aggiunte a piante.
-- Si rifiuta se le tabelle nuove contengono dati: dalla fase 2 in poi va prima eseguito il rollback della fase corrispondente.
-- Controllo e cancellazione sono un'unica istruzione: se il controllo o una cancellazione falliscono non cambia nulla,
-- anche se il file viene lanciato senza -1 o senza ON_ERROR_STOP.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql
do $$
begin
  lock table public.mappa_specie, public.schede, public.cultivar, public.nomi_comuni, public.taxa in access exclusive mode;
  if exists (select 1 from public.taxa) or exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar)
     or exists (select 1 from public.schede) or exists (select 1 from public.mappa_specie) then
    raise exception 'Rollback fase 1 rifiutato: le tabelle nuove contengono dati';
  end if;

  drop table public.mappa_specie, public.schede, public.cultivar, public.nomi_comuni, public.taxa;
end $$;
```

- [ ] **Step 5: Eseguire la prova e verificare che passi**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: `PROVA PRINCIPALE OK`, `PROVE FASE 1 OK`, uscita 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/tassonomia/prova_fase1.sql scripts/tassonomia/rollback_fase1.sql supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
git commit -m "Tassonomia fase 1: tabelle schede e mappa_specie (non applicate), con prove"
```

---

### Task 4: Colonne su `piante` e non-regressione dell'app

**Files:**
- Modify: `scripts/tassonomia/prova_fase1.sql`
- Modify: `supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql`
- Modify: `scripts/tassonomia/rollback_fase1.sql`

**Interfaces:**
- Consumes: `public.taxa(id)`, `public.cultivar(id)`, variabile psql `:proprietario` (definita nel Task 1).
- Produces: `public.piante.taxon_id`, `public.piante.cultivar_id` (uuid, facoltative), vincolo `piante_taxon_o_cultivar`.

- [ ] **Step 1: Aggiungere la sezione di prova**

Prima di `-- FINE SEZIONI`:

```sql
-- ===== Sezione piante =====
savepoint s_piante;
do $$
declare t uuid; c uuid; p text;
begin
  assert (select is_nullable from information_schema.columns where table_schema = 'public' and table_name = 'piante' and column_name = 'taxon_id') = 'YES',
    'piante.taxon_id manca o è obbligatoria';
  assert (select is_nullable from information_schema.columns where table_schema = 'public' and table_name = 'piante' and column_name = 'cultivar_id') = 'YES',
    'piante.cultivar_id manca o è obbligatoria';
  assert not exists (select 1 from public.piante where taxon_id is not null or cultivar_id is not null), 'piante con colonne nuove già valorizzate';

  insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'species', 'Hedera helix', 'accepted') returning id into t;
  insert into public.cultivar (slug, taxon_id, epiteto, fonti) values ('prova-goldchild', t, 'Goldchild', array['RHS (rhs.org.uk)']) returning id into c;
  select id into p from public.piante order by id limit 1;

  update public.piante set taxon_id = t where id = p;
  begin
    update public.piante set cultivar_id = c where id = p;
    raise exception 'ATTESO ERRORE: pianta con taxon e cultivar insieme';
  exception when check_violation then null; end;
  begin
    update public.piante set taxon_id = gen_random_uuid() where id = p;
    raise exception 'ATTESO ERRORE: taxon inesistente';
  exception when foreign_key_violation then null; end;
  begin
    delete from public.taxa where id = t;
    raise exception 'ATTESO ERRORE: cancellato un taxon usato da una pianta';
  exception when foreign_key_violation then null; end;
end $$;
rollback to savepoint s_piante;

-- l'app, come utente proprietario, deve continuare a leggere, creare piante e registrare cure
savepoint s_app;
select set_config('request.jwt.claims', json_build_object('sub', :'proprietario', 'role', 'authenticated')::text, true);
set local role authenticated;
do $$
declare z uuid; r record;
begin
  assert (select count(*) from public.piante) = current_setting('prova.piante_proprietario')::bigint, 'il proprietario non vede tutte le sue piante';
  assert (select count(*) from public.piante where taxon_id is null and cultivar_id is null) = current_setting('prova.piante_proprietario')::bigint,
    'il proprietario non legge le colonne nuove';

  -- Review Focus 1: insert come salvaPianta (colonne esplicite, senza quelle nuove)
  select zona_id into z from public.piante limit 1;
  insert into public.piante (id, specie, zona_id, sottozona_id, varieta, impianto, impianto_circa, note, coltivato_in, ultima_cura)
    values ('prova-fase1-1790000000000', 'hedera-helix', z, null, null, null, null, null, 'terra', '{}');

  -- registra_cura_pianta restituisce il tipo riga di piante, che ora ha due colonne in più
  select * into r from public.registra_cura_pianta('prova-fase1-1790000000000', 'irrigazione', current_date);
  assert r.id = 'prova-fase1-1790000000000', 'registra_cura_pianta non funziona dopo l''aggiunta delle colonne';
  assert r.ultima_cura ? 'irrigazione', 'registra_cura_pianta non ha registrato la cura';
  assert (select (public.registra_cura_pianta('id-inesistente', 'irrigazione', current_date)).id) is null,
    'registra_cura_pianta su id inesistente non restituisce null';
end $$;
reset role;
rollback to savepoint s_app;
```

Nel blocco dopo il rollback aggiungere:

```sql
do $$
begin
  assert not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'piante'
    and column_name in ('taxon_id', 'cultivar_id')), 'rollback: piante ha ancora le colonne nuove';
  assert (select (public.registra_cura_pianta('id-inesistente', 'irrigazione', current_date)).id) is null,
    'registra_cura_pianta non funziona dopo il rollback';
end $$;
```

- [ ] **Step 2: Eseguire la prova e verificare che fallisca**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: errore di asserzione `piante.taxon_id manca o è obbligatoria`, uscita diversa da 0.

- [ ] **Step 3: Aggiungere le colonne alla migration**

In fondo alla migration:

```sql

-- ===== piante: collegamento al nuovo modello, facoltativo fino alla fase 6 (l'app attuale non lo compila) =====
alter table public.piante
  add column taxon_id uuid references public.taxa (id) on delete restrict,
  add column cultivar_id uuid references public.cultivar (id) on delete restrict,
  add constraint piante_taxon_o_cultivar check (num_nonnulls(taxon_id, cultivar_id) <= 1);
create index piante_taxon_id_idx on public.piante (taxon_id);
create index piante_cultivar_id_idx on public.piante (cultivar_id);
```

- [ ] **Step 4: Aggiornare il rollback**

Sostituire l'intero contenuto di `scripts/tassonomia/rollback_fase1.sql` con:

```sql
-- Rollback della fase 1 del modello tassonomico: rimuove le tabelle nuove e le colonne aggiunte a piante.
-- Si rifiuta se le tabelle nuove contengono dati: dalla fase 2 in poi va prima eseguito il rollback della fase corrispondente.
-- Controllo e cancellazione sono un'unica istruzione: se il controllo o una cancellazione falliscono non cambia nulla,
-- anche se il file viene lanciato senza -1 o senza ON_ERROR_STOP.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql
do $$
begin
  lock table public.piante, public.mappa_specie, public.schede, public.cultivar, public.nomi_comuni, public.taxa in access exclusive mode;
  if exists (select 1 from public.taxa) or exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar)
     or exists (select 1 from public.schede) or exists (select 1 from public.mappa_specie)
     or exists (select 1 from public.piante where taxon_id is not null or cultivar_id is not null) then
    raise exception 'Rollback fase 1 rifiutato: le tabelle nuove contengono dati';
  end if;

  alter table public.piante
    drop constraint piante_taxon_o_cultivar,
    drop column cultivar_id,
    drop column taxon_id;
  drop table public.mappa_specie, public.schede, public.cultivar, public.nomi_comuni, public.taxa;
end $$;
```

- [ ] **Step 5: Eseguire la prova e verificare che passi**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: `PROVA PRINCIPALE OK`, `PROVE FASE 1 OK`, uscita 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/tassonomia/prova_fase1.sql scripts/tassonomia/rollback_fase1.sql supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
git commit -m "Tassonomia fase 1: colonne taxon_id e cultivar_id su piante (non applicate), con prove di non-regressione"
```

---

### Task 5: Prove negative (rollback con dati, migration ripetuta)

**Files:**
- Create: `scripts/tassonomia/prova_fase1_guardia.sql`
- Create: `scripts/tassonomia/prova_fase1_doppia.sql`

**Interfaces:**
- Consumes: migration e rollback completi (Task 1–4); `prova_fase1.sh` legge la prima riga `-- ATTESO: <testo>` di ogni prova negativa e controlla che l'errore lo contenga.

- [ ] **Step 1: Scrivere la prova della guardia del rollback**

`scripts/tassonomia/prova_fase1_guardia.sql`:

```sql
-- ATTESO: Rollback fase 1 rifiutato: le tabelle nuove contengono dati
-- Review Focus 4: con dati nelle tabelle nuove il rollback deve fermarsi. La transazione non viene mai confermata:
-- l'errore chiude psql (ON_ERROR_STOP) e la connessione annulla tutto.
begin;
\i supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
insert into public.taxa (origine, rango, nome_scientifico, stato) values ('locale', 'genus', 'Prova guardia', 'accepted');
-- come in autocommit: i controlli differiti delle FK vengono eseguiti subito, così il rollback non fallisce per altri motivi
set constraints all immediate;
\i scripts/tassonomia/rollback_fase1.sql
select 'NON DOVEVA ARRIVARE QUI';
rollback;
```

- [ ] **Step 2: Scrivere la prova della migration ripetuta**

`scripts/tassonomia/prova_fase1_doppia.sql`:

```sql
-- ATTESO: relation "taxa" already exists
-- Review Focus 5: una seconda applicazione deve fallire subito, senza lasciare nulla a metà
-- (in produzione psql -1 annulla l'intera migration). Transazione mai confermata.
begin;
\i supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
\i supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
select 'NON DOVEVA ARRIVARE QUI';
rollback;
```

- [ ] **Step 3: Eseguire tutte le prove**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected:

```
PROVA PRINCIPALE OK
PROVA guardia OK
PROVA doppia OK
PROVE FASE 1 OK
```

Se il messaggio di Postgres è in italiano (impostazione `lc_messages` della connessione) e la prova `doppia` fallisce per il testo, sostituire la prima riga di `prova_fase1_doppia.sql` con il testo esatto stampato da psql per l'errore "esiste già" e rilanciare.

- [ ] **Step 4: Verificare che il database non sia cambiato**

Run: `psql "$(grep '^DATABASE_URL=' .env.local | cut -d= -f2- | tr -d '"')" -At -c "select to_regclass('public.taxa'), to_regclass('public.schede'), (select count(*) from information_schema.columns where table_schema='public' and table_name='piante' and column_name in ('taxon_id','cultivar_id'))"`
Expected: `||0`

- [ ] **Step 5: Commit**

```bash
git add scripts/tassonomia/prova_fase1_guardia.sql scripts/tassonomia/prova_fase1_doppia.sql
git commit -m "Tassonomia fase 1: prove negative (rollback con dati, migration ripetuta)"
```

---

### Task 6: Applicazione al database, verifiche e documentazione

**Questo task modifica il database reale.** Prima dello Step 3 serve il via esplicito dell'utente in chat (Step 2), con il riepilogo di cosa verrà creato. Senza via, fermarsi dopo lo Step 2.

Ogni blocco di comandi va eseguito in una sola chiamata della shell: le variabili non passano da un blocco all'altro. La guardia `[[ "$URL" == *ncuhhsvtjwcolhpdxbkt* ]]` impedisce di lanciare un comando con l'URL vuoto (psql si collegherebbe al Postgres locale).

**Files:**
- Create: `scripts/tassonomia/verifica_fase1.sql`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: migration, rollback e prove dei Task 1–5, tutte verdi.
- Produces: tabelle vuote nel database reale; sezione "Modello tassonomico" in `CLAUDE.md` per le fasi successive.

- [ ] **Step 1: Rieseguire tutte le prove e scrivere la verifica post-applicazione**

Run: `bash scripts/tassonomia/prova_fase1.sh`
Expected: `PROVE FASE 1 OK`.

`scripts/tassonomia/verifica_fase1.sql` (sola lettura):

```sql
-- Verifica dopo l'applicazione reale della fase 1. Sola lettura.
begin transaction read only;
do $$
declare t text; vuota boolean;
begin
  foreach t in array array['taxa', 'nomi_comuni', 'cultivar', 'schede', 'mappa_specie'] loop
    assert to_regclass('public.' || t) is not null, 'manca la tabella ' || t;
    assert (select relrowsecurity from pg_class where oid = ('public.' || t)::regclass), 'RLS non attiva su ' || t;
    assert not has_table_privilege('anon', 'public.' || t, 'INSERT'), 'anon può scrivere in ' || t;
    assert not has_table_privilege('authenticated', 'public.' || t, 'INSERT'), 'authenticated può scrivere in ' || t;
    execute format('select not exists (select 1 from public.%I)', t) into strict vuota;
    assert vuota, 'la tabella ' || t || ' non è vuota';
  end loop;
  assert not has_column_privilege('anon', 'public.schede', 'fonti', 'SELECT'), 'anon legge schede.fonti';
  assert not has_table_privilege('anon', 'public.mappa_specie', 'SELECT'), 'anon legge mappa_specie';
  assert not exists (select 1 from public.piante where taxon_id is not null or cultivar_id is not null), 'piante già collegate';
end $$;
-- permessi esatti, colonna per colonna: nessuna colonna interna leggibile, nessuna scrittura dai client
do $$
declare t text; r text; atteso jsonb := jsonb_build_object(
  'taxa', array['accettato_id','autore','ibrido','id','nome_scientifico','notho','padre_id','rango','stato'],
  'nomi_comuni', array['id','lingua','nome','preferito','taxon_id'],
  'cultivar', array['categoria','epiteto','gruppo','id','nome_commerciale','slug','taxon_id'],
  'schede', array['alert','ciclo_colturale','ciclo_vitale','cultivar_id','descrizione','esigenze','id','immagine','lingua_descrizione','manutenzione','mostrata','stato_verifica','taxon_id','vaso','verificata_il'],
  'mappa_specie', array[]::text[]);
begin
  foreach t in array array['taxa','nomi_comuni','cultivar','schede','mappa_specie'] loop
    foreach r in array array['anon','authenticated'] loop
      assert not has_table_privilege(r, 'public.' || t, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'), r || ' ha privilegi di tabella su ' || t;
      assert coalesce((select jsonb_agg(a.attname order by a.attname) from pg_attribute a where a.attrelid = ('public.' || t)::regclass and a.attnum > 0 and not a.attisdropped and has_column_privilege(r, a.attrelid, a.attnum, 'SELECT')), '[]'::jsonb) = atteso -> t, r || ': colonne leggibili di ' || t || ' diverse dal previsto';
      assert not exists (select 1 from pg_attribute a where a.attrelid = ('public.' || t)::regclass and a.attnum > 0 and not a.attisdropped and has_column_privilege(r, a.attrelid, a.attnum, 'INSERT,UPDATE,REFERENCES')), r || ' ha privilegi di scrittura su colonne di ' || t;
    end loop;
  end loop;
  assert has_column_privilege('authenticated', 'public.piante', 'taxon_id', 'SELECT'), 'l''app non legge piante.taxon_id (select=* fallirebbe)';
end $$;
select 'VERIFICA FASE 1 OK' as esito;
rollback;
```

- [ ] **Step 2: Chiedere il via all'utente**

Messaggio da scrivere in chat (in italiano, senza gergo): cosa verrà creato (5 tabelle vuote, 2 colonne vuote su piante), cosa non cambia (specie, generi, l'app), backup previsto, comando di rollback (`psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql`). Attendere un sì esplicito.

- [ ] **Step 3: Backup di `piante` (l'unica tabella esistente che cambia)**

```bash
URL=$(grep '^DATABASE_URL=' .env.local | cut -d= -f2- | tr -d '"')
# pg_dump sulla connessione diretta (porta 5432, come scripts/backup-db.sh): sul pooler 6543 le sue impostazioni di sessione
# (search_path vuoto, row_security off) resterebbero sul backend condiviso per altri client
DUMP_URL=$(grep '^SUPABASE_DB_URL=' .env.local | cut -d= -f2- | tr -d '"')
[[ "$DUMP_URL" == *ncuhhsvtjwcolhpdxbkt*:5432/* ]] && /opt/homebrew/opt/postgresql@17/bin/pg_dump "$DUMP_URL" -t public.piante --no-owner \
  -f "backups/tassonomia_$(date +%Y%m%d_%H%M%S)_pre_fase1_piante.sql"
ls -la backups | tail -1
[[ "$URL" == *ncuhhsvtjwcolhpdxbkt* ]] && psql "$URL" -X -At -c "select (select count(*) from public.specie), (select count(*) from public.piante), (select count(*) from public.generi)"
```

Expected: un file `tassonomia_..._pre_fase1_piante.sql` di qualche decina di kB e una riga di conteggi. Annotare la riga (alla stesura del piano: `212066|122|2916`): è il riferimento dello Step 5.

- [ ] **Step 4: Applicare la migration**

```bash
URL=$(grep '^DATABASE_URL=' .env.local | cut -d= -f2- | tr -d '"')
[[ "$URL" == *ncuhhsvtjwcolhpdxbkt* ]] && psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql
```

Expected: nessun errore (una serie di `CREATE TABLE`, `CREATE INDEX`, `ALTER TABLE`, `CREATE POLICY`, `REVOKE`, `GRANT`).

- [ ] **Step 5: Verificare**

```bash
URL=$(grep '^DATABASE_URL=' .env.local | cut -d= -f2- | tr -d '"')
[[ "$URL" == *ncuhhsvtjwcolhpdxbkt* ]] && psql "$URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/verifica_fase1.sql
[[ "$URL" == *ncuhhsvtjwcolhpdxbkt* ]] && psql "$URL" -X -At -c "select (select count(*) from public.specie), (select count(*) from public.piante), (select count(*) from public.generi)"
```

Expected: `VERIFICA FASE 1 OK`; seconda riga identica a quella annotata nello Step 3.

Se la verifica fallisce: eseguire subito il rollback (`psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql`, nello stesso blocco con la riga `URL=...` e la guardia), controllare che `select to_regclass('public.taxa')` restituisca una riga vuota e fermarsi senza aggiornare `CLAUDE.md`.

Poi, con lo strumento Supabase `get_advisors` (tipo `security`, progetto `ncuhhsvtjwcolhpdxbkt`): nessun rilievo nuovo che citi `taxa`, `nomi_comuni`, `cultivar`, `schede`, `mappa_specie` o le colonne nuove di `piante` (il rilievo "RLS attiva senza policy" su `mappa_specie` è voluto: annotarlo in `CLAUDE.md`). Con `get_advisors` tipo `performance`: nessun rilievo `unindexed_foreign_keys` sulle tabelle nuove.

- [ ] **Step 6: Prova dell'app nel browser**

Controllare se è già attivo un server di sviluppo di questo repository (`lsof -nP -iTCP:5173 -sTCP:LISTEN`). Se sì, usare quello senza lanciare `npm run dev`: un secondo server partirebbe su 5174, un'origine diversa senza la sessione Supabase dell'utente. Altrimenti avviarlo con `npm run dev`. Con l'utente già autenticato, aprire `http://localhost:5173/giardino/` (Home), `http://localhost:5173/giardino/#/piante` (elenco) e `http://localhost:5173/giardino/#/piante/<id>` (pagina di una pianta). Expected: le pagine si caricano come prima, nessun errore in console, la richiesta `rest/v1/piante?select=*` risponde 200. Non registrare cure né salvare piante: è una prova in sola lettura.

- [ ] **Step 7: Aggiornare `CLAUDE.md`**

In `CLAUDE.md`, nella sezione "Dati e persistenza", subito prima di `### Migrazione zone/sottozone/piante → Supabase (Fase 5, completata)`, inserire:

```markdown
### Modello tassonomico (in corso, fase 1 di 7 applicata)

Le correzioni ai nomi e ai contenuti di `specie` (lotti, generi, doppioni, naturalizzazione delle descrizioni, `revisione_specie` di `/zorbadice`) sono sospese salvo urgenze: dalla fase 4 il contenuto viene copiato in `schede` e una modifica successiva a `specie` non vi arriverebbe. Lo sostituisce il modello descritto in `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md` (nomi scientifici da Catalogue of Life XR, cultivar secondo il codice ICNCP, contenuti in schede con le loro fonti). La fase 1 (`supabase/migrations/20261013130000_tassonomia_fase1_tabelle.sql`, piano `docs/superpowers/plans/2026-10-13-modello-tassonomico-fase1.md`) ha creato le tabelle vuote `taxa`, `nomi_comuni`, `cultivar`, `schede`, `mappa_specie` e le colonne facoltative `piante.taxon_id`/`piante.cultivar_id` (al più una delle due). `specie` e `generi` non sono cambiate e l'app le usa ancora. Permessi: lettura pubblica senza le colonne interne (fonti, note, identificatori COL, `descrizione_originale`), quindi un `select=*` con la chiave pubblica su queste tabelle dà errore 42501 e il codice deve elencare le colonne. Le citazioni delle fonti dentro `descrizione`, `alert` e `immagine` non sono coperte dai permessi e vanno tolte o spostate prima di popolare `schede` (fase 4). Nessuna scrittura per i client. `mappa_specie` ha l'RLS attiva senza policy (rilievo degli advisor voluto: è solo per uso interno). Prove: `bash scripts/tassonomia/prova_fase1.sh`, in transazione annullata; valgono solo prima dell'applicazione: a migration applicata falliscono con «relation "taxa" already exists». Controllo sul database reale: `psql "$URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/verifica_fase1.sql`. Rollback: `psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase1.sql` (si rifiuta se le tabelle contengono dati). Attenzione: `scripts/backup-db.sh` salva con `--no-privileges`, quindi dopo un ripristino da quel backup le tabelle del modello riprendono i privilegi predefiniti di Supabase: vanno rieseguite le righe `revoke`/`grant` della migration e poi `verifica_fase1.sql`.
```

- [ ] **Step 8: Commit**

```bash
git add scripts/tassonomia/verifica_fase1.sql CLAUDE.md
git commit -m "Tassonomia fase 1 applicata: tabelle vuote del nuovo modello, verifica post-applicazione, CLAUDE.md"
```

Non fare push: chiedere all'utente.
