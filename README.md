# Giardino di Rob

Applicazione web Vue 3 per la gestione di un giardino personale a Centinarola, Fano (PU), Italia.

---

## Comandi

```bash
npm run dev      # avvia dev server (localhost:5173)
npm run build    # build produzione → dist/
npm run preview  # anteprima build locale
```

L'app è pubblicata su https://zorbaingiardino.app (Cloudflare Pages): il workflow `.github/workflows/deploy-cloudflare.yml` la carica a ogni push su `main`.

## Struttura del repository

```text
giardino/
├── src/         ← app Vue 3 (Pinia, Vue Router) — vedi CLAUDE.md per i dettagli architetturali
├── public/data/ ← JSON letti a runtime dal frontend (piante, specie, zone, concimi, progetti, ...)
├── supabase/    ← migration SQL del progetto Supabase "Il Giardino di Zorba"
├── docs/        ← vecchio sito Jekyll (non più attivo)
└── README.md
```

### Dati principali (`public/data/`)

- `piante.json` — tutte le piante con zona, sottozona e storico cure
- `zone.json` / `sottozone.json` — metadati delle zone del giardino
- `concimi.json` — dispensa concimi posseduti
- `progetti.json` — progetti del giardino con tappe
- `richieste-agente.json` — coda richieste per l'assistente AI
- `settings.json` — coordinate, provider meteo (Open-Meteo)

### Assistente AI (`AgenteView.vue`)

Le richieste inviate dall'utente vengono accodate in `richieste-agente.json`. Claude Code elabora la coda (comando `/zorbadice`), genera le risposte, aggiorna il JSON (ed eventualmente le schede del catalogo e i progetti su Supabase) e fa il commit.

---

## Licenza

Uso personale.
