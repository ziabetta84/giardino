# Fonti delle immagini delle piante — ricerca del 13/10/2026

Ricerca in tre lenti (foto con licenza aperta, illustrazioni di pubblico dominio, copertura sulle nostre specie) più verifica avversaria delle licenze. Nessuna modifica al database. Legenda: [V] verificato, [R] solo da fonte indiretta, [D] deduzione da far confermare a un legale prima della sponsorizzazione.

1) COSA HA RETTO E COSA HO CORRETTO
Ho riaperto le pagine dei termini, anche quelle che rispondevano 403, usando le copie Wayback del 2026. Risultato: nessuna fonte giudicata "commerciabile" in realtà vieta l'uso commerciale. Ho però trovato sette affermazioni imprecise o da precisare:
- iNaturalist, "le foto sul dominio inaturalist-open-data sono aperte". Aperte vuol dire con licenza CC, NC compresa, non commerciabili. Il README del dataset porta come esempio «(CC-BY-NC)» e la foto 338155266 (Calibrachoa), che sta su quel dominio, è CC BY-NC [V]. Il dominio non basta: la licenza va letta foto per foto.
- iNaturalist, divieto di addestrare IA a fini commerciali: da [R] passa a [V]. Termini (rev. 11/07/2023, copia Wayback dell'11/09/2026): «Users may not use any iNaturalist data for training artificial intelligence, machine learning models … for commercial purposes». Diventano [V] anche il limite di 5 GB/ora o 24 GB/giorno di media e la richiesta di circa 1 richiesta al secondo (copia Wayback del 18/09/2026).
- Pl@ntNet, "non è chiaro se il piano gratuito ammetta l'uso commerciale". I Termini dell'API dicono che è gratuita fino a 500 identificazioni al giorno e che «is paying for commercial usage beyond 500 identification requests per day» [V]: entro le 500 al giorno l'uso commerciale sembra ammesso [D]. Il contratto in vigore è la v5.1, non la v4.2, ma la clausola sulle immagini è la stessa: CC-BY, CC-BY-SA, pubblico dominio, uso commerciale ammesso «subject to indicate the source and the owner» [V].
- Flickr, "chiave API solo per gli abbonati Pro": da [R] passa a [V] (help center, aggiornato al 06/08/2025, copia Wayback del 29/09/2026). In più l'API limita il download di originali sopra i 1024 px dagli account gratuiti. Termini dell'API (copia Wayback del 03/10/2026): vietato conservare le foto oltre «reasonable periods», massimo 30 foto per pagina, avviso obbligatorio «This product uses the Flickr API but is not endorsed…», la chiave commerciale può essere a pagamento [V].
- Openverse: il filtro `commercial` include non solo CC BY-ND ma anche la vecchia licenza "Sampling+", che consente di mostrare l'opera intera solo per fini NON commerciali [V, sorgente licenses.py e pagina della licenza su creativecommons.org].
- Rawpixel: la clausola «considerable artistic value» sul merchandising non è nel paragrafo "Public Domain License", che dichiara CC0, uso commerciale libero e nessuna attribuzione. Sta nella licenza commerciale e nelle regole generali sulle «our images» [V, copia Wayback del 31/12/2025]. Non è chiaro se valga anche per i file PD [D]. La conclusione non cambia: prendere la tavola dalla fonte originale.
- GBIF: il Data User Agreement è ora [V] (copia Wayback del 24/07/2026). Chiede di citare chi ha pubblicato i dati (DOI dove possibile), le licenze scelte dagli editori prevalgono, la qualità non è garantita. Ho rifatto la misura dello scarto fra licenza del record e licenza della foto: su Laurus nobilis, nei record CC BY, 42 media su 455 (9%) sono NC o ND [V].
Confermato senza correzioni [V]:
- Commons non accetta file NC né ND: la pagina Commons:Licensing richiede che uso commerciale e opere derivate siano consentiti.
- Il collegamento diretto alle immagini di Commons è «possible, but is not recommended».
- Su 100 immagini del DB prese a caso, tutte e 100 esistono ancora con la stessa licenza.
- La licenza predefinita di iNaturalist è CC BY-NC (help center e Termini).
- Il research grade di iNaturalist esclude le piante coltivate.
- Su GBIF il filtro di licenza vale solo per il record (lo conferma lo staff nella issue #3831).
- Su BHL i volumi ancora protetti sono «almost always» CC BY-NC-SA 4.0.
- La NYPL Repo API chiude il 1/8/2026.
- L'art. 32-quater della legge italiana sul diritto d'autore (testo su Normattiva, in vigore dal 12/12/2021) rende libere le riproduzioni fedeli di opere d'arte visiva in pubblico dominio, ma fa salvo il Codice dei beni culturali.

2) PROBLEMI NUOVI EMERSI NEI NOSTRI DATI E NELL'APP [V]
a) Attribuzione mostrata. Il credito c'è: l'app scrive «Foto: <autore> / Wikimedia Commons» con un link alla pagina del file su Commons (PiantaView.vue, SelettoreSpecie.vue; nelle righe degli elenchi si vede aprendo la scheda, per scelta, PiantaRiga.vue). Manca solo il nome della licenza con il suo link (i dati ci sono: `immagine.licenza`, `immagine.licenza_url`). Per le licenze CC 4.0 un link a una pagina che contiene le informazioni può bastare [D]. Le versioni 2.0, 2.5 e 3.0 chiedono invece testualmente di includere il link alla licenza «with every copy … publicly display[ed]» [V, testo legale]. Sono 1.884 immagini: BY-SA 3.0 929, BY-SA 2.0 481, BY 2.0 321, BY 3.0 116, BY 2.5 20, BY-SA 2.5 17.
b) Autore sbagliato su 24 immagini CC. 20 sono accreditate a «Wikimedia Commons» (15 CC BY 4.0, 5 CC BY-SA 3.0), 4 a «unknown/anonymous». Per esempio Auckland Museum e Wellcome Collection: nei metadati di Commons l'autore c'è, ma l'importazione non l'ha letto.
c) Specie sbagliata. Rubus almus mostra «File:Trilliumgrand.jpg», cioè un Trillium grandiflorum.
d) Immagini principali che non sono foto della pianta (contate dai nomi dei file, quindi stime per difetto): 51 libri interi .djvu o .pdf, almeno 37 mappe di distribuzione, 43 foto di campioni di legno (xiloteca Cirad), circa 120 fogli d'erbario.
e) Cultivar senza immagine. 123.286 cultivar su 196.343 (63%) hanno una madre senza immagine e quindi restano senza foto. 385 righe "Genere spp." su 477 non hanno immagine.
f) Revisione. Il campo `verificata` è false su tutte le 7.722 immagini.

