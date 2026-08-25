-- Fase 3, trentatreesimo batch da guida-completa-giardino (pp. 536-543,
-- nuovo capitolo "Piante Arbustacee"): Amelanchier, Caryopteris, Cistus.
-- Camellia saltata: gia' posseduta (camelia) e verificata via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Amelanchier$t$,
  $t$Amelanchier$t$,
  $t$amelanchier$t$,
  $t$Rosaceae$t$,
  $t$perenne$t$,
  $t$Genere che comprende diverse specie, originarie di Canada e Nordamerica, ma anche di Asia ed Europa. Si tratta di arbusti spoglianti, alti e decorativi, dalle foglie alterne e rotondeggianti, ovali, tomentose. Generalmente sono bianchi, e compaiono i fiori sui rami spogli, talvolta rosati, in primavera. Specie note: Amelanchier canadensis (raggiunge altezze di circa 3 m) e Amelanchier grandiflora (ibrido a buona resistenza al freddo, dimostrano problemi anche negli inverni più freddi).$t$,
  $t${"luce": "Gradisce posizioni particolarmente soleggiate, che favoriscono la fioritura; non si sviluppa molto bene in zone semiombreggiate, ma cresce anche in ombra", "acqua": "Eventuali annaffiature sono consigliate solo quando il terreno è ben asciutto", "terreno": "Preferiscono piante piuttosto rustiche, non abbisogna di particolari cure se non quelle normalmente dedicate alla maggior parte delle piante"}$t$::jsonb,
  ARRAY[$t$Non presenta particolari predisposizioni ad attacchi parassitari. Nel caso si verifichino si consiglia di intervenire con prodotti specifici$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "severa, praticata dopo la fioritura; i cespugli troppo fitti vanno sfoltiti eliminando annualmente i rami più vecchi e accorciati dagli apici, per formare rami laterali"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Amelanchier, p. 536-537$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Caryopteris$t$,
  $t$Caryopteris$t$,
  $t$caryopteris$t$,
  $t$Verbenaceae$t$,
  $t$perenne$t$,
  $t$Originaria dell'Asia orientale, arbusto rustico e deciduo, apprezzato soprattutto per il fogliame aromatico ai fini dei fiori di colore azzurro-lavanda, riuniti in fitti glomeruli all'ascella delle foglie fino agli inizi dell'autunno. Le foglie, verde grigiastro, con margine dentellato o meno pelose, emettono un profumo balsamico se schiacciate. Specie nota: Caryopteris mastacanthus (fiori blu-violetto, la mongolica con fiori blu e foglie intere; la clandonensis, ibrido con fiori di un colore blu vivace).$t$,
  $t${"luce": "Dimostra una buona resistenza al freddo. Nelle regioni a clima rigido è d'obbligo piantarla al riparo di un muro", "acqua": "Abbisogna di normali annaffiature, soprattutto durante l'estate", "terreno": "Non dimostra particolari esigenze, preferisce però i terreni argillosi e torbosi, con aggiunta di sabbia, molto permeabili"}$t$::jsonb,
  ARRAY[$t$È in genere una pianta molto rustica, che non presenta debolezze nei confronti di deterioramenti né particolari difficoltà di coltivazione$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "si interviene all'inizio della primavera, a fine marzo, a seconda del clima, tagliando drasticamente quelle legnose levate nei primi mesi dell'anno"}, "irrigazione": {"estate": "normali annaffiature, soprattutto durante l'estate", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimare per favorire la ripresa vegetativa e la fioritura, con letame maturo o concime potassico"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Caryopteris, p. 540-541$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Cistus$t$,
  $t$Cistus$t$,
  $t$cistus$t$,
  $t$Cistaceae$t$,
  $t$perenne$t$,
  $t$Cisto, originari delle regioni mediterranee e delle Canarie, arbusti sempreverdi con foglie opposte, intere, diverse nella forma e nella grandezza in base alla specie. I fiori sono grandi, a cinque petali, di colore diverso: rosa, bianchi, gialli, lilla, porporini di marrone o rosso, spesso punteggiati di colore diverso. Fioritura in primavera-estate. Specie note: il Cistus laurifolius (fiori bianchi con macchia gialla) e il Cistus villosus (fiori magenta a unghia gialla).$t$,
  $t${"luce": "Predilige posizioni soleggiate e quindi i climi meridionali. Ha infatti una moderata resistenza al freddo, tanto da richiedere protezioni durante la stagione invernale", "acqua": "Non tollera i ristagni d'acqua, anzi predilige i terreni ben drenati e che si asciughino con una certa facilità", "terreno": "Gradisce suoli ben drenati, poveri di calcio, privi di ristagni, anche asciutti"}$t$::jsonb,
  ARRAY[$t$Il pericolo principale è rappresentato dalle gelate, che possono danneggiare le cime dei getti giovani. In tal caso andranno eliminati in primavera, eliminando i rami morti o a spuntare, dopo la fioritura$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "non si attua se non in forma assai ridotta, limitandosi a spezzati dopo la fioritura, i getti assai morti o a spuntare, dopo la fioritura, nel caso si formino, per facilitare la ripresa vegetativa"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Cistus, p. 542-543$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
