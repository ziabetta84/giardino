# CLAUDE.md

Questo file fornisce indicazioni a Claude Code (claude.ai/code) per lavorare in questo repository.

## Panoramica del progetto

**Giardino di Rob** — applicazione web Vue 3 per la gestione di un giardino personale a Centinarola, Fano (PU), Italia. Tutti i contenuti sono in italiano.

## Comandi principali

```bash
npm run dev      # avvia dev server (localhost:5173)
npm run build    # build produzione → dist/
npm run preview  # anteprima build locale
```

Il deploy su GitHub Pages avviene automaticamente tramite GitHub Actions (`.github/workflows/deploy.yml`) ad ogni push su `main`: pubblica `dist/` sul branch `gh-pages`. La sorgente di GitHub Pages va impostata sul branch `gh-pages`.

## Architettura

```
src/
├── main.js                  ← bootstrap Vue + Pinia + Router
├── App.vue                  ← layout globale (NavBar, BottomNav, StatusBar, banner token)
├── router/index.js          ← route con createWebHashHistory (necessario per gh-pages)
├── stores/dati.js           ← Pinia store: carica tutti i JSON una volta sola
├── composables/
│   ├── useApi.js            ← GitHub API: saveJSON(), uploadFile(), token management
│   ├── useMeteo.js          ← Open-Meteo (no API key)
│   └── useCure.js           ← logica urgenze cure (irrigazione, concimazione, potatura)
├── components/
│   ├── PiantaRiga.vue       ← riga pianta riutilizzabile (usata in PianteView)
│   └── ModalConferma.vue    ← dialog eliminazione generico
└── views/                   ← una view per route
public/data/                 ← JSON letti a runtime dal frontend
docs/                        ← vecchio sito Jekyll (non più attivo)
docs/gallery/piante/         ← foto piante organizzate per {id-pianta}/
```

## Dati e persistenza

Tutti i dati vivono in `public/data/` come JSON. Le scritture avvengono tramite la **GitHub Contents API** (`useApi.js → saveJSON`), che richiede un Personal Access Token con scope `contents:write` salvato in `localStorage.github_token`.

| File | Contenuto |
|------|-----------|
| `piante.json` | Piante con zona, sottozona, ultima_cura per tipo |
| `specie.json` | Profili di cura per specie (~100+ specie) con manutenzione stagionale |
| `zone.json` | Metadati delle 6 zone (nome, tipo, esposizione, microclima) |
| `sottozone.json` | Sottozone indicizzate per chiave zona |
| `richieste-agente.json` | Coda richieste AI (stato: in_attesa → completata/errore) |
| `settings.json` | Coordinate GPS per Open-Meteo |

## Coda richieste agente AI

Le richieste create da `AgenteView.vue` vengono scritte in `richieste-agente.json` con stato `in_attesa`. Claude Code legge la coda, elabora le richieste (può includere foto in base64), aggiorna il JSON con `stato: completata` e `risposta.messaggio`, poi fa commit.

Schema richiesta:
```json
{
  "tipo": "identifica_specie | consiglio_cura | diagnosi | altro",
  "messaggio": "...",
  "foto": "<base64 opzionale>",
  "stato": "in_attesa",
  "creata": "<ISO>",
  "risposta": null
}
```

## Logica cure (`useCure.js`)

`valutaCura(pianta, specie, tipo)` legge `specie.manutenzione[tipo][stagione]`, calcola i giorni dall'ultima cura e restituisce `{ urgente, label, giorni }`. `cureUrgentiPianta` filtra solo i tipi urgenti. La stagione è calcolata dal mese corrente.

## Gallery

Le foto esistenti sono in `docs/gallery/piante/{id-pianta}/{timestamp}_{filename}.jpg` sul branch `main` e vengono servite tramite URL raw di GitHub. I caricamenti nuovi seguono la stessa struttura. La `GalleryView` usa la Contents API per listare le cartelle e costruisce gli URL raw.

## Palette e design

```css
--rose: #cc6e6e  --gold: #e0b84a  --sage: #7a9e82  --olive: #9aaa5a  --cream: #faf7f2
```
Font: Playfair Display (titoli display) · Lora (serif secondario) · DM Sans (UI/body).
Classi globali: `.card`, `.btn`, `.btn-rose/sage/ghost`, `.badge`, `.pill`, `.skeleton`, `.form-input`, `.search-input`, `.title-display`, `.gradient-title`, `.section-label`.
