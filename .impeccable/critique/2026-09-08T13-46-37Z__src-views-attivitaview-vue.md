---
target: AttivitaView.vue
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 1
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/AttivitaView.vue"
target_fingerprint: "sha256:0abfb92cb6bba5ee1b7050318c3aab586bcbcad78f0c72e5a78724b873753e4f"
target_path: /Users/rob/Sites/localhost/giardino/src/views/AttivitaView.vue
timestamp: 2026-09-08T13-46-37Z
slug: src-views-attivitaview-vue
closed: true
---
## Design Health Score — AttivitaView.vue

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2/4 | registraGruppo()/registraTappa() danno zero feedback esplicito |
| 2 | Match System/Real World | 4/4 | Linguaggio e raggruppamento zona-prima rispecchiano l'uso reale |
| 3 | User Control and Freedom | 2/4 | Undo presente solo per registra() singolo |
| 4 | Consistency and Standards | 3/4 | Tre "Fatto" quasi identici si comportano diversamente |
| 5 | Error Prevention | 1/4 | Nessuna conferma prima di sovrascrivere ultima_cura in bulk |
| 6 | Recognition Rather Than Recall | 4/4 | Tab con conteggi live, icone a colore, consiglio concime in riga |
| 7 | Flexibility and Efficiency | 3/4 | "Segna tutto fatto" utile, manca rinvio/snooze singolo |
| 8 | Aesthetic and Minimalist Design | 3/4 | Pulita, incrinata da scivolone tipografico su nome zona |
| 9 | Error Recovery | 1/4 | try/finally senza catch su tutti e tre i percorsi di scrittura |
| 10 | Help and Documentation | 2/4 | Nessun segnale che la riga apra un dossier |
| **Totale** | | **25/40** | **Accettabile** |

## Verdetto di specificità

LLM: autoriale nella codifica colore e nello stato vuoto "Tutto in ordine!", ma l'interazione "Fatto" e l'intestazione zona (nome trattato come chrome, non Fraunces) assottigliano l'identità.

Detector (exit 0, 3 advisory): design-system-radius riga 14 (skeleton, 8px fuori scala), design-system-radius riga 261 (.tappa-riga--urgente, 10px fuori scala), design-system-font-size riga 254 (.attivita-data, 14px fuori scala tipografica). Nessuna eccezione in .impeccable/config.json copre questi casi. Nessun overlay visivo: nessuno strumento di automazione browser disponibile in questo ambiente (verificato indipendentemente da entrambe le valutazioni).

## Impressione generale
Modellazione di dominio reale e disciplina cromatica quasi perfetta, ma l'azione più frequente e più a rischio (bulk "Segna tutto fatto") è la meno protetta: nessun feedback, conferma, undo o gestione errori.

## Cosa funziona
1. Codifica colore per dominio esatta (acqua/olive/uovo -bg/-ink, rosa solo su urgente).
2. "Tutto in ordine!" è un momento autoriale vero (entrata 600ms documentata).
3. Ingegneria difensiva reale (stagger limitato, fallback pianta eliminata nel dossier).

## Problemi prioritari

[P0] Fallimento silenzioso su tutti i percorsi di scrittura — registra()/registraGruppo()/registraTappa() (righe ~219-250) usano try/finally senza catch; su PWA da campo una scrittura fallita è indistinguibile da una riuscita. Fix: propagare l'errore allo stesso canale già usato da ToastCura.annulla(). Comando: /impeccable harden

[P1] Nessun undo/conferma per le azioni bulk/tappa — registraGruppo()/registraTappa() non chiamano mai toastCura.value?.apri(...) come registra(). Fix: estendere la coda di ToastCura a un lotto ("N cure registrate — Annulla tutte"). Comando: /impeccable harden

[P1] Bottone annidato in div[role=button] — AttivitaRiga.vue ripete l'anti-pattern ARIA che DESIGN.md nomina esplicitamente (visto altrove nell'Album Polaroid). Fix: bottone fratello del contenitore cliccabile. Comando: /impeccable harden

[P2] Nome zona in tipografia di servizio — AttivitaGruppoZona.vue riga 5, etichettaZona dentro .slabel (DM Sans) invece che Fraunces, mentre .tappa-riga__t nella stessa vista lo fa correttamente. Comando: /impeccable typeset

[P3] Nessun focus-visible coerente e nessuna semantica da tab sulle pillole filtro. Comando: /impeccable harden

## Red flag per persona
Sam: bottone annidato rompe il doppio tocco VoiceOver/TalkBack; tab senza aria-selected; dialog FoglioLaterale senza aria-labelledby; toast undo 6s non estendibile.
Riley: salvando/salvandoGruppo condivisi fanno cadere silenziosamente tap rapidi su righe diverse; gruppi zona senza tetto dimensionale; Promise.all tutto-o-niente su registraCuraMultipla.
Casey: riga intera cliccabile con bottone piccolo annidato dentro causa aperture accidentali del dossier; nessun chevron; toast 6s facile da perdere.

## Osservazioni minori
- .attivita-data usa Fraunces corsivo correttamente ma a 14px fuori scala tipografica.
- Righe progetto navigano via RouterLink, righe cura aprono un foglio: due modelli diversi per "vedi di più".
- Badge dei tre tab tutti badge-warn (rosa) senza rinforzare il colore di dominio proprio.
- Stagger transitions (0.7s/0.5s ease-in-out) fuori dai token di movimento canonici, pattern preesistente nel codebase.

## Domande provocatorie
- E se "Segna tutto fatto" avesse lo stesso trattamento toast+undo del percorso singolo, raggruppato?
- E se "Zorba conferma" scattasse da usePianteApi invece che solo da HomeView.vue?
