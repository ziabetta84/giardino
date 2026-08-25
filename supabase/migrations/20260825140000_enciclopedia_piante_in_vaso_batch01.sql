-- Fase 3, enciclopedia-piante-in-vaso ("Piante in vaso", collana Fiori &
-- Piante, Edicart) — riprende da dove si era fermata una sessione
-- precedente non documentata (6 generi gia' verificati: Acacia,
-- Agapanthus, Arbutus, Abutilon, Brugmansia, Brassica/cavolo-ornamentale).
-- Tutte le 46 foto della cartella sono state lette; il libro non procede
-- rigidamente in ordine alfabetico continuo (due sessioni di scatto,
-- generi non contigui nella seconda). Contenuto nuovo raccolto:
--
-- INSERT (generi mai presenti nel catalogo): Callistemon, Canna, Cassia,
-- Cestrum, Solanum, Teucrium, Tibouchina, Yucca.
--
-- UPDATE (arricchimento, mai sovrascrittura di campi gia' popolati):
-- Agave (gia' verificato RHS: solo descrizione/alert aggiuntivi),
-- Buxus sempervirens e Punica granatum (bozza PFAF con manutenzione
-- vuota: popolata dove il libro da' indicazioni reali),
-- Chamaerops humilis (bozza PFAF: manutenzione popolata),
-- Chrysanthemum, Cistus, Rosa, Viola (bozza da guida-completa-giardino,
-- generiche: arricchite con dettaglio di specie/cultivar da questa
-- fonte piu' specifica), Rosmarino (gia' verificato RHS: solo cultivar
-- e nota di rinvaso aggiunte).
--
-- Plumbago (gia' verificato RHS, gia' molto completo) escluso: nessun
-- contenuto realmente nuovo in questa fonte oltre a un cenno di uso
-- medicinale minore, non abbastanza per giustificare una scrittura.

-- ============ INSERT: generi nuovi ============

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values
($t$Callistemon$t$, $t$Callistemon$t$, $t$callistemon$t$, $t$Myrtaceae$t$, $t$perenne$t$,
 $t$Scovolino da bottiglia, genere originario dell'Australia con circa 25 specie di arbusti o piccoli alberi sempreverdi, apprezzati per le infiorescenze a spiga cilindrica con lunghi stami sporgenti, simili a uno scovolino, generalmente rossi.$t$,
 $t${"luce": "Pieno sole", "terreno": "Terriccio per vasi ben drenato"}$t$::jsonb,
 ARRAY[$t$Va rinvasato e potato radicalmente se necessario; si moltiplica per talee semilegnose, con un prodotto che favorisce la radicazione, conservate a temperatura calda$t$],
 null,
 ARRAY[$t$Piante in vaso (collana Fiori & Piante, Edicart) — Callistemon, p. 20$t$], $t$bozza$t$),

($t$Canna$t$, $t$Canna$t$, $t$canna$t$, $t$Cannaceae$t$, $t$perenne$t$,
 $t$Genere indigeno delle regioni tropicali e subtropicali dell'America e dell'Asia, comprende 55 specie e numerose varietà. Piante erbacee con spessi rizomi, foglie erette verde brillante lunghe anche 60 cm e splendidi fiori rosso, arancione, giallo, rosa o bianco. Gli ibridi ottenuti da C. indica sono coltivati come ornamentali sin dal Medioevo, spesso riuniti in racemi o pannocchie; alcune varietà hanno foglie viola-bronzo. Cultivar note: 'Orchid' (fiori rosa), 'Red King Humber' (foglie color bronzo, fiori rosso scuro), 'Richard Wallace' (fiori giallo pastello), C. x indica 'Lucifer' (fiori rosso brillante con margine giallo, pianta nana coltivabile anche in appartamento).$t$,
 $t${"luce": "Pieno sole ma posizione riparata, per esempio contro un muro", "acqua": "Innaffiare abbondantemente", "terreno": "Terra per vasi arricchita di sabbia"}$t$::jsonb,
 ARRAY[$t$Proteggere le piante dalle lumache$t$, $t$Tollera qualche notte fredda (10°C) e continua a fiorire fino ai primi geli; eliminare i fiori appassiti$t$],
 $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "irrobustire accuratamente le piante in primavera, rinvasando in aprile"}, "irrigazione": {"estate": "abbondante", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "ogni 15 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
 ARRAY[$t$Piante in vaso (collana Fiori & Piante, Edicart) — Canna, p. 21$t$], $t$bozza$t$),

($t$Cassia$t$, $t$Cassia$t$, $t$cassia$t$, $t$Fabaceae (Leguminosae)$t$, $t$perenne$t$,
 $t$Genere spontaneo nelle regioni tropicali e subtropicali dell'America, dell'Africa e dell'Asia, comprende 500-600 specie erbacee, arboree e arbustive, coltivate anche per le proprietà medicinali (le foglie di C. senna e C. angustifolia hanno proprietà lassative, usate fin dal Medioevo). Foglie aromatiche sempreverdi paripennate, fiori con ampi petali gialli e stami sporgenti riuniti in grandi racemi, frutti a lunghi baccelli. C. corymbosa, originaria dell'Argentina, è un arbusto alto 1-1,5 m con foglie lucide verdi e fiori giallo-oro in racemi; la varietà pluryuga (sin. C. floribunda) fiorisce più tardi, da luglio in autunno. C. didymobotrya, originaria del Kenya, raggiunge i 50 cm, fiorisce tutto l'anno se il clima è favorevole, con spighe erette di 15-20 cm; non produce frutti e non si moltiplica per talea.$t$,
 $t${"luce": "Posizione calda, in pieno sole (serra non riscaldata), protetta dalla pioggia", "terreno": "Terriccio per vasi arricchito con argilla"}$t$::jsonb,
 ARRAY[$t$Dopo la fioritura potare la pianta (C. didymobotrya) per favorire una fioritura successiva; C. corymbosa dopo la fioritura va potata degli stoloni$t$],
 $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "una volta alla settimana nel periodo vegetativo", "autunno": null, "inverno": "far svernare a 5-15°C secondo la specie", "primavera": null}}$t$::jsonb,
 ARRAY[$t$Piante in vaso (collana Fiori & Piante, Edicart) — Cassia, p. 22-23$t$], $t$bozza$t$),

($t$Cestrum$t$, $t$Cestrum$t$, $t$cestrum$t$, $t$Solanaceae$t$, $t$perenne$t$,
 $t$Genere indigeno delle regioni subtropicali dell'America e delle Indie occidentali, comprende circa 150 specie della famiglia delle Solanaceae. Specie arbustive o arboree, adatte per serre non riscaldate, con piccoli fiori tubulosi riuniti in grappoli terminali e frutti a bacca rossi, bianchi o neri. C. aurantiacum è un arbusto semisempreverde con racemi di fiori profumati giallo-aranciati che sbocciano di sera. C. elegans (sin. C. purpureum), cestro, ha fiori rosso-porporini; il cultivar 'Newellii' (sin. Habrothamnus newellii), probabile incrocio tra C. elegans e C. fasciculatum, ha fiori cremisi. C. parqui è più resistente al freddo, con fiori giallo-verdastri.$t$,
 $t${"luce": "Posizione riparata, soleggiata ma non esposta al sole diretto di mezzogiorno", "acqua": "Innaffiare abbondantemente nel periodo vegetativo"}$t$::jsonb,
 ARRAY[$t$Piante sensibili ai funghi$t$],
 $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "alla fine dell'inverno, se necessario, potare e rinvasare in terriccio con un terzo di terriccio arenoso"}, "irrigazione": {"estate": null, "autunno": null, "inverno": "terra piuttosto asciutta, senza far cadere le foglie", "primavera": null}, "concimazione": {"estate": "una volta alla settimana", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
 ARRAY[$t$Piante in vaso (collana Fiori & Piante, Edicart) — Cestrum, p. 24-25$t$], $t$bozza$t$),

($t$Solanum$t$, $t$Solanum$t$, $t$solanum$t$, $t$Solanaceae$t$, $t$perenne$t$,
 $t$Uno dei generi più vasti di piante, comprende 1700 specie diffuse in tutto il mondo, tra cui patata e melanzana note per il valore alimentare. Piante erbacee o legnose con fiori a corolla pentagonale e frutti a bacca (quelli acerbi spesso velenosi). S. glaucum, dell'America meridionale, ha fiori pentagonali blu di 2,5 cm e frutti porpora. S. muricatum (pepino), forse indigena delle Ande, ha fiori blu-porpora e frutti verdi che maturano gialli con striature porpora, polpa dolce e succosa. S. pseudocapsicum (sin. Capsicum capsicastrum), da Madeira, ha portamento espanso alto 40 cm e splendidi frutti arancioni ornamentali; il cultivar 'Variegatum' ha foglie striate di bianco e frutti bicolori.$t$,
 $t${"luce": "Posizione riparata, soleggiata o leggermente in ombra", "acqua": "Innaffiare abbondantemente nel periodo vegetativo"}$t$::jsonb,
 ARRAY[$t$I frutti acerbi sono spesso velenosi$t$],
 $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "potare i rami a un terzo della lunghezza totale"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "ogni 15 giorni nel periodo vegetativo"}}$t$::jsonb,
 ARRAY[$t$Piante in vaso (collana Fiori & Piante, Edicart) — Solanum, p. 61-62$t$], $t$bozza$t$),

