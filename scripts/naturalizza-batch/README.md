# Naturalizzazione/traduzione descrizioni via Anthropic Message Batches API

Script per finire la naturalizzazione dello stile delle `descrizione` (issue **#153**),
sulla parte rimasta in inglese: le ~108 righe residue del lotto "inglese nascosto"
e il blocco RHS marcato (~11.700 righe). Fatto come script separato, fuori da
Claude Code, perché il costo osservato via agenti/fork Claude Code era enorme
(~11.000-12.500 token per riga, quasi tutto overhead di tool-calling) — vedi
memoria di progetto "naturalizzazione-descrizioni" per l'analisi completa.

Regole di stile complete: `.claude/commands/naturalizza-descrizioni.md` (qui
riprodotte in forma compatta nel system prompt di `submit_write_batch.py`).

## Setup

```bash
pip3 install anthropic
```

In `.env.local` (alla radice del repo, già gitignored) serve, oltre a
`SUPABASE_DB_URL` (già presente per `scripts/backup-db.sh`):

```
ANTHROPIC_API_KEY=sk-ant-...
```

**Impostare un limite di spesa sulla console Anthropic prima di lanciare il
batch grande** — un errore di prompt non deve tradursi in una bolletta a
sorpresa.

## Uso

1. **Backup**: `./scripts/backup-db.sh` (dalla radice del repo) — questo tocca
   righe già `verificato`.

2. **Prototipo su un campione piccolo** (fortemente raccomandato prima di
   lanciare il blocco grande — stessa disciplina usata per il resto di questa
   fase):
   ```bash
   cd scripts/naturalizza-batch
   python3 export_rows.py --source rhs --limit 25 --out prototipo.json
   python3 submit_write_batch.py --in prototipo.json --out write_batch_id.txt
   python3 fetch_results.py --batch-id $(cat write_batch_id.txt) --out write_results.json
   python3 submit_verify_batch.py --rows prototipo.json --write-results write_results.json --out verify_batch_id.txt
   python3 fetch_results.py --batch-id $(cat verify_batch_id.txt) --out verify_results.json
   python3 apply_results.py --rows prototipo.json --write-results write_results.json \
       --verify-results verify_results.json --sql-out update.sql --report-out report.json
   # controlla update.sql e report.json a mano, poi:
   python3 apply_results.py --rows prototipo.json --write-results write_results.json \
       --verify-results verify_results.json --sql-out update.sql --report-out report.json --apply
   ```

3. **Lotto vero**, stessa sequenza senza `--limit` (e con `--source hidden` per
   le 108 righe residue, `--source rhs` per il blocco grande, `--source all`
   per entrambi insieme):
   ```bash
   python3 export_rows.py --source rhs --out lotto_rhs.json
   python3 submit_write_batch.py --in lotto_rhs.json --out write_batch_id.txt
   python3 fetch_results.py --batch-id $(cat write_batch_id.txt) --out write_results.json
   python3 submit_verify_batch.py --rows lotto_rhs.json --write-results write_results.json --out verify_batch_id.txt
   python3 fetch_results.py --batch-id $(cat verify_batch_id.txt) --out verify_results.json
   python3 apply_results.py --rows lotto_rhs.json --write-results write_results.json \
       --verify-results verify_results.json --sql-out update.sql --report-out report.json --apply
   ```

## Comportamento su errori/budget esaurito

Ogni richiesta del batch ha un esito indipendente (`succeeded`/`errored`/
`canceled`/`expired`). `apply_results.py` scrive su Supabase **solo** le righe
`succeeded` con verdetto PASS: tutto il resto (errori, scadute, FAIL, fonte
troncata) resta intatto e finisce nel `report.json`. Siccome `export_rows.py`
seleziona le righe con una query sullo stato reale (non una lista fissa), se il
budget finisce a metà basta ripetere lo stesso comando di `export_rows.py` più
tardi: pescherà automaticamente solo le righe ancora da fare.

## Cose deliberatamente fuori scope di questo script

- **Cultivar agganciate al genere invece che alla specie** (bug pregresso, raro
  — un caso su centinaia di righe controllate a mano il 31/08): non viene
  controllato qui. Fare un audit mirato a parte se serve.
- **Righe con contenuto palesemente incoerente con la specie** (es.
  `bixa-orellana`, corretta a mano il 31/08): il prompt non ha una verifica
  esplicita per questo — se il verificatore Haiku lo nota lo segnala come FAIL
  nel report, altrimenti va scoperto a campione.
