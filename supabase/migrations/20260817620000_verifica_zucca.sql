-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- terreno arricchito. resistenza_gelo "nessuna" mantenuta (RHS classifica
-- H2, che nella scala già stabilita corrisponderebbe a "bassa", ma per un
-- ortaggio annuale che muore alla prima gelata "nessuna" resta
-- l'indicazione più utile in pratica, stesso ragionamento già applicato a
-- zucchina). spaziatura_cm corretta da 150 a 300: RHS Max Spread 4-8m,
-- enormemente più ampio della bozza — è una rampicante estremamente
-- vigorosa, coerente con l'alert già presente su "Richiede molto spazio".
-- Aggiunto alert mancante su malattie reali (muffa grigia, oidio), non
-- presenti nella bozza (#132).

update specie set esigenze = $j${"luce": "Pieno sole", "acqua": "Abbondante durante la crescita", "terreno": "Fertile, ricco di sostanza organica, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Cucurbitaceae", "giorni_germinazione": "10-15", "giorni_trapianto": "20-25", "giorni_raccolta": "90-120", "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera"], "resistenza_gelo": "nessuna", "spaziatura_cm": 300, "consociazioni_favorevoli": ["mais", "fagiolo"], "consociazioni_sfavorevoli": ["patata"]}$j$::jsonb, alert = ARRAY[$t$Richiede molto spazio per svilupparsi (rampicante vigorosa)$t$, $t$teme il freddo: mettere a dimora solo dopo le ultime gelate$t$, $t$impollinazione manuale utile in assenza di insetti impollinatori$t$, $t$raccolta a fine estate/inizio autunno, quando la buccia si indurisce$t$, $t$può essere colpita da muffa grigia e oidio$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Cucurbita moschata$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$zucca$t$;
