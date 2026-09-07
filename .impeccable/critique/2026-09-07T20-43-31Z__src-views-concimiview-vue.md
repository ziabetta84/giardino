---
target: ConcimiView
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 1
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue"
target_fingerprint: "sha256:a57c4dd8d3efd11de46cf63f6e5dd54b89128c53144237204295c3aff3557c5e"
target_path: /Users/rob/Sites/localhost/giardino/src/views/ConcimiView.vue
timestamp: 2026-09-07T20-43-31Z
slug: src-views-concimiview-vue
---
Method: dual-agent (A: design-review subagent · B: detector-evidence subagent)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Skeleton, spinner per-riga sul toggle e su Salva/Elimina — buon riscontro in tempo reale, ma l'errore del toggle appare lontano dalla riga che ha fallito. |
| 2 | Match System / Real World | 4 | "Dispensa", "terminato", notazione NPK, "Adatto per" — mappano bene su come un giardiniere pensa davvero ai concimi. |
| 3 | User Control and Freedom | 3 | Foglio/modale richiudibili, Annulla sempre presente; nessun "undo" dopo l'eliminazione ma conferma presente. |
| 4 | Consistency and Standards | 2 | Duplica lo stile di `.field-label` inline invece di riusare la classe già usata in `ZoneView.vue`/`ProgettiView.vue`; banner di errore fatto a mano invece di `.alertbox`; `toggle-switch` resta un componente unico nel codebase. |
| 5 | Error Prevention | 3 | Salva disabilitato a nome vuoto, eliminazione dietro conferma; ma `min="0"` sugli NPK è solo un suggerimento della spinner, un valore negativo digitato viene comunque salvato. |
| 6 | Recognition Rather Than Recall | 3 | "Adatto per" evita di dover ricordare/dedurre il match; ma una volta compilati i campi NPK, quale numero sia N/P/K si deduce solo dalla posizione. |
| 7 | Flexibility and Efficiency | 2 | Nessuna ricerca/filtro/ordinamento oltre l'alfabetico fisso — `PianteView.vue`, la vista più simile, ha una casella di ricerca e filtri per zona. |
| 8 | Aesthetic and Minimalist Design | 3 | Pulita a riposo, ma `.feed__d`/`.feed__match` non troncano: una descrizione lunga o molte piante abbinate possono rendere una riga molto più alta delle vicine. |
| 9 | Error Recovery | 3 | Errori nominati per azione, quello del toggle include il nome del concime; ma la sua posizione in cima alla pagina indebolisce la diagnosi su una lista lunga. |
| 10 | Help and Documentation | 2 | Nessun suggerimento su cosa significhino i numeri NPK o dove trovarli su una confezione reale. |
| **Total** | | **28/40** | **Buono** |

## Design Specificity Verdict

**LLM:** ConcimiView è per lo più autorata per questo prodotto piuttosto che una schermata CRUD generica: la riga "Adatto per: {piante}" — calcolata dal vivo con lo stesso matcher a distanza NPK usato altrove — trasforma una lista d'inventario in un'osservazione personalizzata e da taccuino ("questo vasetto di concime è *per* il tuo rosmarino"), un tocco genuinamente specifico del giardino. Il testo dell'empty state vende il beneficio invece di limitarsi a "nessun elemento". Sotto la superficie, però, la schermata reinventa alcune cose che il resto dell'app ha già risolto — un banner di errore fatto a mano invece di `.alertbox`, etichette di campo con stile inline invece di `.field-label`, un `toggle-switch` su misura che non esiste altrove nel codebase — dettagli che si leggono meno come "questa schermata aveva bisogno di qualcosa di nuovo" e più come costruita senza controllare cosa esistesse già.

**Scansione deterministica:** ancora 5 riscontri advisory, stessi di prima (righe 8/77 a 12px, riga 278 a 8px di raggio, righe 282/325 su glifi). Verificato: 4 su 5 sono riusi diretti di pattern ripetuti altrove nel codebase (`SettingsView.vue`, `AccountView.vue`, `ProgettoView.vue`, `GalleryView.vue`, `PiantaRiga.vue`, `AgenteView.vue`); il quinto (10px sul glifo dello spinner nel toggle) non ha alcun precedente altrove nel repo — un valore isolato, cosmetico, non un problema di sostanza.

