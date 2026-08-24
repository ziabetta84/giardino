-- Fase 3, trentesimo batch da guida-completa-giardino (pp. 512-519,
-- "Arbusti Rampicanti"): Campsis, Clematis (genere, distinto dalla
-- posseduta clematis-montana), Hedera, Ipomoea. Formato ricco con sezioni
-- Terreno/Impianto/Cure colturali/Potatura/Moltiplicazione/Avversità.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Campsis$t$,
  $t$Campsis$t$,
  $t$campsis$t$,
  $t$Bignoniaceae$t$,
  $t$perenne$t$,
  $t$Arbusti rampicanti vigorosi, decidui, a fogliame due specie principali radicanti: la Campsis chiamata comunemente gelsomino della Virginia, originaria del Nordamerica, e la Campsis grandiflora, originaria della Cina, un po' meno rustica, meno vigorosa. Foglie opposte, pennate, di verde intenso. Fiori a tromba riuniti in pannocchie all'estremità dei rami di un anno.$t$,
  $t${"luce": "Pieno sole, dove il muro esposto a sud-ovest", "acqua": "Annaffiature normali, abbondanti dopo la messa a dimora e nella fase d'impianto"}$t$::jsonb,
  ARRAY[$t$Lunghi periodi di siccità possono causare la caduta dei boccioli$t$, $t$Radicans è più resistente al freddo della grandiflora, che va difesa in inverno con protezioni contro le gelate$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": "dopo la messa a riposo, tralci principali accorciati a circa 15 cm dal legno vecchio", "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": "concimare da novembre a marzo con letame ultramaturo o concime organico a base di corno", "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Campsis, p. 512-513$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Clematis$t$,
  $t$Clematis$t$,
  $t$clematis$t$,
  $t$Ranunculaceae$t$,
  $t$perenne$t$,
  $t$Genere originario di Europa, Asia e America, con un buon numero di specie e numerosissime ibridi. Alcune decidue, altre sempreverdi, sono ottime rampicanti da impiegare su pergolati, muri, alberi. Fiori a colpi di colore, a volte in gruppi (grandi e piccoli), la specie a fiore di massima dimensione si possono dividere in due gruppi: le specie a fioritura precoce (primavera-estate) e il gruppo degli ibridi a grandi fiori che fioriscono in primavera-estate.$t$,
  $t${"luce": "Ama la luce, benché l'apparato radicale preferisca stare in zona ombreggiata o disposto a raccogliere il sole o in leggera ombra", "acqua": "Annaffiature consistenti in caso di andamenti stagionali siccitosi", "terreno": "Predilige quelli acidi, freschi, poco compatti, profondi e fertili"}$t$::jsonb,
  ARRAY[$t$Il freddo può danneggiare le specie meno resistenti, gli afidi possono attaccare gli apici$t$, $t$Le lumache possono distruggere i germogli$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "leggera per gli ibridi a grandi fiori del primo gruppo, severa (rami tagliati a 20-30 cm dal suolo) per il gruppo che fiorisce sui getti dell'anno"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Clematis, p. 514-515$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Hedera$t$,
  $t$Hedera$t$,
  $t$hedera$t$,
  $t$Araliaceae$t$,
  $t$perenne$t$,
  $t$Edera, di origine europea, genere con poche specie ma numerosissime varietà. Rampicante o ricadente, può essere usata anche in appartamento. Specie note: Hedera helix, Hedera canariensis (grandi foglie), Hedera helix Chicago e Lutzii, Hedera canariensis Gold Diamond (foglie screziate di bianco o giallo).$t$,
  $t${"luce": "Ha bisogno di luce viva, ma non diretta, si scolorirebbero le foglie; si adatta anche in luoghi con luce diffusa", "acqua": "Annaffiature 1-2 volte a settimana in estate, poca cura d'inverno lasciando asciugare il terriccio prima di annaffiare ancora", "terreno": "Non ha particolare esigenza, tollera anche quelli torbosi poveri, meglio se miscelata con foglie inumidita"}$t$::jsonb,
  ARRAY[$t$Foglie che si seccano: ambiente troppo secco e caldo$t$, $t$Foglie che diventano nere: eccesso d'acqua$t$, $t$Presenza di insetti verdi sulle foglie: afidi (pidocchi)$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": "cimatura estiva se fuoriescono troppo lunghi i rami, per limitarne lo sviluppo e favorire nuovi getti", "autunno": null, "inverno": null, "primavera": "sfoltimento leggero"}, "irrigazione": {"estate": "1-2 volte a settimana, nebulizzare le foglie quotidianamente se il clima supera i 18°C", "autunno": null, "inverno": "ridotta, lasciare asciugare il terriccio", "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Hedera, p. 516-517$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Ipomoea$t$,
  $t$Ipomoea$t$,
  $t$ipomoea$t$,
  $t$Convolvulaceae$t$,
  $t$annuale$t$,
  $t$Genere ricco di specie annuali, perenni, rampicanti e semiarbustici, delicati e semirustici, originario delle regioni calde di due emisferi. Il fusto è volubile o rampicante, con foglie alterne, grandi, sagomate, varia forma di grandi dimensioni. I fiori compaiono in estate-autunno, comuni in colori loro smaglianti, dal bianco al rosso, il porporino e il bianco al blu, con diverse tonalità volubili ben sviluppati e possono coprire in vaso e su terrazzi. Le specie più coltivate sono l'Ipomoea rubro-coerulea e l'Ipomoea purpurea.$t$,
  $t${"luce": "Posizioni riparate e soleggiate (preferite), ma coltivate anche con successo in zone parzialmente ombreggiate", "acqua": "Annaffiature quotidiane frequenti, in tempo asciutto e caldo non troppo abbondanti"}$t$::jsonb,
  ARRAY[$t$Parassiti pericolosi per la campanella rampicante sono afidi, tripidi e ragnetto rosso: causano l'infestazione dei fitofagi$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "eliminando il trapianto e prolungando la fioritura"}, "irrigazione": {"estate": "annaffiature quotidiane frequenti", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimazioni liquide settimanali, a cominciare da giugno con concime liquido con potassio"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Ipomoea, p. 518-519$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
