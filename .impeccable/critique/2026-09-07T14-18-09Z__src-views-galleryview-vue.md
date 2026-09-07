---
target: GalleryView
total_score: 19
max_score: 40
na_heuristics: 
p0_count: 2
p1_count: 2
target_identity: "file:/Users/rob/Sites/localhost/giardino/src/views/GalleryView.vue"
target_fingerprint: "sha256:66cf2e8b5dfb21e21ee92d05bc2697f0306b2512bb6c59695b31035db897e5d3"
target_path: /Users/rob/Sites/localhost/giardino/src/views/GalleryView.vue
timestamp: 2026-09-07T14-18-09Z
slug: src-views-galleryview-vue
---
Method: dual-agent (A: aa68d9bbbdfe9d64b · B: ad94209863fed08d6)

# Critique: GalleryView.vue

## Punteggio di Salute del Design

| # | Euristica (Nielsen) | Punteggio | Nodo chiave |
|---|---|---|---|
| 1 | Visibilità dello stato del sistema | 2 | Loading/upload chiari; l'eliminazione non ha alcuno stato "in corso" prima del modale, e l'errore di caricamento lista non dice cosa è fallito |
| 2 | Corrispondenza sistema/mondo reale | 3 | Copy naturale in italiano ovunque nella vista |
| 3 | Controllo e libertà dell'utente | 2 | "Annulla" c'è nel foglio; nessun modo di annullare un upload in corso, nessun recupero post-eliminazione (solo conferma preventiva) |
| 4 | Coerenza e standard | 1 | Bottone "Carica foto" usa `btn-rose` (colore riservato a distruttivo/urgente) invece di `btn-sage`; pattern long-press/right-click per eliminare non usato altrove nell'app |
| 5 | Prevenzione errori | 2 | Bottone upload disabilitato correttamente finché non c'è un file; nessuna validazione lato client oltre l'hint testuale "max 10 MB" |
| 6 | Riconoscimento piuttosto che ricordo | 1 | Eliminare una foto non ha alcuna affordance visibile — nessuna icona, nessun bottone: va scoperto per caso (long-press o tasto destro) |
| 7 | Flessibilità ed efficienza | 1 | Upload di una foto alla volta (niente `multiple`); nessuna eliminazione bulk; nessun modo di vedere una foto ingrandita |
| 8 | Design estetico e minimalista | 3 | Pulito, usa correttamente i token condivisi (Fraunces sui nomi, sistema chip, raggi) |
| 9 | Aiuto a riconoscere/recuperare errori | 1 | Gli errori di upload mostrano il testo grezzo dell'API GitHub (potenzialmente in inglese); l'errore di caricamento lista è una didascalia minuscola senza azione di retry |
| 10 | Guida e documentazione | 3 | Hint minimi e appropriati per una superficie Operate ("JPG o PNG · max 10 MB") |
| **Totale** | | **19/40** | **Scarso** |

## Verdetto di Specificità del Design

**Parzialmente ancorato al prodotto: la pelle è giusta, lo scheletro è generico.**

Il commento stesso nel CSS recita "Colonna feed stile Instagram" — la grammatica compositiva (post con header, media ritagliata 4:5, dots di paginazione, swipe) è presa di peso da un feed social, non da un'identità "taccuino da giardino". DESIGN.md chiede esplicitamente "non è un pannello di controllo: è un quaderno che si sfoglia" — un feed verticale infinito di tessere quadrate non lo è. I singoli token sono corretti (Fraunces su g.nomeSpecie, chip zona con icone acquerellate, raggi 14–22px, riuso di FoglioLaterale/ModalConferma), ma è proprio questa correttezza dei token a mascherare una composizione che potrebbe finire, invariata a parte colori/font, in una qualunque app generica di upload foto. Notabile anche: è l'unica vista importante dell'app senza alcuna presenza di Zorba, nemmeno una filigrana, su una pagina la cui empty-state promette esplicitamente "documenta la crescita" — promessa che il feed piatto e cronologico non sostiene strutturalmente.

Scansione deterministica (impeccable detect, exit code 0, nessun finding primario): 4 finding, tutti advisory —
- riga 98: border-radius: 8px sulla thumbnail (fuori scala, il token più vicino è tag: 6px)
- riga 100: font-size: 20px sul glifo "×" di rimozione foto (fuori scala tipografica)
- riga 119: font-size: 12px sul messaggio di errore upload (mezzo pixel sotto il range Body 12.5–14px documentato — borderline)
- riga 361: border-radius: 3px sul pallino attivo della paginazione — probabile falso positivo: è metà dell'altezza del pallino stesso (6px), tecnica standard per una pillola vera quando l'elemento si allunga a 14px di larghezza

Il detector non ha rilevato l'uso improprio di btn-rose sul bottone di salvataggio (P1 sotto): è un valore di sistema valido usato nel dominio sbagliato, violazione semantica che solo una revisione olistica coglie.

Overlay visivo: non disponibile. Nessun tool di automazione browser è esposto in questa sessione; anche disponendolo, /gallery richiede una sessione Supabase autenticata che l'agente B non aveva. Il fallback live-server è stato avviato e fermato correttamente ma non ha potuto produrre pixel o output di console senza un browser reale.

## Impressione Generale

