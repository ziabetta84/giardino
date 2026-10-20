# Modello tassonomico — fase 4b: schede — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** caricare in `schede` le 15.770 schede ricavate dalla vecchia `specie` (14.507 mostrate), attaccate al taxon o alla cultivar giusti, con le fonti tolte dai testi leggibili dall'app e un inventario che torna uguale a quello di `specie`.

**Architecture:** tutto si calcola sulla copia locale, che ha la fase 4a e le fusioni dei doppioni con le stesse chiavi del reale.
1. Funzioni SQL puliscono i testi: avvisi, descrizioni, esigenze, immagine.
2. Una query sceglie per ogni riga di contenuto l'aggancio, se è idonea e se è la scheda mostrata, e applica le correzioni a mano.
3. Si esporta un lotto, che `carica_schede.sh` carica sul reale; `verifica_fase4b.sql` rifà l'inventario per campo e per fonte.
4. Il rollback della 4a diventa più severo (rilievo M4 della revisione della 4a).

**Tech Stack:** PostgreSQL 17 (Supabase, progetto `ncuhhsvtjwcolhpdxbkt`, piano gratuito; copia locale con i binari in `/opt/homebrew/opt/postgresql@17/bin/`), bash, Python 3 (solo libreria standard).

**Spec:** `docs/superpowers/specs/2026-10-13-modello-tassonomico-design.md`: sezioni "Modello dati" (`schede`), "Permessi", "Regole di presentazione", "Migrazione dei contenuti", "Decisioni dopo la verifica" punti 9-12, "Decisioni sullo spazio" e "Decisioni per la fase 4 (approvate il 16/10/2026)", punti 1-14. La ricerca, con le misure e gli script, è in `~/giardino-dati/col/ricerca_fase4/` (`schede.md`, `fonti_testi.md`, `sql/`, `fonti_testi/`).

## Global Constraints

- **Righe** (specifica, "Migrazione dei contenuti"): una scheda per ogni riga madre di `specie` con contenuto (15.678 non cultivar e 45 cultivar orfane), per ognuna delle 12 cultivar con una descrizione propria e per ognuna delle 35 madri cancellate, lette dai file di rollback. Nessun contenuto si perde.
- **Aggancio** (decisioni 1, 5 e 6): sull'accettato del nome trovato in `mappa_specie`; per un sinonimo di specie che porta a un autonimo, sulla specie; grex, Gruppo Dunedin e righe cultivar sulla loro cultivar (per una cultivar fusa, su quella in cui è stata fusa); le righe «Genere spp.», *Sansevieria* compresa, sul genere.
- **Idonea** (decisione 2): una scheda di specie finita su un genere o più in alto non è idonea e non è mai mostrata (quindi non è nemmeno ereditata). Sul genere sono idonee le righe con un nome di genere, i contenuti «ibridi o gruppo del genere» e *agapanthus*.
- **Mostrata** (decisione 3), una per aggancio: idonea, poi verificata, poi usata dalle piante dell'utente, poi genere accettato prima di un genere sinonimo, poi completezza sui valori utili, qualità della descrizione, nome accettato esatto, lunghezza, slug. Le schede delle piante dell'utente restano quelle di oggi.
- **Testi** (decisioni 9-14), trasformati nella SELECT che alimenta l'inserimento, mai con un aggiornamento dopo:
  - via l'avviso di bozza PFAF e i nomi comuni inglesi (questi vanno in `nomi_comuni` nella 4c);
  - rischi PFAF come «Rischi (testo in inglese):» senza rimandi numerici; «None known» come «Rischi: nessuno noto»;
  - rusticità RHS come frase in gradi della fascia meno rustica;
  - via le etichette «Da RHS…»; «Descrizione del genere:» resta; la coda inglese di una descrizione italiana si taglia;
  - note di lavorazione nella colonna interna `schede.nota`;
  - immagine senza la chiave `fonte` e senza i parametri `utm`;
  - esigenze senza «Non specificato dalla fonte».
- **Copiati così come sono** (decisione 7): manutenzione, ciclo colturale, vaso, ciclo vitale, descrizione originale, stato e dati di verifica, fonti (tolta solo la nota «Correzione…», spostata in `nota`).
- **La fonte non si nomina mai** nelle colonne leggibili dai client; l'unica eccezione è l'attribuzione della foto richiesta dalla licenza (decisione 12 dopo la verifica). Contenuti come la scala di rusticità USDA restano.
- **Eredità campo per campo** (decisione 4) e Gruppi colturali (decisione 8): sono regole dell'app (fase 6); qui non si fa niente oltre a non mostrare le schede non idonee.
- **Inserimento:** valori definitivi in un solo passaggio, nessun aggiornamento di massa (specifica, "Decisioni sullo spazio", punto 5); indici secondari non unici costruiti dopo il caricamento.
- **Solo queste tabelle cambiano:** `schede`; il rollback della 4a cambia solo nel suo controllo. L'impronta di `specie` resta identica prima e dopo.
- **Spazio:**
  - prima di ogni passo sul reale, somma dei database ≤ 400 MB e WAL ≤ 300 MB;
  - attesi circa 33 MB in più (misurati sulla copia), cioè circa 395 MB su 500 (oggi 361,6);
  - sopra 450 MB ci si ferma (specifica, "Decisioni sullo spazio", punto 1).
- **Connessione:** sul reale solo `SUPABASE_DB_URL` (porta 5432), mai la 6543; `statement_timeout` di 2 minuti sul pooler, quindi il caricamento lo alza con `set local`.
- **Copia locale e reale:** le prove girano sulla copia locale (`127.0.0.1:55440`), che deve avere `cultivar` e `mappa_specie` identiche al reale (impronte del Task 3); sul reale, prima del Task 4, solo letture.
- **Regole di lavoro:**
  - nessuna applicazione al reale senza il via esplicito dell'utente in chat;
  - nessun push senza richiesta;
  - l'URL del database non si stampa mai, nemmeno con `ps`; della connessione si stampa al massimo la porta;
  - se il controllo dei permessi blocca un comando sul reale, lo si dà all'utente da lanciare nel suo terminale.
