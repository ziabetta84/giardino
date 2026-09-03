# Esito — Rollout FoglioLaterale + restyle ModalConferma + debiti SelettoreSpecie

Branch `foglio-laterale-rollout` · **mergiato su `main`** (merge `a65093b`), deploy GitHub Pages OK, 03/09/2026.
Piano: `2026-09-03-foglio-laterale-rollout.md`. Esecuzione subagent-driven: 5 task (T2+T3+T4 in un unico dispatch batch), review per task + review finale whole-branch, tutte pulite.

## Fatto

| Commit | Cosa |
|---|---|
| `bda38be` | `main.css`: utility condivise **`.foglio-form`** (padding contenuto — `.foglio__body` è senza padding di proposito) e **`.foglio-actions`** (riga pulsanti con filetto). **ProgettiView** — modale "Nuovo progetto" → `<FoglioLaterale>` (`:model-value` a una via + `@update:model-value` → `chiudiForm()` nuova, che resetta il form); rimossi gli scoped `.overlay`/`.modal-box` (blocco `<style scoped>` vuoto eliminato). |
| `8eb34c5` | Piano del round. |
| `485105f` | **ConcimiView** — modale nuovo/modifica concime → `<FoglioLaterale>` (`:titolo` = "Modifica/Nuovo concime"). NPK, textarea, toggle disponibilità invariati. `ModalConferma` per l'eliminazione invariata. Corretto il commento stale sopra `.feedlist .feed--tap` (citava `.care-act` "in PiantaView", ora classe globale; "modale" → "foglio"). |
| `6aa98f4` | **SottozoneView** — modale nuova/modifica sottozona → `<FoglioLaterale>`. Griglia icone (`max-height:140px` scroll proprio), select tipo, checkbox esposizione invariati. `ModalConferma` invariata. |
| `941a355` | **ModalConferma** — resta dialog centrato (le conferme distruttive sono una categoria UX a parte). Ritocchi: raggio 20→22px, titolo su `--font-display` (classe `.mc-titolo`), `Esc` per annullare (focus sul box all'apertura via `watch` su `props.aperto`), animazione `fade+scale` 150ms annullata da `prefers-reduced-motion`. **API prop/emit invariata** — i ~10 call site non toccati. |
| `0096b89` | **SelettoreSpecie** — markup di riga del dropdown accorpato: da 3 blocchi ripetuti (posseduta / catalogo / lista piatta) a un solo `v-for` su `gruppiDropdown` (`[{ label, voci }]`). DOM identico. `hero` guadagna `miniUrl` (96px): la miniatura 44px della card compatta (`.sc-th`) non usa più `hero.thumbUrl` (480px). Contratto `v-model` intatto. |

**Pattern `FoglioLaterale` ora in 5 punti**: SelettoreSpecie, AttivitaView (via AttivitaRiga), ProgettiView, ConcimiView, SottozoneView. Restano modali/overlay non convertiti *di proposito*: `ModalConferma` (dialog centrato, scelta), `AgenteView` (composer richieste AI, fuori scope), `LightboxFoto`/`BootLogo`/`GalleryView` (non sono form).

## Ruling preso in autonomia durante l'esecuzione

- **Review finale whole-branch su `sonnet` anziché `opus`.** Primo tentativo su opus fallito con `API 529 Overloaded` (capacità lato provider), nessun output prodotto. Ridispacciata su sonnet per non bloccare il round: il branch è 6 commit di trascrizione, ognuno già revisionato singolarmente (spec + quality, `npm run build` eseguito dai reviewer). *Costo se sbagliato:* un problema d'integrazione cross-cutting scivola al QA browser.

## Da guardare nel QA browser (Minor differiti — nessuno bloccante)

- **I 3 fogli** (Progetti / Concimi / Sottozone): apertura da ＋Aggiungi (da destra ≥640px, dal basso <640px); chiusura via `Esc` / click sul velo / ×; il form si resetta ad ogni chiusura; "Salva" chiude su successo; in modifica (Concimi/Sottozone) il titolo dice "Modifica …"; con *riduci animazioni* niente slide.
- **SottozoneView**: scroll annidato della griglia icone (`max-height:140px`) dentro `.foglio__body` scrollabile.
- **ModalConferma**: il restyle (raggio 22 + fade) tocca **~10 call site**, non solo i 3 del piano — anche `PiantaView` (×2), `ProgettoView`, `GalleryView`, `AgenteView`, `AccountView`, `PianteView`. API invariata, ma vale un'occhiata anche lì.
- **SelettoreSpecie**: gruppi della tendina + miniatura della card compatta post-scelta (ora più nitida, meno banda).
- Osservazioni della review finale, tutte cosmetiche/inerti: `ModalConferma` non ripristina il focus alla chiusura (non era gestito neanche prima — non è regressione); `watch(() => props.aperto)` senza `immediate` (inerte: tutti i caller montano con ref falsy); `ConcimiView` non azzera `modificaId` in `chiudiForm` (header "Modifica concime" visibile per i ~260ms dello slide-out); `ProgettiView.vue` senza newline finale; ordine dell'`import FoglioLaterale`; riga vuota di troppo in `SottozoneView` `<style>`. `--font-serif` non è definito in `main.css` → il cambio a `--font-display` sull'h3 di ModalConferma è un no-op reale.

## Fuori scope — round successivi

- **Redesign MeteoView** in stile taccuino: registro verticale (una riga/giorno, filetti come carta rigata), apertura "Adesso" editoriale, nastro orario, avvisi a margine, barra escursione min–max per giorno, dettaglio giorno nel `FoglioLaterale`. Include l'estensione di `useMeteo` alle ore di **tutti i 7 giorni** (oggi `slice(0,24)`) + mini-grafico orario nel foglio. Round dedicato, con mockup Artifact.
- **Sicurezza**: migration per restringere le policy RLS di `INSERT`/`UPDATE` sulla tabella `specie` (lettura pubblica, scrittura solo curatore/service-role). Round dedicato — vedi `2026-09-03-selettore-specie-redesign-esito.md` § Sicurezza.
- **`useCureVisual.js`**: naming improprio (non è un vero composable). Rinominarlo tocca 3 import per zero guadagno funzionale — semmai in Fase 3.
- **Fase 3**: dark mode. **Fase 4**: velatura stagionale dell'hero della Home.
