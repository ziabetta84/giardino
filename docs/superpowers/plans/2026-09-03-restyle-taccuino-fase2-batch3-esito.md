# Restyle "Taccuino" — Fase 2 Batch 3 · Nota di esito

Branch: `restyle-taccuino-batch3` · commit `dfdb0e8`..`778e845` (5 commit, 6 file).
Subagent-driven: 4 task + review per task. Sola presentazione (template + CSS); `<script setup>` **byte-identical** in tutte le viste toccate (verificato da ogni review). `npm run build` verde a ogni task e sul branch finale. `grep` di regressione (`title-display|gradient-title|title-settle|title-serif|text-light|section-label|--font-serif`) sulle 5 viste → **nessun residuo**. **Non ancora mergiato** — decide Rob dopo il QA browser.

## Fatto

| Task | File | Commit |
|---|---|---|
| 1 | `main.css` — classi condivise `.field-label` (etichetta di campo uppercase) e `.form-card` (sezione di form: bordo leggero, radius 14, niente ombra) | `dfdb0e8` |
| 2 | **MeteoView** — `<h1>` → `.page-title`; 3× `section-label` → `.slabel`; box "avvisi" e "ora per ora" → `.form-card`; numeri temperatura → scoped `.meteo-temp` (Fraunces); `text-light` rimosso; `.meteo-label` da `--font-serif` a `--font-display` | `158b364` |
| 3 | **AccountView + SettingsView** — `<h1>` → `.page-title`; `section-label` → `.slabel`; card di form → `.form-card`; regola scoped `.field-label` rimossa da AccountView (ora globale); reset scoped `.form-card > .slabel:first-child { margin-top:0 }` | `aaa86e7` |
| 4 | **EditZonaView + EditPiantaView** — `<h1>` → `.page-title`; 3+3 `.card` di form → `.form-card`; 6+7 `<label style="…11px…uppercase…">` ripetute inline → `<label class="field-label">` (2 con `margin-top:12px` una-tantum); griglia icone zona, `SelettoreSpecie`, `salva()`+rename a cascata invariati | `778e845` |

## Da guardare nel QA browser (decisioni di design, non bug)

1. **`.slabel` su tutte le pagine di servizio** — ora le intestazioni di sezione ("Adesso", "Posizione", "Token GitHub"…) hanno la linea-filetto `::after` del `.slabel`. È il linguaggio Taccuino (coerente con Home/Attività), ma è un cambiamento visibile rispetto al vecchio `.section-label` piatto. In particolare l'occhiello "Adesso" dentro la card meteo, in colonna stretta, con la riga a fianco: se non convince, una classe scoped senza `::after` per quei punti.
2. **`.form-card` vs `.card`** — le sezioni di form ora hanno bordo leggero senza ombra invece della card piena (radius 20 + ombra). Voluto (alleggerimento), da confermare che l'insieme regga.
3. **MeteoView** — controllare i due numeri grandi di temperatura (`.meteo-temp`, Fraunces) e che nessun testo abbia perso colore togliendo `text-light`.
4. **EditPianta / EditZona** — le `.field-label` ora sono tutte uguali (dalla classe globale); verificare la spaziatura sopra le label con `margin-top:12px` (Icona, Microclima in EditZona).

## Minori / debito

- `margin-top:12px` inline su due label di EditZona senza `;` finale (cosmetico).
- `.meteo-temp` ha ancora `font-weight:800` inline ridondante (la classe lo porta già).
- Il `::after` di `.slabel` dentro contenitori stretti (occhiello meteo) — vedi punto 1: candidato a un modificatore `.slabel--plain` se emerge in più punti.

## Fuori scope (round successivi)

- **Batch 4**: `SelettoreSpecie.vue` (l'ultima con stile proprio non allineato).
- **Fase 3**: dark mode (interruttore in Impostazioni — SettingsView ora ha `form.ui.theme` che salva già `'auto'`).
- **Fase 4**: velatura stagionale dell'hero.
- Debito raccolto in Fase 2 (nota esito Batch 1+2): `.chip` base-chiara + `--on-photo`; `button.pill-mini,a.pill-mini{cursor:pointer}` globale; unificare vocabolario caroselli; `.card` sulle righe tab Progetti in Attività; `.slabel` che maiuscola i nomi zona.
