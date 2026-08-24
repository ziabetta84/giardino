-- Fase 3, secondo batch da guida-completa-giardino: le 5 foto lette per il
-- controllo preliminare del layout (icone/due colonne), riusate invece di
-- scartarle. Crataegus/Tilia/Ulmus (letti nella stessa serie di foto) sono
-- volutamente esclusi: il libro ne parla a livello di genere ma il catalogo
-- ha gia' decine di specie specifiche per ciascuno (da PFAF) e nessuna
-- dominante — inserire un'ennesima riga generica sarebbe rumore, non
-- ampiezza reale. helianthus-annuus/girasole gia' verificato via RHS: nessuna
-- azione.

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Ficus benjamina$t$,
  $t$Ficus benjamina$t$,
  $t$ficus-benjamina$t$,
  $t$Moraceae$t$,
  $t$perenne$t$,
  $t$Appartiene al genere Ficus ed è originario dell'India e della Malesia. Ha foglie ovali o di un verde intenso; esistono varietà a foglie striate e a foglie doppie (Ficus Starlight). Può raggiungere anche i 5 metri di altezza in casa.$t$,
  $t${"luce": "Molta luce, ma non gradisce quella diretta del sole", "acqua": "Annaffiare regolarmente con acqua non fredda, senza mai eccedere", "terreno": "Terriccio comune per piante d'appartamento"}$t$::jsonb,
  ARRAY[$t$Foglie che ingialliscono e cadono: dovuto a un luogo poco luminoso o a correnti d'aria$t$, $t$Insetti bruno-rossastri sotto tronco/foglia: cocciniglia$t$, $t$Non tollera affatto le correnti d'aria$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "una volta a settimana", "autunno": null, "inverno": "ogni 10 giorni", "primavera": null}, "concimazione": {"estate": "ogni 15 giorni con concime liquido", "autunno": null, "inverno": "ridotta a una volta al mese", "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Moraceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Ficus benjamina, p. 324-325$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Gladiolus$t$,
  $t$Gladiolus$t$,
  $t$gladiolus$t$,
  $t$Iridaceae$t$,
  $t$perenne$t$,
  $t$Bulbosa perenne coltivata come annuale, dimensioni da 30 cm a un metro. Fiori tubulari riuniti in un'unica spiga per bulbo; la fioritura inizia in primavera e termina in autunno a seconda dell'epoca di piantagione dei bulbi. Pianta elegante, utilizzata soprattutto per fiore reciso.$t$,
  $t${"luce": "Pieno sole; posizioni ombreggiate se il sole è troppo forte", "acqua": "Costante"}$t$::jsonb,
  ARRAY[$t$Può essere soggetto a vari tipi di funghi$t$, $t$Estremamente sensibile al freddo: i bulbi vanno estirpati appena disseccano$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "costante", "autunno": null, "inverno": null, "primavera": "costante"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimazioni organiche prima dell'impianto dei bulbi"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": ["primavera"], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Iridaceae", "finestra_trapianto": [], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Gladiolus, p. 384$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Cleistocactus$t$,
  $t$Cleistocactus$t$,
  $t$cleistocactus$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Cactacee di origine sudamericana, longilinee, erette, possono ramificare dalla base e arrivano a un'altezza di quasi 2 metri. Hanno molte coste (circa 25) ricoperte da fitte spine sottili. La fioritura avviene solo nei soggetti adulti. Specie più coltivata: Cleistocactus strausii (areole pelose, spine bianche sottili, fusto verde argentato, fiori rossi lunghi fino a 8 cm). Cleistocactus baumannii: pianta sottile ricoperta da spine e peli giallastri, fiori arancioni lunghi 5-7 cm.$t$,
  $t${"luce": "Luce brillante, anche sole diretto", "acqua": "Pochissime annaffiature"}$t$::jsonb,
  $t${"npk": {"estate": "5-10-5", "autunno": null, "inverno": null, "primavera": "5-10-5"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "pochissime annaffiature", "autunno": null, "inverno": null, "primavera": "pochissime annaffiature"}, "concimazione": {"estate": "fertilizzante a base di fosforo nel periodo vegetativo", "autunno": null, "inverno": null, "primavera": "fertilizzante a base di fosforo nel periodo vegetativo"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Cactaceae", "finestra_trapianto": [], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Cleistocactus, p. 468$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Copiapoa$t$,
  $t$Copiapoa$t$,
  $t$copiapoa$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Genere originario del Cile, poco coltivato, presente perlopiù nelle grandi collezioni dei giardini botanici. Dapprima di forma sferica, crescendo diviene cilindrico, con molte coste che formano protuberanze simili a tubercoli; apice fittamente coperto di lana. Copiapoa cinerea: originaria delle coste cilene, arriva a 1 m di altezza nel suo habitat, colore verde pallido, fiori imbutiformi gialli con sfumature rosse.$t$,
  $t${"luce": "Pieno sole", "acqua": "Abbondanti ma distanziate annaffiature"}$t$::jsonb,
  ARRAY[$t$Tutte le specie del genere temono il freddo: in posizione illuminata durante l'estate, ricoverate in ambiente riscaldato durante l'inverno (minimo 13-16°C)$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "abbondanti ma distanziate", "autunno": null, "inverno": null, "primavera": "abbondanti ma distanziate"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Cactaceae", "finestra_trapianto": [], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Copiapoa, p. 469$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;
