# Criterio di disambiguazione dei nomi tra RHS e Catalogue of Life

Questo criterio è stato approvato da Roberta il 26/11/2026. Vale per i lotti di schede nuove scritte dalle pagine RHS e per il controllo mensile di RHS e PFAF (`scripts/rhs-import/`). Nasce da un problema preciso: RHS, che scrive per i giardinieri, usa a volte un nome latino nel senso dei vivai, mentre Catalogue of Life (COL), il riferimento del catalogo per i nomi, attribuisce quello stesso nome a un'altra pianta.

## Le regole

1. **I nomi li decide sempre COL.** Non si cambia mai a mano chi è specie e chi è sinonimo per seguire RHS. Se COL dice che A è sinonimo di B, A usa già la scheda di B e non c'è niente da fare.
2. **RHS serve solo per il contenuto.** Prima di scrivere una scheda da una pagina RHS si confronta ciò che la pagina descrive (colore e forma dei fiori, portamento, foglie, provenienza) con la pianta a cui COL porta quel nome.
3. **Se le due cose coincidono, si scrive la scheda. Se non coincidono, non si scrive.** Esempi del 24/11/2026:
   - «*Sedum roseum*» di RHS descrive la rodiola, a fiori gialli, ma COL porta il nome a *Phedimus stevenianus*;
   - «*Arabis sudetica*» di RHS descrive una violacciocca arancione;
   - «*Leucothoe walteri*» di RHS è la *Leucothoe fontanesiana* dei giardini, ma COL porta il nome ad *Agarista populifolia*.
4. **Segnali che impongono un controllo:**
   - «hort.» nel titolo RHS (nome usato nel senso dei vivai);
   - una descrizione che contraddice la pianta di arrivo;
   - cultivar della pagina che il catalogo ha già sotto un'altra specie;
   - un nome di genere usato da RHS per piante che COL mette in un altro genere (*Sutera* per la bacopa, *Dolichos* per *Lablab*).
5. **Una specie accettata da COL ha la sua scheda**, anche quando altri autori la considerano parte di un'altra specie. La scheda lo dice apertamente (per esempio «per molti autori è *Allium oreophilum*, si coltiva allo stesso modo») e riporta le cure. Due specie non si fondono mai in silenzio.
6. **Per scrivere «per molti autori è la stessa pianta» serve una fonte botanica:** Plants of the World Online (Kew) oppure, per le spontanee italiane, la flora di Pignatti. Un nome da vivaio, da solo, non basta: in quel caso la scheda racconta solo la confusione dei nomi, come per *Ficus maclellandii* 'Alii'.
7. **I casi dubbi li decide Roberta.** Abbinamenti incerti, pagine RHS con dati sbagliati e questioni di opinione botanica si mettono da parte e le si mostrano, con il motivo.
8. **Ogni decisione si registra** in `scripts/rhs-import/dati/rhs_agganci_decisi.tsv` (pagina RHS, nome COL, scheda giusta, motivo) e si può annullare. Ogni scrittura sul database ha il suo file di rollback.

Nel dubbio non si scrive: meglio una pianta senza scheda che una pianta con la scheda di un'altra.

## Che cosa non si fa (scelta del 26/11/2026)

Non c'è un «rimando» nel database del tipo «questo nome mostra la scheda di quell'altro». I vecchi nomi da vivaio elencati in `scripts/rhs-import/dati/rhs_rinvii_proposti.tsv` restano come li dà COL. Le loro cultivar sono già sulla specie giusta, quindi chi cerca la cultivar trova la scheda corretta.
