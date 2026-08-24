-- Fase 3, decimo batch da guida-completa-giardino (pp. 344-351, "Piante da
-- Appartamento"): Platycerium bifurcatum, Schefflera arboricola.
-- Sansevieria trifasciata e Scindapsus aureus (= Epipremnum aureum, "Pothos")
-- saltate: gia' possedute e verificate via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Platycerium bifurcatum$t$,
  $t$Platycerium bifurcatum$t$,
  $t$platycerium-bifurcatum$t$,
  $t$Polypodiaceae$t$,
  $t$perenne$t$,
  $t$Felce detta "Corna d'alce", originaria delle foreste tropicali: il nome deriva dalla foggia delle fronde ricadenti e frastagliate. Varietà Majus: fronde meno divise, molto robusta.$t$,
  $t${"luce": "Si adatta a qualsiasi luce, meglio se attenuata", "acqua": "Per immersione del vaso (non dall'alto), settimanale d'estate, ogni 15 giorni d'inverno", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Fronde che marciscono e cadono: eccesso d'acqua o luogo troppo freddo$t$, $t$Cocciniglie annidate nella peluria delle fronde: trattare con cotone imbevuto di alcol$t$, $t$Non tollera le correnti d'aria$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "settimanale, per immersione del vaso", "autunno": null, "inverno": "ogni 15 giorni", "primavera": null}, "concimazione": {"estate": "2-3 volte l'anno, pianta autosufficiente", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Polypodiaceae", "finestra_trapianto": [], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Platycerium bifurcatum, p. 344-345$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Schefflera arboricola$t$,
  $t$Schefflera arboricola$t$,
  $t$schefflera-arboricola$t$,
  $t$Araliaceae$t$,
  $t$perenne$t$,
  $t$Originaria di Australia, Nuova Zelanda, India. Robusta e duratura anche in luoghi poco luminosi e freddi. Varietà a foglie verde lucido o variegate (es. Gold Cappella, nei toni del giallo).$t$,
  $t${"luce": "Luogo illuminato, tollera anche penombra", "acqua": "Regolare senza ristagni", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Insetti bruni su fusti e sotto le foglie: cocciniglia$t$, $t$Ragnatela sulla pagina inferiore: ragnetto rosso$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "ogni 3-4 giorni", "autunno": null, "inverno": "ogni 10 giorni", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15-20 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Araliaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Schefflera arboricola, p. 348-349$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;
