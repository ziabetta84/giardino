-- Fase 3, enciclopedia-piante-da-arbusti, batch finale: genere Dipelta
-- (fonti/ridimensionate/20.md) — l'ultimo genere del libro rimasto scoperto,
-- citato in 18.md solo nella tabella riepilogativa. Nessuna riga esistente
-- in catalogo per nessuna delle 2 specie: entrambe nuove, in bozza.

insert into specie (nome, nome_scientifico, slug, ciclo_vitale, descrizione, esigenze, fonti, stato_verifica) values
($t$Dipelta floribunda$t$, $t$Dipelta floribunda$t$, $t$dipelta-floribunda$t$, $t$perenne$t$,
 $t$Abbastanza resistente al gelo, 3-5 m, corteccia sfogliante, rami giovani ricurvati, foglie ovato-lanceolate acute leggermente seghettate (2-10 cm), fiori profumati penduli bianchi, gialli all'interno, lunghi 2,5-4 cm (maggio-luglio).$t$,
 $t${"luce": "Pieno sole / Mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di arbusti (Edicart, 1995) — Dipelta floribunda$t$]::text[], $t$bozza$t$),
($t$Dipelta ventricosa$t$, $t$Dipelta ventricosa$t$, $t$dipelta-ventricosa$t$, $t$perenne$t$,
 $t$Abbastanza resistente al gelo, fino a 5 m, fusti pubescenti, foglie dentate leggermente pelose (5-15 cm), fiori rosa scuro, arancioni all'interno, con petali piatti e liberi, riuniti a 3 in mazzetti terminali o solitari all'ascella della foglia (maggio-luglio).$t$,
 $t${"luce": "Pieno sole / Mezz'ombra"}$t$::jsonb,
 ARRAY[$t$Il giardino di arbusti (Edicart, 1995) — Dipelta ventricosa$t$]::text[], $t$bozza$t$)
on conflict (slug) do nothing;
