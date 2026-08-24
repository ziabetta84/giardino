-- Fase 3, sedicesimo batch da guida-completa-giardino (pp. 396-403, "Piante
-- Ornamentali"): Paeonia, Pelargonium, Petunia hybrida, Phlox, Rosa.
-- Rhododendron simsii e Primula vulgaris saltate: gia' possedute e
-- verificate via RHS. Portulaca grandiflora (bozza) saltata: esigenze gia'
-- plausibili, il libro non aggiunge dati numerici ne' fatti nuovi.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Paeonia$t$,
  $t$Paeonia$t$,
  $t$paeonia$t$,
  $t$Ranunculaceae$t$,
  $t$perenne$t$,
  $t$Peonia, genere perenne con diverse specie e ibridi, fiori variamente colorati, semplici, semidoppi, doppi (da 3 a 5 per stelo), profumati. Foglie alterne, ternate o biternate, foglioline ovali-lanceolate spesso saldate alla base. Esistono specie arbustive (P. suffruticosa). Colore: bianco, rosa, violetto, con macchie e striature verso il centro. Uso: rustica, di coltura facile, adatta anche in vaso.$t$,
  $t${"luce": "Posizioni a mezz'ombra", "acqua": "Annaffiature regolari", "terreno": "Si adatta a qualsiasi terreno, non ama i trapianti"}$t$::jsonb,
  ARRAY[$t$Macchie scure su boccioli e fogliame dovute a virosi: bruciare le piante colpite e sterilizzare il suolo$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Paeonia, p. 396$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Pelargonium$t$,
  $t$Pelargonium$t$,
  $t$pelargonium$t$,
  $t$Geraniaceae$t$,
  $t$perenne$t$,
  $t$Geranio, originario delle regioni temperate e subtropicali dell'Africa. Le varietà più coltivate sono i gerani edera e i gerani zonali. Può essere coltivato anche in appartamento, ma i risultati migliori li dà su balcone o terrazzo. Colore: rosso, bianco, rosa, lilla ecc.$t$,
  $t${"luce": "Molta luce", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Moscerini bianchi al tocco delle foglie: aleuroidi, intervenire con insetticida specifico$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Pelargonium, p. 397$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Petunia hybrida$t$,
  $t$Petunia hybrida$t$,
  $t$petunia-hybrida$t$,
  $t$Solanaceae$t$,
  $t$biennale$t$,
  $t$Erbacea cespitosa biennale coltivata come annuale, risultato di incroci e selezioni (il genere comprende circa 25 specie originarie dell'America sudoccidentale e del Brasile). Fiori imbutiformi, fusti erbacei eretti semplici o ramosi, foglie alterne ternate o biternate. Colore: dal bianco, rosa, violetto, con macchie e striature verso il centro. Uso: giardini, terrazzi, finestre, balconi.$t$,
  $t${"luce": "Esposizioni al sole ben luminose", "acqua": "Abbondanti"}$t$::jsonb,
  ARRAY[$t$Vento e pioggia possono danneggiarla, per il resto pianta piuttosto resistente$t$, $t$Teme particolarmente il freddo: preferisce luoghi riparati$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Petunia hybrida, p. 398$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Phlox$t$,
  $t$Phlox$t$,
  $t$phlox$t$,
  $t$Polemoniaceae$t$,
  $t$perenne$t$,
  $t$Flox, pianta annuale o perenne, altezza variabile secondo specie. Specie note: subulata, paniculata, drummondii. Fiori a stella, isolati e abbondanti o riuniti in vistose pannocchie. Fioritura variabile da aprile ad agosto, in alcuni casi fino a ottobre. Colore: bianco, rosso, porpora, lilla, salmone, a tinta unita o variegato e striato.$t$,
  $t${"luce": "Predilige il pieno sole, si coltiva bene anche a mezz'ombra", "acqua": "Abbondanti e frequenti innaffiature"}$t$::jsonb,
  ARRAY[$t$Non si segnalano malattie o parassiti particolari$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Phlox, p. 399$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Rosa$t$,
  $t$Rosa$t$,
  $t$rosa$t$,
  $t$Rosaceae$t$,
  $t$perenne$t$,
  $t$Pianta generalmente spinosa e decidua, foglie alterne imparipennate a margine dentato. Fiori solitari o raggruppati in corimbi, corolla semplice, semidoppia o doppia, con colorazioni molto varie.$t$,
  $t${"luce": "Posizioni molto soleggiate, evitare quelle poco soleggiate", "acqua": "Normale, ma costante durante la fioritura", "terreno": "Piuttosto compatto, leggermente calcareo, ben concimato, senza ristagni d'acqua"}$t$::jsonb,
  ARRAY[$t$Cancro: zone brune necrotiche prima sui germogli poi sugli steli$t$, $t$Oidio: muffa biancastra su germogli, boccioli e foglie, favorito da umidità stagnante e impianti fitti$t$, $t$Eccellente resistenza al freddo, ma varietà sensibili vanno protette$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Rosa, p. 403$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
