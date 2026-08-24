-- Fase 3, settimo batch da guida-completa-giardino (pp. 328-333, "Piante da
-- Appartamento"): Howea forsteriana, Maranta leuconeura. Fittonia
-- argyroneura saltata: e' il nome sinonimo di Fittonia albivenis, gia'
-- posseduta e verificata via RHS (fonte piu' ricca). Le foto 191605 e
-- 191620 sono duplicate (stessa pagina 332-333), usata una sola volta.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Kentia (Howea forsteriana)$t$,
  $t$Howea forsteriana$t$,
  $t$howea-forsteriana$t$,
  $t$Palmae$t$,
  $t$perenne$t$,
  $t$Detta comunemente Kentia o Chenzia, originaria dell'Isola di Lord Howe (Oceano Pacifico, al largo dell'Australia). Ha lunghe fronde ricadenti; pianta di facile ambientazione in appartamento.$t$,
  $t${"luce": "Luoghi luminosi, si adatta anche a zone più ombrose", "acqua": "1-2 volte a settimana evitando ristagni, con foglie bagnate ogni 3-4 giorni ad acqua a temperatura ambiente", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Foglie secche: aria troppo secca e calda, spostare in luogo più fresco e annaffiare$t$, $t$Punte delle foglie scure: cocciniglia, spruzzare acqua evitando correnti d'aria$t$],
  $t${"npk": {"estate": "10-5-5", "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "1-2 volte a settimana", "autunno": null, "inverno": "una volta a settimana", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Palmae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Kentia/Howea forsteriana, p. 330-331$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Maranta leuconeura$t$,
  $t$Maranta leuconeura$t$,
  $t$maranta-leuconeura$t$,
  $t$Marantaceae$t$,
  $t$perenne$t$,
  $t$Maranta originaria dell'America equatoriale. Varietà diffuse: Kerchoviana (foglie verde chiaro con nervature scure) e Massangeana (foglie verde più scuro con nervature rossastre).$t$,
  $t${"luce": "Buona illuminazione, mai sole diretto", "acqua": "Con acqua tiepida, non tollera le correnti d'aria", "terreno": "Torba"}$t$::jsonb,
  ARRAY[$t$Foglie scolorite con ragnatele nella pagina inferiore: ragnetto rosso$t$, $t$Macchie e seccume ai margini delle foglie: attacco fungino, trattare con anticrittogamico$t$, $t$Lesioni sul lembo fogliare: ambiente troppo freddo o scarsa umidità$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "ogni 2-3 giorni", "autunno": null, "inverno": "ogni 10 giorni", "primavera": null}, "concimazione": {"estate": "concime liquido ricco di azoto ogni due settimane", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Marantaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Maranta leuconeura, p. 332-333$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;
