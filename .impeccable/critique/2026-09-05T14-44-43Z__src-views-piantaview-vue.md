---
target: Scheda pianta (src/views/PiantaView.vue)
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/PiantaView.vue"
target_fingerprint: "sha256:cab95e0406de814fb0e97ce0e8476c3fe58ac463f0108ec6ec3cf62dda272201"
target_path: /Users/rob/Sites/localhost/giardino/src/views/PiantaView.vue
timestamp: 2026-09-05T14-44-43Z
slug: src-views-piantaview-vue
---
Method: dual-agent (A: general-purpose · B: general-purpose)

## Design Health Score

| # | Euristica | Punteggio | Nodo specifico |
|---|-----------|-------|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Spinner presente sul salvataggio; nessun indicatore quando si ricarica la galleria cambiando pianta |
| 2 | Corrispondenza sistema/mondo reale | 3 | Linguaggio orticolo naturale, ma NPK/consociazioni senza legenda per utenti non esperti |
| 3 | Controllo e libertà dell'utente | 4 | Back link, Annulla, Esc, click-fuori — vie d'uscita coerenti ovunque |
| 4 | Coerenza e standard | 2 | Stesso comando cura duplicato in due punti; bottone distruttivo fuori standard |
| 5 | Prevenzione errori | 4 | Messaggio di eliminazione pluralizza correttamente e cita le foto coinvolte |
| 6 | Riconoscimento anziché ricordo | 3 | Etichette sempre accanto alle icone; penalizzato da gergo tecnico non spiegato |
| 7 | Flessibilità ed efficienza d'uso | 2 | Nessuna azione bulk, nessuna scorciatoia tastiera fuori dal lightbox |
| 8 | Estetica e design minimalista | 2 | Fino a 9 sezioni sempre espanse, il compito operativo rischia di annegare nel materiale di consultazione |
| 9 | Aiutare a riconoscere/recuperare errori | 1 | registraCura/eliminaPianta/confermaEliminaFoto non hanno alcun catch — fallimento di rete completamente silenzioso |
| 10 | Aiuto e documentazione | 1 | Nessun tooltip, nessuna spiegazione di NPK/consociazioni, nessun punto di aiuto |
| **Totale** | | **25/40** | **Accettabile** (al confine con "Scarso") |

## Design Specificity Verdict

Valutazione LLM: in gran parte ancorato a DESIGN.md — Fraunces sui nomi, filetti hairline nelle liste, filigrana di Zorba al 7% esatto dietro "La specie", coppie -bg/-ink per dominio in "Stato cure". Ma tre punti riportano verso il generico: ModalConferma.vue ricostruisce il bottone distruttivo via stile inline invece di .btn-rose; l'alert "Da curare subito" usa il colore olive invece di rosa nonostante DESIGN.md riservi il rosa a "cure in ritardo" (il commento nel CSS conferma che è una scelta mai risolta); "La specie" funziona come scheda-prodotto generica non appena i fatti crescono.

Scansione deterministica: pulita — 0 anti-pattern reali su 5 file, solo 4 note advisory (tutte micro-drift di tokenizzazione: 16px/8px di radius fuori scala, un rgba non catalogato ma nella stessa famiglia "inchiostro" già documentata, 17px su un glifo "×" simbolico). Nessun falso positivo puro, nessuna violazione grave della filosofia del sistema.

Il contrasto è il finding più interessante: il detector non trova nulla di grave, ma la revisione qualitativa trova veri problemi di coerenza e affidabilità — il tipo di drift che un detector non può strutturalmente vedere.

Overlay visivi: non disponibili in questa sessione — nessun tool di automazione browser esposto.

## Overall Impression

Questa è la pagina più densa e ricca dell'app — ed è anche quella dove le crepe di coerenza pesano di più, perché è dove un utente guarda la sua pianta specifica dopo averla curata. Localmente il craft è alto; ma la stessa azione di cura è rappresentata due volte con etichette diverse, un fallimento di salvataggio non lascia alcuna traccia visibile, e il momento di delight appena costruito su Home ("Zorba conferma") non raggiunge questa schermata. La più grande opportunità non è aggiungere altro: è togliere la ridondanza e chiudere i buchi di affidabilità già presenti.

## What's Working

