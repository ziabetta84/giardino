-- Fase 3, quarantaduesimo e ultimo batch da guida-completa-giardino
-- (pp. 612-619, chiude "Alberi Sempreverdi e Caducifogli" e l'intero
-- libro): arricchisce Pinus pinaster, Pinus sylvestris, Populus alba,
-- Quercus rubra (bozza PFAF, manutenzione vuota); inserisce Platanus.
-- Prunus (genere) e Quercus (genere) saltati: decine di specie
-- specifiche PFAF gia' presenti per entrambi senza una dominante chiara,
-- stesso motivo di Crataegus/Tilia/Ulmus in un batch precedente.

update specie set
  alert = alert || ARRAY[$t$Se la pianta deperisce, gli aghi diventano rossastri e poi cadono, siete in presenza del pissode del pino$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "non richiede molti interventi, ma soltanto tagli di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimarlo normalmente"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Pinus pinaster, p. 612$t$)
where slug = $t$pinus-pinaster$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Pinus pinaster, p. 612$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Tende a spogliarsi nei palchi più bassi se ombreggiata, se troppo irrigata oppure se coltivata in climi troppo caldi e stagni idrici$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "si deve effettuare periodicamente l'eliminazione dei rami secchi"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "deve essere concimata normalmente"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Pinus sylvestris, p. 613$t$)
where slug = $t$pinus-sylvestris$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Pinus sylvestris, p. 613$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$La larva del punteruolo scava gallerie nei rami provocando l'essiccamento delle piante più deboli; l'afide lanigero rivestendoli di una sostanza fioccosa$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "devono essere effettuate solo potature di risanamento e spollonature"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "utilizzare del concime organico"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Populus alba, p. 615$t$)
where slug = $t$populus-alba$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Populus alba, p. 615$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Soggetta all'oidio (macchie bianche sulle foglie, trattare con antioidici a base di zolfo)$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "sono sufficienti potature di risanamento"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimazione normale"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Quercus rubra, p. 619$t$)
where slug = $t$quercus-rubra$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Quercus rubra, p. 619$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Platanus$t$,
  $t$Platanus$t$,
  $t$platanus$t$,
  $t$Platanaceae$t$,
  $t$perenne$t$,
  $t$Platano, pianta di grandi dimensioni, molto longeva, originaria dell'America settentrionale e delle regioni asiatiche (P. orientalis), molto diffusa in Italia nelle prime zone collinari. La chioma ha portamento tondeggiante e colonnare. Il tronco raggiunge grandi dimensioni, di colore verde grigio, si presenta a grandi placche verde chiaro che virano al giallo oro in autunno. Le foglie sono ampie, con nervature evidenti, costituite da 5-7 lobi tondi, di colore verde chiaro che virano al giallo oro in autunno. Caratteristiche sono le infruttescenze, tonde, lungamente peduncolate a forma di riccio.$t$,
  $t${"luce": "Ama la luce e le posizioni lungamente soleggiate", "acqua": "Tollera consistenti sbalzi di temperatura nei riguardi dei geli invernali e dei caldi estivi", "terreno": "Ama i terreni profondi, ricchi di sostanza organica, sia carei che argillosi"}$t$::jsonb,
  ARRAY[$t$Gli esemplari giovani vengono colpite dalla ruggine e dal mal bianco; gli esemplari adulti difficilmente sono colpiti da parassiti o malattie$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "viene effettuata una volta o due all'anno"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "utilizzare del concime organico"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Platanus, p. 614$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
