Lancia UN lotto di naturalizzazione dal blocco RHS (issue **#153**), con lo stesso metodo collaudato nei lotti 3-12: fork Claude Code diretto (non lo script Batches API, deciso esplicitamente con l'utente il 23/09 — vedi memoria `project-naturalizzazione-descrizioni`), verifica indipendente del coordinatore sempre dopo, mai fidarsi solo del report del fork. Le regole di stile complete sono nella skill `naturalizza-descrizioni` (`.claude/commands/naturalizza-descrizioni.md`) — leggila prima di scrivere il prompt del fork, potrebbe essere cambiata dall'ultima volta.

Argomenti opzionali (`$ARGUMENTS`): un numero per la dimensione del lotto (default 70) e/o `possedute` per dare priorità alle piante del giardino non ancora naturalizzate (come nel lotto10).

## Procedura

1. **Numero lotto**: `ls scripts/naturalizza-batch/lotto*_rhs.json` e prendi il numero più alto + 1.

2. **Priorità piante possedute** (sempre, non solo se richiesto esplicitamente — è economico da controllare):
   ```sql
   select distinct s.slug, s.nome
   from piante p join specie s on s.slug = p.specie
   where s.specie_padre_id is null and s.descrizione ilike '%testo originale in inglese%';
   ```
   Se non vuoto, esporta un lotto misto (quelle piante in testa + il resto in ordine di popolarità) con una query psql diretta come nel lotto10 (`export_rows.py` non supporta un filtro slug). Se vuoto, usa semplicemente:
   ```bash
   cd scripts/naturalizza-batch
   python3 export_rows.py --source rhs --order popolarita --limit <N> --out lottoN_rhs.json
   ```

3. **Backup**: `./scripts/backup-db.sh` dalla radice del repo, sempre prima di lanciare il fork.

4. **Lancia UN fork** (`Agent`, `subagent_type: "fork"`) con un prompt che include, sempre:
   - riscrivere lui stesso le righe (mai delegare a un altro sub-agente), leggendo la skill `naturalizza-descrizioni` aggiornata per le regole di stile correnti (elencale comunque nel prompt, non basta il nome della skill — i fork a volte non la rileggono da soli)
   - scrivere direttamente su Supabase (progetto `ncuhhsvtjwcolhpdxbkt`, tabella `specie`) via `psql` diretto (`$SUPABASE_DB_URL` da `.env.local`, transazione unica `ON_ERROR_STOP=1`) o `apply_migration`
   - vincoli invariati: niente `git add`/`git commit`, niente nuovi file nel repository (scratch nella sua scratchpad directory)
   - un'autoverifica SQL propria su tutte le righe scritte, prima di dichiarare il lotto concluso
   - se le piante possedute sono nel lotto, dedicare loro attenzione extra esplicita

5. **Se il fork torna a 0 tool-call o con un report implausibile** (es. dice "sta scrivendo in background", cifre che non può conoscere, tono da conversazione con l'utente invece che da report tecnico): **non fidarti**, verifica subito sul DB un campione di slug. Se non ha scritto, **riprendilo con `SendMessage`** sullo stesso agente invece di rilanciarne uno nuovo (vedi memoria `feedback-no-spreco-token-retry`).

6. **Verifica indipendente del coordinatore, sempre, su TUTTE le righe del lotto** (non un campione), indipendentemente da cosa riporta il fork:
   ```sql
   -- sostituisci l'array con gli slug del lotto
   with lottoN as (select unnest(array[...]) as slug)
   select
     count(*) as totale,
     count(*) filter (where s.descrizione ilike '%testo originale in inglese%') as ancora_inglese,
     count(*) filter (where s.descrizione ~* '^(Colore di fioritura|Periodo[i]? di fioritura( principale)?|Portamento|Forma)\s*:') as label_dump,
     count(*) filter (where exists (select 1 from unnest(s.alert) v where v ilike 'Rusticità RHS:%' and v ~* '(°c|gradi)')) as rusticita_alert_bug,
     count(*) filter (where s.descrizione ~* '(RHS|PFAF|Le Georgiche|la fonte|una fonte|un.altra fonte|secondo la|a seconda della)') as citazione_fonte,
     count(*) filter (where s.descrizione ~* '\mverificat[ao]e?\M') as nota_editoriale,
     count(*) filter (where s.descrizione is null or s.descrizione = '') as descrizione_vuota,
     count(*) filter (where s.alert is null or array_length(s.alert,1) is null) as alert_vuoto
   from lottoN l join specie s on s.slug = l.slug;
   ```
   Poi leggi per intero 3-4 righe a campione (sempre le piante possedute se presenti nel lotto, più eventuali casi limite segnalati dal fork) per un controllo di qualità sulla prosa, non solo sui pattern automatici — i controlli regex non intercettano tutto (vedi lo storico dei bug in memoria: label-dump, rusticità-in-alert in due varianti opposte, citazione-fonte in più forme, note editoriali "Verificata su X").

7. **`git status`**: conferma che resta pulito (a parte modifiche preesistenti già note).

8. **Aggiorna la memoria di progetto** `project-naturalizzazione-descrizioni` con: numero lotto, esito reale (non il report grezzo del fork), eventuali bug nuovi trovati e come sono stati corretti, nuovo totale naturalizzato e nuovo residuo (conteggio via query diretta, non a mente).

## Se emerge un nuovo bug di stile

Non limitarti a correggere le righe del lotto corrente: fai un audit DB-wide col pattern del bug (come per "Verificata su X", trovato il 29/09 su 8 righe di cui solo 3 erano bug reali su righe già naturalizzate) prima di dichiararlo chiuso, e aggiungi la regola alla skill `naturalizza-descrizioni.md` per i lotti futuri.
