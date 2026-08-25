-- Fase 3, ultimo batch (43) da guida-completa-giardino (pp. 620-627,
-- ultime pagine del libro): arricchisce Robinia pseudoacacia, Salix
-- babylonica, Sophora variegata, Taxus baccata, Thuja occidentalis, Thuja
-- orientalis (bozza, manutenzione vuota/assente); inserisce Tamarix,
-- Taxodium. Chiude l'importazione delle 173 foto di guida-completa-giardino.

update specie set
  alert = alert || ARRAY[$t$Può essere soggetta all'attacco del tarlo, le cui larve scavano nella corteccia provocando rigonfiamenti$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "necessita di potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "le concimazioni non sono necessarie"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Robinia, p. 620$t$)
where slug = $t$robinia-pseudoacacia$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Robinia, p. 620$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Generalmente queste piante non risentono dell'attacco di parassiti o di malattie$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "viene effettuata sulle piante giovani"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non ha bisogno di particolari concimazioni"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Salix babylonica, p. 621$t$)
where slug = $t$salix-babylonica$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Salix babylonica, p. 621$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Può essere attaccata da afidi o acari, che difficilmente provocano danni gravi$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "necessari interventi eliminando i rami secchi"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimare normalmente"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Sophora, p. 622$t$)
where slug = $t$sophora-variegata$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Sophora, p. 622$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Mancanza di acqua provoca la caduta delle foglie (non ha nemici nel mondo animale)$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "sono sufficienti solo potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non necessita di molte concimazioni"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Taxus baccata, p. 625$t$)
where slug = $t$taxus-baccata$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Taxus baccata, p. 625$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$È soggetta al floesino, un piccolo coleottero che scava gallerie nel legno; possono aprirsi spontaneamente a maturità piccolissimi colpi di piacimento$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "intervenire con potature di risanamento, non soffre i tagli"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "al momento dell'impianto è bene utilizzare del concime organico"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Thuja occidentalis, p. 626-627$t$)
where slug = $t$thuja-occidentalis$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Thuja occidentalis, p. 626-627$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Scava gallerie insediandosi e provocando la morte della pianta se attaccata da organismi legnosi$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "interventi con potature di risanamento, non soffre i tagli"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "al momento dell'impianto è bene utilizzare del concime organico"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Thuja orientalis, p. 626-627$t$)
where slug = $t$thuja-orientalis$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Thuja orientalis, p. 626-627$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Tamarix$t$,
  $t$Tamarix$t$,
  $t$tamarix$t$,
  $t$Tamaricaceae$t$,
  $t$perenne$t$,
  $t$Tamerice, arborea caducifoglia, originaria dell'Europa meridionale e dell'Asia occidentale, con chioma espansa e irregolare, molto arbustivo. Ha portamento spesso arbustivo e rami spioventi. Mediamente è alta 3-4 m, può raggiungere il massimo i 6 m. Il fusto è contorto, spesso ramificato al-la base. La corteccia è di colore grigio scuro quasi liscia e di colore grigio scuro. Si caratterizza per le foglie squamiformi, lanceolate, di colore verde glauco. I fiori sono piccolissimi, riuniti in racemi a spiga, di colore rosa o rossastro, compaiono all'apice dei giovani rami in numero elevatissimo so in numero elevatissimo formando un caratteristico effetto piumoso.$t$,
  $t${"luce": "Si adatta bene a ogni tipo di terreno, ma preferisce quelli sciolti e ben drenati", "acqua": "Soffre solo il calcare", "terreno": "Si adatta bene a ogni tipo di terreno, ma preferisce quelli sciolti e ben drenati"}$t$::jsonb,
  ARRAY[$t$È una pianta molto rustica che non necessita di cure particolari$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "intervenire soltanto con potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "le concimazioni non sono necessarie"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Tamarix, p. 623$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Taxodium$t$,
  $t$Taxodium$t$,
  $t$taxodium$t$,
  $t$Taxodiaceae$t$,
  $t$perenne$t$,
  $t$Cipresso calvo, arborea caducifoglia molto longeva, originaria dell'America sudorientale, con portamento colonnare e chioma a forma conico-piramidale. Ha il tronco eretto, con corteccia bruno-rossastra, molto rugosa, con corteccia color bruno-rossastro, molto rugosa. Le foglie di colore verde chiaro sulla pagina superiore, sono disposte a due file opposte, sono molto sottili, lineari e molto sottili, disposte a due file opposte, di colore verde chiaro.$t$,
  $t${"luce": "Predilige i terreni tendenzialmente acidi e molto umidi", "terreno": "Predilige i terreni tendenzialmente acidi e molto umidi"}$t$::jsonb,
  ARRAY[$t$Non soffre né il freddo né il caldo eccessivo, tollera bene anche le posizioni in pieno sole$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "interviene soltanto con potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "le concimazioni non sono necessarie"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Taxodium, p. 624$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
