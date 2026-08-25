-- Fase 3, trentanovesimo batch da guida-completa-giardino (pp. 588-595,
-- "Alberi Sempreverdi e Caducifogli"): arricchisce Cedrus deodara, Cercis
-- siliquastrum, Chamaecyparis lawsoniana, Cupressus sempervirens (bozza
-- PFAF, manutenzione vuota); inserisce Betula, Carpinus, Eriobotrya.

update specie set
  alert = alert || ARRAY[$t$Soggetta a funghi che indeboliscono il tessuto legnoso$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "non ha bisogno di interventi particolari"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non ha bisogno di concimazioni regolari"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Cedrus deodara, p. 590$t$)
where slug = $t$cedrus-deodara$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Cedrus deodara, p. 590$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Essendo una pianta rustica, non soffre di particolari malattie; le foglie possono essere attaccate dagli afidi$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "necessita di tagli di formazione al piede"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non sono necessarie concimazioni"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Cercis siliquastrum, p. 591$t$)
where slug = $t$cercis-siliquastrum$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Cercis siliquastrum, p. 591$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Teme molto il gelo e non sopporta gli sbalzi termici$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "non necessita di interventi particolari"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "è sufficiente concimarla normalmente"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Chamaecyparis lawsoniana, p. 592$t$)
where slug = $t$chamaecyparis-lawsoniana$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Chamaecyparis lawsoniana, p. 592$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Può essere soggetto all'attacco di afidi che portano una piccola quantità di concime organico ai piedi dell'albero, denominato appunto afide del cipresso$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "devono essere eliminati i rami che fuoriescono dal fusto"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "in autunno e in primavera è opportuno interrare una piccola quantità di concime organico ai piedi dell'albero", "autunno": "in autunno e in primavera è opportuno interrare una piccola quantità di concime organico ai piedi dell'albero", "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Cupressus sempervirens, p. 593$t$)
where slug = $t$cupressus-sempervirens$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Cupressus sempervirens, p. 593$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Betula$t$,
  $t$Betula$t$,
  $t$betula$t$,
  $t$Betulaceae$t$,
  $t$perenne$t$,
  $t$Betulla, arborea caducifoglia con portamento slanciato e chioma poco espansa. Può raggiungere altezza di 25-30 m. La crescita è molto rapida, ma è una pianta longeva. Il fusto è dritto, con corteccia liscia e di colore bianco, che si sfalda in foglie molto sottili e ramificati. Le foglie sono semplici, alterne, di forma romboidale, di colore verde chiaro su quella superiore, verde su quella inferiore, e di forma rombo alterne, di colore verde chiaro nella pagina superiore. In autunno assumono una colorazione giallo dorata molto piacevole.$t$,
  $t${"luce": "Ha una buona resistenza al freddo", "terreno": "Gradisce terreni sciolti e areati"}$t$::jsonb,
  ARRAY[$t$Il poliporo, un particolare fungo, può penetrare nella pianta dall'emissione delle foglie o dalla corteccia provocandone il marciume del legno$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "deve essere capitozzata quando raggiunge altezze pro-prio per le sue scarse esigenze"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "le irrigazioni devono essere abbondanti, ma con attenzione ai ristagni idrici prolungati"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non necessita concimazioni"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Betula, p. 588$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Carpinus$t$,
  $t$Carpinus$t$,
  $t$carpinus$t$,
  $t$Corylaceae$t$,
  $t$perenne$t$,
  $t$Carpino, arborea caducifoglia, originaria delle regioni dell'Europa centrale e delle regioni caucasiche, con chioma slanciata e folta, portamento arbustivo. Può raggiungere i 20 m di altezza. Mediamente raggiunge i 20 m di altezza. Il fusto è eretto e contorto, con corteccia grigio cenerino e profonde mificazioni assurgente e corteccia liscia. Le foglie sono ovale-oblunga, di colore verde scuro, più chiaro nella pagina inferiore, hanno una forma ovale-oblunga con margine dentato e apice acuminato.$t$,
  $t${"luce": "Molto rustica, si adatta bene a ogni tipo di temperatura", "terreno": "Predilige i terreni sciolti e profondi. Non sopporta quelli né argillosi né calcarei"}$t$::jsonb,
  ARRAY[$t$Non presenta particolari problemi per quanto riguarda malattie e parassiti$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "sopporta bene ogni tipo di taglio di potatura, le spollonature devono essere frequenti"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non necessita concimazioni particolari"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Carpinus, p. 589$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Eriobotrya$t$,
  $t$Eriobotrya$t$,
  $t$eriobotrya$t$,
  $t$Rosaceae$t$,
  $t$perenne$t$,
  $t$Nespolo del Giappone, originaria della Cina e del Giappone. Gli alberi di grandi dimensioni sono rari, superano di rado i 4-5 m di altezza, con un portamento tipicamente espanso e una vegetazione sempreverde, ricca e lussureggiante. Le grandi foglie coriacee, provviste di una caratteristica tomentosità rugginosa sulla pagina inferiore, sono di un bel colore verde lucente sulla pagina superiore; i fiori bianchi tomentosi riuniti a mazzetti, con abbondante fioritura autunno-invernale, attira in grande abbondanza gli insetti pronubi, indispensabili per una buona impollinazione. I frutti di colore giallo-arancio, hanno una buona polpa dolce e succosa, profumatissima.$t$,
  $t${"luce": "Predilige climi miti e temperati. Non sopporta il freddo intenso", "terreno": "Deve essere ben drenato, sciolto, umido e calcareo"}$t$::jsonb,
  ARRAY[$t$È soggetta agli attacchi che provoca necrosi dei tessuti e disseccamento parziale o della cocciniglia che provoca necrosi dei tessuti e disseccamento dei rami$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "non richiede interventi particolari"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "il terreno deve essere bene concimato, soprattutto in primavera e in autunno, interrare del concime organico ai piedi della pianta", "autunno": "il terreno deve essere bene concimato, soprattutto in primavera e in autunno, interrare del concime organico ai piedi della pianta", "inverno": null, "primavera": "il terreno deve essere bene concimato, soprattutto in primavera e in autunno, interrare del concime organico ai piedi della pianta"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Eriobotrya, p. 595$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
