-- Verifica reale (#120, secondo task), terzo del blocco di 5: avocado,
-- fonte RHS Plants (rhs.org.uk), letta da Roberta e relayata.
--
-- Aggiunta alert di sicurezza mancante: RHS segnala tossicità per animali
-- domestici ("Potentially harmful: Pets (rabbits): Leaves TOXIC if eaten;
-- Pets incl. caged birds: Fruit harmful if eaten repeatedly") — dato reale
-- non presente nella bozza (#132). Aggiunto anche un alert su parassiti da
-- ambiente chiuso (RHS: glasshouse whitefly, thrips, red spider mite,
-- mealybug).
--
-- Confermato con forza resistenza_gelo "nessuna": RHS classifica H1C
-- (serra riscaldata/tropicale, minimo 15°C), la fascia più tenera della
-- scala. spaziatura_cm 300 dentro Max Spread RHS (2.5-4m).
--
-- Nessuna correzione a esigenze.luce: RHS elenca "Full sun, Partial shade"
-- ma questo si riferisce a coltivazione sotto vetro/serra per la
-- fruttificazione. "Luce indiretta" della bozza è comunque compatibile con
-- l'opzione "Partial shade" — per una pianta nata da nocciolo e tenuta in
-- vaso in appartamento, non ha senso forzare "pieno sole" (rischio di
-- scottature fogliari attraverso il vetro su una pianta non acclimatata).
-- Giudizio di adattamento al contesto reale, non una fonte RHS diretta.

update specie set
  alert = ARRAY[$t$Foglie che scuriscono o si seccano ai bordi → aria troppo secca o acqua troppo calcarea$t$, $t$Cresce molto in altezza da seme: potare per compattarlo$t$, $t$Sensibile al freddo sotto i 10°C$t$, $t$Teme i ristagni idrici (rischio marciume radicale)$t$, $t$foglie tossiche per conigli, frutto dannoso per uccelli da gabbia se ingerito ripetutamente: attenzione con animali domestici$t$, $t$in ambiente chiuso può essere soggetto a cocciniglia, ragnetto rosso e mosca bianca$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Persea americana$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$avocado$t$;
