-- Fase 3, trentasettesimo batch da guida-completa-giardino (pp. 572-579):
-- Spiraea, Syringa (chiudono "Piante Arbustacee"), Abies (apre "Alberi
-- Sempreverdi e Caducifogli"). Rhododendron saltato: gia' posseduto e
-- verificato via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Spiraea$t$,
  $t$Spiraea$t$,
  $t$spiraea$t$,
  $t$Rosaceae$t$,
  $t$perenne$t$,
  $t$Spiree, bellissimi arbusti decidui rustici originari del Nord-est asiatico e, in minor misura, del Nordamerica e dell'Europa. Ha dimensioni medio-piccole, con steli sottili e ramificati, foglie alterne, dentate, di forma variabile dal bianco, al rosso, al rosato della fioritura, riuniti in pannocchie o corimbi terminali. Talvolta la fioritura può fiorire in primavera oppure in estate intensa da rosso. A seconda della specie la pianta può fiorire in primavera oppure in estate.$t$,
  $t${"luce": "Si adatta bene sia alle posizioni in pieno sole sia a quelle in ombra", "acqua": "Dimostra una buona resistenza al freddo", "terreno": "Non ha particolari preferenze, pur prediligendo suoli fertili e freschi"}$t$::jsonb,
  ARRAY[$t$Talvolta può essere colpita da insetti minatori che ne determinano l'arrotolamento fogliare$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": "si regola a seconda delle specie. Alcune, infatti, portano i fiori su rami di un anno (Spiraea arguta e una delle spe-cie più coltivate per formare siepi), altre invece a fioritura conclusa, operando in modo cesantomiensis; altre invece a fioritura estiva sulla vegetazione dell'anno (Spiraea japonica, bumalda, douglasii, prunifolia), a questa distinzione", "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Spiraea, p. 572-573$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Syringa$t$,
  $t$Syringa$t$,
  $t$syringa$t$,
  $t$Oleaceae$t$,
  $t$perenne$t$,
  $t$Lillà, arbusto deciduo di buona rusticità, in minor misura, originario dell'Asia e dell'Europa. Presenta foglie opposte, in genere semplici, con margine intero, riuniti in grosse pannocchie ascellari o terminali, di colore intenso ed emanano un profumo soave che ne costituisce il pregio maggiore. Presentano una gamma di colori dal giallo, al rosa, al rosso porporino, al giallo, al malva, al rosa, al rosso violetto, al lilla bluastro. In commercio esistono numerose varietà; molte hanno il pregio di allungare il ciclo di fioritura che purtroppo ha soltanto, un ciclo piuttosto rapido.$t$,
  $t${"luce": "Predilige posizioni soleggiate, anche se si può essere coltivata in leggera ombra. Si tenga comunque che l'ombra limita la fioritura e smorza la vivacità dei colori", "acqua": "Dimostra una buona resistenza al freddo", "terreno": "Pur adattandosi a diversi tipi, gradisce suoli piuttosto compatti, freschi ben dotati di sostanza organica. Sopporta bene la presenza di calcare"}$t$::jsonb,
  ARRAY[$t$Non richiede protezioni particolarmente costanti, anche se può essere colpita da insetti minatori delle foglie e da parassiti che presente che l'ombra limita la fioritura$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "si effettua in giugno, operando in modo conclusa. E' importante potare le piante vecchie andranno tagli sulla bassa, gli arbusti andranno contro sviluppperanno una chioma piu densa aghi soggetti alla sfogliazione della pianta"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "durante i mesi più caldi in prima-vera e in estate. Si può effettuare una pacciamatura alla base della pianta utilizzando letame maturo", "autunno": null, "inverno": null, "primavera": "durante i mesi più caldi in prima-vera e in estate. Si può effettuare una pacciamatura alla base della pianta utilizzando letame maturo"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Syringa, p. 574-575$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Abies$t$,
  $t$Abies$t$,
  $t$abies$t$,
  $t$Pinaceae$t$,
  $t$perenne$t$,
  $t$Abete bianco, arborea sempreverde con portamento conico-piramidale, molto diffusa sulle montagne dell'Europa, in Italia sugli Appennini centromeridionali e sulle Alpi orientali e centromeridionali sino in Calabria. Può raggiungere i 45-50 m di altezza. Ha il fusto diritto, con taglia ridotta il fustaia, molto rugida, da cui si staccano numerose placche. Le foglie aghiformi, di colore verde intenso, sono lunghe circa 2 cm, appiattite e con la parte terminale arrotondata; inserite sui rametti singolarmente e disposte su due file. I fiori femminili uniti in pigne erette (mai pendule) lunghe circa 10-15 cm e sono di colore bruno-rossiccio a maturazione. Varietà note: Abies balsamea Hudsonia (nana), Abies cephalonica (aghi glauchi e appuntiti), Abies concolor (aghi glauchi su tutti i lati), Abies procera (foglie azzurro argentato), Abies pinsapo (chioma elegante), Picea pungens Kosteri (aghi blu argentato), Picea nordmanniana (abete del Caucaso, rustico).$t$,
  $t${"luce": "Non teme le basse temperature essendo tipico delle zone montane. Non è esigente ma predilige posizioni soleggiate pur adattandosi anche all'ombra parziale", "terreno": "Generalmente predilige i terreni profondi e umidi, alcune specie si adattano anche a terreni calcarei"}$t$::jsonb,
  ARRAY[$t$Può essere soggetta ad alcuni tipi di afidi che provocano il decolorimento di aghi e il deperimento dei rametti da cui partono fin dalla base$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Abies, p. 578-579$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
