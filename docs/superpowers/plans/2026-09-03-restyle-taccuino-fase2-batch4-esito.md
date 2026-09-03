# Restyle "Taccuino" — Fase 2 Batch 4 (SelettoreSpecie) · Nota di esito

Branch: `restyle-taccuino-batch4` · commit `2154b46`..`e3fc562` (2 commit, 2 file — 1 codice + piano).
Subagent-driven: 1 task impl + review. Sola presentazione; `<script setup>` byte-identical (shasum invariato). `npm run build` verde. `grep` di regressione sull'intero file → nessun residuo.

## Fatto

`src/components/SelettoreSpecie.vue` (commit `e3fc562`):
- **3× `var(--font-serif)` → `var(--font-display)`** — `--font-serif` era stato rimosso in Fase 1, quindi risolveva a nulla e i tre punti (`.scheda-nome`, `.scheda-descrizione`, `<h3>` della modale) cadevano sul font ereditato. Bug latente chiuso.
- **12 `<label style="…text-transform:uppercase…">`** (intestazioni di sezione della modale nuova/modifica specie) → `<label class="field-label">` (la classe globale di Batch 3). La label "Potatura" tiene `display:flex` + icona come override inline.
- **9 `<p style="font-size:11px;color:var(--ink-faint)…">`** (testi di aiuto) → `<p class="campo-hint">` (nuova classe **scoped**, unica aggiunta CSS del batch).
- `.campo-label` (19 usi, l'etichetta fine dei sotto-campi), il combobox, la `.modal-box`, i `.badge` mini e il contenitore `.scheda-specie` non toccati (solo i loro token di font).

## Chiude l'arco "restyle di tutte le viste"

Con Batch 4 tutte le viste e i componenti dell'app usano il linguaggio "Taccuino":
Fase 1 (Home, Scheda pianta, cornice) + Fase 2 Batch 1 (Progetti, Progetto, Galleria, Zorba dice) + Batch 2 (Zone, Sottozone, Concimi, Attività) + Batch 3 (Meteo, Account, Impostazioni, EditZona, EditPianta) + Batch 4 (SelettoreSpecie).

## Da guardare nel QA browser

- Modale nuova/modifica specie: le 3 tab (Generale / Cure / Coltivazione), le label di sezione ora uniformi (`.field-label`), i testi di aiuto uniformi (`.campo-hint`).
- Combobox + dropdown + scheda di sola lettura: struttura invariata, controllare solo che il testo (nome/descrizione specie) sia in Fraunces.
- I due punti d'uso: "Modifica pianta" (`/piante/nuova`) e "Zorba dice" → richiesta "revisione specie".

## Minori / debito (invariato dalle note precedenti)

- 7 `style="margin:…"` una-tantum su `.campo-hint` senza `;` finale (cosmetico).
- `.scheda-*` di SelettoreSpecie resta un'implementazione parallela della sezione "La specie" di PiantaView (`.specie`/`.kv`/`.prose`) — non unificata; da valutare in un giro di consolidamento CSS.
- Debito CSS raccolto in Fase 2/Batch 3: `.chip` da rifare base-chiara + `--on-photo`; `button.pill-mini, a.pill-mini { cursor:pointer }` globale; `.section-label` ancora in `main.css` ma non più usata (sweep); `.card` sulle righe tab Progetti in Attività; `.slabel` che rende maiuscoli i nomi zona.

## Fuori scope (round successivi)

- **Fase 3**: dark mode — interruttore in Impostazioni (`SettingsView` salva già `ui.theme`), palette scura calda, blocchi `@media (prefers-color-scheme: dark)` + `:root[data-theme="dark"]` da aggiungere ai token in `main.css`.
- **Fase 4**: velatura stagionale dell'hero della Home.
