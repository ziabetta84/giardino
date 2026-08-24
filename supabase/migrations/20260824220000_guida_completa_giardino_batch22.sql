-- Fase 3, ventiduesimo batch da guida-completa-giardino (pp. 450-459):
-- chiude "Piante Aromatiche" (Satureja hortensis, Thymus vulgaris,
-- arricchite) e apre "Piante Grasse" (Aloe, genere, nuovo inserimento).
-- Aeonium e Agave saltate: gia' possedute e verificate via RHS.

update specie set
  alert = alert || ARRAY[$t$Si riproduce spontaneamente autoseminandosi$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "regolari", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Satureja hortensis, p. 450-451$t$)
where slug = $t$satureja-hortensis$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Satureja hortensis, p. 450-451$t$ = any(fonti));

update specie set
  alert = alert || ARRAY[$t$Tanto comune da poter diventare infestante$t$, $t$Proteggere il collo con ghiaia o sabbia grossa contro l'eccessiva umidità invernale$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "qualche annaffiatura in più dopo l'impianto, poi si adatta bene alla siccità", "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Thymus vulgaris, p. 452-453$t$)
where slug = $t$thymus-vulgaris$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Thymus vulgaris, p. 452-453$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Aloe$t$,
  $t$Aloe$t$,
  $t$aloe$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Genere originario di Africa e Madagascar, rosette acauli o su fusto/rami, foglie molto carnose, spesso con piccoli rilievi bianchi e dentini sul margine. Simile alle agavi ma con infiorescenze pendule. Specie note: Aloe aristata (rosetta acaule 10-20 cm, Sudafrica), Aloe ferox (fusto fino a 4 m, foglie fino a 1 m, fiori giallo-rossi, Sudafrica).$t$,
  $t${"luce": "Pieno sole"}$t$::jsonb,
  ARRAY[$t$Genere resistente alla siccità, teme i ristagni d'acqua$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Aloe, p. 458-459$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
