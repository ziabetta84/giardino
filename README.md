# Giardino di Rob

Applicazione web per la gestione del giardino personale a Centinarola, Fano (PU), Italia.

---

## Struttura del repository

```text
giardino/
├── docs/        ← frontend GitHub Pages (HTML, JS, JSON)
├── generale/    ← foto generali del giardino
└── README.md
```

## Frontend (`docs/`)

Sito statico pubblicato su GitHub Pages, vanilla JavaScript senza framework. I dati sono gestiti tramite file JSON in `docs/data/` e il frontend li legge direttamente.

### Dati principali (`docs/data/`)

- `piante.json` — tutte le piante con stato e storico cure
- `specie.json` — profili di cura per specie
- `zone.json` / `sottozone.json` — metadati delle zone del giardino
- `richieste-agente.json` — coda richieste per l'assistente AI
- `settings.json` — coordinate, provider meteo (Open-Meteo), unità di misura

### Assistente AI (`docs/agente.html`)

Le richieste inviate dall'utente vengono accodate in `richieste-agente.json`. Claude Code legge la coda, genera le risposte, aggiorna il JSON e fa il commit.

---

## Licenza

Uso personale.
