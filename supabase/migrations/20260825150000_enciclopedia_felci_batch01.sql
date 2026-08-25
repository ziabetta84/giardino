-- Fase 3, enciclopedia-felci ("Il giardino di felci", Edicart 1995, 98 foto,
-- l'intero libro, un genere per pagina/doppia pagina con icone di coltivazione
-- e descrizioni morfologiche per specie/cultivar). Nessuna copertura pregressa
-- (verificato con query su fonti). Segue la regola 6 del criterio di
-- importazione: le cultivar/varietà citate solo per nome vengono ripiegate
-- nella descrizione della specie madre, non ricevono una riga propria; le
-- specie con un proprio dato distintivo (origine, morfologia) ricevono una
-- riga separata. Righe esistenti arricchite in append (mai sovrascritte);
-- nuove specie inserite in bozza con on conflict do nothing.

-- ADIANTUM (Polypodiaceae) — genere epifita/rizomatoso da appartamento,
-- terriccio sempre umido, concimazione marzo-agosto ogni 15gg (1/3 dose),
-- rinvaso in primavera con terriccio ricco di humus.
update specie set
  alert = alert || ARRAY[$t$Predilige posizione riparata da correnti d'aria, non troppo luminosa, temperatura minima 18°C e atmosfera ricca di umidità (nebulizzazioni)$t$],
  manutenzione = coalesce(manutenzione, '{}'::jsonb) || $t${"potatura": {"primavera": "se le fronde sono appassite, recidere i fusti raso terra; la pianta riprende a svilupparsi dopo un riposo di 1-2 mesi"}, "irrigazione": {"estate": "mantenere il terriccio costantemente umido, immergere il vaso in acqua una volta a settimana", "primavera": "mantenere il terriccio costantemente umido, immergere il vaso in acqua una volta a settimana"}, "concimazione": {"estate": "da marzo ad agosto, una volta ogni 15 giorni, un terzo della dose raccomandata", "primavera": "da marzo ad agosto, una volta ogni 15 giorni, un terzo della dose raccomandata"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Adiantum$t$)
where slug in ($t$adiantum-capillus-veneris$t$, $t$adiantum-pedatum$t$, $t$adiantum-venustum$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Adiantum$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Fronde particolarmente resistenti, coriacee.$t$,
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Adiantum pedatum$t$)
where slug = $t$adiantum-pedatum$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Adiantum pedatum$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values
($t$Adiantum hispidulum$t$, $t$Adiantum hispidulum$t$, $t$adiantum-hispidulum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Felce da appartamento con fusti pelosi rossastri e fronde nuove rosate che virano al verde scuro.$t$,
 $t${"luce": "Mezz'ombra, posizione riparata", "acqua": "Terriccio sempre umido, atmosfera umida"}$t$::jsonb,
 ARRAY[]::text[], null,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Adiantum hispidulum$t$], $t$bozza$t$),
($t$Adiantum peruvianum$t$, $t$Adiantum peruvianum$t$, $t$adiantum-peruvianum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Originaria del Perù, ha fronde grandi triangolari con pinne ampie di colore verde-bluastro metallico.$t$,
 $t${"luce": "Mezz'ombra, posizione riparata", "acqua": "Terriccio sempre umido, atmosfera umida"}$t$::jsonb,
 ARRAY[]::text[], null,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Adiantum peruvianum$t$], $t$bozza$t$),
($t$Adiantum raddianum$t$, $t$Adiantum raddianum$t$, $t$adiantum-raddianum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Sinonimo A. cuneatum, è la specie di Adiantum più diffusa come pianta da appartamento, con numerose cultivar coltivate: 'Brilliant Else', 'Fragrans', 'Fragrantissimum', 'Fritz-Luthi' e 'Glorytas' si distinguono per densità e forma delle fronde.$t$,
 $t${"luce": "Mezz'ombra, posizione riparata", "acqua": "Terriccio sempre umido, atmosfera umida"}$t$::jsonb,
 ARRAY[]::text[], null,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Adiantum raddianum$t$], $t$bozza$t$),
