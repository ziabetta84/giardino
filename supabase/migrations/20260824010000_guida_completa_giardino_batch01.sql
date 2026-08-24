-- Fase 3 dell'importazione fonti: primo batch da guida-completa-giardino
-- ("Tutto per il giardino", Demetra 2006), i 5 .txt gia' trascritti
-- dall'utente (confermati corretti, non affetti dal problema di
-- interlacciatura a due colonne del copia-incolla).
--
-- 7 specie/generi trovati nei 5 file. anthurium e' gia' verificato via RHS
-- con dati piu' ricchi di quelli del libro: nessuna azione (niente da
-- aggiungere di reale, non si tocca un record gia' buono solo per citare
-- una fonte in piu').

-- INSERT: Aechmea fasciata — scheda specifica e puntuale sul libro, fonte
-- primaria univoca -> verificato.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Aechmea fasciata$t$,
  $t$Aechmea fasciata$t$,
  $t$aechmea-fasciata$t$,
  $t$Bromeliaceae$t$,
  $t$perenne$t$,
  $t$Bromeliacea originaria delle zone tropicali dell'America centro-meridionale. A maturità emette al centro un'infiorescenza composta da brattee rosa, con piccoli fiori color celeste che virano al rosso.$t$,
  $t${"luce": "Molta luce per favorire la fioritura, mai sole diretto vicino a fonti di calore", "acqua": "Nel terriccio ogni 15-20 giorni, più 2 cm d'acqua nella rosetta centrale cambiata ogni ~20 giorni", "terreno": "Torba, sfagno e terriccio di foglie in parti uguali"}$t$::jsonb,
  ARRAY[$t$Se foglie e fusto del fiore marciscono: eccesso d'acqua, spostare in luogo caldo e areato$t$, $t$Foglie scure sui bordi: siccità prolungata, immergere il vaso in acqua a metà altezza per qualche ora$t$, $t$Non porre vicino a termosifoni o correnti d'aria$t$, $t$Non tollera temperature sotto i 10-11°C, ideale 15-20°C$t$],
  $t${"npk": {"estate": "5-10-10", "autunno": null, "inverno": null, "primavera": "5-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "ogni 15-20 giorni nel terriccio, più acqua nella rosetta centrale", "autunno": null, "inverno": null, "primavera": "ogni 15-20 giorni nel terriccio, più acqua nella rosetta centrale"}, "concimazione": {"estate": "concime liquido diluito nell'acqua d'annaffiatura, pianta poco esigente", "autunno": null, "inverno": null, "primavera": "concime liquido diluito nell'acqua d'annaffiatura, pianta poco esigente"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Bromeliaceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Aechmea fasciata, p. 286-287$t$],
  $t$verificato$t$
)
on conflict (slug) do nothing;

-- INSERT: Aglaonema — genere (~50 specie), scheda generica da libro -> bozza
-- (stessa logica delle 23 righe gia' a livello di genere in tabella).
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Aglaonema$t$,
  $t$Aglaonema$t$,
  $t$aglaonema$t$,
  $t$Araceae$t$,
  $t$perenne$t$,
  $t$Genere di circa 50 specie di piante da appartamento sempreverdi, originarie di Borneo, Filippine e Indonesia (le più diffuse: A. treubii, A. pseudobracteatum, A. crispum). Il nome deriva dal greco e significa "filo lucente".$t$,
  $t${"luce": "Anche poco luminoso, tollera brevemente il sole diretto", "acqua": "Moderata, lasciare asciugare il terriccio tra un'annaffiatura e l'altra", "terreno": "Torba con un po' di sabbia"}$t$::jsonb,
  ARRAY[$t$Foglie gialle: eccesso d'acqua o ambiente troppo freddo$t$, $t$Macchie bianche cotonose sotto le foglie: cocciniglia$t$],
  $t${"npk": {"estate": "20-10-10", "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "ogni 4-5 giorni, spruzzare ogni 5-6 giorni", "autunno": null, "inverno": "solo quando il terriccio è asciutto", "primavera": null}, "concimazione": {"estate": "ogni 15 giorni con concime liquido", "autunno": null, "inverno": null, "primavera": null}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "nessuna", "giorni_trapianto": null, "famiglia_botanica": "Araceae", "finestra_trapianto": ["primavera"], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Aglaonema$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

-- INSERT: Eucalyptus — genere, scheda generica da libro -> bozza.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Eucalyptus$t$,
  $t$Eucalyptus$t$,
  $t$eucalyptus$t$,
  $t$Myrtaceae$t$,
  $t$perenne$t$,
  $t$Genere di alberi sempreverdi originari dell'Australia, portamento slanciato, altezza media 20 m (fino a oltre 40 m). Corteccia grigio-glauca con sfumature violacee che si sfalda a strisce. Foglie tondeggianti nei soggetti giovani, lanceolate e arcuate negli adulti. Fiori piumosi bianco-giallastri in estate.$t$,
  $t${"luce": "Zone molto soleggiate", "acqua": "Normale, sopporta bene anche la siccità", "terreno": "Non esigente, preferisce terreni ben drenati, profondi e tendenzialmente acidi"}$t$::jsonb,
  ARRAY[$t$Le cocciniglie possono attaccare foglie e fusti giovani: trattare con anticoccidici$t$, $t$Non sopporta le temperature rigide, predilige climi miti e temperati$t$],
  $t${"npk": {"estate": "10-5-5", "autunno": null, "inverno": null, "primavera": "10-5-5"}, "potatura": {"estate": "nessuna", "autunno": "nessuna", "inverno": "nessuna", "primavera": "nessuna"}, "irrigazione": {"estate": "moderata, tollera bene la siccità", "autunno": null, "inverno": null, "primavera": "moderata, tollera bene la siccità"}, "concimazione": {"estate": "concime complesso disciolto in acqua", "autunno": null, "inverno": null, "primavera": "concime complesso disciolto in acqua"}}$t$::jsonb,
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "bassa", "giorni_trapianto": null, "famiglia_botanica": "Myrtaceae", "finestra_trapianto": [], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Eucalyptus$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

-- INSERT: Fagus — genere, note del libro non stagionali -> manutenzione
-- lasciata null per non inventare una distribuzione per stagione che la
-- fonte non da'.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, ciclo_colturale, fonti, stato_verifica)
values (
  $t$Fagus$t$,
  $t$Fagus$t$,
  $t$fagus$t$,
  $t$Fagaceae$t$,
  $t$perenne$t$,
  $t$Genere tipico dell'Europa centrale, molto longevo (fino a 300 anni), presente in Italia su Appennino e Alpi. Albero maestoso a chioma ampia e tondeggiante, talvolta colonnare. Foglie ovali/ellittiche verde cupo o amaranto, in autunno giallo-brune o rosse. Corteccia grigio cenere, liscia. Necessita di normali concimazioni; potatura solo per ridimensionare la pianta quando necessario.$t$,
  $t${"luce": "Buona insolazione, ma tollera bene anche posizioni ombreggiate", "acqua": "Abbondante", "terreno": "Suoli freschi e drenati, ricchi di potassio; si adatta anche a terreni meno fertili, non tollera quelli pesanti"}$t$::jsonb,
  ARRAY[$t$Soggetto a cocciniglie, afidi e larve di punteruoli sulle foglie$t$, $t$La famigliola (fungo) può provocarne la rapida morte$t$, $t$Rifugge climi secchi e rigidi, non tollera gelate intense e prolungate, necessita di elevata umidità$t$],
  $t${"spaziatura_cm": null, "finestra_semina": [], "giorni_raccolta": null, "resistenza_gelo": "media", "giorni_trapianto": null, "famiglia_botanica": "Fagaceae", "finestra_trapianto": [], "giorni_germinazione": null, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$t$::jsonb,
  ARRAY[$t$Tutto per il giardino (Demetra, 2006) — Fagus$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

-- UPDATE: Ananas comosus (bozza PFAF, manutenzione tutta null) — arricchito
-- con dati reali dal libro. Descrizione/esigenze PFAF gia' plausibili, non
-- toccate. Resta bozza: mix di fonti, non una scheda interamente verificata.
update specie set
  alert = alert || ARRAY[$t$Se le foglie muoiono dopo la fioritura, interrare gli eventuali germogli basali per ottenere nuove piantine$t$, $t$Punte delle foglie secche: bagnare il terriccio e spruzzare le foglie con acqua non fredda$t$, $t$Marciume alla base: spostare in luogo più caldo e far asciugare il terreno$t$],
  manutenzione = $t${"npk": {"estate": "5-10-15", "autunno": null, "inverno": null, "primavera": "5-10-15"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "due volte a settimana", "autunno": null, "inverno": "una volta a settimana", "primavera": null}, "concimazione": {"estate": "una volta al mese, una volta a settimana durante la formazione del frutto", "autunno": null, "inverno": null, "primavera": "una volta al mese, una volta a settimana durante la formazione del frutto"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Ananas comosus$t$)
where slug = $t$ananas-comosus$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Ananas comosus$t$ = any(fonti));

-- UPDATE: Fraxinus excelsior (bozza PFAF, manutenzione tutta null) —
-- arricchito con dati reali dal libro. Resta bozza per lo stesso motivo.
update specie set
  alert = alert || ARRAY[$t$Il poliporo ("fungo a mensola") può penetrare da ferite della corteccia e causare marciume del legno$t$, $t$La famigliola può far marcire l'apparato radicale e causare la morte rapida della pianta$t$],
  manutenzione = $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": "20-10-10"}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": "esigenze minime, solo se necessario"}, "irrigazione": {"estate": "normale, non tollera la siccità prolungata", "autunno": null, "inverno": null, "primavera": "normale, non tollera la siccità prolungata"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concimi complessi ad alto tenore di azoto"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Tutto per il giardino (Demetra, 2006) — Fraxinus excelsior$t$)
where slug = $t$fraxinus-excelsior$t$
  and not ($t$Tutto per il giardino (Demetra, 2006) — Fraxinus excelsior$t$ = any(fonti));
