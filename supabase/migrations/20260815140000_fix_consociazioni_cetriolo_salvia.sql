-- #131: verifica di coerenza delle consociazioni, ora che il catalogo è
-- completo (104/104). Trovata un'unica asimmetria reale tra le 7 specie che
-- si citano a vicenda (le altre 16 piante citate come consociazione non
-- esistono nel catalogo, quindi non verificabili): salvia segnala cetriolo
-- come sfavorevole, cetriolo non lo reciprocava — relazione nota anche nella
-- pratica orticola, non solo forzata per coerenza interna.
update specie set ciclo_colturale = $j${"famiglia_botanica": "Cucurbitaceae", "giorni_germinazione": "6-10", "giorni_trapianto": "20-30", "giorni_raccolta": "50-70", "finestra_semina": ["primavera"], "finestra_trapianto": ["primavera", "estate"], "resistenza_gelo": "nessuna", "spaziatura_cm": 40, "consociazioni_favorevoli": ["fagiolo", "mais", "girasole"], "consociazioni_sfavorevoli": ["patata", "salvia"]}$j$::jsonb where slug = $t$cetriolo$t$;
