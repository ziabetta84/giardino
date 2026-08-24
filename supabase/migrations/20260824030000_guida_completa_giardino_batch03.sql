-- Fase 3, terzo batch da guida-completa-giardino (pp. 294-301, "Piante da
-- Appartamento"): Aralia/Fatsia, Asparagus sprengeri, Asplenium nidus,
-- Caladium bicolor. Schede puntuali e specifiche -> verificato.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Aralia (Fatsia japonica)$t$,
  $t$Fatsia japonica$t$,
  $t$fatsia-japonica$t$,
  $t$Araliaceae$t$,
  $t$perenne$t$,
  $t$Detta comunemente Aralia, proviene dall'Asia orientale. Ha grandi foglie palmate e verdi, adatta anche alla coltivazione su terrazzi. Si distinguono due specie affini vendute con lo stesso nome comune: la Fatsia (Aralia) japonica dalle foglie larghe e lobate, e la Schefflera (Aralia) elegantissima dalle foglie frastagliate su lunghi rami.$t$,
  $t${"luce": "Anche zone poco luminose", "acqua": "Due o più volte a settimana, acqua non fredda, terriccio sempre un po' umido", "terreno": "Ricco, con aggiunta di torba"}$t$::jsonb,
  ARRAY[$t$Foglie non di un verde intenso o fusti lunghi e radi: fertilizzante insufficiente o pianta in un luogo troppo caldo$t$, $t$Soggetta ad attacchi di cocciniglie e afidi$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "accorciare i fusti troppo lunghi o esili, cospargendo di zolfo in polvere i punti di taglio per favorire la cicatrizzazione"}, "irrigazione": {"estate": "due o più volte a settimana", "autunno": null, "inverno": null, "primavera": "due o più volte a settimana"}, "concimazione": {"estate": "fertilizzante liquido ogni 15 giorni", "autunno": null, "inverno": null, "primavera": "fertilizzante liquido ogni 15 giorni"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Araliaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Aralia/Fatsia japonica, p. 294-295$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Asparagus sprengeri$t$,
  $t$Asparagus sprengeri$t$,
  $t$asparagus-sprengeri$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Asparagina originaria del Sudafrica, con lunghi rami ricadenti e fogliame piumoso (le foglie vere sono in realtà minuscole spine). Genera occasionalmente bacche rosse ornamentali. Specie affine più elegante ma più difficile da coltivare: Asparagus plumosus.$t$,
  $t${"luce": "Anche zone ombreggiate d'inverno, all'aperto (non in pieno sole) d'estate", "acqua": "Regolare, spruzzare spesso le fronde; teme sia la siccità sia l'acqua troppo calcarea"}$t$::jsonb,
  ARRAY[$t$Fronde che seccano per luce solare diretta troppo intensa o scarsità d'acqua$t$, $t$Fronde che ingialliscono: acqua troppo calcarea$t$, $t$Perde le foglioline se l'ambiente è troppo freddo$t$],
  $t${"npk": {"estate": null, "autunno": "5-5-5", "inverno": null, "primavera": "5-5-5"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": "ridotta, la pianta tollera anche solo 10°C", "primavera": null}, "concimazione": {"estate": "da aprile a settembre, con aggiunta mensile di un prodotto a base di ferro", "autunno": "da aprile a settembre, con aggiunta mensile di un prodotto a base di ferro", "inverno": null, "primavera": "da aprile a settembre, con aggiunta mensile di un prodotto a base di ferro"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": ["primavera"], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Liliaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Asparagus sprengeri, p. 296-297$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Asplenium nidus$t$,
  $t$Asplenium nidus$t$,
  $t$asplenium-nidus$t$,
  $t$Polypodiaceae$t$,
  $t$perenne$t$,
  $t$Felce sempreverde diffusa dall'India al Giappone e all'Australia, con foglie a rosetta di un verde acceso e lucido; la concavità centrale, che ricorda un nido d'uccello, dà il nome comune "asplenio a nido d'uccello".$t$,
  $t${"luce": "Diffusa, filtrata; tollera brevemente anche un po' di luce diretta ma scolorisce le foglie se eccessiva", "acqua": "Buon grado di umidità ambientale, senza mai ristagni — utile evitare il contatto diretto tra vaso e sottovaso", "terreno": "Torboso, ricco"}$t$::jsonb,
  ARRAY[$t$Fronde macchiate di giallo: cocciniglie brune$t$, $t$Ristagno d'acqua: rischio di marciume e attacco fungino, macchie scure sulle foglie richiedono un anticrittogamico tempestivo$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "concime liquido circa una volta al mese", "autunno": null, "inverno": null, "primavera": "concime liquido circa una volta al mese"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Polypodiaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Asplenium nidus, p. 298-299$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Caladium bicolor$t$,
  $t$Caladium bicolor$t$,
  $t$caladium-bicolor$t$,
  $t$Araceae$t$,
  $t$perenne$t$,
  $t$Caladio originario del Brasile e della Guyana, con grandi foglie cuoriformi variegate — dal bianco avorio al rosa al rosso, con colorazione più intensa al centro verso l'esterno.$t$,
  $t${"luce": "Molta luce, non diretta", "acqua": "Moderata: lasciare asciugare il terreno tra un'annaffiatura e l'altra, mai bagnare le foglie per evitare malattie criptogamiche", "terreno": "Terreno da giardino mescolato a torba"}$t$::jsonb,
  ARRAY[$t$Foglie che si piegano e accartocciano: eccesso d'acqua o ambiente troppo freddo (sotto i 15°C)$t$, $t$Evitare ristagni: rischio di marciume dei piccoli tuberi che si formano attorno a quello principale$t$],
  $t${"npk": {"estate": "10-10-10", "autunno": null, "inverno": null, "primavera": "10-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "ogni 15 giorni con concime liquido diluito, nel periodo vegetativo", "autunno": null, "inverno": null, "primavera": "ogni 15 giorni con concime liquido diluito, nel periodo vegetativo"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Araceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Caladium bicolor, p. 300-301$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;
