-- Fase 3, ventunesimo batch da guida-completa-giardino (pp. 442-449, "Piante
-- Aromatiche"): arricchisce Origanum majorana (Maggiorana, bozza, manutenzione
-- vuota). Origanum vulgare, Rosmarinus officinalis, Salvia officinalis
-- saltate: gia' possedute (origano/rosmarino/salvia) e verificate via RHS.

update specie set
  alert = alert || ARRAY[$t$Molto sensibile ai ristagni idrici: annaffiare solo in caso di stagione molto secca$t$, $t$Nelle zone a clima rigido perde la caratteristica di perenne e diviene annuale$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": "potare a pochi centimetri dal suolo a fine stagione, proteggendo le radici con paglia dal freddo", "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "solo in caso di stagione molto secca", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Origanum majorana, p. 442-443$t$)
where slug = $t$origanum-majorana$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Origanum majorana, p. 442-443$t$ = any(fonti));
