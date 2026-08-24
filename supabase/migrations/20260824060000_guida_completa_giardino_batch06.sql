-- Fase 3, sesto batch da guida-completa-giardino (pp. 318-327, "Piante da
-- Appartamento"): Dieffenbachia (genere), Dracaena fragrans, Euphorbia
-- pulcherrima, Ficus lyrata. ficus-elastica gia' presente (bozza PFAF) ma
-- solo citato di sfuggita nel testo di Ficus lyrata, senza scheda propria:
-- nessun contenuto reale da aggiungere, saltato.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Dieffenbachia$t$,
  $t$Dieffenbachia$t$,
  $t$dieffenbachia$t$,
  $t$Araceae$t$,
  $t$perenne$t$,
  $t$Genere originario del Centro-Sudamerica, dedicato al curatore dei giardini imperiali austriaci J.F. Dieffenbach. Varietà diffuse: Amoena (foglie grandi, verde scuro variegate), Exotica (foglie piccole, molto screziate), Picta Camilla (foglie verde scuro con parte centrale bianco-crema e margine verde).$t$,
  $t${"luce": "Diffusa, mai diretta", "acqua": "Moderata, terriccio sempre un po' umido ma senza ristagni", "terreno": "Composto a base di torba"}$t$::jsonb,
  ARRAY[$t$Foglie e linfa tossiche se ingerite: attenzione durante la pulizia e con bambini/animali$t$, $t$Macchie bianche sulle foglie: cocciniglia$t$, $t$Foglie che ingialliscono o seccano: attacco fungino, trattare con anticrittogamico e asportare le parti secche$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": null, "autunno": null, "inverno": "una volta a settimana", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 10-12 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Araceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Dieffenbachia, p. 318-319$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Dracaena fragrans$t$,
  $t$Dracaena fragrans$t$,
  $t$dracaena-fragrans$t$,
  $t$Agavaceae$t$,
  $t$perenne$t$,
  $t$Dracena originaria dell'Africa tropicale e dell'Asia (oltre 40 specie nel genere; le più note fragrans, sanderiana, marginata). Il nome deriva dal greco e significa "femmina del drago". Fogliame arcuato e ondulato.$t$,
  $t${"luce": "Viva, ma non sole diretto", "acqua": "Abbondante in primavera-estate senza ristagni, moderata d'inverno", "terreno": "Buon terriccio a base di torba"}$t$::jsonb,
  ARRAY[$t$Pianta afflosciata e foglie marce: eccesso d'acqua o ristagno$t$, $t$Insetti scuri su foglie e fusto: cocciniglia$t$, $t$Non tollera le correnti d'aria$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "abbondante, senza ristagni", "autunno": null, "inverno": "moderata", "primavera": "abbondante, senza ristagni"}, "concimazione": {"estate": "concime liquido ogni 15 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Agavaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Dracaena fragrans, p. 320-321$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Euphorbia pulcherrima$t$,
  $t$Euphorbia pulcherrima$t$,
  $t$euphorbia-pulcherrima$t$,
  $t$Euphorbiaceae$t$,
  $t$perenne$t$,
  $t$Stella di Natale, originaria del Messico. Coltivata non per il fogliame ma per l'effetto cromatico (rosso, rosa, bianco) delle brattee che circondano i fiori veri, piccoli e insignificanti.$t$,
  $t${"luce": "Abbondante, per mantenere le brattee dai colori vivaci", "acqua": "Regolare in fioritura, ridotta durante il riposo vegetativo", "terreno": "Ricco, non calcareo"}$t$::jsonb,
  ARRAY[$t$Moscerino bianco sulla pagina inferiore delle foglie: trattare con insetticida, ripetendo ogni 4 giorni per eliminare le larve$t$, $t$Foglie e brattee che si accartocciano e cadono: pianta troppo al buio o al caldo$t$, $t$Non sopravvive alle gelate$t$],
  $t${"npk": {"estate": "5-10-10", "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "rifiorire: tagliare a 8-10 cm da terra dopo il riposo vegetativo"}, "irrigazione": {"estate": "ogni 2-3 giorni durante fioritura/vegetazione", "autunno": null, "inverno": "ridotta, anche una sola volta a settimana", "primavera": null}, "concimazione": {"estate": "fertilizzante liquido ogni 15 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Euphorbiaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Euphorbia pulcherrima, p. 322-323$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Ficus lyrata$t$,
  $t$Ficus lyrata$t$,
  $t$ficus-lyrata$t$,
  $t$Moraceae$t$,
  $t$perenne$t$,
  $t$Detto anche "Fico pandurato", originario dell'Africa occidentale. Foglie verde intenso a forma di violino, solcate da profonde nervature. Specie affine più diffusa: Ficus elastica.$t$,
  $t${"luce": "Viva ma diffusa, mai sole diretto", "acqua": "Settimanale d'inverno lasciando asciugare il terriccio, più frequente d'estate con spruzzature d'acqua a temperatura ambiente", "terreno": "Torboso"}$t$::jsonb,
  ARRAY[$t$Foglie macchiate di giallo e ragnatela nella pagina inferiore: ragnetto rosso, trattare con acaricida$t$, $t$Foglie afflosciate: annaffiare più di frequente$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "più frequente, con spruzzature d'acqua sulle foglie", "autunno": null, "inverno": "una volta a settimana", "primavera": null}, "concimazione": {"estate": "concime liquido ogni 15 giorni", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Moraceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Ficus lyrata, p. 326-327$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;
