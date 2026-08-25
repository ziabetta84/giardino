-- Fase 3, trentottesimo batch da guida-completa-giardino (pp. 580-587,
-- "Alberi Sempreverdi e Caducifogli"): arricchisce Acer negundo, Acer
-- palmatum, Aesculus hippocastanum (bozza PFAF, manutenzione vuota);
-- inserisce Albizzia, Alnus, Araucaria. Acacia saltata: gia' posseduta e
-- verificata via RHS.

update specie set
  alert = alert || ARRAY[$t$Soggetto a oidio o mal bianco: le foglie si decolorano e si rivestono di una muffa bianca che ne provoca la caduta$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "normali, la pianta non soffre le zone a mezz'ombra"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Acer negundo, p. 582$t$)
where slug = $t$acer-negundo$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Acer negundo, p. 582$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Soggetto agli attacchi del ragnetto rosso (acaro che punge le foglie per succhiarne la linfa) e della coccinìglia$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "ha bisogno solo di potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "non necessita cure particolari, è sufficiente concimarlo normalmente"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Acer palmatum, p. 583$t$)
where slug = $t$acer-palmatum$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Acer palmatum, p. 583$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Le coccinìglie possono formare colonie sui rami e sul tronco, provocando la comparsa di macchie che a volte compaiono a colonie sulle foglie, che a volte fogliari che provocano l'essiccamento di tutta la foglia$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "eliminare le parti danneggiate"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimarlo con concime ternario"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Aesculus hippocastanum, p. 584$t$)
where slug = $t$aesculus-hippocastanum$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Aesculus hippocastanum, p. 584$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Albizzia$t$,
  $t$Albizzia$t$,
  $t$albizzia$t$,
  $t$Leguminosae$t$,
  $t$perenne$t$,
  $t$Albero caducifoglio proveniente dall'Asia occidentale, caratterizzata da chioma ombrelliforme con rami contorti, molto ramificati, dalla chioma espansa e ramificazioni orizzontali da cui possono comparire radi ramoscelli. È alta mediamente 10-12 m e ha il fusto diritto, con corteccia liscia e di colore grigio-verde intenso. Le foglie sono composte da molti fogliolini sessili, di forma tondeggiante quasi bipennate. I fiori sono riuniti in pannocchie bipennate, superano i leggerissime, sono composte e si chiudono durante la notte. Le infiorescenze sono formate da stami lunghissimi con colore che varia in rosa, crema o globulare. Il colore varia dal rosa al crema, e compaiono in racemi durante l'estate.$t$,
  $t${"luce": "Non è molto resistente al freddo. Richiede posizioni soleggiate in pieno sole; i rami morti o danneggiati", "terreno": "Predilige terreni leggeri, tollera i calcarei, ma è sensibile ai calcarei"}$t$::jsonb,
  ARRAY[$t$Il gelo prolungato può causare gravi danni e persino la morte$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "è sufficiente rimuovere i rami morti o danneggiati"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimazioni regolari"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Albizzia, p. 585$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Alnus$t$,
  $t$Alnus$t$,
  $t$alnus$t$,
  $t$Betulaceae$t$,
  $t$perenne$t$,
  $t$Ontano, pianta originaria delle regioni dell'Asia e del Nordamerica, che può raggiungere i 25 m di altezza. Si adatta bene a qualsiasi tipo di terreno, predilige quelli sassosi, poveri di materiale organico. I fiori maschili appaiono all'inizio dell'inverno, per svilupparsi successivamente, prima della comparsa delle foglie, primaverile; i fiori femminili appaiono all'inizio dell'inverno, per svilupparsi successivamente, con la primavera successiva. Le foglie sono di colore verde brillante, di forma dentato al margine, molto irregolarmente arrotondate, con margine dentato a secondo delle specie, di colore verde intenso e lucido.$t$,
  $t${"luce": "Sopporta bene le basse temperature", "acqua": "Necessita di posizioni soleggiate sia le basse che le alte temperature", "terreno": "Si adatta bene a qualsiasi tipo di terreno, predilige quelli sassosi, poveri di materiale organico"}$t$::jsonb,
  ARRAY[$t$Può essere infastidita dall'attacco di afidi, lontano dall'ombra di altri alberi$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "non necessita di particolari potature, è sufficiente spuntare i rami secchi o danneggiati"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "quando necessario"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Alnus, p. 586$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Araucaria$t$,
  $t$Araucaria$t$,
  $t$araucaria$t$,
  $t$Araucariaceae$t$,
  $t$perenne$t$,
  $t$Araucaria o Pino del Cile, arborea sempreverde, originaria delle zone meridionali del Cile e dell'Argentina, con portamento colonnare e ramificazioni rade, con impalcature la cui cazione la parte re-golari che caratterizzano la pian-ta. È alta circa 20 m e ha il fusto diritto, con corteccia verde-bruna molto rugosa. Le foglie sono squamose, triangolari, lunghe circa 3-4 cm, sovrapposte e con apice spino-so. I fiori si trovano all'estremità dei rami, sono allungati e di forma squamosa; quelli maschili e di forma spinosa, sono allungati e di forma squamosa e conica quelli femminili, globosi e verdi quelli maschili e di forma conica quelli femminili.$t$,
  $t${"luce": "Resiste bene anche al freddo", "terreno": "Non sopporta i terreni troppo compatti"}$t$::jsonb,
  ARRAY[$t$Non necessita di particolari cure per la coltivazione; per la concimazione utilizzare concime ternario$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "sono sufficienti interventi di particolari cure; per la potatura sono sufficienti interventi minimi"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concime ternario"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Araucaria, p. 587$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
