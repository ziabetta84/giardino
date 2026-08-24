-- Fase 3, quindicesimo batch da guida-completa-giardino (pp. 388-395,
-- "Piante Ornamentali"): Iris, Lilium, Lobelia, Muscari, Myosotis.
-- Hydrangea, Matthiola, Narcissus saltate: gia' possedute e verificate via
-- RHS. iris-spontaneo posseduto e' in realta' Sisyrinchium californicus,
-- genere diverso da Iris: nessun conflitto.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Iris$t$,
  $t$Iris$t$,
  $t$iris$t$,
  $t$Iridaceae$t$,
  $t$perenne$t$,
  $t$Pianta rizomatosa con fiori eleganti su lunghi steli rigidi, 6 petali setosi e vellutati (3 superiori saldati a formare un vessillo, 3 inferiori ad ali). Uno stesso stelo porta più fiori in successione. Foglie a spada, rigide, erette, verde chiaro. Colore: tutti tranne il rosso brillante. Uso: bordure di vialetti e scale; varietà nane per balconi, terrazze, giardini rocciosi.$t$,
  $t${"luce": "Pieno sole", "acqua": "Poche annaffiature prima della fioritura, più abbondanti in prossimità e durante l'antesi"}$t$::jsonb,
  ARRAY[$t$Non soggetta a malattie o parassiti particolari$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Iris, p. 389$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Lilium$t$,
  $t$Lilium$t$,
  $t$lilium$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Giglio, bulbosa perenne molto rustica, coltivabile in ogni ambiente climatico, altezza 50 cm - 1,5 m. Fiori imbutiformi, a volte con petali retroflessi, riuniti in infiorescenze terminali lasse, fioriscono in estate. Foglie lanceolate. Colore: classico bianco candido, esistono specie monocromatiche gialle, rosse, porpora, arancio, rosa, o striate/bordate. Uso: fiore reciso, vaso per balconi e terrazzi.$t$,
  $t${"luce": "Posizione ideale a mezz'ombra", "acqua": "Abbondanza d'acqua, senza creare ristagni idrici", "terreno": "Leggero, fresco, ricco di sostanza organica"}$t$::jsonb,
  ARRAY[$t$Nemico principale: Lilioceris lilii (coleottero) che attacca le parti aeree — eliminare raccogliendo manualmente uova e adulti$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Lilium, p. 390$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Lobelia$t$,
  $t$Lobelia$t$,
  $t$lobelia$t$,
  $t$Campanulaceae$t$,
  $t$annuale$t$,
  $t$Pianta erbacea annuale di piccole dimensioni (non supera i 20 cm), alcune specie perenni a carattere arbustivo. Fiori piccoli e numerosissimi, foglie alterne obovate o ellittiche. Fiorisce da aprile all'autunno inoltrato. Colore: blu brillante (L. erinus) il più caratteristico, anche scarlatto (cardinalis), rosa-lilla (holstii), rosso-porpora (fulgens), bianco (erinus White Gem). Uso: aiuole e bordure, vaso su terrazzi e balconi per la vegetazione ricadente.$t$,
  $t${"luce": "Mezz'ombra, tollera anche zone soleggiate con luce diffusa mai diretta", "acqua": "Irrigazioni regolari, quotidiane", "terreno": "Fertile, soffice, che mantenga bene l'umidità"}$t$::jsonb,
  ARRAY[$t$Soffre di marciumi radicali in luoghi troppo umidi$t$, $t$Molto sensibile al freddo, predilige climi freschi con piogge uniformi$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Lobelia, p. 391$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Muscari$t$,
  $t$Muscari$t$,
  $t$muscari$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Bulbosa perenne di ridotte dimensioni (max 25 cm), infiorescenze erette e compatte di fiori tubulari-tondeggianti, gradevolmente profumati. Fiorisce in primavera da marzo a giugno secondo varietà. Foglie nastriformi, carnose, verde chiaro. Colore: più diffuso azzurro o violaceo, anche bianco e giallo brillante, o giallo-verdastro molto profumato. Uso: giardini rocciosi, piccole aiuole, bordure, vasi e ciotole.$t$,
  $t${"luce": "Pieno sole o mezz'ombra"}$t$::jsonb,
  ARRAY[$t$A volte soggetta a problemi di muffa$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Muscari, p. 393$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Myosotis$t$,
  $t$Myosotis$t$,
  $t$myosotis$t$,
  $t$Boraginaceae$t$,
  $t$biennale$t$,
  $t$Non ti scordar di me, genere biennale o perenne a seconda della specie, fusti eretti, foglie alterne oblungo-lanceolate. Fiori numerosi e piccoli, riuniti in infiorescenze scorpioidi. Specie diffuse: alpestris, sylvatica, palustris, rupicola (da roccia). Colore: azzurro, raramente bianco o roseo. Uso: vaso e cassette su balconi e terrazzi.$t$,
  $t${"luce": "Posizioni mediamente ombrose", "acqua": "Annaffiature frequenti", "terreno": "Fertile, soffice, umido, ricco di humus, posizioni riparate"}$t$::jsonb,
  ARRAY[$t$Soffre per attacchi di afidi e oidio, contro l'oidio trattamenti a base di zolfo$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Myosotis, p. 394$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
