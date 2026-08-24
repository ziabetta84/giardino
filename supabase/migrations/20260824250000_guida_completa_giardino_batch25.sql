-- Fase 3, venticinquesimo batch da guida-completa-giardino (pp. 478-479,
-- "Piante Grasse"): Epiphyllum. (Le foto 193152/193204 duplicano pp.
-- 476-477 gia' importate nel batch24, nessuna azione aggiuntiva li'.)

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Epiphyllum$t$,
  $t$Epiphyllum$t$,
  $t$epiphyllum$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Piante selezionate incrociando cactus del genere Epiphyllum con epifiti della foresta umida sudamericana, note anche come Phyllocactus ("cactus foglia"). Fusti ceroidi o piatti/ritorti, simili a foglie spesse e allungate, eretti o ricadenti fino a 90 cm, margini dentellati o crestati con areole lanose e poche spine setolose (a volte assenti). Fiori grandi e colorati, a volte spettacolari, già dai primi anni di vita. Specie nota: Epiphyllum ackermannii (fiori a imbuto rosso cremisi, petali irregolari lunghi fino a 20 cm, fioritura intermittente anche tutto l'anno).$t$,
  $t${"luce": "Solare indiretta o filtrata, non tollera le basse temperature", "acqua": "Terriccio ricco e sempre umido, mai lasciato asciugare (diversamente dalla maggior parte delle piante grasse)"}$t$::jsonb,
  ARRAY[$t$Ha bisogno di un periodo di riposo invernale, poca umidità e poche annaffiature$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": "poca umidità e poche annaffiature", "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "regolarmente, non appena iniziano a emettere i boccioli"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Epiphyllum, p. 478-479$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
