Lancia UN lotto di traduzione e naturalizzazione delle **schede** rimaste in inglese (issue **#153**). Dal 28/10/2026 si lavora sulla tabella `schede` del modello tassonomico: `specie` è un archivio chiuso e una modifica lì non arriva più nell'app (vedi CLAUDE.md, «Modello tassonomico»). I lotti 1-78 erano su `specie`; il 79 è stato il primo su `schede` (66 schede delle piante dell'utente, verificato e approvato come prova).

Le regole di stile sono nella skill `naturalizza-descrizioni` (`.claude/commands/naturalizza-descrizioni.md`): leggila prima di scrivere, può essere cambiata. Argomento facoltativo (`$ARGUMENTS`): la dimensione del lotto (predefinita 70).

## Che cosa è «da fare»

Una scheda mostrata (`mostrata = true`) è da fare se:
- la descrizione è ancora il testo inglese di RHS (coincide con la citazione tra virgolette in `descrizione_originale`), o ha comunque prosa inglese;
- oppure un avviso è ancora «Parassiti/Potatura/Propagazione (testo in inglese): …».

«Rischi (testo in inglese)» resta in inglese: è un dato di sicurezza e la sua traduzione è rimandata a un giro dedicato (scelta dell'utente del 31/08/2026). Le schede non mostrate non si toccano. La logica è in `scripts/naturalizza-batch/esporta_schede.sql`, che mette in testa le schede che l'utente vede per le sue piante. `python3 scripts/naturalizza-batch/esporta_schede.py --conta` dice quante ne restano.

## Procedura

1. **Esporta**: `cd scripts/naturalizza-batch && python3 esporta_schede.py --limite <N>`. Scrive `lottoN_schede.json` (ignorato da git): per ogni scheda id, livello (genere, specie, cultivar), nome scientifico, famiglia (da `taxa`), descrizione, `descrizione_originale`, avvisi, esigenze, ciclo vitale e `aggiornata_il`. Non serve più `scripts/backup-db.sh`: il backup del lotto è il file di rollback del punto 3.

2. **Traduci e adatta tu, nella sessione principale**, scheda per scheda, scrivendo `lottoN_traduzioni.json`. Le descrizioni non sono una traduzione frase per frase: vanno riscritte nella voce delle enciclopedie botaniche cartacee, con gli stessi fatti dell'originale (sezione «Il modello di voce» della skill di stile, con i brani modello: rileggili prima di ogni lotto). Gli avvisi invece sono indicazioni pratiche e si traducono asciutti.
   ```json
   {"<id>": {"descrizione": "…", "alert": {"8": "Parassiti: …", "11": null}, "ciclo_vitale": "perenne"}}
   ```
   - `alert` va per indice (da 0) nell'array dell'export; si scrivono solo le voci da cambiare; `null` toglie la voce (segnaposto come «See cultivation notes», doppioni). Le voci «Rusticità:», «Dimensioni a maturità:» e «Rischi (testo in inglese)» non si toccano: lo script rifiuta il lotto.
   - Leggi ogni scheda per intero, anche gli avvisi già in italiano: se una voce italiana dice già la stessa cosa in forma più povera, non duplicarla in prosa, e segnala il doppione nel resoconto invece di cancellarlo.
   - Se una descrizione italiana è già a posto e ci sono solo avvisi da tradurre, non riscrivere la descrizione.

3. **Prepara e controlla**: `python3 scrivi_schede.py --lotto lottoN_schede.json --traduzioni lottoN_traduzioni.json`. Controlla indici, voci intoccabili, fonti citate, parole inglesi rimaste, codici H, note editoriali; se trova errori non scrive niente. Produce `lottoN_schede_scrittura.sql` e `lottoN_schede_rollback.sql` (rimette le schede com'erano: `psql "$SUPABASE_DB_URL" -X -1 -v ON_ERROR_STOP=1 -f lottoN_schede_rollback.sql`).

4. **Verifica indipendente prima di scrivere**: un agente `general-purpose` riceve, per ogni scheda, le coppie originale → tradotto (descrizione e voci) e controlla fatti persi o aggiunti, termini botanici e fitopatologici italiani, concordanza di genere con il nome italiano della pianta, e se le descrizioni hanno la voce delle enciclopedie (dagli i brani modello della skill di stile) o sono rimaste una traduzione ricalcata sull'inglese. Dagli l'elenco delle eccezioni volute (vedi «Eccezioni volute» sotto), altrimenti le segnala come errori. Correggi le traduzioni e rilancia il punto 3.

5. **Scrivi**: `python3 scrivi_schede.py … --applica`. Una transazione sola; si ferma se una scheda è cambiata dopo l'export (controllo su `aggiornata_il`, che il trigger aggiorna da sé).

6. **Ricontrolla sul database** con `controlla_schede.sql` sugli id del lotto (istruzioni nel file): tutti i conteggi a 0 tranne `totale`. Falsi positivi noti: `voci_doppie` conta anche avvisi italiani liberi che iniziano con «Potatura …»; `etichette_in_prosa` conta gli stub «Famiglia botanica: …» che non erano nel lotto. Poi leggi per intero 4-5 schede.

7. **Resoconto** breve in italiano: schede scritte, correzioni del verificatore, casi dubbi lasciati intatti, residuo (`esporta_schede.py --conta`). Niente `git add` o commit dei file del lotto (sono ignorati).

## Eccezioni volute (da dare sempre al verificatore)

- I rimandi alle pagine RHS («See sowing vegetable seeds», «see Fan trained trees», «See bulb propagation») si tolgono; una voce con solo «See cultivation notes» si toglie del tutto.
- Le temperature in Fahrenheit tra parentesi si tolgono, restano i °C.
- Il numero del gruppo di potatura RHS («pruning group N», anche quelli delle clematidi e delle rose) non compare mai: al suo posto va la frase fissa del gruppo, approvata dall'utente il 29/10/2026, in `scripts/naturalizza-batch/frasi_potatura.py` (per una scheda di *Clematis* i gruppi 1-3 sono quelli delle clematidi, `C1`-`C3`). Le altre indicazioni della voce restano; se la voce dà un periodo, vale quello. Quando la voce dice di non tagliare nel legno vecchio (Cytisus, Genista…), si usa solo l'indicazione specifica. I rimandi («see Eucalyptus pruning», video) si tolgono. Fino al 29/10 la convenzione era «gruppo di potatura N»: quelle voci sono state riscritte nel lotto 80.
- Le voci RHS doppie della stessa scheda si fondono in una, con l'unione delle informazioni.
- Se l'originale ha parassiti e malattie scambiati (malattie sotto «pests»), il tradotto li rimette al posto giusto.
- Nelle descrizioni di genere la famiglia botanica viene dal campo `famiglia` dell'export; non si nominano le fonti né le cultivar elencate da RHS (restano in `descrizione_originale`).

## Glossario usato nel lotto 79

Parassiti: mealybugs cocciniglie farinose; scale insects cocciniglie; soft scale cocciniglie molli; cushion scale cocciniglia cotonosa; fluted scale cocciniglia cotonosa solcata; vine weevil oziorrinco; glasshouse red spider mite ragnetto rosso delle serre; two-spotted mite acaro a due macchie; glasshouse whitefly mosca bianca delle serre; leafhoppers cicaline; Thrips tripidi; fungus gnats moscerini dei funghi; slugs and snails limacce e lumache; earwigs forbicine; flea beetles altiche; cabbage root fly mosca del cavolo; leaf miners minatori fogliari; bay sucker psilla dell'alloro; large narcissus bulb fly mosca del narciso; narcissus eelworm nematode del narciso; bulb scale mite acaro dei bulbi; agapanthus gall midge cecidomia dell'agapanto.
Malattie: powdery mildew oidio; downy mildew peronospora; grey mould muffa grigia; honey fungus armillaria; club root ernia del cavolo; white blister ruggine bianca; peach leaf curl bolla del pesco; silver leaf mal del piombo; blossom wilt moniliosi dei fiori; brown rot marciume bruno dei frutti; bacterial canker cancro batterico; crown gall tumore batterico del colletto; olive scab occhio di pavone; onion white rot marciume bianco della cipolla; leafy gall galla fogliosa; anther smut carbone delle antere.
Propagazione: softwood cuttings talee erbacee; semi-ripe o semi-hardwood cuttings talee semilegnose; hardwood cuttings talee legnose; layering propaggine; mound-layering rincalzatura (margotta di ceppaia); offsets polloni (cactacee, succulente) o bulbilli (bulbose); chipping frammentazione del bulbo; cold frame cassone freddo; bottom heat calore dal basso; sow in situ seminare a dimora.
