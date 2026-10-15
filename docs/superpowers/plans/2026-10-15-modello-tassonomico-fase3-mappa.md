# Modello tassonomico — fase 3: abbinamento delle righe di `specie` e `mappa_specie` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** abbinare ognuna delle 15.713 righe non cultivar della vecchia `specie` a un taxon di `taxa` e caricare sul database reale `mappa_specie` con l'esito di ogni abbinamento. Servono anche 6.729 taxon di COL in più e 8 taxon locali. L'utente rivede solo i 128 casi incerti.

**Architecture:** tutto si calcola sulla copia locale, dove ci sono Catalogue of Life completo (schema `col`) e `taxa` identica al reale (stessi lotti della fase 2, stesse chiavi).
1. Una cascata di regole SQL produce una proposta per ogni riga: corrispondenze esatte prima, poi forma, ortografia, refusi, rango superiore.
2. I casi incerti vanno all'utente in una pagina con proposta e alternativa, e l'utente risponde con le sole eccezioni.
3. Le decisioni si applicano.
4. Si esportano i taxon mancanti, i taxon locali e `mappa_specie` con i valori definitivi.
5. Il caricamento sul reale riusa `carica_taxa.sh` della fase 2, esteso ai lotti aggiuntivi, più un nuovo `carica_mappa.sh`; tutti e due si possono rilanciare.

**Tech Stack:** PostgreSQL 17 (Supabase, progetto `ncuhhsvtjwcolhpdxbkt`, piano gratuito; copia locale con i binari in `/opt/homebrew/opt/postgresql@17/bin/` ed estensione `fuzzystrmatch`), bash, Python 3.

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md`: sezioni "mappa_specie", "Fasi" (punto 3), "Decisioni dopo la verifica", "Decisioni sullo spazio" e "Decisioni per la fase 3 (approvate il 15/10/2026)". La ricerca è in `~/giardino-dati/col/ricerca_fase3/` (note dei ricercatori, risposte di GBIF, ICNCP).

## Global Constraints

- **Esiti** (vocabolario di `mappa_specie`): esatto, variante, sinonimo, rango superiore, ambiguo, ibrido, non trovato, deciso dall'utente. `taxon_id` è il nome trovato (accettato o sinonimo); dove attaccare le schede si decide nella fase 4 (decisione 4 della fase 3).
- **Regole automatiche:**
  - corrispondenza esatta: con la stessa `col.chiave` della fase 2; un accettato vince sugli omonimi sinonimi; sinonimi verso un solo accettato = sinonimo (decisione 1);
  - generi omonimi in altri generi: decide la famiglia della riga, con i nomi alternativi dell'ICN art. 18.5;
  - ambigui: il sinonimo omotipico se è uno solo (ICN art. 49), altrimenti l'antenato comune come HIGHERRANK di GBIF (decisione 2);
  - grex di orchidee: al genere (decisione 3); "hybrids", "species", "group" e "aff." al genere;
  - notogeneri assenti da COL: taxon locali sotto la famiglia della riga (decisione 6);
  - righe dei rollback: per nome, con l'eccezione di *agapanthus*, che va al genere (decisione 7);
  - mai i segnaposto "Genere spp" di COL.
- **Revisione:** solo i casi incerti (decisione 5): refusi, generi scritti male, generi sinonimi od omonimi, casi speciali, righe non esatte con le piante dell'utente. L'utente risponde in chat con le eccezioni; le decisioni si salvano in `scripts/tassonomia/dati/fase3_decisioni.tsv`.
- **Inserimento:**
  - `mappa_specie` si inserisce una volta sola, con i valori definitivi; sul reale nessun aggiornamento (specifica, "Decisioni sullo spazio", punto 5);
  - i taxon di COL nuovi seguono le regole della fase 2 e hanno `nota = 'importato nella fase 3 (abbinamento)'`; i taxon locali hanno `nota = 'notogenere assente da COL (fase 3)'`. Le note servono al rollback.
- **Solo queste tabelle cambiano:** `taxa` (righe in più) e `mappa_specie`. L'impronta di `specie` resta identica prima e dopo.
- **Spazio:**
  - prima di ogni passo sul reale, somma dei database ≤ 400 MB e WAL ≤ 300 MB;
  - attesi circa 6 MB in più per `taxa` e 4,5 MB per `mappa_specie`, cioè circa 271 MB su 500 (oggi 260,7);
  - sopra 450 MB ci si ferma (specifica, "Decisioni sullo spazio", punto 1).
- **Connessione:** sul reale solo `SUPABASE_DB_URL` (porta 5432), mai la 6543; `statement_timeout` di 2 minuti sul pooler, quindi ogni caricamento lo alza con `set local`.
- **Copia locale e reale:**
  - le prove girano sulla copia locale (`127.0.0.1:55440`);
  - COL completo non entra mai nel reale;
  - sul reale, prima del Task 4, solo letture: l'elenco delle piante e il backup.
- **Regole di lavoro:**
  - nessuna applicazione al reale senza il via esplicito dell'utente in chat;
  - nessun push senza richiesta;
  - l'URL del database non si stampa mai, nemmeno con `ps`;
  - se il controllo dei permessi blocca un comando sul reale, lo si dà all'utente da lanciare nel suo terminale.
- **Revisione e ramo:** si lavora su `main`; revisione dei Task 1–3 da parte di revisori nuovi prima del Task 4.

## Review Focus

1. **Un abbinamento sbagliato che passa per esatto** (omonimi di autori o regni diversi, notazione dell'ibrido, una x iniziale scambiata per il segno d'ibrido come in *Xanthoceras*): i casi verificati a mano devono restare giusti. `prova_mappa.sql` nel Task 1.
2. **Decisioni dell'utente applicate male** (numero che non corrisponde allo slug, codice COL inesistente, decisioni applicate due volte): rifiuto o nessun effetto. Prove nel Task 2.
3. **Mappa caricata prima dei taxon nuovi o a metà:** non entra niente, e rilanciando si completa. Prove `ordine` e `rilancio` di `prova_fase3.sh` nel Task 3.
4. **Rollback quando la fase 4 è già cominciata:** rifiuto. Prova `rollback` di `prova_fase3.sh`.
5. **`carica_taxa.sh` esteso che rompe la fase 2** (lotti senza `base.txt` né `regni.txt`): `prova_fase2.sh` deve ancora passare. Task 3.

## Misure del prototipo (15/10/2026, copia locale, tutte le proposte confermate)

| Misura | Valore |
|---|---|
| Righe | 15.713 (15.678 di `specie` + 35 dai rollback); 14.622 con una corrispondenza esatta |
| Esiti | esatto 12.134, sinonimo 2.084, variante 706, rango superiore 505, ambiguo 273 (153 omotipici, 120 all'antenato comune), ibrido 10, deciso dall'utente 1 (*Cetraria islandica*) |
| Da rivedere | 128: 2 piante dell'utente, 2 casi speciali, 97 possibili refusi, 17 generi scritti male, 10 generi incerti |
| Taxon nuovi | 6.729 di COL (406 nomi proposti più catena e sinonimi), 8 locali |
| WAL | taxon 20,9 MB, mappa 19,3 MB |
| Spazio | `mappa_specie` 4,5 MB |
| Durata sulla copia | abbinamento circa 1 minuto; prove di fase 3 25 s |

## File

- Create: `scripts/tassonomia/mappa_rollback_madri.py` — le 35 madri dai file di rollback.
- Create: `scripts/tassonomia/mappa_righe.sql`, `mappa_esatti.sql`, `mappa_altri.sql`, `mappa_proposte.sql` — l'abbinamento (copia locale, schema `col`).
- Create: `scripts/tassonomia/prova_mappa.sql` — prove dell'abbinamento.
- Create: `scripts/tassonomia/mappa_revisione.sql`, `mappa_revisione_pagina.py`, `mappa_decisioni.sql` — elenco da rivedere, pagina, decisioni.
- Create: `scripts/tassonomia/dati/fase3_decisioni.tsv` — le decisioni dell'utente.
- Create: `scripts/tassonomia/mappa_nuovi_taxa.sql`, `mappa_esporta.sh` — taxon in più e file da caricare.
- Modify: `scripts/tassonomia/carica_taxa.sh` e `scripts/tassonomia/verifica_fase2.sql` — lotti aggiuntivi (`base.txt`, `regni.txt`, colonne dall'intestazione).
- Create: `scripts/tassonomia/carica_mappa.sh`, `verifica_fase3.sql`, `rollback_fase3.sql`, `prova_fase3.sh`.
- Modify: `CLAUDE.md` (Task 4).

Tutti i comandi si lanciano dalla radice del repository. In ogni shell nuova vanno impostate queste variabili:
- `PG=/opt/homebrew/opt/postgresql@17/bin`;
- `SCRATCH` = la cartella temporanea della sessione (scratchpad);
- `COLDIR=$HOME/giardino-dati/col`;
- `F3=$COLDIR/fase3`;
- `COPIA=postgresql://postgres@127.0.0.1:55440/giardino`;
- `SUPABASE_DB_URL` da `.env.local`;
- `TS` e `BK` dal Task 4.

---

### Task 1: Abbinamento sulla copia locale

**Files:**
- Create: `scripts/tassonomia/prova_mappa.sql`
- Create: `scripts/tassonomia/mappa_rollback_madri.py`
- Create: `scripts/tassonomia/mappa_righe.sql`
- Create: `scripts/tassonomia/mappa_esatti.sql`
- Create: `scripts/tassonomia/mappa_altri.sql`
- Create: `scripts/tassonomia/mappa_proposte.sql`

**Interfaces:**
- Consumes:
  - la copia locale con `public.specie`, `public.generi`, `public.taxa` caricata dai lotti della fase 2, `col.nome_uso` e `col.corrispondenze` (da `col_selezione.sql`);
  - `piante_specie.tsv` dal reale (sola lettura).
- Produces: nella copia, le tabelle `col.mappa_righe`, `col.mappa_rollback`, `col.mappa_esatti`, `col.mappa_altri`, `col.mappa_plantae`, `col.mappa_piante` e soprattutto `col.mappa_proposte`, con le colonne:

  | Colonna | Tipo |
  |---|---|
  | `vecchia_specie_id` | uuid, chiave |
  | `vecchio_slug` | text |
  | `vecchio_nome_scientifico` | text |
  | `origine` | `specie` o `rollback` |
  | `col_id` | text, nome COL proposto |
  | `taxon_locale` | text |
  | `famiglia_locale` | text |
  | `esito` | text |
  | `nota` | text |
  | `da_rivedere` | boolean |
  | `motivo` | text |
  | `piante` | int |

  Funzioni nuove: `col.segno`, `col.autore_base`, `col.parole`, `col.k1`, `col.k2`.

- [ ] **Step 1: Copia locale pronta e dati d'ingresso**

Se la copia non è accesa con `taxa` caricata (per esempio dopo un riavvio, perché la cartella temporanea si svuota), va ricreata. Ci vogliono circa 6 minuti.

```bash
bash scripts/tassonomia/copia_locale.sh crea backups/completo_20261015_182023_pre_fase2.dump "$SCRATCH/copia_fase3"
bash scripts/tassonomia/col_carica_locale.sh "$COLDIR/xr_latest_coldp.zip" "$COPIA"
bash scripts/tassonomia/carica_taxa.sh "$COPIA" "$COLDIR/lotti_fase2" "$SCRATCH/copia_fase3_carico" | tail -1
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/col_selezione.sql | tail -1
$PG/psql "$COPIA" -X -q -c 'create table if not exists public.piante (taxon_id uuid references public.taxa (id) on delete restrict, cultivar_id uuid references public.cultivar (id) on delete restrict)'
```

Se la copia è già accesa, bastano i controlli. In ogni caso, poi:

```bash
mkdir -p "$F3"
set -a; source .env.local; set +a
$PG/psql "$SUPABASE_DB_URL" -X -q -c "begin read only" -c "copy (select p.specie as slug, s.nome_scientifico, (s.nome_scientifico ~ '''') as cultivar, count(*) as piante from public.piante p join public.specie s on s.slug = p.specie group by 1, 2, 3 order by 1) to stdout with (format csv, header, delimiter E'\t')" -c "rollback" > "$F3/piante_specie.tsv"
$PG/psql "$COPIA" -X -qAt -c "select 'taxa ' || count(*) from public.taxa" -c "select 'corrispondenze ' || count(*) from col.corrispondenze" -c "select 'col ' || count(*) from col.nome_uso"
tail -n +2 "$F3/piante_specie.tsv" | wc -l
```

Expected:
- `taxa 234514`, `corrispondenze 20775`, `col 8479599`;
- `93`: le righe di `specie` usate dalle 122 piante. La `col_selezione.sql` rilanciata cambia gli uuid di `col.selezione`, ma qui contano solo le chiavi di `public.taxa`, che vengono dai lotti.

- [ ] **Step 2: Scrivere le prove dell'abbinamento**

`scripts/tassonomia/prova_mappa.sql`:

```sql
-- Prove dell'abbinamento della fase 3 (mappa_righe, mappa_esatti, mappa_altri, mappa_proposte), sulla copia locale.
-- Errore al primo controllo che fallisce. Numeri e casi valgono per COL26.9 XR e specie del 15/10/2026.
do $$
declare
  n bigint;
  atteso record;
begin
  select count(*) into n from col.mappa_righe;
  if n <> 15713 then raise exception 'righe da abbinare: % (attese 15713: 15678 di specie + 35 dai rollback)', n; end if;
  select count(*) into n from col.mappa_proposte;
  if n <> 15713 then raise exception 'proposte: % su 15713', n; end if;
  select count(*) into n from col.mappa_proposte where col_id is null and taxon_locale is null and esito <> 'non trovato';
  if n > 0 then raise exception 'proposte senza taxon: %', n; end if;
  -- casi verificati a mano nella ricerca (slug, origine, esito atteso, nome del taxon proposto)
  for atteso in select * from (values
      ('pomodoro', 'specie', 'esatto', 'Solanum lycopersicum'),
      ('solanum-lycopersicum', 'rollback', 'esatto', 'Solanum lycopersicum'),
      ('rosmarino', 'specie', 'sinonimo', 'Rosmarinus officinalis'),
      ('sansevieria', 'specie', 'sinonimo', 'Sansevieria'),
      ('helleborus', 'specie', 'esatto', 'Helleborus'),
      ('pinus-sylvestris', 'specie', 'esatto', 'Pinus sylvestris'),
      ('galium-palustre', 'specie', 'ambiguo', 'Galium palustre'),
      ('sedum-hybridum', 'specie', 'ambiguo', 'Sedum hybridum'),
      ('physalis-alkekengi', 'specie', 'ambiguo', 'Physalidinae'),
      ('albizzia', 'specie', 'variante', 'Albizzia'),
      ('peperoncino', 'specie', 'variante', 'Capsicum annuum'),
      ('pianta-delle-monete', 'specie', 'variante', 'Pilea peperomioides'),
      ('sedum-morganianum', 'specie', 'variante', 'Sedum morganianum'),
      ('ferocactus', 'specie', 'rango superiore', 'Ferocactus'),
      ('agave', 'specie', 'rango superiore', 'Agave'),
      ('agapanthus', 'rollback', 'rango superiore', 'Agapanthus')
    ) v(slug, origine, esito, nome) loop
    select count(*) into n from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
     where p.vecchio_slug = atteso.slug and p.origine = atteso.origine and p.esito = atteso.esito and u.nome = atteso.nome;
    if n <> 1 then raise exception 'caso % (%): atteso % su %', atteso.slug, atteso.origine, atteso.esito, atteso.nome; end if;
  end loop;
  -- nomi di Plantae con la X iniziale (Xanthoceras): la x non è un segno d'ibrido
  perform 1 from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
   where p.vecchio_nome_scientifico = 'Xanthoceras sorbifolium' and u.nome = 'Xanthoceras sorbifolia';
  if not found then raise exception 'Xanthoceras sorbifolium non porta a Xanthoceras sorbifolia'; end if;
  -- grex: al genere, mai a una specie
  select count(*) into n from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
   where p.nota like 'grex%' and u.rango <> 'genus';
  if n > 0 then raise exception 'grex collegati a un taxon che non è un genere: %', n; end if;
  -- notogeneri locali sotto una famiglia
  select count(*) into n from col.mappa_proposte where taxon_locale is not null and famiglia_locale is null;
  if n > 0 then raise exception 'taxon locali senza famiglia: %', n; end if;
  -- refusi: mai senza conferma
  select count(*) into n from col.mappa_proposte where nota like 'possibile refuso%' and not da_rivedere;
  if n > 0 then raise exception 'refusi non da rivedere: %', n; end if;
  -- segnaposto "Genere spp" di COL: mai proposti
  select count(*) into n from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id where u.nome ~ '\sspp?\.?\s*$';
  if n > 0 then raise exception 'proposti segnaposto spp: %', n; end if;
  raise notice 'ABBINAMENTO CORRETTO: % proposte, % da rivedere', (select count(*) from col.mappa_proposte),
    (select count(*) from col.mappa_proposte where da_rivedere);
end $$;
```

