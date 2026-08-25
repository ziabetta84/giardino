-- Fase 4, primo batch: legeorgiche + actaplantarum. L'utente ha scaricato
-- localmente 3 pagine HTML di Le Georgiche (vivaio) e 2 schede Acta Plantarum
-- (IPFI, solo nomenclatura/tassonomia, mai dati di coltivazione) — la fonte
-- non è più "solo URL" come indicato nel criterio, quindi esce dall'attesa
-- Fase 4 e si processa come le altre fonti locali.
--
-- Decisione stato_verifica (chiesta esplicitamente all'utente): Le Georgiche
-- è un vivaio commerciale, non una fonte primaria elencata nella regola 3
-- (RHS/CREA/libro cartaceo) — resta sempre 'bozza' anche quando il
-- contenuto è puntuale e specifico sulla specie, non generico. Questo
-- corregge anche la riga `centaurea-ragusina`, marcata 'verificato' in una
-- sessione precedente non documentata con lo stesso tipo di fonte: qui
-- viene riportata a 'bozza' per coerenza di catalogo (nessun dato toccato,
-- solo l'etichetta di affidabilità).

update specie set stato_verifica = 'bozza'
where slug = 'centaurea-ragusina' and stato_verifica = 'verificato';

-- AGAPANTHUS AFRICANUS — arricchita con dati di coltivazione reali e
-- specifici (Le Georgiche, pagina sulla cultivar 'Albus' a fiore bianco;
-- per la regola 6 la cultivar non riceve riga propria, solo nota in
-- descrizione, perché il resto del contenuto/coltivazione è quello della
-- specie). Non tocca esigenze/manutenzione già presenti da PFAF: solo
-- append.
update specie set
  descrizione = descrizione || $t$ Esiste la cultivar 'Albus' (Agapanto bianco), a fiori bianchi anziché blu, dal portamento eretto e sempreverde: foglie strette ed erette verde intenso, ombrelle di fiori a forma di tromba in estate su steli slanciati. Originaria dell'Africa meridionale (coste e colline). A maturità raggiunge 80-100 cm di altezza in fioritura e 50-70 cm di larghezza.$t$,
  alert = alert || ARRAY[$t$Rusticità H3: tollera brevi abbassamenti fino a circa -5°C se in posizione riparata e terreno ben drenato; temperature ideali di crescita 18-28°C$t$],
  manutenzione = manutenzione || $t${"irrigazione": {"estate": "regolare durante stagione vegetativa e fioritura", "autunno": "ridotta sensibilmente", "inverno": "ridotta sensibilmente", "primavera": "regolare durante stagione vegetativa e fioritura"}, "concimazione": {"estate": null, "autunno": null, "inverno": null, "primavera": "concime universale per piante ornamentali"}}$t$::jsonb,
  fonti = array_append(fonti, $t$Vivai Le Georgiche (legeorgiche.it) — Agapanthus africanus "Albus"$t$)
where slug = 'agapanthus-africanus'
  and not ($t$Vivai Le Georgiche (legeorgiche.it) — Agapanthus africanus "Albus"$t$ = any(fonti));

-- MAMMILLARIA GRACILIS — nuova specie, nessuna riga esistente in catalogo.
insert into specie (nome, nome_scientifico, slug, famiglia_botanica, ciclo_vitale, descrizione, esigenze, alert, manutenzione, fonti, stato_verifica)
values (
  $t$Mammillaria gracilis$t$,
  $t$Mammillaria vetula subsp. gracilis$t$,
  $t$mammillaria-gracilis$t$,
  $t$Cactaceae$t$,
  $t$perenne$t$,
  $t$Piccolo cactus succulento cespitoso, con numerosi fusti cilindrici sottili ricoperti di spicole; in primavera produce piccoli fiori bianchi. Originaria del Messico, cresce naturalmente in zone rocciose, soleggiate e aride, su terreni poveri ma ben drenati. A maturità raggiunge circa 8-10 cm di altezza e 15-20 cm di larghezza.$t$,
  $t${"luce": "Esposizione luminosa, sole diretto nelle ore più miti, protezione nelle ore più calde d'estate", "acqua": "Moderata, solo a terreno asciutto; drasticamente ridotta in inverno", "terreno": "Povero, ben drenato; terriccio specifico per cactus"}$t$::jsonb,
  ARRAY[$t$Rusticità H2: temperature minime tollerate 1-5°C se protetta; temperatura ideale di crescita 18-24°C$t$],
  $t${"npk": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "potatura": {"estate": null, "autunno": null, "inverno": null, "primavera": null}, "irrigazione": {"estate": "solo quando il terreno è asciutto", "autunno": null, "inverno": "drasticamente ridotte", "primavera": "solo quando il terreno è asciutto"}, "concimazione": {"estate": "concime liquido per cactus ogni 4-6 settimane, o concime a lenta cessione", "autunno": null, "inverno": null, "primavera": "concime liquido per cactus ogni 4-6 settimane, o concime a lenta cessione"}}$t$::jsonb,
  ARRAY[$t$Vivai Le Georgiche (legeorgiche.it) — Mammillaria gracilis$t$],
  $t$bozza$t$
)
on conflict (slug) do nothing;

-- URGINEA MARITIMA (Scilla marina) — arricchita con dati nomenclaturali e
-- di distribuzione da Acta Plantarum (IPFI); nessun dato di coltivazione
-- nella fonte (come già per Centaurea ragusina), quindi solo alert/nota
-- tassonomica, manutenzione/esigenze PFAF non toccate.
update specie set
  alert = alert || ARRAY[
    $t$Nome comune italiano: Scilla marina$t$,
    $t$Nomenclatura botanica aggiornata (checklist 2018): il nome accettato è ora Squilla maritima (L.) Steinh., con Urginea maritima tra i sinonimi$t$,
    $t$Specie protetta a livello nazionale in Italia, a rischio (livello IUCN: DD); entità officinale e ornamentale$t$
  ],
  fonti = array_append(fonti, $t$Acta Plantarum (actaplantarum.org) — Scheda IPFI, Squilla maritima (sinonimo Urginea maritima)$t$)
where slug = 'urginea-maritima'
  and not ($t$Acta Plantarum (actaplantarum.org) — Scheda IPFI, Squilla maritima (sinonimo Urginea maritima)$t$ = any(fonti));
