# Esito — Sweep cosmetico (debiti minori sparsi)

Branch `sweep-cosmetico` · **mergiato su `main`** (merge `87ba1cd`), 04/09/2026.
Piano: `2026-09-04-sweep-cosmetico.md`. Triage A–G approvato in chat (nessuna spec formale). Esecuzione subagent-driven: 3 task + review per task + review finale su Opus + 1 fix wave (2 Important + 1 Minor) + re-review scoped.

## Fatto

| Commit | Cosa |
|---|---|
| `c2e81c3` | **Batch A/B/C/F/G**: catch-all route (`{ path: '/:pathMatch(.*)*', redirect: '/' }`, i vecchi `/zone/nuova` ecc. non danno più pagina bianca); `.pill-mini` `cursor:pointer` di base (era `default`, ridefinito scoped in 2 view); `.dossier-x` `:hover`/`:focus-visible` (`currentColor`, vale per entrambe le varianti); `MeteoGiorno`: il mini-grafico non pianta più un punto a 0° se un'ora non ha temperatura; `role="button"` (Adesso/registro Meteo, AttivitaRiga) accetta anche Spazio; `.day:hover` solo sotto `@media(hover:hover)`. |
| `04859d8` | **Unificati `.alert-cura`/`.alert-meteo`** → `.alertbox`(+`.alertbox--rose`) globale in `main.css`. Restano scoped solo le righe (`__row`), layout diverso tra i due consumatori (label+bottone in PiantaView, icona+testo in MeteoView). |
| `916e805` | **`.chip`** da cablata-per-foto a chiara di base, nuova `.chip--on-photo` per il caso foto. Eliminate due reimplementazioni: `PiantaView.phead-text__chip*` (scoped, quasi identica) e l'override scoped di `GalleryView`. |
| `c68ab42` | Piano. |
| `99e60f8` | **Fix review finale**: `GalleryView` — `.gpost__hd .chip` aveva perso `--acqua`/`--acqua-dark: currentColor` (la nuova base `.chip` non li forza più), l'icona zona tornava azzurra invece di monocroma — ripristinato, zero cambio visivo. `HomeView` — il bottone "Fatto" in "Da fare oggi" (mai avuto un `@click`) sembrava ora cliccabile col `cursor:pointer` di base di `.pill-mini` — ripristinato l'aspetto non-interattivo (**non wireato**, resta fuori scope). `AgenteView` — una quarta riga `role="button"` (storico richieste), dimenticata dal batch F2, ha ora anche lei lo Spazio. |

## Ruling presi in autonomia

Nessuno tocca sicurezza o produzione. Tutti a costo nullo/basso se sbagliati:

- **Non incluso nella fix wave**: commento di sezione in `main.css` sopra `.chip`, un po' generico dopo il cambio — copre un blocco ampio (header foto scheda pianta), non solo il chip. Costo se sbagliato: nullo, è un commento.
- **Differito**: `class="card alertbox"` in PiantaView — `.card` non aggiunge più nulla visivamente (`.alertbox` sovrascrive background/border/radius/shadow). Segnalato dalla review finale come nota di fragilità futura (un `.card` aggiunto dopo la riga 725 di `main.css` potrebbe "ri-vestire" l'alert senza che nessuno se ne accorga), non un difetto vivo oggi.
- **Differito**: naming `.alertbox__rows > .alert-cura__row` / `.alert-meteo__row` — è la decisione esplicita del piano (i due layout di riga restano scoped, non forzati in una forma comune), non un finding nuovo.

## Fuori scope confermato in triage (non toccato)

- `.section-label` — ancora usata da `PianteView` (2 volte); convertirla a `.slabel` è una scelta di design, non pulizia.
- Vocabolario caroselli (`.gtrack`/`.gslide` vs `.gpost`) — non è duplicazione, sono concetti diversi.
- `@media (hover:hover)` esteso a tutti i `:hover` dell'app — fatto solo su `.day` (finding esplicito del round Meteo).

## Da guardare nel QA browser

- **Galleria**: icona zona nell'intestazione dei post — deve restare monocromatica come il testo del chip (non azzurra).
- **Home → "Da fare oggi"**: il bottone "Fatto" ha di nuovo il cursore statico (non promette un'azione che non fa).
- **Scheda pianta**: header con foto — chip zona/vaso chiari sulla foto, invariati. Header senza foto — chip invariati (ora condivisi). Blocco "Da curare subito" — invariato (ora `.alertbox`).
- **Meteo**: blocco "Occhio a questi giorni" — invariato (`.alertbox--rose`, margine 22px/2px preservato). Registro: hover solo con mouse/trackpad, non appiccicato dopo un tap; `.adesso` e le righe si aprono anche con Spazio.
- **Attività**: Spazio su una riga apre il dossier. **Agente**: Spazio su una riga dello storico la seleziona.
- **Selettore specie**: la × sul foglio-dossier ha hover/focus visibili (foto e senza-foto).
- **Zone/Sottozone/Home**: cursore a manina su Sottozone/matita/×.
- **URL ritirati**: `#/zone/nuova` (o qualunque path inesistente) porta alla Home invece che a pagina vuota.
