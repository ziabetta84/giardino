-- Verifica reale (#120, secondo task), seconda specie del pilota: salcerella
-- (Lythrum salicaria), fonte RHS Plants (rhs.org.uk), letta da Roberta e
-- relayata. A differenza di marsilea-quadrifolia, qui la bozza risulta già
-- accurata su tutti i campi verificabili: nessuna correzione necessaria.
--
-- Conferme: esigenze.luce "Sole" = RHS "Full sun"; esigenze.acqua/terreno
-- "Abbondante"/"Umido" = RHS "reliably moist soil", Moisture: Poorly-drained;
-- resistenza_gelo "alta" = RHS H7 (resistente sotto i -20°C, la fascia più
-- alta della scala); spaziatura_cm 40 rientra nel Max Spread RHS (0.1-0.5m);
-- finestra_trapianto primavera = RHS "Propagate by division in spring".
--
-- Nota: giorni_germinazione ("14-21") NON è confermato da questa fonte — la
-- pagina RHS documenta solo la propagazione per divisione, non la semina.
-- Resta una stima di bozza, non ancora verificata da fonte specifica sul
-- seme; da rivedere se emerge una fonte migliore.

update specie set
  fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Lythrum salicaria$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta (fonte RHS) + Claude Code (compilazione)$t$
where slug = $t$salcerella$t$;
