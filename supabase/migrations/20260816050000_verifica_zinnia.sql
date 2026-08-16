-- Verifica reale (#120, secondo task), secondo del blocco di 5: zinnia,
-- fonte RHS Plants (rhs.org.uk), letta da Roberta e relayata.
--
-- A differenza delle specie precedenti, qui molti campi di ciclo_colturale
-- erano rimasti null (zinnia era già presente da Fase 2 e i batch
-- successivi l'avevano toccata solo per correggere famiglia_botanica, mai
-- per compilare il resto). Compilati ora con dati RHS:
-- resistenza_gelo "bassa" (RHS H2, "half-hardy", tollerante 1 a -5°C);
-- spaziatura_cm 30 (RHS Max Spread 0.1-0.5m); finestra_semina/trapianto
-- primavera (RHS: "seed sown in pots in spring or, in warm areas, sown in
-- situ in late spring").
--
-- esigenze.terreno corretto da "Fertile" a "Fertile, ben drenato" (RHS:
-- "well-drained, fertile, humus-rich soil").
--
-- Alert: rimossa una voce duplicata sull'oidio (due formulazioni quasi
-- identiche nella bozza), aggiunta una voce reale su altre malattie
-- documentate da RHS non presenti prima (marciume del colletto/radici,
-- muffa grigia) — #132.
--
-- giorni_germinazione non compilato: RHS non fornisce un dato numerico
-- specifico su questa pagina, solo il metodo/stagione di semina.

update specie set
  esigenze = $j${"luce": "Sole", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb,
  ciclo_colturale = $j${"famiglia_botanica": "Asteraceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "bassa", "spaziatura_cm": 30, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb,
  alert = ARRAY[$t$ama sole pieno$t$, $t$teme ristagni idrici$t$, $t$sensibile all'oidio, soprattutto in condizioni di umidità elevata$t$, $t$può essere colpita anche da marciume del colletto/radici e muffa grigia (botrite) in condizioni di ristagno idrico$t$, $t$fioritura molto abbondante se ben concimata$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Zinnia elegans$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$zinnia$t$;
