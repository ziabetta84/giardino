-- Verifica reale (#120), pagina RHS salvata localmente da Roberta.
--
-- Corretta resistenza_gelo da "media" ad "alta": RHS classifica H5,
-- coerente con la scala già stabilita (H5→alta). Aggiunto un dato reale
-- importante non presente in bozza: RHS segnala che il rischio principale
-- legato al sole non è solo il caldo pomeridiano (già noto in bozza), ma
-- anche il sole del primo mattino dopo gelate notturne, che può causare
-- scottature da disgelo rapido sui boccioli — meccanismo diverso,
-- entrambi reali e complementari. spaziatura_cm (150) NON corretta
-- nonostante RHS indichi Max Height 8-12m e Max Spread 4-8m per l'arbusto
-- maturo in piena libertà: la camelia da giardino è comunemente mantenuta
-- compatta tramite potature, coerente con casi analoghi già trattati
-- (alloro, agrumi). Aggiunto un gap di alert reale su parassiti e
-- malattie specifiche, non presenti nella bozza (#132).

update specie set esigenze = $j${"luce": "Mezz'ombra, teme il sole diretto intenso del pomeriggio estivo", "acqua": "Costante, senza ristagni", "terreno": "Acido, ricco di sostanza organica, ben drenato"}$j$::jsonb, ciclo_colturale = $j${"famiglia_botanica": "Theaceae", "giorni_germinazione": null, "giorni_trapianto": null, "giorni_raccolta": null, "finestra_semina": [], "finestra_trapianto": ["autunno"], "resistenza_gelo": "alta", "spaziatura_cm": 150, "consociazioni_favorevoli": [], "consociazioni_sfavorevoli": []}$j$::jsonb, alert = ARRAY[$t$non tollera terreni calcarei: usare terriccio specifico per acidofile$t$, $t$evitare gusci d'uovo o altri ammendanti calcitanti (alzano il pH)$t$, $t$teme il sole diretto e intenso del primo pomeriggio estivo: posizione riparata preferibile$t$, $t$evitare ristagni idrici (rischio marciumi radicali)$t$, $t$non potare sul legno vecchio subito prima della fioritura$t$, $t$i boccioli possono cadere per stress idrico o sbalzi termici$t$, $t$fioritura tra fine inverno e primavera$t$, $t$RHS segnala un meccanismo di danno diverso da quello già noto: il sole del primo mattino dopo notti fredde può causare scottature da disgelo rapido sui boccioli, non solo il caldo pomeridiano estivo$t$, $t$può essere soggetta ad afidi, cocciniglie e oziorrinco$t$, $t$può essere colpita da marciume radicale (Phytophthora), galla della camelia, bruciatura fogliare, virus del mosaico giallo e blight dei petali$t$], fonti = ARRAY[$t$RHS Plants (rhs.org.uk) — Camellia japonica$t$], stato_verifica = $t$verificato$t$, verificata_il = now(), verificata_da = $t$Roberta + Claude Code (pagine RHS salvate e lette localmente)$t$ where slug = $t$camelia$t$;