($t$Teucrium$t$, $t$Teucrium$t$, $t$teucrium$t$, $t$Lamiaceae$t$, $t$perenne$t$,
 $t$Genere spontaneo nelle regioni temperate calde, comprende circa 300 specie di piante erbacee o legnose con foglie aromatiche opposte e fiori in verticilli ascellari. T. fruticans (sin. T. latifolium) è un arbusto sempreverde eretto, con giovani getti e pagina inferiore delle foglie cotonosi, fiori blu o lilla in infiorescenze racemose; il cultivar 'Azureum' ha fiori di un blu più carico. Tollera bene i climi aridi.$t$,
 $t${"luce": "Posizione soleggiata", "terreno": "Terriccio calcareo-arenoso, ben drenato"}$t$::jsonb,
 null, null,
 ARRAY[$t$Piante in vaso (collana Fiori & Piante, Edicart) — Teucrium, p. 66$t$], $t$bozza$t$),

($t$Tibouchina$t$, $t$Tibouchina$t$, $t$tibouchina$t$, $t$Melastomataceae$t$, $t$perenne$t$,
 $t$Genere indigeno delle regioni tropicali dell'America, comprende 200 specie di arbusti legnosi con grandi fiori solitari o raggruppati. T. urvilleana (sin. T. grandiflora, T. semidecandra), tibouchina, proveniente dal Brasile orientale, ha fioritura abbondante, fusti a sezione quadrangolare alati e foglie vellutate; i fiori blu-viola hanno un diametro di 10 cm e la pianta fiorisce verso la fine dell'estate.$t$,
 $t${"luce": "Posizione soleggiata e riparata soprattutto dal vento", "acqua": "Innaffiare abbondantemente"}$t$::jsonb,
 null,
 $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "potare radicalmente e rinvasare"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "ogni 15 giorni"}}$t$::jsonb,
 ARRAY[$t$Piante in vaso (collana Fiori & Piante, Edicart) — Tibouchina, p. 67$t$], $t$bozza$t$),

