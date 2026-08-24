-- Fase 3, quinto batch da guida-completa-giardino (pp. 310-317, "Piante da
-- Appartamento"): Codiaeum variegatum, Columnea gloriosa, Cordyline
-- terminalis, Cyperus papyrus (arricchimento).

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Codiaeum variegatum$t$,
  $t$Codiaeum variegatum$t$,
  $t$codiaeum-variegatum$t$,
  $t$Euphorbiaceae$t$,
  $t$perenne$t$,
  $t$Croton originario della Malesia e dell'India, coltivato per le foglie coloratissime (fiore insignificante). Varietà diffuse: Aucubifolium, Superbum, Fascination, Craigii.$t$,
  $t${"luce": "Diretta, necessaria per sviluppare la colorazione delle foglie", "terreno": "Mantenuto sempre umido, senza ristagni"}$t$::jsonb,
  ARRAY[$t$Insetti bruni sotto le foglie e sui fusti: cocciniglia, intervenire con un acaricida$t$, $t$Foglie che cadono: sbalzi di temperatura$t$, $t$Foglie opache o perdita di colore: luce insufficiente$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15 giorni, diluito per non causare ustioni", "autunno": null, "inverno": null, "primavera": "concime liquido ogni 15 giorni, diluito per non causare ustioni"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Euphorbiaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Codiaeum variegatum, p. 310-311$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Columnea gloriosa$t$,
  $t$Columnea gloriosa$t$,
  $t$columnea-gloriosa$t$,
  $t$Gesneriaceae$t$,
  $t$perenne$t$,
  $t$Columnea originaria dell'America tropicale, a portamento ricadente (epifita, in natura cresce sugli alberi), con fiori vistosi dal giallo al rosso-arancione. Specie affine diffusa: Columnea microphylla.$t$,
  $t${"luce": "Luoghi ben luminosi, mai sole diretto", "acqua": "Regolare in estate, non tollera le correnti d'aria", "terreno": "Ricco, tipo terra da giardino"}$t$::jsonb,
  ARRAY[$t$Nuvola di moscerini bianchi al tocco: attacco di aleurodidi, trattare con insetticida specifico$t$, $t$Fusti allungati e sottili: luce insufficiente, spostare la pianta$t$, $t$Foglie che cadono: freddo eccessivo (sotto i 10°C) o eccesso di umidità$t$],
  $t${"npk": {"estate": "10-10-10", "autunno": null, "inverno": null, "primavera": "10-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "regolare, con acqua a temperatura ambiente", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15-20 giorni", "autunno": null, "inverno": "una volta sola", "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Gesneriaceae", "finestra_trapianto": [], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Columnea gloriosa, p. 312-313$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Cordyline terminalis$t$,
  $t$Cordyline terminalis$t$,
  $t$cordyline-terminalis$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Cordilina originaria dell'India orientale e delle isole del Pacifico; il nome deriva dalla forma a clava delle radici. Foglie verde-bronzo, ombreggiate di rosa o rosso.$t$,
  $t${"luce": "Molta, ma diffusa: non tollera i raggi solari diretti", "acqua": "Costante grado di umidità nel terreno", "terreno": "Torba mista a sabbia in parti uguali"}$t$::jsonb,
  ARRAY[$t$Foglie ingiallite: possibile presenza di ragnetto rosso$t$, $t$Foglie marce: eccesso d'acqua$t$, $t$Caduta delle foglie più vecchie: processo naturale, nessun problema$t$, $t$Insetti bruni sotto foglie e fusti: cocciniglia$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "ogni 4-5 giorni", "autunno": null, "inverno": "ogni 8-9 giorni", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15 giorni", "autunno": null, "inverno": "una volta al mese", "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Liliaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Cordyline terminalis, p. 314-315$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

-- UPDATE: cyperus-papyrus (bozza PFAF, manutenzione tutta null) arricchita.
update specie set
  alert = alert || ARRAY[$t$Foglie che ingialliscono: annaffiatura insufficiente, immergere il vaso in acqua$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "sottovaso sempre pieno d'acqua (pianta acquatica/palustre)", "autunno": null, "inverno": null, "primavera": "sottovaso sempre pieno d'acqua (pianta acquatica/palustre)"}, "concimazione": {"estate": "concime liquido nell'acqua ogni 15 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Cyperus papyrus, p. 316-317$t$)
where slug = $t$cyperus-papyrus$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Cyperus papyrus, p. 316-317$t$ = any(fonti));
