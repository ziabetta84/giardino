# Brief: sistema di feedback e ticketing per la beta

Documento di partenza per `/impeccable`. Descrive che cosa serve, per chi, con quali vincoli. Le scelte di design (layout, testi precisi, stati visivi, gerarchia) sono da proporre e poi da rifinire insieme; qui sono indicate solo come vincoli e riferimenti.

## 1. Obiettivo

Dare ai beta tester un modo semplice per dire che cosa non funziona, che cosa manca o che cosa non si capisce, e far sapere loro che qualcuno ha letto e che cosa è stato fatto. Non è un servizio clienti: la beta è piccola (oggi due account, obiettivo 20-30 inviti) e ogni messaggio conta.

Non è un canale per le domande sulle piante: quelle le gestisce Zorba. Vedi sezione 6.

## 2. Pubblico

- Beta tester invitati a mano: persone con un giardino, un orto o vasi, non necessariamente tecniche.
- Usano l'app su telefono e computer, spesso in giardino, con una mano sola o con le mani sporche di terra.
- Si fidano del progetto per la sua promessa di privacy: niente pubblicità, niente profilazione, foto senza posizione GPS. Qualsiasi elemento del sistema di feedback deve rispettarla.

## 3. Che cosa deve fare il sistema

1. **Inviare** un messaggio in tre categorie: *qualcosa non funziona*, *non riesco a fare una cosa*, *un'idea*.
2. **Allegare il contesto automaticamente** (senza chiedere niente all'utente): pagina da cui arriva, versione dell'app, tipo di dispositivo e browser in forma generica. Nessuna posizione, nessuna foto, nessun dato del giardino.
3. **Mostrare lo stato** al mittente: *ricevuto*, *letto*, *risolto*, *non previsto per ora*, più una risposta breve del curatore quando c'è.
4. **Permettere al curatore** di vedere i messaggi, ordinarli per categoria e stato, cambiare stato e scrivere una risposta. Il curatore lavora da una vista dedicata, non dal database a mano.

## 4. Vincoli tecnici e di prodotto (non negoziabili)

- **Dati su Supabase**, nella stessa istanza delle altre tabelle, con RLS per utente come nel resto del progetto (`owner_id` con default `auth.uid()`).
- **Cancellazione dell'account:** la nuova tabella va aggiunta a `account_elimina_dati` (migration `20261030130000_account_eliminati.sql`, funzione in `20261030120000_elimina_account.sql`), oppure creata con `on delete cascade`. Senza questo, l'eliminazione dell'account non cancella i feedback e la promessa di privacy non regge.
- **Nessun servizio esterno** per il modulo (niente form di terze parti, niente analytics, niente allegati su storage pubblico).
- **Nessuna email automatica** in questa fase. Lo stato si vede in app. L'indirizzo di posta della beta, se serve, è una decisione separata.
- **Nessuna notifica push, né streak, né promemoria** per tornare a lasciare feedback: non sono coerenti con il progetto.
- **Limite di invii** per utente, per esempio 20 al giorno, applicato nel database, non solo nell'interfaccia.
- **Lunghezza del testo:** minimo poche parole, massimo 1000 caratteri. Il campo non è obbligatorio oltre il minimo.
- **Accessibilità:** etichette esplicite, messaggi di errore in italiano e vicini al campo, contrasto adeguato in chiaro e scuro, navigazione da tastiera.
- **Mobile:** margine laterale di 16 px, nessuno scroll orizzontale.

## 5. Vincoli di design

- **Palette e font del progetto:** colori `--rose`, `--gold`, `--sage`, `--olive`, `--cream` su `:root`, con varianti scure. Titoli in Fraunces, interfaccia in DM Sans.
- **Classi già disponibili:** `.card`, `.btn`, `.btn-rose`, `.btn-sage`, `.btn-ghost`, `.badge`, `.form-input`, `.page-title`, `.back-link`, `.section-label`. Usarle prima di crearne di nuove.
- **Tono dei testi:** italiano, dare del tu, calmo, concreto. Nessun «ops!», nessuna enfasi, nessuna promessa di tempi che non si possono mantenere.
- **Dove sta il punto d'ingresso:** una voce semplice, raggiungibile dal menu di navigazione (vedi `NavBar`) e dalla pagina Account (`AccountView.vue`). Non deve sembrare un pulsante di supporto invadente.
- **Stati visivi chiari:** ogni stato del feedback ha un'etichetta testuale oltre al colore, così non dipende solo dal colore.
- **Nessuna icona di Zorba** sul modulo: la mascotte è riservata alle risposte di Zorba sulle piante.

## 6. Confini con Zorba

- Zorba risponde a domande su piante, cure, diagnosi. Già esistono votazioni sulle sue risposte con motivo (`zorba_messaggi`).
- La segnalazione di una scheda del catalogo (`segnalazione_scheda`) va al curatore del catalogo tramite Zorba, e questo flusso resta com'è.
- Il modulo di feedback non entra in Zorba e non passa da Zorba. Non è un altro tipo di filo.

## 7. Dati e modello (indicativo, da verificare con il database)

Tabella `feedback`, da definire nella migration:

- `id` uuid, chiave primaria
- `owner_id` uuid, default `auth.uid()`, riferimento a `auth.users`
- `categoria` testo, con vincolo sui tre valori
- `testo` testo, con vincolo di lunghezza
- `pagina` testo (percorso dell'app, senza parametri), `versione` testo, `dispositivo` testo breve
- `stato` testo, con vincolo sui valori: `nuovo`, `letto`, `risolto`, `non_previsto`
- `risposta` testo, opzionale, scritta dal curatore
- `creato_il`, `aggiornato_il` timestamptz

Permessi:
- l'utente inserisce e legge solo le proprie righe; non può cambiare stato né risposta;
- il curatore lavora con funzioni riservate a `service_role`, come per Zorba;
- nessun accesso in lettura per altri utenti.

## 8. Cosa non fare in questa prima versione

- Thread di conversazione completi (una risposta sola basta).
- Votazione delle idee tra utenti o roadmap pubblica.
- Ricerca o filtri per l'utente.
- Allegati di qualsiasi tipo.
- Analytics sull'uso del modulo.

## 9. Criteri di accettazione

- Un beta tester invia un messaggio in meno di un minuto da una pagina qualsiasi dell'app.
- Il messaggio contiene la pagina e la versione senza che l'utente le scriva.
- Il mittente vede lo stato aggiornato e la risposta del curatore quando c'è.
- Eliminando l'account, le righe `feedback` spariscono (verificato con la funzione di eliminazione).
- Funziona su telefono con una sola mano e con tastiera.
- Nessun testo in inglese, nessun segnaposto.

## 10. Decisioni confermate

1. **Tempo di risposta dichiarato:** tre giorni lavorativi, scritto nel modulo.
2. **Notifiche:** solo in app. Nessuna email per lo stato del messaggio.
3. **Punto d'ingresso:** pulsante sempre visibile. Da definire nel passo di design: su mobile non deve competere con la barra di navigazione in basso (proposta: nella barra in alto, non galleggiante).

## 11. Decisioni ancora aperte

1. **Limite giornaliero di invii** (20 proposti, non ancora confermati).
2. **Il curatore** lavora da una vista nell'app o da SQL? (Proposta: vista dedicata, come `/zorbadice`.)
3. **Posizionamento del pulsante** su mobile (vedi punto 3 sopra).
