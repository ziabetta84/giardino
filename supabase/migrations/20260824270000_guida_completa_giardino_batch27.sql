-- Fase 3, ventisettesimo batch da guida-completa-giardino (pp. 486-493,
-- "Piante Grasse"): Haworthia, Lobivia, Matucana, Melocactus. Kalanchoe e
-- Mammillaria saltate: gia' possedute e verificate via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Haworthia$t$,
  $t$Haworthia$t$,
  $t$haworthia$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Genere originario del Sudafrica, piante prive di fusto o con fusto breve, foglie carnose e ricoperte di macchie o formazioni puntiformi rilevate, striature. Specie note: Haworthia fasciata (foglie strette allungate, appuntite ed erette, rilievi bianchi trasversali sulla pagina inferiore), Haworthia cymbiformis (rosette convesse a forma di barchetta, foglie verde-azzurro con righe verticali più scure, apici traslucidi).$t$,
  $t${"luce": "Posizione soleggiata, patiscono sotto il sole cocente estivo diretto sui davanzali", "acqua": "Scarse annaffiature"}$t$::jsonb,
  ARRAY[$t$Temono l'umidità$t$, $t$Temperatura minima di almeno 10°C$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Haworthia, p. 486-487$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Lobivia$t$,
  $t$Lobivia$t$,
  $t$lobivia$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario delle regioni montuose dell'America meridionale (il nome è un anagramma di Bolivia). Piante piccole (diametro fino a 15 cm), globose o cilindriche, con costolature fittamente ravvicinate, solitamente un unico fusto circondato da numerosi polloni. Specie nota: Lobivia ferox (spine lunghe e fitte).$t$,
  $t${"luce": "Piuttosto sopportano temperature invernali fino a 2°C, ma è meglio filtrare i raggi forti del sole d'estate"}$t$::jsonb,
  ARRAY[$t$Annaffiare solo o quasi asciutto, facendo attenzione a non creare ristagni d'acqua$t$, $t$In inverno periodo di riposo vegetativo ascittto e concimare con sali di fosforo molto diluiti$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Lobivia, p. 488-489$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Matucana$t$,
  $t$Matucana$t$,
  $t$matucana$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario del Perù, piante andine di scoperta recente, corpo abbastanza tozzo e sferico, sferiche, spesso caratterizzate da costolature seguite in tubercoli e con fitte spine lunghe, setolose e con spine lunghe. Facili da coltivare in appartamento. Specie nota: Matucana madisionorum (corpo globulare, spine curve color bluastro/verde-grigio, fiori tubolari rosso scarlatto a tromba).$t$,
  $t${"luce": "Sole estivo, con luce diretta", "acqua": "Assolutamente poche annaffiature"}$t$::jsonb,
  ARRAY[$t$Sopportano bene il freddo, ma patiscono l'ambiente eccessivamente asciutto$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Matucana, p. 492$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Melocactus$t$,
  $t$Melocactus$t$,
  $t$melocactus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario dell'America meridionale tropicale, forma globulare o colonnare, coste robuste da cui spuntano areole con spine sporgenti e robuste. Da adulti sviluppano un cefalio (formazione lanosa/setolosa all'apice) da cui nascono fiori e frutti. Riproduzione difficile e lenta. Specie nota: Melocactus longispinus (lunghe spine).$t$,
  $t${"luce": "Luce diretta del sole, costante, temperatura tra 18°C e 30°C"}$t$::jsonb,
  ARRAY[$t$Non deve mai scendere sotto i 12-16°C (o 0°C con cefalio intensamente sviluppato)$t$, $t$Necessitano di scarse annaffiature, soprattutto in inverno$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Melocactus, p. 493$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
