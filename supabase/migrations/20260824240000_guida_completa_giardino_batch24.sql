-- Fase 3, ventiquattresimo batch da guida-completa-giardino (pp. 470-477,
-- "Piante Grasse"): Coryphantha, Cotyledon, Crassula, Echinocereus,
-- Echinocactus. Echeveria saltata: gia' posseduta e verificata via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Coryphantha$t$,
  $t$Coryphantha$t$,
  $t$coryphantha$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario delle zone desertiche americane, simile alle Mammillaria ma con fiori che spuntano all'apice anziché attorno alla pianta. Ogni tubercolo reca un'areola con un ciuffo di spine disposte simmetricamente, fiori generalmente gialli. Specie nota: Coryphantha clavata (Stati Uniti meridionali, forma a clava fino a 30 cm, spine rosse o gialle, fiori gialli fino a 9 cm in estate).$t$,
  $t${"luce": "Molto sole", "acqua": "Poche annaffiature anche nei periodi più caldi, in inverno terriccio pressoché asciutto"}$t$::jsonb,
  ARRAY[$t$La temperatura non deve scendere assolutamente sotto i 4°C$t$, $t$Radici a fittone che scendono in profondità: necessita di contenitori adatti$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Coryphantha, p. 470-471$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Cotyledon$t$,
  $t$Cotyledon$t$,
  $t$cotyledon$t$,
  $t$Crassulaceae$t$,
  $t$perenne$t$,
  $t$Genere originario del Sudafrica, sempreverde, forma piccoli arbusti con fusti succulenti eretti molto ramificati (fino a 50 cm). Foglie pruinose, colorazione tra il verde e l'azzurro. Specie nota: Cotyledon orbiculata (fino a 80 cm, foglie ovali carnose grigio-verdi orlate di rosso, lungo ramo fiorifero con fiori a ombrello giallo-rossi in estate).$t$,
  $t${"luce": "Posizione molto luminosa", "acqua": "Scarse ma regolari, in inverno terriccio quasi completamente asciutto", "terreno": "Sabbioso e ben drenato"}$t$::jsonb,
  ARRAY[$t$Nessuna particolare difficoltà di coltivazione$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Cotyledon, p. 471$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Crassula$t$,
  $t$Crassula$t$,
  $t$crassula$t$,
  $t$Crassulaceae$t$,
  $t$perenne$t$,
  $t$Genere originario dell'Africa meridionale, arbusti di diverse dimensioni a foglie carnose. Specie diffuse: Crassula lactea (60 cm, foglioline ovali verde scuro con macchioline chiare, fiori bianchi profumati d'inverno), Crassula tetragona (rami eretti sottili, foglie cilindriche appuntite, fiori bianchi), Crassula portulacea (fusto nodoso fino a 2 m, foglie ovali margine rosso, spesso confusa con la arborescens), Crassula arborescens (fusto e rami articolati, foglie tondeggianti carnose 5-7 cm).$t$,
  $t${"luce": "Posizione luminosa", "acqua": "Poche annaffiature durante la crescita, terreno mantenuto asciutto in inverno"}$t$::jsonb,
  ARRAY[$t$Non tollerano temperature sotto i 5°C$t$, $t$Crassula tetragona: se non annaffiata regolarmente i rami sottili possono cadere per la siccità$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Crassula, p. 472-473$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Echinocereus$t$,
  $t$Echinocereus$t$,
  $t$echinocereus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario del Messico e degli Stati Uniti sudoccidentali, piante piccole molto accestenti con rami striscianti, fusto cilindrico e breve, fino a 40 cm. Specie note: E. fendleri, pectinatus, polycanthus (fiori fucsia); E. engelmannii (cespitosa, fusti fino a 25 cm, fiori 7 cm); E. melanocentrus (nano, cilindrico 8-10 cm, spine radiali bianche e centrali brune, fiori rosa intenso).$t$,
  $t${"luce": "Molto sole, riparare dal sole di mezzogiorno estivo"}$t$::jsonb,
  ARRAY[$t$Molto resistente all'umidità eccessiva, ma teme le scottature da sole estivo diretto$t$, $t$In inverno la temperatura notturna non deve scendere sotto i 5°C$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Echinocereus, p. 476-477$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Echinocactus$t$,
  $t$Echinocactus$t$,
  $t$echinocactus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Detti comunemente "cactus barile", originari dei deserti del Messico e degli Stati Uniti sudoccidentali. Forma globosa o poco allungata, coste ben evidenti, areole allineate con spine lunghe e robuste. Specie nota: Echinocactus grusonii (globoso, molte coste rilevate, spine gialle lanose, cresce lentamente, molto resistente, fiori diurni estivi gialli con centro scuro).$t$,
  $t${"luce": "Pieno sole", "acqua": "In estate solo quando il terriccio è asciutto, nelle altre stagioni non annaffiare"}$t$::jsonb,
  ARRAY[$t$Crescita molto lenta: raggiunge piena maturità e fiorisce solo dopo molti anni$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Echinocactus, p. 477$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
