-- Fase 3, diciannovesimo batch da guida-completa-giardino (pp. 426-433,
-- "Piante Aromatiche"): arricchisce 3 specie bozza PFAF a manutenzione
-- vuota. Lavandula officinalis (=angustifolia) saltata: gia' posseduta
-- (lavanda) e verificata via RHS.

update specie set
  alert = alert || ARRAY[$t$Teme il gelo, in inverno tenere al riparo (in serra nelle zone fredde)$t$, $t$Se si desidera raccogliere i semi: posizione ben soleggiata; se si vogliono usare le foglie: posizione in ombra$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "regolari, soprattutto in estate — in clima troppo asciutto la pianta va facilmente in seme", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Coriandrum sativum, p. 426-427$t$)
where slug = $t$coriandrum-sativum$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Coriandrum sativum, p. 426-427$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Teme decisamente il gelo$t$, $t$Si autosemina facilmente e può diventare infestante: recidere le ombrelle fiorite prima che disperdano i semi se non lo si desidera$t$, $t$Non tollera l'eccessiva umidità$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "moderate, non tollera l'eccessiva umidità", "autunno": null, "inverno": null, "primavera": "moderate, non tollera l'eccessiva umidità"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Foeniculum vulgare, p. 428-429$t$)
where slug = $t$foeniculum-vulgare$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Foeniculum vulgare, p. 428-429$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Non tollera affatto temperature rigide$t$, $t$Teme molto i ristagni idrici$t$, $t$Si autosemina spontaneamente$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "tagliare a 10-15 cm di altezza a fine marzo per rinnovare il vigore della pianta"}, "irrigazione": {"estate": "scarse, teme molto i ristagni idrici", "autunno": null, "inverno": null, "primavera": "scarse, teme molto i ristagni idrici"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Hyssopus officinalis, p. 430-431$t$)
where slug = $t$hyssopus-officinalis$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Hyssopus officinalis, p. 430-431$t$ = any(fonti));
