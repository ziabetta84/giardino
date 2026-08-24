-- Fase 3, quarto batch da guida-completa-giardino (pp. 302-309, "Piante da
-- Appartamento"): Calathea (genere, gia' verificato via RHS: saltato),
-- Chamaedorea elegans, Chlorophytum comosum, Cocos nucifera.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Chamaedorea elegans$t$,
  $t$Chamaedorea elegans$t$,
  $t$chamaedorea-elegans$t$,
  $t$Palmae$t$,
  $t$perenne$t$,
  $t$Palma originaria del Messico, tra le piante d'appartamento più resistenti. Può superare il metro di altezza e si presta bene alla coltivazione in idrocoltura. In commercio si trova spesso anche con i nomi di Neanthe bella o Collinia elegans.$t$,
  $t${"luce": "Tollera anche zone poco luminose", "acqua": "Moderata, tollera bene la siccità ma non gradisce l'aria troppo secca"}$t$::jsonb,
  ARRAY[$t$Punte delle foglie scure: troppa siccità, immergere il vaso fino all'orlo in acqua per 15-20 minuti$t$, $t$Foglie ingiallite nella pagina inferiore: possibile attacco di ragnetto rosso$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": "20-10-10", "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "regolare", "autunno": null, "inverno": "ridotta", "primavera": "regolare"}, "concimazione": {"estate": "ogni 15 giorni con concime liquido, da aprile a settembre", "autunno": null, "inverno": null, "primavera": "ogni 15 giorni con concime liquido, da aprile a settembre"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Palmae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Chamaedorea elegans, p. 304-305$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Chlorophytum comosum$t$,
  $t$Chlorophytum comosum$t$,
  $t$chlorophytum-comosum$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Falangio originario del Sudafrica, di rapida moltiplicazione e facile coltivazione. Fogliame verde rigoglioso con una larga fascia bianco-giallognola. Dagli steli fiorali germogliano piccole piantine che, se toccano il terreno o vengono poste in acqua, radicano dando origine a nuove piante.$t$,
  $t${"luce": "Molta luce, la scarsità di luce fa perdere alla pianta il suo caratteristico colore", "terreno": "Ricco"}$t$::jsonb,
  ARRAY[$t$Punte delle foglie che imbruniscono e crescita stentata: concimazione insufficiente, riprendere con apporti regolari$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15 giorni", "autunno": null, "inverno": null, "primavera": "concime liquido ogni 15 giorni"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Liliaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Chlorophytum comosum, p. 306-307$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

-- UPDATE: cocos-nucifera (bozza PFAF, manutenzione tutta null) arricchita.
update specie set
  alert = alert || ARRAY[$t$Non sistemarla in composizione con altre piante: soggetta a cocciniglie e ragnetto rosso, soprattutto in ambiente troppo secco$t$],
  manutenzione = $t${"npk": {"estate": "10-5-5", "autunno": null, "inverno": null, "primavera": "10-5-5"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "2-3 volte a settimana", "autunno": null, "inverno": "un po' meno", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15-20 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Cocos nucifera, p. 308-309$t$)
where slug = $t$cocos-nucifera$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Cocos nucifera, p. 308-309$t$ = any(fonti));