**Verifica accessibilità riga:** confermato riscontro-per-riscontro che `role="button"`/`tabindex="0"`/gestori keydown Invio-Spazio sulla riga concime corrispondono esattamente al pattern già in uso in `AgenteView.vue` — stesso markup, stessa logica.

**Overlay visivi:** ancora non disponibili — nessuno strumento di controllo browser esposto in questo ambiente, verificato di nuovo da entrambi gli assessment.

## Overall Impression

Il punteggio sale da 24 a 28/40 (soglia "Buono"). I fix dei due giri precedenti reggono bene sotto un terzo controllo indipendente. Il problema più concreto rimasto è che l'interruttore disponibilità — l'unico controllo per-riga rimasto sotto i 44px — è stato introdotto proprio nello stesso file che ha appena corretto altri due bottoni per la stessa identica ragione, senza essere toccato a sua volta.

## What's Working

1. **Il match NPK dal vivo (`pianteAbbinatePerConcime`)** riusa lo stesso matcher (`concimeConsigliato`) della scheda pianta: l'affermazione "Adatto per" è affidabile e coerente in tutta l'app, non un'euristica separata inventata per questa schermata.
2. **La distinzione N/D vs. zero reale in `formattaNPK`** — un dettaglio di correttezza di dominio che un'app di dispensa generica sbaglierebbe.
3. **I 44px applicati correttamente su CTA e bottone elimina**, con un ragionamento esplicito nei commenti del codice sull'uso in giardino/mani bagnate — l'unica schermata del campione che ragiona visibilmente su questo scenario per questi due controlli specifici.

## Priority Issues

**[P1] L'interruttore disponibilità (42×24px) viola la stessa regola dei 44px che questo file ha appena corretto per altri due controlli.**
- **Perché conta**: è l'azione per-riga principale su una schermata pensata per l'uso in giardino, una mano sola, mani potenzialmente sporche/bagnate — esattamente lo scenario per cui la regola dei 44px esiste. È anche l'unico punto del codebase dove esiste un `toggle-switch`, quindi non c'è un precedente stabilito a cui appellarsi: è stato introdotto nuovo e sottodimensionato nello stesso file che ha corretto con cura i suoi due vicini.
- **Fix**: allargare l'area di tocco a ≥44×44px (padding invisibile oltre il binario visibile 42×24, come fanno gli switch iOS/Android), oppure promuovere `.toggle-switch` in `main.css` dimensionato correttamente fin dall'inizio, così un domani altre viste lo erediterebbero già giusto.
- **Comando suggerito**: `/impeccable adapt`

**[P2] L'errore del toggle appare lontano dalla riga che ha fallito.**
- **Perché conta**: `erroreDisponibile` è un banner fisso in cima alla pagina, mentre l'azione che l'ha generato avviene altrove (potenzialmente in fondo a una lista lunga). L'utente vede lo spinner risolversi senza alcun cambiamento visibile sulla riga e deve risalire per capire perché — il tipo peggiore di fallimento apparentemente silenzioso, proprio nel momento in cui la rassicurazione conta di più.
- **Fix**: mostrare l'errore vicino alla riga che ha fallito (es. una piccola didascalia rossa sotto la riga meta di quella riga, agganciata a `c.id`), non solo nel banner in cima.
- **Comando suggerito**: `/impeccable clarify`

**[P2] Nessuna ricerca/filtro per la lista concimi, a differenza della vista più simile (`PianteView.vue`).**
- **Perché conta**: `PianteView.vue` offre alla stessa forma di lista una casella di ricerca e filtri per zona; ConcimiView offre alla stessa lista (nome, potenzialmente decine di voci per chi prepara i propri macerati) solo l'ordine alfabetico fisso.
- **Fix**: aggiungere un `.search-input` che filtri su nome/descrizione, sullo stesso modello di `PianteView.vue`.
- **Comando suggerito**: `/impeccable layout`