($t$Yucca$t$, $t$Yucca$t$, $t$yucca$t$, $t$Agavaceae (Asparagaceae)$t$, $t$perenne$t$,
 $t$Genere originario degli USA meridionali e dell'America centrale, comprende circa 40 specie arboree o arbustive sempreverdi con foglie rigide, spesso fibrose, lanceolate e pannocchie terminali di fiori penduli bianchi profumati soprattutto di notte. Y. aloifolia è un arbusto eretto o alberello con fusto cilindrico e foglie ravvicinate con margine tagliente e spina all'apice (cultivar 'Variegata' e 'Marginata' a foglie striate/marginate di bianco). Y. gloriosa è a crescita lenta, con fusto breve e rigido, foglie pendenti verde-grigiastre e fiori bianco-crema con strisce rosse in pannocchie fino a 2,5 m.$t$,
 $t${"luce": "Pieno sole", "terreno": "Vasi ben drenati, terriccio argilloso ricco di humus"}$t$::jsonb,
 null,
 $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "abbondante", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
 ARRAY[$t$Piante in vaso (collana Fiori & Piante, Edicart) — Yucca, p. 71$t$], $t$bozza$t$)

on conflict (slug) do nothing;

-- ============ UPDATE: arricchimento righe esistenti ============

update specie set
  descrizione = descrizione || $t$ A. americana è la specie più grande, con foglie fino a 175 cm e pungiglioni prima marroni scuri poi grigi (la varietà 'Marginata' ha foglie a margini striati o gialli); A. victoriae-reginae resta più bassa, con foglie striate di bianco lunghe fino a 25 cm, non forma stoloni e si moltiplica per seme.$t$,
  alert = alert || ARRAY[$t$Per via dei pungiglioni terminali va tenuta in posizione sicura, non di passaggio; durante spostamento o rinvaso si può proteggere la punta delle foglie con un turacciolo di sughero$t$],
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Agave, p. 6-7$t$)
where slug = $t$agave$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Agave, p. 6-7$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Genere spontaneo nell'Europa meridionale, comprende arbusti sempreverdi molto rustici con foglioline piccole e lucide, adatti a siepi basse e bordure anche in vaso, tollera potature ripetute a forme geometriche. Il cultivar 'Aureovariegata' ha foglie striate di giallo.$t$,
  alert = alert || ARRAY[$t$Cresce lentamente e tollera bene le potature di formazione ripetute$t$],
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Buxus, p. 17-18$t$)
where slug = $t$buxus-sempervirens$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Buxus, p. 17-18$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Il genere comprende l'unica palma che cresce spontanea in Europa, originaria delle regioni mediterranee occidentali; in natura può raggiungere i 7 m, ma la varietà coltivata è più bassa e con portamento espanso. Alberello con foglie a ventaglio su fusto spinoso, fiori gialli a spadice e frutti a drupa gialla scura. C. humilis, palma nana o palma di S. Pietro, ha fusto fibroso marrone spesso assente; il cultivar 'Macrocarpa' ha frutti sorprendentemente grandi, 'Elatior' è una varietà più grande. Cresce lentamente e sviluppa polloni alla base del fusto.$t$,
  esigenze = $t${"terreno": "Terra per vasi ben drenata, mescolata ad argilla, pacciame e sabbia"}$t$::jsonb || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[$t$Le punte marroni delle foglie vanno eliminate, ma non i margini$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "abbondante, il cespo non va lasciato seccare", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "ogni 2-4 settimane, con nebulizzazioni", "autunno": null, "inverno": "sospesa, riporre in locale asciutto con temperatura non inferiore a 0°C", "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Chamaerops, p. 26$t$)
where slug = $t$chamaerops-humilis$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Chamaerops, p. 26$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ C. carinatum ha capolini con disco rosso scuro di 4-6 cm (cultivar 'Court Jesters' screziato, 'Poolter' bianco con corona gialla). C. coronarium ha capolini di 3-5 cm con flosculi tubulosi verdi-giallastri ('Primrose Gem' e 'Golden Gem' quasi solo flosculi ligulati). C. segetum, margherita delle messi, ha capolini gialli o gialli con disco marrone, fiorisce già a 10 settimane dalla semina, ottima da fiore reciso. C. frutescens è una specie semiarbustiva ramificata con capolini a margherita fino a 7 cm, gialli con flosculi ligulati bianchi; si moltiplica per talee prese in autunno (le altre specie per seme).$t$,
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Chrysanthemum, p. 27-28$t$)
where slug = $t$chrysanthemum$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Chrysanthemum, p. 27-28$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Il genere comprende circa 200 specie che si incrociano facilmente (esistono molti ibridi). C. crispus, cisto increspato, ha lunghi fusti pelosi e foglie sessili ovato-lanceolate, tomentose e pubescenti.$t$,
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Cistus, p. 29-30$t$)
where slug = $t$cistus$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Cistus, p. 29-30$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ In Cina le rose erano coltivate già nel 2700 a.C. R. polyantha (e le sue circa 200 varietà) produce precocemente fiori piccoli e duraturi, tra le specie più facilmente coltivabili in vaso; piantare con il punto d'innesto a circa 5 cm dal suolo. Specie naturali: R. hugonensis (fiori giallo brillante, fioritura precoce), R. movesii (fiori rosso sangue, falsi frutti rosso-aranciati), R. pimpinellifolia sin. spinosissima (varietà nana, fiori bianco-crema, piccoli falsi frutti neri). Varietà Floribunda e Tea (fiori semidoppi o doppi, potare tutti i rami a 15 cm da terra in primavera): 'All Gold' giallo-oro, 'Dearest' rosa-salmone, 'Iceberg' bianco puro, 'Topsi' nana rosso-arancio, 'Blue Moon' rosa poi lilla, 'King's Ransom' giallo carico, 'Ernest H. Morse' rosso carico, 'Melrose' crema sfumato rosso. Rose rampicanti (potare i rami principali a 50 cm, i laterali a 10 cm): 'Danse du Feu' rosso carico, 'Golden Showers' giallo-oro, 'Händel' bianco con lembo rosso, 'New Dawn' rosa chiaro. Rose sarmentose (potare a 30 cm dal suolo): 'Albéric Barbier' giallo-crema profumata di mela, 'Dorothy Perkins' rosa carico, 'Sanders White' bianco puro.$t$,
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Rosa, p. 55-58$t$)
where slug = $t$rosa$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Rosa, p. 55-58$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Il genere comprende 3 specie. Cultivar di R. officinalis: 'Albus' fiori bianchi, 'Marjocan Pink' fiori rosa, 'Benenden Blue' varietà nana a fiori blu, 'Sissinghurst Blue' fiori blu scuro. Resiste all'aperto sui litorali; sotto i -10°C far svernare in locale luminoso e fresco.$t$,
  alert = alert || ARRAY[$t$Rinvasare ogni 3 anni in terriccio calcareo ben drenato; non è necessario concimare$t$],
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Rosmarinus, p. 64$t$)
where slug = $t$rosmarino$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Rosmarinus, p. 64$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Genere di specie erbacee, per lo più perenni, diffuso nelle regioni temperate e montuose tropicali/subtropicali. V. hederacea, dall'Australia, soffre il gelo, ha stoloni e piccoli fiori viola; in estate va posta in cesto pensile all'aperto. Gli ibridi di V. tricolor (es. 'Hollandse Reuzen', fiori grandi unicolori o screziati) fioriscono in primavera e si conservano in serra fredda d'inverno. Gli ibridi di V. cornuta sono perenni cespugliose alte 15-20 cm, da tenere in posizione un po' ombreggiata e fresca. V. x wittrockiana, coltivata di solito come biennale, ha fiori unicolori o striati spesso con centro scuro; seminare in agosto per la fioritura invernale.$t$,
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Viola, p. 68-69$t$)
where slug = $t$viola$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Viola, p. 68-69$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Il genere Punica comprende solo 2 specie, di cui unicamente il melograno (P. granatum) è coltivato. La polpa acidula dei semi ha proprietà diuretiche e serve a preparare sciroppi (granatina); la corteccia contiene sostanze alcaline. Fusti in genere spinosi, foglie lanceolate coriacee verde-lucente, fiori campanulati rosso-scarlatto di 4 cm. Le piante adulte fioriscono più abbondantemente; un'estate calda e un autunno asciutto favoriscono la fruttificazione. I frutti hanno diametro 6-12 cm, buccia giallognola-rossastra, con semi avvolti da polpa rosso-rubino. Le cultivar a fiori doppi di solito non producono frutti; 'Nana' è una varietà nana più espansa, alta fino a 1 m, che fruttifica anche da giovane.$t$,
  esigenze = $t${"acqua": "Innaffiare regolarmente, il cespo non va fatto asciugare", "terreno": "Terra per vasi arricchita di argilla"}$t$::jsonb || coalesce(esigenze, '{}'::jsonb),
  alert = alert || ARRAY[$t$Richiede una posizione riparata, va esposta al pieno sole solo dopo un periodo di adattamento graduale; tollera temperature fino a -10°C ma non l'umidità eccessiva$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": "potare i rami giovani a metà della loro lunghezza prima del ricovero invernale", "primavera": "in primavera rinvasare (piante giovani ogni anno, adulte ogni 5 anni)"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimare di tanto in tanto"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Piante in vaso (collana Fiori & Piante, Edicart) — Punica granatum, p. 52-53$t$)
where slug = $t$punica-granatum$t$
  and not ($t$Piante in vaso (collana Fiori & Piante, Edicart) — Punica granatum, p. 52-53$t$ = any(fonti));
