-- Fase 3, ventiseiesimo batch da guida-completa-giardino (pp. 480-485,
-- "Piante Grasse"): Espostoa, Euphorbia (genere), Gymnocalycium.
-- Ferocactus e Gasteria saltate: gia' possedute e verificate via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Espostoa$t$,
  $t$Espostoa$t$,
  $t$espostoa$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario dei monti del Perù e della Bolivia, cactus eretti, semplici o poco ramificati, spesso rastremati verso il basso. Coste numerose e poco evidenti, punteggiate di areole da cui spuntano numerose spine morbide e setose, ricoperte da lunghi peli bianchi e molli che conferiscono un aspetto lanoso. Specie nota: Espostoa lanata (spine radiali giallastre, "capigliatura" lanosa centrale, fiori notturni bianchi/rosati lunghi 5 cm, fino a 4 m di altezza da adulta).$t$,
  $t${"luce": "Pieno sole", "acqua": "Poche annaffiature, interrotte durante l'inverno"}$t$::jsonb,
  ARRAY[$t$Temperatura non deve scendere sotto i 7°C di notte, 15°C di giorno d'inverno$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Espostoa, p. 480$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Euphorbia$t$,
  $t$Euphorbia$t$,
  $t$euphorbia$t$,
  $t$Euphorbiaceae$t$,
  $t$perenne$t$,
  $t$Genere di oltre 1600 specie diffuse in tutto il mondo, originario soprattutto dell'Africa. Molte Euphorbia sono quasi identiche alle cactacee (fusto succulento con lattice urticante e velenoso, spine su gibbosità o costolature), ma le vere spine spuntano sempre in coppia da un'areola, a differenza delle cactacee. Specie note: Euphorbia milii ("corona di spine", arbusto spinoso ramificato, alto fino a 90 cm, fiori piccoli accompagnati da vistose brattee rosa o gialle); Euphorbia grandicornis (fusti a 3-4 coste con spine appuntite e ricurve, fino a 2 m).$t$,
  $t${"luce": "Molto sole"}$t$::jsonb,
  ARRAY[$t$Il lattice è urticante e velenoso: maneggiare con attenzione se il fusto viene spezzato$t$, $t$Non richiedono molte annaffiature$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Euphorbia, p. 481-483$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Gymnocalycium$t$,
  $t$Gymnocalycium$t$,
  $t$gymnocalycium$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere diffuso in Argentina, Uruguay, Paraguay e Brasile meridionale, pianta grossa a forma globosa, con natura piuttosto grossa. Costole regolari o irregolari, a volte tubercolate, a volte con creste e ondulazioni trasversali; spine sottili, a volte curve e brevi. Specie note: Gymnocalycium mihanowichii (piccolo cactus, diametro 4-5 cm, spine lunghe circa 4 cm, colore verde-rossiccio striato, fiori a imbuto lunghi circa 4 cm); Gymnocalycium spegazzinii (spine lunghe, ricurve, colorate).$t$,
  $t${"luce": "Non luce diretta molto forte: teme l'umidità eccessiva e la luce troppo intensa"}$t$::jsonb,
  ARRAY[$t$Temono l'umidità eccessiva, per questo cactus sono coltivati spesso su genere Cereus o Trichocereus come portainnesti$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Gymnocalycium, p. 485$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