**[P2] Testo lungo non troncato nelle righe (`feed__d`, `feed__match`) rompe il ritmo della lista a filetti.**
- **Perché conta**: il placeholder della textarea invita esplicitamente a descrizioni articolate ("Preparazione, dosi, tempo di macerazione…"), e l'elenco piante abbinate può in teoria crescere senza limite — entrambi possono rendere una riga molto più alta delle vicine, rompendo la scansionabilità su cui si basa il resto della lista (per questo `PiantaRiga.vue` tronca nome/varietà/zona con ellissi).
- **Fix**: limitare `.feed__d` a 1-2 righe con line-clamp, e limitare l'elenco piante abbinate (es. "Adatto per: Rosa, Basilico +3 altre") con l'elenco completo visibile nel foglio di modifica.
- **Comando suggerito**: `/impeccable polish`

**[P3] Incoerenze locali che frammentano il sistema di design: etichette inline invece di `.field-label`, banner d'errore fatto a mano invece di `.alertbox`.**
- **Perché conta**: nessuna delle due è visivamente sbagliata, ma entrambe significano che il "taccuino" ha ora due modi di dire la stessa cosa — esattamente il tipo di scarto che erode la sensazione di "prodotto coerente" nel tempo e fa sì che una futura modifica globale (es. cambiare lo stile delle etichette) salti questa schermata.
- **Fix**: sostituire entrambe con le classi condivise già esistenti.
- **Comando suggerito**: `/impeccable extract`

## Persona Red Flags

**Casey (mobile, in giardino)**: l'interruttore da 24px (Priority 1) è la violazione più concreta della regola "in giardino" dell'app, proprio accanto al bottone elimina da 44px nello stesso cluster di azioni — un disallineamento di dimensioni anche visivamente incoerente nella stessa riga.

**Sam (accessibilità)**: le righe `.feed`/`.feed--tap` non hanno **alcuno stile `:focus-visible` definito in `main.css`**, a differenza di `.wxrow`, `.dest`, `.zdice`, `.gslide` e `.care-act`, che definiscono tutti esplicitamente un anello di focus oro — un utente da tastiera che tabula la lista Concimi ottiene `role="button"`/`tabindex="0"` e gestori Invio/Spazio funzionanti, ma nessuna indicazione visibile di quale riga abbia il focus (verificato assente con una ricerca sull'intero foglio di stile). Inoltre ogni riga annida due `&lt;button&gt;` reali (toggle, elimina) dentro un `div[role="button"]` — un pattern ARIA annidato non valido.

**Alex (power user)**: nessuna ricerca/filtro/ordinamento oltre l'alfabetico (Priority 2); nessuna scorciatoia "parti da una ricetta esistente" per duplicare un concime fatto in casa simile a uno già in dispensa.

## Minor Observations

- `.pill--cta` è un fix deliberato a 44px per questa schermata, ma non è stato propagato a `ZoneView.vue`/`ProgettiView.vue`/`PianteView.vue`, che usano lo stesso pattern "+ Aggiungi" a 36px — l'app ora ha due altezze diverse per la stessa azione concettuale tra viste gemelle.
- Il titolo della conferma di eliminazione ("Eliminare questo concime?") non include il nome dell'elemento — pattern condiviso con `ZoneView.vue`/`PianteView.vue`/`AgenteView.vue`, quindi sistemico, non specifico di questo file.
- `min="0"` sugli input NPK non è realmente applicato in `salva()`: un numero negativo digitato viene comunque salvato as-is.
- Il `toggle-switch` ha `aria-label` sull'azione, non sullo stato — nessun `role="switch"`/`aria-checked` per un controllo che è semanticamente uno stato binario persistente.

## Questions to Consider

- Se "Adatto per" è davvero la riga più preziosa di questa schermata — quella che trasforma la tenuta di un inventario in un'osservazione utile — perché ha lo stesso peso visivo di un numero NPK statico invece di essere la prima cosa su cui cade l'occhio?
- Il file mostra un ragionamento esplicito sui bersagli di tocco per CTA e bottone elimina ("vedi critica del 07/09/2026") — perché lo stesso passaggio non ha raggiunto l'interruttore, tre righe più sotto nello stesso template?
- Ogni altra lista dell'app che può crescere oltre una schermata (`PianteView`) ha una casella di ricerca: cosa giustifica che la dispensa dei concimi sia l'unico inventario che non ne ha mai bisogno?