($t$Adiantum tenerum$t$, $t$Adiantum tenerum$t$, $t$adiantum-tenerum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Fronde ampie e pendule; la cultivar 'Scutum Rosea' ha fronde nuove rosate. Le cultivar 'Monocolor' e 'Bronze Venus' sono intermedie tra A. tenerum e A. raddianum.$t$,
 $t${"luce": "Mezz'ombra, posizione riparata", "acqua": "Terriccio sempre umido, atmosfera umida"}$t$::jsonb,
 ARRAY[]::text[], null,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Adiantum tenerum$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- ASPLENIUM (Polypodiaceae) — genere da appartamento e da giardino roccioso,
-- terreno terriccio+sabbia+torba+farina di ossa, temperatura 18-22°C giorno,
-- 15°C notte, 12°C in inverno per le specie da appartamento.
update specie set
  alert = alert || ARRAY[$t$Predilige temperatura di 18-22°C di giorno, 15°C di notte, minimo 12°C in inverno (specie da appartamento)$t$],
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Asplenium$t$)
where slug in ($t$asplenium-adiantum-nigrum$t$, $t$asplenium-ruta-muraria$t$, $t$asplenium-trichomanes$t$, $t$asplenium-nidus$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Asplenium$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Cresce spontanea sulle rocce calcaree e sui vecchi muri; le fronde, ricoperte di squame argentate sulla pagina inferiore, hanno un uso tradizionale come rimedio erboristico (da cui il nome comune "erba dorata"/"scolopendria minore" a seconda delle zone).$t$,
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Asplenium ceterach (Ceterach officinarum)$t$)
where slug = $t$asplenium-ceterach$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Asplenium ceterach (Ceterach officinarum)$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Sinonimo Phyllitis scolopendrium: fronde intere, nastriformi, lucide, molto diverse dalle altre specie del genere. Numerose cultivar coltivate con fronde ondulate o crestate: 'Crispum', 'Crispum Nobile', 'Cristatum', 'Undulata', 'Ramosa Cristata'.$t$,
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Phyllitis scolopendrium (Asplenium scolopendrium)$t$)
where slug = $t$asplenium-scolopendrium$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Phyllitis scolopendrium (Asplenium scolopendrium)$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Asplenium marinum$t$, $t$Asplenium marinum$t$, $t$asplenium-marinum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Felce delle coste rocciose atlantiche europee, tollera gli spruzzi salini.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Asplenium marinum$t$], $t$bozza$t$),
($t$Asplenium septentrionale$t$, $t$Asplenium septentrionale$t$, $t$asplenium-septentrionale$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Piccola felce delle rocce silicee montane, con fronde strette, quasi lineari, divise in pochi segmenti.$t$,
 $t${"luce": "Sole, mezz'ombra"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Asplenium septentrionale$t$], $t$bozza$t$),
($t$Asplenium viride$t$, $t$Asplenium viride$t$, $t$asplenium-viride$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Piccola felce delle rocce calcaree montane, riconoscibile dal rachide verde (a differenza di A. trichomanes che lo ha bruno-nerastro).$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Asplenium viride$t$], $t$bozza$t$),
($t$Asplenium antiquum$t$, $t$Asplenium antiquum$t$, $t$asplenium-antiquum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Originaria del Giappone, simile ad A. nidus ma di dimensioni più contenute, con fronde a rosetta di colore verde lucido.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Asplenium antiquum$t$], $t$bozza$t$),
($t$Asplenium daucifolium$t$, $t$Asplenium daucifolium$t$, $t$asplenium-daucifolium$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Originaria delle isole dell'Oceano Indiano, ha fronde molto divise, simili a foglie di carota, che producono piantine avventizie (proliferazioni) sulla pagina superiore.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Asplenium daucifolium$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- ATHYRIUM (Dryopteridaceae)
update specie set
  descrizione = descrizione || $t$ Numerose cultivar coltivate con fronde crestate o filiformi: 'Cristatum', 'Frizeliae', 'Victoriae'.$t$,
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Athyrium filix-femina$t$)
where slug = $t$athyrium-filix-femina$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Athyrium filix-femina$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values ($t$Athyrium distentifolium$t$, $t$Athyrium distentifolium$t$, $t$athyrium-distentifolium$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Felce montana simile ad A. filix-femina, diffusa nelle radure boschive d'alta quota europee.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Athyrium distentifolium$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- BLECHNUM (Blechnaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Blechnum spicant$t$)
where slug = $t$blechnum-spicant$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Blechnum spicant$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Blechnum penna-marina$t$, $t$Blechnum penna-marina$t$, $t$blechnum-penna-marina$t$, $t$Blechnaceae$t$, $t$perenne$t$,
 $t$Piccola felce tappezzante originaria dell'emisfero australe, adatta a coprire il terreno nei giardini rocciosi ombrosi.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Blechnum penna-marina$t$], $t$bozza$t$),
($t$Blechnum brasiliense$t$, $t$Blechnum brasiliense$t$, $t$blechnum-brasiliense$t$, $t$Blechnaceae$t$, $t$perenne$t$,
 $t$Felce da appartamento con portamento a piccola palma: sviluppa un breve tronco eretto sormontato da una rosetta di fronde rigide, coriacee, color bronzo da giovani.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 16-24°C di giorno, minimo 14°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Blechnum brasiliense$t$], $t$bozza$t$),
