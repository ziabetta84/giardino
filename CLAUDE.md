# CLAUDE.md

Questo file fornisce indicazioni a Claude Code (claude.ai/code) per lavorare in questo repository.

## Panoramica del progetto

**Giardino di Rob** — applicazione web per la gestione di un giardino personale a Centinarola, Fano (PU), Italia. Tutti i contenuti sono in italiano. Il repository contiene esclusivamente il frontend statico (GitHub Pages) e i dati in JSON.

Non esiste uno step di build. Non ci sono script Python né pipeline di dati. Il frontend legge direttamente i file JSON in `docs/data/`.

## Architettura

```
docs/
├── data/          ← fonte primaria di tutti i dati (JSON)
├── js/            ← moduli JavaScript (vanilla, no framework)
├── _layouts/      ← layout Jekyll
├── _includes/     ← partial Jekyll (nav, scripts, status)
├── agente.html    ← chat con l'assistente AI
└── attivita.html  ← registro attività
```

### File dati (`docs/data/`)

| File | Contenuto |
|------|-----------|
| `piante.json` | Tutte le piante con stato e storico cure |
| `specie.json` | Profili di cura per specie (~100+ specie) |
| `zone.json` | Metadati delle 6 zone del giardino |
| `sottozone.json` | Metadati delle sottozone |
| `richieste-agente.json` | Coda richieste per l'assistente AI |
| `settings.json` | Coordinate, provider meteo (Open-Meteo), unità di misura |

### Coda richieste agente AI

Le richieste inviate dall'utente tramite `agente.html` vengono accodate in `richieste-agente.json`. Claude Code legge la coda, genera le risposte, aggiorna il JSON e fa il commit. Vedi `cloudflare-worker/README.md` per lo schema (il file è stato rimosso ma il protocollo resta valido).

### Modificare i dati

Tutti gli aggiornamenti (nuove piante, cure, note) si fanno **editando direttamente i file JSON** in `docs/data/`. Non esistono script di sincronizzazione.
