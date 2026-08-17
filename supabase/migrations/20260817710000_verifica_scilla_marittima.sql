-- Verifica reale (#120): scilla-marittima non ha pagina su RHS (fonte
-- inglese), verificata invece su Acta Plantarum (actaplantarum.org),
-- database della flora italiana — scheda per "Squilla maritima", nome
-- attualmente valido secondo la checklist 2022 (sinonimo diretto del
-- Drimia maritima già nel nostro catalogo, verificabile dai sinonimi
-- elencati in scheda).
--
-- Confermati: famiglia_botanica Asparagaceae (già corretta in bozza);
-- ciclo_vitale "perenne" (Acta Plantarum: "G bulb - Geofite bulbose").
-- Tipo corologico W-Mediterraneo, entità indigena — coerente con
-- l'ambiente costiero secco già descritto in bozza (esigenze.luce/
-- terreno non modificati: fonte qualitativa, non fornisce dati
-- strutturati di coltivazione come RHS).
--
-- Consolidati i due alert quasi duplicati sulla tossicità in uno solo,
-- arricchito con il dettaglio reale (glicosidi cardioattivi, uso storico
-- come topicida) confermato da Acta Plantarum ("Entità tossica").
--
-- Aggiunto un dato reale importante assente dalla bozza: Acta Plantarum
-- classifica la specie come "Entità a rischio" (IUCN: DD) e "protetta a
-- livello nazionale" in Italia — informazione rilevante per chi valuta
-- di procurarsi la pianta (da preferire origine vivaistica, non prelievo
-- in natura).

update specie set
  alert = ARRAY[$t$richiede pieno sole e terreno molto drenante$t$, $t$evitare assolutamente irrigazioni: pianta xerofila$t$, $t$foglie che seccano in estate → comportamento normale (riposo estivo)$t$, $t$bulbo parzialmente esposto: non coprirlo$t$, $t$tossica se ingerita (attenzione a bambini e animali) — contiene glicosidi cardioattivi, storicamente usata anche come topicida$t$, $t$specie a rischio, protetta per legge a livello nazionale in Italia: non prelevare bulbi dall'ambiente naturale, procurarsi solo materiale di origine colturale/vivaistica$t$],
  fonti = ARRAY[$t$Acta Plantarum (actaplantarum.org) — Scheda IPFI, Squilla maritima (L.) Steinh. [sinonimo di Drimia maritima]$t$],
  stato_verifica = $t$verificato$t$,
  verificata_il = now(),
  verificata_da = $t$Roberta + Claude Code (scheda Acta Plantarum)$t$
where slug = $t$scilla-marittima$t$;