- [ ] **Step 3: Lanciarle e vederle fallire**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_mappa.sql; echo "uscita $?"
```

Expected: `ERROR:  relation "col.mappa_righe" does not exist`, uscita 3.

- [ ] **Step 4: Scrivere l'estrazione delle madri e le righe da abbinare**

`scripts/tassonomia/mappa_rollback_madri.py`:

```python
#!/usr/bin/env python3
"""Fase 3: estrae dai file di rollback le righe madri cancellate (specifica, mappa_specie: origine 'rollback').

Legge il JSON di json_populate_recordset in rollback_doppioni_slug.sql (32 righe) e rollback_tre_casi_doppioni.sql
(3 righe) e scrive su stdout un TSV id, slug, nome_scientifico, famiglia_botanica. Le cultivar (nome con apici o con
una madre) restano fuori: le 4 cultivar doppie di rollback_hedera_residue.sql sono materia della fase 4.
Uso: python3 scripts/tassonomia/mappa_rollback_madri.py > madri.tsv
"""
import csv
import json
import re
import sys
from pathlib import Path

FILE = ['scripts/nomi-italiani/rollback_doppioni_slug.sql', 'scripts/nomi-italiani/rollback_tre_casi_doppioni.sql']

righe = []
for nome in FILE:
    testo = Path(nome).read_text(encoding='utf-8')
    blocco = re.search(r'\$json\$(.*?)\$json\$', testo, re.S)
    if not blocco:
        sys.exit(f'JSON non trovato in {nome}')
    for r in json.loads(blocco.group(1)):
        if "'" in r['nome_scientifico'] or r.get('specie_padre_id'):
            continue
        righe.append((r['id'], r['slug'], r['nome_scientifico'], r.get('famiglia_botanica') or ''))
