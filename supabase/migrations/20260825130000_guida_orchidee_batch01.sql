-- Fase 3, guida-orchidee (20 foto, libro monografico su Phalaenopsis,
-- Edizioni Del Baldo 2014): arricchisce la riga genere "orchidea"
-- (Phalaenopsis, gia' verificato via RHS in Fase 1) con storia/origine e
-- la tecnica del "peso del vaso" per l'irrigazione (aggiunta a descrizione,
-- non sovrascrittura), piu' nuovi alert su parassiti/malattie/fioritura non
-- gia' presenti. Inserisce 11 specie botaniche di Phalaenopsis citate nel
-- libro (amabilis, aphrodite, amboinensis, equestris, gigantea, mannii,
-- parishii, philippinensis, schilleriana, stuartiana, pulcra, violacea):
-- ognuna ha un proprio dato distintivo nella fonte (origine geografica,
-- dimensione/colore dei fiori) quindi riceve una riga separata per la
-- regola 6 del criterio di importazione; nessuna manutenzione stagionale
-- specifica per specie nel libro (la cura e' trattata solo a livello di
-- genere), quindi manutenzione resta assente su queste righe.

update specie set
  descrizione = descrizione || $t$ Originaria delle foreste tropicali del Sud-est asiatico, vive in natura come epifita sugli alberi lungo i grandi fiumi; il nome Phalaenopsis (dal greco "che sembra una falena") fu coniato nel 1825 dal botanico Carl Ludwig Blume dopo averla scoperta nel Borneo. Il modo piu' pratico per capire quando annaffiare e' soppesare il vaso: se e' leggero e' il momento di bagnare abbondantemente, fino a far uscire l'acqua dal fondo o per immersione per pochi minuti.$t$,
  alert = alert || ARRAY[
    $t$L'etilene prodotto da frutta in decomposizione (soprattutto mele) vicino alle piante provoca la caduta dei boccioli$t$,
    $t$Temperature notturne sotto i 15°C possono causare la caduta dei boccioli nelle varietà più sensibili$t$,
    $t$Contro cocciniglia e afidi si può pulire con un bastoncino imbevuto d'alcool o lavare con sapone di Marsiglia/potassico; contro le limacce funzionano trappole a birra$t$,
    $t$La batteriosi fa marcire rapidamente le foglie con cattivo odore: va rimossa la parte marcia e cosparsa cannella in polvere sul resto della pianta$t$,
    $t$Il rinvaso va fatto ogni 2-3 anni quando il substrato di corteccia si degrada, o prima se il vaso è troppo piccolo o le radici sono marce$t$,
    $t$Eccesso di azoto nella concimazione, troppo caldo o troppa ombra possono inibire l'induzione a fiore e impedire la rifioritura$t$
  ],
  fonti = array_append(fonti, $t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$)
where slug = $t$orchidea$t$
  and not ($t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$ = any(fonti));

insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, fonti, stato_verifica)
values
  ($t$Phalaenopsis amabilis$t$, $t$Phalaenopsis amabilis$t$, $t$phalaenopsis-amabilis$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Scoperta nel Borneo dal botanico Carl Ludwig Blume nel 1825, e' insieme alla Phalaenopsis aphrodite delle Filippine la specie madre di tutte le grandi Phalaenopsis bianche ibride oggi in commercio. Vive come epifita sugli alberi lungo i grandi fiumi, con fiori bianchi ben visibili da lontano.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis aphrodite$t$, $t$Phalaenopsis aphrodite$t$, $t$phalaenopsis-aphrodite$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Originaria delle Filippine, insieme alla Phalaenopsis amabilis del Borneo e' la specie madre di tutte le grandi Phalaenopsis bianche ibride oggi coltivate su scala industriale.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis amboinensis$t$, $t$Phalaenopsis amboinensis$t$, $t$phalaenopsis-amboinensis$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Proveniente dall'isola di Amboina (Molucche, Indonesia), ha fiori cerosi di 4-5 cm color crema maculati di giallo-arancio. La maggior parte dei grandi ibridi gialli di Phalaenopsis in commercio deriva da questa specie.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis equestris$t$, $t$Phalaenopsis equestris$t$, $t$phalaenopsis-equestris$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Deliziosa miniatura delle Filippine, produce molti piccoli fiori rosa di lunghissima durata. Ne esistono numerose varietà locali che prendono il nome dall'isola di provenienza (es. 'Apari', 'Ilocos').$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis gigantea$t$, $t$Phalaenopsis gigantea$t$, $t$phalaenopsis-gigantea$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Originaria del Borneo, soprannominata "orchidea orecchio d'elefante" per le grandi foglie pendule (oltre 1 m in natura). Fiori molto cerosi di circa 5 cm, color crema maculati di bruno.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis mannii$t$, $t$Phalaenopsis mannii$t$, $t$phalaenopsis-mannii$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Originaria dell'India, in primavera produce steli ramificati con un gran numero di fiori a forma di stella, di colore variabile, spesso gialli maculati di rosso.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis parishii$t$, $t$Phalaenopsis parishii$t$, $t$phalaenopsis-parishii$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Diffusa dall'India alla Birmania, dove fu scoperta dal reverendo Parish. Graziosa miniatura con fiori di circa 2 cm.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis philippinensis$t$, $t$Phalaenopsis philippinensis$t$, $t$phalaenopsis-philippinensis$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Originaria delle Filippine, con foglie finemente screziate di grigio, fiorisce in primavera. Fiori bianchi di circa 7 cm, con le ali del labello gialle sia internamente che esternamente.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis schilleriana$t$, $t$Phalaenopsis schilleriana$t$, $t$phalaenopsis-schilleriana$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Originaria delle Filippine, con foglie finemente screziate di grigio. Produce infiorescenze ramificate con moltissimi fiori rosa-lilla profumati di 7-8 cm: una pianta adulta può produrre più di 80 fiori per singolo stelo.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis stuartiana$t$, $t$Phalaenopsis stuartiana$t$, $t$phalaenopsis-stuartiana$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Originaria delle Filippine, con foglie finemente screziate di grigio. Produce infiorescenze ramificate con molti fiori di circa 7 cm, bianchi punteggiati di porpora nella parte inferiore.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis pulcra$t$, $t$Phalaenopsis pulcra$t$, $t$phalaenopsis-pulcra$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Originaria delle Filippine, con fiori cerosi color viola che si susseguono ininterrottamente dalla primavera al tardo autunno.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$),

  ($t$Phalaenopsis violacea$t$, $t$Phalaenopsis violacea$t$, $t$phalaenopsis-violacea$t$, $t$Orchidaceae$t$, $t$perenne$t$,
   $t$Considerata tra le più belle del genere, si trova in diverse forme (Borneo, Malesia, Alba). Pianta elegante con grandi foglie verde chiaro, fiorisce a fine estate-autunno con fiori cerosi e molto profumati.$t$,
   ARRAY[$t$Guida orchidee — Phalaenopsis (Edizioni Del Baldo, 2014)$t$], $t$bozza$t$)

on conflict (slug) do nothing;