- **Revisione e ramo:** si lavora su `main`; revisione dei Task 1–3 da parte di un revisore nuovo prima del Task 4 (un solo revisore, scelta dell'utente per il credito), con le note scritte in un file mentre lavora.

## Review Focus

1. **Una pianta dell'utente che cambia scheda** o resta senza scheda mostrata: tutte le 91 righe usate dalle piante devono restare mostrate. Controllo in `prova_schede.sql` (Task 2).
2. **Una fonte ancora nominata in un testo leggibile** (descrizione, avvisi, esigenze): il controllo dei residui di `prova_schede.sql` e di `verifica_fase4b.sql` deve trovarne zero (Task 2 e 3).
3. **Un contenuto perso o cambiato senza motivo**: l'inventario di `verifica_fase4b.sql` confronta per campo e per fonte con `specie` (Task 3).
4. **Una scheda di specie mostrata su un genere o più in alto**: controllo in `prova_schede.sql` e `verifica_fase4b.sql` (Task 2 e 3).
5. **Rollback della 4a con le schede già caricate**: deve essere rifiutato. Prova `rollback_4a` di `prova_fase4b.sh` (Task 3).

## Misure del prototipo (20/10/2026, copia locale con la fase 4a e le fusioni)

| Misura | Valore |
|---|---|
| Righe di contenuto | 15.770: 15.678 non cultivar, 45 cultivar orfane, 12 cultivar con una descrizione propria, 35 madri dai rollback |
| Agganci | 14.588, di cui 875 con più schede; 278 schede su cultivar (220 grex, 1 Gruppo, 45 orfane, 12 con descrizione) |
| Mostrate | 14.507; non idonee 363; tutte le 91 righe delle piante dell'utente sono mostrate |
| Testi | correzioni a mano 24 (9 descrizioni, 15 avvisi), tutte applicate; schede con una nota interna 74; residui di fonti nominate 0 |
| WAL | 34,9 MB per il lotto, 0,7 MB per gli indici |
| Spazio | `schede` 33 MB con gli indici |
| Durata sulla copia | funzioni e proposte circa 11 s; prove della fase 4b circa 1 minuto |

## File

- Create: `scripts/tassonomia/schede_testi.sql`, `prova_schede_testi.sql` — funzioni che tolgono le fonti dai testi.
- Create: `scripts/tassonomia/dati/fase4_schede_a_mano.tsv` — le 24 correzioni a mano.
- Create: `scripts/tassonomia/schede_rollback_madri.py` — le 35 madri dai file di rollback, per intero.
- Create: `scripts/tassonomia/schede_proposte.sql`, `prova_schede.sql` — le schede proposte sulla copia.
- Create: `scripts/tassonomia/schede_esporta.sh`, `carica_schede.sh`, `verifica_fase4b.sql`, `rollback_fase4b.sql`, `prova_fase4b.sh`.
- Modify: `scripts/tassonomia/rollback_fase4a.sql` (intero file) — rifiuto con qualsiasi riga in `schede` o `nomi_comuni`.
- Modify: `CLAUDE.md` (Task 4).

Tutti i comandi si lanciano dalla radice del repository. In ogni shell nuova vanno impostate queste variabili:
- `PG=/opt/homebrew/opt/postgresql@17/bin`;
- `SCRATCH` = la cartella temporanea della sessione (scratchpad);
- `COLDIR=$HOME/giardino-dati/col`;
- `F4=$COLDIR/fase4`;
- `COPIA=postgresql://postgres@127.0.0.1:55440/giardino`;
- `SUPABASE_DB_URL` da `.env.local`;
- `BK` dal Task 4.

---

### Task 1: Funzioni che tolgono le fonti dai testi

**Files:**
- Create: `scripts/tassonomia/prova_schede_testi.sql`
- Create: `scripts/tassonomia/schede_testi.sql`

**Interfaces:**
- Consumes: la copia locale con lo schema `col` (fasi 2-4a).
- Produces: le funzioni `col.alert_elemento(text) -> text` (null = tolto), `col.alert_pulito(text[]) -> text[]`, `col.alert_nota(text[]) -> text`, `col.rusticita_frase(text) -> text`, `col.descrizione_pulita(text) -> text`, `col.descrizione_nota(text) -> text`, `col.esigenze_pulite(jsonb) -> jsonb`, `col.immagine_pulita(jsonb) -> jsonb`.

- [ ] **Step 1: Copia locale pronta**

La copia è quella della 4a, accesa su 55440 con la fase 4a e le fusioni; le sue chiavi devono essere identiche al reale.

```bash
Q="select count(*) || ' ' || md5(string_agg(id::text || '|' || slug || '|' || taxon_id::text || '|' || categoria || '|' || epiteto || '|' || coalesce(gruppo, '') || '|' || coalesce(nome_commerciale, '') || '|' || coalesce(grex_id::text, ''), ',' order by id)) from public.cultivar"
$PG/psql "$COPIA" -X -qAt -c "$Q" -c "select 'schede ' || count(*) from public.schede"
set -a; source .env.local; set +a
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c "$Q"
```

Expected: `196303 7294967f2fd4e835c21d92073ba264f1` uguale sulla copia e sul reale, `schede 0` sulla copia. Se le impronte sono diverse, fermarsi: la copia non è più quella del reale.

Poi si tolgono dalla copia le tabelle e le funzioni lasciate dal prototipo, perché le prove dei Task 1 e 2 devono vederle mancare:

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -c 'drop table if exists col.schede_proposte, col.schede_a_mano, col.schede_piante, col.schede_rollback' \
  -c 'drop function if exists col.rusticita_frase(text), col.togli_virgolette(text), col.alert_tipo(text), col.alert_elemento(text), col.alert_pulito(text[]), col.alert_nota(text[]), col.descrizione_pulita(text), col.descrizione_nota(text), col.esigenze_pulite(jsonb), col.immagine_pulita(jsonb), col.utile(jsonb), col.pieno(text), col.applica_a_mano(text, text, text)'
```

- [ ] **Step 2: Scrivere le prove**

`scripts/tassonomia/prova_schede_testi.sql`:

```sql
-- Prove delle funzioni di schede_testi.sql (fase 4b) su esempi reali presi da specie. Sola lettura. Errore al primo
-- caso che non torna.
do $$
declare c record;
begin
  for c in select * from (values
      ('Scheda in bozza, importata automaticamente da Plants For A Future (pfaf.org): dati non verificati manualmente, da controllare prima di considerarli affidabili', null),
      ('Nome comune (inglese, fonte PFAF): Cretan Thyme', null),
      ('Rischi segnalati dalla fonte (testo originale in inglese, non tradotto per non alterarne il significato): None known', 'Rischi: nessuno noto'),
      ('Rischi segnalati dalla fonte (testo originale in inglese, non tradotto per non alterarne il significato): This plant is reputed to be poisonous to cattle, sheep and pigs[155].',
       'Rischi (testo in inglese): This plant is reputed to be poisonous to cattle, sheep and pigs.'),
      ('Nessun rischio noto segnalato dalla fonte.', 'Rischi: nessuno noto'),
      ('Rischi segnalati dalla fonte: pianta velenosa.', 'Rischi: pianta velenosa.'),
      ('Dimensioni RHS a maturità: altezza 0.5-1m, diffusione 0.1-0.5m', 'Dimensioni a maturità: altezza 0.5-1m, diffusione 0.1-0.5m'),
      ('Rusticità RHS: H4 (scala UK, vedi H1-H7 nella documentazione RHS)', 'Rusticità: minime fino a -10 °C'),
      ('Rusticità RHS: H1C, H4 (scala UK, vedi H1-H7 nella documentazione RHS)', 'Rusticità: minime non sotto i 5 °C'),
      ('Propagazione (RHS, testo originale in inglese): "Propagate by seed, layering or semi- hardwood cuttings"',
       'Propagazione (testo in inglese): Propagate by seed, layering or semi- hardwood cuttings'),
      ('Da RHS (testo originale in inglese) — Parassiti: "Generally pest-free"; Malattie: "Generally disease-free"',
       'Parassiti (testo in inglese): Generally pest-free; Malattie: Generally disease-free'),
      ('nota tassonomica: famiglia classificata oggi come Primulaceae (APG); tradizionalmente/in molte fonti più datate inclusa in Myrsinaceae', null)
    ) v(prima, dopo) loop
    if col.alert_elemento(c.prima) is distinct from c.dopo then
      raise exception 'avviso «%»: atteso «%», ottenuto «%»', left(c.prima, 60), c.dopo, col.alert_elemento(c.prima);
    end if;
  end loop;
  if col.alert_nota(array['Rischi: x', 'nota tassonomica: famiglia Primulaceae']) <> 'nota tassonomica: famiglia Primulaceae' then
    raise exception 'la nota tassonomica non va nella nota';
  end if;
  if col.alert_pulito(array['Scheda in bozza, importata automaticamente da Plants For A Future (pfaf.org): dati', 'Dimensioni RHS a maturità: altezza 1m'])
     <> array['Dimensioni a maturità: altezza 1m'] then raise exception 'alert_pulito'; end if;
  for c in select * from (values
      ('Da RHS, descrizione del genere (testo originale in inglese): "Allium are bulbous herbaceous perennials."', 'Descrizione del genere: Allium are bulbous herbaceous perennials.'),
      ('Da RHS (testo originale in inglese): "A deciduous shrub with white flowers."', 'A deciduous shrub with white flowers.'),
      ('Melo da fiore, arborea caducifoglia. Da RHS (testo originale in inglese): "A small tree with glossy red fruits that persist into winter"', 'Melo da fiore, arborea caducifoglia.'),
      ('Pianta erbacea perenne con fiori blu.', 'Pianta erbacea perenne con fiori blu.')
    ) v(prima, dopo) loop
    if col.descrizione_pulita(c.prima) is distinct from c.dopo then
      raise exception 'descrizione «%»: attesa «%», ottenuta «%»', left(c.prima, 60), c.dopo, col.descrizione_pulita(c.prima);
    end if;
  end loop;
  if col.esigenze_pulite('{"luce": "Non specificato dalla fonte", "acqua": "Moderata", "terreno": "Non specificato dalla fonte; terriccio universale"}')
     <> '{"acqua": "Moderata", "terreno": "terriccio universale"}' then raise exception 'esigenze: %', col.esigenze_pulite('{"luce": "Non specificato dalla fonte", "acqua": "Moderata", "terreno": "Non specificato dalla fonte; terriccio universale"}'); end if;
  if col.immagine_pulita('{"url": "https://upload.wikimedia.org/a/Mertensia_maritima_4.jpg?utm_source=commons.wikimedia.org&utm_campaign=imageinfo&utm_content=original", "fonte": "Wikimedia Commons", "licenza": "CC BY-SA 3.0", "attribuzione": "No machine-readable author provided. Dlanglois assumed (based on copyright claims).", "fonte_pagina": "https://commons.wikimedia.org/wiki/File:Mertensia_maritima_4.jpg"}')
     <> '{"url": "https://upload.wikimedia.org/a/Mertensia_maritima_4.jpg", "licenza": "CC BY-SA 3.0", "attribuzione": "Dlanglois", "fonte_pagina": "https://commons.wikimedia.org/wiki/File:Mertensia_maritima_4.jpg"}'
    then raise exception 'immagine'; end if;
  raise notice 'TESTI DELLE SCHEDE CORRETTI';
end $$;
```

- [ ] **Step 3: Lanciarle e vederle fallire**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_schede_testi.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
```

Expected: `ERROR:  function col.alert_elemento(text) does not exist`.

- [ ] **Step 4: Scrivere le funzioni**

`scripts/tassonomia/schede_testi.sql`:

```sql
-- Fase 4b: funzioni che tolgono le fonti citate dentro i testi delle schede (specifica, "Decisioni dopo la verifica",
-- punti 11-12, e "Decisioni per la fase 4", punti 9-14). Si usano nella SELECT che alimenta le schede, mai con un
-- aggiornamento dopo l'inserimento (decisione sullo spazio 5). Solo copia locale (schema col).
-- - avvisi (alert, text[]): via l'avviso di bozza PFAF e i nomi comuni inglesi (vanno in nomi_comuni nella fase 4c);
--   i rischi PFAF diventano «Rischi (testo in inglese):» senza i rimandi numerici, «None known» «Rischi: nessuno noto»;
--   i dati di coltivazione restano con prefissi fissi; la rusticità RHS diventa la frase in gradi della fascia meno
--   rustica; le note tassonomiche o sul libro vanno nella nota interna;
-- - descrizioni: via le etichette «Da RHS (testo originale in inglese):», «Descrizione del genere:» resta; la coda
--   inglese di una descrizione italiana si taglia (resta in descrizione_originale); le note di lavorazione (IPNI,
--   aggiornamenti PFAF, identificazione RHS non confermata) vanno nella nota interna;
-- - esigenze: via «Non specificato dalla fonte»; immagine: via la chiave costante «fonte», via i parametri utm
--   dall'indirizzo, l'autore «No machine-readable author provided. X assumed» diventa X.
-- Le righe che nessuna regola copre si correggono a mano (dati/fase4_schede_a_mano.tsv).

-- fasce ufficiali di rusticità RHS (minima invernale): H1a oltre 15 °C … H7 sotto -20 °C
create or replace function col.rusticita_frase(a text) returns text language sql immutable parallel safe as $$
  select 'Rusticità: minime ' || case min(o)
           when 1 then 'non sotto i 15 °C' when 2 then 'non sotto i 10 °C' when 3 then 'non sotto i 5 °C'
           when 4 then 'non sotto 1 °C' when 5 then 'fino a -5 °C' when 6 then 'fino a -10 °C' when 7 then 'fino a -15 °C'
           when 8 then 'fino a -20 °C' when 9 then 'anche sotto i -20 °C' end
    from regexp_matches(upper(substring(a from '^Rusticit. RHS: ([^(]*)')), '(H1[ABC]|H[2-7])', 'g') m
    cross join lateral (select array_position(array['H1A','H1B','H1C','H2','H3','H4','H5','H6','H7'], m[1]) as o) x
  having count(*) > 0
$$;

create or replace function col.togli_virgolette(t text) returns text language sql immutable parallel safe as $$
  select regexp_replace(t, ': "([^"]*)"', ': \1', 'g')
$$;

-- tipo di un elemento degli avvisi: N = nota interna, X = tolto, A = resta (trasformato)
create or replace function col.alert_tipo(a text) returns text language sql immutable parallel safe as $$
  select case
    when a ~ '^Scheda in bozza, importata automaticamente da Plants For A Future' then 'X'
    when a ~ '^Nome comune \(' then 'X'
    when a ~* '^la fonte non riporta il simbolo di tossicit' or a ~* 'il libro riporta' or a ~* '^nota tassonomica' then 'N'
    else 'A' end
$$;

create or replace function col.alert_elemento(a text) returns text language sql immutable parallel safe as $$
  select case
    when col.alert_tipo(a) <> 'A' then null
    when a ~ '^Rischi segnalati dalla fonte \(testo originale in inglese' and a ~* ': None known\.?\s*$' then 'Rischi: nessuno noto'
    when a ~ '^Rischi segnalati dalla fonte \(testo originale in inglese' then
      btrim(regexp_replace(regexp_replace(
        regexp_replace(a, '^Rischi segnalati dalla fonte \(testo originale in inglese, non tradotto per non alterarne il significato\): ',
                       'Rischi (testo in inglese): '),
        '\[K Plants for a Future[^]]*\]', '', 'gi'),
        '[[:space:] ]*\[[[:space:] ]*(\[?[0-9]{1,4}(-[0-9]{1,4})?|K)([[:space:] ]*,[[:space:] ]*([0-9]{1,4}|K))*[[:space:] ]*\]', '', 'g'))
    when a ~ '^Rischi segnalati dalla fonte: nessun rischio noto' or a ~ '^Nessun rischio noto segnalato dalla fonte' then 'Rischi: nessuno noto'
    when a ~ '^Rischi segnalati dalla fonte' then regexp_replace(a, '^Rischi segnalati dalla fonte: ', 'Rischi: ')
    when a ~ '^Dimensioni RHS a maturit' then regexp_replace(a, '^Dimensioni RHS a maturità: ', 'Dimensioni a maturità: ')
    when a ~ '^Rusticit. RHS' then coalesce(col.rusticita_frase(a), a)
    when a ~ '^(Propagazione|Potatura) \(RHS, testo originale in inglese\)' then
      col.togli_virgolette(regexp_replace(a, '^(Propagazione|Potatura) \(RHS, testo originale in inglese\): ', '\1 (testo in inglese): '))
    when a ~ '^(Propagazione|Potatura)' then
      col.togli_virgolette(
        regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(a,
          '^(Propagazione|Potatura) \(RHS\): ', '\1: '),
          ' \((classificazione RHS)\)', '', 'g'),
          ',? (della )?classificazione RHS', '', 'g'),
          ' \(([^()]*), classificazione RHS\)', ' (\1)', 'g'),
          'gruppo di potatura RHS ', 'gruppo di potatura ', 'gi'))
    when a ~ '^Da RHS \(testo originale in inglese\)' then
      col.togli_virgolette(regexp_replace(a, '^Da RHS \(testo originale in inglese\) — (Parassiti|Malattie): ', '\1 (testo in inglese): '))
    when a ~ '^Da RHS' or a ~ '^Parassiti \(RHS' then
      col.togli_virgolette(regexp_replace(regexp_replace(a, '^Da RHS — ', ''), '(Parassiti|Malattie) \(RHS\): ', '\1: ', 'g'))
    when a ~ '^(Parassiti|Malattie)' then col.togli_virgolette(a)
    when a ~* 'simbolo[^)]*nel libro' and a ~* 'velenos|tossic' and a !~* 'non specificamente' then regexp_replace(a, ' \(simbolo[^)]*nel libro\)', '')
    else a end
$$;

create or replace function col.alert_pulito(al text[]) returns text[] language sql immutable parallel safe as $$
  select case when al is null then null
              else coalesce((select array_agg(col.alert_elemento(x) order by o) from unnest(al) with ordinality u(x, o)
                              where col.alert_elemento(x) is not null), '{}') end
$$;

create or replace function col.alert_nota(al text[]) returns text language sql immutable parallel safe as $$
  select string_agg(x, ' | ' order by o) from unnest(al) with ordinality u(x, o) where col.alert_tipo(x) = 'N'
$$;

create or replace function col.descrizione_pulita(d text) returns text language sql immutable parallel safe as $$
  with u as (
    select case
      when d ~ '^Da RHS, descrizione del genere \(testo originale in inglese\): ' then
        regexp_replace(regexp_replace(d, '^Da RHS, descrizione del genere \(testo originale in inglese\): "', 'Descrizione del genere: '), '\.?"\.?\s*$', '.')
      when d ~ '^Da RHS \(testo originale in inglese\): ' then
        regexp_replace(regexp_replace(d, '^Da RHS \(testo originale in inglese\): "', ''), '\.?"\.?\s*$', '.')
      when d ~ '.Da RHS(, descrizione del genere)? \(testo originale in inglese\): ' then
        btrim(regexp_replace(d, '\s*Da RHS(, descrizione del genere)? \(testo originale in inglese\): ".*$', ''))
      else d end as d1),
  v as (
    select regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(regexp_replace(d1,
      '"?\.?\s*Identificazione RHS non confermata \([^)]*\)[^.]*\.', '', 'g'),
      '\s*See the RHS pages on [^".]*(for further details)?\.?', '', 'g'),
      '\s*\((le fonti|la fonte|il testo originale)\M[^)]*\)', '', 'gi'),
      '\s*(Aggiornamento: )?[^.]*(International Plant Names? Index|\mIPNI\M).*$', '', 'g'),
      '\s*\m(UPDATE|Update|Aggiornamento)\M( del)?[^:\n]{0,25}:[^\n]*', '', 'g'),
      '\s+—\s+le fonti riportano[^.;]*', '', 'gi') as d1b, d1 from u)
  select case when d is null then null when d1b = d then d else regexp_replace(btrim(d1b), '([^.])\.\.$', '\1.') end from v
$$;

create or replace function col.descrizione_nota(d text) returns text language sql immutable parallel safe as $$
  select nullif(concat_ws(' | ',
    substring(d from '(Identificazione RHS non confermata[^—]*—[^.]*\.)'),
    substring(d from '((?:Aggiornamento: )?[^.]*(?:International Plant Names? Index|\mIPNI\M).*$)'),
    substring(d from '(\m(?:UPDATE|Update|Aggiornamento)\M(?: del)?[^:\n]{0,25}:[^\n]*)')), '')
$$;

create or replace function col.esigenze_pulite(e jsonb) returns jsonb language sql immutable parallel safe as $$
  select case when e is null or jsonb_typeof(e) <> 'object' then e else
    coalesce((select jsonb_object_agg(k, case when jsonb_typeof(v) = 'string'
                                              then to_jsonb(regexp_replace(v #>> '{}', '^Non specificato dalla fonte;\s*', ''))
                                              else v end)
                from jsonb_each(e) x(k, v)
               where not (jsonb_typeof(v) = 'string' and btrim(v #>> '{}') = 'Non specificato dalla fonte')), '{}'::jsonb) end
$$;

create or replace function col.immagine_pulita(i jsonb) returns jsonb language sql immutable parallel safe as $$
  select case when i is null or jsonb_typeof(i) <> 'object' then i else
    (i - 'fonte')
    || case when i ? 'url' then jsonb_build_object('url', regexp_replace(i->>'url', '\?utm_source=[^#]*$', '')) else '{}'::jsonb end
    || case when coalesce(i->>'attribuzione', '') ~ '^No machine-readable author provided\. .+ assumed'
            then jsonb_build_object('attribuzione', substring(i->>'attribuzione' from '^No machine-readable author provided\. (.+?) assumed'))
            else '{}'::jsonb end end
$$;
```

- [ ] **Step 5: Crearle e rilanciare le prove**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/schede_testi.sql
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_schede_testi.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
```

Expected: `NOTICE:  TESTI DELLE SCHEDE CORRETTI`.

- [ ] **Step 6: Commit**

```bash
git add scripts/tassonomia/prova_schede_testi.sql scripts/tassonomia/schede_testi.sql
git commit -m "Tassonomia fase 4b: funzioni che tolgono le fonti dai testi delle schede, con le prove"
```

---

### Task 2: Schede proposte sulla copia locale

**Files:**
- Create: `scripts/tassonomia/dati/fase4_schede_a_mano.tsv`
- Create: `scripts/tassonomia/schede_rollback_madri.py`
- Create: `scripts/tassonomia/prova_schede.sql`
- Create: `scripts/tassonomia/schede_proposte.sql`

**Interfaces:**
- Consumes: le funzioni del Task 1; `public.specie`, `public.mappa_specie`, `public.taxa`, `public.cultivar` della copia; i file di rollback `scripts/nomi-italiani/rollback_doppioni_slug.sql` e `rollback_tre_casi_doppioni.sql`; `$COLDIR/fase3/piante_specie.tsv` (righe di specie usate dalle piante dell'utente).
- Produces:
  - `col.schede_proposte`: le colonne di `public.schede` (`id`, `taxon_id`, `cultivar_id`, `fonti`, `descrizione`, `descrizione_originale`, `lingua_descrizione`, `esigenze`, `manutenzione`, `ciclo_colturale`, `ciclo_vitale`, `vaso`, `alert`, `immagine`, `stato_verifica`, `verificata_il`, `verificata_da`, `mostrata`, `vecchia_specie_id`, `nota`) più `vecchio_slug`, `origine_riga`, `idonea`, `usata_piante`, `chiave`;
  - `col.schede_a_mano` con la colonna `applicata`; le funzioni `col.utile(jsonb)`, `col.pieno(text)`, `col.applica_a_mano(text, text, text)`.

- [ ] **Step 1: Scrivere le correzioni a mano e l'estrazione delle madri**

`scripts/tassonomia/dati/fase4_schede_a_mano.tsv` (tabulazioni tra le colonne, formato testo di COPY: nessuna tabulazione né barra rovescia nei valori; `a` vuota = tolto). Sono le 9 descrizioni e i 15 avvisi che citano una fonte e che nessuna regola copre (`~/giardino-dati/col/ricerca_fase4/fonti_testi.md`, punto 15):

```text
vecchio_slug	campo	da	a
ambrosia-trifida	descrizione	 non meglio specificati dalla fonte.	 non meglio specificati.
calamus-ovoideus	descrizione	; la fonte lo descrive anche come un grande albero alto fino a circa 4,3 m (14 piedi).	.
helenium-hoopesii	descrizione	la fonte consiglia comunque di considerarla per precauzione tossica anche per l'uomo.	per precauzione conviene considerarla tossica anche per l'uomo.
hibiscus-rosa-sinensis	descrizione	La fonte sconsiglia l'uso della pianta durante la gravidanza	Se ne sconsiglia l'uso durante la gravidanza
lemna-gibba	descrizione	; la fonte non specifica il tipo di terreno.	.
mahonia-aquifolium	descrizione	Tra le cultivar con Award of Garden Merit della Royal Horticultural Society figurano	Tra le cultivar più apprezzate figurano
phellodendron-amurense	descrizione	Le fonti riportano periodi di fioritura diversi: a inizio, metà e fine primavera secondo i dati strutturati, oppure in estate secondo la descrizione narrativa, con gruppi	Fiorisce in primavera o in estate, con gruppi
sambucus-nigra-spp-canadensis	descrizione	La Royal Horticultural Society lo classifica attualmente come	Oggi è classificato come
vanda-motes-purple-rain	descrizione	 It carries many awards by AOS and RHS committees.	
aesculus-californica	alert	; per maggiori indicazioni vedi le informazioni RHS sulla propagazione da seme (alberi/arbusti)	
camelia	alert	RHS segnala un meccanismo di danno diverso da quello già noto: il sole	Il sole
erba-cipollina	alert	RHS segnala che può	Può
iberis-sempervirens	alert	RHS segnala che può	Può
passiflora-caerulea	alert	RHS segnala che può	Può
jatropha	alert	 (fatto botanico generale, non specificamente segnalato dal libro con il simbolo "!")	
kalanchoe	alert	 (fatto ampiamente documentato, non specificamente segnalato dal libro con il simbolo "!")	
lavanda	alert	RHS classifica la specie come "High Risk Host" per	la specie è un ospite ad alto rischio per
ulivo	alert	RHS classifica l'olivo come "High Risk Host" per	l'olivo è un ospite ad alto rischio per
medinilla	alert	la fonte segnala esplicitamente che questa pianta	questa pianta
prunus-persica	alert	 secondo RHS:	:
rhododendron	alert	: fatto botanico ampiamente documentato, non specificamente segnalato con il simbolo "!" in questa pagina del libro	
rosmarino	alert	RHS classifica ora il rosmarino come	Il rosmarino è oggi classificato come
uva-di-gatto	alert	(RHS: "may be invasive")	(può diventare invasiva)
zantedeschia	alert	: fatto botanico ampiamente documentato, non specificamente segnalato dal libro con il simbolo "!"	
```

`scripts/tassonomia/schede_rollback_madri.py`:

```python
#!/usr/bin/env python3
"""Fase 4b: le 35 righe madri cancellate, per intero, dai file di rollback (le stesse di mappa_rollback_madri.py), una
per riga in JSON, per diventare schede (specifica, "Migrazione dei contenuti": le 35 madri entrano come schede).
Uso: python3 scripts/tassonomia/schede_rollback_madri.py > madri.jsonl   (dalla radice del repository)
"""
import json
import re
import sys
from pathlib import Path

FILE = ['scripts/nomi-italiani/rollback_doppioni_slug.sql', 'scripts/nomi-italiani/rollback_tre_casi_doppioni.sql']
n = 0
for nome in FILE:
    blocco = re.search(r'\$json\$(.*?)\$json\$', Path(nome).read_text(encoding='utf-8'), re.S)
    if not blocco:
        sys.exit(f'JSON non trovato in {nome}')
    for r in json.loads(blocco.group(1)):
        if "'" in r['nome_scientifico'] or r.get('specie_padre_id'):
            continue
        print(json.dumps(r, ensure_ascii=False))
        n += 1
print(f'madri estratte: {n}', file=sys.stderr)
```

```bash
chmod +x scripts/tassonomia/schede_rollback_madri.py
python3 scripts/tassonomia/schede_rollback_madri.py | python3 -c "import sys, json; l = [json.loads(x) for x in sys.stdin]; print(len(l), sum(1 for r in l if r.get('descrizione')))"
```

Expected: `madri estratte: 35` e `35 35`.

- [ ] **Step 2: Scrivere le prove delle schede**

`scripts/tassonomia/prova_schede.sql`:

```sql
-- Prove delle proposte delle schede della fase 4b (schede_proposte.sql), sulla copia locale. Errore al primo controllo
-- che fallisce. Numeri e casi valgono per specie del 16/10/2026, la fase 4a applicata e le fusioni del 20/10/2026.
do $$
declare
  n bigint;
  atteso record;
begin
  -- 15.678 righe non cultivar + 45 cultivar orfane + 12 cultivar con una descrizione propria + 35 madri dai rollback
  select count(*) into n from col.schede_proposte;
  if n <> 15770 then raise exception 'schede proposte: % (attese 15770)', n; end if;
  select count(*) into n from col.schede_proposte where num_nonnulls(taxon_id, cultivar_id) <> 1;
  if n > 0 then raise exception 'schede senza aggancio o con due agganci: %', n; end if;
  -- una sola mostrata per aggancio; mai una scheda non idonea (contenuto di specie su un taxon superiore)
  select count(*) into n from (select coalesce(taxon_id, cultivar_id) from col.schede_proposte where mostrata group by 1 having count(*) > 1) x;
  if n > 0 then raise exception 'agganci con più schede mostrate: %', n; end if;
  select count(*) into n from col.schede_proposte p join public.taxa t on t.id = p.taxon_id
   where p.mostrata and t.rango not in ('genus', 'species', 'subspecies', 'variety', 'form');
  if n > 0 then raise exception 'schede mostrate sopra il genere: %', n; end if;
  select count(*) into n from col.schede_proposte where mostrata and not idonea;
  if n > 0 then raise exception 'schede non idonee mostrate: %', n; end if;
  -- le righe usate dalle piante dell'utente sono tutte mostrate
  select count(*) into n from col.schede_proposte where usata_piante and not mostrata;
  if n > 0 then raise exception 'schede delle piante dell''utente non mostrate: %', n; end if;
  -- casi (slug, nome del taxon o della cultivar, mostrata)
  for atteso in select * from (values
      ('pomodoro', 'Solanum lycopersicum', true),
      ('rosmarino', 'Salvia rosmarinus', true),           -- sinonimo verso un autonimo: sulla specie
      ('rosmarinus-officinalis', 'Salvia rosmarinus', false), -- madre dai rollback, doppione
      ('hydrangea', 'Hydrangea', true),                    -- riga "Genere spp." sul genere
      ('brassia-rex', 'Rex', true),                        -- grex: sulla sua cultivar
      ('brachyglottis-dunedin-hybrids', 'Dunedin Group', true),
      ('physalis-alkekengi', 'Physalidinae', false)        -- specie finita su una sottotribù: non idonea
    ) v(slug, nome, mostrata) loop
    select count(*) into n from col.schede_proposte p
      left join public.taxa t on t.id = p.taxon_id left join public.cultivar c on c.id = p.cultivar_id
     where p.vecchio_slug = atteso.slug and coalesce(t.nome_scientifico, c.epiteto) = atteso.nome and p.mostrata = atteso.mostrata;
    if n <> 1 then raise exception 'caso %: atteso % (mostrata %)', atteso.slug, atteso.nome, atteso.mostrata; end if;
  end loop;
  -- nessuna fonte nominata nelle colonne leggibili dai client (descrizione, avvisi, esigenze); fanno eccezione la scala
  -- di rusticità USDA, un nome di persona e «fonte» nel senso di origine di un prodotto
  select count(*) into n from col.schede_proposte p
    cross join lateral (select regexp_replace(concat_ws(' ¦ ', p.descrizione, array_to_string(p.alert, ' ¦ '), p.esigenze::text),
             '(zone?|zona) di rusticità USDA|President of the RHS|la fonte (della|dell)|le fonti naturali', '', 'gi') as t) x
   where x.t ~ '\mRHS\M|\mPFAF\M|Plants For A Future|pfaf\.org|rhs\.org|Royal Horticultural|Wisley|\mKew\M|\mUSDA\M|Wikipedia|\mIPNI\M|\mPOWO\M|Missouri|iNaturalist|PlantNet|Pl@ntNet|Edicart|Demetra|De Vecchi|\mGiunti\M'
      or x.t ~* '\m(la|le) fonti? (segnala|riporta|consiglia|sconsiglia|descrive|specifica|non)|dalla fonte|fonti consultate|testo originale|\mlibro\M|\menciclopedia\M|\[[0-9]{1,4}';
  if n > 0 then raise exception 'schede con una fonte nominata nei testi leggibili: %', n; end if;
  select count(*) into n from col.schede_a_mano where not applicata;
  if n > 0 then raise exception 'correzioni a mano non applicate (testo non trovato): %', n; end if;
  -- avvisi, immagini, note
  select count(*) into n from col.schede_proposte, unnest(alert) a where a ~ '^Scheda in bozza|^Nome comune \(|^Rusticit. RHS';
  if n > 0 then raise exception 'avvisi di bozza, nomi comuni o rusticità RHS rimasti: %', n; end if;
  select count(*) into n from col.schede_proposte where immagine ? 'fonte' or immagine->>'url' ~ 'utm_source';
  if n > 0 then raise exception 'immagini con la chiave fonte o con utm: %', n; end if;
  select count(*) into n from col.schede_proposte where nota like '%nota tassonomica%';
  if n = 0 then raise exception 'nessuna nota tassonomica spostata nella nota interna'; end if;
  raise notice 'SCHEDE CORRETTE: % schede, % mostrate, % su cultivar, % non idonee',
    (select count(*) from col.schede_proposte), (select count(*) from col.schede_proposte where mostrata),
    (select count(*) from col.schede_proposte where cultivar_id is not null), (select count(*) from col.schede_proposte where not idonea);
end $$;
```

- [ ] **Step 3: Lanciarle e vederle fallire**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_schede.sql 2>&1 | grep -o 'ERROR.*'
```

Expected: `ERROR:  relation "col.schede_proposte" does not exist`.

- [ ] **Step 4: Scrivere le proposte**

`scripts/tassonomia/schede_proposte.sql`:

```sql
-- Fase 4b: le schede da caricare (col.schede_proposte), con i valori definitivi, sulla copia locale (fase 4a applicata,
-- stesse chiavi del reale). Regole: specifica, "Decisioni per la fase 4", punti 1-14.
-- - righe: le 15.723 righe madri di specie (15.678 non cultivar e 45 cultivar orfane), le 12 cultivar con una
--   descrizione propria e le 35 madri cancellate, lette dai file di rollback (schede_rollback_madri.py);
-- - aggancio (punto 1): grex, Gruppo Dunedin e righe cultivar sulla loro cultivar (per una cultivar fusa nella fase 4a,
--   quella in cui è stata fusa); le altre sull'accettato del nome trovato in mappa_specie, e per un sinonimo di specie
--   che porta a un autonimo sulla specie;
-- - idonea (punto 2): una scheda di specie finita su un genere o più in alto non è idonea: non è mai mostrata. Sono
--   idonee sul genere le righe con un nome di genere ("Genere spp." comprese, punto 6), i contenuti di gruppo del
--   genere e agapanthus (descrizione del genere sotto un nome di specie);
-- - mostrata (punto 3): per ogni aggancio la prima per idonea, verificata, usata dalle piante dell'utente, genere
--   accettato prima di un genere sinonimo, completezza sui valori utili (i jsonb tutti a null non contano), qualità
--   della descrizione, nome accettato esatto, lunghezza della descrizione, slug;
-- - testi (punti 9-14): funzioni di schede_testi.sql, poi le correzioni a mano di dati/fase4_schede_a_mano.tsv; le
--   note di lavorazione e la nota «Correzione…» delle fonti vanno nella colonna interna nota. I jsonb di coltivazione
--   si copiano così come sono (punto 7).
-- Standard input: piante_specie.tsv (slug, nome_scientifico, cultivar, piante: le righe di specie usate dalle piante
-- dell'utente). Lanciare dalla radice del repository, dopo schede_testi.sql.
set statement_timeout = 0;
do $$ begin
  if to_regproc('col.alert_pulito') is null then raise exception 'manca schede_testi.sql'; end if;
end $$;
drop table if exists col.schede_proposte, col.schede_a_mano, col.schede_piante, col.schede_rollback;
create table col.schede_piante (slug text primary key, nome_scientifico text, cultivar boolean, piante int);
\copy col.schede_piante from pstdin with (format csv, delimiter E'\t', header)
create table col.schede_a_mano (vecchio_slug text not null, campo text not null check (campo in ('descrizione', 'alert')),
                                da text not null check (da <> ''), a text not null, applicata boolean not null default false);
\copy col.schede_a_mano (vecchio_slug, campo, da, a) from 'scripts/tassonomia/dati/fase4_schede_a_mano.tsv' with (format text, header true)
create table col.schede_rollback (r jsonb not null);
\copy col.schede_rollback from program 'python3 scripts/tassonomia/schede_rollback_madri.py' with (format csv, quote e'\x01', delimiter e'\x02')

-- valori utili: almeno un valore foglia non nullo e non vuoto (gli scheletri jsonb di PFAF hanno tutto a null)
create or replace function col.utile(j jsonb) returns boolean language sql immutable parallel safe as $$
  select j is not null and jsonb_path_exists(j, '$.** ? ((@.type() == "string" && @ != "") || @.type() == "number" || @.type() == "boolean")')
$$;
create or replace function col.pieno(t text) returns boolean language sql immutable parallel safe as $$ select t is not null and btrim(t) <> '' $$;
create or replace function col.applica_a_mano(t text, slug text, campo text) returns text language plpgsql stable as $$
declare r record;
begin
  if t is null then return null; end if;
  for r in select x.da, x.a from col.schede_a_mano x where x.vecchio_slug = slug and x.campo = applica_a_mano.campo order by x.da loop
    t := replace(t, r.da, r.a);
  end loop;
  return t;
end $$;

create temp table m as
select s.*, 'specie'::text as origine_riga from public.specie s where s.specie_padre_id is null or s.descrizione is not null
union all
select (jsonb_populate_record(null::public.specie, r)).*, 'rollback' from col.schede_rollback;
create index on m (id);

create temp table d as
select m.id, m.slug, m.nome_scientifico, m.origine_riga, coalesce(cv.id, mc.cultivar_id) as cultivar_id,
       mp.taxon_id as trovato, mp.esito, mp.nota as nota_mappa, t.rango as t_rango, t.stato as t_stato,
       case when coalesce(cv.id, mc.cultivar_id) is not null then null
            when t.stato in ('accepted', 'provisionally accepted') then t.id
            when t.rango = 'species' and a.rango in ('subspecies', 'variety', 'form', 'subvariety', 'subform', 'infraspecific name')
                 and split_part(a.nome_scientifico, ' ', 2) = regexp_replace(a.nome_scientifico, '^.* ', '') then a.padre_id
            else coalesce(t.accettato_id, t.id) end as dest
  from m
  left join public.cultivar cv on cv.vecchia_specie_id = m.id
  left join public.mappa_specie mc on mc.vecchia_specie_id = m.id and mc.cultivar_id is not null
  left join public.mappa_specie mp on mp.vecchia_specie_id = m.id and mp.taxon_id is not null
  left join public.taxa t on t.id = mp.taxon_id
  left join public.taxa a on a.id = t.accettato_id;
alter table d add column dest_rango text, add column idonea boolean, add column usata_piante boolean;
update d set dest_rango = x.rango from public.taxa x where x.id = d.dest;
update d set idonea = case
  when cultivar_id is not null then true
  when dest_rango in ('species', 'subspecies', 'variety', 'form') then true
  when dest_rango = 'genus' then nome_scientifico ~ '^(× ?|x )?[A-Z][a-z-]+(\s+spp?\.?)?$'
                                 or coalesce(nota_mappa, '') like 'ibridi o gruppo del genere%' or slug = 'agapanthus'
  else false end;
update d set usata_piante = exists (
  select 1 from col.schede_piante p join public.specie s on s.slug = p.slug
   where coalesce(s.specie_padre_id, s.id) = d.id and d.origine_riga = 'specie');

create temp table k as
select d.*, m.stato_verifica,
       case when d.cultivar_id is not null then 'cv:' || d.cultivar_id else 'tx:' || d.dest end as chiave,
       col.pieno(m.descrizione)::int + col.pieno(m.descrizione_originale)::int + col.utile(m.esigenze)::int
       + (col.utile(m.manutenzione -> 'irrigazione') or col.utile(m.manutenzione -> 'concimazione') or col.utile(m.manutenzione -> 'potatura')
          or col.utile(m.manutenzione -> 'calcio') or col.utile(m.manutenzione -> 'cambio_acqua'))::int
       + (col.utile(m.ciclo_colturale - 'famiglia_botanica' - 'resistenza_gelo')
          or coalesce(m.ciclo_colturale ->> 'resistenza_gelo', '') not in ('', 'non specificata'))::int
       + col.pieno(m.ciclo_vitale)::int + col.utile(m.vaso)::int + (m.immagine is not null and m.immagine <> '{}'::jsonb)::int as n_utili,
       case when not col.pieno(m.descrizione) then 0
            when m.descrizione ~ '^Famiglia botanica:' or m.lingua_descrizione = 'stub' then 1
            when m.descrizione ~* 'testo originale in inglese' then 2 else 3 end as q_descr,
       (d.esito = 'esatto' and d.t_stato in ('accepted', 'provisionally accepted'))::int as nome_accettato,
       length(coalesce(m.descrizione, '')) as ld
  from d join m on m.id = d.id;
create temp table rk as
select k.*, row_number() over (partition by chiave order by idonea desc, (stato_verifica = 'verificato') desc, usata_piante desc,
          (dest_rango = 'genus' and t_rango = 'genus' and t_stato not in ('accepted', 'provisionally accepted')) asc,
          n_utili desc, q_descr desc, nome_accettato desc, ld desc, slug) as pos
  from k;

-- testi puliti, poi le correzioni a mano (segnate come applicate solo se il testo da sostituire c'è)
create temp table t as
select m.id, m.slug, col.descrizione_pulita(m.descrizione) as descrizione, col.alert_pulito(m.alert) as alert,
       concat_ws(' | ', col.alert_nota(m.alert), col.descrizione_nota(m.descrizione),
                 (select string_agg(f, ' | ') from unnest(m.fonti) f where f ~ '^Correzione')) as nota,
       m.descrizione ~ '.Da RHS(, descrizione del genere)? \(testo originale in inglese\): ' as coda_inglese
  from m;
update col.schede_a_mano x set applicata = true
 where exists (select 1 from t where t.slug = x.vecchio_slug
                  and ((x.campo = 'descrizione' and strpos(t.descrizione, x.da) > 0)
                       or (x.campo = 'alert' and exists (select 1 from unnest(t.alert) e where strpos(e, x.da) > 0))));

create table col.schede_proposte as
select gen_random_uuid() as id,
       case when rk.cultivar_id is null then rk.dest end as taxon_id, rk.cultivar_id,
       coalesce((select array_agg(f order by o) from unnest(m.fonti) with ordinality u(f, o) where f !~ '^Correzione'), m.fonti) as fonti,
       col.applica_a_mano(t.descrizione, m.slug, 'descrizione') as descrizione,
       m.descrizione_originale,
       case when t.coda_inglese and m.lingua_descrizione = 'mixed' then 'it' else m.lingua_descrizione end as lingua_descrizione,
       col.esigenze_pulite(m.esigenze) as esigenze, m.manutenzione, m.ciclo_colturale, m.ciclo_vitale, m.vaso,
       case when t.alert is null then null
            else coalesce((select array_agg(col.applica_a_mano(e, m.slug, 'alert') order by o) from unnest(t.alert) with ordinality u(e, o)), '{}') end as alert,
       col.immagine_pulita(m.immagine) as immagine,
       m.stato_verifica, m.verificata_il, m.verificata_da,
       (rk.pos = 1 and rk.idonea) as mostrata,
       m.id as vecchia_specie_id,
       nullif(t.nota, '') as nota,
       m.slug as vecchio_slug, m.origine_riga, rk.idonea, rk.usata_piante, rk.chiave
  from rk join m on m.id = rk.id join t on t.id = rk.id;
alter table col.schede_proposte add primary key (id);

\pset tuples_only on
\pset format unaligned
select 'schede ' || count(*) || ' (mostrate ' || count(*) filter (where mostrata) || ', su cultivar ' || count(cultivar_id)
       || ', non idonee ' || count(*) filter (where not idonea) || ', delle piante dell''utente ' || count(*) filter (where usata_piante) || ')'
  from col.schede_proposte;
select 'agganci ' || count(distinct chiave) || ', con più schede ' || count(distinct chiave) filter (where n > 1)
  from (select chiave, count(*) over (partition by chiave) as n from col.schede_proposte) x;
select 'con nota ' || count(nota) || ', correzioni a mano applicate ' || (select count(*) filter (where applicata) || ' su ' || count(*) from col.schede_a_mano)
  from col.schede_proposte;
```

- [ ] **Step 5: Eseguirle e rilanciare le prove**

```bash
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/schede_proposte.sql < "$COLDIR/fase3/piante_specie.tsv" 2>&1 | grep -v 'NOTICE:  table'
$PG/psql "$COPIA" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/prova_schede.sql 2>&1 | grep -o 'ERROR.*\|NOTICE.*'
```

Expected, in meno di un minuto:
- `madri estratte: 35`;
- `schede 15770 (mostrate 14507, su cultivar 278, non idonee 363, delle piante dell'utente 91)`;
- `agganci 14588, con più schede 875`;
- `con nota 74, correzioni a mano applicate 24 su 24`;
- infine `NOTICE:  SCHEDE CORRETTE: 15770 schede, 14507 mostrate, 278 su cultivar, 363 non idonee`.

- [ ] **Step 6: Commit**

```bash
git add scripts/tassonomia/dati/fase4_schede_a_mano.tsv scripts/tassonomia/schede_rollback_madri.py scripts/tassonomia/prova_schede.sql scripts/tassonomia/schede_proposte.sql
git commit -m "Tassonomia fase 4b: aggancio, scheda mostrata e testi delle schede (copia locale) con le prove"
```

---

### Task 3: Esportazione, caricamento, verifica e rollback sulla copia locale

**Files:**
- Create: `scripts/tassonomia/prova_fase4b.sh`
- Create: `scripts/tassonomia/schede_esporta.sh`
- Create: `scripts/tassonomia/carica_schede.sh`
- Create: `scripts/tassonomia/verifica_fase4b.sql`
- Create: `scripts/tassonomia/rollback_fase4b.sql`
- Modify: `scripts/tassonomia/rollback_fase4a.sql` (intero file)

**Interfaces:**
- Consumes: `col.schede_proposte` (Task 2); `controlli_spazio.sql`, `impronta_specie.sql` (fasi 1b-2); `prova_fase4a.sh`, `cultivar_fondi.sql` e l'esportazione della 4a in `$F4/esporta` (fase 4a).
- Produces:
  - `schede_esporta.sh URL_COPIA CARTELLA` scrive `schede_01.csv`, `manifest.tsv` e `mostrate.txt`;
  - `carica_schede.sh URL CARTELLA CARTELLA_MISURE`: ultima riga `CARICAMENTO SCHEDE OK`;
  - `prova_fase4b.sh URL_COPIA CARTELLA_ESPORTA CARTELLA`: ultima riga `PROVE FASE 4B OK`.

- [ ] **Step 1: Scrivere le prove**

`scripts/tassonomia/prova_fase4b.sh`:

```bash
#!/usr/bin/env bash
# Prove della fase 4b (schede) sulla copia locale: rifiuti, file alterato, ripresa dopo un lotto fallito, caricamento,
# rilancio, rollback della 4a rifiutato con le schede presenti, rollback della 4b rifiutato se una scheda è stata
# modificata, rollback eseguito, nuovo caricamento.
# Uso: bash scripts/tassonomia/prova_fase4b.sh URL_COPIA CARTELLA_ESPORTA CARTELLA      (CARTELLA nuova a ogni giro)
#   CARTELLA_ESPORTA = cartella scritta da schede_esporta.sh. La copia deve avere la fase 4a applicata e schede vuota.
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
conta() { "${PSQL[@]}" -tAc "select count(*) || ' ' || count(*) filter (where mostrata) from public.schede"; }
SCHEDE=$(awk -F'\t' '$1 ~ /^schede_/ { s += $2 } END { print s }' "$E/manifest.tsv")
MOSTRATE=$(cat "$E/mostrate.txt")
VUOTO="0 0"
PIENO="$SCHEDE $MOSTRATE"
[ "$(conta)" = "$VUOTO" ] || fallita preparazione "schede non è vuota ($(conta)): prima rollback_fase4b.sql"
[ "$("${PSQL[@]}" -tAc 'select count(*) from public.cultivar')" -gt 0 ] || fallita preparazione "la fase 4a non è applicata"
carica() {  # carica CARTELLA PROVA
  bash $D/carica_schede.sh "$URL" "$E" "$OUT/$1" > "$OUT/$1.log" 2>&1 || fallita "$2" "carica_schede: $(tail -3 "$OUT/$1.log")"
  [ "$(tail -1 "$OUT/$1.log")" = 'CARICAMENTO SCHEDE OK' ] || fallita "$2" "$(tail -3 "$OUT/$1.log")"
}

# 1. Rifiuti, prima di qualsiasi connessione.
out=$(bash $D/carica_schede.sh 'postgresql://u:p@finto.pooler.supabase.com:5432/postgres' "$E" "$OUT/r1" 2>&1) \
  && fallita rifiuti "accettato il database reale senza conferma"
grep -qF 'RIFIUTATO: database reale senza CONFERMO_CARICAMENTO_REALE=si' <<<"$out" || fallita rifiuti "$out"
out=$(CONFERMO_CARICAMENTO_REALE=si bash $D/carica_schede.sh 'postgresql://u:p@finto.pooler.supabase.com:6543/postgres' "$E" "$OUT/r2" 2>&1) \
  && fallita rifiuti "accettata la porta 6543"
grep -qF 'RIFIUTATO: serve la porta 5432' <<<"$out" || fallita rifiuti "$out"
echo "PROVA rifiuti OK"

# 2. File alterato: rifiuto prima di scrivere.
cp -R "$E" "$OUT/esporta_alterata"
printf 'x' >> "$OUT/esporta_alterata/schede_01.csv"
out=$(bash $D/carica_schede.sh "$URL" "$OUT/esporta_alterata" "$OUT/r3" 2>&1) && fallita alterato "nessun errore"
grep -qF 'RIFIUTATO: schede_01.csv diverso da quello del manifesto' <<<"$out" || fallita alterato "$out"
[ "$(conta)" = "$VUOTO" ] || fallita alterato "caricato qualcosa: $(conta)"
echo "PROVA alterato OK"

# 3. Ripresa: il lotto fallisce (una scheda con la stessa vecchia riga della sua prima riga, già presente) e non entra
#    niente; tolta la riga, il rilancio carica tutto.
"${PSQL[@]}" -c "insert into public.schede (taxon_id, cultivar_id, fonti, vecchia_specie_id)
                 select taxon_id, cultivar_id, '{prova}', vecchia_specie_id from (select nullif(split_part(l, ',', 2), '')::uuid as taxon_id,
                   nullif(split_part(l, ',', 3), '')::uuid as cultivar_id, split_part(l, ',', 4)::uuid as vecchia_specie_id
                   from (select '$(python3 -c 'import csv, sys; r = next(csv.DictReader(open(sys.argv[1], encoding="utf-8"))); print(",".join([r["id"], r["taxon_id"], r["cultivar_id"], r["vecchia_specie_id"]]))' "$E/schede_01.csv")'::text as l) x) y"
out=$(bash $D/carica_schede.sh "$URL" "$E" "$OUT/r4" 2>&1) && fallita ripresa "nessun errore con il lotto in conflitto"
grep -qF 'duplicate key value' <<<"$out" || fallita ripresa "$out"
[ "$("${PSQL[@]}" -tAc "select count(*) from public.schede")" = 1 ] || fallita ripresa "dopo il lotto fallito ci sono $(conta) schede"
"${PSQL[@]}" -c "delete from public.schede where fonti = '{prova}'"
carica r5 ripresa
[ "$(conta)" = "$PIENO" ] || fallita ripresa "stato inatteso: $(conta) invece di $PIENO"
echo "PROVA ripresa OK"

# 4. Rilancio: tutto saltato, stato invariato.
carica r6 rilancio
grep -qF 'schede_01.csv già caricato' "$OUT/r6/tempi.txt" || fallita rilancio "lotto ricaricato"
[ "$(conta)" = "$PIENO" ] || fallita rilancio "stato cambiato: $(conta)"
echo "PROVA rilancio OK"

# 5. Il rollback della fase 4a si rifiuta con le schede presenti (anche quelle sui soli taxon).
out=$("${PSQL[@]}" -c 'begin' -c 'delete from public.schede where cultivar_id is not null' -f $D/rollback_fase4a.sql 2>&1) \
  && fallita rollback_4a "rollback della fase 4a accettato con le schede presenti"
grep -qF 'Rollback fase 4a rifiutato' <<<"$out" || fallita rollback_4a "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback_4a "stato cambiato: $(conta)"
echo "PROVA rollback_4a OK"

# 6. Rollback della 4b: rifiutato se una scheda è stata modificata dopo il caricamento (in una transazione mai
#    confermata), poi eseguito e seguito da un nuovo caricamento completo.
out=$("${PSQL[@]}" -c 'begin' -c "update public.schede set descrizione = descrizione || ' ' where id = (select min(id::text)::uuid from public.schede)" \
        -f $D/rollback_fase4b.sql 2>&1) && fallita rollback "rollback accettato con una scheda modificata"
grep -qF 'Rollback fase 4b rifiutato' <<<"$out" || fallita rollback "$out"
[ "$(conta)" = "$PIENO" ] || fallita rollback "un rollback rifiutato ha tolto righe: $(conta)"
"${PSQL[@]}" -1 -f $D/rollback_fase4b.sql
"${PSQL[@]}" -c 'vacuum full public.schede'
[ "$(conta)" = "$VUOTO" ] || fallita rollback "stato dopo il rollback: $(conta) invece di $VUOTO"
carica r7 rollback
[ "$(conta)" = "$PIENO" ] || fallita rollback "stato dopo il nuovo caricamento: $(conta)"
echo "PROVA rollback OK"
echo "PROVE FASE 4B OK"
```

- [ ] **Step 2: Scrivere esportazione, caricamento, verifica e rollback della 4b, ed esportare**

`scripts/tassonomia/schede_esporta.sh`:

```bash
#!/usr/bin/env bash
# Fase 4b: dalle schede proposte (col.schede_proposte, copia locale) scrive i file da caricare sul database reale:
# lotti schede_NN.csv da 20.000 righe al massimo (oggi uno solo, circa 40 MB di WAL), manifest.tsv con righe e sha256,
# mostrate.txt (schede mostrate attese). Le chiavi di taxa e cultivar sono quelle della copia, identica al reale.
# Uso: bash scripts/tassonomia/schede_esporta.sh URL_COPIA CARTELLA
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL della copia locale}; DIR=${2:?manca CARTELLA}
[[ $URL == postgresql://postgres@127.0.0.1:* ]] || { echo "I file si preparano solo dalla copia locale" >&2; exit 1; }
[ ! -e "$DIR" ] || { echo "La cartella $DIR esiste già: i file provati non si sovrascrivono" >&2; exit 1; }
PSQL=(/opt/homebrew/opt/postgresql@17/bin/psql "$URL" -X -q -v ON_ERROR_STOP=1)
LOTTO=20000
COLONNE='id,taxon_id,cultivar_id,fonti,descrizione,descrizione_originale,lingua_descrizione,esigenze,manutenzione,ciclo_colturale,ciclo_vitale,vaso,alert,immagine,stato_verifica,verificata_il,verificata_da,mostrata,vecchia_specie_id,nota'
mkdir -p "$DIR"
"${PSQL[@]}" -c 'set statement_timeout = 0' -c "copy (select $COLONNE from col.schede_proposte order by vecchio_slug) to stdout with (format csv, header)" > "$DIR/tutte.csv"
python3 - "$DIR" "$LOTTO" <<'PY'
import csv, hashlib, os, sys
d, lotto = sys.argv[1], int(sys.argv[2])
csv.field_size_limit(10**9)
righe = list(csv.reader(open(os.path.join(d, 'tutte.csv'), encoding='utf-8', newline='')))
testa, corpo = righe[0], righe[1:]
with open(os.path.join(d, 'manifest.tsv'), 'w', encoding='utf-8') as man:
    for n, i in enumerate(range(0, len(corpo), lotto), 1):
        nome = f'schede_{n:02d}.csv'
        with open(os.path.join(d, nome), 'w', encoding='utf-8', newline='') as f:
            w = csv.writer(f, lineterminator='\n')
            w.writerow(testa)
            w.writerows(corpo[i:i + lotto])
        sha = hashlib.sha256(open(os.path.join(d, nome), 'rb').read()).hexdigest()
        man.write(f'{nome}\t{len(corpo[i:i + lotto])}\t{sha}\t{corpo[i][0]}\n')
os.remove(os.path.join(d, 'tutte.csv'))
PY
"${PSQL[@]}" -tAc 'select count(*) from col.schede_proposte where mostrata' > "$DIR/mostrate.txt"
cut -f1,2 "$DIR/manifest.tsv"
echo "mostrate $(cat "$DIR/mostrate.txt")"
```

`scripts/tassonomia/carica_schede.sh`:

```bash
#!/usr/bin/env bash
# Fase 4b del modello tassonomico: carica public.schede dai lotti preparati da schede_esporta.sh, uno per transazione,
# con le righe già definitive (nessun aggiornamento: specifica, "Decisioni sullo spazio", punto 5). Va lanciato dopo la
# fase 4a: ogni taxon_id e cultivar_id deve già esistere.
# Regole sullo spazio: prima di ogni passo controlla la somma dei database e il WAL; tra un lotto e l'altro fa una pausa
# (10 minuti sul reale); i 2 indici secondari non unici di schede si tolgono prima e si ricreano dopo (quelli unici
# sulla scheda mostrata restano, perché garantiscono una sola mostrata per aggancio).
# Si può rilanciare dopo un'interruzione: ogni lotto è una transazione e quelli già caricati vengono saltati. Le altre
# tabelle non cambiano: l'impronta di specie si confronta prima e dopo.
# Uso: bash scripts/tassonomia/carica_schede.sh URL CARTELLA_SCHEDE CARTELLA_MISURE
#   Sul database reale serve CONFERMO_CARICAMENTO_REALE=si; soglie fisse: 400 MB di database, 300 MB di WAL.
#   Sulla copia locale: PAUSA_S (secondi, predefinito 0), SOGLIA_MB e SOGLIA_WAL_MB (predefiniti 100000).
# Uscita 0 e ultima riga CARICAMENTO SCHEDE OK = riuscito.
set -euo pipefail
cd "$(dirname "$0")/../.."
URL=${1:?manca URL}; SC=${2:?manca CARTELLA_SCHEDE}; OUT=${3:?manca CARTELLA_MISURE}
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
caricato() { [ "$("${PSQL[@]}" -tAc "select count(*) from public.schede where id = '$1'")" = 1 ]; }
primo_passo=1
pausa() {
  if [ "$primo_passo" = 1 ]; then primo_passo=0
  elif [ "$PAUSA_S" -gt 0 ]; then tempo "pausa di $PAUSA_S s"; sleep "$PAUSA_S"; fi
}
UUID='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
COLONNE='id,taxon_id,cultivar_id,fonti,descrizione,descrizione_originale,lingua_descrizione,esigenze,manutenzione,ciclo_colturale,ciclo_vitale,vaso,alert,immagine,stato_verifica,verificata_il,verificata_da,mostrata,vecchia_specie_id,nota'

# 1. I file sono quelli provati (sha256 del manifesto), con le colonne attese.
while IFS=$'\t' read -r file righe sha primo <&3; do
  [[ $file =~ ^schede_[0-9]{2}\.csv$ && $righe =~ ^[0-9]+$ && $primo =~ $UUID ]] \
    || { echo "RIFIUTATO: riga del manifesto non valida: $file" >&2; exit 1; }
  [ "$(shasum -a 256 "$SC/$file" | cut -d' ' -f1)" = "$sha" ] || { echo "RIFIUTATO: $file diverso da quello del manifesto" >&2; exit 1; }
  [ "$(head -1 "$SC/$file")" = "$COLONNE" ] || { echo "RIFIUTATO: colonne inattese in $file" >&2; exit 1; }
done 3< "$SC/manifest.tsv"
SCHEDE=$(awk -F'\t' '{ s += $2 } END { print s }' "$SC/manifest.tsv")
MOSTRATE=$(cat "$SC/mostrate.txt")
[[ $MOSTRATE =~ ^[0-9]+$ ]] || { echo "RIFIUTATO: mostrate.txt non valido" >&2; exit 1; }
controlla inizio
tempo "impronta di specie prima"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_prima.txt"

# 2. Indici secondari non unici tolti se c'è qualcosa da caricare (si ricreano al passo 4, anche dopo un'interruzione).
da_caricare=0
while IFS=$'\t' read -r file righe sha primo <&3; do
  if ! caricato "$primo"; then da_caricare=$((da_caricare + 1)); fi
done 3< "$SC/manifest.tsv"
if [ "$da_caricare" -gt 0 ]; then
  tempo "tolgo gli indici secondari di schede ($da_caricare lotti da caricare)"
  "${PSQL[@]}" -c 'drop index if exists public.schede_taxon_id_idx, public.schede_cultivar_id_idx'
fi

# 3. Un lotto per transazione; il conteggio si controlla dentro la transazione, prima del commit.
while IFS=$'\t' read -r file righe sha primo <&3; do
  if caricato "$primo"; then tempo "$file già caricato"; continue; fi
  pausa
  controlla "$file"
  prima=$("${PSQL[@]}" -tAc 'select count(*) from public.schede')
  lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
  tempo "$file: carico $righe righe"
  "${PSQL[@]}" -1 -c "set local statement_timeout = '10min'" \
    -c "copy public.schede ($COLONNE) from stdin with (format csv, header)" \
    -c "do \$\$ begin if (select count(*) from public.schede) <> $((prima + righe)) then raise exception 'lotto $file incompleto'; end if; end \$\$" \
    < "$SC/$file"
  wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
  tempo "$file: caricate $righe righe, WAL $wal MB"
done 3< "$SC/manifest.tsv"

# 4. Indici secondari (identici alla migration della fase 1) e statistiche.
pausa
controlla indici
lsn=$("${PSQL[@]}" -tAc 'select pg_current_wal_lsn()')
tempo "ricreo gli indici secondari di schede"
"${PSQL[@]}" -1 -c 'set local statement_timeout = 0' \
  -c 'create index if not exists schede_taxon_id_idx on public.schede (taxon_id)' \
  -c 'create index if not exists schede_cultivar_id_idx on public.schede (cultivar_id)'
"${PSQL[@]}" -c 'analyze public.schede'
wal=$("${PSQL[@]}" -tAc "select round(pg_wal_lsn_diff(pg_current_wal_lsn(), '$lsn') / 1e6, 1)")
tempo "indici ricreati, WAL $wal MB"

# 5. specie invariata, schede corrette, misure finali.
tempo "impronta di specie dopo"
"${PSQL[@]}" -f $D/impronta_specie.sql > "$OUT/impronta_specie_dopo.txt"
diff "$OUT/impronta_specie_prima.txt" "$OUT/impronta_specie_dopo.txt" >&2 \
  || { echo "FALLITO: specie è cambiata durante il caricamento" >&2; exit 1; }
"${PSQL[@]}" -v righe_schede="$SCHEDE" -v righe_mostrate="$MOSTRATE" -f $D/verifica_fase4b.sql
"${PSQL[@]}" -f $D/controlli_spazio.sql | tee "$OUT/controlli_fine.txt"
tempo "fine"
echo "CARICAMENTO SCHEDE OK"
```

`scripts/tassonomia/verifica_fase4b.sql`:

```sql
-- Fase 4b: controllo di public.schede dopo il caricamento, con l'inventario della specifica ("Migrazione dei
-- contenuti", Verifica): per campo e per fonte le schede hanno gli stessi numeri delle righe di specie da cui vengono.
-- Le differenze ammesse sono solo quelle decise: testi puliti (descrizione, avvisi, esigenze, immagine), la nota
-- «Correzione…» spostata da fonti a nota. Sola lettura.
-- Variabili psql: righe_schede (righe dei lotti) e righe_mostrate (schede mostrate attese).
-- Uso: psql URL -X -q -v ON_ERROR_STOP=1 -v righe_schede=N -v righe_mostrate=M -f scripts/tassonomia/verifica_fase4b.sql
select set_config('fase4b.righe', :'righe_schede', false), set_config('fase4b.mostrate', :'righe_mostrate', false) \g /dev/null
do $$
declare
  attese bigint := current_setting('fase4b.righe')::bigint;
  mostrate bigint := current_setting('fase4b.mostrate')::bigint;
  n bigint;
  campo text;
begin
  select count(*) into n from public.schede;
  if n <> attese then raise exception 'schede: % righe, attese %', n, attese; end if;
  select count(*) into n from public.schede where mostrata;
  if n <> mostrate then raise exception 'schede mostrate: %, attese %', n, mostrate; end if;
  -- ogni riga madre di specie e ogni cultivar con una descrizione ha la sua scheda; le altre schede vengono dai rollback
  select count(*) into n from public.specie s
   where (s.specie_padre_id is null or s.descrizione is not null) and not exists (select 1 from public.schede h where h.vecchia_specie_id = s.id);
  if n > 0 then raise exception 'righe di specie con contenuto senza scheda: %', n; end if;
  select count(*) into n from public.schede h
   where not exists (select 1 from public.specie s where s.id = h.vecchia_specie_id)
     and not exists (select 1 from public.mappa_specie m where m.vecchia_specie_id = h.vecchia_specie_id and m.origine = 'rollback');
  if n > 0 then raise exception 'schede che non vengono né da specie né dai rollback: %', n; end if;
  -- inventario per campo: stessi campi pieni
  foreach campo in array array['descrizione', 'descrizione_originale', 'lingua_descrizione', 'esigenze', 'manutenzione', 'ciclo_colturale',
                               'ciclo_vitale', 'vaso', 'alert', 'immagine', 'verificata_il', 'verificata_da'] loop
    execute format('select (select count(*) from public.schede h join public.specie s on s.id = h.vecchia_specie_id where h.%1$I is not null)
                         - (select count(*) from public.specie s where (s.specie_padre_id is null or s.descrizione is not null) and s.%1$I is not null)', campo)
      into n;
    if n <> 0 then raise exception 'inventario: il campo % ha % schede piene in più (o in meno se negativo) delle righe di specie', campo, n; end if;
  end loop;
  -- campi copiati così come sono: valori identici (decisione 7 della fase 4)
  select count(*) into n from public.schede h join public.specie s on s.id = h.vecchia_specie_id
   where h.descrizione_originale is distinct from s.descrizione_originale or h.manutenzione is distinct from s.manutenzione
      or h.ciclo_colturale is distinct from s.ciclo_colturale or h.vaso is distinct from s.vaso or h.ciclo_vitale is distinct from s.ciclo_vitale
      or h.stato_verifica is distinct from s.stato_verifica or h.verificata_il is distinct from s.verificata_il
      or h.verificata_da is distinct from s.verificata_da;
  if n > 0 then raise exception 'schede con un campo copiato diverso dalla riga di specie: %', n; end if;
  -- inventario per fonte: le stesse fonti, tolta solo la nota «Correzione…» (spostata in nota)
  select count(*) into n from public.schede h join public.specie s on s.id = h.vecchia_specie_id
   where h.fonti is distinct from array(select f from unnest(s.fonti) with ordinality u(f, o) where f !~ '^Correzione' order by o);
  if n > 0 then raise exception 'schede con fonti diverse dalla riga di specie: %', n; end if;
  -- una sola mostrata per aggancio, mai sopra il genere
  select count(*) into n from public.schede h join public.taxa t on t.id = h.taxon_id
   where h.mostrata and t.rango not in ('genus', 'species', 'subspecies', 'variety', 'form');
  if n > 0 then raise exception 'schede mostrate sopra il genere: %', n; end if;
  -- nessuna fonte nominata nei testi leggibili dai client (eccezioni: scala USDA, un nome di persona, «fonte» di un prodotto)
  select count(*) into n from public.schede h
    cross join lateral (select regexp_replace(concat_ws(' ¦ ', h.descrizione, array_to_string(h.alert, ' ¦ '), h.esigenze::text),
             '(zone?|zona) di rusticità USDA|President of the RHS|la fonte (della|dell)|le fonti naturali', '', 'gi') as t) x
   where x.t ~ '\mRHS\M|\mPFAF\M|Plants For A Future|pfaf\.org|rhs\.org|Royal Horticultural|Wisley|\mKew\M|\mUSDA\M|Wikipedia|\mIPNI\M|\mPOWO\M|Missouri|iNaturalist|PlantNet|Pl@ntNet|Edicart|Demetra|De Vecchi|\mGiunti\M'
      or x.t ~* '\m(la|le) fonti? (segnala|riporta|consiglia|sconsiglia|descrive|specifica|non)|dalla fonte|fonti consultate|testo originale|\mlibro\M|\menciclopedia\M|\[[0-9]{1,4}';
  if n > 0 then raise exception 'schede con una fonte nominata nei testi leggibili: %', n; end if;
  -- indici e permessi
  select count(*) into n from unnest(array['schede_taxon_id_idx', 'schede_cultivar_id_idx', 'schede_mostrata_taxon_idx', 'schede_mostrata_cultivar_idx']) i
   where to_regclass('public.' || i) is null;
  if n > 0 then raise exception 'indici di schede mancanti: %', n; end if;
  if has_column_privilege('anon', 'public.schede', 'nota', 'select') or has_column_privilege('anon', 'public.schede', 'fonti', 'select')
     or has_column_privilege('anon', 'public.schede', 'descrizione_originale', 'select') or has_column_privilege('anon', 'public.schede', 'verificata_da', 'select')
     or not has_column_privilege('anon', 'public.schede', 'descrizione', 'select') then
    raise exception 'permessi di colonna di schede inattesi';
  end if;
  raise notice 'schede: % (mostrate %, su cultivar %, con nota %); inventario per campo e per fonte uguale a specie', attese, mostrate,
    (select count(*) from public.schede where cultivar_id is not null), (select count(*) from public.schede where nota is not null);
end $$;
```

`scripts/tassonomia/rollback_fase4b.sql`:

```sql
-- Rollback della fase 4b: toglie tutte le schede. Si rifiuta se una scheda è stata modificata dopo il caricamento
-- (aggiornata_il oltre creata_il, per esempio una revisione fatta dall'app o da /zorbadice): quel lavoro andrebbe perso.
-- Non TRUNCATE, per coerenza con gli altri rollback.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4b.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.schede'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.schede where aggiornata_il > creata_il + interval '1 second') then
    raise exception 'Rollback fase 4b rifiutato: alcune schede sono state modificate dopo il caricamento';
  end if;
end $$;
delete from public.schede;
```

```bash
chmod +x scripts/tassonomia/schede_esporta.sh scripts/tassonomia/carica_schede.sh scripts/tassonomia/prova_fase4b.sh
bash scripts/tassonomia/schede_esporta.sh "$COPIA" "$F4/esporta_schede"
```

Expected: `schede_01.csv 15770` e `mostrate 14507`.

- [ ] **Step 3: Lanciare le prove e vederle fallire sul rollback della 4a**

Il rollback della 4a di oggi rifiuta solo se una scheda punta a una cultivar.

```bash
bash scripts/tassonomia/prova_fase4b.sh "$COPIA" "$F4/esporta_schede" "$SCRATCH/prove_fase4b_0" > "$SCRATCH/prove_fase4b_0.log" 2>&1; echo "uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase4b_0.log"
$PG/psql "$COPIA" -X -qAt -c "select (select count(*) from public.schede) || ' schede, ' || (select count(*) from public.cultivar) || ' cultivar'"
```

Expected: uscita 1; `PROVA rifiuti OK`, `PROVA alterato OK`, `PROVA ripresa OK`, `PROVA rilancio OK`, poi `PROVA rollback_4a FALLITA: rollback della fase 4a accettato con le schede presenti`; `15770 schede, 196303 cultivar` (il rollback della 4a era in una transazione mai confermata: non ha tolto niente).

- [ ] **Step 4: Rendere più severo il rollback della 4a**

Sostituire l'intero `scripts/tassonomia/rollback_fase4a.sql` con:

```sql
-- Rollback della fase 4a: toglie le righe di mappa_specie delle cultivar, tutte le cultivar e i taxon di COL aggiunti
-- per le cultivar (riconoscibili dalla nota). Le righe di mappa della fase 3 e i taxon delle fasi 2 e 3 restano.
-- Si rifiuta se le fasi successive sono cominciate: qualsiasi riga in schede (fase 4b) o in nomi_comuni (fase 4c), o una
-- pianta che punta a una cultivar (fase 5); prima vanno annullate quelle.
-- Non TRUNCATE: schede, piante e mappa_specie hanno chiavi esterne verso cultivar.
-- Comando: psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4a.sql
-- Poi, per restituire lo spazio: psql "$URL" -X -c 'vacuum full public.mappa_specie' -c 'vacuum full public.cultivar' -c 'vacuum full public.taxa'
set local statement_timeout = '10min';
do $$
begin
  if exists (select 1 from public.schede) or exists (select 1 from public.nomi_comuni)
     or exists (select 1 from public.piante where cultivar_id is not null) then
    raise exception 'Rollback fase 4a rifiutato: le fasi 4b, 4c o 5 hanno già dati (schede, nomi comuni o piante sulle cultivar)';
  end if;
end $$;
-- gli indici sulle chiavi esterne servono alla DELETE (vedi rollback_fase2.sql)
create index if not exists cultivar_taxon_id_idx on public.cultivar (taxon_id);
create index if not exists cultivar_grex_id_idx on public.cultivar (grex_id) where grex_id is not null;
create index if not exists taxa_padre_id_idx on public.taxa (padre_id);
create index if not exists taxa_accettato_id_idx on public.taxa (accettato_id);
delete from public.mappa_specie m
 where m.cultivar_id is not null or exists (select 1 from public.specie s where s.id = m.vecchia_specie_id and s.nome_scientifico like '%''%');
delete from public.cultivar;
delete from public.taxa where origine = 'col' and nota = 'importato nella fase 4 (cultivar)';
```

- [ ] **Step 5: Lanciare le prove due volte di fila**

Prima di ogni giro le schede vanno tolte, perché le prove partono da `schede` vuota.

```bash
torna4b() { $PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4b.sql && $PG/psql "$COPIA" -X -q -c 'vacuum full public.schede'; }
torna4b
bash scripts/tassonomia/prova_fase4b.sh "$COPIA" "$F4/esporta_schede" "$SCRATCH/prove_fase4b_1" > "$SCRATCH/prove_fase4b_1.log" 2>&1; echo "giro 1 uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase4b_1.log"
torna4b
bash scripts/tassonomia/prova_fase4b.sh "$COPIA" "$F4/esporta_schede" "$SCRATCH/prove_fase4b_2" > "$SCRATCH/prove_fase4b_2.log" 2>&1; echo "giro 2 uscita $?"; grep -E '^PROV' "$SCRATCH/prove_fase4b_2.log"
grep -h 'NOTICE:  schede' "$SCRATCH/prove_fase4b_1/r7.log"; grep -h 'WAL' "$SCRATCH/prove_fase4b_1/r7/tempi.txt"
$PG/psql "$COPIA" -X -qAt -c "select 'schede ' || pg_size_pretty(pg_total_relation_size('public.schede'))"
shasum -a 256 "$F4/esporta_schede/manifest.tsv"
```

Expected:
- per tutti e due i giri `uscita 0`, poi `PROVA rifiuti OK`, `PROVA alterato OK`, `PROVA ripresa OK`, `PROVA rilancio OK`, `PROVA rollback_4a OK`, `PROVA rollback OK`, `PROVE FASE 4B OK`;
- la NOTICE `schede: 15770 (mostrate 14507, su cultivar 278, con nota 74); inventario per campo e per fonte uguale a specie`;
- WAL sotto 100 MB (sul prototipo 34,9 e 0,7 MB);
- `schede 33 MB`.

Annotare nel registro lo sha256 del manifesto: il Task 4 lo confronta.

- [ ] **Step 6: Prove di mutazione**

```bash
muta() {  # muta FILE ESPRESSIONE_SED NOME
  cp "$1" "$SCRATCH/mutazione.bak"; sed -i '' "$2" "$1"
  cmp -s "$1" "$SCRATCH/mutazione.bak" && echo "MUTAZIONE $3 NON APPLICATA"
  torna4b > /dev/null 2>&1
  bash scripts/tassonomia/prova_fase4b.sh "$COPIA" "$F4/esporta_schede" "$SCRATCH/mut4b_$3" > "$SCRATCH/mut4b_$3.log" 2>&1
  echo "mutazione $3: uscita $? — $(grep -E 'FALLITA' "$SCRATCH/mut4b_$3.log" | head -1 | cut -c1-90)"
  cp "$SCRATCH/mutazione.bak" "$1"
}
muta scripts/tassonomia/carica_schede.sh 's/\[ "$(shasum -a 256 "$SC\/$file" | cut -d. . -f1)" = "$sha" \]/true/' sha
muta scripts/tassonomia/carica_schede.sh 's/^  if caricato "$primo"; then tempo "$file già caricato"; continue; fi$/  :/' rilancio
muta scripts/tassonomia/rollback_fase4b.sql 's/raise exception .Rollback fase 4b rifiutato.*;/null;/' rifiuto_4b
muta scripts/tassonomia/rollback_fase4a.sql 's/^  if exists (select 1 from public.schede) or exists (select 1 from public.nomi_comuni)$/  if false/' rifiuto_4a
git status --short scripts/tassonomia/
```

Expected:
- nessuna riga `NON APPLICATA`;
- `mutazione sha: … PROVA alterato FALLITA`;
- `mutazione rilancio: … PROVA rilancio FALLITA`;
- `mutazione rifiuto_4b: … PROVA rollback FALLITA`;
- `mutazione rifiuto_4a: … PROVA rollback_4a FALLITA`;
- `git status` mostra solo i file nuovi di questo task e `rollback_fase4a.sql` modificato.

- [ ] **Step 7: Regressione della 4a con il rollback nuovo, poi stato finale**

Si tolgono schede e cultivar, si rilanciano le prove della 4a (che ricaricano la 4a dagli stessi lotti), si rifanno le fusioni e si controlla che la copia sia tornata identica al reale; poi un ultimo giro delle prove della 4b lascia le schede caricate.

```bash
torna4b > /dev/null 2>&1
$PG/psql "$COPIA" -X -1 -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/rollback_fase4a.sql 2>/dev/null
$PG/psql "$COPIA" -X -q -c 'vacuum full public.mappa_specie' -c 'vacuum full public.cultivar' -c 'vacuum full public.taxa'
bash scripts/tassonomia/prova_fase4a.sh "$COPIA" "$F4/esporta" "$SCRATCH/regressione_4a" > "$SCRATCH/regressione_4a.log" 2>&1; echo "prova 4a uscita $? — $(tail -1 "$SCRATCH/regressione_4a.log")"
$PG/psql "$COPIA" -X -q -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/cultivar_fondi.sql 2>&1 | grep -o 'NOTICE:  FUSIONI.*\|ERROR.*'
Q="select count(*) || ' ' || md5(string_agg(id::text || '|' || slug || '|' || taxon_id::text || '|' || categoria || '|' || epiteto || '|' || coalesce(gruppo, '') || '|' || coalesce(nome_commerciale, '') || '|' || coalesce(grex_id::text, ''), ',' order by id)) from public.cultivar"
Q2="select count(*) || ' ' || md5(string_agg(vecchia_specie_id::text || '|' || coalesce(taxon_id::text, '') || '|' || coalesce(cultivar_id::text, '') || '|' || coalesce(esito, ''), ',' order by vecchia_specie_id)) from public.mappa_specie"
$PG/psql "$COPIA" -X -qAt -c "$Q" -c "$Q2"
bash scripts/tassonomia/prova_fase4b.sh "$COPIA" "$F4/esporta_schede" "$SCRATCH/prove_fase4b_finale" > "$SCRATCH/prove_fase4b_finale.log" 2>&1; echo "uscita $?"; tail -1 "$SCRATCH/prove_fase4b_finale.log"
```

Expected:
- `prova 4a uscita 0 — PROVE FASE 4A OK`;
- `NOTICE:  FUSIONI OK: 143 cultivar tolte in questo giro; cultivar 196303, righe di mappa delle fusioni 143`;
- `196303 7294967f2fd4e835c21d92073ba264f1` e `16023 b917eb2840ae2503740c18df2b6c1864`, le stesse impronte del reale;
- infine `uscita 0` e `PROVE FASE 4B OK`.

- [ ] **Step 8: Commit**

```bash
git add scripts/tassonomia/prova_fase4b.sh scripts/tassonomia/schede_esporta.sh scripts/tassonomia/carica_schede.sh \
        scripts/tassonomia/verifica_fase4b.sql scripts/tassonomia/rollback_fase4b.sql scripts/tassonomia/rollback_fase4a.sql
git commit -m "Tassonomia fase 4b: esportazione, caricamento, verifica con l'inventario e rollback delle schede; rollback della 4a più severo"
```

**Prima del Task 4:** revisione dei commit dei Task 1–3 da parte di un revisore nuovo (vedi Global Constraints), con le note scritte in un file mentre lavora. Le correzioni importanti si fanno con una prova che fallisce prima. Se cambiano i file esportati, si rigenera l'esportazione in una cartella nuova, si rilanciano le prove e si annota il nuovo sha256.

---

### Task 4: Caricamento sul database reale e documentazione

**Files:**
- Modify: `CLAUDE.md` (sezione "Modello tassonomico")

**Interfaces:**
- Consumes: `$F4/esporta_schede` (Task 3) con lo sha256 annotato; `carica_schede.sh`, `verifica_fase4b.sql`, `rollback_fase4b.sql`.

- [ ] **Step 1: Backup e controlli di partenza (solo letture)**

```bash
set -a; source .env.local; set +a
python3 -c 'import os, urllib.parse; print("porta", urllib.parse.urlsplit(os.environ["SUPABASE_DB_URL"]).port)'
BK=backups/completo_$(date +%Y%m%d_%H%M%S)_pre_fase4b.dump; echo "BK=$BK"
$PG/pg_dump "$SUPABASE_DB_URL" -Fc -f "$BK"
$PG/psql "$SUPABASE_DB_URL" -X -q -v ON_ERROR_STOP=1 -f scripts/tassonomia/impronta_specie.sql > "${BK%.dump}.impronta.txt"
$PG/pg_restore -f /dev/null "$BK" && echo BACKUP LEGGIBILE
diff backups/completo_20261020_105626_pre_fusioni_cultivar.impronta.txt "${BK%.dump}.impronta.txt" && echo "SPECIE COME NELLA COPIA"
$PG/psql "$SUPABASE_DB_URL" -X -q -f scripts/tassonomia/controlli_spazio.sql
Q="select count(*) || ' ' || md5(string_agg(id::text || '|' || slug || '|' || taxon_id::text || '|' || categoria || '|' || epiteto || '|' || coalesce(gruppo, '') || '|' || coalesce(nome_commerciale, '') || '|' || coalesce(grex_id::text, ''), ',' order by id)) from public.cultivar"
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c "$Q" -c "select 'schede ' || count(*) from public.schede"
shasum -a 256 "$F4/esporta_schede/manifest.tsv"
```

Expected:
- `porta 5432`; se è diversa, fermarsi;
- `BACKUP LEGGIBILE` e `SPECIE COME NELLA COPIA`. Se no, fermarsi: il contenuto da cui nascono le schede è cambiato;
- `somma_db_mb` circa 362, `wal_mb` sotto 300;
- `196303 7294967f2fd4e835c21d92073ba264f1` (come la copia) e `schede 0`;
- lo sha256 uguale a quello annotato nel Task 3. Se no, fermarsi.

- [ ] **Step 2: Via esplicito dell'utente**

Chiedere in chat il via, dicendo:
- **cosa entra:** 15.770 schede, di cui 14.507 mostrate, con le fonti tolte dai testi e le 24 correzioni a mano;
- **durata:** circa 11 minuti, di cui 10 di pausa voluta prima degli indici;
- **effetto sull'app:** nessuno, perché l'app non legge ancora queste tabelle;
- **spazio:** circa 33 MB in più, fino a circa 395 MB su 500;
- **dati:** non cambia niente fuori da `schede`; l'impronta di `specie` si confronta prima e dopo;
- **ripresa:** se si interrompe basta rilanciare lo stesso comando;
- **rollback:** pronto e provato (`rollback_fase4b.sql`).

Senza un sì esplicito ci si ferma qui.

- [ ] **Step 3: Caricare**

Va lanciato dalla sessione principale in background (`run_in_background`), da uno script che imposta da sé `PG`, `F4` e `BK` (in background ogni chiamata è una shell nuova). Se il controllo dei permessi lo blocca, dare all'utente lo stesso blocco da incollare nel suo terminale. Per sapere se è attivo usare `pgrep -f carica_`, che stampa solo il pid. Se tra lo Step 1 e lo Step 3 è passato molto tempo, prima di lanciare rifare l'impronta di `specie` e il confronto dello Step 1.

```bash
set -a; source .env.local; set +a
OUT=backups/fase4b_$(date +%Y%m%d_%H%M%S)
CONFERMO_CARICAMENTO_REALE=si bash scripts/tassonomia/carica_schede.sh "$SUPABASE_DB_URL" "$F4/esporta_schede" "$OUT" > "$OUT.log" 2>&1; echo "uscita $?"
diff "${BK%.dump}.impronta.txt" "$OUT/impronta_specie_prima.txt" && diff "${BK%.dump}.impronta.txt" "$OUT/impronta_specie_dopo.txt" && echo "SPECIE INVARIATA DALLO STEP 1"
```

Expected:
- `uscita 0`;
- in `$OUT.log` la NOTICE `schede: 15770 (mostrate 14507, su cultivar 278, con nota 74); inventario per campo e per fonte uguale a specie` e `CARICAMENTO SCHEDE OK`;
- `SPECIE INVARIATA DALLO STEP 1`;
- somma dei database circa 395 MB.

Se l'uscita non è 0, prima di tutto (sola lettura) `controlli_spazio.sql` e i conteggi dello Step 1. Poi:
- **`FERMATO: spazio insufficiente`, interruzione o connessione persa:** rilanciare lo stesso comando, che salta i passi fatti;
- **`RIFIUTATO`:** non è stato scritto niente; riferire;
- **`FALLITO: specie è cambiata` o un errore della verifica:** fermarsi e riferire. Il rollback si decide insieme: `rollback_fase4b.sql` con `psql -1`, poi `vacuum full public.schede`.

- [ ] **Step 4: Controlli finali**

```bash
set -a; source .env; source .env.local; set +a
curl -s -o /dev/null -w 'schede mostrate con la chiave pubblica: %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/schede?select=descrizione,alert,immagine&mostrata=eq.true&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
curl -s -o /dev/null -w 'nota delle schede con la chiave pubblica: %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/schede?select=nota&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
curl -s -o /dev/null -w 'fonti delle schede con la chiave pubblica: %{http_code}\n' "$VITE_SUPABASE_URL/rest/v1/schede?select=fonti&limit=1" \
  -H "apikey: $VITE_SUPABASE_ANON_KEY" -H "Authorization: Bearer $VITE_SUPABASE_ANON_KEY"
$PG/psql "$SUPABASE_DB_URL" -X -qAt -c 'show statement_timeout' -c 'show lock_timeout'
```

Expected:
- `schede mostrate con la chiave pubblica: 200`: le colonne pubbliche si leggono;
- `nota delle schede con la chiave pubblica: 401` e `fonti delle schede con la chiave pubblica: 401`;
- `2min` e `0`.

- [ ] **Step 5: CLAUDE.md**

1. La copia locale resta accesa: la 4c la usa.
2. In `CLAUDE.md`, il titolo "### Modello tassonomico (in corso, fasi 1, 1b, 2, 3 e 4a di 7 applicate)" diventa "### Modello tassonomico (in corso, fasi 1, 1b, 2, 3, 4a e 4b di 7 applicate)" e in fondo alla sezione va aggiunto questo paragrafo, con le misure reali al posto di quelle attese se diverse:

```markdown
La fase 4b (piano `docs/superpowers/plans/2026-10-20-modello-tassonomico-fase4b-schede.md`) ha caricato `schede`: 15.770 schede, una per ogni riga di contenuto della vecchia `specie` (15.678 righe non cultivar, 45 cultivar orfane, 12 cultivar con una descrizione propria) e per le 35 madri cancellate lette dai file di rollback.
- **Aggancio:** sull'accettato del nome trovato in `mappa_specie` (per un sinonimo che porta a un autonimo, sulla specie); grex, Gruppo Dunedin e cultivar sulla loro cultivar (278 schede); le righe «Genere spp.», *Sansevieria* compresa, sul genere.
- **Mostrate:** 14.507, una per aggancio, scelte con la regola della decisione 3 della fase 4 (idonea, verificata, delle piante dell'utente, genere accettato, completezza sui valori utili…); le 91 righe usate dalle piante dell'utente sono tutte mostrate. Le 363 schede di specie finite su un genere o più in alto non sono idonee: restano collegate ma non sono mai mostrate.
- **Testi:** le fonti sono tolte dai testi leggibili (avviso di bozza PFAF, etichette «Da RHS…», rischi e rusticità riscritti, rusticità in gradi) con le funzioni di `schede_testi.sql`, nella stessa SELECT dell'inserimento; 24 correzioni a mano in `scripts/tassonomia/dati/fase4_schede_a_mano.tsv`; le note di lavorazione sono in `schede.nota` (interna, 74 schede). Restano in inglese, segnati, gli avvisi e le descrizioni che lo erano: la traduzione è sospesa fino alla fine della fase 4. Le foto hanno ancora i dati per il credito (url senza utm, autore, licenza, pagina).
- **Inventario:** `verifica_fase4b.sql` controlla che per campo e per fonte le schede abbiano gli stessi numeri delle righe di `specie` da cui vengono.
- **Spazio:** circa 395 MB su 500; WAL 34,9 MB per un lotto. Backup preso prima: il file `$BK` dello Step 1 (`backups/completo_…_pre_fase4b.dump`).
- **Script, tutti in `scripts/tassonomia/`:** `schede_testi.sql` (prove `prova_schede_testi.sql`); `schede_rollback_madri.py`, `schede_proposte.sql` e `prova_schede.sql` (copia locale); `schede_esporta.sh`, `carica_schede.sh`, `verifica_fase4b.sql`, `rollback_fase4b.sql` (rifiutato se una scheda è stata modificata dopo il caricamento). `rollback_fase4a.sql` ora si rifiuta con qualsiasi riga in `schede` o `nomi_comuni`.
- **Prove:** `bash scripts/tassonomia/prova_fase4b.sh URL_COPIA CARTELLA_ESPORTA CARTELLA`, su una copia con la fase 4a e `schede` vuota.
```

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "Tassonomia fase 4b applicata: schede (15.770, 14.507 mostrate), CLAUDE.md"
```

Nessun push senza richiesta dell'utente.