3) COPERTURA MISURATA (dalle tre ricerche; i numeri del DB li ho ricontrollati)
- Catalogo: 7.722 specie madri su 15.723 hanno un'immagine (49%). Per licenza: CC BY-SA 5.404 (70%), CC BY 1.099 (14%), CC0 o pubblico dominio 1.219 (16%).
- Le 93 piante dell'utente: 81 hanno un'immagine propria, 85 contando quella ereditata dalla madre. Delle 81: 71 CC BY-SA, 3 CC BY, 7 CC0/PD.
- Fonti alternative, piante dell'utente (93) / campione casuale (40 specie madri):
  - Commons: 93/93 e 32/40
  - iNaturalist: 89/93 e 32/40
  - GBIF: 90/93 e 33/40
  - almeno una delle tre: 93/93 e 37/40
- I 21 buchi del campione casuale: Commons ne colma 15, iNaturalist 16, GBIF 15, le tre insieme 18. Gli 8 buchi delle piante dell'utente sono colmabili tutti già da Commons. Le righe importate da RHS hanno un'immagine nel 39% dei casi, quelle da PFAF nell'80%.
- Tavole botaniche in pubblico dominio anteriori al 1900: 28% su un campione di 400 binomi (IC95% circa 24-32%); 22% tra le specie oggi senza immagine; 40 piante dell'utente su 62. Le cultivar sono coperte solo per la frutta storica (USDA Pomological, 7.592 acquerelli).
- iNaturalist: solo il 13,0% delle osservazioni research grade di piante con foto ha almeno una foto commerciabile (10.922.663 su 84.105.794, rimisurato oggi). Il 62,4% è CC BY-NC.
- Pl@ntNet su GBIF: 388 media su 388 sono CC BY-SA (rimisurato).

