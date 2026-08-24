-- Fase 3, dodicesimo batch da guida-completa-giardino (pp. 362-369, nuovo
-- capitolo "Piante Ornamentali" — formato piu' sintetico: Avversita',
-- resistenza al freddo, esposizione, irrigazione, colore, uso, niente
-- npk/potatura stagionali dettagliati): Ageratum, Alyssum, Anemone,
-- Antirrhinum, Aster. Agapanthus, Aquilegia vulgaris, Begonia saltate:
-- gia' possedute e verificate via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Ageratum$t$,
  $t$Ageratum$t$,
  $t$ageratum$t$,
  $t$Compositae$t$,
  $t$annuale$t$,
  $t$Agerato, perenne spesso coltivato come annuale, fiori riuniti in capolini fitti simili a piumini, molto numerosi e persistenti; foglie ovato-triangolari con margine dentato. Colore fiore: blu, bianco o rosa, persistente anche da appassito. Uso: bordure, adatto a vaso e cassette.$t$,
  $t${"luce": "Esposizioni riparate e soleggiate", "acqua": "Solo quando il terreno sottostante è asciutto"}$t$::jsonb,
  ARRAY[$t$Soffre il gelo invernale$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Ageratum, p. 363$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Alyssum$t$,
  $t$Alyssum$t$,
  $t$alyssum$t$,
  $t$Cruciferae$t$,
  $t$perenne$t$,
  $t$Alisso, pianta perenne a cespuglio (alcune specie annuali, circa 80 specie nel genere), fiori piccoli in corti racemi terminali, fioritura da marzo-aprile a settembre. Colore fiore: bianco candido, rosa, rosa carminio, viola, esistono varietà gialle. Uso: bordure (non supera i 30 cm), giardini rocciosi, fenditure di muri.$t$,
  $t${"luce": "Sole e luce in abbondanza", "acqua": "Pochi interventi irrigui, concentrati nei periodi di elevata e persistente siccità"}$t$::jsonb,
  ARRAY[$t$Non sopporta ristagni d'acqua$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Alyssum, p. 364-365$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Anemone$t$,
  $t$Anemone$t$,
  $t$anemone$t$,
  $t$Ranunculaceae$t$,
  $t$perenne$t$,
  $t$Genere perenne, rustico, circa 150 specie e numerosissime varietà; fiori singoli a corolla semplice o doppia, foglie pennatosette verde brillante. Specie erbacee (fioritura primaverile) e rizomatose (fioritura estivo-autunnale). Colore: bianco, rosso, viola, azzurrino, rosaceo. Uso: balconi ombrosi (A. japonica), aiuole e bordure (A. coronaria).$t$,
  $t${"luce": "Pieno sole o zone ombrose", "acqua": "Interventi irrigui sufficienti a mantenere il terreno sempre umido, soffre i ristagni idrici"}$t$::jsonb,
  ARRAY[$t$Spesso preda di afidi: trattare subito con prodotti specifici alla comparsa$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Anemone, p. 365$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Antirrhinum$t$,
  $t$Antirrhinum$t$,
  $t$antirrhinum$t$,
  $t$Scrophulariaceae$t$,
  $t$annuale$t$,
  $t$Bocca di leone, buona rusticità, annuale o perenne a seconda delle specie, portamento eretto, taglia da 20 cm a oltre il metro secondo varietà. Fiori a corolla lobata in lunghi racemi. Colore: predominante il giallo, facile trovare varietà rosse, rosa, bianche. Uso: varietà nane per giardini rocciosi (A. pumila), le altre per fiore reciso e coltivazione in vaso.$t$,
  $t${"luce": "Pieno sole, vegeta bene anche a mezz'ombra", "acqua": "Innaffiature molto frequenti"}$t$::jsonb,
  ARRAY[$t$Grande nemico: la ruggine, trattare con anticrittogamico o solfato di rame$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Antirrhinum, p. 366$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Aster$t$,
  $t$Aster$t$,
  $t$aster$t$,
  $t$Compositae$t$,
  $t$perenne$t$,
  $t$Astro, genere di oltre 250 specie (perenni e annuali), portamento/forma/resistenza climatica molto variabili. Fiori simili a margherite con cuore giallo o aranciato, isolati o multipli su assi terminali. Colore: ogni colore, cuore sempre giallo-arancio. Uso: macchie di colore isolate, anche in vaso per balconi e terrazze.$t$,
  $t${"luce": "Posizioni semiombreggiate", "acqua": "Abbondanti, soprattutto prima della comparsa dei fiori"}$t$::jsonb,
  ARRAY[$t$Soggetto a oidio (mal bianco)$t$, $t$Le varietà più alte necessitano di sostegni$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Aster, p. 368$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
