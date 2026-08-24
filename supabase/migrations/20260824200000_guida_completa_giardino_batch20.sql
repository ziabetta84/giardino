-- Fase 3, ventesimo batch da guida-completa-giardino (pp. 434-441, "Piante
-- Aromatiche"): Malva silvestris, Mentha piperita. Melissa officinalis
-- (bozza, manutenzione vuota) arricchita. Ocimum basilicum saltato: gia'
-- posseduto (basilico) e verificato via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Malva silvestris$t$,
  $t$Malva silvestris$t$,
  $t$malva-silvestris$t$,
  $t$Malvaceae$t$,
  $t$biennale$t$,
  $t$Malva, biennale e talvolta perenne, portamento cespuglioso eretto o prostrato, fusto legnoso alla base. Foglie a 5-7 lobi arrotondati, margine dentato, coperte di peli. Fiori rosa violaceo con striature più scure da aprile a ottobre. Cresce spontanea in prati incolti, sentieri, ruderi.$t$,
  $t${"luce": "Posizione molto soleggiata", "acqua": "Regolari, soprattutto in estate", "terreno": "Fresco e ricco"}$t$::jsonb,
  ARRAY[$t$Non tollera affatto temperature rigide$t$, $t$Può essere attaccata dalla ruggine (crittogama) in inverno, difficile da risanare$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "regolari", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "terreno lavorato e concimato prima della semina/trapianto"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Malva silvestris, p. 434-435$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Mentha piperita$t$,
  $t$Mentha piperita$t$,
  $t$mentha-piperita$t$,
  $t$Labiatae$t$,
  $t$perenne$t$,
  $t$Menta piperita, erbacea perenne con apparato radicale molto sviluppato e ricco di stoloni, fusto quadrangolare eretto verde-violaceo. Fiori rosso-rosati a luglio. È un ibrido naturale tra Mentha aquatica e Mentha spicata. Specie affini: M. pulegium (terreno sabbioso), M. requienii (clima umido), M. longifolia (tollera aridità), M. aquatica (terreni paludosi).$t$,
  $t${"luce": "Posizione in semi-ombra", "acqua": "Regolari, teme i ristagni, evitare di bagnare le foglie", "terreno": "Ricco di sostanza organica"}$t$::jsonb,
  ARRAY[$t$Se non contenuta può diventare infestante: a fine stagione è meglio estirparla$t$, $t$Terreno poco drenato favorisce ruggine e marciumi radicali$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "regolari, senza bagnare le foglie", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Mentha piperita, p. 438-439$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

update specie set
  alert = alert || ARRAY[$t$Non tollera temperature eccessive, teme più il caldo/sole intenso che il freddo$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "regolari", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Melissa officinalis, p. 436-437$t$)
where slug = $t$melissa-officinalis$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Melissa officinalis, p. 436-437$t$ = any(fonti));