4) RACCOMANDAZIONE (in parole semplici)
Ordine di preferenza:
1. Wikimedia Commons resta la fonte principale delle foto. Tra più foto della stessa pianta, scegliere prima quelle CC0 o di pubblico dominio, poi CC BY, e CC BY-SA solo se non c'è altro. Prima di aggiungere fonti nuove conviene completare l'importazione da Commons: ha già foto utilizzabili per tutte le 8 piante dell'utente senza immagine e per 15 dei 21 buchi del campione.
2. Per lo stile "taccuino", un secondo strato di tavole botaniche storiche in pubblico dominio, sempre da Commons. Conviene limitarsi a poche serie dallo stile uniforme (Köhler, Thomé, Lindman, Curtis fino al 1920 circa, Flore des serres, Edwards, Redouté), più gli acquerelli USDA Pomological per gli alberi da frutto. Si possono ritoccare o acquerellare liberamente, a una condizione: che l'artista sia morto entro il 1955.
3. iNaturalist solo per riempire i buchi rimasti, una foto alla volta, controllando che la licenza sia CC0, CC BY o CC BY-SA. Non usare la "foto predefinita" senza controllo: per Aralia bipinnata le prime 5 foto curate sono NC o con tutti i diritti riservati, solo la sesta è CC BY-SA.
4. GBIF e Pl@ntNet (tramite il dataset Pl@ntNet su GBIF) per le piante coltivate o ornamentali che mancano altrove, controllando la licenza di ogni foto.
5. BHL, con una chiave API, come riserva per le tavole, solo dai volumi segnati "Public domain".

Cosa comporta per i crediti da mostrare:
- Accanto a ogni foto CC: autore vero, nome della licenza con link, link alla fonte. Per esempio: «Foto: Krzysztof Ziarnek, CC BY-SA 4.0, via Wikimedia Commons».
- Per Pl@ntNet va aggiunta anche la menzione «Pl@ntNet».
- Per GBIF va citato il dataset.
- Per le tavole in pubblico dominio il credito non è obbligatorio ma è consigliato: «Tavola: artista, opera, anno».
- Le cultivar che mostrano la foto della madre dovrebbero dirlo in chiaro [D].
- Ritagli o filtri ad acquerello sono modifiche: vanno dichiarate, e una modifica di una foto CC BY-SA va ripubblicata con la stessa licenza. Ridimensionare o convertire il formato non conta come modifica. Il resto dell'app non viene "contagiato" dalla CC BY-SA.
- Correggere i 24 crediti sbagliati e aggiungere il link alla licenza, obbligatorio almeno per le 1.884 immagini con licenze 2.0, 2.5 e 3.0.
- Conservare per ogni immagine licenza, autore, URL e data di verifica: il DB ha già i campi, ma nessuna immagine è stata verificata.

Cosa NON usare e perché:
- Qualunque foto NC o ND. Sono NC la licenza predefinita di iNaturalist, i volumi BHL ancora protetti e il 9-13% dei media dentro record GBIF "CC BY".
- Flickr: chiave API solo per abbonati Pro più una chiave commerciale, vietato conservare le foto, rischio di foto altrui ricaricate con licenze false.
- Openverse come fonte: il suo filtro "commercial" include ND e Sampling+, le licenze non sono verificate, senza registrazione consente 200 richieste al giorno. Va bene solo per cercare candidati da verificare.
- Rawpixel e Plantillustrations come fonti dei file: licenza ambigua e protezione anti-bot.
- NYPL: l'API è chiusa dal 1/8/2026.
- Smithsonian: quasi solo fogli d'erbario.
- iNaturalist per addestrare un modello che generi acquerelli: è vietato dai Termini.
- Da far vedere a un legale prima della sponsorizzazione: le rielaborazioni di foto CC BY-SA, le tavole del Novecento, le scansioni di biblioteche statali italiane (Codice dei beni culturali).

