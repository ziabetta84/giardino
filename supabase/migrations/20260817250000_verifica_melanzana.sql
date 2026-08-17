-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Confermati luce, terreno, resistenza_gelo "nessuna" (RHS H1C, molto
-- tenera). Dorifora e ragnetto rosso già segnalati in bozza confermati da
-- RHS; aggiunti afidi e mosca bianca (RHS Pests) e nota su armillaria rara
-- (RHS Diseases), non presenti prima (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Regolare", "terreno": "Fertile, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Solanaceae", "giorni_germinazione": "14-21", "giorni_trapianto": "35-45", "giorni_raccolta": "65-80", "finestra_semina": ["inverno", "primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 70, "consociazioni_favorevoli": ["fagiolo", "pisello", "basilico"], "consociazioni_sfavorevoli": ["finocchio"]}$j$::jsonb, alert = ARRAY[$t$Teme il freddo anche in primavera (crescita rallentata sotto i 15°C)$t$, $t$controllare dorifora e ragnetto rosso$t$, $t$necessita di un tutore per le varietà a frutto grosso$t$, $t$cimare i primi getti per favorire la ramificazione e la fruttificazione$t$, $t$attenzione anche ad afidi e mosca bianca, oltre a dorifora e ragnetto rosso già segnalati$t$, $t$raramente può essere colpita da armillaria (marciume del piede)$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Solanum melongena$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$melanzana$t$;
