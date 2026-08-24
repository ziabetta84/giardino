-- Fase 3, ottavo batch da guida-completa-giardino (pp. 334-341, "Piante da
-- Appartamento"): Nephrolepis exaltata, Peperomia (genere), Philodendron
-- (genere); monstera-deliciosa (bozza PFAF, manutenzione vuota) arricchita.

update specie set
  alert = alert || ARRAY[$t$Fogliame che cade: pianta tenuta in luogo troppo secco, immergerla in un secchio d'acqua e far sgocciolare$t$, $t$Foglie scure: pianta troppo fredda$t$, $t$Foglie ingiallite: eccesso d'acqua$t$],
  manutenzione = $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "una volta a settimana", "autunno": null, "inverno": "una volta al mese", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 20 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Monstera deliciosa, p. 334-335$t$)
where slug = $t$monstera-deliciosa$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Monstera deliciosa, p. 334-335$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Nephrolepis exaltata$t$,
  $t$Nephrolepis exaltata$t$,
  $t$nephrolepis-exaltata$t$,
  $t$Polypodiaceae$t$,
  $t$perenne$t$,
  $t$Nefrolepide o felce di Boston, originaria dei paesi tropicali, molto decorativa per il fogliame verde intenso. Varietà diffuse: Marechalii (foglie più corte), Meyendorfii (sfumature rossastre), Tricolor.$t$,
  $t${"luce": "Diffusa, filtrata da tende, mai sole diretto", "acqua": "Terriccio sempre umido senza ristagni; utile un letto di ghiaino nel sottovaso per l'umidità ambientale", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Fogliame che cade: pianta tenuta in luogo secco, immergere e far sgocciolare$t$, $t$Tenere lontana da correnti d'aria$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": "concime liquido ogni 20-25 giorni", "autunno": null, "inverno": "ogni 30-35 giorni", "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Polypodiaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Nephrolepis exaltata, p. 336-337$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Peperomia$t$,
  $t$Peperomia$t$,
  $t$peperomia$t$,
  $t$Piperaceae$t$,
  $t$perenne$t$,
  $t$Genere originario dell'America tropicale e sub-tropicale. Specie diffuse: Peperomia magnoliifolia (foglie verdi con screziature bianco-crema) e Peperomia caperata (foglie verde scuro rugose, orlate di rosso).$t$,
  $t${"luce": "Buona, adatta a davanzali luminosi", "acqua": "Scarsa, non tollera ristagni", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Foglie che cadono: ambiente troppo freddo$t$, $t$Foglie con bolle: eccesso d'acqua — non pulire le foglie, solo spruzzare con acqua tiepida$t$, $t$Ragnatele sotto le foglie: ragnetto rosso, trattare con acaricida nei casi avanzati$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "cimare i germogli apicali per contenere l'infoltimento, asportare foglie malate"}, "irrigazione": {"estate": "ogni 10 giorni", "autunno": null, "inverno": "ogni 15-20 giorni", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 20-25 giorni", "autunno": null, "inverno": "ogni 30 giorni", "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Piperaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Peperomia, p. 338-339$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Philodendron$t$,
  $t$Philodendron$t$,
  $t$philodendron$t$,
  $t$Araceae$t$,
  $t$perenne$t$,
  $t$Filodendro di origine tropicale (Brasile, Guyana, Colombia). Specie diffuse: scandens (la più resistente e robusta per gli appartamenti), bipennifolium, selloum, hastatum, bipinnatifidum. Pianta facile da coltivare e moltiplicare.$t$,
  $t${"luce": "Diffusa, tollera anche zone ombrose, mai sole diretto", "acqua": "Abbondante, con spruzzature frequenti sulle foglie", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Punte delle foglie secche: eliminarle con le forbici$t$, $t$Possibili attacchi di cocciniglie e afidi, specie a fine inverno$t$, $t$Non tollera le correnti d'aria$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "almeno 2 volte a settimana", "autunno": null, "inverno": "una volta a settimana", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15 giorni", "autunno": null, "inverno": null, "primavera": "concime liquido ogni 15 giorni"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Araceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Philodendron, p. 340-341$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
