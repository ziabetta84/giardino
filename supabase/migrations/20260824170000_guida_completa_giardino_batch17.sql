-- Fase 3, diciassettesimo batch da guida-completa-giardino (pp. 408-413):
-- Tulipa, Viola, Zephyrantes. Chiude il capitolo "Piante Ornamentali".
-- Verbena (=Verbena hybrida), Zinnia, Zantedeschia aethiopica, Allium
-- schoenoprasum saltate: gia' possedute e verificate via RHS.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Tulipa$t$,
  $t$Tulipa$t$,
  $t$tulipa$t$,
  $t$Liliaceae$t$,
  $t$perenne$t$,
  $t$Tulipano, bulbosa perenne diffusa in centinaia di varietà. Fiori primaverili singoli, portati da un solo asse fiorale, terminali, formati da petali grandi, carnosi, disposti a coppa, con margine terminale liscio, frastagliato, appuntito o arrotondato. Foglie sessili, rade, basali, ovato-lanceolate verde glauco, a volte screziate. Colore: tutti i colori dal bianco al viola scuro, anche screziato/variegato/multicolore. Uso: bordure, vaso, cassette, fiore reciso.$t$,
  $t${"luce": "Pieno sole, si adatta bene anche a mezz'ombra", "acqua": "Annaffiature regolari"}$t$::jsonb,
  ARRAY[$t$Soggetto agli attacchi di diversi tipi di parassiti$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Tulipa, p. 408$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Viola$t$,
  $t$Viola$t$,
  $t$viola$t$,
  $t$Violaceae$t$,
  $t$perenne$t$,
  $t$Genere di circa 400 specie, diffuse nell'emisfero settentrionale temperato, perenni, biennali o annuali. Specie note: Viola tricolor (viola del pensiero), odorata (viola mammola), cornuta, x wittrockiana, biflora. Fiori spesso bicolori con cuore scuro e corolla variabile. Uso: aiuole dall'inizio della primavera, anche in vaso per balconi e terrazzi.$t$,
  $t${"luce": "Posizioni soleggiate o leggermente in ombra", "acqua": "Distribuire acqua in caso di siccità", "terreno": "Fertile, privo di ristagni d'acqua"}$t$::jsonb,
  ARRAY[$t$Foglie che ingialliscono e la pianta muore: distruggere le piante infette e trapiantare quelle sane in altro luogo$t$, $t$Il troppo calore blocca la fioritura, amano il clima temperato-fresco$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Viola, p. 410$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Zephyrantes$t$,
  $t$Zephyrantes$t$,
  $t$zephyrantes$t$,
  $t$Amaryllidaceae$t$,
  $t$perenne$t$,
  $t$Genere originario dell'Argentina e dell'America del nord, circa 71 specie erbacee perenni, decidue o sempreverdi. Foglie strette, simili a fili d'erba, compaiono con i fiori a fine estate-inizio autunno. Specie coltivate: Zephyrantes candida (fiori bianchi), atamasca (fiori sfumati di viola porpora). Colore: bianco, rosso, rosa o giallo secondo specie. Uso: in vaso, in terriccio organico umido con torba, sabbia e foglie.$t$,
  $t${"luce": "Posizioni soleggiate", "acqua": "Annaffiature regolari e frequenti", "terreno": "Umido, in leggera penombra"}$t$::jsonb,
  ARRAY[$t$Soffre per il freddo eccessivo: coprire con paglia o foglie la pianta lasciata a dimora, specie oltre la Zephyrantes candida/atamasca (tolleranti fino a -5°C) le altre specie sono più sensibili$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Zephyrantes, p. 411$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
