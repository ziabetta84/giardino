-- Fase 3, quarantunesimo batch da guida-completa-giardino (pp. 604-611,
-- "Alberi Sempreverdi e Caducifogli"): arricchisce Magnolia grandiflora,
-- Picea abies, Pinus cembra, Pinus nigra (bozza, manutenzione vuota);
-- inserisce Malus, Melia, Paulownia.

update specie set
  alert = alert || ARRAY[$t$La famigliola (fungo) può provocare la morte della pianta$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non necessita di interventi di potatura o concimazione"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Magnolia, p. 604-605$t$)
where slug = $t$magnolia-grandiflora$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Magnolia, p. 604-605$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Soggetta all'attacco dell'afide galligeno, che colpisce i germogli facendoli seccare$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "non necessita di interventi di potatura"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "sono sufficienti concimazioni normali"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Picea excelsa, p. 609$t$)
where slug = $t$picea-abies$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Picea excelsa, p. 609$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$È poco esigente, si consiglia di non annaffiarla molto$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "non richiede interventi di potatura"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimare normalmente"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Pinus cembra, p. 610$t$)
where slug = $t$pinus-cembra$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Pinus cembra, p. 610$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Le larve degli imenotteri defogliatrici, potenti e attaccano gli aghi e li divorano lasciando un'esile nervatura che presto dissecca$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "sono sufficienti interventi normalmente di risanamento, con tagli non troppo compatti"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "è sufficiente concimare normalmente"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Pinus nigra, p. 611$t$)
where slug = $t$pinus-nigra$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Pinus nigra, p. 611$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Malus$t$,
  $t$Malus$t$,
  $t$malus$t$,
  $t$Rosaceae$t$,
  $t$perenne$t$,
  $t$Melo da fiore, arborea caducifoglia con portamento globoso-espansa, con chioma di origine giapponese, con chioma globoso-espansa, con crescita rapida e leggera. Ha una altezza media di 4-5 m, anche se può raggiungere i 6-8 m. Il fusto è eretto, con corteccia grigio-rossastra e liscia, di colore scuro terminano con punta leggermente arrotondata e li-scia. Le foglie ellittiche, di colore verde scuro termina con punta arrotondata e leggermente arrotondata. I fiori sono riuniti in corimbo, con margini dentati e hanno punta arrotondata, colore rosso vivo quando sono chiusi, poi aprendosi assumono colore bianco rosato.$t$,
  $t${"luce": "Poco esigente, preferisce i terreni argillosi e ricchi in humus", "terreno": "Poco esigente, preferisce i terreni argillosi e ricchi in humus"}$t$::jsonb,
  ARRAY[$t$Afidi e funghi possono attaccare i rami e le foglie provocandone il rossore a corimbo e poi la caduta delle foglie$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "solo di risanamento, si consiglia la rimozione dei rami che tendono a fuoriuscire dalla chioma"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "necessita di normali concimazioni"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Malus, p. 606$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Melia$t$,
  $t$Melia$t$,
  $t$melia$t$,
  $t$Meliaceae$t$,
  $t$perenne$t$,
  $t$Albero dei rosari, arborea caducifoglia, originaria dell'India e della Cina, con portamento arboreo e chioma tondeggiante, molto rapida e leggera. Mediamente alta 10-12 m, ma può raggiungere anche i 15 m. Ha il fusto diritto che ramifica molto in alto, con corteccia liscia e grigio-verdastra, con margini dentati e imparipennate, sono di colore verde vivo. La Melia presenta infiorescenze in pannocchie con piccoli fiori di colore lilla-violaceo con margini striati di bianco. I suoi fiori viola scuro producono piccoli frutti tondeggianti color verde scuro, che a maturazione, si trasforma in giallo-ocra.$t$,
  $t${"luce": "Poco esigente il terreno, soffre i substrati compatti e asfittici", "terreno": "Poco esigente, soffre i substrati compatti e asfittici"}$t$::jsonb,
  ARRAY[$t$Le radici, il legno e la vegetazione possono essere soggetti ad attacchi di tipo fungino$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "solo di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "le concimazioni non sono necessarie"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Melia, p. 607$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Paulownia$t$,
  $t$Paulownia$t$,
  $t$paulownia$t$,
  $t$Scrophulariaceae$t$,
  $t$perenne$t$,
  $t$Arborea caducifoglia di origine cinese, con chioma globosa, regolare, tendenzialmente molto rada. Ha una crescita molto rapida ed è alta mediamente 7-8 m, ma può arrivare a un'altezza di 15 m. Il fusto è dritto e con cortec-cia grigio-verdastra, leggermente rugosa. Le foglie sono cuoriformi, in genere abbastanza grandi (anche più di 30 cm), con apice appuntito e margine intero. Il fogliame nella pagina superiore, mentre nella pagina inferiore diviene più chiaro. I fiori sono riuniti in infiorescenze lunghe circa 30 cm, di colore violaceo, ricoperte da una folta lanugine biancastra.$t$,
  $t${"luce": "Non è esigente, si sviluppa senza problemi in qualsiasi terreno, soffre solo quelli asfittici", "terreno": "Non è esigente, si sviluppa senza problemi in qualsiasi terreno, soffre solo quelli asfittici"}$t$::jsonb,
  ARRAY[$t$La paulownia è rara-mente attaccata da parassiti e da malattie$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "necessita solo di potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "interrare al piede della pianta all'inizio della primavera del concime organico maturo"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Paulownia, p. 608$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
