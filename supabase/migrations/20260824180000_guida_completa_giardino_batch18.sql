-- Fase 3, diciottesimo batch da guida-completa-giardino (pp. 418-425, nuovo
-- capitolo "Piante Aromatiche"): arricchisce 3 specie bozza PFAF a
-- manutenzione vuota con dati reali di coltivazione. Capsicum annuum
-- (peperoncino/peperone) saltato: gia' posseduto e verificato via RHS.

update specie set
  alert = alert || ARRAY[$t$Pianta difficile da conservare essiccata: meglio scalare le semine ogni 2 settimane da primavera per avere sempre foglie fresche disponibili$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "cimare le infiorescenze appena si formano, per mantenere la qualità aromatica delle foglie"}, "irrigazione": {"estate": "regolare, attenzione ai ristagni", "autunno": null, "inverno": null, "primavera": "regolare, attenzione ai ristagni"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Anthriscus cerefolium, p. 418-419$t$)
where slug = $t$anthriscus-cerefolium$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Anthriscus cerefolium, p. 418-419$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Se si lasciano andare a seme i fiori senza toglierli, la pianta si riproduce spontaneamente per l'anno seguente (rischio infestante)$t$, $t$Da consumare sempre cotta: da cruda i peli che ricoprono la pianta hanno effetto urticante$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "regolari, soprattutto in estate", "autunno": null, "inverno": null, "primavera": "regolari"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Borago officinalis, p. 420-421$t$)
where slug = $t$borago-officinalis$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Borago officinalis, p. 420-421$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Tende a diventare infestante se lasciata montare a seme senza estirparla$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "solo in estate e nei periodi particolarmente secchi, senza abbondare", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Carum carvi, p. 424-425$t$)
where slug = $t$carum-carvi$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Carum carvi, p. 424-425$t$ = any(fonti));
