# Sistema notifiche GitHub (mobile)

Questo modulo genera notifiche automatiche per il giardino usando:

- meteo locale (Open-Meteo)
- analisi dei file in `zone/` (piante e cure)
- analisi dei file in `progetti/` (stato lavori)
- pubblicazione su GitHub Issue + commento (notifica su app GitHub)

## Struttura

- `notifiche-github/config.giardino.json`: coordinate e impostazioni
- `notifiche-github/genera_notifica.py`: genera titolo e report markdown
- `.github/workflows/notifiche-giardino.yml`: schedulazione e invio notifica

## Configurazione coordinate

Le coordinate sono gia impostate su:

- latitudine: `43.830961`
- longitudine: `12.9885673`
- localita: `Centinarola, Fano (PU), Italia`
- timezone: `Europe/Rome`

Per cambiarle modifica `notifiche-github/config.giardino.json`.

## Come funziona la notifica

Ad ogni esecuzione del workflow:

1. viene chiamato Open-Meteo per oggi/domani
2. vengono lette le piante documentate in `zone/**/piante/**/*.md`
3. vengono estratti suggerimenti da sezioni `Potatura e manutenzione` / `Coltivazione`
4. vengono letti i progetti in `progetti/*.md` e lo stato attuale
5. viene aggiornata (o creata) una issue con label `notifiche-giardino`
6. viene aggiunto un commento con mention all'owner, per trigger notifica mobile

## Trigger workflow

- manuale (`workflow_dispatch`)
- giornaliero (`cron`, ore 06:00 UTC)
- automatico quando cambiano file in `zone/`, `progetti/`, `manutenzione/`, `notifiche-github/`

## Test locale rapido

Da root repository:

```bash
python notifiche-github/genera_notifica.py \
  --repo-root . \
  --config notifiche-github/config.giardino.json \
  --output-title /tmp/notifica-title.txt \
  --output-body /tmp/notifica-body.md
```

Poi controlla:

```bash
cat /tmp/notifica-title.txt
head -n 60 /tmp/notifica-body.md
```