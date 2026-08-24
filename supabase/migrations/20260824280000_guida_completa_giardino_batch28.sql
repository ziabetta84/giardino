-- Fase 3, ventottesimo batch da guida-completa-giardino (pp. 494-501,
-- "Piante Grasse"): Myrtillocactus, Neoporteria, Notocactus, Opuntia,
-- Oreocereus.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Myrtillocactus$t$,
  $t$Myrtillocactus$t$,
  $t$myrtillocactus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere con una sola specie, Myrtillocactus geometrizans, originario del Messico centrale, con aspetto di un piccolo albero dal fusto breve che ramifica molto vicino al suolo. Raggiunge un'altezza massima di 4 metri. Coltivata in vaso raggiunge al massimo 1,5 m. Fusti lisci, di colore verde-azzurro, con 5-6 coste sulle quali compaiono distanziate le areole e con spine brevissime. Fiori bianchi profumati; frutti simili a mirtilli commestibili, usati come portainnesti.$t$,
  $t${"luce": "Molta luce diretta del sole", "acqua": "Concimare una volta all'anno, in primavera"}$t$::jsonb,
  ARRAY[$t$Marcisce facilmente d'inverno se necessita di poca umidità atmosferica: gradisce la luce diretta dal sole e le temperature dai 10°C ai 30°C$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Myrtillocactus, p. 494-495$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Neoporteria$t$,
  $t$Neoporteria$t$,
  $t$neoporteria$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Piccole piante cilene, di origini andine. Hanno fusto di forma globulare che si sviluppa diventando cilindrico, con coste da cui si dipartono diritte e rilevate quasi sempre molli ciuffi di spine dritte e rilevate, morbide e lunghe.$t$,
  $t${"luce": "Poche, hanno bisogno di buona luminosità, tuttavia è meglio filtrare la luce diretta del sole"}$t$::jsonb,
  ARRAY[$t$Piante delicate: sopportano temperature piuttosto basse (4-7°C) ma solo se l'umidità è scarsa$t$, $t$Necessitano di poche annaffiature, ma regolari$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Neoporteria, p. 495$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Notocactus$t$,
  $t$Notocactus$t$,
  $t$notocactus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere di piante provenienti dalle praterie sudamericane, dalla forma globulare e poi cilindrica. Hanno le spine bianche corte e morbide che circondano una spina centrale più lunga e acuminata, a volte colorata. I fiori sono diurni e imbutiformi, spesso gialli. Specie note: N. haselbergii (globosa, 12 cm diametro, spine bianco-dorate, fiori arancione-rosso), N. ottonis (nano, fiori gialli), N. scopa (cilindrico, 30 coste, spine lanuginose bianche con ciuffi rosso-arancione), N. leninghausii (globulare poi cilindrico fino a 20 cm, spine bianco-gialle lunghe, fiori gialli), N. roseo-lutescens.$t$,
  $t${"luce": "Diverse ore al giorno di luce solare diretta, ma è meglio proteggerli dal sole cocente", "acqua": "Sopportano bene le basse temperature, poco tolleranti ai ristagni"}$t$::jsonb,
  ARRAY[$t$Non tollerano l'umidità eccessiva: il terriccio deve essere ben drenato$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Notocactus, p. 496-499$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Opuntia$t$,
  $t$Opuntia$t$,
  $t$opuntia$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere diffuso in tutta l'America, con poche specie tipiche delle zone desertiche fuse (dette articoli). Rami cilindrici o globosi, molto ramificati, oppure appiattiti a forma di pale (dette articoli). Areole con glochidi (piccoli e fastidiosi aculei microscopici, dotati di spine minuscole difficili da estrarre dalla pelle). Specie note: Opuntia ficus-indica (fico d'India, cespuglio o piccolo albero fino a 5 m, pale ovali coperte di glochidi, frutti commestibili), Opuntia microdasys (piccola, cespugliosa, fino a 1 m, spine gialle o pallide).$t$,
  $t${"luce": "Molte ore di luce brillante, meglio se diretta", "acqua": "Scarse annaffiature, soprattutto in inverno"}$t$::jsonb,
  ARRAY[$t$Non deve scendere sotto i 4°C, essendo piante di zone aride che vivono bene all'aperto dove la temperatura non scende sotto questa soglia$t$, $t$Necessario assicurarle molte ore di luce diretta$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Opuntia, p. 499-501$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Oreocereus$t$,
  $t$Oreocereus$t$,
  $t$oreocereus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$"Cactus delle Ande", piante di montagna, piuttosto piccole, colonnari o cespitose, con coste ingrossamenti in corrispondenza delle lunghe areole. Sono caratterizzati da una folta peluria che ricopre come una pelliccia più o meno fitta la parte superiore. Hanno 10-15 coste ricoperte da lunghi peli bianchi o biondi. Specie nota: Oreocereus celsianus (colonnare, ricoperta di peli bianchi o biondi più o meno fitti, con spine gialle o rosse dure che spuntano dalla peluria, fiori rossi).$t$,
  $t${"luce": "Molta luce brillante e anche del sole diretto"}$t$::jsonb,
  ARRAY[$t$Sopportano temperature molto basse, ma non del sole diretto che del sole più intenso che appesantiscono$t$, $t$Annaffiare poco (quasi nulla) durante la stagione invernale e i mesi più caldi$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Oreocereus, p. 501$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
