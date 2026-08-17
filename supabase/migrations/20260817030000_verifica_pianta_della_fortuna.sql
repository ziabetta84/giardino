-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Errore reale corretto: famiglia_botanica era "Crassulaceae" (sbagliata),
-- RHS conferma Urticaceae. resistenza_gelo era "nessuna", RHS classifica H4
-- (-10/-5°C, "hardy through most of the UK") — sottostimata nella bozza,
-- coerente con la descrizione RHS "becoming deciduous in frost-prone areas"
-- (sopravvive al gelo perdendo la parte aerea, non muore). spaziatura_cm
-- corretta da 30 a 50: RHS Max Spread 0.5-1m. Aggiunto alert su rischio di
-- diventare infestante (RHS: "potential to become a nuisance").

update specie set esigenze = $j${"luce": "Molto luminosa ma indiretta; evitare sole diretto forte", "acqua": "Terreno costantemente leggermente umido, senza ristagni", "terreno": "Morbido, ricco di sostanza organica, ben drenante ma capace di trattenere umidità"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Urticaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["primavera"], "resistenza_gelo": "media", "spaziatura_cm": 50, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$teme i ristagni idrici (rischio marciumi radicali)$t$, $t$foglie che ingialliscono ai bordi → aria troppo secca$t$, $t$foglie pallide → luce insufficiente$t$, $t$secchezza rapida del terriccio → vaso troppo piccolo o ambiente troppo caldo$t$, $t$non tollera sole diretto nelle ore centrali$t$, $t$ha il potenziale di diventare infestante se non contenuta$t$], famiglia_botanica = $t$Urticaceae$t$, fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Soleirolia soleirolii$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$pianta-della-fortuna$t$;
