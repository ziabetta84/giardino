---
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/AccountView.vue"
target_fingerprint: "sha256:3dc565acae66bae6800508486b2b9af123ffced5b61faa776d5b69e49f63513d"
target_path: /Users/rob/Sites/localhost/giardino/src/views/AccountView.vue
timestamp: 2026-09-08T07-33-55Z
slug: src-views-accountview-vue
closed: true
---
Method: dual-agent (A: design review sub-agent · B: detector/browser-evidence sub-agent)

## Design Health Score

| # | Euristica | Punteggio | Nota chiave |
|---|-----------|-----------|-------------|
| 1 | Visibilità dello stato del sistema | 2 | Stati "Un momento…"/"Uscita in corso…" sono solo cambi di testo nel bottone, nessun indicatore visivo aggiuntivo, nessun annuncio per screen reader |
| 2 | Corrispondenza sistema/mondo reale | 3 | Errori Supabase tradotti bene nei 4 casi mappati; il fallback `e.message` lascia passare inglese tecnico grezzo proprio quando l'utente è già in difficoltà |
| 3 | Controllo e libertà dell'utente | 2 | Nessuna via d'uscita dallo stato "Nuova password" (niente "Annulla"/"Torna al login") |
| 4 | Coerenza e standard | 3 | Palette sage/rose rispettata anche nei dettagli minori, ma 7 valori font-size fuori dalla type ramp (vedi scan) e stile quasi interamente inline invece delle classi BEM usate nel resto della codebase |
| 5 | Prevenzione degli errori | 2 | Doppio submit prevenuto ovunque; manca però il campo "conferma password" in registrazione |
| 6 | Riconoscimento piuttosto che ricordo | 3 | Email persiste tra login e recupero password, tab chiaramente etichettate |
| 7 | Flessibilità ed efficienza d'uso | 2 | Nessun `autofocus` sul campo email; nessuna scorciatoia oltre al submit nativo da tastiera |
| 8 | Design estetico e minimalista | 2 | Minimale ma "spoglio": nessun elemento del sistema Taccuino (china/acquerello/ink-pooling) sulla superficie di primo contatto |
| 9 | Aiuto a riconoscere/diagnosticare/recuperare errori | 2 | Errori corretti nel tono ma non azionabili: "Email o password non corretti" non rimanda a "Password dimenticata?" già in pagina; email non confermata non offre un rinvio |
| 10 | Aiuto e documentazione | n/a | Un form di 2-3 campi non richiede documentazione contestuale strutturale |
| **Totale** | | **21/36** | **Accettabile (58%)** |

## Verdetto di Design Specificity

**LLM assessment**: Debole per una pagina di primo contatto. Lo stato non autenticato è funzionalmente corretto ma visivamente è il form di login di un SaaS qualunque con un logo diverso incollato sopra: zero elementi a china/acquerello, zero icone "ink-pooling", nessuna illustrazione. `ZorbaLogo.vue` espone `reagisci()`/`confermaCura()` per animare la mascotte in risposta a eventi reali, ma `AccountView.vue` non li chiama mai — proprio nella pagina che DESIGN.md indica come la più critica per fiducia ed emotional journey. Segnale collaterale: la vista è stilizzata quasi interamente con `style=""` inline (16+ occorrenze) invece delle classi BEM dedicate usate nel resto della codebase — un investimento di autorialità visibilmente inferiore al resto del prodotto.

