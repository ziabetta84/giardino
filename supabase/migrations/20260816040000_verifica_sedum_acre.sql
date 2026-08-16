-- Verifica reale (#120, secondo task), primo blocco di 5: sedum-acre,
-- fonte RHS Plants (rhs.org.uk), letta da Roberta e relayata.
--
-- Due correzioni: esigenze.terreno era "Sabbioso", RHS descrive un range
-- più ampio ("wide range of well-drained soils": Chalk, Loam, Sand) quindi
-- "Drenato" è più accurato; aggiunto alert mancante sulla linfa irritante
-- ("Potentially harmful — Sap can be an irritant. Wear gloves"), dato di
-- sicurezza reale non presente nella bozza (#132).
--
-- Confermato: esigenze.luce "Sole" = RHS Full sun; resistenza_gelo "alta" =
-- RHS H7 (fascia più resistente); spaziatura_cm 15 dentro Max Spread RHS
-- (0.1-0.5m). RHS conferma propagazione per seme o divisione ma senza
-- indicare una stagione di semina precisa: finestra_semina lasciata vuota
-- com'era, per non inventare un dato non in fonte.

update specie set
  esigenze = $j${"luce": "Sole", "acqua": "Scarsa", "terreno": "Drenato"}$j$::jsonb,
  alert = ARRAY[$t$Può espandersi rapidamente$t$, $t$richiede pieno sole per mantenere portamento compatto$t$, $t$evitare irrigazioni: pianta xerofila$t$, $t$crescita molto rapida: può espandersi oltre il punto desiderato$t$, $t$perfetta per competere con parietaria e infestanti$t$, $t$fioritura gialla intensa in tarda primavera$t$, $t$la linfa può essere irritante per la pelle: usare guanti durante la manipolazione$t$],
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Sedum acre$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$sedum-acre$t$;
