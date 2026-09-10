---
target: AccountView
total_score: 26
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/AccountView.vue"
target_fingerprint: "sha256:ca4c73cac584c8f8507c306e369f320a6284bcbe75962ac9b46ddb0fa4d13589"
target_path: /Users/rob/Sites/localhost/giardino/src/views/AccountView.vue
timestamp: 2026-09-10T07-01-32Z
slug: src-views-accountview-vue
---
# /impeccable critique — src/views/AccountView.vue

⚠️ DEGRADED: single-context (nessuna richiesta esplicita dell'utente di usare sub-agenti; automazione browser non disponibile in questa sessione)

Assessment A (design review) ed Assessment B (detector) eseguiti in sequenza nello stesso contesto: prima il giudizio di design, poi `impeccable detect`. Nessuna ispezione live del browser.

## Design Health Score

| # | Euristica | Voto | Problema chiave |
|---|-----------|:---:|-----------------|
| 1 | Visibilità dello stato del sistema | 3 | Durante `caricamento` la vista non renderizza nulla: schermo vuoto al primo caricamento da slogato. Salvataggio token senza conferma esplicita. |
| 2 | Corrispondenza col mondo reale | 3 | Italiano naturale e caldo. `ghp_…` è gergo, ma quel campo ha come unico destinatario Rob. |
| 3 | Controllo e libertà | 3 | Annulla / "torna al login" ovunque, modale di conferma sul token. Manca un "reinvia email" dopo la registrazione. |
| 4 | Coerenza e standard | 2 | `.btn` forzato a 36px in modo incoerente; due sistemi di etichetta (`slabel` + `field-label`) impilati nella stessa card; classe `tab-icona` inerte; "Annulla" a volte link, a volte bottone. |
| 5 | Prevenzione degli errori | 3 | `type=email`, `minlength`, `maxlength`, modale prima della rimozione token. Nessun show/hide password. |
| 6 | Riconoscere anziché ricordare | 3 | Campi etichettati, `autocomplete` corretto e commutato, "Password dimenticata?" visibile. |
| 7 | Flessibilità ed efficienza | 3 | Invio da tastiera sui campi inline, `autofocus`, submit su Enter, disabilitazione durante l'invio. Adeguato alla superficie. |
| 8 | Estetica e minimalismo | 2 | Vista loggata = pila di 3–4 card bianche piatte con bordo hairline. La card del token GitHub (in via di dismissione) è l'elemento visivamente più pesante. |
| 9 | Recupero dagli errori | 2 | `errore.value = e.message`: le stringhe d'errore di Supabase Auth passano grezze e in inglese ("Invalid login credentials", "Email not confirmed") sulla porta d'ingresso di un'app tutta in italiano. |
| 10 | Aiuto e documentazione | 2 | Buona spiegazione inline sulla card token; nient'altro, ma la superficie non ne richiede molto. |
| **Totale** | | **26/40** | **Accettabile (fascia bassa)** |

## Design Specificity Verdict

Valutazione LLM — spaccata in due. Lo stato slogato è specifico e riconoscibile: `account-hero` con Zorba 64px e alone ad acquerello dedicato (`::before` radiale gold→sage), più il cablaggio della "Regola dei Due Battiti" (`zorba.reagisci()` su registrazione e reset). Vero momento di primo contatto, esito della critica del 08/09.

Lo stato loggato è il più anonimo dell'app: titolo "Account" + tre `form-card` bianche con bordo hairline, nessun Zorba, nessun lavaggio d'acquerello. È l'anti-riferimento esplicito di DESIGN.md ("superfici piatte grigie … da tool aziendale"). Zorba — "presenza ricorrente dell'assistente" — compare fuori e sparisce dentro: il contrario di quanto dovrebbe. Per una vista dichiarata critica per la fiducia e mostrabile all'agenzia, la ricompensa dell'accesso è lo schermo più scialbo del prodotto.

Scansione deterministica: `impeccable detect --json src/views/AccountView.vue` → `[]`, exit 0. Nessun pattern generico rilevato. Le criticità sono tutte di sintesi umana; nessun falso positivo.

Overlay visivi: non disponibili (nessuna automazione browser esposta). Recensione da sorgente (`AccountView.vue`, `App.vue`, `main.css`).

## Overall Impression

Fondamenta funzionali solide (stati di caricamento, `role=alert`/`role=status`, `autocomplete`, guard async). Ma il valore della vista per il progetto sta nella fiducia e nella dimostrabilità, e lì si ferma a metà: metà slogata curata, metà loggata un pannello impostazioni qualunque. Opportunità più grande: portare l'identità (Zorba, acquerello, nome in Fraunces) nello stato loggato con la cura già data allo stato slogato.

## What's Working

1. Il momento di primo contatto (`account-hero`): Zorba + alone ad acquerello dedicato, distinto dal lavaggio globale, nel punto giusto. Collegamento a `reagisci()` (battito lento = evento raro) su registrazione e reset: delight misurato.
2. Il pannello "Controlla la posta": sostituisce il form con un pannello centrato dedicato nel momento a più alta posta emotiva; copy chiara e rassicurante.
3. Igiene dell'autenticazione: `autocomplete` commutato `current-password`/`new-password`, `type=email` + `required` + `minlength`, submit su Enter, azioni async disabilitate durante l'invio, messaggi con `role=alert`/`role=status`.

## Priority Issues

### [P1] Lo stato loggato abbandona il linguaggio visivo del prodotto
- Perché conta: vista dichiarata critica per la fiducia e mostrabile all'agenzia. Lo stato slogato ha un momento brand su misura; la metà loggata resta tre card piatte — l'anti-riferimento esplicito di DESIGN.md. Zorba assente proprio qui.
- Fix: elemento d'ancoraggio del brand nell'header loggato — Zorba piccolo (`.zorba-mini`) che saluta per nome in Fraunces; mantenere il lavaggio d'acquerello; fondere email + nome + logout in un blocco identità più caldo invece di `slabel` → `field-label`.
- Comando: /impeccable bolder (o /impeccable delight)

### [P1] Stringhe d'errore in inglese sulla porta d'ingresso
- Perché conta: `errore.value = e.message` passa grezzi i messaggi di Supabase Auth ("Invalid login credentials", "User already registered", "Email not confirmed"). App tutta in italiano, la memoria di progetto vieta stringhe UI in inglese, ed è la schermata che un potenziale sponsor vede per prima al fallimento del login.
- Fix: mappare i codici/messaggi noti di Supabase Auth su copy italiana in `useAuth.js` (helper `traduciErroreAuth`), con fallback generico italiano.
- Comando: /impeccable clarify

### [P2] I bottoni sono rimpiccioliti a mano a 36px, contro il sistema
- Perché conta: quasi ogni bottone porta `style="min-height:36px;padding:6px 14px;font-size:13px"`, che scavalca il target da 44px di DESIGN.md e `.btn`. PWA mobile-first usata in giardino: sotto 44px si viola WCAG 2.5.5. L'unico bottone senza override (`Esci`) resta a 44px → altezze miste.
- Fix: togliere il rimpicciolimento inline; se serve un controllo più piccolo, aggiungere `.btn--sm` documentato al sistema.
- Comando: /impeccable layout (poi /impeccable polish)

### [P2] La card del token GitHub (in dismissione) è il centro visivo della vista loggata
- Perché conta: card più grande, paragrafo più lungo, due sotto-stati e una modale — per un meccanismo che la memoria di progetto dice in uscita e non meritevole di investimento UX. Seppellisce identità account e link impostazioni.
- Fix: comprimerla in una riga (stato + "Gestisci") espandibile su richiesta, o spostarla in `/impostazioni`.
- Comando: /impeccable distill

### [P2] Pattern di azione secondaria incoerenti + classe morta
- Perché conta: "Annulla" a volte `.link-reset`, a volte `.btn-ghost`; annulla della modale è un bottone. `slabel` e `field-label` entrambi intestazione nella stessa card. `tab-icona` applicata ma `scoped` in AttivitaView → inerte. Tab senza `aria-controls`/`role="tabpanel"`.
- Fix: una sola affordance di annullamento per la vista, un solo sistema di label per card, rimuovere `tab-icona`, completare ARIA delle tab.
- Comando: /impeccable polish

## Persona Red Flags

Jordan (prima volta): si registra, vede "Controlla la posta", torna più tardi, prova ad accedere → "Email not confirmed" in inglese. Nessun "reinvia email". Può concludere che l'account è rotto.

Casey (mobile, una mano, in giardino): cluster "Modifica / Salva / Esci" loggato a 36px e in cima alla card; su connessione lenta, durante `caricamento`, schermo bianco senza spinner. Bottoni primari slogati full-width 44px — ok.

Sam (screen reader / tastiera): tab con `role="tab"`/`aria-selected` ma senza `aria-controls` verso un `role="tabpanel"`. Al cambio ramo (login → pannello conferma) il focus resta su un bottone nascosto; `role="status"` aiuta ma il focus non viene spostato. Target sotto 44px. Buono `role="alert"` sugli errori.

## Minor Observations

- Flash vuoto al freddo: ramo slogato con `caricamento` true non renderizza nulla. Anche solo l'hero di Zorba stabilizzerebbe.
- Nessun "reinvia" dopo la registrazione: se la mail non arriva, l'utente è bloccato.
- Salto di larghezza container: 420px (loggato) vs 340px (slogato) al primo ingresso dopo la registrazione.
- Password senza show/hide.
- Duplicazione dell'editor inline: nome e token re-implementano una struttura quasi identica; un piccolo componente condiviso taglierebbe gli stili inline.
- `autofocus` come attributo (non `.focus()`): col `<Transition>` attorno a `RouterView` può scattare prima che l'elemento sia visibile — da verificare.

## Questions to Consider

- Cosa si prova a essere "dentro l'account" adesso vs. cosa si potrebbe provare? Dovrebbe accoglierti come l'hero della Home?
- Se il token GitHub sta uscendo, perché è la cosa più grande sullo schermo?
- La vista slogata ha avuto un momento brand su misura dalla critica precedente: cosa servirebbe per dare alla metà loggata gli stessi 20 minuti?