## Wikimedia Commons, fotografie (fonte attuale del catalogo)
Licenze: [V] Solo licenze libere: CC0, pubblico dominio, CC BY, CC BY-SA e affini. Commons:Licensing vieta le licenze «non-commercial only» ed esige che siano consentiti l'uso commerciale e le opere derivate, quindi niente NC né ND. Nel DB: CC BY-SA 4.0 3.977, 3.0 929, 2.0 481, 2.5 17; pubblico dominio 718; CC BY 4.0 642, 2.0 321, 3.0 116, 2.5 20; CC0 501 (totale 7.722). Su un campione di 50 file in pubblico dominio i tag sono soprattutto PD-old, PD-self, PD-USGov e PD-France; solo 2 hanno il solo PD-US,
Commerciale: [V] Sì per tutte le licenze presenti. Con CC BY-SA la versione modificata va ripubblicata CC BY-SA: «Adapted Material» comprende materiale «altered, transformed», mentre le «technical modifications» come il ridimensionamento non producono mai Adapted Material (CC BY-SA 4.0, §1 e §2(a)(4)). Una racco
Attribuzione: [V] CC 4.0 (§3(a)): creatore, avviso di copyright, riferimento alla licenza con URI, link al materiale, indicazione delle modifiche; ammessa «in any reasonable manner», anche con un link a una pagina che contiene queste informazioni. CC 2.0 e 3.0: «You must include a copy of, or the Uniform Resource
Copertura: [V] Catalogo: 7.722 specie madri su 15.723 (49%). Piante dell'utente: 81/93 con immagine propria, 85/93 con quella della madre; Commons ha foto commerciabili per 93/93, compresi gli 8 buchi. Campione casuale di 40 specie madri: 19/40 nel DB, 32/40 su Commons, che colma 15 dei 21 buchi. Su 23 specie senza immagine, 18 hanno file CC0/PD o CC BY. Righe RHS con immagine: 39%; righe PFAF: 80%.

## Tavole botaniche storiche in pubblico dominio su Wikimedia Commons (serie omogenee: Köhler, Thomé, Lindman, Curtis, Flora Batava, Flore des serres, Edwards, Redouté)
Licenze: [V] Campione delle piante dell'utente, 1.200 file: pubblico dominio 863, «No restrictions» 223, CC0 16, CC BY o CC BY-SA circa 98 (per esempio le riproduzioni Wellcome in CC BY 4.0). Nessun file NC o ND. Template delle serie: Köhler {{PD-old}}, Thomé {{PD-old-auto-expired|deathyear=1925}}, Lindman {{PD-Nordens Flora}}.
Commerciale: [V] Le riproduzioni fedeli di opere d'arte visiva in pubblico dominio non sono protette in Italia: art. 32-quater LdA (testo su Normattiva, in vigore dal 12/12/2021), che però fa salvo il d.lgs. 42/2004 sui beni culturali. [D] In Italia il pubblico dominio scatta 70 anni dopo la morte dell'artista, 
Attribuzione: Non obbligatoria per il pubblico dominio e il CC0, ma consigliata: artista, opera, anno, pagina Commons. [D] In Italia il diritto morale di paternità non scade, quindi è prudente citare sempre l'artista. Obbligatoria per i file CC BY (per esempio «Wellcome Collection, CC BY 4.0»).
Copertura: [V] Campione di 400 binomi: 28% (IC95% circa 24-32%) ha almeno una tavola PD o CC0 anteriore al 1900; 22% tra le specie oggi senza immagine; piante dell'utente 40/62. Mancano le ornamentali moderne (Pilea, Nassella, Carex oshimensis, Sedum morganianum, Trachelospermum…) e in pratica tutte le cultivar. Serie: Köhler 318 file, Thomé 887, Lindman 827.

