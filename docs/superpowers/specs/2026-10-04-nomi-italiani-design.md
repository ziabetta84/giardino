# Nomi italiani delle specie — design

Data: 2026-10-04

## Obiettivo

Mostrare nell'app il nome comune italiano delle specie ovunque esista una fonte affidabile, mantenendo il nome scientifico visibile come sottotitolo. Dove un nome italiano non esiste, resta il nome scientifico: nessun nome inventato o tradotto con IA.

Successo: nell'app compare "Tarassaco" con *Taraxacum officinale* accanto, e cercando "tarassaco" si trova la specie.

## Stato di partenza (verificato su Supabase, 2026-10-04)

- Tabella `specie`: ~212.000 righe. In 211.936 `nome = nome_scientifico`.
- Le ~158 righe curate (piante del giardino e dell'orto) seguono già la convenzione: `nome` = nome italiano (es. "Rosmarino"), `nome_scientifico` = nome botanico (es. *Rosmarinus officinalis*).
- Le piante puntano alle specie per **slug** (FK `piante.specie`, `on update cascade`), non per nome. Cambiare `nome` non rompe i collegamenti.
- Wikidata ha ~10.900 taxa con nome comune italiano (`P1843`, lingua `it`), animali inclusi.

## Decisioni

1. **Nessuna colonna nuova.** Si usa la convenzione già esistente: `nome` = italiano, `nome_scientifico` = botanico, `slug` immutato.
2. **Righe curate intoccabili.** L'import agisce solo dove `nome = nome_scientifico`.
3. **Cultivar escluse** (`specie_padre_id` non nullo): restano col nome attuale.
4. **Specie senza fonte** restano col nome scientifico.

## Import in blocco

- Fonte: Wikidata, query SPARQL su `P225` (nome scientifico) + `P1843` (nome comune) con lingua `it`.
- Match: confronto esatto, senza distinzione di maiuscole, tra `P225` e `specie.nome_scientifico`.
- Nomi multipli per lo stesso taxon (es. soffione/tarassaco): si usa nell'ordine
  1. il valore con rango "preferito" su Wikidata;
  2. altrimenti il titolo dell'articolo it.wikipedia, se diverso dal nome scientifico;
  3. altrimenti il caso è **ambiguo**: saltato ed elencato per decisione manuale.
- Il nome importato prende la maiuscola iniziale (convenzione delle righe curate: "Rosmarino").
- Output intermedio in `scratchpad`: CSV con slug, nome scientifico, nome proposto, criterio usato, ambigui. Revisione a campione prima di applicare.
- Applicazione via migration in `supabase/migrations/` (batch di `update`), in lotti, come per l'import RHS e la naturalizzazione.

## Reversibilità

Il valore precedente di `nome` coincide con `nome_scientifico`. La migration salva l'elenco degli slug modificati; il rollback è `nome = nome_scientifico` su quegli slug. Nessuna colonna di tracciamento.

## UI e ricerca

- Ovunque l'app mostra `nome` e il nome scientifico è disponibile e diverso, mostrare lo scientifico in corsivo come sottotitolo (selettore specie, pianta, attività, dossier). Nelle viste dense solo nel tooltip.
- La ricerca del selettore specie deve cercare su `nome` e `nome_scientifico`.
- `specie.nome` ha un vincolo UNIQUE nel database (scoperto applicando il lotto 1): l'import salta i nomi che andrebbero in conflitto (il genere tiene il nome, le specie in conflitto restano col nome scientifico). La chiave resta lo slug.

## Controlli prima del batch

Alcuni file usano `nome` in confronti o testi: `GalleryView.vue`, `AgenteView.vue`, `useSuggerimentoIrrigazione.js`, `useRichiesteAgente.js`, `SelettoreSpecie.vue`, `PiantaRiga.vue`, `AttivitaView.vue`, `PiantaView.vue`, `IrrigazioneView.vue`, `ConcimiView.vue`. Ogni uso come chiave o criterio di match va spostato su slug prima di applicare l'import. Controllare anche la logica di match PlantNet in `/zorbadice` (`identifica_specie`).

## Fuori scope

- Cultivar.
- Tabella sinonimi (`specie_nomi`): rimandata, aggiungibile senza perdere nulla.
- Fallback offline `specie.json`: non aggiornato (già dichiarato disallineato).
- Traduzioni generate da IA.

## Rischi

- `specie.nome` è UNIQUE: due specie non possono avere lo stesso nome italiano, quindi gli omonimi vanno esclusi dall'import (anche rispetto ai nomi già in tabella).
- Il nome comune su Wikidata può riferirsi al genere o a un gruppo e non alla specie: la revisione a campione serve a questo.
- Un nome mostrato diverso da quello atteso dai testi di `descrizione` già naturalizzati: verificare a campione.
