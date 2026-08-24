-- Fase 3, quattordicesimo batch da guida-completa-giardino (pp. 378-387,
-- "Piante Ornamentali"): Dahlia, Dianthus, Freesia, Hemerocallis. Cyclamen,
-- Gazania, Hyacinthus orientalis saltate: gia' possedute e verificate via
-- RHS. Galanthus nivalis (bozza PFAF, npk/irrigazione vuoti) arricchita solo
-- con alert reali, nessun dato numerico disponibile dal libro da aggiungere.

update specie set
  alert = alert || ARRAY[$t$Se l'inverno è troppo siccitoso, i bulbi possono seccarsi producendo pochi fiori in primavera$t$],
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Galanthus nivalis, p. 382$t$)
where slug = $t$galanthus-nivalis$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Galanthus nivalis, p. 382$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Dahlia$t$,
  $t$Dahlia$t$,
  $t$dahlia$t$,
  $t$Compositae$t$,
  $t$perenne$t$,
  $t$Dalia, radici tuberiformi; annuali le varietà nane (oltre 30 cm), biennali o poliannuali le altre (oltre il metro nelle giganti). Fiori terminali dalle forme più svariate (semplici, doppi, a palla). Fioritura estiva o autunnale. Colore predominante giallo o rosso, molti ibridi con altri colori e petali screziati. Uso: vaso su balconi e terrazze (varietà nane).$t$,
  $t${"luce": "Pieno sole", "acqua": "Abbondanti e continue irrigazioni", "terreno": "Fresco, profondo, ricco di sostanze organiche"}$t$::jsonb,
  ARRAY[$t$Soffre attacchi di insetti roditori, afidi e marciumi radicali$t$, $t$Pianta esigente nei confronti del terreno, richiede concimazioni periodiche sia minerali sia organiche$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Dahlia, p. 379$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Dianthus$t$,
  $t$Dianthus$t$,
  $t$dianthus$t$,
  $t$Caryophyllaceae$t$,
  $t$perenne$t$,
  $t$Garofano, annuali, biennali o perenni, facile coltivazione, fiori di colore assai vario (rosa, rosso, giallo, cremisi, multicolore). Specie note: sinensis (garofano della Cina, molti ibridi), caryophyllus (adatto a vaso su terrazzi), barbatus. Alcune specie adatte a giardini rocciosi. Colore: dal bianco al rosa al rosso.$t$,
  $t${"luce": "Posizioni in pieno sole", "acqua": "Regolare", "terreno": "Calcareo"}$t$::jsonb,
  ARRAY[$t$Soggetta ad afidi su apici e foglie$t$, $t$Foglie macchiate dal ragnetto rosso$t$, $t$Macchie biancastre sui petali causate dai tripidi$t$, $t$Pustole brune sulle foglie causate dalla ruggine$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Dianthus, p. 380$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Freesia$t$,
  $t$Freesia$t$,
  $t$freesia$t$,
  $t$Iridaceae$t$,
  $t$perenne$t$,
  $t$Fresia, bulbosa perenne di piccole dimensioni, intensamente profumata. Fiori (6-12 per spiga) a forma campanulata aperta, corolla grande rispetto alle dimensioni della pianta. Fiorisce da fine inverno a inizio estate. Foglie nastriformi verde chiaro, poco appariscenti. Colore: dal bianco al blu, dal rosso al giallo, dal porpora al violetto. Uso: fioriture precoci in vaso (gennaio), aiuole/bordure per fioriture primaverili.$t$,
  $t${"luce": "Esposizioni soleggiate, cresce bene anche parzialmente ombreggiata", "acqua": "Abbondante", "terreno": "Leggero, soffice, ricco di humus"}$t$::jsonb,
  ARRAY[$t$Originaria del Sudafrica, teme il freddo: predilige clima caldo e moderatamente asciutto, meglio in vaso da ricoverare d'inverno$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Freesia, p. 381$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Hemerocallis$t$,
  $t$Hemerocallis$t$,
  $t$hemerocallis$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Emerocallide, bulbosa perenne molto vigorosa, spesso raggiunge il metro d'altezza. Fiori simili a gigli, di breve durata ma prodotti in continuazione da giugno a inizio settembre. Foglie lanceolate a cespuglio basale, verde chiaro. Colore: arancio o giallo; nuovi ibridi anche rosso, bronzeo, porpora, albicocca. Uso: macchie isolate in ampi spazi, bordure medio-alte, angoli ombrosi e umidi.$t$,
  $t${"luce": "Predilige posizioni a mezz'ombra", "acqua": "Abbondanti e frequenti irrigazioni", "terreno": "Buon drenaggio, evitare ristagni"}$t$::jsonb,
  ARRAY[$t$Può essere attaccata da afidi, cocciniglia e ruggine$t$, $t$Scarso drenaggio o annaffiature eccessive favoriscono il marciume del colletto$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Hemerocallis, p. 386$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
