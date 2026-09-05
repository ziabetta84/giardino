# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Persone che curano un giardino reale e vogliono tenerne traccia in modo strutturato: zone e sottozone, piante singole con specie e storico cure, progetti con tappe, dispensa concimi. Nato per Rob e il suo giardino a Centinarola, Fano (PU), Italia; con l'autenticazione Supabase (RLS per `owner_id`) l'app è ora aperta anche ad altre persone, ciascuna con il proprio giardino isolato dagli altri (famiglia, amici, altri appassionati che vogliono lo stesso strumento per il proprio giardino).

## Product Purpose

Gestire un giardino reale nel tempo: sapere cosa c'è, dove si trova, di cosa ha bisogno e quando, senza che la conoscenza di cura resti solo nella testa di chi cura il giardino. Successo = meno piante trascurate o dimenticate, cure fatte al momento giusto, progetti di giardino portati a termine invece che abbandonati a metà.

## Positioning

Il valore è nella combinazione di due cose che raramente stanno insieme in un'app di giardinaggio generica:

1. **Cure automatiche da catalogo specie** — un catalogo condiviso di migliaia di specie con profili di manutenzione stagionale (irrigazione, concimazione, potatura) che, incrociato con le piante reali del giardino dell'utente e la stagione corrente, calcola in automatico le urgenze di cura (`useCure.js`), invece di lasciare all'utente il calcolo a memoria.
2. **Assistente AI integrato nel flusso di cura reale** — una coda di richieste (identificazione specie da foto, diagnosi, consigli di cura/concimazione, pianificazione progetti) elaborata da un agente AI che scrive risposte e aggiornamenti strutturati (specie, progetti/tappe) direttamente nei dati del giardino dell'utente, non un chatbot separato scollegato dai dati.

Non è un quaderno di appunti né un'app di identificazione piante generica: è uno strumento operativo legato a un giardino specifico, con dati e intelligenza applicati sopra quel giardino.

## Operating Context

- Uso quotidiano/settimanale sul campo (in giardino, da mobile) per controllare urgenze di cura, registrare una cura appena fatta, scattare/caricare foto; uso da desktop per compiti più lunghi (pianificare un progetto, rivedere zone e piante, impostazioni).
- Meteo locale (Open-Meteo, no API key) integrato per contestualizzare le decisioni di cura.
- PWA installabile con aggiornamento in background (banner di update) e cache offline (Workbox) per continuare a consultare i propri dati di giardino senza connessione.
- Login obbligatorio: senza sessione attiva, ogni rotta reindirizza a `/account`.

## Capabilities and Constraints

- Zone → sottozone → piante, ciascuna pianta legata a una specie del catalogo condiviso; storico cure per tipo (`ultima_cura`), non un log illimitato di eventi.
- Progetti con tappe (milestones) che calcolano una scadenza dal progresso reale, non solo date fisse.
- Dispensa concimi con abbinamento concime↔pianta per distanza NPK normalizzata.
- Galleria foto per pianta, organizzata per cartelle.
- Coda di richieste AI (`richieste-agente.json`) ancora su GitHub/JSON, elaborata manualmente via comando `/elabora`, non in tempo reale: le risposte non sono istantanee.
- Catalogo specie è condiviso fra tutti gli utenti in sola lettura (nessuna scrittura pubblica); zone/sottozone/piante/progetti/tappe/concimi/impostazioni sono privati per utente (RLS).
- Contenuti e interfaccia interamente in italiano.
- Deploy statico su GitHub Pages (routing hash-based): nessun backend proprio oltre Supabase.

## Brand Commitments

- Nome del progetto: "Giardino di Rob" / progetto Supabase "Il Giardino di Zorba".
- Mascotte/logo: **Zorba**, un gatto nero realmente esistito e sepolto nel giardino — va sempre reso nero, anche in dark mode (solo un alone più chiaro attorno, mai schiarire il gatto stesso). Unica eccezione ammessa alla palette colori.
- Palette: rose `#cc6e6e`, gold `#e0b84a`, sage `#7a9e82`, olive `#9aaa5a`, cream `#faf7f2`.
- Font: Fraunces (titoli display), DM Sans (UI/testo), Caveat (accento manoscritto).
- Direzione illustrativa in corso: icone acquerellate per zone/sottozone (45 icone), hero ad acquerello/china animato in Home.

## Evidence on Hand

- App reale e funzionante con dati veri del giardino di Centinarola (piante, zone, progetti, cure) su Supabase — non un prototipo con dati finti.
- Foto reali delle piante in `docs/gallery/piante/{id-pianta}/`.
- Nessuna testimonianza, caso studio o materiale di marketing: è uno strumento operativo, non un prodotto da vendere. Non inventare contenuti di questo tipo nei lavori futuri.

## Product Principles

- La cura reale del giardino viene prima dell'estetica: ogni schermata deve restare scansionabile e operativa (Operate), non solo bella.
- Il catalogo specie e l'assistente AI devono sempre sentirsi collegati ai dati reali dell'utente, mai come funzioni satellite scollegate.
- Zorba è identità, non decorazione: nero sempre, in ogni tema e in ogni superficie che lo mostra.
- I dati di ciascun utente sono isolati e privati (RLS): il design non deve mai suggerire che i dati siano condivisi tra utenti, a parte il catalogo specie.
- Tutto il contenuto è in italiano: nessuna stringa UI in inglese deve sopravvivere a un lavoro di design.