($t$Blechnum gibbum$t$, $t$Blechnum gibbum$t$, $t$blechnum-gibbum$t$, $t$Blechnaceae$t$, $t$perenne$t$,
 $t$Simile a B. brasiliense, con portamento a piccola palma e tronco che si allunga con l'età.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 16-24°C di giorno, minimo 14°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Blechnum gibbum$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- CHEILANTHES (Pteridaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Cheilanthes$t$)
where slug = $t$cheilanthes-pteridioides$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Cheilanthes$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values ($t$Cheilanthes lanosa$t$, $t$Cheilanthes lanosa$t$, $t$cheilanthes-lanosa$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Piccola felce xerofila delle rocce nordamericane, con fronde ricoperte di una fitta peluria protettiva.$t$,
 $t${"luce": "Sole, mezz'ombra", "acqua": "Tollera la siccità"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Cheilanthes lanosa$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- CIBOTIUM (Dicksoniaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Cibotium barometz$t$)
where slug = $t$cibotium-barometz$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Cibotium barometz$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Cibotium glaucum$t$, $t$Cibotium glaucum$t$, $t$cibotium-glaucum$t$, $t$Dicksoniaceae$t$, $t$perenne$t$,
 $t$Felce arborea hawaiana con tronco peloso e grandi fronde arcuate.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-15°C di notte$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Cibotium glaucum$t$], $t$bozza$t$),
($t$Cibotium schiedei$t$, $t$Cibotium schiedei$t$, $t$cibotium-schiedei$t$, $t$Dicksoniaceae$t$, $t$perenne$t$,
 $t$Felce arborea messicana, con fronde grandi, molto divise, di colore verde chiaro.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-15°C di notte$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Cibotium schiedei$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- CYATHEA (Cyatheaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Cyathea$t$)
where slug in ($t$cyathea-dealbata$t$, $t$cyathea-medullaris$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Cyathea$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Cyathea australis$t$, $t$Cyathea australis$t$, $t$cyathea-australis$t$, $t$Cyatheaceae$t$, $t$perenne$t$,
 $t$Felce arborea australiana, con tronco fibroso e grandi fronde arcuate; nebulizzare regolarmente il fusto.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 18°C di notte$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Cyathea australis$t$], $t$bozza$t$),
($t$Cyathea cooperi$t$, $t$Cyathea cooperi$t$, $t$cyathea-cooperi$t$, $t$Cyatheaceae$t$, $t$perenne$t$,
 $t$Felce arborea australiana a crescita rapida, molto diffusa in coltivazione; nebulizzare regolarmente il fusto.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 18°C di notte$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Cyathea cooperi$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- CYRTOMIUM (Dryopteridaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Cyrtomium$t$)
where slug in ($t$cyrtomium-falcatum$t$, $t$cyrtomium-fortunei$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Cyrtomium$t$ = any(fonti));

-- CYSTOPTERIS (Dryopteridaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Cystopteris$t$)
where slug in ($t$cystopteris-bulbifera$t$, $t$cystopteris-fragilis$t$, $t$cystopteris-montana$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Cystopteris$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values ($t$Cystopteris dickiana$t$, $t$Cystopteris dickiana$t$, $t$cystopteris-dickiana$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Piccola felce delle rocce calcaree, simile a C. fragilis.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Cystopteris dickiana$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- DAVALLIA (Davalliaceae) — genere nuovo, felci epifite da appartamento
-- con rizoma peloso rampicante ("zampa di coniglio"), temperatura 20-24°C
-- giorno, 7-15°C notte.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Davallia canariensis$t$, $t$Davallia canariensis$t$, $t$davallia-canariensis$t$, $t$Davalliaceae$t$, $t$perenne$t$,
 $t$Felce epifita con rizoma peloso strisciante ("zampa di coniglio") visibile sulla superficie del terriccio, da cui si sviluppano fronde triangolari.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 20-24°C di giorno, 7-15°C di notte; non interrare il rizoma$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Davallia canariensis$t$], $t$bozza$t$),
($t$Davallia divaricata$t$, $t$Davallia divaricata$t$, $t$davallia-divaricata$t$, $t$Davalliaceae$t$, $t$perenne$t$,
 $t$Felce epifita a rizoma strisciante peloso, con fronde grandi e molto divise, adatta a cestelli pensili.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 20-24°C di giorno, 7-15°C di notte; non interrare il rizoma$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Davallia divaricata$t$], $t$bozza$t$),
($t$Davallia mariesii$t$, $t$Davallia mariesii$t$, $t$davallia-mariesii$t$, $t$Davalliaceae$t$, $t$perenne$t$,
 $t$Sinonimo D. bullata; piccola felice epifita, molto rustica tra le Davallia, con rizoma peloso argenteo.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 20-24°C di giorno, 7-15°C di notte; non interrare il rizoma$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Davallia mariesii$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- DENNSTAEDTIA (Dennstaedtiaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Dennstaedtia$t$)
where slug = $t$dennstaedtia-punctilobula$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Dennstaedtia$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values ($t$Dennstaedtia cicutaria$t$, $t$Dennstaedtia cicutaria$t$, $t$dennstaedtia-cicutaria$t$, $t$Dennstaedtiaceae$t$, $t$perenne$t$,
 $t$Felce tropicale con fronde grandi, triangolari, molto divise.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Dennstaedtia cicutaria$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- DICKSONIA (Dicksoniaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Dicksonia$t$)
where slug = $t$dicksonia-antarctica$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Dicksonia$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values
($t$Dicksonia fibrosa$t$, $t$Dicksonia fibrosa$t$, $t$dicksonia-fibrosa$t$, $t$Dicksoniaceae$t$, $t$perenne$t$,
 $t$Felce arborea neozelandese a crescita lenta, con tronco fibroso molto spesso.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Dicksonia fibrosa$t$], $t$bozza$t$),
($t$Dicksonia squarrosa$t$, $t$Dicksonia squarrosa$t$, $t$dicksonia-squarrosa$t$, $t$Dicksoniaceae$t$, $t$perenne$t$,
 $t$Felce arborea neozelandese, forma spesso polloni basali che creano gruppi di più tronchi.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Dicksonia squarrosa$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- DIDYMOCHLAENA (Hypodematiaceae) — genere nuovo, unica specie coltivata
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values ($t$Didymochlaena truncatula$t$, $t$Didymochlaena truncatula$t$, $t$didymochlaena-truncatula$t$, $t$Hypodematiaceae$t$, $t$perenne$t$,
 $t$Unica specie del genere coltivata, felce tropicale da appartamento con fronde coriacee color bronzo da giovani, poi verde scuro lucido.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 20-22°C, ambiente costantemente umido$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Didymochlaena truncatula$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- DORYOPTERIS (Pteridaceae) — genere nuovo
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Doryopteris ludens$t$, $t$Doryopteris ludens$t$, $t$doryopteris-ludens$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Piccola felce tropicale con fronde palmate lobate, di forma decorativa.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 24-26°C di giorno, 15-21°C di notte$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Doryopteris ludens$t$], $t$bozza$t$),
($t$Doryopteris nobilis$t$, $t$Doryopteris nobilis$t$, $t$doryopteris-nobilis$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Felce tropicale con fronde palmate, più grandi di D. ludens.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 24-26°C di giorno, 15-21°C di notte$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Doryopteris nobilis$t$], $t$bozza$t$),
($t$Doryopteris pedata$t$, $t$Doryopteris pedata$t$, $t$doryopteris-pedata$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Felce tropicale con fronde a forma di piede d'oca (da cui il nome); la varietà palmata ha lobi più arrotondati.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 24-26°C di giorno, 15-21°C di notte$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Doryopteris pedata$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- DRYOPTERIS (Dryopteridaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Dryopteris$t$)
where slug in ($t$dryopteris-carthusiana$t$, $t$dryopteris-cristata$t$, $t$dryopteris-dilatata$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Dryopteris$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Numerose cultivar ornamentali coltivate con fronde crestate o filiformi: 'Crispa', 'Cristata', 'Grandiceps'.$t$,
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Dryopteris filix-mas$t$)
where slug = $t$dryopteris-filix-mas$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Dryopteris filix-mas$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values
($t$Dryopteris goldiana$t$, $t$Dryopteris goldiana$t$, $t$dryopteris-goldiana$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Grande felce nordamericana dei boschi, con fronde larghe fino a 30 cm.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Dryopteris goldiana$t$], $t$bozza$t$),
($t$Dryopteris pseudomas$t$, $t$Dryopteris pseudomas$t$, $t$dryopteris-pseudomas$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Felce semi-sempreverde, simile a D. filix-mas ma con fronde più coriacee e persistenti.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Dryopteris pseudomas$t$], $t$bozza$t$),
($t$Dryopteris villarsii$t$, $t$Dryopteris villarsii$t$, $t$dryopteris-villarsii$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Felce delle zone montane calcaree europee.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Dryopteris villarsii$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- GYMNOCARPIUM (Cystopteridaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Gymnocarpium dryopteris$t$)
where slug = $t$gymnocarpium-dryopteris$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Gymnocarpium dryopteris$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values ($t$Gymnocarpium robertianum$t$, $t$Gymnocarpium robertianum$t$, $t$gymnocarpium-robertianum$t$, $t$Cystopteridaceae$t$, $t$perenne$t$,
 $t$Piccola felce tappezzante delle rocce calcaree, con fronde odorose se stropicciate.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Gymnocarpium robertianum$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- HUMATA (Davalliaceae) — genere nuovo, unica specie diffusa in coltivazione
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values ($t$Humata tyermannii$t$, $t$Humata tyermannii$t$, $t$humata-tyermannii$t$, $t$Davalliaceae$t$, $t$perenne$t$,
 $t$Piccola felce epifita con rizoma peloso bianco-argenteo strisciante, simile nell'aspetto a una Davallia.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-15°C di notte$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Humata tyermannii$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- MATTEUCCIA (Polypodiaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Matteuccia$t$)
where slug in ($t$matteuccia-pensylvanica$t$, $t$matteuccia-struthiopteris$t$, $t$matteuccia-orientalis$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Matteuccia$t$ = any(fonti));

-- MICROLEPIA (Dennstaedtiaceae) — genere nuovo
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values ($t$Microlepia speluncae$t$, $t$Microlepia speluncae$t$, $t$microlepia-speluncae$t$, $t$Dennstaedtiaceae$t$, $t$perenne$t$,
 $t$Felce tropicale da appartamento a rapida crescita, con fronde grandi, morbide, molto divise.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 18-22°C, minimo 15°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Microlepia speluncae$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- NEPHROLEPIS (Nephrolepidaceae) — genere nuovo, felci da appartamento
-- molto diffuse; numerose cultivar di N. exaltata ripiegate in descrizione.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Nephrolepis cordifolia$t$, $t$Nephrolepis cordifolia$t$, $t$nephrolepis-cordifolia$t$, $t$Nephrolepidaceae$t$, $t$perenne$t$,
 $t$Produce piccoli tuberi sotterranei di riserva idrica lungo gli stoloni; la cultivar 'Plumosa' ha fronde più piumose.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 18-22°C, minimo 18°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Nephrolepis cordifolia$t$], $t$bozza$t$),
($t$Nephrolepis duffii$t$, $t$Nephrolepis duffii$t$, $t$nephrolepis-duffii$t$, $t$Nephrolepidaceae$t$, $t$perenne$t$,
 $t$Cultivar/specie compatta con pinne piccole e arrotondate, molto diversa dall'aspetto tipico del genere.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 18-22°C, minimo 18°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Nephrolepis duffii$t$], $t$bozza$t$),
($t$Nephrolepis exaltata$t$, $t$Nephrolepis exaltata$t$, $t$nephrolepis-exaltata$t$, $t$Nephrolepidaceae$t$, $t$perenne$t$,
 $t$La "felce di Boston" in senso ampio: specie da appartamento più diffusa del genere, con fronde pendule lunghe fino a 1 m. Numerosissime cultivar coltivate, tra cui 'Atlanta', 'Boston Marathon', 'Bostoniensis', 'Maassii', 'Teddy Junior', 'Bornstedt', 'Rooseveltii Plumosa' e 'Whitemanii', diverse per densità, arricciatura e taglio delle pinne.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 18-22°C, minimo 18°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Nephrolepis exaltata$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- ONOCLEA (Onocleaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Onoclea sensibilis$t$)
where slug = $t$onoclea-sensibilis$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Onoclea sensibilis$t$ = any(fonti));

-- OSMUNDA (Osmundaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Osmunda$t$)
where slug in ($t$osmunda-cinnamomea$t$, $t$osmunda-claytoniana$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Osmunda$t$ = any(fonti));

update specie set
  descrizione = descrizione || $t$ Esistono cultivar ornamentali come 'Cristata' e 'Purpurascens' (fronde nuove purpuree).$t$,
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Osmunda regalis$t$)
where slug = $t$osmunda-regalis$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Osmunda regalis$t$ = any(fonti));

-- PELLAEA (Pteridaceae) — genere nuovo
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Pellaea atropurpurea$t$, $t$Pellaea atropurpurea$t$, $t$pellaea-atropurpurea$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Piccola felce xerofila nordamericana delle rocce calcaree, con fusti scuri quasi neri.$t$,
 $t${"luce": "Sole, mezz'ombra", "acqua": "Tollera la siccità"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 14-20°C, minimo 12-15°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pellaea atropurpurea$t$], $t$bozza$t$),
