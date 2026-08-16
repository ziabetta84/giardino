-- Verifica reale (#120, secondo task), secondo del secondo blocco di 5:
-- geranio-zonale (Pelargonium zonale), fonte RHS Plants (rhs.org.uk),
-- letta da Roberta e relayata.
--
-- esigenze.terreno arricchito da "Fertile" a "Fertile, ben drenato" (RHS:
-- "fertile, well-drained soil"). spaziatura_cm corretta da 30 a 50: RHS
-- Max Spread è 0.5-1m, molto più ampio della bozza (che sembrava basata su
-- piante annuali compatte, non su questa specie che arriva a 1m di
-- larghezza).
--
-- Confermato con forza resistenza_gelo "nessuna": RHS classifica H1C
-- (serra riscaldata/tropicale, minimo 15°C), la fascia più tenera della
-- scala.
--
-- Nota: RHS descrive la propagazione di questa specie solo per talea
-- legnosa (softwood cuttings), non menziona la semina. finestra_semina e
-- giorni_germinazione della bozza non cancellati (la semina di gerani
-- zonali è comunque pratica commerciale reale e diffusa), ma non
-- confermati da questa fonte specifica.
--
-- Aggiunto alert mancante su parassiti (tripidi, afidi, cicaline, bruchi,
-- sciaridi, oziorrinco) e malattie specifiche (marciume radicale in
-- terreni umidi, muffa grigia, ruggine del pelargonio) — #132.

update specie set
  esigenze = $j${"luce": "Sole", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb,
  ciclo_colturale = $j${"famiglia_botanica": "Geraniaceae", "giorni_germinazione": "7-14", "giorni_trapianto": "40-50", "giorni_raccolta": null, "finestra_semina": ["inverno", "primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 50, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb,
  alert = ARRAY[$t$Sensibili al gelo$t$, $t$ama sole pieno$t$, $t$teme ristagni idrici$t$, $t$fioritura molto lunga$t$, $t$ottimi in fioriere e balconiere$t$, $t$può essere colpito da parassiti (tripidi, afidi, cicaline, bruchi, sciaridi, oziorrinco) e da malattie come marciume radicale in terreni umidi, muffa grigia e ruggine del pelargonio$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Pelargonium zonale$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$geranio-zonale$t$;