- .care__ic--{tipo} in "Stato cure": mappa esattamente le coppie -bg/-ink per dominio — l'unico punto dove la promessa "un colore per dominio" di PRODUCT.md è realizzata fedelmente.
- messaggioEliminaPianta: copy dinamica e consapevole delle conseguenze, Error Prevention fatta bene invece di un generico "sei sicuro?".
- Degrado a tre stati dell'header foto (foto personali → immagine Wikimedia con attribuzione → header testuale): gestito con cura, licenza rispettata, filigrana Zorba al 7% esatto.

## Priority Issues

**[P1] La stessa cura urgente ha due comandi diversi.**
Ogni cura urgente compare due volte: come riga "Registra" nell'alert in cima, e come riga "Fatto" in "Stato cure" subito sotto — entrambi chiamano registraCura(tipo). .care-act--rose esiste già per colorare una riga urgente, ma qui non viene usato.
Fix: eliminare l'alert per le cure e applicare .care-act--rose direttamente alle righe urgenti di "Stato cure".
Comando suggerito: /impeccable clarify

**[P1] Salvataggi ed eliminazioni falliscono in silenzio.**
registraCura, eliminaPianta, confermaEliminaFoto hanno solo try/finally, mai un catch. Un errore di rete fa sparire lo spinner senza alcun messaggio.
Fix: messaggio inline vicino al controllo fallito, stesso pattern già introdotto in Home per registra().
Comando suggerito: /impeccable harden

**[P1] La galleria foto non è raggiungibile da tastiera.**
Le <figure class="gslide" @click="apriLuce(f)"> nell'header non hanno tabindex, role="button" né gestione tastiera.
Fix: rendere le figure focalizzabili e attivabili da tastiera, coerente con l'apertura da tastiera appena aggiunta al lightbox.
Comando suggerito: /impeccable harden

**[P2] Bottone distruttivo fuori standard in ModalConferma.**
Il bottone "Elimina" usa uno stile inline invece di class="btn btn-rose" — sotto il target di tocco di 44px, proprio sull'azione più irreversibile dell'app.
Fix: sostituire con class="btn btn-rose" senza override inline.
Comando suggerito: /impeccable harden

**[P2] Colore di dominio sbagliato nell'alert urgenze.**
.alertbox base (olive) è usato per "Da curare subito" indipendentemente dal tipo di cura scaduta — DESIGN.md riserva il rosa a "cure in ritardo".
Fix: usare .alertbox--rose, o colorare per il tipo specifico di cura.
Comando suggerito: /impeccable colorize

**[P2] Sovraccarico cognitivo in "La specie".**
Fino a 10 righe kv non raggruppate, sempre espanse, subito dopo Esigenze e Note tecniche — 6 checklist su 8 falliscono.
Fix: raggruppare in 2-3 sotto-cluster con sotto-etichette, o introdurre una disclosure comprimibile.
Comando suggerito: /impeccable distill

## Persona Red Flags

**Jordan (prima volta, familiare/amico)**: vede lo stesso tipo di cura urgente con due etichette diverse e non sa quale toccare. NPK, consociazioni favorevoli/sfavorevoli sono gergo tecnico senza spiegazione. Il chip icona-only per "coltivato in" ha solo title/aria-label — su touch il title non appare mai.

**Sam (screen reader/tastiera)**: le foto della galleria header sono raggiungibili solo con mouse/touch. I bottoni Annulla/Elimina in ModalConferma sono forzati a 40px. Tutte le foto della galleria condividono lo stesso alt.

**Alex (uso quotidiano/esperto)**: nota subito la ridondanza "Registra"/"Fatto". Nessuna azione bulk con più cure urgenti. Il blocco "La specie" sempre espanso costringe a scorrere fatti già noti ogni volta.

## Minor Observations

- Il momento di delight "Zorba conferma" non raggiunge questa pagina: PiantaView.vue non monta alcuna istanza di ZorbaLogo.
- .notelist li usa i bullet di default del browser.
- Il messaggio in ModalConferma usa uno stile inline invece di .prose — piccola incoerenza tipografica.
- Nessuno stato di caricamento quando si passa da una pianta all'altra e la galleria si ricarica.
- Il ranking dei concimi consigliati non spiega mai perché un concime è primo.

## Questions to Consider

- Se il bottone "Registra" e il bottone "Fatto" eseguono la stessa azione sullo stesso tipo di cura, perché mostrarne due?
- Questa pagina fa da centro operativo e da dossier botanico nello stesso scroll: e se fossero due pagine distinte?
- Cosa succede alla fiducia dell'utente la prima volta che una registraCura fallisce in silenzio, e se ne accorge solo una settimana dopo?