Il livello dei token (font, colori, raggi) è quasi tutto a posto — ma la vista ha un buco funzionale serio (non si può ingrandire una foto) e un'azione chiave completamente invisibile (eliminare). Per una pagina il cui unico scopo è "guardare le foto del proprio giardino", questi due problemi bloccano il compito principale più di quanto qualunque scelta estetica potrebbe fare. La più grande opportunità: LightboxFoto.vue esiste già, è già cablato in PiantaView.vue con lo stesso commento "condiviso tra GalleryView e PiantaView" — sembra un'integrazione rimasta a metà, non un problema di design da risolvere da zero.

## Cosa Funziona

1. Protezione touchmove contro il long-press accidentale — annullaPressione è agganciato a touchmove/touchend/touchcancel così scorrere il carosello con il pollice non fa scattare per errore il timer di eliminazione.
2. Selettore Libreria/Fotocamera separato invece di un unico input accept="image/*" — aggira consapevolmente un bug noto di Android, riusando lo stesso pattern già risolto in AgenteView.vue.
3. Il gruppo appena caricato risale in cima al feed grazie all'ordinamento per nome-file con prefisso timestamp — l'utente vede subito il risultato della propria azione senza scorrere.

## Problemi Prioritari

**[P0] Nessun modo di vedere una foto a grandezza piena**
Perché conta: toccare .slide non fa nulla — nessun @click. LightboxFoto.vue è importato e funzionante in PiantaView.vue ma mai importato in GalleryView.vue.
Fix: importare LightboxFoto.vue e aggiungere il click handler su .slide/.gimg con f.url, ricalcando il pattern già presente in PiantaView.vue.
Comando suggerito: /impeccable harden

**[P0] Eliminare una foto è indiscoverable e non ha percorso da tastiera**
Perché conta: nessuna icona o bottone visibile — solo @contextmenu.prevent (desktop) o 550ms di pressione prolungata non annunciata (touch). .slide non ha tabindex/role.
Fix: aggiungere un bottone-icona eliminazione sempre presente (o rivelato su focus/hover su desktop, sempre visibile su touch) con aria-label.
Comando suggerito: /impeccable harden

**[P1] Rosa usato su un'azione affermativa, in contraddizione col sistema colori**
Perché conta: il bottone "Carica foto" (riga 125) usa btn btn-rose. DESIGN.md è esplicito: rosa solo per azioni distruttive/irreversibili. Tutte le altre viste usano btn-sage per salvare.
Fix: cambiare in btn btn-sage.
Comando suggerito: /impeccable polish

**[P1] I messaggi di errore possono mostrare testo API grezzo, potenzialmente in inglese**
Perché conta: erroreUpload.value = e.message propaga il testo d'errore grezzo di GitHub (tranne il caso 401). Il percorso di eliminazione nella stessa vista fa già la cosa giusta.
Fix: applicare lo stesso pattern di stringa fissa italiana al blocco catch di caricaFoto.
Comando suggerito: /impeccable clarify

**[P2] Errore di caricamento lista indistinguibile dal "nessuna foto ancora", senza retry**
Perché conta: un fallimento di listaTutte() mostra la stessa illustrazione dell'empty-state con il testo d'errore grezzo appiccicato sotto. Nessuna azione di retry.
Fix: distinguere la resa tra errore e vuoto-vero, aggiungendo un'azione "Riprova".
Comando suggerito: /impeccable harden

## Persona: Bandiere Rosse

**Jordan (prima volta)**: tocca una foto aspettandosi che si apra più grande — non succede nulla. Non scopre che le foto si possono eliminare. Può vedere una stringa GitHub grezza al posto dell'italiano su un upload fallito.

**Sam (dipendente da accessibilità)**: non può ingrandire una foto né via tastiera né via screen reader. Non può eliminare una foto in nessun modo assistivo. Il nome accessibile di ogni foto è il nome file grezzo.

**Casey (utente mobile distratto, "in giardino")**: split Libreria/Fotocamera e protezione touchmove ben ingegnerizzati per questo contesto. Ma caricare più foto in un giro richiede riaprire il foglio e rifare tutto da capo per ogni singola foto, niente flusso batch.

## Osservazioni Minori

- SideNav.vue e la griglia destinazioni di HomeView.vue linkano a questa rotta con l'etichetta inglese "Gallery", mentre il titolo pagina dice correttamente "Galleria".
- alt="f.nome" usa il nome file grezzo come descrizione accessibile di ogni foto.
- Il pallino attivo della paginazione usa var(--rose), colore riservato al dominio distruttivo/urgente, per un indicatore neutro.
- Forte uso di style inline nel foglio di upload invece di classi scoped dedicate; diversi valori non mappano sulla scala di spaziatura dichiarata in DESIGN.md.
- listaTutte() lancia una chiamata API per cartella-pianta in Promise.all, senza paginazione né rendering incrementale.

## Domande da Considerare

- La copy dell'empty-state promette "documenta la crescita", ma niente nell'interazione permette di confrontare nel tempo. La Galleria non dovrebbe essere organizzata per tempo dentro una pianta invece che per piante dentro un feed?
- LightboxFoto.vue esiste già, funziona in PiantaView.vue, ed è commentato come condiviso — questa vista è stata davvero finita, o consegnata a metà integrazione?
- Se il pattern "feed stile Instagram" fosse una scelta deliberata, come sarebbe un'alternativa nativa del "taccuino" — una bacheca stile Polaroid, o un visualizzatore "sfoglia le pagine" per pianta?
