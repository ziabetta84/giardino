-- Verifica reale di prunus-persica (Pesco), ultima delle 87 specie possedute
-- ancora a bozza/PFAF. Fonte: fonti/rhs/Prunus persica _ peach.html, letta
-- localmente da Claude Code (HTML salvato estratto a testo con un parser
-- Python stdlib, non tramite dump grezzo) — non relayata dall'utente come
-- nelle verifiche precedenti (vedi es. verifica_avocado.sql).
--
-- Fatti diretti da RHS: Position "Full sun"; Soil "Chalk, Clay, Loam, Sand",
-- moist but well-drained, pH acid/alkaline/neutral; Hardiness H4 (-10/-5°C);
-- Habit "Spreading branched", deciduous, Max Height/Spread 4-8m; Cultivation
-- "moist but well-drained soil in full sun, protect flowers from frosts,
-- best fan-trained"; Propagation "seed sown outdoors in autumn, or softwood
-- cuttings in early summer"; Pruning "prune after harvest... little pruning
-- needed, Pruning group 1"; Pests "aphids and caterpillars"; Diseases "High
-- Risk Host for Xylella fastidiosa. bacterial canker, blossom wilt, brown
-- rot, honey fungus, peach leaf curl, silver leaf".
--
-- Giudizio agronomico (non RHS diretto, coerente col criterio "da frutto ->
-- potassio prevalente" gia' in uso nel resto del catalogo): NPK 5-10-15 in
-- primavera/estate, assente in autunno/inverno; programma di irrigazione/
-- concimazione/potatura stagionale adattato al clima mediterraneo collinare
-- di Centinarola (Fano) invece che al Regno Unito. La regola "evitare
-- potature invernali" e' un collegamento diretto fatto da Claude tra due
-- fatti RHS distinti (Pruning + le malattie da ferita "bacterial canker" e
-- "silver leaf"), non un'affermazione esplicita della fonte.
-- spaziatura_cm 500 e finestra_semina "autunno" sono dentro i range RHS
-- (Max Spread 4-8m; seed sown outdoors in autumn).

update specie set
  descrizione = $t$Albero deciduo dal portamento espanso, alto 4-8 m. Foglie strette, lucide, verde scuro, lunghe fino a 15 cm. Fiori a coppa, rosa o rossi (4 cm), prodotti in primavera prima della fogliazione, seguiti da frutti sferici, tomentosi, commestibili, gialli sfumati di rosso. Spesso allevato a ventaglio o a spalliera contro un muro esposto a sud/ovest; rusticità elevata (H4 RHS, resiste fino a circa -10/-5°C).$t$,
  esigenze = $t${"luce": "Pieno sole", "acqua": "Moderata, terreno sempre umido ma ben drenato", "terreno": "Ben drenato; tollera calcareo, argilloso, sabbioso e franco (pH acido, neutro o alcalino)"}$t$::jsonb,
  alert = ARRAY[$t$Ospite ad alto rischio per Xylella fastidiosa secondo RHS: monitorare lo stato fitosanitario, soprattutto in aree con focolai segnalati$t$, $t$Bolla del pesco (peach leaf curl): trattare in via preventiva a fine inverno/inizio primavera con prodotti rameici$t$, $t$Evitare potature invernali: aumentano il rischio di cancro batterico e mal del piombo (silver leaf) — potare dopo la raccolta$t$, $t$Proteggere la fioritura precoce dalle gelate tardive, ad esempio con tessuto non tessuto biodegradabile$t$, $t$Possibili attacchi di afidi e larve di lepidotteri (caterpillars)$t$, $t$Rischio di marciume radicale su terreni con ristagno idrico nonostante la tolleranza a suoli argillosi$t$],
  manutenzione = $t${"npk": {"estate": "5-10-15", "autunno": null, "inverno": null, "primavera": "5-10-15"}, "potatura": {"estate": "potatura principale dopo la raccolta dei frutti, per ridurre l'altezza e mantenere la forma a ventaglio o a spalliera", "autunno": "nessuna", "inverno": "da evitare: aumenta il rischio di cancro batterico e mal del piombo", "primavera": "nessuna, o minima se allevato a ventaglio"}, "irrigazione": {"estate": "frequente nei periodi caldi e secchi, specialmente durante la maturazione dei frutti", "autunno": "ridotta, solo in caso di siccità prolungata", "inverno": "nessuna, salvo inverni eccezionalmente secchi", "primavera": "regolare durante allegagione e ingrossamento dei frutti, evitando ristagni"}, "concimazione": {"estate": "eventuale apporto leggero durante l'ingrossamento dei frutti", "autunno": "nessuna", "inverno": "nessuna", "primavera": "concime organico o NPK bilanciato a inizio ripresa vegetativa"}}$t$::jsonb,
  ciclo_colturale = ciclo_colturale || $t${"spaziatura_cm": 500, "finestra_semina": ["autunno"]}$t$::jsonb,
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Prunus persica$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Claude Code (lettura fonte RHS locale + compilazione)$t$
where slug = $t$prunus-persica$t$;
