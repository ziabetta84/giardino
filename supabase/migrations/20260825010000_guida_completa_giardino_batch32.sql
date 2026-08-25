-- Fase 3, trentaduesimo batch da guida-completa-giardino (pp. 528-533):
-- Polygonum, Pyracantha, Wisteria — chiude il capitolo "Arbusti Rampicanti".

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Polygonum$t$,
  $t$Polygonum$t$,
  $t$polygonum$t$,
  $t$Polygonaceae$t$,
  $t$perenne$t$,
  $t$Poligono, genere ricco di specie di piante erbacee perenni, annuali e di rampicanti suffruticosi, a foglie decidue, con numerosi piccoli fiori. Due specie rampicanti utilizzate: Polygonum baldschuanicum (originario delle regioni del mar Nero, detto "rampicante espresso" per la rapidità di sviluppo, fiori rosa pallido o bianchi da luglio a settembre) e Polygonum multiflorum (area cino-giapponese, foglie verde pallido lucide, fiori rosa pallido o bianchi da inizio luglio a fine settembre).$t$,
  $t${"luce": "Esposizioni a mezz'ombra o a pieno sole", "acqua": "Annaffiare solo se necessario, in particolare nel periodo marzo-tardo autunno", "terreno": "Senza particolari esigenze, preferisce terreni freschi e fertili, cresce bene anche in quelli fortemente calcarei"}$t$::jsonb,
  ARRAY[$t$Non si segnalano danni particolari provocati da crittogame o fitofagi$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "in marzo-aprile si taglia il Polygonum multiflorum a 30 cm dal livello del terreno; la vegetazione vigorosa del baldschuanicum richiede uno sfoltimento periodico per contenerne lo sviluppo entro i 5-6 m"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Polygonum, p. 528-529$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Pyracantha$t$,
  $t$Pyracantha$t$,
  $t$pyracantha$t$,
  $t$Rosaceae$t$,
  $t$perenne$t$,
  $t$Stupendi arbusti spinosi rustici o semirustici originari dell'areale mediterraneo, dell'Asia Minore e della Cina. Coltivati per l'abbondante fioritura primaverile ma soprattutto per i piccoli grappoli di pittoreschi frutti rossi, arancioni o gialli che addobbano la pianta per tutta la stagione invernale. Specie note: Pyracantha coccinea, detta "roveto ardente" (fiori bianchi, bacche rosso vivace) e Pyracantha angustifolia (fiori bianco-crema, bacche arancione).$t$,
  $t${"luce": "Tollera sia il pieno sole sia la leggera ombra", "acqua": "Annaffiature normali, più intense in caso di andamento stagionale siccitoso", "terreno": "Nessuna esigenza particolare, eccettuata la scarsa adattabilità a quelli eccessivamente calcarei; possibilmente non troppo pesante"}$t$::jsonb,
  ARRAY[$t$Soggette ad attacchi di malattie fungine, in particolare ticchiolatura e ruggine$t$, $t$I giovani getti possono essere attaccati anche da afidi lanosi: intervenire subito con anticrittogamici e insetticidi specifici$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "regolare le piante a fine inverno e cimarle in maggio-giugno; in primavera/estate ridurre i fusti più lunghi contro i muri, eliminare annualmente i rami vecchi mantenendo i getti giovani; potatura di riforma a marzo, tagliando tutti i tronchi raso terra"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "pacciamare con letame ultramaturo o torba"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Pyracantha, p. 530-531$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Wisteria$t$,
  $t$Wisteria$t$,
  $t$wisteria$t$,
  $t$Leguminosae$t$,
  $t$perenne$t$,
  $t$Glicine, tra i più attraenti arbusti rampicanti decidui, originarie di Cina, Giappone e Nordamerica, piante rustiche e vigorose con foglie composte imparipennate. Fiori profumati riuniti in racemi, colori dal blu-viola al lillà, al rosato, al bianco. Specie note: Wisteria sinensis (vigorosa, fiori più grandi e fitti, sbocciano insieme sullo stesso grappolo) e Wisteria floribunda (fioritura abbondante ma più tardiva).$t$,
  $t${"luce": "Gradiscono sia esposizioni soleggiate sia quelle in leggera ombra", "acqua": "Annaffiare normalmente, aumentando gli apporti in caso di periodi siccitosi", "terreno": "Nessuna esigenza particolare, purché non eccessivamente calcareo; quelli migliori sono freschi e profondi"}$t$::jsonb,
  ARRAY[$t$La clorosi (ingiallimento fogliare) si combatte somministrando al terreno chelati di ferro$t$, $t$Proteggere con reti i germogli in caso di attacchi da parte degli uccelli$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": "riduzione dei nuovi getti laterali a circa 15 cm", "autunno": null, "inverno": "accorciamento degli stessi getti a 2-3 gemme dalla base", "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "concime polivalente", "autunno": null, "inverno": null, "primavera": "concime polivalente"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Wisteria, p. 532-533$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