w = csv.writer(sys.stdout, delimiter='\t', lineterminator='\n')
w.writerow(['id', 'slug', 'nome_scientifico', 'famiglia_botanica'])
w.writerows(righe)
print(f'madri estratte: {len(righe)}', file=sys.stderr)
```

`scripts/tassonomia/mappa_righe.sql`:

```sql
-- Fase 3: righe da abbinare = righe non cultivar di specie + madri recuperate dai rollback.
-- Lo standard input è il TSV delle madri recuperate (psql ... -f mappa_righe.sql < rollback_madri.tsv).
set statement_timeout = 0;
drop table if exists col.mappa_righe, col.mappa_rollback;
create table col.mappa_rollback (id uuid primary key, slug text not null, nome_scientifico text not null, famiglia_botanica text);
\copy col.mappa_rollback from pstdin with (format csv, delimiter E'\t', header)
create table col.mappa_righe as
  select id, slug, nome_scientifico, famiglia_botanica, 'specie'::text as origine
    from public.specie where nome_scientifico !~ '''' and specie_padre_id is null
  union all
  select id, slug, nome_scientifico, famiglia_botanica, 'rollback' from col.mappa_rollback;
alter table col.mappa_righe add primary key (id);
alter table col.mappa_righe add column chiave text, add column nome text, add column rango_atteso text;
update col.mappa_righe set
  nome = btrim(regexp_replace(nome_scientifico, '\s+', ' ', 'g')),
  chiave = col.chiave(nome_scientifico),
  rango_atteso = case
    when nome_scientifico ~ '\s(subsp|ssp)\.\s' then 'subspecies'
    when nome_scientifico ~ '\svar\.\s' then 'variety'
    when nome_scientifico ~ '\sf\.\s' then 'form'
    when col.chiave(nome_scientifico) !~ ' ' then 'genus'
    when col.chiave(nome_scientifico) ~ '^[A-Z][^ ]* [a-z][^ ]*$' then 'species'
    else 'altro' end;
create index on col.mappa_righe (chiave);
analyze col.mappa_righe;
\pset tuples_only on
\pset format unaligned
select 'righe ' || count(*) || ' (specie ' || count(*) filter (where origine = 'specie') || ', rollback ' || count(*) filter (where origine = 'rollback') || ')' from col.mappa_righe;
select 'con corrispondenza esatta ' || count(*) from col.mappa_righe r where exists (select 1 from col.corrispondenze c where c.chiave = r.chiave);
```

- [ ] **Step 5: Scrivere la classificazione delle corrispondenze esatte**

`scripts/tassonomia/mappa_esatti.sql`:

```sql
-- Fase 3: classificazione delle righe con corrispondenze esatte (stessa col.chiave) già in public.taxa.
-- Regole (GBIF species match su COL XR, ICN):
-- - un accettato con il nostro nome vince sugli omonimi sinonimi di altri autori;
-- - sinonimi che portano tutti allo stesso accettato = sinonimo;
-- - generi omonimi in altri generi: decide la famiglia della riga (ICN art. 18.5 per i nomi alternativi);
-- - altrimenti ambiguo: il sinonimo omotipico (ICN art. 49) se è uno solo, se no l'antenato comune (GBIF HIGHERRANK).
set statement_timeout = 0;
drop table if exists col.mappa_esatti;
create or replace function col.segno(n text) returns text language sql immutable parallel safe as $$
  select btrim(regexp_replace(regexp_replace(regexp_replace(n, '\s+', ' ', 'g'),
           '(^|\s)[×x](\s+|(?=[A-Z]))', '\1× ', 'g'), '\s+', ' ', 'g'))
$$;
-- autore del basionimo (tra parentesi, ICN art. 49) o, senza parentesi, l'autore stesso
create or replace function col.autore_base(a text) returns text language sql immutable parallel safe as $$
  select btrim(regexp_replace(coalesce(substring(coalesce(a, '') from '^\(([^)]*)\)'), coalesce(a, '')), '\s+', ' ', 'g'))
$$;

create temp table cand as
select r.id as sid, t.id as tid, t.col_id, t.nome_scientifico as tnome, t.autore, t.rango, t.stato,
       case when t.stato in ('accepted', 'provisionally accepted') then t.id else t.accettato_id end as acc_id,
       (t.stato in ('accepted', 'provisionally accepted')) as e_acc,
       (t.nome_scientifico = r.nome) as identico,
       (col.segno(t.nome_scientifico) = col.segno(regexp_replace(r.nome, '\s+spp\.?$', ''))) as stesso_segno,
       ((t.nome_scientifico ~ '×') = (r.nome ~ '×|(^|\s)x\s')) as stesso_ibrido
  from col.mappa_righe r
  join col.corrispondenze c on c.chiave = r.chiave
  join public.taxa t on t.col_id = c.id;
create index on cand (sid);
analyze cand;

-- famiglia e antenati di ogni accettato raggiunto
create temp table anc as
with recursive a(acc_id, id, rango, nome, padre_id, dist) as (
  select t.id, t.id, t.rango, t.nome_scientifico, t.padre_id, 0
    from public.taxa t where t.id in (select distinct acc_id from cand where acc_id is not null)
  union all
  select a.acc_id, p.id, p.rango, p.nome_scientifico, p.padre_id, a.dist + 1
    from a join public.taxa p on p.id = a.padre_id where a.dist < 60)
select acc_id, id, rango, nome, dist, max(dist) over (partition by acc_id) - dist as prof from a;
create index on anc (acc_id);
create temp table fam as
select acc_id, max(nome) filter (where rango = 'family') as famiglia from anc group by acc_id;
create index on fam (acc_id);

-- famiglie scritte nella riga ("X or Y", "X / Y") portate al nome accettato di COL (Compositae -> Asteraceae...)
create temp table fam_riga as
with alt as (
  select r.id as sid, btrim(x) as f
    from col.mappa_righe r, regexp_split_to_table(coalesce(r.famiglia_botanica, ''), '\s+or\s+|\s*/\s*|\s*,\s*') x
   where btrim(x) <> '' and r.id in (select sid from cand))
select distinct alt.sid,
       coalesce(case when u.status in ('accepted', 'provisionally accepted') then u.nome end, p.nome, alt.f) as famiglia_col
  from alt
  left join col.nome_uso u on u.nome = alt.f and u.rango = 'family' and u.codice in ('botanical', '')
  left join col.nome_uso p on p.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym') and p.rango = 'family';
create index on fam_riga (sid);

create temp table c2 as
select c.*, r.rango_atteso,
       (r.rango_atteso = 'altro' or c.rango = r.rango_atteso
        or (r.rango_atteso = 'species' and c.rango = 'species aggregate')) as rango_ok,
       (c.rango in ('other', 'unranked', 'infraspecific name')) as rango_debole,
       exists (select 1 from fam f join fam_riga fr on fr.famiglia_col = f.famiglia
                where f.acc_id = c.acc_id and fr.sid = c.sid) as fam_ok,
       ta.rango as acc_rango, ta.autore as acc_autore, ta.padre_id as acc_padre
  from cand c
  join col.mappa_righe r on r.id = c.sid
  left join public.taxa ta on ta.id = c.acc_id;
-- livello d'uso: 1 rango giusto, 2 rango non dichiarato, 3 solo misapplied, 4 rango diverso
alter table c2 add column livello int;
update c2 set livello = case when rango_ok and stato <> 'misapplied' then 1
                             when rango_debole and stato <> 'misapplied' then 2
                             when stato = 'misapplied' then 3 else 4 end;
create temp table u as select c2.* from c2 where c2.livello = (select min(x.livello) from c2 x where x.sid = c2.sid);
create index on u (sid);

create temp table m as
select u.sid, min(u.livello) as livello,
       (select count(*) from cand c where c.sid = u.sid) as n_cand,
       count(*) filter (where e_acc) as n_acc,
       count(*) filter (where stato = 'accepted') as n_acc_str,
       count(distinct acc_id) as n_dest,
       count(distinct acc_id) filter (where fam_ok) as n_dest_fam,
       bool_or(e_acc and fam_ok) as acc_fam_ok,
       bool_or(not e_acc and fam_ok) as altro_fam_ok
  from u group by u.sid;

create temp table classe as
select m.*, r.rango_atteso,
  case
    when m.livello = 3 then 'solo misapplied'
    when m.livello = 4 then 'rango diverso'
    when m.n_acc = 1 and m.n_dest = 1 then 'accettato'
    when m.n_acc = 1 and r.rango_atteso = 'genus' and m.altro_fam_ok and not m.acc_fam_ok and m.n_dest_fam = 1 then 'genere omonimo: decide la famiglia'
    when m.n_acc = 1 then 'accettato tra omonimi'
    when m.n_acc > 1 and m.n_acc_str = 1 then 'accettato e provvisorio omonimo'
    when m.n_acc > 1 then 'più accettati omonimi'
    when m.n_dest = 1 then 'sinonimo'
    when m.n_dest_fam = 1 then 'sinonimi: decide la famiglia'
    else 'sinonimi verso più accettati'
  end as classe
  from m join col.mappa_righe r on r.id = m.sid;

-- candidato scelto per le classi risolte
create temp table scelto as
select distinct on (k.sid) k.sid, u.tid, u.col_id, u.tnome, u.autore, u.stato, u.rango, u.identico, u.stesso_segno, u.stesso_ibrido
  from classe k join u on u.sid = k.sid
 where case k.classe
         when 'accettato' then u.e_acc
         when 'accettato tra omonimi' then u.e_acc
         when 'accettato e provvisorio omonimo' then u.stato = 'accepted'
         when 'genere omonimo: decide la famiglia' then u.fam_ok
         when 'sinonimo' then true
         when 'sinonimi: decide la famiglia' then u.fam_ok
         else false end
 order by k.sid, u.identico desc, (u.stato = 'synonym') desc, u.col_id;

-- ambigui: sinonimo omotipico (stesso autore del basionimo del suo accettato; per gli autonimi senza autore vale la specie)
create temp table omotipici as
select u.sid, u.tid, u.col_id, u.tnome, u.autore, u.stato, u.rango, u.acc_id
  from u
  join classe k on k.sid = u.sid
  left join public.taxa sp on sp.id = u.acc_padre and u.acc_rango in ('subspecies', 'variety', 'form') and coalesce(u.acc_autore, '') = ''
 where k.classe in ('sinonimi verso più accettati', 'più accettati omonimi', 'solo misapplied') and not u.e_acc
   and col.autore_base(u.autore) <> ''
   and col.autore_base(u.autore) = col.autore_base(coalesce(nullif(u.acc_autore, ''), sp.autore));
create temp table omotipico as
select sid, min(tid::text)::uuid as tid from omotipici
 where sid in (select sid from omotipici group by sid having count(distinct acc_id) = 1)
 group by sid;

-- antenato comune più basso delle destinazioni (GBIF HIGHERRANK quando non sceglie)
create temp table lca as
select x.sid, x.id as tid from (
  select u.sid, a.id, count(distinct u.acc_id) as n,
         row_number() over (partition by u.sid order by count(distinct u.acc_id) desc, max(a.prof) desc) as rn
    from u join anc a on a.acc_id = u.acc_id
   group by u.sid, a.id) x
  join m on m.sid = x.sid
 where x.rn = 1 and x.n = m.n_dest;

create table col.mappa_esatti as
select k.sid, k.classe,
  case
    when k.classe in ('accettato', 'accettato tra omonimi', 'accettato e provvisorio omonimo', 'genere omonimo: decide la famiglia')
         and s.autore ~* 'orth\.\s*var' then 'variante'
    when k.classe in ('accettato', 'accettato tra omonimi', 'accettato e provvisorio omonimo', 'genere omonimo: decide la famiglia')
         and not s.stesso_ibrido then 'variante'
    when k.classe in ('accettato', 'accettato tra omonimi', 'accettato e provvisorio omonimo')
         or (k.classe = 'genere omonimo: decide la famiglia' and s.stato in ('accepted', 'provisionally accepted')) then 'esatto'
    when k.classe in ('sinonimo', 'sinonimi: decide la famiglia', 'genere omonimo: decide la famiglia') and s.autore ~* 'orth\.\s*var' then 'variante'
    when k.classe in ('sinonimo', 'sinonimi: decide la famiglia', 'genere omonimo: decide la famiglia') then 'sinonimo'
    when k.classe = 'rango diverso' then 'rango superiore'
    else 'ambiguo'
  end as esito,
  coalesce(s.tid, o.tid, l.tid) as taxon_id,
  case
    when r.nome ~ '\sspp\.?$' then 'riga di genere ("Genere spp."): collegata al genere'
    when s.tid is not null and not s.identico and s.stesso_segno then 'scritto con x invece di ×'
    when s.tid is not null and not s.stesso_ibrido then 'segno d''ibrido presente solo in uno dei due nomi'
    when k.classe like '%famiglia%' then 'omonimo risolto con la famiglia della riga'
    when k.classe = 'accettato tra omonimi' then 'esistono omonimi sinonimi di altri autori: vale l''accettato'
    when o.tid is not null then 'ambiguo: scelto il sinonimo omotipico (ICN art. 49)'
    when s.tid is null then 'ambiguo: collegato all''antenato comune delle destinazioni (come GBIF HIGHERRANK)'
  end as nota,
  k.n_cand
  from classe k
  join col.mappa_righe r on r.id = k.sid
  left join scelto s on s.sid = k.sid
  left join omotipico o on o.sid = k.sid and s.tid is null
  left join lca l on l.sid = k.sid;
alter table col.mappa_esatti add primary key (sid);

\pset tuples_only on
\pset format unaligned
select 'righe ' || count(*) || ', senza taxon ' || count(*) filter (where taxon_id is null) from col.mappa_esatti;
select esito || ' ' || count(*) from col.mappa_esatti group by esito order by count(*) desc;
select classe || ' ' || count(*) from col.mappa_esatti group by classe order by count(*) desc;
select 'ambigui: omotipico ' || count(*) filter (where nota like '%omotipico%') || ', antenato comune ' || count(*) filter (where nota like '%antenato%') from col.mappa_esatti where esito = 'ambiguo';
```

- [ ] **Step 6: Scrivere la cascata per le righe senza corrispondenza esatta**

`scripts/tassonomia/mappa_altri.sql`:

```sql
-- Fase 3: righe senza corrispondenza esatta. Cascata di regole, dalla più sicura alla più larga:
-- forme speciali (grex, "hybrids", "aff.") -> genere; forma del nome (k1); ortografia (k2, come SciNameNormalizer di
-- GBIF); refuso di 1-2 lettere nello stesso genere (da far confermare); rango superiore (specie, poi genere);
-- genere scritto male con conferma dell'epiteto (da far confermare); famiglia; non trovato.
set statement_timeout = 0;
create extension if not exists fuzzystrmatch schema extensions;
drop table if exists col.mappa_altri, col.mappa_plantae;

-- parole del nome in forma normalizzata: senza trattino morbido, segni d'ibrido (× ovunque, x solo isolata o davanti
-- a una maiuscola: la X di Xanthoceras resta), parentesi, quello che segue una barra, marcatori di rango, " sp./spp.";
-- minuscolo
create or replace function col.parole(n text) returns text[] language sql immutable parallel safe as $$
  select regexp_split_to_array(btrim(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(
           lower(regexp_replace(replace(replace(n, chr(173), ''), '×', ' '), '(^|\s)x(\s+|(?=[A-Z]))', ' ', 'g')),
           '\([^)]*\)', ' ', 'g'),
           '/.*$', ''),
           '(^|\s)(subsp|ssp|var|f|forma|subvar|nothosubsp|nothovar|convar)\.?(?=\s)', ' ', 'g'),
           '\s+spp?\.?\s*$', ''),
           '\s+', ' ', 'g')), ' ')
$$;
-- k1: forma. Il genere resta separato, il resto si unisce (novae hiberniae = novae-hiberniae, ICN art. 23.1)
create or replace function col.k1(w text[]) returns text language sql immutable parallel safe as $$
  select w[1] || coalesce(' ' || nullif(replace(array_to_string(w[2:], ''), '-', ''), ''), '')
$$;
-- k2: ortografia sull'epiteto (regole di SciNameNormalizer di GBIF checklistbank): lettere doppie, desinenze, i/j/y, th, rh
create or replace function col.k2(k text) returns text language sql immutable parallel safe as $$
  select split_part(k, ' ', 1) || coalesce(' ' || nullif(
    regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(
      split_part(k, ' ', 2),
      '(.)\1+', '\1', 'g'), '(on|um|us|a)$', 'a'), '(?<=.)[jyi]+', 'i', 'g'), 'ei$', 'i'), 'th', 't', 'g'), 'rh', 'r', 'g'), ''), '')
$$;

create temp table nt as
select r.*, col.parole(r.nome) as parole,
  case
    when r.nome ~ '^(×\s*|x\s+)?[A-Z][a-z-]+(\s+[A-Z0-9(][^\s]*)+$' then 'grex'
    when r.nome ~* '\s(hybrids?|species|group|mix)\s*$' or r.nome ~* '\shybrids?\s' then 'ibridi o gruppo'
    when r.nome ~ '\s(aff|cf)\.\s' then 'aff.'
  end as forma,
  (r.nome ~ '×|(^|\s)x\s') as ibrido
  from col.mappa_righe r
 where not exists (select 1 from col.corrispondenze c where c.chiave = r.chiave);
alter table nt add column k1 text, add column genere text;
update nt set k1 = col.k1(parole), genere = parole[1];
create index on nt (id);

-- COL in Plantae, ristretto ai generi dei nostri nomi (sinonimi: il regno è quello dell'accettato; niente segnaposto spp)
create table col.mappa_plantae as
select u.id, u.nome, u.autore, u.rango, u.status, u.parent_id,
       case when u.status in ('accepted', 'provisionally accepted') then u.id else u.parent_id end as acc_id,
       col.k1(col.parole(u.nome)) as k1
  from col.nome_uso u
  left join col.nome_uso p on p.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym', 'misapplied')
 where coalesce(nullif(u.regno, ''), p.regno) = 'Plantae'
   and u.nome !~ '\sspp?\.?\s*$' and coalesce(p.nome, '') !~ '\sspp?\.?\s*$'
   and lower(split_part(col.chiave(u.nome), ' ', 1)) in (select genere from nt);
alter table col.mappa_plantae add column k2 text, add column genere text, add column ibrido boolean;
update col.mappa_plantae set k2 = col.k2(k1), genere = split_part(k1, ' ', 1), ibrido = (nome ~ '×');
create index on col.mappa_plantae (k1);
create index on col.mappa_plantae (k2);
create index on col.mappa_plantae (genere);
analyze col.mappa_plantae;

-- 1-2. forma (k1) e ortografia (k2); solo nomi di almeno due parole e non delle forme speciali
create temp table candidati as
select n.id as sid, 'forma'::text as metodo, c.id, c.status, c.acc_id from nt n join col.mappa_plantae c on c.k1 = n.k1
 where n.forma is null and n.k1 ~ ' ' and c.rango <> 'genus'
union all
select n.id, 'ortografia', c.id, c.status, c.acc_id from nt n join col.mappa_plantae c on c.k2 = col.k2(n.k1)
 where n.forma is null and n.k1 ~ ' ' and c.rango <> 'genus'
   and not exists (select 1 from col.mappa_plantae x where x.k1 = n.k1 and x.rango <> 'genus');
-- 3. refuso di una lettera (due se l'epiteto supera 7 lettere) nello stesso genere, stessa natura d'ibrido; solo binomi:
--    per i nomi di tre o più parole vale la specie superiore (con il refuso Vicia faba major diventava V. faba var. minor)
insert into candidati
select n.id, 'refuso', c.id, c.status, c.acc_id
  from nt n join col.mappa_plantae c on c.genere = n.genere and c.rango <> 'genus' and c.ibrido = n.ibrido
 where n.forma is null and array_length(n.parole, 1) = 2 and n.id not in (select sid from candidati)
   and extensions.levenshtein(split_part(n.k1, ' ', 2), split_part(c.k1, ' ', 2))
       <= case when length(split_part(n.k1, ' ', 2)) > 7 then 2 else 1 end;
-- per i refusi vale solo la distanza minima
delete from candidati c using (
  select c2.sid, c2.id, extensions.levenshtein(split_part(n.k1, ' ', 2), split_part(p.k1, ' ', 2)) as d,
         min(extensions.levenshtein(split_part(n.k1, ' ', 2), split_part(p.k1, ' ', 2))) over (partition by c2.sid) as dmin
    from candidati c2 join nt n on n.id = c2.sid join col.mappa_plantae p on p.id = c2.id where c2.metodo = 'refuso') x
 where c.sid = x.sid and c.id = x.id and x.d > x.dmin;

create temp table metriche as
select sid, count(*) filter (where status in ('accepted', 'provisionally accepted')) as n_acc, count(distinct acc_id) as n_dest
  from candidati group by sid;
create temp table scelta as
select distinct on (c.sid) c.sid, c.metodo, c.id as col_id, c.status
  from candidati c join metriche m using (sid)
 where (m.n_acc = 1 and c.status in ('accepted', 'provisionally accepted')) or (m.n_acc = 0 and m.n_dest = 1)
 order by c.sid, (c.status = 'accepted') desc, (c.status = 'synonym') desc, c.id;

-- 4. rango superiore: la specie per i nomi di tre o più parole, poi il genere (accettato; preferito quello già in taxa)
create temp table specie_sup as
select distinct on (n.id) n.id as sid, c.id as col_id, c.status
  from nt n join col.mappa_plantae c on c.k1 = col.k1(n.parole[1:2]) and c.rango = 'species'
 where n.forma is null and array_length(n.parole, 1) >= 3 and n.id not in (select sid from scelta)
   and c.status in ('accepted', 'provisionally accepted')
 order by n.id, (c.status = 'accepted') desc, c.id;
create temp table genere_sup as
select distinct on (n.id) n.id as sid, c.id as col_id, c.status,
       count(*) filter (where c.status in ('accepted', 'provisionally accepted')) over (partition by n.id) as n_generi
  from nt n join col.mappa_plantae c on c.k1 = n.genere and c.rango = 'genus'
 order by n.id, (c.status in ('accepted', 'provisionally accepted')) desc,
          exists (select 1 from public.taxa t where t.col_id = c.id) desc, (c.status = 'accepted') desc, c.id;

-- 5. genere scritto male: un genere di Plantae a una o due lettere (generi lunghi) in cui esiste lo stesso epiteto, quando
--    il nostro genere non è un genere accettato (Buddleia è un sinonimo di Buddleja, Reineckia di un genere di palme).
--    Sicuro se COL registra il nostro genere come sinonimo proprio di quello trovato.
create temp table genere_refuso as
select distinct on (n.id) n.id as sid, u.id as col_id, u.status,
       exists (select 1 from col.mappa_plantae g join col.nome_uso a on a.id = g.parent_id
                where g.genere = n.genere and g.rango = 'genus' and g.status not in ('accepted', 'provisionally accepted')
                  and lower(a.nome) = lower(split_part(col.chiave(u.nome), ' ', 1))) as sicuro
  from nt n
  join col.nome_uso u on lower(split_part(col.chiave(u.nome), ' ', 2)) = n.parole[2]
  left join col.nome_uso p on p.id = u.parent_id and u.status in ('synonym', 'ambiguous synonym')
 where n.forma is null and array_length(n.parole, 1) >= 2
   and not exists (select 1 from col.mappa_plantae g where g.genere = n.genere and g.rango = 'genus'
                                                   and g.status in ('accepted', 'provisionally accepted'))
   and coalesce(nullif(u.regno, ''), p.regno) = 'Plantae'
   and u.nome !~ '\sspp?\.?\s*$'
   and extensions.levenshtein(lower(split_part(col.chiave(u.nome), ' ', 1)), n.genere)
       between 1 and case when length(n.genere) > 8 then 2 else 1 end
 order by n.id, (array_length(col.parole(u.nome), 1) = array_length(n.parole, 1)) desc, (u.status = 'accepted') desc, u.id;

-- 6. notogeneri assenti da COL (× Angulocaste, × Mahoberberis...): taxon locale sotto la famiglia della riga
--    (specifica, "taxa": i taxon locali servono per i notogeneri non riconosciuti)
create temp table notogeneri as
select n.genere, '× ' || initcap(n.genere) as nome,
       min(btrim(split_part(regexp_replace(coalesce(n.famiglia_botanica, ''), '\s+or\s+', '/', 'g'), '/', 1))) as famiglia
  from nt n
 where n.genere in (select genere from nt where nome ~ '^(×\s*|x\s+)[A-Z]')
   and not exists (select 1 from col.mappa_plantae g where g.genere = n.genere and g.rango = 'genus')
 group by n.genere;

-- 7. nomi che in COL esistono solo fuori da Plantae (Cetraria islandica, un lichene): da decidere
create temp table fuori_plantae as
select distinct on (n.id) n.id as sid, u.id as col_id, u.regno
  from nt n join col.nome_uso u on col.chiave(u.nome) = n.chiave
 where u.status in ('accepted', 'provisionally accepted') and u.regno <> 'Plantae'
 order by n.id, u.id;

-- 8. ultime proposte per chi non ne ha (da far confermare): il genere accettato di Plantae più simile per scrittura
--    (due lettere al massimo), altrimenti la famiglia scritta nella riga, portata al nome accettato di COL
create temp table genere_simile as
select distinct on (n.id) n.id as sid, u.id as col_id
  from nt n join col.nome_uso u on u.rango = 'genus' and u.status = 'accepted' and u.regno = 'Plantae'
   and extensions.levenshtein(lower(u.nome), n.genere) <= 2
 where not exists (select 1 from col.mappa_plantae g where g.genere = n.genere and g.rango = 'genus')
   and n.genere not in (select genere from notogeneri)
 order by n.id, extensions.levenshtein(lower(u.nome), n.genere), u.id;
create temp table famiglia_riga as
select distinct on (n.id) n.id as sid, coalesce(case when u.status = 'accepted' then u.id end, a.id) as col_id
  from nt n
  join col.nome_uso u on u.nome = btrim(split_part(regexp_replace(coalesce(n.famiglia_botanica, ''), '\s+or\s+', '/', 'g'), '/', 1))
   and u.rango = 'family' and u.codice in ('botanical', '')
  left join col.nome_uso a on a.id = u.parent_id and u.status <> 'accepted' and a.rango = 'family' and a.status = 'accepted'
 where coalesce(case when u.status = 'accepted' then u.id end, a.id) is not null
 order by n.id, (u.status = 'accepted') desc, u.id;

create table col.mappa_altri as
select n.id as sid, n.forma,
  case
    when s.sid is not null then s.metodo
    when ng.genere is not null then 'notogenere locale'
    when n.forma is not null and g.sid is not null then n.forma
    when gr.sid is not null then 'genere scritto male'
    when sp.sid is not null then 'specie superiore'
    when g.sid is not null then 'genere superiore'
    when fp.sid is not null then 'fuori da Plantae'
    when gs.sid is not null then 'genere simile'
    when fr.sid is not null then 'famiglia della riga'
    else 'nessuno' end as metodo,
  case when ng.genere is null then
    coalesce(s.col_id, case when n.forma is null then gr.col_id end, case when n.forma is null then sp.col_id end, g.col_id, fp.col_id,
             gs.col_id, fr.col_id)
  end as col_id,
  ng.nome as taxon_locale, ng.famiglia as famiglia_locale,
  case
    when s.sid is not null then 'variante'
    when ng.genere is not null then 'ibrido'
    when n.forma is null and gr.sid is not null then 'variante'
    when n.forma is null and sp.sid is not null then 'rango superiore'
    when g.sid is not null then 'rango superiore'
    when fp.sid is null and gs.sid is not null then 'variante'
    when fp.sid is null and fr.sid is not null then 'rango superiore'
    else 'non trovato' end as esito,
  case
    when s.metodo = 'refuso' then true
    when ng.genere is not null then false
    when n.forma is null and gr.sid is not null and s.sid is null then not gr.sicuro
    when s.sid is null and sp.sid is null and g.sid is null then true
    when s.sid is null and sp.sid is null and g.status not in ('accepted', 'provisionally accepted') then true
    when g.n_generi > 1 and s.sid is null and sp.sid is null then true
    else false end as da_rivedere,
  case
    when s.metodo = 'forma' then 'stesso nome scritto in un''altra forma (maiuscole, marcatori di rango, segni, trattini)'
    when s.metodo = 'ortografia' then 'variante ortografica (regole di normalizzazione di GBIF)'
    when s.metodo = 'refuso' then 'possibile refuso: da confermare'
    when ng.genere is not null then 'notogenere assente da COL: taxon locale sotto la famiglia ' || coalesce(ng.famiglia, '?')
    when n.forma = 'grex' then 'grex (ICNCP art. 23): collegato al genere, nella fase 4 diventa una cultivar di categoria grex'
    when n.forma = 'ibridi o gruppo' then 'ibridi o gruppo del genere: collegato al genere'
    when n.forma = 'aff.' then '"aff." indica una pianta affine, non la specie: collegato al genere'
    when gr.sid is not null and gr.sicuro then 'genere scritto in una variante registrata da COL come sinonimo'
    when gr.sid is not null then 'genere scritto male: da confermare'
    when sp.sid is not null then 'la sottospecie o varietà non è in COL: collegato alla specie'
    when g.n_generi > 1 then 'più generi omonimi in Plantae: da confermare'
    when g.sid is not null and g.status not in ('accepted', 'provisionally accepted') then 'il genere in COL è solo un sinonimo: da confermare'
    when g.sid is not null and exists (select 1 from candidati c where c.sid = n.id) then 'più candidati senza una scelta sicura: collegato al genere'
    when g.sid is not null then 'specie non trovata in COL: collegato al genere'
    when fp.sid is not null then 'in COL solo fuori da Plantae (regno ' || fp.regno || '): da decidere'
    when gs.sid is not null then 'genere non trovato in COL; proposto il genere più simile per scrittura: da confermare'
    when fr.sid is not null then 'genere non trovato in COL; proposta la famiglia scritta nella riga: da confermare'
    else 'genere non trovato in COL' end as nota
  from nt n
  left join scelta s on s.sid = n.id
  left join specie_sup sp on sp.sid = n.id
  left join genere_sup g on g.sid = n.id
  left join genere_refuso gr on gr.sid = n.id
  left join notogeneri ng on ng.genere = n.genere and s.sid is null
  left join fuori_plantae fp on fp.sid = n.id
  left join genere_simile gs on gs.sid = n.id
  left join famiglia_riga fr on fr.sid = n.id;
alter table col.mappa_altri add primary key (sid);

\pset tuples_only on
\pset format unaligned
select 'righe ' || count(*) from col.mappa_altri;
select metodo || ' | ' || esito || ' | da rivedere ' || da_rivedere || ' | ' || count(*) from col.mappa_altri group by metodo, esito, da_rivedere order by count(*) desc;
```

- [ ] **Step 7: Scrivere le proposte finali**

`scripts/tassonomia/mappa_proposte.sql`:

```sql
-- Fase 3: proposte finali per tutte le righe (col.mappa_esatti + col.mappa_altri), priorità delle piante dell'utente,
-- casi speciali, taxon COL ancora da importare. Standard input: TSV slug/nome_scientifico/cultivar/piante (piante_specie.tsv).
set statement_timeout = 0;
drop table if exists col.mappa_proposte, col.mappa_piante;
create table col.mappa_piante (slug text primary key, nome_scientifico text, cultivar boolean, piante int);
\copy col.mappa_piante from pstdin with (format csv, delimiter E'\t', header)

create table col.mappa_proposte as
select r.id as vecchia_specie_id, r.slug as vecchio_slug, r.nome_scientifico as vecchio_nome_scientifico, r.origine,
       t.col_id, null::text as taxon_locale, null::text as famiglia_locale,
       e.esito, e.nota, false as da_rivedere, null::text as motivo
  from col.mappa_esatti e join col.mappa_righe r on r.id = e.sid join public.taxa t on t.id = e.taxon_id
union all
select r.id, r.slug, r.nome_scientifico, r.origine, a.col_id, a.taxon_locale, a.famiglia_locale, a.esito, a.nota,
       a.da_rivedere, case when a.da_rivedere then a.metodo end
  from col.mappa_altri a join col.mappa_righe r on r.id = a.sid;
alter table col.mappa_proposte add primary key (vecchia_specie_id);
alter table col.mappa_proposte add column piante int not null default 0;
update col.mappa_proposte p set piante = x.piante from col.mappa_piante x where x.slug = p.vecchio_slug and p.origine = 'specie';

-- piante dell'utente: si rivede ogni riga non esatta (le altre restano automatiche)
update col.mappa_proposte set da_rivedere = true, motivo = coalesce(motivo, 'pianta tua')
 where piante > 0 and esito in ('ambiguo', 'rango superiore', 'non trovato');
-- agapanthus (riga recuperata): nome di specie ma descrizione del genere (migration 20261013100000) -> proposto il genere
update col.mappa_proposte p set col_id = g.col_id, esito = 'rango superiore', da_rivedere = true, motivo = 'caso speciale',
       nota = 'nome di specie ma descrizione del genere (migration 20261013100000): proposto il genere Agapanthus'
  from public.taxa g
 where p.vecchio_slug = 'agapanthus' and p.origine = 'rollback'
   and g.nome_scientifico = 'Agapanthus' and g.rango = 'genus' and g.stato = 'accepted';

\pset tuples_only on
\pset format unaligned
select 'proposte ' || count(*) || ', senza taxon ' || count(*) filter (where col_id is null and taxon_locale is null) from col.mappa_proposte;
select esito || ' ' || count(*) from col.mappa_proposte group by esito order by count(*) desc;
select 'da rivedere ' || count(*) filter (where da_rivedere) || ' (con piante ' || count(*) filter (where da_rivedere and piante > 0) || ')' from col.mappa_proposte;
select 'motivo ' || motivo || ' ' || count(*) from col.mappa_proposte where da_rivedere group by motivo order by count(*) desc;
select 'taxon COL da importare ' || count(distinct col_id) from col.mappa_proposte p
 where col_id is not null and not exists (select 1 from public.taxa t where t.col_id = p.col_id);
select 'taxon locali ' || count(distinct taxon_locale) from col.mappa_proposte where taxon_locale is not null;
```

- [ ] **Step 8: Eseguire l'abbinamento e rilanciare le prove**

```bash
python3 scripts/tassonomia/mappa_rollback_madri.py > "$F3/madri.tsv"
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_righe.sql < "$F3/madri.tsv"
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_esatti.sql
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_altri.sql
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_proposte.sql < "$F3/piante_specie.tsv"
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_mappa.sql; echo "uscita $?"
```

Expected, in circa un minuto:
- `madri estratte: 35`;
- `righe 15713 (specie 15678, rollback 35)`, `con corrispondenza esatta 14622`;
- in `mappa_esatti`: `righe 14622, senza taxon 0`, `esatto 12135`, `sinonimo 2084`, `ambiguo 273`, `variante 130`, `ambigui: omotipico 153, antenato comune 120`;
- in `mappa_altri`: `righe 1091` e la tabella dei metodi (forma 307, grex 213, genere superiore 209, ortografia 136, refuso 97…);
- in `mappa_proposte`: `proposte 15713, senza taxon 0`, `da rivedere 128 (con piante 2)`, `taxon COL da importare 406`, `taxon locali 8`;
- infine `NOTICE:  ABBINAMENTO CORRETTO: 15713 proposte, 128 da rivedere` e `uscita 0`.

- [ ] **Step 9: Commit**

```bash
chmod +x scripts/tassonomia/mappa_rollback_madri.py
git add scripts/tassonomia/prova_mappa.sql scripts/tassonomia/mappa_rollback_madri.py scripts/tassonomia/mappa_righe.sql \
        scripts/tassonomia/mappa_esatti.sql scripts/tassonomia/mappa_altri.sql scripts/tassonomia/mappa_proposte.sql
git commit -m "Tassonomia fase 3: abbinamento delle righe di specie ai taxon (copia locale) con le prove"
```

---

### Task 2: Revisione dei casi incerti con l'utente

**Files:**
- Create: `scripts/tassonomia/mappa_revisione.sql`
- Create: `scripts/tassonomia/mappa_revisione_pagina.py`
- Create: `scripts/tassonomia/mappa_decisioni.sql`
- Create: `scripts/tassonomia/dati/fase3_decisioni.tsv`

**Interfaces:**
- Consumes: `col.mappa_proposte` (Task 1).
- Produces:
  - `col.mappa_revisione`, con le colonne `numero`, `gruppo`, `vecchia_specie_id`, `vecchio_slug`, `vecchio_nome_scientifico`, `piante`, `esito`, `nota`, `proposta`, `accettato`, `alt_col_id`, `alternativa`, `alt_esito`;
  - `$F3/revisione.tsv` e `$F3/revisione.html`;
  - il file delle decisioni: TSV `numero`, `vecchio_slug`, `decisione`, dove la decisione è `si`, `no` oppure `col:<col_id>`;
  - `col.mappa_proposte` con `da_rivedere` falso dappertutto.

- [ ] **Step 1: Prova delle decisioni prima che lo script esista**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_decisioni.sql < /dev/null; echo "uscita $?"
```

Expected: `No such file or directory`, uscita diversa da 0.

- [ ] **Step 2: Scrivere l'elenco, la pagina e le decisioni**

`scripts/tassonomia/mappa_revisione.sql`:

```sql
-- Fase 3: elenco dei casi da rivedere (col.mappa_proposte con da_rivedere), numerato, con la proposta e l'alternativa
-- che vale se l'utente risponde «no»: il genere del nome (per i refusi e le piante), la famiglia scritta nella riga (per
-- i generi incerti), la specie (per agapanthus), altrimenti nessun taxon («non trovato»). Solo copia locale.
set statement_timeout = 0;
drop table if exists col.mappa_revisione;
create temp table genere_nostro as
select distinct on (p.vecchia_specie_id) p.vecchia_specie_id, u.id as col_id
  from col.mappa_proposte p join col.mappa_righe r on r.id = p.vecchia_specie_id
  join col.nome_uso u on lower(u.nome) = (col.parole(r.nome))[1] and u.rango = 'genus'
   and u.status in ('accepted', 'provisionally accepted') and u.regno = 'Plantae'
 where p.da_rivedere
 order by p.vecchia_specie_id, exists (select 1 from public.taxa t where t.col_id = u.id) desc, (u.status = 'accepted') desc, u.id;
create temp table famiglia_nostra as
select distinct on (p.vecchia_specie_id) p.vecchia_specie_id, coalesce(case when u.status = 'accepted' then u.id end, a.id) as col_id
  from col.mappa_proposte p join col.mappa_righe r on r.id = p.vecchia_specie_id
  join col.nome_uso u on u.nome = btrim(split_part(regexp_replace(coalesce(r.famiglia_botanica, ''), '\s+or\s+', '/', 'g'), '/', 1))
   and u.rango = 'family' and u.codice in ('botanical', '')
  left join col.nome_uso a on a.id = u.parent_id and u.status <> 'accepted' and a.rango = 'family' and a.status = 'accepted'
 where p.da_rivedere and coalesce(case when u.status = 'accepted' then u.id end, a.id) is not null
 order by p.vecchia_specie_id, (u.status = 'accepted') desc, u.id;

create table col.mappa_revisione as
select row_number() over (order by
         case p.motivo when 'pianta tua' then 1 when 'caso speciale' then 2 when 'fuori da Plantae' then 2
                       when 'refuso' then 3 when 'genere scritto male' then 4 when 'genere simile' then 4 else 5 end,
         p.vecchio_nome_scientifico, p.vecchio_slug) as numero,
       case p.motivo when 'pianta tua' then 'Le tue piante' when 'caso speciale' then 'Casi speciali'
                     when 'fuori da Plantae' then 'Casi speciali' when 'refuso' then 'Possibili refusi'
                     when 'genere scritto male' then 'Generi scritti male' when 'genere simile' then 'Generi scritti male'
                     else 'Generi incerti' end as gruppo,
       p.vecchia_specie_id, p.vecchio_slug, p.vecchio_nome_scientifico, p.piante, p.esito, p.nota,
       coalesce(u.nome || coalesce(' ' || u.autore, '') || ' (' || u.rango || case when u.status <> 'accepted' then ', ' || u.status else '' end || ')',
                p.taxon_locale || ' (taxon locale)') as proposta,
       acc.nome as accettato,
       case
         when p.vecchio_slug = 'agapanthus' and p.origine = 'rollback' then sp.col_id
         when p.motivo in ('refuso', 'pianta tua') and coalesce(u.rango, '') <> 'genus' then g.col_id
         when p.motivo in ('genere scritto male', 'genere simile', 'genere superiore', 'ibridi o gruppo', 'grex') then f.col_id
       end as alt_col_id
  from col.mappa_proposte p
  left join col.nome_uso u on u.id = p.col_id
  left join col.nome_uso acc on acc.id = u.parent_id and u.status not in ('accepted', 'provisionally accepted')
  left join genere_nostro g on g.vecchia_specie_id = p.vecchia_specie_id
  left join famiglia_nostra f on f.vecchia_specie_id = p.vecchia_specie_id
  left join (select t.col_id from public.taxa t where t.nome_scientifico = 'Agapanthus africanus' and t.stato = 'accepted') sp on true
 where p.da_rivedere;
alter table col.mappa_revisione add primary key (numero);
alter table col.mappa_revisione add column alternativa text, add column alt_esito text;
update col.mappa_revisione v set
  alternativa = coalesce((select u.nome || coalesce(' ' || u.autore, '') || ' (' || u.rango || ')' from col.nome_uso u where u.id = v.alt_col_id),
                         'nessun taxon: il nome resta non trovato'),
  alt_esito = case when v.alt_col_id is null then 'non trovato' else 'deciso dall''utente' end;

\pset tuples_only on
\pset format unaligned
select 'da rivedere ' || count(*) from col.mappa_revisione;
select gruppo || ' ' || count(*) from col.mappa_revisione group by gruppo order by min(numero);
```

`scripts/tassonomia/mappa_revisione_pagina.py`:

```python
#!/usr/bin/env python3
"""Fase 3: pagina HTML dell'elenco da rivedere (dal TSV di mappa_revisione.sh), da pubblicare come pagina privata.

Uno strumento interno di revisione: mostra nome della riga, proposta e alternativa; l'utente risponde in chat con le
sole eccezioni (numero e «no», oppure il nome giusto). Uso: python3 mappa_revisione_pagina.py revisione.tsv > revisione.html
"""
import csv
import html
import sys
from itertools import groupby

righe = list(csv.DictReader(open(sys.argv[1], encoding='utf-8'), delimiter='\t'))
e = html.escape
parti = []
for gruppo, casi in groupby(righe, key=lambda r: r['gruppo']):
    casi = list(casi)
    parti.append(f'<h2>{e(gruppo)} <span class="n">{len(casi)}</span></h2><ol class="casi">')
    for r in casi:
        acc = f' <span class="acc">oggi si chiama {e(r["accettato"])}</span>' if r['accettato'] else ''
        piante = f' <span class="piante">{r["piante"]} piante</span>' if r['piante'] not in ('', '0') else ''
        parti.append(
            f'<li value="{r["numero"]}"><div class="nome">{e(r["vecchio_nome_scientifico"])}{piante}</div>'
            f'<div class="prop">→ {e(r["proposta"])}{acc}</div>'
            f'<div class="alt">se no: {e(r["alternativa"])}</div></li>')
    parti.append('</ol>')
print(f"""<!doctype html>
<html lang="it"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Revisione abbinamenti</title>
<style>
:root {{ --sfondo: #faf7f2; --testo: #2b2b2b; --tenue: #6b6b6b; --linea: #e4dccf; --accento: #7a9e82; --oro: #b8912f; }}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{ --sfondo: #1d1f1d; --testo: #ece8e1; --tenue: #a39e95; --linea: #3a3d39; --accento: #9cc2a4; --oro: #e0b84a; }} }}
:root[data-theme="dark"] {{ --sfondo: #1d1f1d; --testo: #ece8e1; --tenue: #a39e95; --linea: #3a3d39; --accento: #9cc2a4; --oro: #e0b84a; }}
body {{ background: var(--sfondo); color: var(--testo); font: 16px/1.5 system-ui, sans-serif; margin: 0; padding: 16px; }}
main {{ max-width: 760px; margin: 0 auto; }}
h1 {{ font-size: 1.5rem; margin: 0 0 .5rem; }} h2 {{ font-size: 1.15rem; margin: 2rem 0 .5rem; color: var(--accento); }}
.n {{ color: var(--tenue); font-weight: normal; }} p {{ color: var(--tenue); }}
ol.casi {{ padding-left: 2.6rem; }} ol.casi li {{ padding: .5rem 0; border-bottom: 1px solid var(--linea); }}
.nome {{ font-style: italic; }} .prop {{ margin-left: .2rem; }} .alt {{ color: var(--tenue); font-size: .9rem; margin-left: .2rem; }}
.acc {{ color: var(--tenue); font-size: .9rem; }} .piante {{ color: var(--oro); font-style: normal; font-size: .85rem; margin-left: .4rem; }}
</style></head><body><main>
<h1>Revisione degli abbinamenti</h1>
<p>{len(righe)} casi incerti: per ognuno c'è già una proposta. Rispondi in chat solo con le eccezioni, per esempio
«12 no» (vale l'alternativa) o «12 è Celosia cristata». Tutto il resto viene confermato così com'è.</p>
{''.join(parti)}
</main></body></html>""")
```

`scripts/tassonomia/mappa_decisioni.sql`:

```sql
-- Fase 3: applica alle proposte (col.mappa_proposte, copia locale) le decisioni dell'utente sull'elenco da rivedere.
-- Standard input: TSV numero, vecchio_slug, decisione (si | no | col:<col_id di COL>), una riga per ogni caso di
-- col.mappa_revisione. si = proposta confermata (esito invariato, nota con la conferma); no = vale l'alternativa;
-- col:<id> = il nome indicato dall'utente. Si rifiuta se manca una decisione o se un numero non corrisponde allo slug.
-- Vale solo per le proposte ancora da rivedere: per cambiare una decisione si rigenerano proposte ed elenco.
set statement_timeout = 0;
create temp table decisioni (numero int primary key, vecchio_slug text not null, decisione text not null);
\copy decisioni from pstdin with (format csv, delimiter E'\t', header)
do $$
declare n bigint;
begin
  select count(*) into n from col.mappa_revisione v left join decisioni d on d.numero = v.numero where d.numero is null;
  if n > 0 then raise exception 'decisioni mancanti: %', n; end if;
  select count(*) into n from decisioni d left join col.mappa_revisione v on v.numero = d.numero and v.vecchio_slug = d.vecchio_slug
   where v.numero is null;
  if n > 0 then raise exception 'decisioni che non corrispondono all''elenco (numero o slug): %', n; end if;
  select count(*) into n from decisioni where decisione !~ '^(si|no|col:[A-Za-z0-9]+)$';
  if n > 0 then raise exception 'decisioni non valide: %', n; end if;
  select count(*) into n from decisioni d where d.decisione like 'col:%'
     and not exists (select 1 from col.nome_uso u where u.id = substr(d.decisione, 5));
  if n > 0 then raise exception 'col_id indicati che non esistono in COL: %', n; end if;
end $$;
update col.mappa_proposte p set
  nota = p.nota || ' — confermato dall''utente il ' || to_char(current_date, 'DD/MM/YYYY'), da_rivedere = false,
  -- una proposta per un nome «non trovato» (Cetraria islandica fuori da Plantae), confermata, è una decisione dell'utente
  esito = case when p.esito = 'non trovato' and p.col_id is not null then 'deciso dall''utente' else p.esito end
  from col.mappa_revisione v join decisioni d on d.numero = v.numero
 where p.vecchia_specie_id = v.vecchia_specie_id and p.da_rivedere and d.decisione = 'si';
update col.mappa_proposte p set
  col_id = v.alt_col_id, taxon_locale = null, famiglia_locale = null, esito = v.alt_esito, da_rivedere = false,
  nota = 'proposta «' || v.proposta || '» respinta dall''utente il ' || to_char(current_date, 'DD/MM/YYYY') || ': ' || v.alternativa
  from col.mappa_revisione v join decisioni d on d.numero = v.numero
 where p.vecchia_specie_id = v.vecchia_specie_id and p.da_rivedere and d.decisione = 'no';
update col.mappa_proposte p set
  col_id = substr(d.decisione, 5), taxon_locale = null, famiglia_locale = null, esito = 'deciso dall''utente', da_rivedere = false,
  nota = 'indicato dall''utente il ' || to_char(current_date, 'DD/MM/YYYY') || ': ' || u.nome || coalesce(' ' || u.autore, '')
  from col.mappa_revisione v join decisioni d on d.numero = v.numero join col.nome_uso u on u.id = substr(d.decisione, 5)
 where p.vecchia_specie_id = v.vecchia_specie_id and p.da_rivedere and d.decisione like 'col:%';
\pset tuples_only on
\pset format unaligned
select 'decisioni ' || count(*) || ' (si ' || count(*) filter (where decisione = 'si') || ', no ' || count(*) filter (where decisione = 'no')
       || ', nome indicato ' || count(*) filter (where decisione like 'col:%') || ')' from decisioni;
select 'ancora da rivedere ' || count(*) from col.mappa_proposte where da_rivedere;
```

- [ ] **Step 3: Generare l'elenco e provare i rifiuti delle decisioni**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_revisione.sql
$PG/psql "$COPIA" -X -q -c "copy (select numero, gruppo, vecchio_slug, vecchio_nome_scientifico, piante, proposta, coalesce(accettato, '') as accettato, alternativa from col.mappa_revisione order by numero) to stdout with (format csv, delimiter E'\t', header)" > "$F3/revisione.tsv"
python3 scripts/tassonomia/mappa_revisione_pagina.py "$F3/revisione.tsv" > "$F3/revisione.html"
awk -F'\t' 'BEGIN { OFS = "\t"; print "numero", "vecchio_slug", "decisione" } NR > 1 { print $1, $3, "si" }' "$F3/revisione.tsv" > "$SCRATCH/decisioni_si.tsv"
awk -F'\t' 'BEGIN { OFS = "\t" } NR == 2 { $3 = "col:ZZZZZZZZ" } { print }' "$SCRATCH/decisioni_si.tsv" > "$SCRATCH/decisioni_codice.tsv"
awk -F'\t' 'BEGIN { OFS = "\t" } NR == 2 { $2 = "slug-sbagliato" } { print }' "$SCRATCH/decisioni_si.tsv" > "$SCRATCH/decisioni_slug.tsv"
head -n 10 "$SCRATCH/decisioni_si.tsv" > "$SCRATCH/decisioni_poche.tsv"
for f in codice slug poche; do
  $PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_decisioni.sql < "$SCRATCH/decisioni_$f.tsv" 2>&1 | grep -o 'ERROR:.*'
done
$PG/psql "$COPIA" -X -qAt -c "select 'ancora da rivedere ' || count(*) from col.mappa_proposte where da_rivedere"
```

Expected:
- `da rivedere 128`, con i gruppi Le tue piante 2, Casi speciali 2, Possibili refusi 97, Generi scritti male 17, Generi incerti 10;
- i tre rifiuti: `ERROR:  col_id indicati che non esistono in COL: 1`, `ERROR:  decisioni che non corrispondono all'elenco (numero o slug): 1`, `ERROR:  decisioni mancanti: 119`;
- `ancora da rivedere 128`: nessuna decisione è stata applicata.

- [ ] **Step 4: Pubblicare la pagina e chiedere all'utente**

1. Caricare la skill `artifact-design` e pubblicare `$F3/revisione.html` come Artifact (icona `list`), in privato.
2. Dare il link all'utente. Spiegare in italiano semplice che ci sono 128 casi, ognuno con una proposta già pronta, e che basta rispondere con le eccezioni: «12 no» per applicare l'alternativa, «12 è Celosia cristata» per indicare il nome giusto, oppure «tutte ok».
3. Fermarsi fino alla risposta.

- [ ] **Step 5: Scrivere il file delle decisioni e applicarlo**

Ogni nome indicato dall'utente va cercato in `col.nome_uso`, tra gli accettati in Plantae, con `col.k1(col.parole(...))`. Se il nome non è certo, chiedere all'utente prima di scriverlo come `col:<id>`. Le decisioni diverse da `si` vanno annotate nel registro.

```bash
mkdir -p scripts/tassonomia/dati
cp "$SCRATCH/decisioni_si.tsv" scripts/tassonomia/dati/fase3_decisioni.tsv
```

Poi modificare in `scripts/tassonomia/dati/fase3_decisioni.tsv` solo le righe indicate dall'utente, con `no` o `col:<id>`, e applicare:

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_decisioni.sql < scripts/tassonomia/dati/fase3_decisioni.tsv
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/mappa_decisioni.sql < scripts/tassonomia/dati/fase3_decisioni.tsv
$PG/psql "$COPIA" -X -qAt -c "select count(*) from col.mappa_proposte where nota like '%confermato dall''utente%confermato dall''utente%'"
```

Expected:
- `decisioni 128 (si …, no …, nome indicato …)` e `ancora da rivedere 0`, per due volte: il secondo giro non cambia niente;
- poi `0`: nessuna conferma doppia.

- [ ] **Step 6: Commit**

```bash
chmod +x scripts/tassonomia/mappa_revisione_pagina.py
git add scripts/tassonomia/mappa_revisione.sql scripts/tassonomia/mappa_revisione_pagina.py scripts/tassonomia/mappa_decisioni.sql \
        scripts/tassonomia/dati/fase3_decisioni.tsv
git commit -m "Tassonomia fase 3: revisione dei casi incerti con l'utente e decisioni"
```

---

### Task 3: Esportazione, caricamento, verifica e rollback sulla copia locale

**Files:**
- Create: `scripts/tassonomia/prova_fase3.sh`
- Create: `scripts/tassonomia/mappa_nuovi_taxa.sql`
- Create: `scripts/tassonomia/mappa_esporta.sh`
- Modify: `scripts/tassonomia/carica_taxa.sh` (intero file)
- Modify: `scripts/tassonomia/verifica_fase2.sql` (intero file)
- Create: `scripts/tassonomia/carica_mappa.sh`
- Create: `scripts/tassonomia/verifica_fase3.sql`
- Create: `scripts/tassonomia/rollback_fase3.sql`

**Interfaces:**
- Consumes: `col.mappa_proposte` con le decisioni (Task 2); `impronta_specie.sql`, `controlli_spazio.sql` e `rollback_fase2.sql` (fasi 1b e 2).
- Produces:
  - `mappa_esporta.sh URL_COPIA CARTELLA` scrive:
    - in `CARTELLA/taxa`: `lotto_01.csv`, `manifest.tsv`, `versione.txt`, `base.txt` e `regni.txt`;
    - in `CARTELLA/mappa`: `locali.csv`, `mappa.csv` e `manifest.tsv`;
  - `carica_taxa.sh` accetta `base.txt` e `regni.txt`, facoltativi;
  - `carica_mappa.sh URL CARTELLA_MAPPA CARTELLA_MISURE`: ultima riga `CARICAMENTO MAPPA OK`;
  - `prova_fase3.sh URL_COPIA CARTELLA_ESPORTA CARTELLA`: ultima riga `PROVE FASE 3 OK`.

- [ ] **Step 1: Scrivere le prove**

`scripts/tassonomia/prova_fase3.sh`:

```bash
#!/usr/bin/env bash
# Prove della fase 3 (taxon in più e mappa_specie) sulla copia locale: rifiuti, file alterato, ordine sbagliato,
# caricamento, rilancio, rollback rifiutato ed eseguito, nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase3.sh URL_COPIA CARTELLA_ESPORTA CARTELLA      (CARTELLA nuova a ogni giro)
#   CARTELLA_ESPORTA = cartella scritta da mappa_esporta.sh (sottocartelle taxa e mappa).
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
conta() { "${PSQL[@]}" -tAc "select (select count(*) from public.mappa_specie) || ' ' || count(*) filter (where origine = 'col') || ' ' || count(*) filter (where origine = 'locale') from public.taxa"; }
BASE=$(cat "$E/taxa/base.txt")
NUOVI=$(awk -F'\t' '{ s += $2 } END { print s }' "$E/taxa/manifest.tsv")
RIGHE=$(awk -F'\t' '$1 == "mappa.csv" { print $2 }' "$E/mappa/manifest.tsv")
LOCALI=$(awk -F'\t' '$1 == "locali.csv" { print $2 }' "$E/mappa/manifest.tsv")
VUOTO="0 $BASE 0"
PIENO="$RIGHE $((BASE + NUOVI)) $LOCALI"
[ "$(conta)" = "$VUOTO" ] || fallita preparazione "la copia non è nello stato della fase 2 ($(conta)): prima rollback_fase3.sql"
carica() {  # carica CARTELLA PROVA: taxon in più e poi mappa, con log in OUT
  bash $D/carica_taxa.sh "$URL" "$E/taxa" "$OUT/$1_taxa" > "$OUT/$1_taxa.log" 2>&1 || fallita "$2" "carica_taxa: $(tail -3 "$OUT/$1_taxa.log")"
  bash $D/carica_mappa.sh "$URL" "$E/mappa" "$OUT/$1_mappa" > "$OUT/$1_mappa.log" 2>&1 || fallita "$2" "carica_mappa: $(tail -3 "$OUT/$1_mappa.log")"
  [ "$(tail -1 "$OUT/$1_mappa.log")" = 'CARICAMENTO MAPPA OK' ] || fallita "$2" "$(tail -3 "$OUT/$1_mappa.log")"
}

# 1. Rifiuti, prima di qualsiasi connessione.
out=$(bash $D/carica_mappa.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$E/mappa" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_mappa.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$E/mappa" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. File alterato: rifiuto prima di scrivere.
cp -R "$E/mappa" "$OUT/mappa_alterata"
printf 'x' >> "$OUT/mappa_alterata/mappa.csv"
out=$(bash $D/carica_mappa.sh "$URL" "$OUT/mappa_alterata" "$OUT/r3" 2>&1) && fallita alterato "nessun errore"
grep -qF 'RIFIUTATO: mappa.csv diverso da quello del manifesto' <<<"$out" || fallita alterato "$out"
[ "$(conta)" = "$VUOTO" ] || fallita alterato "caricato qualcosa: $(conta)"
echo "PROVA alterato OK"

# 3. Ordine sbagliato (mappa prima dei taxon nuovi): la mappa non entra (chiave esterna), i taxon locali sì.
out=$(bash $D/carica_mappa.sh "$URL" "$E/mappa" "$OUT/r4" 2>&1) && fallita ordine "nessun errore"
grep -qF 'violates foreign key constraint' <<<"$out" || fallita ordine "$out"
[ "$(conta)" = "0 $BASE $LOCALI" ] || fallita ordine "stato inatteso: $(conta)"
echo "PROVA ordine OK"

# 4. Caricamento completo (i taxon locali già presenti vengono saltati).
carica r5 caricamento
grep -qF 'taxon locali già caricati' "$OUT/r5_mappa/tempi.txt" || fallita caricamento "taxon locali ricaricati"
[ "$(conta)" = "$PIENO" ] || fallita caricamento "stato inatteso: $(conta) invece di $PIENO"
echo "PROVA caricamento OK"

# 5. Rilancio: tutto saltato, stato invariato.
carica r6 rilancio
grep -qF 'lotto_01.csv già caricato' "$OUT/r6_taxa/tempi.txt" || fallita rilancio "lotto dei taxon ricaricato"
grep -qF 'mappa_specie già caricata' "$OUT/r6_mappa/tempi.txt" || fallita rilancio "mappa ricaricata"
[ "$(conta)" = "$PIENO" ] || fallita rilancio "stato cambiato: $(conta)"
echo "PROVA rilancio OK"

# 6. Rollback: rifiutato se la fase 4 ha già dati (una cultivar in una transazione mai confermata), poi eseguito e
#    seguito da un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' \
        -c "insert into public.cultivar (slug, taxon_id, epiteto, fonti) select 'prova', id, 'Prova', '{prova}' from public.taxa limit 1" \
        -f $D/rollback_fase3.sql 2>&1) && fallita rollback "rollback accettato con la fase 4 iniziata"
grep -qF 'Rollback fase 3 rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback "un rollback rifiutato ha tolto righe: $(conta)"
"${PSQL[@]}" -1 -f $D/rollback_fase3.sql
"${PSQL[@]}" -c 'vacuum full public.mappa_specie' -c 'vacuum full public.taxa'
[ "$(conta)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(conta) invece di $VUOTO"
carica r7 rollback
[ "$(conta)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo caricamento: $(conta)"
echo "PROVA rollback OK"
echo "PROVE FASE 3 OK"
```

- [ ] **Step 2: Lanciarle e vederle fallire**

```bash
bash scripts/tassonomia/prova_fase3.sh "$COPIA" "$F3/esporta" "$SCRATCH/prove_fase3_0" > "$SCRATCH/prove_fase3_0.log" 2>&1; echo "uscita $?"; tail -2 "$SCRATCH/prove_fase3_0.log"
```

Expected: uscita diversa da 0 con `cat: …/esporta/taxa/base.txt: No such file or directory`, perché l'esportazione non esiste ancora.

- [ ] **Step 3: Scrivere l'esportazione**

`scripts/tassonomia/mappa_nuovi_taxa.sql`:

```sql
-- Fase 3: taxon da aggiungere a public.taxa per le proposte decise (copia locale). Dai nomi proposti che non sono ancora
-- in taxa: i loro accettati, la catena dei padri fino a un taxon già presente, i sinonimi degli accettati e dei generi
-- nuovi (stesse regole della fase 2, niente segnaposto "Genere spp"). Poi i taxon locali (notogeneri assenti da COL)
-- sotto la famiglia della riga, che deve essere un taxon accettato già in taxa.
set statement_timeout = 0;
drop table if exists col.mappa_nuovi, col.mappa_locali;
create temp table semi as
select distinct p.col_id as id from col.mappa_proposte p
 where p.col_id is not null and not exists (select 1 from public.taxa t where t.col_id = p.col_id);
create temp table acc as
select distinct case when u.status in ('accepted', 'provisionally accepted') then u.id else u.parent_id end as id
  from semi s join col.nome_uso u on u.id = s.id;
create temp table catena as
with recursive c(id) as (
  select id from acc
  union
  select u.parent_id from col.nome_uso u join c on u.id = c.id
   where u.parent_id <> '' and not exists (select 1 from public.taxa t where t.col_id = u.id))
select id from c;
create temp table sin as
select u.id from col.nome_uso u
 where u.status in ('synonym', 'ambiguous synonym') and u.nome !~ '\sspp?\.?\s*$'
   and u.parent_id in (select id from acc
                       union select c.id from catena c join col.nome_uso g on g.id = c.id where g.rango = 'genus');
create table col.mappa_nuovi (col_id text primary key, id uuid not null unique default gen_random_uuid());
insert into col.mappa_nuovi (col_id)
  select id from semi union select id from catena union select id from sin
  except select col_id from public.taxa where col_id is not null;

create table col.mappa_locali (nome text primary key, id uuid not null unique default gen_random_uuid(), padre_id uuid);
insert into col.mappa_locali (nome, padre_id)
  select p.taxon_locale, (select min(f.id::text)::uuid from public.taxa f
                           where f.nome_scientifico = min(p.famiglia_locale) and f.rango = 'family' and f.stato = 'accepted')
    from col.mappa_proposte p where p.taxon_locale is not null group by p.taxon_locale;
do $$
declare n bigint;
begin
  select count(*) into n from col.mappa_locali where padre_id is null;
  if n > 0 then raise exception 'taxon locali senza una famiglia accettata in taxa: %', n; end if;
  -- chiusura: il padre di ogni nuovo accettato e l'accettato di ogni nuovo sinonimo sono in taxa o tra i nuovi
  select count(*) into n from col.mappa_nuovi m join col.nome_uso u on u.id = m.col_id
   where u.parent_id <> '' and not exists (select 1 from col.mappa_nuovi x where x.col_id = u.parent_id)
     and not exists (select 1 from public.taxa t where t.col_id = u.parent_id);
  if n > 0 then raise exception 'nuovi taxon con il padre o l''accettato mancante: %', n; end if;
end $$;
\pset tuples_only on
\pset format unaligned
select 'nuovi taxon COL ' || count(*) from col.mappa_nuovi;
select 'taxon locali ' || count(*) from col.mappa_locali;
```

`scripts/tassonomia/mappa_esporta.sh`:

```bash
#!/usr/bin/env bash
# Fase 3: dalle proposte decise (col.mappa_proposte, copia locale) scrive i file da caricare sul database reale.
# - CARTELLA/taxa: i taxon di COL che mancano in public.taxa (mappa_nuovi_taxa.sql) in un lotto per carica_taxa.sh, con
#   base.txt (righe di COL già in taxa, che restano) e regni.txt (regni ammessi dalla verifica);
# - CARTELLA/mappa: locali.csv (taxon locali) e mappa.csv (una riga per ogni riga da abbinare, valori definitivi), con il
#   manifesto per carica_mappa.sh. Le chiavi sono quelle di public.taxa della copia, identica al reale (stessi lotti).
# Uso: bash scripts/tassonomia/mappa_esporta.sh URL_COPIA CARTELLA
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I file si preparano solo dalla copia locale" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i file provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
aperti=$("${PSQL[@]}" -tAc 'select count(*) from col.mappa_proposte where da_rivedere')
[ "$aperti" = 0 ] || { echo "Ci sono ancora $aperti casi da rivedere: prima mappa_decisioni.sql" >&2; exit 1; }
VERSIONE=$("${PSQL[@]}" -tAc "select string_agg(distinct versione_col, ',') from public.taxa where origine = 'col'")
[[ $VERSIONE =~ ^COL[0-9.]+\ XR$ ]] || { echo "Versione di COL in taxa inattesa: $VERSIONE" >&2; exit 1; }
"${PSQL[@]}" -f scripts/tassonomia/mappa_nuovi_taxa.sql
mkdir -p "$DIR/taxa" "$DIR/mappa"

manifesto() {  # manifesto CARTELLA FILE PRIMO_CAMPO_DA_REGISTRARE(0/1)
  local righe primo=""
  righe=$(( $(wc -l < "$1/$2") - 1 ))
  [ "$3" = 1 ] && primo=$(sed -n 2p "$1/$2" | cut -d, -f3)
  printf '%s\t%s\t%s\t%s\n' "$2" "$righe" "$(shasum -a 256 "$1/$2" | cut -d' ' -f1)" "$primo" >> "$1/manifest.tsv"
}

# taxon di COL nuovi: un solo lotto, con la nota che li distingue (serve al rollback della fase 3)
echo "$VERSIONE" > "$DIR/taxa/versione.txt"
"${PSQL[@]}" -tAc "select count(*) from public.taxa where origine = 'col'" > "$DIR/taxa/base.txt"
"${PSQL[@]}" -tAc "select string_agg(distinct r, ',' order by r) from (select 'Plantae' as r union
                   select coalesce(nullif(u.regno, ''), case when u.rango = 'kingdom' then u.nome end)
                     from col.mappa_nuovi m join col.nome_uso u on u.id = m.col_id
                    where u.status in ('accepted', 'provisionally accepted')) x where r is not null" > "$DIR/taxa/regni.txt"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select m.id, 'col' as origine, m.col_id, '$VERSIONE' as versione_col, u.rango, u.nome as nome_scientifico,
               nullif(u.autore, '') as autore, nullif(split_part(lower(u.notho), ',', 1), '') as notho, u.status as stato,
               case when u.status in ('synonym', 'ambiguous synonym', 'misapplied') then coalesce(pn.id, pt.id) end as accettato_id,
               case when u.status in ('accepted', 'provisionally accepted') then coalesce(pn.id, pt.id) end as padre_id,
               'importato nella fase 3 (abbinamento)' as nota
          from col.mappa_nuovi m join col.nome_uso u on u.id = m.col_id
          left join col.mappa_nuovi pn on pn.col_id = nullif(u.parent_id, '')
          left join public.taxa pt on pt.col_id = nullif(u.parent_id, '')
         order by m.col_id) to stdout with (format csv, header)" > "$DIR/taxa/lotto_01.csv"
manifesto "$DIR/taxa" lotto_01.csv 1

# taxon locali e mappa
"${PSQL[@]}" -c "
  copy (select id, 'locale' as origine, 'genus' as rango, nome as nome_scientifico, 'generic' as notho, 'accepted' as stato,
               padre_id, 'notogenere assente da COL (fase 3)' as nota
          from col.mappa_locali order by nome) to stdout with (format csv, header)" > "$DIR/mappa/locali.csv"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "
  copy (select p.vecchia_specie_id, p.vecchio_slug, p.vecchio_nome_scientifico, p.origine,
               coalesce(t.id, n.id, l.id) as taxon_id, p.esito, p.nota
          from col.mappa_proposte p
          left join public.taxa t on t.col_id = p.col_id
          left join col.mappa_nuovi n on n.col_id = p.col_id
          left join col.mappa_locali l on l.nome = p.taxon_locale
         order by p.vecchio_slug, p.origine) to stdout with (format csv, header)" > "$DIR/mappa/mappa.csv"
manifesto "$DIR/mappa" locali.csv 0
manifesto "$DIR/mappa" mappa.csv 0
senza=$(python3 -c 'import csv, sys; print(sum(1 for r in csv.DictReader(open(sys.argv[1], encoding="utf-8")) if not r["taxon_id"] and r["esito"] != "non trovato"))' "$DIR/mappa/mappa.csv")
[ "$senza" = 0 ] || { echo "Righe di mappa senza taxon e con un esito diverso da 'non trovato': $senza" >&2; exit 1; }
cut -f1,2 "$DIR/taxa/manifest.tsv" "$DIR/mappa/manifest.tsv"
echo "base $(cat "$DIR/taxa/base.txt"), regni $(cat "$DIR/taxa/regni.txt")"
```

- [ ] **Step 4: Estendere il caricamento e la verifica dei taxon ai lotti aggiuntivi**

Sostituire l'intero `scripts/tassonomia/carica_taxa.sh` con:

```bash
#!/usr/bin/env bash
# Fase 2 del modello tassonomico: carica in public.taxa i lotti preparati da col_esporta_lotti.sh, uno per transazione.
# Regole sullo spazio (specifica, "Decisioni sullo spazio", punto 5):
# - prima di ogni passo controlla la somma dei database e il WAL;
# - tra un lotto e l'altro fa una pausa (10 minuti sul reale, perché il WAL venga riciclato);
# - i 3 indici secondari di taxa si tolgono prima e si ricreano dopo.
# Si può rilanciare dopo un'interruzione: ogni lotto è una transazione (c'è tutto o niente) e quelli già caricati
# vengono saltati. Le altre tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Facoltativi nella cartella dei lotti (fase 3, lotti che si aggiungono a taxa già caricata): base.txt = righe di COL già
# in taxa che restano (la verifica attende base + righe dei lotti; con base > 0 gli indici restano, per poche righe
# costa meno tenerli che ricrearli); regni.txt = regni ammessi dalla verifica, separati da virgole (predefinito Plantae).
# Le colonne del COPY sono quelle dell'intestazione del lotto.
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
BASE=0
[ ! -f "$LOTTI/base.txt" ] || BASE=$(cat "$LOTTI/base.txt")
[[ $BASE =~ ^[0-9]+$ ]] || { echo "RIFIUTATO: base.txt non valido" >&2; exit 1; }
REGNI=Plantae
[ ! -f "$LOTTI/regni.txt" ] || REGNI=$(cat "$LOTTI/regni.txt")
[[ $REGNI =~ ^[A-Z][a-z]+(,[A-Z][a-z]+)*$ ]] || { echo "RIFIUTATO: regni.txt non valido" >&2; exit 1; }
ATTESE=$(( BASE + $(awk -F'\t' '{ s += $2 } END { print s }' "$LOTTI/manifest.tsv") ))
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
if [ "$da_caricare" -gt 0 ] && [ "$BASE" = 0 ]; then
  tempo "tolgo gli indici secondari di taxa ($da_caricare lotti da caricare)"
  "${PSQL[@]}" -c 'drop index if exists public.taxa_padre_id_idx, public.taxa_accettato_id_idx, public.taxa_nome_scientifico_trgm_idx'
fi

# 3. Un lotto per transazione; il conteggio si controlla dentro la transazione, prima del commit.
while IFS=$'\t' read -r file righe sha primo <&3; do
  if caricato "$primo"; then tempo "$file già caricato"; continue; fi
  pausa
  controlla "$file"
  colonne=$(head -1 "$LOTTI/$file")
  [[ ,$colonne, =~ ^(,(id|origine|col_id|versione_col|rango|nome_scientifico|autore|notho|stato|accettato_id|padre_id|nota))+,$ ]] \
    || { echo "RIFIUTATO: colonne inattese in $file" >&2; exit 1; }
  prima=$("${PSQL[@]}" -tAc 'select count(*) from public.taxa')
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "$file: carico $righe righe"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.taxa ($colonne) from stdin with (format csv, header)" \
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
"${PSQL[@]}" -v righe_attese="$ATTESE" -v versione="$VERSIONE" -v regni_ammessi="$REGNI" -f $D/verifica_fase2.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO TAXA OK"
```

Sostituire l'intero `scripts/tassonomia/verifica_fase2.sql` con:

```sql
-- Fase 2: controllo di public.taxa dopo il caricamento di COL XR. Sola lettura.
-- Variabili psql: righe_attese (righe di COL attese in taxa) e versione (es. COL26.9 XR); facoltativa regni_ammessi,
-- regni separati da virgole (predefinito Plantae; nella fase 3 anche Fungi se l'utente ha accettato Cetraria islandica).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_attese=N -v versione='COL26.9 XR' -f scripts/tassonomia/verifica_fase2.sql
\if :{?regni_ammessi}
\else
  \set regni_ammessi Plantae
\endif
select set_config('fase2.righe_attese', :'righe_attese', false), set_config('fase2.versione', :'versione', false),
       set_config('fase2.regni', :'regni_ammessi', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase2.righe_attese')::bigint;
  versione text := current_setting('fase2.versione');
  regni text[] := string_to_array(current_setting('fase2.regni'), ',');
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
  -- solo i regni ammessi, Plantae compreso, e ogni accettato sotto il regno ci arriva risalendo i padri
  select count(*) into n from public.taxa where rango = 'kingdom' and nome_scientifico <> all (regni);
  if n > 0 or not exists (select 1 from public.taxa where rango = 'kingdom' and nome_scientifico = 'Plantae') then
    raise exception 'regni in taxa fuori da quelli ammessi (%): %', array_to_string(regni, ', '), n;
  end if;
  with recursive su(id, partenza, nome, rango) as (
    select id, id, nome_scientifico, rango from public.taxa where stato in ('accepted', 'provisionally accepted')
    union all
    select p.id, su.partenza, p.nome_scientifico, p.rango
      from su join public.taxa t on t.id = su.id join public.taxa p on p.id = t.padre_id),
  in_plantae as (select distinct partenza from su where rango = 'kingdom' and nome = any (regni))
  select count(*) into n from public.taxa t left join in_plantae b on b.partenza = t.id
   where t.stato in ('accepted', 'provisionally accepted') and t.rango not in ('domain', 'kingdom') and b.partenza is null;
  if n > 0 then raise exception 'taxon accettati fuori dai regni ammessi: %', n; end if;
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

- [ ] **Step 5: Scrivere il caricamento della mappa, la verifica e il rollback**

`scripts/tassonomia/carica_mappa.sh`:

```bash
#!/usr/bin/env bash
# Fase 3 del modello tassonomico: carica i taxon locali (locali.csv) e public.mappa_specie (mappa.csv) preparati da
# mappa_esporta.sh, ciascuno in una transazione, con le righe già definitive (nessun aggiornamento: specifica, "Decisioni
# sullo spazio", punto 5). Va lanciato dopo carica_taxa.sh sui taxon nuovi della fase 3: ogni taxon_id di mappa.csv deve
# già esistere in taxa o tra i taxon locali. Si può rilanciare: un passo già fatto viene saltato, uno fatto a metà non
# esiste (transazione). Le altre tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_mappa.sh URL CARTELLA_MAPPA CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 400 MB di database, 300 MB di WAL.
# Uscita 0 e ultima riga CARICAMENTO MAPPA OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; MAPPA=${2:?manca CARTELLA_MAPPA}; OUT=${3:?manca CARTELLA_MISURE}
D=scripts/tassonomia
if [[ $URL == *supabase* ]]; then
  [[ $URL != *:6543/* ]] || { echo "RIFIUTATO: serve la porta 5432 (modalità sessione), non la 6543" >&2; exit 1; }
  [[ ${CONFERMO_CARICAMENTO_REALE:-} == si ]] || { echo "RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si" >&2; exit 1; }
  SOGLIA_MB=400; SOGLIA_WAL_MB=300
else
  SOGLIA_MB=${SOGLIA_MB:-100000}; SOGLIA_WAL_MB=${SOGLIA_WAL_MB:-100000}
fi
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
mkdir -p "$OUT"
tempo() { echo "$(date +%T) $1" >> "$OUT/tempi.txt"; }
controlla() {
  "${PSQL[@]}" -v soglia_mb="$SOGLIA_MB" -v soglia_wal_mb="$SOGLIA_WAL_MB" -f $D/controlli_spazio.sql > "$OUT/controlli_$1.txt" \
    || { cat "$OUT/controlli_$1.txt" >&2; echo "FERMATO: spazio insufficiente prima di $1; in questo passo non è stato caricato niente" >&2; exit 1; }
}

# 1. I file sono quelli provati (sha256 del manifesto).
for f in locali.csv mappa.csv; do
  riga=$(awk -F'\t' -v f="$f" '$1 == f' "$MAPPA/manifest.tsv")
  [ -n "$riga" ] || { echo "RIFIUTATO: $f non è nel manifesto" >&2; exit 1; }
  [ "$(shasum -a 256 "$MAPPA/$f" | cut -d' ' -f1)" = "$(cut -f3 <<<"$riga")" ] \
    || { echo "RIFIUTATO: $f diverso da quello del manifesto" >&2; exit 1; }
done
LOCALI=$(awk -F'\t' '$1 == "locali.csv" { print $2 }' "$MAPPA/manifest.tsv")
RIGHE=$(awk -F'\t' '$1 == "mappa.csv" { print $2 }' "$MAPPA/manifest.tsv")
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Taxon locali: tutti o nessuno.
presenti=$("${PSQL[@]}" -tAc "select count(*) from public.taxa where origine = 'locale' and nota = 'notogenere assente da COL (fase 3)'")
if [ "$presenti" = "$LOCALI" ]; then
  tempo "taxon locali già caricati"
elif [ "$presenti" = 0 ]; then
  tempo "carico $LOCALI taxon locali"
  "${PSQL[@]}" -1 -c "copy public.taxa ($(head -1 "$MAPPA/locali.csv")) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.taxa where origine = 'locale') <> $LOCALI then raise exception 'taxon locali incompleti'; end if; end \$\$" \
    < "$MAPPA/locali.csv"
else
  echo "RIFIUTATO: in taxa ci sono $presenti taxon locali della fase 3 invece di 0 o $LOCALI" >&2; exit 1
fi

# 3. mappa_specie: vuota -> si carica; già completa -> si salta; altrimenti rifiuto.
presenti=$("${PSQL[@]}" -tAc 'select count(*) from public.mappa_specie')
if [ "$presenti" = "$RIGHE" ]; then
  tempo "mappa_specie già caricata"
elif [ "$presenti" = 0 ]; then
  controlla mappa
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "carico $RIGHE righe di mappa_specie"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.mappa_specie ($(head -1 "$MAPPA/mappa.csv")) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.mappa_specie) <> $RIGHE then raise exception 'mappa_specie incompleta'; end if; end \$\$" \
    < "$MAPPA/mappa.csv"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "mappa_specie caricata, WAL $wal MB"
else
  echo "RIFIUTATO: mappa_specie contiene $presenti righe invece di 0 o $RIGHE" >&2; exit 1
fi
"${PSQL[@]}" -c 'analyze public.mappa_specie'

# 4. specie invariata, mappa corretta, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_mappa="$RIGHE" -v righe_locali="$LOCALI" -f $D/verifica_fase3.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO MAPPA OK"
```

`scripts/tassonomia/verifica_fase3.sql`:

```sql
-- Fase 3: controllo di public.mappa_specie e dei taxon locali dopo il caricamento. Sola lettura.
-- Variabili psql: righe_mappa (righe di mappa.csv) e righe_locali (righe di locali.csv).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_mappa=N -v righe_locali=M -f scripts/tassonomia/verifica_fase3.sql
select set_config('fase3.righe_mappa', :'righe_mappa', false), set_config('fase3.righe_locali', :'righe_locali', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase3.righe_mappa')::bigint;
  locali bigint := current_setting('fase3.righe_locali')::bigint;
  n bigint;
begin
  select count(*) into n from public.mappa_specie;
  if n <> attese then raise exception 'mappa_specie: % righe, attese %', n, attese; end if;
  -- una riga per ogni riga non cultivar di specie (senza apici e senza madre), e nessuna per le cultivar
  select count(*) into n from public.specie s
   where s.nome_scientifico !~ '''' and s.specie_padre_id is null
     and not exists (select 1 from public.mappa_specie m where m.vecchia_specie_id = s.id and m.origine = 'specie');
  if n > 0 then raise exception 'righe non cultivar di specie senza riga di mappa: %', n; end if;
  select count(*) into n from public.mappa_specie m left join public.specie s on s.id = m.vecchia_specie_id
   where m.origine = 'specie' and (s.id is null or s.nome_scientifico ~ '''' or s.specie_padre_id is not null
                                   or s.slug <> m.vecchio_slug or s.nome_scientifico <> m.vecchio_nome_scientifico);
  if n > 0 then raise exception 'righe di mappa che non corrispondono a una riga non cultivar di specie: %', n; end if;
  -- le righe recuperate dai rollback non esistono più in specie
  select count(*) into n from public.mappa_specie m join public.specie s on s.id = m.vecchia_specie_id or s.slug = m.vecchio_slug
   where m.origine = 'rollback';
  if n > 0 then raise exception 'righe da rollback ancora presenti in specie: %', n; end if;
  -- ogni riga ha un taxon, tranne i non trovati; nessuna cultivar (arrivano nella fase 4)
  select count(*) into n from public.mappa_specie where (taxon_id is null) <> (esito = 'non trovato') or cultivar_id is not null;
  if n > 0 then raise exception 'righe di mappa con taxon ed esito incoerenti: %', n; end if;
  -- taxon locali: notogeneri sotto una famiglia accettata
  select count(*) into n from public.taxa t join public.taxa f on f.id = t.padre_id
   where t.origine = 'locale' and t.rango = 'genus' and t.notho = 'generic' and f.rango = 'family' and f.stato = 'accepted';
  if n <> locali then raise exception 'taxon locali sotto una famiglia: % (attesi %)', n, locali; end if;
  -- mappa_specie resta illeggibile per i client
  if has_table_privilege('anon', 'public.mappa_specie', 'select') or has_table_privilege('authenticated', 'public.mappa_specie', 'select') then
    raise exception 'mappa_specie leggibile da anon o authenticated';
  end if;
  raise notice 'mappa_specie: % righe (%), taxon locali %', attese,
    (select string_agg(esito || ' ' || c, ', ' order by c desc) from (select esito, count(*) c from public.mappa_specie group by esito) x),
    locali;
end $$;
```

`scripts/tassonomia/rollback_fase3.sql`:

```sql
-- Rollback della fase 3: svuota mappa_specie e toglie da taxa i taxon locali e i taxon di COL aggiunti nella fase 3
-- (riconoscibili dalla nota). I taxon della fase 2 restano. Si rifiuta se le tabelle della fase 4 contengono dati o se
-- una pianta punta già a un taxon (fase 5). Non TRUNCATE: piante ha una chiave esterna verso taxa.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase3.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.mappa_specie' -c 'vacuum full public.taxa'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.nomi_comuni) or exists (select 1 from public.cultivar) or exists (select 1 from public.schede)
     or exists (select 1 from public.piante where taxon_id is not null or cultivar_id is not null) then
    raise exception 'Rollback fase 3 rifiutato: le tabelle delle fasi 4-5 contengono già dati';
  end if;
end $$;
-- gli indici sulle chiavi esterne di taxa verso se stessa servono alla DELETE (vedi rollback_fase2.sql)
create index if not exists taxa_padre_id_idx on public.taxa (padre_id);
create index if not exists taxa_accettato_id_idx on public.taxa (accettato_id);
delete from public.mappa_specie;
delete from public.taxa where origine = 'locale' and nota = 'notogenere assente da COL (fase 3)';
delete from public.taxa where origine = 'col' and nota = 'importato nella fase 3 (abbinamento)';
```

- [ ] **Step 6: Esportare e lanciare le prove, due volte di fila**

Prima del secondo giro va fatto il rollback, perché le prove partono dallo stato della fase 2.

```bash
chmod +x scripts/tassonomia/mappa_esporta.sh scripts/tassonomia/carica_mappa.sh scripts/tassonomia/prova_fase3.sh
bash scripts/tassonomia/mappa_esporta.sh "$COPIA" "$F3/esporta"
bash scripts/tassonomia/prova_fase3.sh "$COPIA" "$F3/esporta" "$SCRATCH/prove_fase3_1" > "$SCRATCH/prove_fase3_1.log" 2>&1; echo "giro 1 uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase3_1.log"
$PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase3.sql
$PG/psql "$COPIA" -X -q -c 'vacuum full public.mappa_specie' -c 'vacuum full public.taxa'
bash scripts/tassonomia/prova_fase3.sh "$COPIA" "$F3/esporta" "$SCRATCH/prove_fase3_2" > "$SCRATCH/prove_fase3_2.log" 2>&1; echo "giro 2 uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase3_2.log"
grep -h 'NOTICE' "$SCRATCH/prove_fase3_1/r5_mappa.log" "$SCRATCH/prove_fase3_1/r5_taxa.log"; cat "$SCRATCH/prove_fase3_1/r5_taxa/tempi.txt" "$SCRATCH/prove_fase3_1/r5_mappa/tempi.txt"
shasum -a 256 "$F3/esporta/taxa/manifest.tsv" "$F3/esporta/mappa/manifest.tsv"
```

Expected:
- dall'esportazione: `nuovi taxon COL 6729`, `taxon locali 8`, `lotto_01.csv 6729`, `locali.csv 8`, `mappa.csv 15713`, `base 234514, regni Fungi,Plantae`. Se l'utente ha respinto *Cetraria islandica*, i regni sono solo `Plantae` e i numeri dei taxon cambiano di poco;
- per tutti e due i giri `uscita 0`, poi `PROVA rifiuti OK`, `PROVA alterato OK`, `PROVA ordine OK`, `PROVA caricamento OK`, `PROVA rilancio OK`, `PROVA rollback OK`, `PROVE FASE 3 OK`;
- le NOTICE `mappa_specie: 15713 righe (esatto 12134, sinonimo 2084, …)` e `taxa: 241243 righe`;
- in ogni passo WAL sotto 100 MB.

Annotare nel registro i due sha256: il Task 4 li confronta.

- [ ] **Step 7: Regressione della fase 2 con il caricamento esteso**

Si riporta la copia a `taxa` vuota, si lanciano le prove della fase 2 (che alla fine lasciano `taxa` caricata dai lotti della fase 2) e poi si ricarica la fase 3.

```bash
$PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase3.sql
$PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase2.sql
$PG/psql "$COPIA" -X -q -c 'vacuum full public.mappa_specie' -c 'vacuum full public.taxa'
bash scripts/tassonomia/prova_fase2.sh "$COPIA" "$COLDIR/lotti_fase2" "$SCRATCH/prove_fase2_regressione" > "$SCRATCH/prove_fase2_regressione.log" 2>&1; echo "uscita $?"; tail -1 "$SCRATCH/prove_fase2_regressione.log"
```

Expected: `uscita 0` e `PROVE FASE 2 OK`. I lotti della fase 2 non hanno `base.txt` né `regni.txt`, quindi valgono i valori predefiniti.

- [ ] **Step 8: Prove di mutazione**

Ogni mutazione si applica a una copia di sicurezza dello script e si ripristina subito dopo. Tra un giro e l'altro la copia torna allo stato della fase 2 con `rollback_fase3.sql`.

```bash
torna_fase2() { $PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase3.sql 2>/dev/null; $PG/psql "$COPIA" -X -q -c 'vacuum full public.mappa_specie' -c 'vacuum full public.taxa'; }
muta() {  # muta FILE ESPRESSIONE_SED NOME
  cp "$1" "$SCRATCH/mutazione.bak"; sed -i '' "$2" "$1"
  cmp -s "$1" "$SCRATCH/mutazione.bak" && echo "MUTAZIONE $3 NON APPLICATA"
  torna_fase2
  bash scripts/tassonomia/prova_fase3.sh "$COPIA" "$F3/esporta" "$SCRATCH/mut3_$3" > "$SCRATCH/mut3_$3.log" 2>&1
  echo "mutazione $3: uscita $? — $(grep -E 'FALLITA' "$SCRATCH/mut3_$3.log" | head -1 | cut -c1-90)"
  cp "$SCRATCH/mutazione.bak" "$1"
}
muta scripts/tassonomia/carica_mappa.sh 's/\[ "$(shasum -a 256 "$MAPPA\/$f" | cut -d. . -f1)" = "$(cut -f3 <<<"$riga")" \]/true/' sha
muta scripts/tassonomia/carica_mappa.sh 's/^if \[ "$presenti" = "$RIGHE" \]; then$/if false; then/' rilancio
muta scripts/tassonomia/rollback_fase3.sql 's/raise exception .Rollback fase 3 rifiutato.*;/null;/' rifiuto
git status --short scripts/tassonomia/
torna_fase2
bash scripts/tassonomia/prova_fase3.sh "$COPIA" "$F3/esporta" "$SCRATCH/prove_fase3_finale" > "$SCRATCH/prove_fase3_finale.log" 2>&1; echo "uscita $?"; tail -1 "$SCRATCH/prove_fase3_finale.log"
```

Expected:
- nessuna riga `NON APPLICATA`;
- `mutazione sha: … PROVA alterato FALLITA`;
- `mutazione rilancio: … PROVA rilancio FALLITA`;
- `mutazione rifiuto: … PROVA rollback FALLITA`;
- `git status` mostra solo file nuovi e i due file modificati di questo task;
- infine `uscita 0` e `PROVE FASE 3 OK`.

- [ ] **Step 9: Commit**

```bash
git add scripts/tassonomia/prova_fase3.sh scripts/tassonomia/mappa_nuovi_taxa.sql scripts/tassonomia/mappa_esporta.sh \
        scripts/tassonomia/carica_taxa.sh scripts/tassonomia/verifica_fase2.sql scripts/tassonomia/carica_mappa.sh \
        scripts/tassonomia/verifica_fase3.sql scripts/tassonomia/rollback_fase3.sql
git commit -m "Tassonomia fase 3: taxon in più e mappa_specie, caricamento, verifica, rollback e prove sulla copia locale"
```

**Prima del Task 4:** revisione dei commit dei Task 1–3 da parte di revisori nuovi (vedi Global Constraints). Ogni revisore scrive i risultati confermati in un file di note mentre lavora, perché il computer può andare in stop. Le correzioni importanti si fanno con una prova che fallisce prima. Se cambiano i file esportati, si rigenera l'esportazione in una cartella nuova, si rilanciano le prove e si annotano i nuovi sha256.

---

### Task 4: Caricamento sul database reale e documentazione

**Files:**
- Modify: `CLAUDE.md` (sezione "Modello tassonomico")

**Interfaces:**
- Consumes: `$F3/esporta` (Task 3), con i manifesti degli sha256 annotati; `carica_taxa.sh`, `carica_mappa.sh`, `verifica_fase3.sql`, `rollback_fase3.sql`.

- [ ] **Step 1: Backup e controlli di partenza (solo letture)**

```bash
set -a; source .env.local; set +a
TS=$(date +%Y%m%d_%H%M%S)
BK=backups/completo_${TS}_pre_fase3.dump
$PG/pg_dump "$SUPABASE_DB_URL" -Fc -f "$BK"
$PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/impronta_specie.sql > "${BK%.dump}.impronta.txt"
$PG/pg_restore -f /dev/null "$BK" && echo BACKUP LEGGIBILE
diff backups/completo_20261015_182023_pre_fase2.impronta.txt "${BK%.dump}.impronta.txt" && echo "SPECIE COME NELLA COPIA"
$PG/psql "$SUPABASE_DB_URL" -X -q -f scripts/tassonomia/controlli_spazio.sql
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c "select 'taxa col ' || count(*) filter (where origine = 'col') || ', locali ' || count(*) filter (where origine = 'locale') from public.taxa" -c "select 'mappa ' || count(*) from public.mappa_specie"
shasum -a 256 "$F3/esporta/taxa/manifest.tsv" "$F3/esporta/mappa/manifest.tsv"
```

Expected:
- `BACKUP LEGGIBILE`;
- `SPECIE COME NELLA COPIA`. Se no, fermarsi: i nomi da abbinare sono cambiati;
- `somma_db_mb` circa 261, `wal_mb` sotto 300;
- `taxa col 234514, locali 0` e `mappa 0`;
- i due sha256 uguali a quelli annotati nel Task 3. Se no, fermarsi: i file non sono quelli provati.

- [ ] **Step 2: Via esplicito dell'utente**

Chiedere in chat il via, dicendo:
- **cosa entra:** circa 6.700 nomi di COL in più, 8 taxon locali e le 15.713 righe di `mappa_specie`;
- **durata:** qualche minuto;
- **effetto sull'app:** nessuno, perché l'app non legge ancora queste tabelle;
- **spazio:** circa 10 MB in più, fino a circa 271 MB su 500;
- **dati:** non cambia niente fuori da `taxa` e `mappa_specie`;
- **ripresa:** se si interrompe basta rilanciare lo stesso comando;
- **rollback:** pronto e provato.

Senza un sì esplicito ci si ferma qui.

- [ ] **Step 3: Eseguire il caricamento**

Va lanciato dalla sessione principale in background (`run_in_background`), senza fermarlo. Se il controllo dei permessi lo blocca, dare all'utente lo stesso blocco da incollare nel suo terminale. Per sapere se è attivo usare `pgrep -f carica_`, che stampa solo il pid.

```bash
set -a; source .env.local; set +a
OUT=backups/fase3_$(date +%Y%m%d_%H%M%S)
CONFERMO_CARICAMENTO_REALE=si bash scripts/tassonomia/carica_taxa.sh "$SUPABASE_DB_URL" "$HOME/giardino-dati/col/fase3/esporta/taxa" "$OUT/taxa" > "$OUT.taxa.log" 2>&1 \
  && CONFERMO_CARICAMENTO_REALE=si bash scripts/tassonomia/carica_mappa.sh "$SUPABASE_DB_URL" "$HOME/giardino-dati/col/fase3/esporta/mappa" "$OUT/mappa" > "$OUT.mappa.log" 2>&1; echo "uscita $?"
```

Expected:
- `uscita 0`;
- in `$OUT.taxa.log` `taxa: 241243 righe` e `CARICAMENTO TAXA OK`;
- in `$OUT.mappa.log` la NOTICE `mappa_specie: 15713 righe (…), taxon locali 8` e `CARICAMENTO MAPPA OK`;
- somma dei database circa 271 MB.

Se l'uscita non è 0, prima di tutto (sola lettura) `controlli_spazio.sql` e i conteggi dello Step 1. Poi:
- **`FERMATO: spazio insufficiente`, interruzione o connessione persa:** rilanciare lo stesso comando, che salta i passi fatti;
- **`RIFIUTATO`:** non è stato scritto niente; riferire;
- **`violates foreign key constraint` in `carica_mappa.sh`:** i taxon nuovi non ci sono. Rilanciare l'intero comando, che parte da `carica_taxa.sh`;
- **`FALLITO: specie è cambiata` o un errore delle verifiche:** fermarsi e riferire. Il rollback si decide insieme: `rollback_fase3.sql` con `psql -1`, poi `vacuum full` di `mappa_specie` e `taxa`.

- [ ] **Step 4: Controlli finali**

```bash
set -a; source .env; set +a
curl -s -o /dev/null -w 'mappa con la chiave pubblica: %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/mappa_specie?select=vecchio_slug&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
curl -s -w ' %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/taxa?select=nome_scientifico,rango&nome_scientifico=eq.%C3%97%20Angulocaste" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c 'show statement_timeout' -c 'show lock_timeout'
```

Expected:
- `mappa con la chiave pubblica: 401`, perché `mappa_specie` non è leggibile dai client;
- `[{"nome_scientifico":"× Angulocaste","rango":"genus"}] 200`;
- `2min` e `0`.

- [ ] **Step 5: Fermare la copia locale e aggiornare CLAUDE.md**

```bash
bash scripts/tassonomia/copia_locale.sh ferma "$SCRATCH/copia_fase3"
```

In `CLAUDE.md` vanno fatte due modifiche:
1. il titolo "### Modello tassonomico (in corso, fasi 1, 1b e 2 di 7 applicate)" diventa "### Modello tassonomico (in corso, fasi 1, 1b, 2 e 3 di 7 applicate)";
2. in fondo alla sezione va aggiunto questo paragrafo, con le misure reali al posto di quelle attese se diverse:

```markdown
La fase 3 (piano `docs/superpowers/plans/2026-10-15-modello-tassonomico-fase3-mappa.md`) ha compilato `mappa_specie`: una riga per ognuna delle 15.713 righe non cultivar di `specie` (15.678, più 35 madri cancellate e recuperate dai file di rollback).
- **Esiti:** esatto 12.134, sinonimo 2.084, variante 706, rango superiore 505, ambiguo 273, ibrido 10, deciso dall'utente 1.
- **Regole:** sono nella specifica, "Decisioni per la fase 3".
  - Un accettato vince sugli omonimi; i sinonimi seguono COL.
  - Gli ambigui vanno al sinonimo omotipico (ICN art. 49) o all'antenato comune (GBIF HIGHERRANK).
  - I grex di orchidee vanno al genere e nella fase 4 diventano cultivar `grex`.
  - I refusi sono stati confermati dall'utente.
- **Revisione:** l'utente ha rivisto 128 casi incerti; le decisioni sono in `scripts/tassonomia/dati/fase3_decisioni.tsv`.
- **Taxon aggiunti:** 6.729 di COL, con `nota = 'importato nella fase 3 (abbinamento)'`, e 8 notogeneri locali assenti da COL, con `nota = 'notogenere assente da COL (fase 3)'`.
- **Cosa registra la mappa:** `mappa_specie.taxon_id` è il nome trovato, accettato o sinonimo. Dove attaccare le schede (accettato; autonimi → specie) si decide nella fase 4.
- **Spazio:** circa 271 MB su 500.
- **Script, tutti in `scripts/tassonomia/`:**
  - `mappa_*.sql` e `mappa_rollback_madri.py`: l'abbinamento sulla copia locale;
  - `mappa_revisione.sql` e `mappa_revisione_pagina.py`: l'elenco dei casi incerti; `mappa_decisioni.sql` applica le decisioni;
  - `mappa_esporta.sh`: i file da caricare;
  - `carica_taxa.sh`: ora accetta anche lotti aggiuntivi, con `base.txt` e `regni.txt`;
  - `carica_mappa.sh` e `verifica_fase3.sql`: il caricamento e il controllo della mappa;
  - `rollback_fase3.sql`: rifiutato se la fase 4 è cominciata.
- **Prove:**
  - `prova_mappa.sql` per l'abbinamento;
  - `bash scripts/tassonomia/prova_fase3.sh URL_COPIA CARTELLA_ESPORTA CARTELLA` per il caricamento. Nella copia locale serve una `public.piante` minima con `taxon_id` e `cultivar_id`.
```

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "Tassonomia fase 3 applicata: mappa_specie (15.713 righe) e taxon in più, CLAUDE.md"
```

Nessun push senza richiesta dell'utente.