**Scan deterministico**: `impeccable detect --json src/views/AccountView.vue` → 7 finding, tutti regola `design-system-font-size` (severity `advisory`): righe 10, 15, 20, 45, 76, 104, 229 — valori `12px`/`14px` che non corrispondono a nessuno step della type ramp dichiarata in DESIGN.md (display 26px, body/ui 13px, label 11px, hand 19px). Verificati uno per uno contro DESIGN.md: tutti e 7 veri positivi. Nota di copertura: riga 65 (`h1.page-title` con `style="font-size:1.5rem"` = 24px, anch'esso fuori ramp) non è stata flaggata — probabile gap del detector sulle unità `rem`, quindi lo scostamento reale è probabilmente più ampio degli 7 finding riportati.

**Evidenza visiva**: nessun overlay disponibile. Né l'Assessment A né l'Assessment B avevano accesso a uno strumento di automazione browser in questa sessione (verificato anche a livello di harness principale) — entrambe le valutazioni sono state fatte da codice/markup, senza screenshot o iniezione del detector nella pagina viva. Nessuna conferma visiva reale di resa, breakpoint mobile o contrasto colore effettivo: le osservazioni responsive/visive sotto sono dedotte dai token CSS, non osservate a schermo.

## Overall Impression

AccountView funziona ed è tecnicamente disciplinata sui dettagli difensivi (guardie anti-doppio-submit su tutti e quattro i percorsi, autocomplete corretto, palette semantica mai invertita), ma è la superficie meno autoriale dell'app proprio dove conta di più: il primo contatto di un nuovo utente e il momento più delicato del flusso (registrazione con conferma email obbligatoria). La più grande opportunità è collegare questa vista al resto del linguaggio di prodotto — Zorba che reagisce, un elemento a china dietro il form, stati di conferma reali invece di una riga di testo — e chiudere un bug concreto nel flusso di recupero password che può bloccare silenziosamente un utente.

## What's Working

1. **Palette semantica applicata con disciplina**: nessun bottone di salvataggio è rose, "Esci"/"Crea account"/"Accedi" restano sage/ghost, "Rimuovi" token usa rose solo nel testo — coerente con la regola "sage=affermativo, rose=solo distruttivo" fin nei dettagli minori.
2. **`autocomplete` contestuale corretto**: `current-password` in login, `new-password` in registrazione/reset — dettaglio spesso trascurato che aiuta concretamente i password manager.
3. **Prevenzione sistematica del doppio submit**: la stessa guardia (`if (in corso) return` + `:disabled`) è applicata a tutti e quattro gli handler asincroni (login/registrazione, richiesta reset, imposta password, logout), non solo a uno.

## Priority Issues

**[P1] Refresh a metà del flusso di recupero password blocca l'utente senza spiegazione**
- **Perché conta**: `recuperoInCorso` (`useAuth.js`) è uno stato solo in-memoria, impostato una sola volta dall'evento `PASSWORD_RECOVERY` di `onAuthStateChange` al momento dello scambio del codice PKCE. Se l'utente clicca il link dall'email e poi ricarica la pagina prima di impostare la nuova password, `recuperoInCorso` torna `false` mentre la sessione resta valida: `AccountView.vue` mostra il ramo "loggato" invece del form "Nuova password", e l'utente non può più completare il reset né capisce perché — uno scenario comune (F5, tab riaperta), non un edge case remoto.
- **Fix**: derivare lo stato di recupero da qualcosa di persistente (es. un flag scritto in `sessionStorage` al momento dell'evento `PASSWORD_RECOVERY`, riletto al mount) invece che dal solo ref in-memory.
- **Suggested command**: `/impeccable harden`

**[P1] Messaggi di errore e di successo non sono annunciati agli screen reader**
- **Perché conta**: i paragrafi condizionali di errore/messaggio (login, reset, imposta password) non hanno `aria-live`/`role="alert"`. Un utente con screen reader che sbaglia la password o completa una registrazione non riceve alcun annuncio automatico — deve ri-esplorare manualmente il DOM proprio nei due momenti a più alto rischio del flusso. Le due pillole "Accedi"/"Registrati" sono inoltre `<button>` semplici senza `role="tab"`/`aria-selected`: lo stato attivo è solo una classe CSS, invisibile a uno screen reader.
- **Fix**: `aria-live="assertive"` sui paragrafi di errore, `aria-live="polite"` su quelli di successo; aggiungere semantica tab (`role="tablist"/"tab"`, `aria-selected`) alle due pillole di modalità.
- **Suggested command**: `/impeccable audit`

**[P2] Sette valori di font-size fuori dalla type ramp del design system**
- **Perché conta**: il detector conferma 7 punti (righe 10, 15, 20, 45, 76, 104, 229) con `font-size: 12px`/`14px`, nessuno dei quali è uno step della ramp DESIGN.md (11/13/19/26px); un ottavo punto probabile (`h1` a `1.5rem`) sfugge al detector ma è ugualmente fuori ramp. È la stessa vista che, secondo la Regola del Nome in Fraunces, dovrebbe trattare titoli/nomi con la massima coerenza tipografica — qui è quella con più scostamenti puntuali dell'app.
- **Fix**: sostituire ogni valore hardcoded con lo step di ramp più vicino (13px body/ui, 11px label) e rimuovere `style=""` inline a favore delle classi/token esistenti.
- **Suggested command**: `/impeccable typeset`

**[P2] Nessuna via d'uscita dallo stato "Nuova password"**
- **Perché conta**: se un utente arriva sul form "Nuova password" per errore (link vecchio, cambio idea) o si blocca lì, non esiste alcun link "Annulla"/"Torna al login": l'unica UI disponibile è quel form finché non lo si completa o non si esce dall'app manualmente.
- **Fix**: aggiungere un link ghost sotto "Salva password" che esegue `esci()` e riporta al login normale.
- **Suggested command**: `/impeccable harden`

**[P2] La superficie di primo contatto non riflette l'identità "Taccuino da Giardino" nei momenti che contano di più**
- **Perché conta**: nessun elemento a china/acquerello o icona ink-pooling sulla vista non autenticata; dopo la registrazione il form resta identico e attivo (stesso tab, stesso bottone "Crea account", campi ancora popolati) con solo una riga sage da 12px a segnalare l'esito — il momento con la posta emotiva più alta (conferma email obbligatoria) riceve il trattamento visivo più debole di tutta la vista, e Zorba (che altrove "risponde" via `reagisci()`/`confermaCura()`) resta completamente muto qui.
- **Fix**: introdurre un piccolo elemento illustrativo coerente con l'atmosfera Taccuino dietro il form (distinto dal `body::before` globale) e sostituire, dopo una registrazione riuscita, il form con un pannello di conferma dedicato (ripete l'email, spiega il prossimo passo, offre eventualmente "Invia di nuovo"); collegare `reagisci()`/`confermaCura()` a login riuscito/errore/conferma inviata.
- **Suggested command**: `/impeccable onboard`

## Persona Red Flags

**Jordan (primo utilizzo, ansioso)**
- Il tab "Accedi" è selezionato di default anche se, per un nuovo utente, l'intento reale è quasi sempre "Registrati" — nessun segnale ("Nuovo qui?") indica quale tab scegliere.
- Nessun campo "conferma password" in registrazione: un refuso nell'unico campo password si scopre solo al primo login fallito, nel momento più delicato (creare le proprie credenziali).
- Dopo "Crea account" il form resta invariato: Jordan, ansioso, può non fidarsi che sia successo qualcosa e ri-cliccare, ottenendo "Esiste già un account con questa email" — recuperabile ma disorientante.

**Sam (accessibilità, tastiera/screen reader)**
- Errori/messaggi senza `aria-live` (vedi P1): un fallimento di login o una conferma di registrazione passano inosservati senza esplorazione manuale del DOM.
- Le pillole "Accedi"/"Registrati" senza `role="tab"`/`aria-selected`: solo classe CSS, non percepibile via screen reader.
- Nessun `autofocus` sul campo email: un utente da tastiera deve raggiungerlo con Tab prima di poter digitare.

**Riley (stress tester: refresh a metà flusso, email non confermata)**
- Refresh durante il recupero password (P1 sopra) è il problema più serio trovato: rompe silenziosamente l'intero flusso di reset.
- "Email non confermata" è tradotto correttamente ma senza alcuna azione di recupero: se l'email originale è persa, l'unica via è ricominciare la registrazione, che fallirebbe con "Esiste già un account con questa email".
- Doppio submit non è un red flag qui: tutti e quattro i percorsi sono protetti in modo identico e disciplinato.

## Minor Observations

- Stile quasi interamente inline (`style="..."`) invece delle classi BEM del resto della codebase — segnale di manutenibilità/coerenza di processo più debole per questa vista specifica.
- Linguaggio tecnico ("Token GitHub", scope `contents:write`) nella stessa pagina "Account" pensata per un utente da giardino non tecnico — stacco di tono evidente rispetto a "Entra nel Giardino di Zorba".
- Il messaggio di conferma email/reset non ripete l'indirizzo a cui è stata inviata la mail, lasciando un dubbio residuo su "quale email, esattamente".
- Fallback errore generico (`e.message`) per casi Supabase non mappati: può mostrare inglese tecnico grezzo all'utente.

## Questions to Consider

- Se questa è l'unica pagina che un nuovo utente vede prima di fidarsi del prodotto, perché è anche l'unica priva di qualunque elemento a china/acquerello del sistema Taccuino — sobrietà deliberata per l'onboarding, o vista rimasta indietro rispetto al restyle?
- Ha senso che Zorba resti muto proprio nel momento più carico emotivamente (registrazione con conferma email obbligatoria), quando altrove nell'app "risponde" a ogni azione dell'utente?
- Il pannello "Token GitHub" con linguaggio da API dev è nella sede giusta dentro "Account", o merita una sezione "avanzate" separata dal resto della pagina?
