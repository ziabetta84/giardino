-- Fase 3, ventinovesimo batch da guida-completa-giardino (pp. 502-505):
-- Parodia, Rebutia, Sempervivum, Trichocereus — chiude il capitolo "Piante
-- Grasse". Abutilon e Bougainvillea (viste all'inizio del capitolo
-- successivo "Arbusti Rampicanti", pp. 508-511) saltate: gia' presenti e
-- verificate da altre fonti Edicart fotografate in precedenza.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Parodia$t$,
  $t$Parodia$t$,
  $t$parodia$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario delle pianure del Sudamerica, piante semplici, di forma sferica o cilindrica, disposte in file regolari o a spirale. Ricoperte da tubercoli di formazioni spesso munite di un ciuffo di spine lanuginose all'apice. Le areole hanno successo come piante ornamentali, sia per le lunghe spine, sia per i grandi fiori che si formano anche su esemplari giovani. Specie nota: Parodia sanguiniflora (spine radiali bianche e setose, centrali brune e più forti, fiori rosso sangue lucenti).$t$,
  $t${"luce": "Piuttosto basse in inverno (4-18°C), con caldo umido, il terriccio deve essere mantenuto un po' umido"}$t$::jsonb,
  ARRAY[$t$Bisogno di temperature piuttosto basse in inverno$t$, $t$Richiedono pochissime annaffiature$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Parodia, p. 502-503$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Rebutia$t$,
  $t$Rebutia$t$,
  $t$rebutia$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario delle zone montuose dell'Argentina e della Bolivia, piante piccole, in genere cespitose, di forma globosa (massimo 7 cm di diametro), caratterizzate dalla forma dei tubercoli disposti a spirale con spine sottili. Specie nota: Rebutia minuscula (globi depressi alti 2 cm e larghi al massimo 5 cm, che formano cespi numerosi, tubercoli a spirale, spine corte e setolose, fiori rosso lucenti a tubo imbutiforme).$t$,
  $t${"luce": "Luce del sole ma è meglio riparata dell'estate, concimare una volta l'anno", "acqua": "Regolari e piuttosto abbondanti"}$t$::jsonb,
  ARRAY[$t$Nella stagione calda necessita di annaffiature regolari e frequenti; dopo la fioritura riducile$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Rebutia, p. 503$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Sempervivum$t$,
  $t$Sempervivum$t$,
  $t$sempervivum$t$,
  $t$Crassulaceae$t$,
  $t$perenne$t$,
  $t$Piante grasse alpine, con foglie carnose disposte a rosetta, cauline e a volte coperte di peli. Habitat naturale sono i luoghi rocciosi, soprattutto su substrato siliceo, ad altitudine di 1600-2700 m. Si ibridano facilmente tra loro. Specie nota: Sempervivum arachnoideum (piccole rosette globose formate da foglie cuneiformi appuntite orlate di peli rossastro, ricoperta da un fitto intreccio di peli all'apice come una ragnatela).$t$,
  $t${"luce": "Cresce tra i sassi e le rocce, molto resistente al freddo e alla siccità", "acqua": "Scarse annaffiature"}$t$::jsonb,
  ARRAY[$t$La rosetta muore dopo la fioritura, ma la vita della pianta continua grazie ai polloni che la circondano$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Sempervivum, p. 504-505$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, fonti, stato_verifica)
values (
  $t$Trichocereus$t$,
  $t$Trichocereus$t$,
  $t$trichocereus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario delle montagne del Sudamerica, piante di forma colonnare, presto ramificate dalla base, coste sottili con spine lunghe e generalmente robuste. Sono coperte da lanugine o da peli evidenti. Genere che comprende molte specie diversi, facilmente coltivabili anche in appartamento. Specie nota: Trichocereus candicans (fusti biancastri lanosi con spine lunghe, ramificate dalla base, cespi fitti di fusti che possono arrivare al metro di altezza, fiori bianchi, notturni, molto grandi).$t$,
  $t${"luce": "Solar diretta e soleggiata, hanno bisogno di temperature invernali a riposo (4°C) con pochissima umidità"}$t$::jsonb,
  ARRAY[$t$Necessitano di scarse annaffiature, soprattutto d'inverno$t$],
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Trichocereus, p. 505$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