## USDA Pomological Watercolor Collection (via Wikimedia Commons)
Licenze: [V] Template Commons PD-USGov-USDA-NAL-Pomological-Watercolors: «As a work of the U.S. federal government, the image is in the public domain in the United States».
Commerciale: [V] Sì negli Stati Uniti. [D] In Italia: gli artisti morti entro il 1955 sono comunque in pubblico dominio. Per gli altri (per esempio R. C. Steadman, morto nel 1964), con la regola del termine più breve della direttiva UE sulla durata (paese d'origine extra-UE con protezione nulla) l'opera dovrebbe
Attribuzione: Non obbligatoria. Consigliato: «USDA Pomological Watercolor Collection, National Agricultural Library», con artista e anno. [R] La NAL chiede di essere contattata per l'uso in pubblicazioni: la pagina NAL è solo JavaScript, non l'ho letta.
Copertura: [V] Solo frutta, 1886-1942, anche a livello di cultivar storiche: Prunus persica 978 file, Citrus sinensis 248, Persea 107, Olea europaea 8; i kumquat sono sotto «Fortunella».

## iNaturalist
Licenze: [V] Licenza scelta foto per foto: cc0, cc-by, cc-by-sa, cc-by-nc (PREDEFINITA, confermata da help center e Termini), cc-by-nc-sa, cc-by-nd, cc-by-nc-nd, oppure nessuna (tutti i diritti riservati). Osservazioni research grade di piante con foto (rimisurato il 13/10/2026): 84.105.794. Con almeno una foto CC0, CC BY o CC BY-SA: 10.922.663 (13,0%). CC BY-NC: 62,4%. CORRETTO: il dominio inaturalist-open-data ospita anche foto CC BY-NC (README del dataset; foto 338155266, CC BY-NC); «open» non signifi
Commerciale: [V] Solo foto con licenza cc0, cc-by o cc-by-sa (cc-by-nd ammette l'uso commerciale ma non la rielaborazione). La licenza dell'osservazione non vale per le foto (osservazione 28348298: cc-by-sa, foto cc-by). Il filtro photo_license significa «Must have at least one photo with this license». [V, prim
Attribuzione: [V] L'API restituisce `attribution` già pronta, per esempio «(c) William G. Borges, some rights reserved (CC BY)». Per il CC0: «Nome, no rights reserved (CC0)».
Copertura: [V] Piante dell'utente: 89/93. Campione casuale: 32/40; colma 16 dei 21 buchi, e 3 che Commons non copre (Aralia bipinnata, Curio articulatus, Tradescantia chrysophylla). La foto predefinita del taxon è commerciabile solo per 20 piante dell'utente su 93 e 4 specie del campione su 40. Aralia bipinnata (ricontrollata): delle prime 6 foto curate, solo la sesta (30059916) è CC BY-SA.

## GBIF (immagini delle occorrenze)
Licenze: [V] La licenza del record è solo una fra CC0_1_0, CC_BY_4_0 e CC_BY_NC_4_0. La licenza del media è un campo di testo libero e indipendente. Staff GBIF (issue #3831): «currently we don't support media licenses filter, license filter applies only to records».
Commerciale: [V] Solo controllando la licenza di ogni singola foto. Rimisurato oggi: Laurus nobilis, record CC BY 4.0: 42 media NC o ND su 455 (9%), per esempio l'occorrenza 6320359885 con foto by-nc-nd. La ricerca precedente aveva trovato 1.244 su 9.343 (13%) su più specie.
Attribuzione: [V] Data User Agreement (copia Wayback del 24/07/2026): citare chi ha pubblicato i dati, «where appropriate through use of a Digital Object Identifier»; in caso di conflitto prevalgono le licenze scelte dagli editori. Per la foto: rightsHolder o creator più la licenza del media.
Copertura: [V] 141,5 milioni di record di piante con immagini. Piante dell'utente: 90/93. Campione casuale: 33/40; colma 15 dei 21 buchi. Media aperti da fonti diverse da iNaturalist: piante dell'utente 43/93, campione 14/40 (Pl@ntNet, Arter.dk, servizio norvegese, NatureMapr).

## Pl@ntNet (API e dataset su GBIF)
Licenze: [V] Contratto API v5.1 (versione in vigore citata nei Termini; CORRETTO, la ricerca precedente usava la v4.2): «All images used in Pl@ntNet API are under … CC-BY …, CC-BY-SA … and Public domain». Documentazione: «Most images … CC BY-SA … always check the specific license for each image». Metadati delle osservazioni in CC BY. Rimisurato: dataset GBIF Pl@ntNet, 300 record, 388 media su 388 cc-by-sa.
Commerciale: [V] Documentazione: «Commercial use is permitted under CC BY-SA (images) and CC BY (data) licenses, provided that attribution requirements are met». Contratto: uso «internal and / or commercial … subject to indicate the source and the owner». CORRETTO: i Termini dell'API dicono «free of use up to 50
Attribuzione: [V] Minimo obbligatorio: menzione di Pl@ntNet, licenza, nome del contributore. Esempio ufficiale: «Photo(s): [Contributor Username], CC BY-SA / Data source: Pl@ntNet (https://plantnet.org), CC BY». Con il piano gratuito: frase «…based on the Pl@ntNet recognition API…» e logo (il piano Pro è indicato
Copertura: [V] 2,59 milioni di osservazioni con immagini su GBIF. Progetto 'useful' (piante coltivate e ornamentali): 5.547 specie. Esempio: Thymus × citriodorus, 58 media aperti tutti da Pl@ntNet.

## Biodiversity Heritage Library (BHL)
Licenze: [V] Tre stati: Public domain (regola USA, pubblicato più di 95 anni fa); «No known copyright restrictions» («proceed with caution»); in copyright con licenza «Almost always a … CC BY-NC-SA 4.0».
Commerciale: [V] Volumi in pubblico dominio: «free to reuse it including commercial reuse». Volumi in copyright: «Usually, you can NOT reuse … for commercial purposes», quindi vanno esclusi. «Commercial use carries higher risk». BHL valuta solo la legge USA. [D] In Italia va verificata la data di morte dell'arti
Attribuzione: [V] Di cortesia: «Image from the Biodiversity Heritage Library. Contributed by [Holding Institution]».
Copertura: Non misurata (nessuna chiave). [D] È la raccolta più ampia di tavole dell'Ottocento.

## Openverse (aggregatore)
Licenze: [V] Filtri `license` e `license_type`. CORRETTO/ESTESO: `commercial` = tutte le licenze senza 'nc', quindi include CC BY-ND e la licenza ritirata «sampling+». Quest'ultima permette di mostrare l'opera intera solo «for noncommercial purposes» (deed su creativecommons.org).
Commerciale: [V] Dipende dalla fonte. Termini: Openverse «does not verify its licensing status». Il filtro `commercial` non basta per un'app sponsorizzata.
Attribuzione: [V] Attribuzione già pronta nel campo `attribution`. Termini: un'app che usa l'API deve indicare che è «made using Openverse but is not endorsed».
Copertura: [V] 915 milioni di immagini (Flickr 536 M, iNaturalist 266 M, Commons 89 M).

## Flickr
Licenze: [V] Licenze CC 2.0, CC0 e PDM; dal 20/06/2025 anche CC 4.0 (Flickr Foundation). Esiste anche «No known copyright restrictions» (Flickr Commons), che non è una licenza.
Commerciale: [V] Termini API (copia Wayback del 03/10/2026): «If you use Flickr photos for a commercial purpose, the photos must be marked with a Creative Commons license that allows for such use». Un'app il cui scopo principale è generare ricavi è «commercial application» e richiede una chiave commerciale, che 
Attribuzione: [V] Secondo la licenza CC, più l'avviso obbligatorio «This product uses the Flickr API but is not endorsed or certified by SmugMug, Inc.».
Copertura: Non misurata (nessuna chiave).

## NYPL Digital Collections
Licenze: [V] Pubblico dominio come «no known U.S. copyright restrictions»; valutazione limitata alla legge USA.
Commerciale: Per il pubblico dominio sì negli USA. [D] In Italia va controllata la data di morte dell'artista.
Attribuzione: Di cortesia (da snippet).
Copertura: Non misurabile: non c'è API.

## Smithsonian Open Access
Licenze: [V] CC0 per gli asset marcati usage.access='CC0'; anche il repository GitHub dei dati è CC0-1.0.
Commerciale: Sì per gli asset CC0. [R] Vietato suggerire un'approvazione dello Smithsonian (si.edu risponde 403).
Attribuzione: Non richiesta.
Copertura: [V] Per nome scientifico escono quasi solo fogli d'erbario (per esempio Passiflora caerulea: 79 su 79).

## Rawpixel (sezione Public Domain)
Licenze: [V] Pagina licenze (copia Wayback del 31/12/2025): «Our public domain collection is available to everyone with a CC0 license. Free for personal and comercial use with no attribution required» e «it is your responsibility to ensure it is ok to use in your country».
Commerciale: CORRETTO: la clausola «considerable artistic value» per stampe e merchandise sta nella licenza commerciale e nelle regole generali «What you cannot do» sulle «our images» (vietato anche mettere le immagini in una «image gallery … where users are able to access our images»). Non è chiaro se valga per
Attribuzione: Non richiesta per il CC0.
Copertura: Non misurata.

## Plantillustrations.org
Licenze: [V] Pagina About: «All available HD illustrations belong to the public domain according to the European law and may be reused under the Creative Commons License», senza dire quale. Per le fotografie bisogna chiedere all'autore.
Commerciale: Ambiguo: la licenza CC non è specificata. Bisogna risalire alla fonte originale linkata.
Attribuzione: Non chiarita.
Copertura: Non misurata.

RISCHI
- [V] La licenza va controllata su ogni singola foto: su nessuna fonte il filtro o il dominio garantisce la licenza dell'immagine. Su iNaturalist `photo_license` vuol dire «at least one photo with this license» e il dominio inaturalist-open-data contiene anche foto CC BY-NC (foto 338155266). Su GBIF il filtro vale per il record: oggi su Laurus nobilis 42 media su 455 dei record CC BY erano NC o ND. 
- [V] Il credito nell'app c'è («Foto: <autore> / Wikimedia Commons» con link alla pagina del file), ma senza il nome della licenza e senza il suo link. Le licenze CC 2.0, 2.5 e 3.0 chiedono il link alla licenza «with every copy» mostrata: sono 1.884 immagini. Nelle righe degli elenchi (SelettoreSpecie, PiantaRiga) le miniature non hanno alcun credito. Per le CC 4.0 basta un credito «reasonable» (anche un link a un
- [V] Ci sono 24 attribuzioni sbagliate nel DB su immagini CC: 20 accreditate a «Wikimedia Commons» (15 CC BY 4.0, 5 CC BY-SA 3.0) e 4 a «unknown». Esempi: Auckland Museum, Wellcome Collection, Cnicus benedictus. Per CC BY e CC BY-SA citare l'autore è obbligatorio. L'importazione ha ignorato il campo Attribution o l'autore scritto solo nel wikitesto.
- [V] Le immagini sono sbagliate o non presentabili. Rubus almus mostra un Trillium grandiflorum (File:Trilliumgrand.jpg). Ci sono almeno 51 libri djvu/pdf, 37 mappe di distribuzione, 43 campioni di legno e circa 120 fogli d'erbario usati come immagine principale. Il campo `verificata` è false su tutte le 7.722 righe. Per un'app da mostrare a un'agenzia è un danno d'immagine: serve una revisione pri
- [V/D] Share-alike. Il 70% delle immagini (5.404) è CC BY-SA, così come quasi tutto Pl@ntNet. Un ritaglio creativo o un filtro ad acquerello producono «Adapted Material», che va ripubblicato CC BY-SA con l'indicazione delle modifiche. Ridimensionare e convertire il formato invece non lo producono mai (§2(a)(4)), e l'app nel suo insieme non diventa CC BY-SA. Per le rielaborazioni preferire CC0, PD o
- [V] Addestramento di IA. I Termini di iNaturalist (rev. 11/07/2023) vietano di usare i loro dati per addestrare modelli di IA, machine learning o LLM a fini commerciali. Se gli acquerelli venissero generati addestrando o affinando un modello, iNaturalist va escluso dall'insieme di addestramento, anche quando le singole foto sono CC BY.
- [V/D] Il pubblico dominio negli USA non coincide con quello in Italia. BHL, NYPL e Flickr usano la regola «anno - 95», l'Italia vita + 70 dell'artista. Sono sicure solo le tavole di artisti morti entro il 1955; Lilian Snelling (Curtis's Botanical Magazine, morta nel 1972) è un caso a rischio [D]. Le scansioni di beni di enti pubblici italiani restano soggette al d.lgs. 42/2004 per l'uso commercial
- [V] Licenze NC da escludere: la licenza predefinita di iNaturalist (CC BY-NC, 62,4% delle osservazioni research grade di piante), i volumi BHL ancora protetti («almost always» CC BY-NC-SA 4.0) e i media NC dentro record GBIF CC BY. Le ND non si possono rielaborare.
- [V] Le licenze cambiano nel tempo. Su iNaturalist l'utente può cambiare o revocare la licenza dei propri contenuti, e il dominio della foto «may change … if the license changes». I file Commons possono essere cancellati o rietichettati (oggi 100 su 100 risultano invariati). Bisogna conservare per ogni foto licenza, autore, URL e data di verifica e ricontrollare periodicamente.
- [V] Termini delle piattaforme. Flickr: chiave API solo per gli abbonati Pro, chiave commerciale, divieto di conservare le foto, massimo 30 foto per pagina, avviso SmugMug obbligatorio. Openverse: 200 richieste al giorno, scraping vietato, avviso «not endorsed». iNaturalist: circa 1 richiesta al secondo e 10.000 al giorno; oltre 5 GB/ora o 24 GB/giorno di media il blocco può essere permanente. Pl@n
- [V] Copertura delle cultivar. 123.286 cultivar su 196.343 (63%) hanno una madre senza immagine, quindi nessuna foto. 385 righe «Genere spp.» su 477 sono senza immagine (per esempio Tulipa 'Happy Generation', Geranium 'Gerwat'). Nessuna fonte certifica la cultivar, e solo il Pomological ha cultivar in pubblico dominio (frutta storica). Quando una cultivar mostra la foto della madre l'app dovrebbe d
- [V] Identificazione e piante coltivate. Il research grade di iNaturalist esclude le coltivate (Pilea peperomioides: 0 osservazioni research grade commerciali). La tassonomia di iNaturalist accorpa specie diverse (Spiraea × arguta su S. × vanhouttei). La colonna sinonimi_botanici è inaffidabile per cercare tavole: in 32 casi su 63 il «sinonimo» è un'altra specie del catalogo.
- [R/D] Limiti di questa verifica. Le pagine bloccate le ho lette tramite copie Wayback della pagina ufficiale (iNaturalist 11 e 18/09/2026, GBIF 24/07/2026, Flickr 29/09 e 03/10/2026, Rawpixel 31/12/2025): le versioni correnti potrebbero essere diverse. Restano non verificate direttamente le pagine dei termini di Rawpixel e di si.edu e la dichiarazione della NAL sul Pomological (pagina solo JavaScr
