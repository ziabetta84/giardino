# Restyle "Taccuino" — Fase 2 (Batch 1+2) · Nota di esito

Branch: `restyle-taccuino-fase2` · commit `8fcdd07`..`269f4d4` (12 commit, 11 file, +771/−674).
Eseguita subagent-driven (1 implementer + 1 reviewer per task, fix-loop, come Fase 1). `npm run build` verde a ogni task e sul branch finale. **Non ancora mergiata su `main`** — la merge la decide Rob dopo il QA nel browser.

## Fatto

| Task | Vista | Commit |
|---|---|---|
| 1 | `main.css` — classi Fase 2 (`.page-title`/`__row`, `.prow*`+`.st--*`, `.empty`, timeline `.path*`/`.step*`/`.pgoal`, drawer `.hstore*`/`.hitem*`/`.hback`/`.htoggle`/`.adot`, feed `.gpost*`, form agente `.reqchip*`/`.reqbox`/`.reqsend`/`.answer*`) + `prefers-reduced-motion` per la timeline | `8fcdd07` |
| 2 | **ProgettiView** — titolo Fraunces piatto, lista con filetti (`.prow`), chip di stato colorati (`.st--n/g/s/r`), date con mese per esteso | `cf48d29` |
| 3 | **ProgettoView** — intestazione Fraunces + **timeline tappe che si disegna sullo scroll** (linea dritta, `--draw` da scroll di `window`, gradiente `#trailGrad` per esito, pallini in sequenza, reduced-motion → statica) | `8fd30f4` + `0d589dd` |
| 4 | **GalleryView** — titolo Fraunces + feed `.gpost` per pianta, carosello allineato alla scheda pianta, overlay `.gov` (nuova, aggiunta in `main.css`) | `1fd1677` + `0b0ba8a` |
| 5 | **AgenteView** — storico conversazioni come **drawer da sinistra** (`.hstore`, scrollabile, "＋ Nuova"), form richiesta (`.reqchip`/`.reqbox`/`.reqsend`) e risposta (`.answer`) al linguaggio Taccuino; script invariato | `e8adf06` + `04c5743` |
| 6 | **ZoneView + SottozoneView** — griglia di card → liste di destinazioni (`.destlist`/`.dest`), icona acquerellata + nome + conteggio; tutte le azioni conservate (piante, sottozone, modifica, elimina + delete-guard) | `aa75117` + `d24e37e` |
| 7 | **ConcimiView** — lista piatta (`.feed`) con NPK + tag "terminato", toggle disponibilità mantenuto | `c06f7a5` |
| 8 | **Attività** (`AttivitaView` + `AttivitaGruppoZona` + `AttivitaRiga`) — titolo Fraunces + data, tab e righe al linguaggio; **logica invariata** (tab, raggruppamento per zona, espansione, ✓ Fatto singolo + bulk) — solo classi/wrapper/token | `269f4d4` |

## Da guardare nel QA browser (decisioni di design, non bug)

1. **Attività / tab Progetti** — le righe "Tappe progetto" hanno ancora `class="card"` (fuori dall'elenco di modifiche del Task 8): card pesanti dove altrove ci sono filetti. Da uniformare in un passaggio successivo (tocca un ternario di stile inline, rischio inutile ora).
2. **Attività / header di gruppo** — `.slabel` mette in maiuscolo i nomi zona ("Est" → "EST"). Coerente col linguaggio Taccuino ma è un nome proprio: se non convince, togliere `text-transform` con una classe scoped (1 riga).
3. **Attività / riga urgente** — mantiene sfondo `rose-pale` + `border-radius:10px` (niente ombra/bordo) per non perdere il segnale di urgenza: via di mezzo tra card e filetto puro. Fallback a filetto puro documentato nel report del Task 8.
4. **ProgettoView** — la timeline si disegna sullo scroll: verificare lo scrub su un progetto con ≥2 tappe (colore per esito, comparsa pallini) e con *riduci animazioni* attivo (tutto statico).
5. **ConcimiView** — `.feed` è usata senza `.feed__rank` (nata per la lista "Concimi consigliati" della scheda pianta): controllare che la riga non collassi/disallinei.
6. **GalleryView** — carosello del feed tenuto scoped (`.carosello`/`.slide`/`.puntini`): i globali Fase-1 `.gtrack/.gslide/.gdots` sono `position:absolute` (fatti per l'header foto della scheda pianta) e inservibili in-flow.
7. **AgenteView** — lo storico ora è un drawer da sinistra a **tutte** le larghezze (prima su desktop era una colonna fissa a due colonne). Voluto dal mockup Fase 2.

## Minori / debito tecnico raccolto

- **`.chip`** in `main.css` è la variante "su foto" (testo/icona quasi bianchi). GalleryView la usa su fondo chiaro con un override scoped `.gpost__hd .chip`. Andrebbe rifatta come base neutra/chiara + modificatore `.chip--on-photo`, poi GalleryView toglie l'override.
- **`.pill-mini`** ha `cursor:default` in `main.css`; 3 viste (Zone/Sottozone, Concimi) aggiungono un override scoped parent-qualified. Candidato a un fix globale `button.pill-mini, a.pill-mini { cursor:pointer }`.
- **Vocabolario caroselli** — la scheda pianta usa `.gtrack/.gslide/.gdots`, il feed galleria usa `.carosello/.slide/.puntini`. Da riconciliare in una base condivisa.
- `formatData` (giorno + mese per esteso, anno solo se ≠ corrente) è duplicato in ProgettiView e ProgettoView — scelta consapevole (piano di sola presentazione, niente nuovi composable). Candidato a `useFormatData` in un round futuro.
- `.prow__chev` (chevron) definito in `main.css` ma le righe Progetti non lo rendono — il mockup lo mostra; aggiungere `<span class="prow__chev">›</span>` se lo si vuole.
- `.wxrow__s` senza "· Centinarola", `.stat` che lampeggiano prima del load, consociazioni senza accento colore — minori Fase 1 ancora aperti (nota di esito Fase 1).

## Fuori scope (round successivi)

- **Batch 3**: Meteo, Account, Impostazioni, EditPianta, EditZona (hanno ancora i titoli gradient resi come testo normale — atteso).
- **Batch 4**: SelettoreSpecie.
- **Fase 3**: dark mode (interruttore in Impostazioni).
- **Fase 4**: velatura stagionale dell'hero.