($t$Pellaea falcata$t$, $t$Pellaea falcata$t$, $t$pellaea-falcata$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Felce australiana con pinne falciformi coriacee.$t$,
 $t${"luce": "Sole, mezz'ombra", "acqua": "Tollera la siccità"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 14-20°C, minimo 12-15°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pellaea falcata$t$], $t$bozza$t$),
($t$Pellaea rotundifolia$t$, $t$Pellaea rotundifolia$t$, $t$pellaea-rotundifolia$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Felce neozelandese con pinne piccole, rotonde, coriacee, su fusti striscianti; adatta a cestelli pensili.$t$,
 $t${"luce": "Sole, mezz'ombra", "acqua": "Tollera la siccità"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 14-20°C, minimo 12-15°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pellaea rotundifolia$t$], $t$bozza$t$),
($t$Pellaea viridis$t$, $t$Pellaea viridis$t$, $t$pellaea-viridis$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Felce sudafricana con fronde verde brillante, pennate.$t$,
 $t${"luce": "Sole, mezz'ombra", "acqua": "Tollera la siccità"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 14-20°C, minimo 12-15°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pellaea viridis$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- PHLEBODIUM (Polypodiaceae) — genere nuovo
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values ($t$Phlebodium aureum$t$, $t$Phlebodium aureum$t$, $t$phlebodium-aureum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Sinonimo Polypodium aureum, felce epifita con rizoma peloso blu-verde strisciante e fronde grandi, glauche. Le cultivar 'Cristatum' e 'Mandaianum' hanno fronde crestate o ondulate.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 18-22°C, minimo 10-16°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Phlebodium aureum$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- PILULARIA (Marsileaceae) — genere nuovo, felci acquatiche
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Pilularia globulifera$t$, $t$Pilularia globulifera$t$, $t$pilularia-globulifera$t$, $t$Marsileaceae$t$, $t$perenne$t$,
 $t$Felce acquatica erbacea con rizoma strisciante e fronde cilindriche filiformi lunghe 3-14 cm, adatta a stagni poco profondi o torbiere.$t$,
 $t${"luce": "Sole", "acqua": "Acque poco profonde con scarse sostanze nutritive"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pilularia globulifera$t$], $t$bozza$t$),
($t$Pilularia minuta$t$, $t$Pilularia minuta$t$, $t$pilularia-minuta$t$, $t$Marsileaceae$t$, $t$perenne$t$,
 $t$Felce acquatica minuta, con fronde densamente appressate lunghe solo 5-6 cm.$t$,
 $t${"luce": "Sole", "acqua": "Acque poco profonde"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pilularia minuta$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- PLATYCERIUM (Polypodiaceae)
update specie set
  descrizione = descrizione || $t$ Felce epifita con fronde sterili a forma di conchiglia che proteggono le radici e fronde fertili pendule a forma di corna ramificate, ricoperte di cera protettiva. Numerose sottospecie e cultivar: 'willinckii', 'bifurcatum bifurcatum var. hillii' e 'San Diego'.$t$,
  alert = alert || ARRAY[$t$Non somministrare troppe innaffiature: in estate immergere il vaso una volta a settimana, in inverno una volta ogni 15 giorni; non rimuovere i puntini marrone (sono le spore)$t$],
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Platycerium bifurcatum$t$)
where slug = $t$platycerium-bifurcatum$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Platycerium bifurcatum$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values ($t$Platycerium grande$t$, $t$Platycerium grande$t$, $t$platycerium-grande$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Fronde sterili basse riunite a formare una sorta di nido, fronde fertili pendule a forma di corna lunghe 30-200 cm, con pinne larghe lanceolate leggermente pelose.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 20°C, minimo 12-15°C in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Platycerium grande$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- POLYPODIUM (Polypodiaceae)
update specie set
  descrizione = descrizione || $t$ Rizomi striscianti e ramificati, fronde coriacee che lasciano una cicatrice alla caduta; adatto anche a coltura in cestelli pensili. Esistono varietà con pinne crestate e crespe, come 'Bifido Multifidum'.$t$,
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Polypodium vulgare$t$)
where slug = $t$polypodium-vulgare$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Polypodium vulgare$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values
($t$Polypodium interjectum$t$, $t$Polypodium interjectum$t$, $t$polypodium-interjectum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Fronde leggermente triangolari, quadrilobate, lunghe 15-50 cm; le fronde vecchie cadono da maggio a giugno. La cultivar 'Cornubiense' ha splendide fronde pennate verde chiaro.$t$,
 $t${"luce": "Sole, mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Polypodium interjectum$t$], $t$bozza$t$),
($t$Polypodium crassifolium$t$, $t$Polypodium crassifolium$t$, $t$polypodium-crassifolium$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Fronde linguiformi coriacee, lunghe 30-90 cm, con margine liscio e ondulato.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Polypodium crassifolium$t$], $t$bozza$t$),
($t$Polypodium subauriculatum$t$, $t$Polypodium subauriculatum$t$, $t$polypodium-subauriculatum$t$, $t$Polypodiaceae$t$, $t$perenne$t$,
 $t$Sinonimo Goniophlebium subauriculatum; rizomi corti squamosi, fronde pennate pendule lunghe 100-200 cm. La cultivar 'Knightiae' ha fronde grandi con pinne crespe.$t$,
 $t${"luce": "Mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Polypodium subauriculatum$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- POLYSTICHUM (Dryopteridaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Polystichum$t$)
where slug in ($t$polystichum-acrostichoides$t$, $t$polystichum-aculeatum$t$, $t$polystichum-munitum$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Polystichum$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values
($t$Polystichum lonchitis$t$, $t$Polystichum lonchitis$t$, $t$polystichum-lonchitis$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Fronde molto strette, rigide, pennate, riunite in gruppi compatti; adatta ai giardini rocciosi umidi, proteggere dal sole invernale.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Polystichum lonchitis$t$], $t$bozza$t$),
($t$Polystichum makinoi$t$, $t$Polystichum makinoi$t$, $t$polystichum-makinoi$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Fronde bruno-arancioni in primavera, lunghe fino a 50 cm.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Polystichum makinoi$t$], $t$bozza$t$),
($t$Polystichum setiferum$t$, $t$Polystichum setiferum$t$, $t$polystichum-setiferum$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Fronde eleganti, ripiegate, morbide, verde chiaro opaco, adatte a luoghi molto scuri. Numerose cultivar sempreverdi coltivate: 'Herrenhausen' (ciuffi grandi) e 'Proliferum Plumosum Densum' (felce piumosa con fronde bruno-rugginose in inverno).$t$,
 $t${"luce": "Ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Polystichum setiferum$t$], $t$bozza$t$),
($t$Polystichum tsus-sinense$t$, $t$Polystichum tsus-sinense$t$, $t$polystichum-tsus-sinense$t$, $t$Dryopteridaceae$t$, $t$perenne$t$,
 $t$Fronde bipennate verde molto scuro, affusolate in punta; proviene da regioni con nevicate abbondanti, va riparata in inverno e non esposta al sole. Diffusa anche come pianta da appartamento in angoli freddi e luminosi (7-18°C).$t$,
 $t${"luce": "Ombra, lontano dai raggi diretti"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Polystichum tsus-sinense$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- PTERIDIUM (Polypodiaceae)
update specie set
  descrizione = descrizione || $t$ Il nome deriva dalla sagoma di un'aquila bicipite visibile nelle venature scure del fusto se reciso diagonalmente.$t$,
  alert = alert || ARRAY[$t$Velenosa per gli animali domestici (conigli e altri erbivori la evitano istintivamente)$t$],
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Pteridium aquilinum$t$)
where slug = $t$pteridium-aquilinum$t$
  and not ($t$Il giardino di felci (Edicart, 1995) — Pteridium aquilinum$t$ = any(fonti));

-- PTERIS (Pteridaceae) — genere nuovo, felci ornamentali da appartamento,
-- tutte le specie hanno l'ultima coppia di pinne a forma di ali di farfalla,
-- 21-26°C di giorno (10-12°C in inverno), varietà screziate min. 16-18°C.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Pteris cretica$t$, $t$Pteris cretica$t$, $t$pteris-cretica$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Fusti eretti gialli o verde chiaro, fronde coriacee pennate verde chiaro. Meno sensibile al clima secco delle altre Pteris. Numerose cultivar screziate o dalla forma particolare: 'Albolineata' (striscia bianca centrale), 'Mayi', 'Parkeri', 'Roeweri', 'Wilsonii', 'Wimsettii'.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-12°C di notte in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pteris cretica$t$], $t$bozza$t$),
($t$Pteris ensiformis$t$, $t$Pteris ensiformis$t$, $t$pteris-ensiformis$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Fusti sottili gialli, fronde sterili smussate lunghe 20-45 cm e fronde fertili più lunghe ed erette. La cultivar 'Evergemiensis' ha fronde bianche screziate.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-12°C di notte in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pteris ensiformis$t$], $t$bozza$t$),
($t$Pteris faurei$t$, $t$Pteris faurei$t$, $t$pteris-faurei$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Fronde pennate verde scuro con margini leggermente ondulati; tollera un'aria più secca delle altre Pteris.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-12°C di notte in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pteris faurei$t$], $t$bozza$t$),
($t$Pteris multifida$t$, $t$Pteris multifida$t$, $t$pteris-multifida$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Sinonimo P. serrulata; fusti marrone, fronde strette pennate verde scuro lunghe 30-60 cm, bipennate alla base. La cultivar 'Cristata' ha pinne crespe con estremità crestate.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-12°C di notte in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pteris multifida$t$], $t$bozza$t$),
($t$Pteris quadriaurita$t$, $t$Pteris quadriaurita$t$, $t$pteris-quadriaurita$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Fusti giallo paglierino, fronde triangolari bi-tripennate lunghe 50 cm. Le cultivar 'Argyreia' e 'Tricolor' hanno una striscia centrale bianco-argentata o bianco-verdastra sulle pinne.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-12°C di notte in inverno; le varietà screziate richiedono almeno 16-18°C$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pteris quadriaurita$t$], $t$bozza$t$),
($t$Pteris tremula$t$, $t$Pteris tremula$t$, $t$pteris-tremula$t$, $t$Pteridaceae$t$, $t$perenne$t$,
 $t$Cresce e si allunga rapidamente alla base; fusti marrone, fronde pluripennate verde chiaro lunghe fino a 1 m, pinne sovrapposte ruvide e lobate. Non tollera l'aria secca.$t$,
 $t${"luce": "Mezz'ombra, ombra"}$t$::jsonb, ARRAY[$t$Temperatura consigliata 21-26°C di giorno, 10-12°C di notte in inverno$t$],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Pteris tremula$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- SALVINIA (Salviniaceae) — genere nuovo, felci acquatiche galleggianti
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values
($t$Salvinia auriculata$t$, $t$Salvinia auriculata$t$, $t$salvinia-auriculata$t$, $t$Salviniaceae$t$, $t$perenne$t$,
 $t$Nota anche come S. natans, felce acquatica galleggiante tropicale con pinne larghe ovali verde brillante lunghe 2-2,5 cm, rivestite di peli marrone sulla pagina inferiore. Non resiste al freddo.$t$,
 $t${"luce": "Sole, mezz'ombra leggera", "acqua": "Acqua dolce stagnante, 18-25°C"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Salvinia auriculata$t$], $t$bozza$t$),
($t$Salvinia rotundifolia$t$, $t$Salvinia rotundifolia$t$, $t$salvinia-rotundifolia$t$, $t$Salviniaceae$t$, $t$perenne$t$,
 $t$Felce acquatica galleggiante con pinne rotonde lunghe 2 cm, con estremità rivestite di peli ispidi. Non resiste al freddo.$t$,
 $t${"luce": "Sole, mezz'ombra leggera", "acqua": "Acqua dolce stagnante, 18-25°C"}$t$::jsonb, ARRAY[]::text[],
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Salvinia rotundifolia$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- THELYPTERIS (Thelypteridaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Thelypteris$t$)
where slug in ($t$thelypteris-noveboracensis$t$, $t$thelypteris-palustris$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Thelypteris$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values
($t$Thelypteris hexagonoptera$t$, $t$Thelypteris hexagonoptera$t$, $t$thelypteris-hexagonoptera$t$, $t$Thelypteridaceae$t$, $t$perenne$t$,
 $t$Sinonimo Dryopteris/Phegopteris hexagonoptera; grande felce con rizomi ramificati e fronde lanceolate lunghe 25-30 cm, dai margini frastagliati ondulati.$t$,
 $t${"luce": "Sole, mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Thelypteris hexagonoptera$t$], $t$bozza$t$),
($t$Thelypteris oreopteris$t$, $t$Thelypteris oreopteris$t$, $t$thelypteris-oreopteris$t$, $t$Thelypteridaceae$t$, $t$perenne$t$,
 $t$Sinonimo Oreopteris limbosperma; fronde lanceolate verde-giallognolo brillante che, se sfregate, emanano un intenso profumo di limone. Cresce in terreno acido, umido, sabbioso.$t$,
 $t${"luce": "Sole, mezz'ombra", "terreno": "Acido, umido, sabbioso, ricco di humus"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Thelypteris oreopteris$t$], $t$bozza$t$),
($t$Thelypteris phegopteris$t$, $t$Thelypteris phegopteris$t$, $t$thelypteris-phegopteris$t$, $t$Thelypteridaceae$t$, $t$perenne$t$,
 $t$Sinonimo Phegopteris connectilis; fronde triangolari bipennate verde-oliva, con la coppia di pinne basali separata dalle altre e rivolta in basso. Adatta a coltura di copertura sotto arbusti.$t$,
 $t${"luce": "Ombra", "terreno": "Non calcareo"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Thelypteris phegopteris$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- WOODSIA (Woodsiaceae) — genere nuovo, felci decidue da giardino roccioso
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values
($t$Woodsia alpina$t$, $t$Woodsia alpina$t$, $t$woodsia-alpina$t$, $t$Woodsiaceae$t$, $t$perenne$t$,
 $t$Piccola felce alpina con fronde strette lunghe 5-15 cm e pinne leggermente squamose triangolari.$t$,
 $t${"luce": "Mezz'ombra", "terreno": "Terreno povero, roccioso"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Woodsia alpina$t$], $t$bozza$t$),
($t$Woodsia ilvensis$t$, $t$Woodsia ilvensis$t$, $t$woodsia-ilvensis$t$, $t$Woodsiaceae$t$, $t$perenne$t$,
 $t$Fusti pelosi bruno-rossicci, fronde frastagliate come un pizzo lunghe 7-20 cm, pagina inferiore squamosa e pelosa. Vuole terreno acido, piuttosto umido.$t$,
 $t${"luce": "Mezz'ombra", "terreno": "Acido, umido"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Woodsia ilvensis$t$], $t$bozza$t$),
($t$Woodsia obtusa$t$, $t$Woodsia obtusa$t$, $t$woodsia-obtusa$t$, $t$Woodsiaceae$t$, $t$perenne$t$,
 $t$Fronde grigiastre lunghe 15-40 cm con peli bianchi su entrambe le pagine, pinne arrotondate. Sempreverde o quasi, richiede terreno calcareo.$t$,
 $t${"luce": "Mezz'ombra", "terreno": "Calcareo"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Woodsia obtusa$t$], $t$bozza$t$),
($t$Woodsia scopulina$t$, $t$Woodsia scopulina$t$, $t$woodsia-scopulina$t$, $t$Woodsiaceae$t$, $t$perenne$t$,
 $t$Fronde lunghe 15-20 cm con pinne profondamente frastagliate.$t$,
 $t${"luce": "Mezz'ombra", "terreno": "Terreno povero, roccioso"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Woodsia scopulina$t$], $t$bozza$t$)
on conflict (slug) do nothing;

-- WOODWARDIA (Blechnaceae)
update specie set
  fonti = array_append(fonti, $t$Il giardino di felci (Edicart, 1995) — Woodwardia$t$)
where slug in ($t$woodwardia-areolata$t$, $t$woodwardia-radicans$t$, $t$woodwardia-virginica$t$)
  and not ($t$Il giardino di felci (Edicart, 1995) — Woodwardia$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica)
values ($t$Woodwardia fimbriata$t$, $t$Woodwardia fimbriata$t$, $t$woodwardia-fimbriata$t$, $t$Blechnaceae$t$, $t$perenne$t$,
 $t$Sinonimo W. chamissoi; grande felce nordamericana con fronde che nel loro habitat naturale (USA) possono raggiungere 250 cm di lunghezza (le varietà coltivate restano più contenute).$t$,
 $t${"luce": "Mezz'ombra", "terreno": "Paludoso, acido"}$t$::jsonb,
 ARRAY[$t$Il giardino di felci (Edicart, 1995) — Woodwardia fimbriata$t$], $t$bozza$t$)
on conflict (slug) do nothing;
