#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Overrides per la naturalizzazione del lotto4 (70 righe blocco RHS).
Applica meccanicamente le traduzioni delle voci alert marcate (regola 8a/8b)
preservando verbatim tutto il resto, e inserisce le descrizioni riscritte a mano."""
import json
import re
from pathlib import Path

RISCHI_NONE_RE = re.compile(
    r"^Rischi segnalati dalla fonte \(testo originale in inglese, non tradotto per non alterarne il significato\): None [Kk]nown\.?$"
)

PARASSITI_MALATTIE_RE = re.compile(
    r'^Da RHS \(testo originale in inglese\) — Parassiti: "(?P<p>.*)"; Malattie: "(?P<m>.*)"$'
)
POTATURA_RE = re.compile(r'^Potatura \(RHS, testo originale in inglese\): "(?P<v>.*)"$')
PROPAGAZIONE_RE = re.compile(r'^Propagazione \(RHS, testo originale in inglese\): "(?P<v>.*)"$')

# id -> {"descrizione": nuova descrizione, "parassiti_malattie": "Parassiti: ...; Malattie: ...",
#        "potatura": "Potatura: ...", "propagazione": "Propagazione: ..."}
# I campi facoltativi vengono usati solo se la riga alert corrispondente esiste nell'originale.
OVERRIDES = {
 "0f090ce2-a602-451c-9346-e1057ef54719": {  # aristolochia-clematitis
  "descrizione": "Aristolochia clematitis è una pianta perenne della famiglia delle Aristolochiaceae, alta fino a 90 cm, con rizomi striscianti e ramificati. Le foglie sono a forma di cuore, verde medio-scuro, portate su fusti prima eretti poi rampicanti. Fiorisce da fine primavera a metà estate, con fiori stretti e tubolari, giallo pallido o bruno-giallastro, dal labbro superiore appuntito e ricurvo.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: può essere soggetta ad armillaria (fungo del miele) nei giardini dove è presente, ma non ci sono dati sufficienti per determinare il grado di suscettibilità",
  "potatura": "Potatura: gruppo di potatura 12; potare dopo la fioritura",
  "propagazione": "Propagazione: per seme in primavera, per divisione in estate o per talea di radice in inverno",
 },
 "55afd27b-8a2b-4aa4-b4b5-48f77fa23eba": {  # polypodium-vulgare
  "descrizione": "Polypodium vulgare è una felce sempreverde, terrestre o epifita, della famiglia delle Polypodiaceae, alta fino a 30 cm, dal portamento variabile (irregolare o prostrato, tondeggiante, oppure eretto). Ha rizomi striscianti e ramificati e fronde coriacee, da lanceolate a oblunghe, pennate o profondamente pennatifide, verde scuro, che lasciano una cicatrice quando cadono. È adatta anche alla coltivazione in cestelli pensili. Esistono varietà con pinne crestate e crespe, come 'Bifido Multifidum'.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti all'aperto; Malattie: generalmente esente da malattie all'aperto",
  "potatura": "Potatura: le fronde morte o danneggiate possono essere rimosse quando necessario",
  "propagazione": "Propagazione: per divisione in primavera o a inizio estate; le spore si seminano a 15-16°C quando mature",
 },
 "e645646c-0630-4958-ad71-15bf32e71268": {  # quercus-durata (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Quercus, della famiglia delle Fagaceae, alberi o arbusti decidui o sempreverdi, con foglie intere, lobate o dentate; i fiori sono poco vistosi, seguiti dalle caratteristiche ghiande, e talvolta il fogliame assume una bella colorazione autunnale.",
 },
 "fb402863-2da2-46db-98f2-08d879e29dff": {  # gunnera-tinctoria (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Gunnera, della famiglia delle Gunneraceae, perenni rizomatose sempreverdi o erbacee, che vanno da piccole piante striscianti a esemplari molto grandi con foglie enormi. I fiori sono piccoli, portati in pannocchie o spighe strette, talvolta seguiti da piccoli frutti simili a bacche.",
  "parassiti_malattie": "Parassiti: vedi note di coltivazione; Malattie: vedi note di coltivazione",
  "propagazione": "Propagazione: vedi note di coltivazione",
 },
 "136d3eec-bf07-420f-acc1-77deeb3cef14": {  # rhododendron-japonicum (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Rhododendron, della famiglia delle Ericaceae, arbusti o alberi sempreverdi o decidui, con foglie semplici, a volte con un fitto indumento peloso e colorato nella pagina inferiore, e fiori a imbuto, a campana o tubolari, solitari o in brevi racemi.",
 },
 "752eaf34-a4bd-4581-879e-0926bad4da5d": {  # ranunculus-ternatus (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Ranunculus, della famiglia delle Ranunculaceae, piante annuali, biennali o perenni sempreverdi o erbacee, con rizomi, tuberi o stoloni striscianti. Le foglie sono variabili, spesso lobate o incise palmate, e i fiori solitamente a coppa.",
 },
 "44d70ef5-4b38-4d39-aaa8-61061350b0b7": {  # dianella-caerulea (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Dianella, della famiglia delle Phormiaceae, perenni rizomatose sempreverdi con foglie coriacee a forma di spada e pannocchie di piccoli fiori blu scuro a stella, seguiti da bacche blu o viola di lunga durata.",
 },
 "ea347aaa-b3fc-4930-955a-d854771d5a8b": {  # prunus-pseudocerasus (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Prunus, della famiglia delle Rosaceae, alberi o arbusti decidui o sempreverdi con fioriture vistose in primavera, spesso con un bel colore autunnale del fogliame. Alcune specie hanno frutti commestibili in autunno, e poche hanno una corteccia ornamentale.",
 },
 "c6cf90a3-5c19-422a-886b-3652c146d713": {  # malus-transitoria
  "descrizione": "Malus transitoria è un albero deciduo di piccole dimensioni e portamento aggraziato, della famiglia delle Rosaceae, con foglie ovali, profondamente lobate, che in autunno virano al giallo. Produce abbondanti fiori bianchi semplici, seguiti da minuscoli frutti globosi gialli, lunghi 9 mm.",
  "parassiti_malattie": "Parassiti: può essere soggetto ad afidi, inclusi l'afide lanigero e l'afide rosato del melo, al ragnetto rosso dei fruttiferi, alla carpocapsa e ad altri bruchi; Malattie: può essere soggetto a cancro del melo, ticchiolatura, avvizzimento dei fiori, marciume bruno, colpo di fuoco batterico, armillaria (fungo del miele) e oidio",
  "potatura": "Potatura: gruppo di potatura 1",
  "propagazione": "Propagazione: per seme, seminato in semenzaio in autunno, oppure per innesto a occhio (chip budding) a fine estate; l'innesto può essere eseguito in pieno inverno",
 },
 "02ee2401-4550-42b0-85fd-7de30ed1d4b9": {  # eucalyptus-viminalis (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Eucalyptus, della famiglia delle Myrtaceae, alberi o grandi arbusti sempreverdi, spesso a crescita rapida, alcuni con corteccia decorativa, la maggior parte con fogliame aromatico, e gruppi di piccoli fiori bianchi, gialli o rossi.",
  "parassiti_malattie": "Parassiti: può essere soggetto alla vespa galligena dell'eucalipto e allo psillide dell'eucalipto; Malattie: può essere soggetto a mal del piombo (silver leaf) e a edema",
  "potatura": "Potatura: gruppo di potatura 1, oppure gruppo di potatura 7 per la migliore resa del fogliame giovanile",
  "propagazione": "Propagazione: per seme a 13-18°C in primavera ed estate",
 },
 "2af9346b-088f-480e-b75d-fc750ccbc13b": {  # daphne-laureola
  "descrizione": "Daphne laureola è un arbusto cespuglioso sempreverde della famiglia delle Thymelaeaceae, alto fino a 1,2 m, con foglie persistenti, verde scuro e lucide. Fiorisce a fine inverno con fiori verde-giallastri, profumati di sera, nascosti tra il fogliame; seguono frutti neri. Predilige posizioni umide e ombreggiate.",
  "parassiti_malattie": "Parassiti: può essere soggetta ad afidi; Malattie: può essere soggetta ad armillaria (fungo del miele, raramente), marciume radicale da Phytophthora, maculatura fogliare fungina e virosi",
  "potatura": "Potatura: gruppo di potatura 1, o gruppo di potatura 8 se necessario; è meglio ridurla al minimo",
  "propagazione": "Propagazione: per seme in contenitori in una cassa fredda non appena maturo; per talea erbacea da primavera a inizio estate e semilegnosa in estate; per propaggine da tarda primavera a inizio estate",
 },
 "8f3d10c4-a31a-45c2-adde-1c2ae811f6df": {  # clematis-chinensis (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Clematis, della famiglia delle Ranunculaceae, arbusti decidui o sempreverdi oppure perenni erbacee, per lo più rampicanti tramite piccioli fogliari attorcigliati, spesso con fiori vistosi; alcune specie hanno in autunno infruttescenze piumose decorative.",
 },
 "fcc9f3bf-5777-476e-990d-2f8ad4b5572b": {  # brahea-edulis
  "descrizione": "Brahea edulis è una palma a crescita lenta, a fusto singolo, della famiglia delle Arecaceae, che può raggiungere i 12 m di altezza. Le foglie sono grandi, pieghettate, a ventaglio, verde medio, che con il tempo si incurvano verso il basso; il tronco è grigio-bruno, più spesso alla base e rastremato verso l'alto. Fiorisce da inizio a fine estate, con fiori bianco-crema portati su pannocchie ramificate sugli esemplari maturi, seguiti da frutti commestibili verde-bruno.",
  "parassiti_malattie": "Parassiti: può essere soggetta al ragnetto rosso da serra e a cocciniglie; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: non richiede potatura; si possono rimuovere le foglie (fronde) più basse e appassite per migliorare l'aspetto e lasciare il tronco libero",
  "propagazione": "Propagazione: per seme",
 },
 "a32eb78e-53a1-47b4-8f6b-d28b3e498f67": {  # rubus-occidentalis (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Rubus, della famiglia delle Rosaceae, arbusti decidui o sempreverdi, spesso rampicanti con fusti ispidi o spinosi, foglie semplici, lobate, palmate o pennate e fiori a 5 petali, seguiti da frutti succosi, talvolta commestibili.",
 },
 "d514ede7-5d3a-4ed4-80d7-12c584f115f7": {  # brugmansia
  "descrizione": "Brugmansia (sin. Datura) è un genere originario dell'America centrale e meridionale, che comprende grandi arbusti sempreverdi arborei e arbustivi, con foglie semplici e ovali. Queste specie sono simili a quelle di Datura, genere a cui in passato erano ascritte e che oggi include le forme più erbacee. Si tratta di piante velenose dalle grandi foglie, con fiori profumati, imbutiformi o tubolari, solitari e penduli, di colore bianco, giallo o arancione. Gli incroci sono comuni.\n\nB. sanguinea (sin. Datura sanguinea), alta 1-1,5 m, ha una chioma folta, composta di foglie ovali, pubescenti, e fiorisce tutto l'anno, soprattutto in inverno, con fiori inodori, lunghi 20 cm, di colore rosso-aranciato.\n\nB. suaveolens (sin. Datura suaveolens) è un arbusto delicato, alto fino a 5 m, con foglie ovato-oblunghe, semi-sempreverdi, lunghe 15-30 cm, leggermente pubescenti sulla pagina inferiore. Fiorisce in estate e in autunno, con grandi fiori penduli, bianchi, imbutiformi, profumati di notte, lunghi 25-30 cm, con corolla stellata; 'Plena' ha fiori doppi bianchi, 'Rosa' ha fiori rosa.",
  "parassiti_malattie": "Parassiti: può essere soggetta al ragnetto rosso da serra, alla mosca bianca da serra, ai tripidi e alle cocciniglie farinose se coltivata sotto vetro; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: gruppo di potatura 9; può essere potata drasticamente quando portata in casa in autunno",
  "propagazione": "Propagazione: per seme o per talea semilegnosa o erbacea",
 },
 "b19c95d9-10f2-4717-b13f-31ad7f7adf52": {  # medicago-arborea (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Medicago, della famiglia delle Fabaceae, piante annuali, perenni o piccoli arbusti. Le foglie sono composte da tre foglioline, di colore che va dal verde chiaro al verde-giallastro o verde-blu; brevi infiorescenze di fiori papilionacei, simili a quelli dei piselli, attirano api e farfalle.",
 },
 "9325f30f-4add-46d6-8aca-52bdbdee7182": {  # indigofera-hebepetala (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Indigofera, della famiglia delle Fabaceae, alberi o arbusti decidui o sempreverdi, perenni erbacee o annuali, con foglie pennate e spighe o racemi di piccoli fiori papilionacei in estate o autunno.",
 },
 "628c5cf0-95fa-4fbb-93f1-4788178e7f97": {  # lonicera-quinquelocularis
  "descrizione": "Lonicera quinquelocularis è un grande arbusto o piccolo albero della famiglia delle Caprifoliaceae, alto fino a 5 m, con fusti violacei molto pelosi e foglie ovali verdi, anch'esse pelose. A inizio estate produce abbondanti gruppi di fiori bilabiati color crema, che con il tempo virano al giallo dorato, seguiti da insolite bacche bianche traslucide, di forma tondeggiante o ovale.",
  "parassiti_malattie": "Parassiti: può essere soggetta ad afidi; Malattie: può essere soggetta a oidio",
  "potatura": "Potatura: gruppo di potatura 2",
  "propagazione": "Propagazione: per talea legnosa, erbacea o semilegnosa in qualsiasi periodo dell'anno, oppure per seme",
 },
 "32d5ac9d-f80f-4b66-876a-ca4ab50940e9": {  # camellia-reticulata (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Camellia, della famiglia delle Theaceae, arbusti sempreverdi con foglie semplici, ovali, lucide e coriacee, e vistosi fiori solitari o riuniti in gruppi, che sbocciano nei primi mesi dell'anno.",
 },
 "e4fa5866-0648-461d-b625-2afe00faa903": {  # lycoris-sanguinea (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Lycoris, della famiglia delle Amaryllidaceae, perenni bulbose che producono vistose ombrelle di fiori a imbuto su steli privi di foglie, dalla primavera all'autunno; le foglie possono essere lineari o a forma di nastro.",
 },
 "694ec598-71d6-4915-870a-b1e005a76f00": {  # eryngium-campestre (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Eryngium, della famiglia delle Apiaceae, piante annuali, biennali o perenni, con foglie semplici o divise, spesso con margine spinoso, e infiorescenze coniche spesso circondate da un involucro di vistose brattee spinose.",
 },
 "7048af43-b98b-4336-b946-1eb82fbfc17c": {  # rhodiola-rhodantha (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Rhodiola, della famiglia delle Crassulaceae, perenni da fiore, coltivate principalmente come tappezzanti, con fusti alti e carnosi e fiori verde-giallastri, a volte sfumati di rosso.",
 },
 "5c170533-75bb-4962-bb81-a54f94de4f42": {  # cornus-australis (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Cornus, della famiglia delle Cornaceae, arbusti o alberi decidui, oppure perenni striscianti a base legnosa, alcuni con fusti giovani dai colori vivaci. I fiori, minuscoli, sono riuniti in dense infiorescenze, a volte con vistose brattee; molte specie hanno una bella colorazione autunnale.",
 },
 "0a901f18-e3db-4507-9303-5215afb1fc35": {  # trillium-erectum
  "descrizione": "Trillium erectum è una perenne eretta della famiglia delle Trilliaceae, alta fino a 50 cm, con fusti eretti che portano ciascuno un verticillo di tre foglie ampiamente ovali. Fiorisce in tarda primavera con un unico fiore terminale, chinato, largo 5-9 cm, di colore porpora scuro, occasionalmente bianco.",
  "parassiti_malattie": "Parassiti: può essere soggetta a lumache e chiocciole; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: non richiede potatura",
  "propagazione": "Propagazione: per seme in vaso, in una cassa fredda ombreggiata, non appena il seme è maturo; richiede 5-7 anni per raggiungere le dimensioni da fioritura. I rizomi si propagano per divisione dopo la fioritura, oppure asportando l'apice vegetativo del rizoma dopo la fioritura, il che ne stimola la formazione",
 },
 "e90f9312-562d-45f9-bedf-4c2265f59584": {  # avena-sativa
  "descrizione": "Avena sativa (avena comune) è una graminacea annuale della famiglia delle Poaceae, coltivata principalmente come cereale o per sovescio. Ha portamento eretto e cespuglioso, con fusti sottili che portano pannocchie rade e aperte di chicchi d'avena, e raggiunge tipicamente un'altezza tra 60 cm e 1,5 m. Le foglie, verdi o verde-bluastre, sono strette, lineari, simili a quelle dell'erba, lunghe circa 20-40 cm e larghe fino a 1,5 cm, con una tessitura leggermente ruvida. Produce piccoli fiori verde pallido o dorati, riuniti in pannocchie rade e chinate, che compaiono da fine primavera a inizio estate (maggio-luglio) e sviluppano i caratteristici chicchi d'avena. A fine stagione la pianta ingiallisce prima di seccare.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti in un contesto informale non agricolo, ma può essere soggetta ad afidi, elateridi (larve filiformi) e crisomelidi dei cereali; Malattie: generalmente esente da malattie in un contesto informale non agricolo",
  "potatura": "Potatura: si rimanda alle indicazioni generali per la cimatura delle graminacee decidue",
  "propagazione": "Propagazione: per semina diretta all'aperto",
 },
 "30f1bca0-ac86-46f8-b614-28cb44904671": {  # mentha-diemenica (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Mentha, della famiglia delle Lamiaceae, perenni rizomatose e aromatiche, con foglie opposte e dentate e piccoli fiori tubolari riuniti in spighe di verticilli in estate.",
 },
 "231d1165-4949-495b-87be-5e6ff2ed27bb": {  # adenophora-liliifolia
  "descrizione": "Adenophora liliifolia, dal portamento eretto, fiorisce a inizio e metà estate con fiori blu. Non sono disponibili altri dati specifici per la specie: si riportano i tratti generali del genere Adenophora, della famiglia delle Campanulaceae, perenni decidue strettamente imparentate con le campanule, con fiori simili a campana o a imbuto, di colore blu-violaceo, riuniti in grandi pannocchie o racemi terminali in estate, sopra foglie basali arrotondate.",
 },
 "bed32927-4a68-430e-b97b-8580bc16ef3b": {  # thymus-praecox
  "descrizione": "Thymus praecox è una perenne sempreverde, bassa e strisciante, originaria d'Europa, della famiglia delle Lamiaceae, dal portamento tondeggiante. Forma un fitto tappeto di fogliame aromatico verde medio-scuro. Fiorisce da metà primavera fino all'estate, con gruppi di piccoli fiori tubolari rosa-porpora.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: cimare dopo la fioritura per mantenere la compattezza",
  "propagazione": "Propagazione: per divisione e per talea semilegnosa",
 },
 "37396d39-0029-4f42-8eb0-9428ae681cdd": {  # iris-japonica
  "descrizione": "Iris japonica è una perenne rizomatosa della famiglia delle Iridaceae, che forma ventagli di fogliame sempreverde lucido. I fusti ramificati, alti fino a 45 cm, portano fiori bianchi o blu pallido, larghi 4-5 cm, con i petali inferiori sfrangiati, punteggiati di porpora scuro e con creste arancioni.",
  "parassiti_malattie": "Parassiti: può essere soggetta a lumache, chiocciole e tripidi; Malattie: può essere soggetta a virosi trasmesse da afidi, marciume molle batterico e muffe grigie; vedi le malattie degli iris",
  "potatura": "Potatura: rimuovere il fogliame secco in autunno; i vecchi steli fiorali possono essere tagliati dopo la fioritura",
  "propagazione": "Propagazione: per seme in vaso, in cassa fredda, in autunno o primavera; per divisione dei rizomi da metà estate a inizio autunno",
 },
 "f442ee35-a9ca-4ba4-8ec5-06034f65f3f5": {  # kadsura-coccinea
  "descrizione": "Kadsura coccinea è un rampicante sempreverde a portamento volubile, della famiglia delle Schisandraceae, con foglie ovali, appuntite, verde medio. I fiori maschili e femminili si trovano su piante separate e possono essere bianchi, rossi, verde pallido o di colori combinati, con un vistoso disco centrale formato da stami o stili molto corti. Sulle piante femminili fecondate si sviluppa un frutto commestibile rosso, largo fino a 10 cm, composto da numerosi segmenti a cuneo.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: gruppo di potatura 12, in inverno",
  "propagazione": "Propagazione: per seme, oppure per talea semilegnosa in estate",
 },
 "aa374dba-efd4-438c-9701-47f5f334f087": {  # cyperus-textilis (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Cyperus, della famiglia delle Cyperaceae, piante annuali oppure perenni rizomatose sempreverdi, con foglie lineari simili a quelle dell'erba e gruppi terminali di piccole spighe fiorali verdastre, circondate da brattee simili a foglie.",
 },
 "444c4d05-bd63-4297-8ce7-4cb475f9ab77": {  # tamarix-gallica
  "descrizione": "Tamarix gallica è un grande arbusto deciduo espanso, o piccolo albero, della famiglia delle Tamaricaceae, alto circa 4 m, con germogli giovani bruno-porpora scuro rivestiti di piccole foglie squamiformi verde-azzurro. I fiori, a forma di stella, bianco-rosati, sono riuniti in gruppi cilindrici sui germogli della stagione in corso.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: può essere soggetta ad armillaria (fungo del miele, raramente)",
  "potatura": "Potatura: gruppo di potatura 6",
  "propagazione": "Propagazione: per talea semilegnosa in estate o legnosa in inverno; per seme, seminato non appena maturo, in contenitori in una cassa fredda",
 },
 "c00eb8ed-3dd1-4493-93ae-fbd2b279cfef": {  # osmunda-japonica
  "descrizione": "Osmunda japonica è una felce decidua della famiglia delle Osmundaceae, con rizoma eretto, ascendente o brevemente strisciante. Produce un ciuffo di fronde verdi, alte fino a 150 cm e larghe 50 cm. Le fronde fertili, portatrici di spore, sono più erette e di tonalità bronzea.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: rimuovere le fronde morenti se necessario",
  "propagazione": "Propagazione: per divisione o per spore",
 },
 "12c38831-57ce-46ee-bd6b-33a0788a9dec": {  # ribes-lacustre (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Ribes, della famiglia delle Grossulariaceae, arbusti decidui o sempreverdi, a volte spinosi, con foglie semplici, per lo più lobate palmate, e piccoli fiori tubolari o a campana, solitari o in racemi, portati in primavera o estate, seguiti da bacche succose, talvolta commestibili.",
 },
 "eb2047ed-34dc-4fdf-afa3-3cd0388e2ae0": {  # cyrtomium-fortunei
  "descrizione": "Cyrtomium fortunei è una felce sempreverde della famiglia delle Dryopteridaceae, che forma ciuffi eretti a 'volano' di fronde pennate, alte fino a 1,2 m, composte da circa 20 paia di foglioline strette, falciformi, verde opaco.",
  "potatura": "Potatura: non richiede potatura, ma le fronde danneggiate dal gelo possono essere rimosse in primavera",
  "propagazione": "Propagazione: per spore, seminate a 16°C a fine estate",
 },
 "e730124e-b3b6-425b-9ac7-a028342ad268": {  # satureja-hortensis
  "descrizione": "Satureja hortensis (santoreggia) è una pianta annuale cespugliosa della famiglia delle Lamiaceae, alta fino a 25 cm, con foglie strette, lanceolate, aromatiche, lunghe 3 cm. In estate produce spighe con verticilli di fino a cinque fiori bianchi.",
  "potatura": "Potatura: non richiede potatura",
  "propagazione": "Propagazione: per seme in primavera",
 },
 "ed019625-d98a-40d5-9994-79dfbb90ed7c": {  # urtica-pilulifera (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Urtica, della famiglia delle Urticaceae, piante annuali o perenni con foglie verdi seghettate a forma di freccia e piccoli gruppi di fiori verde-brunastri. Molte specie hanno peli urticanti sulle foglie. Il fogliame può essere usato per tisane e per scopi medicinali, e le piante offrono cibo e rifugio prezioso alla fauna selvatica.",
 },
 "f31f8375-052d-4acb-869d-9ebce6a9a6c0": {  # acacia-auriculiformis
  "descrizione": "Acacia auriculiformis è una pianta della famiglia delle Fabaceae, utile in agroforestazione, con usi alimentari minori. Può raggiungere i 20 m di altezza, con una chioma fitta e tondeggiante; il tronco è contorto e nodoso, adatto a fare ombra, con corteccia ruvida e dura, grigio-verdastra, dal diametro di 50 cm. Le foglie, falciformi, lucide, verde scuro, lunghe 10-20 cm e larghe 1,5-3,5 cm, si assottigliano fino a una punta smussata e mostrano tre nervature principali prominenti. Fiorisce a inizio, metà e fine primavera, con fiori a bastoncino, giallo-dorato opaco, prodotti in coppie. I baccelli sono caratteristici, a forma di orecchio, legnosi, contorti e duri. Le radici sono superficiali ed espanse.\n\nIl genere Acacia comprende circa 1.350 specie, di cui oltre 1.000 presenti in Australia, tra alberi, arbusti o rampicanti decidui o sempreverdi, con foglie alterne pennate oppure ridotte a piccioli fogliari appiattiti (fillodi), e minuscoli fiori, talvolta profumati, riuniti in brevi spighe, racemi o capolini sferici. A. auriculiformis può diventare invasiva in condizioni favorevoli e fissa l'azoto atmosferico associandosi a diversi ceppi di Rhizobium e Bradyrhizobium, oltre a instaurare associazioni con funghi micorrizici sia ecto- che endomicorrizici.",
 },
 "5ef13176-f95f-4048-a571-3a2c5a97e50d": {  # euonymus-latifolius
  "descrizione": "Euonymus latifolius è un arbusto deciduo dal portamento tondeggiante, della famiglia delle Celastraceae. Le foglie, verde scuro, sono ampiamente ovali e in autunno virano all'arancio-rosso. I piccoli fiori verde pallido sono seguiti da frutti rosa-rossi brillanti, che si aprono rivelando semi arancioni.",
  "parassiti_malattie": "Parassiti: può essere soggetto all'otiorrinco, alla cocciniglia dell'ippocastano, alla cocciniglia dell'evonimo e a bruchi; Malattie: può essere soggetto a oidio, a una maculatura fogliare e talvolta ad armillaria (fungo del miele)",
  "potatura": "Potatura: gruppo di potatura 1",
  "propagazione": "Propagazione: per seme o per talea semilegnosa",
 },
 "2ac69ed2-037b-4b78-a756-bc2319c1334a": {  # delphinium-cashmerianum (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Delphinium, della famiglia delle Ranunculaceae, piante annuali, biennali o perenni, con foglie basali lobate palmate e vistosi fiori a coppa riuniti in spighe, racemi o pannocchie.",
 },
 "31d045ab-47bb-45d7-9ad1-6306451e38af": {  # pinus-pungens (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Pinus, della famiglia delle Pinaceae, arbusti o grandi alberi sempreverdi, alcune specie con corteccia decorativa, che con l'età sviluppano una forma irregolare e portano lunghe foglie aghiformi riunite in fascetti di 2, 3 o 5; le pigne vistose possono cadere o restare sulla pianta per anni.",
 },
 "cbf915b2-7abb-4b1f-abb4-6ec7cd1968d4": {  # ribes-petraeum
  "descrizione": "Ribes petraeum è un arbusto deciduo della famiglia delle Grossulariaceae, che raggiunge circa 1,8 m di altezza, con fogliame verde. In primavera produce gruppi di graziosi fiori rossi, seguiti da bacche rosse lucide, dal sapore acidulo ma adatte per marmellate e conserve; i frutti contengono una notevole quantità di semi.",
  "parassiti_malattie": "Parassiti: può essere soggetto ad afidi, alla tentredine dell'uva spina, al moscerino Drosophila suzukii e alla cocciniglia del ribes; Malattie: può essere soggetto a oidio americano dell'uva spina, muffe grigie e corallo (Nectria)",
  "potatura": "Potatura: potare due volte l'anno, in estate e in inverno",
  "propagazione": "Propagazione: per talea legnosa, prelevata da piante giovani per evitare malattie",
 },
 "d1fbb1c0-de70-4340-816e-abf38dee973e": {  # rumex-bucephalophorus (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Rumex, della famiglia delle Polygonaceae, annuali, biennali o perenni con foglie perlopiù basali e semplici, e pannocchie o racemi eretti di piccoli fiori verdastri o rossastri, seguiti da frutti triangolari bruno-rossastri.",
 },
 "13782c17-7ef7-40b7-b206-f710a4d866f9": {  # coptis-japonica (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Coptis, della famiglia delle Ranunculaceae, perenni basse che si sviluppano da rizomi striscianti. I piccoli fiori sono bianchi o verde-giallastri, e il fogliame sempreverde è diviso in due-cinque foglioline.",
 },
 "a1a885dc-256b-4e21-8eb3-0a74750c52bd": {  # lactuca-canadensis (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Lactuca, della famiglia delle Asteraceae, piante annuali, biennali, perenni o arbustive, con foglie alterne, linfa bianca lattiginosa e fiori simili a margherite, bianchi, gialli o blu. Il genere comprende un'ampia gamma di piante spontanee, oltre a specie coltivate per le foglie commestibili (lattuga).",
 },
 "896e325d-d143-40c6-b2fa-b9de61a4d113": {  # campanula-portenschlagiana
  "descrizione": "Campanula portenschlagiana è una perenne bassa della famiglia delle Campanulaceae, che forma rapidamente un cuscino sempreverde alto fino a 15 cm, di piccole foglie ampiamente cuoriformi, verde medio. In estate produce fiori tubolari o a imbuto, blu-violacei, lunghi 2 cm, portati su fusti radi e ramificati.",
  "parassiti_malattie": "Parassiti: può essere soggetta a lumache e chiocciole; Malattie: può essere soggetta a ruggine, oidio e a una maculatura fogliare",
  "potatura": "Potatura: non richiede potatura; i fiori e gli steli sfioriti possono essere rimossi per pulizia",
  "propagazione": "Propagazione: per seme, oppure per talea basale in primavera",
 },
 "cf76942f-771f-434c-990f-19e6bc7e45b0": {  # rubus-parviflorus
  "descrizione": "Rubus parviflorus è un arbusto deciduo che forma fitti cespugli, della famiglia delle Rosaceae, con foglie palmate, lobate, verde medio. I fusti biennali producono grandi fiori bianchi in primavera ed estate, seguiti da piccoli frutti rossi commestibili, simili ai lamponi.",
  "parassiti_malattie": "Parassiti: può essere soggetto ad afidi; Malattie: può essere soggetto a muffe grigie, maculatura dei fusti del lampone, a una maculatura fogliare fungina, al cancro dei fusti del lampone o a virosi",
  "potatura": "Potatura: tagliare a livello del suolo i fusti che hanno fruttificato, subito dopo la raccolta; diradare i fusti per evitare il sovraffollamento",
  "propagazione": "Propagazione: prelevare i polloni sani che compaiono tra le file e ripiantarli altrove; si possono anche dividere i cespi grandi durante il riposo vegetativo",
 },
 "a9e19068-899f-46f1-83cf-2cec99bfa472": {  # ribes-maximowiczii (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Ribes, della famiglia delle Grossulariaceae, arbusti decidui o sempreverdi, a volte spinosi, con foglie semplici, per lo più lobate palmate, e piccoli fiori tubolari o a campana, solitari o in racemi, portati in primavera o estate, seguiti da bacche succose, talvolta commestibili.",
 },
 "79e8b0e3-724b-4923-b15a-c35b9346675d": {  # salvia-microphylla
  "descrizione": "Salvia microphylla è un arbusto sempreverde della famiglia delle Lamiaceae, con foglie ovali, verde chiaro, aromatiche. Fiorisce da fine estate ad autunno, con fiori rosso intenso riuniti in racemi terminali.",
  "parassiti_malattie": "Parassiti: può essere soggetta a lumache, chiocciole, cimici fitofaghe, cicaline e al coleottero del rosmarino; Malattie: può essere soggetta ad armillaria (fungo del miele, raramente), oidio, verticillosi e marciumi del colletto e delle radici",
  "potatura": "Potatura: gruppo di potatura 9; eliminare i fiori sfioriti per prolungare la fioritura",
  "propagazione": "Propagazione: per talea basale o erbacea in primavera o inizio estate, oppure per talea semilegnosa a fine estate o autunno con calore di fondo",
 },
 "02fa1bdf-8ed5-4cbb-bfd7-75f96fcee769": {  # podocarpus-salignus
  "descrizione": "Podocarpus salignus è una conifera sempreverde della famiglia delle Podocarpaceae, che forma un albero di medie dimensioni, dalla crescita cespugliosa ed eretta. I rami, arcuati o ricadenti, sono fittamente ricoperti da foglie scure e lucide, simili a quelle del salice, lunghe fino a 15 cm.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: non richiede potatura",
  "propagazione": "Propagazione: per seme o per talea semilegnosa",
 },
 "a69cd3d6-8b76-4730-9be7-9abc8b94a410": {  # pelargonium-bowkeri (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Pelargonium, della famiglia delle Geraniaceae, perenni, sub-arbusti o arbusti, a volte succulenti e per lo più sempreverdi, con foglie palmate lobate o pennate e gruppi di fiori leggermente irregolari, a 5 petali.",
 },
 "5c38c455-e59e-429f-a208-3109e328a8db": {  # convolvulus-tricolor
  "descrizione": "Convolvulus tricolor è una pianta annuale o perenne di breve durata, cespugliosa e prostrata, dal portamento irregolare e altezza variabile, della famiglia delle Convolvulaceae, con foglie ovali verde scuro. Fiorisce a metà e fine estate e a inizio autunno, con fiori blu intenso a imbuto, larghi fino a 4 cm, sfumati di bianco piumato verso la base dei petali, con un occhio giallo al centro; ogni fiore dura un solo giorno, ma vengono prodotti in successione per un lungo periodo.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: armillaria (fungo del miele, raramente)",
  "potatura": "Potatura: eliminare i fiori appassiti per prolungare la fioritura",
  "propagazione": "Propagazione: per seme, per talea erbacea radicata a fine estate, oppure per divisione in primavera",
 },
 "888b1b5c-d6a0-48f2-bf07-36fa458c18a0": {  # primula-auricula (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Primula, della famiglia delle Primulaceae, perenni erbacee o semi-sempreverdi, che formano una rosetta basale di foglie semplici, con fiori a salvietta o a campana, solitari oppure riuniti in ombrella o in verticilli su uno stelo eretto.",
 },
 "3a95efb7-1be2-4515-9df0-4bc13783876c": {  # galeopsis-bifida (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Galeopsis, piante erbacee annuali velenose della famiglia delle Lamiaceae, con foglie simili all'ortica e fiori tubolari, porpora, rosa o gialli, in estate e autunno. Si trovano in aree boschive ombreggiate, campi e terreni incolti, e offrono una preziosa fonte di nettare per gli insetti e di semi per gli uccelli.",
 },
 "f3279bbc-f353-4f0a-b1ac-49097c1d80c8": {  # smilax-sieboldii (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Smilax, un ampio genere di circa 300-350 specie di arbusti sempreverdi e decidui, diffuse nelle regioni tropicali e subtropicali del mondo. Formano fitti cespugli di fusti spinosi, con fogliame verde a forma di cuore e fiori bianco-verdastri che compaiono a maggio e giugno. Le piante impollinate producono bacche tonde, blu-rosse brillanti, che maturano in autunno.",
 },
 "9bc09203-76a9-4a53-aaff-6f561d90a8c6": {  # photinia-villosa
  "descrizione": "Photinia villosa è un piccolo albero deciduo o grande arbusto della famiglia delle Rosaceae, alto fino a 5 m, con germogli giovani lanuginosi e foglie ovali, lunghe fino a 8 cm, dal margine finemente dentato. Le foglie sono bronzee da giovani, maturano al verde scuro e in autunno virano all'arancio e al rosso brillante. A fine primavera produce corimbi di piccoli fiori bianchi, seguiti da bacche ovali, rosso brillante.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: può essere soggetta a colpo di fuoco batterico, a una maculatura fogliare, ad armillaria (fungo del miele) e a oidio",
  "potatura": "Potatura: gruppo di potatura 1",
  "propagazione": "Propagazione: per talea semilegnosa in estate, oppure per seme, seminato in contenitori, in una cassa fredda in autunno",
 },
 "e326d167-f414-4c7e-ad96-30e4be8ca4a4": {  # malus-lancifolia (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Malus, della famiglia delle Rosaceae, alberi decidui di piccole o medie dimensioni, con fioriture vistose in primavera e frutti ornamentali o commestibili in autunno; alcune specie hanno una buona colorazione autunnale del fogliame.",
 },
 "7754fbe1-3a20-4eef-9cf6-0a2c8e4f03d1": {  # alangium-platanifolium
  "descrizione": "Alangium platanifolium è un grande arbusto deciduo, o piccolo albero, della famiglia delle Alangiaceae, coltivato anche per il fogliame decorativo. Le foglie sono variabili, lunghe fino a 20 cm, di solito con tre o cinque lobi. Fiorisce da tarda primavera a metà estate, con piccoli fiori profumati, a forma di nappa, bianchi e gialli; in autunno le foglie virano al giallo, in contrasto con le bacche blu scuro.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: gruppo di potatura 1",
  "propagazione": "Propagazione: per seme o per talea semilegnosa",
 },
 "b386e7f1-e5cd-4ec7-b16b-dafd6088ed5f": {  # chenopodium-berlandieri (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Chenopodium, della famiglia delle Chenopodiaceae, piante annuali o perenni, spesso con fusti e fogliame farinosi, foglie semplici o lobate e minuscoli fiori riuniti in gruppi terminali o ascellari, in alcune specie seguiti da frutti colorati.",
 },
 "150b5051-e129-4a76-90e6-19d2dd108237": {  # anemonella-thalictroides
  "descrizione": "Anemonella thalictroides è una perenne eretta della famiglia delle Ranunculaceae, che forma un cespo espanso, alto fino a 10 cm, con foglie divise, verde-azzurre. Fiorisce a metà e fine primavera e a inizio estate, con fiori larghi 2 cm, simili a quelli dell'anemone, bianchi o rosa.",
  "parassiti_malattie": "Parassiti: può essere soggetta a lumache; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: non richiede potatura",
  "propagazione": "Propagazione: per seme in contenitori, in cassa fredda, non appena maturo; dividere le piante giovani a inizio primavera",
 },
 "4d6c69d7-8457-47f0-8960-5ee72aacd6c1": {  # allium-orientale (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Allium, della famiglia delle Alliaceae, perenni bulbose dal forte odore di cipolla o aglio, con foglie basali lineari, a nastro o cilindriche, e fiori a stella o a campana riuniti in ombrella su uno stelo privo di foglie.",
 },
 "1d782d5d-60a6-4789-aed6-1be2862747c6": {  # farfugium-japonicum
  "descrizione": "Farfugium japonicum è una perenne cespitosa sempreverde, leggermente delicata, della famiglia delle Asteraceae, alta fino a 60 cm, dal portamento eretto, con grandi foglie leggermente carnose, verde intenso e lucido, a forma di rene. Fiorisce da fine estate a inizio autunno, con una fioritura che secondo altre fonti prosegue fino a tarda autunno e inizio inverno: i fiori, gialli e vistosi, simili a margherite, larghi 4 cm, sono riuniti in gruppi ramificati.",
  "parassiti_malattie": "Parassiti: può essere soggetta a lumache e chiocciole; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: non richiede potatura",
  "propagazione": "Propagazione: per seme in contenitori, in cassa fredda, in inverno o primavera, oppure per divisione in primavera",
 },
 "1ed8fe04-ac2d-4106-b25e-799b6c0aa623": {  # acacia-saligna
  "descrizione": "Acacia saligna è un arbusto sempreverde o piccolo albero a crescita rapida, della famiglia delle Fabaceae, con altezza e diffusione variabili tra 2 e 8 m. Ha lunghi fillodi grigio-verdi stretti, lunghi fino a 25 cm. In primavera produce piccoli fiori tondi, giallo brillante, e se avviene la fecondazione dei semi si formano baccelli bruni e cartacei. È segnalata come specie non autoctona invasiva nel Regno Unito.",
  "parassiti_malattie": "Parassiti: vedi note di coltivazione; Malattie: vedi note di coltivazione",
  "propagazione": "Propagazione: vedi note di coltivazione",
 },
 "d2682485-112f-4e21-bdff-ef2a66b62914": {  # urtica-urens
  "descrizione": "Urtica urens è una pianta annuale cespugliosa ed eretta, della famiglia delle Urticaceae, alta fino a 75 cm, con foglie nettamente dentate. In estate produce gruppi di piccoli fiori bianco-verdastri. Le foglie sono ricoperte di minuscoli peli che possono irritare la pelle, anche se le foglie giovani sono commestibili se cotte.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: può essere soggetta ad alcune malattie fungine e virali",
  "potatura": "Potatura: cimare dopo la fioritura per evitare l'autosemina",
  "propagazione": "Propagazione: per seme",
 },
 "d8285cbd-9cdd-4944-9252-41563da872ab": {  # callistemon-citrinus
  "descrizione": "Callistemon citrinus è un arbusto sempreverde, dai rami arcuati, dal portamento tondeggiante o eretto, della famiglia delle Myrtaceae, che può raggiungere circa 5 m di altezza. Le foglie, strette, da oblunghe a lanceolate, sprigionano un profumo di limone se stropicciate. Fiorisce dall'inizio della primavera alla fine dell'estate, con vistosi fiori rosso brillante riuniti in spighe cilindriche, lunghe fino a 10 cm.",
  "parassiti_malattie": "Parassiti: può essere soggetto a cocciniglie, cocciniglie farinose e al ragnetto rosso da serra; Malattie: può essere soggetto ad armillaria (fungo del miele)",
  "potatura": "Potatura: gruppo di potatura 8",
  "propagazione": "Propagazione: per seme o per talea semilegnosa",
 },
 "8e87e914-f8bb-4db6-9028-1b2aa669383c": {  # phyteuma-orbiculare
  "descrizione": "Phyteuma orbiculare è una specie rara e autoctona, limitata ad alcune contee del sud dell'Inghilterra, della famiglia delle Campanulaceae. Produce fiori blu intenso su fusti non ramificati, alti 30-50 cm, sopra un ciuffo di foglie da ovali a lanceolate. Le insolite infiorescenze globose, formate da fino a 30 fiori stretti, tubolari e incurvati, compaiono da inizio a fine estate.",
  "parassiti_malattie": "Parassiti: generalmente esente da parassiti; Malattie: generalmente esente da malattie",
  "potatura": "Potatura: non richiede potatura",
  "propagazione": "Propagazione: per seme",
 },
 "dc7279fe-dade-40df-9e76-32491923de82": {  # cotoneaster-microphyllus (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Cotoneaster, della famiglia delle Rosaceae, arbusti o piccoli alberi decidui o sempreverdi, con foglie semplici e intere, e gruppi di piccoli fiori bianchi o rosa in primavera ed estate, seguiti da vistose bacche rosse, viola o nere.",
 },
 "48208379-6b0c-49a2-9abc-edea43d11383": {  # prunus-simonii (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Prunus, della famiglia delle Rosaceae, alberi o arbusti decidui o sempreverdi con fioriture vistose in primavera, spesso con un bel colore autunnale del fogliame. Alcune specie hanno frutti commestibili in autunno, e poche hanno una corteccia ornamentale.",
 },
 "a1302e7c-cccb-4379-9a38-33f9b2ac4aa7": {  # berberis-aristata (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Berberis, della famiglia delle Berberidaceae, arbusti decidui o sempreverdi con germogli spinosi che portano foglie semplici, spesso dentate a spina, e piccoli fiori gialli o arancioni in gruppi ascellari o racemi, seguiti da piccole bacche.",
 },
 "021ae931-a4da-47d7-bc70-2fb3263c81ec": {  # abies-veitchii (genere)
  "descrizione": "Non sono disponibili dati specifici per la specie: si riportano i tratti generali del genere Abies, della famiglia delle Pinaceae, conifere sempreverdi, spesso di grandi dimensioni, con rami disposti a verticilli che portano foglie aghiformi appiattite, spesso biancastre nella pagina inferiore, e sui rami superiori grandi pigne che si disgregano rimanendo attaccate alla pianta.",
 },
}


def apply_overrides(row, override):
    alert = list(row["alert"])
    for i, voce in enumerate(alert):
        if RISCHI_NONE_RE.match(voce):
            alert[i] = "Rischi segnalati dalla fonte: nessun rischio noto"
            continue
        m = PARASSITI_MALATTIE_RE.match(voce)
        if m and "parassiti_malattie" in override:
            alert[i] = override["parassiti_malattie"]
            continue
        m = POTATURA_RE.match(voce)
        if m and "potatura" in override:
            alert[i] = override["potatura"]
            continue
        m = PROPAGAZIONE_RE.match(voce)
        if m and "propagazione" in override:
            alert[i] = override["propagazione"]
            continue
    return {"descrizione": override["descrizione"], "alert": alert}


def main():
    rows = {r["id"]: r for r in json.loads(Path("lotto4_rhs.json").read_text())}
    missing = [rid for rid in rows if rid not in OVERRIDES]
    extra = [rid for rid in OVERRIDES if rid not in rows]
    print(f"Righe totali: {len(rows)}  Override forniti: {len(OVERRIDES)}")
    if missing:
        print("MANCANTI (nessun override):")
        for rid in missing:
            print(" -", rid, rows[rid]["slug"])
    if extra:
        print("EXTRA (override senza riga corrispondente):", extra)

    results = {}
    for rid, override in OVERRIDES.items():
        results[rid] = apply_overrides(rows[rid], override)
    Path("lotto4_finale.json").write_text(json.dumps(results, ensure_ascii=False, indent=1))
    print(f"Scritte {len(results)} righe elaborate in lotto4_finale.json")


if __name__ == "__main__":
    main()
