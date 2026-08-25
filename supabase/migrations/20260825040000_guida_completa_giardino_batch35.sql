-- Fase 3, trentacinquesimo batch da guida-completa-giardino (pp. 554-561,
-- "Piante Arbustacee"): Genista, Kerria, Lagerstroemia. Hibiscus saltato:
-- gia' presente e verificato da altra fonte Edicart fotografata in
-- precedenza.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Genista$t$,
  $t$Genista$t$,
  $t$genista$t$,
  $t$Leguminosae$t$,
  $t$perenne$t$,
  $t$Ginestra, le specie sono arbusti rustici, decidui, anche se talvolta parzialmente rustici, decidui, anche se talvolta parzialmente decidui o sempreverdi, con talvolta rametti opposti (che possono ingannare per il colore verde della scorza dei giovani getti). I rami, a volte spinosi, hanno di solito foglie alterne, semplici o trifogliate, opposte, semplici o trifogliate, qualche volta la pianta risulta priva di foglie. I fiori, riuniti in racemi terminali o più raramente ascellari, hanno mazzi di solito uno splendido colore giallo dorato, ma possono essere anche bianchi. Tra le specie più note ricordiamo la Genista hispanica, la lydia, la monosperma (fiori bianchi) e la Genista aethnensis, dal portamento piuttosto simile a un alberello.$t$,
  $t${"luce": "Ama il caldo, ma resiste assai bene anche al freddo", "acqua": "Raramente necessita di acqua, anzi sopporta assai bene i terreni ascciutti, anche secchi, non soggetti comunque ai temuti ristagni idrici", "terreno": "Predilige quelli poveri, sabbiosi, anche secchi; più un terreno è povero, migliore è la fioritura. La Genista lydia si adatta a vivere in terreni rocciosi ben si adatta anche a quelli con l'unica specie che tollera esporsi coltivata in terreno siliceo"}$t$::jsonb,
  ARRAY[$t$Si tratta di un genere piuttosto rustico, difficilmente colpito da attacchi parassitari$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "nelle piante adulte si esegue una potatura di sfoltimento, anzi sopporta assai bene i tagli. Nel caso di piante giovani, ci si limita per lo più agli interventi di potatura"}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "raramente necessita di concimazioni, per cui si limita per lo più agli interventi invernali e primaverili"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Genista, p. 554-555$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Kerria$t$,
  $t$Kerria$t$,
  $t$kerria$t$,
  $t$Rosaceae$t$,
  $t$perenne$t$,
  $t$Arbusto compatto, pollonante, deciduo, originario della Cina e del Giappone, introdotta in Europa nel XVIII secolo da William Kerr, da qui il nome. I rami pendenti sono rivestiti da una lucente corteccia verdolina; le foglie alterne, ovato-lanceolate e rugose, hanno fiori dorati, semplici o doppi, sono dop-piamente dentate. Comprende una sola specie, la Kerria japonica, con diverse varietà: la Kerria Pleniflora (fiori doppi e di un colore giallo intenso), la Picta (foglie argenteo-variegata) e la Albiflora (colore bianco crema, foglie screziate di colore bianco tipo rustico).$t$,
  $t${"luce": "Gradisce esposizioni in piena luce o a mezz'ombra, pertanto sopporta bene anche le basse temperature", "acqua": "In caso di periodi primaverili siccitosi, distribuire acqua in abbondanza sostanziosa a base di minerale e organico", "terreno": "Vegeta bene in quasi tutti i tipi di terreno, a esclusione di quelli troppo umidi e molto calcarei"}$t$::jsonb,
  ARRAY[$t$La specie Kerria non presenta significative suscettibilità in modo particolare al freddo, la pianta non presenta particolari inconvenienti né difficoltà di coltivazione$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "importante che la sommini-strazione sia particolarmente robusta, per favorire la formazione di nuovi getti dopo la fioritura"}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Kerria, p. 558-559$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Lagerstroemia$t$,
  $t$Lagerstroemia$t$,
  $t$lagerstroemia$t$,
  $t$Lythraceae$t$,
  $t$perenne$t$,
  $t$Arboscello o arbusto, deciduo o più o meno sempreverde, originario dell'Asia. Si fa apprezzare per la grande profusione di fiori rosa, violacei o bianchi, raggruppati in grosse pannocchie all'estremità dei rami; le foglie sono opposte, ovato-rotondate, a margine intero, di colore diverso dal bianco al rosso: la Lagerstroemia indica e la Lagerstroemia più bella è la lutzii, la ricordiamo la Lagerstroemia indica e la Lagerstroemia Chicago, la lutzii, la più bella ricordiamo l'Hibrid Diamond. Molto bella è l'Hibrid Diamond canariensis, con grandi foglie.$t$,
  $t${"luce": "A parte la Lagerstroemia indica, che sopporta abbastanza bene i climi freddi, le altre specie sono alquanto sensibili alle basse temperature, tanto da dover essere riparate in serra durante la stagione invernale", "acqua": "Gradisce esposizioni calde, in pieno sole", "terreno": "La Lagerstroemia indica è rustica nelle regioni settentrionali; le specie sempreverdi, alquanto sensibili, sono invece di essere ricoverate ogni anno durante il periodo di essere ricoverate ogni anno durante il periodo invernale in serra"}$t$::jsonb,
  ARRAY[$t$Oltre al pericolo rappresentato dal freddo, la pianta non presenta particolari inconvenienti né difficoltà di coltivazione$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": "la potatura si effettua a fine inverno sopprimendo i rami deboli o danneggiati, e accorciando quelli vigorosi verso l'alto o a due-tre gemme dal legno vecchio", "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Lagerstroemia, p. 560-561$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
