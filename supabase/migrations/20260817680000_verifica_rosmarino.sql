-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Nota tassonomica importante: RHS ha riclassificato l'intero genere
-- Rosmarinus in Salvia — il rosmarino è ora ufficialmente Salvia
-- rosmarinus per RHS, non più Rosmarinus officinalis. Aggiunto come alert
-- dedicato per visibilità, dati botanici non influenzati. terreno
-- corretto da "Sabbioso" (troppo specifico) a "Ben drenato, da povero a
-- moderatamente fertile" (RHS: "poor to moderately fertile, well-drained
-- soil", nessuna menzione specifica di sabbia). Corretta resistenza_gelo
-- da "alta" a "media": RHS classifica H4, coerente con la scala già
-- stabilita (H4→media). spaziatura_cm corretta da 50 a 150: RHS Max Spread
-- 1.5-2.5m, molto più ampio della bozza. Aggiunto un gap di alert reale su
-- parassiti/malattie specifiche, solo parzialmente coperto dalla bozza
-- (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Scarsa", "terreno": "Ben drenato, da povero a moderatamente fertile"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Lamiaceae", "giorni_germinazione": "15-25", "giorni_trapianto": "40-60", "giorni_raccolta": null, "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "autunno"], "resistenza_gelo": "media", "spaziatura_cm": 150, "consociazioni_favorevoli": ["salvia", "cavolo"], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$Evitare ristagni$t$, $t$evitare irrigazioni frequenti (rischio marciumi)$t$, $t$richiede pieno sole per mantenere portamento compatto$t$, $t$molto resistente al vento: perfetto per il crinale$t$, $t$evitare potature drastiche sul legno vecchio$t$, $t$controllare eventuale presenza di cocciniglia in estati molto calde$t$, $t$RHS classifica ora il rosmarino come Salvia rosmarinus (non più Rosmarinus officinalis): l'intero genere è stato riclassificato$t$, $t$può essere colpito da coleottero del rosmarino, sputacchina, cicalina della salvia e tortrice, oltre alla cocciniglia già segnalata$t$, $t$può essere colpito da oidio, verticillosi, marciume del piede/radici e raramente armillaria$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Salvia rosmarinus (nome sotto cui RHS classifica ora questa specie, riclassificata dal genere Rosmarinus a Salvia)$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$rosmarino$t$;
