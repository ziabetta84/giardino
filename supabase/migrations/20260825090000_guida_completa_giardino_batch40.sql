-- Fase 3, quarantesimo batch da guida-completa-giardino (pp. 596-603,
-- "Alberi Sempreverdi e Caducifogli"): arricchisce Fagus, Ginkgo biloba,
-- Larix decidua (manutenzione vuota) con la scheda dedicata piu' ricca di
-- questa pagina; inserisce Laburnum, Liquidambar. Eucalyptus e Fraxinus
-- excelsior saltati: gia' arricchiti dalla stessa fonte in un batch
-- precedente (stesso genere, nessun contenuto realmente nuovo da questa
-- pagina piu' dettagliata).

update specie set
  alert = alert || ARRAY[$t$Le coccinìglie sono soggette all'attacco delle larve dei punteruoli che infestano le foglie; la famigliola (fungo) può provocare la rapida morte della pianta$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "il faggio rifugge sia i climi secchi sia quelli rigidi, necessita di elevata umidità"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "abbondanti"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "normali concimazioni"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Fagus, p. 597-599$t$)
where slug = $t$fagus$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Fagus, p. 597-599$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Molto resistente ai parassiti e alle malattie, raramente viene colpito$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "richiede soltanto potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non ha bisogno di concimazioni particolari"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Ginkgo biloba, p. 600$t$)
where slug = $t$ginkgo-biloba$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Ginkgo biloba, p. 600$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Può subire l'attacco di afidi e da funghi che ne danneggiano il legno$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "necessita di potature di mantenimento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": "si consiglia di arricchire il terreno con concime maturo ogni primavera-autunno, interrandolo ai piedi della pianta", "primavera": "si consiglia di arricchire il terreno con concime maturo ogni primavera-autunno, interrandolo ai piedi della pianta"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Larix decidua, p. 602$t$)
where slug = $t$larix-decidua$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Larix decidua, p. 602$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Laburnum$t$,
  $t$Laburnum$t$,
  $t$laburnum$t$,
  $t$Leguminosae$t$,
  $t$perenne$t$,
  $t$Maggiociondolo, arborea caducifoglia di piccole dimensioni originaria dell'Europa centro-meridionale, con chioma espansa, irregolare, e ramoscelli giovani penduli. Ha una altezza media di 5-6 m e cresce velocemente. Le foglie sono trifogliate, di colore verde brillante, glauche nella pagina inferiore, con margine intero, arrotondate in punta. I fiori sono riuniti in racemi penduli, lunghe anche più di 20 cm, di colore giallo dorato, fiorisce in tarda primavera.$t$,
  $t${"luce": "Predilige i terreni calcarei. Poiché è molto rustica, sopporta bene anche quelli sabbiosi e umidi", "terreno": "Predilige i terreni calcarei, sopporta bene anche quelli sabbiosi e umidi"}$t$::jsonb,
  ARRAY[$t$Tutti i semi sono velenosi; le foglie e i rami tendono a seccare prematuramente in primavera e a non aprirsi, la pianta è stata colpita dalla famigliola, fungo che porta al marciume radicale e quindi alla morte$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "richiede solo potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non sono necessarie concimazioni"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Laburnum, p. 601$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Liquidambar$t$,
  $t$Liquidambar$t$,
  $t$liquidambar$t$,
  $t$Hamamelidaceae$t$,
  $t$perenne$t$,
  $t$Albero a foglia caduca e l'unica conifera caduche. Originario del Nord America, ha una crescita mediamente lenta, ma è una pianta longeva, molto longeva, ha la chioma rada e leggera, di colore verde chiaro in primavera-estate, poi dorata e di colore marrone-rossastra in autunno. Le foglie sono squamose, di forma triangolare, sovrapposte e con apice spinoso.$t$,
  $t${"luce": "Poco esigente, ma teme gli eccessi di calcare. Sopporta i terreni argillosi, profondi e umidi", "terreno": "Una buona concimazione e il segreto per avere le meravigliose colorazioni autunnali del fogliame"}$t$::jsonb,
  ARRAY[$t$Nessuna particolare avversità di rilievo$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "occorre rimuovere i rami morti o danneggiati"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "una buona concimazione è il segreto per avere le meravigliose colorazioni autunnali del fogliame"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Liquidambar, p. 603$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
