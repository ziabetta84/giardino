# Generi come entità propria — specifica

Data: 08/10/2026 · Stato: bozza da approvare, nessuna modifica al database fatta.

## Obiettivo

Dare al genere botanico un posto suo nel modello dati, così che:

1. le cultivar nominate "Genere 'Epiteto'" (circa 16.400 oggi senza nome italiano) possano prendere il nome italiano del genere;
2. chi non conosce la specie possa scegliere "Genere spp." come pianta;
3. il modello sia coerente prima che l'app abbia altri utenti (oggi l'unico utente è il proprietario, 121 piante).

## Stato attuale (misurato l'07-08/10/2026)

- 570 righe `specie` con slug di una sola parola (righe di genere). 514 sono usate: 505 hanno cultivar, 46 hanno piante (9 solo piante).
- 121 di queste righe hanno un `nome_scientifico` binomiale (nome di una specie rappresentativa, es. `rhododendron` → *Rhododendron simsii*); 10 hanno già la forma "Genere spp." o "Genere sp.".
- Il contenuto è misto: la descrizione di *Rhododendron* e *Impatiens* parla del genere, quella di *Gerbera* della specie *G. jamesonii*.
- 66 delle 121 piante dell'utente puntano a una riga di genere.
- 127 madri hanno cultivar il cui nome non inizia col nome scientifico della madre (17.642 cultivar); 58 sono righe di genere (16.375 cultivar). I casi con "x" nello slug (ibridi) non sono stati analizzati.
- Codice che usa la gerarchia: `src/stores/dati.js` (`fondiEredita`) e `src/components/SelettoreSpecie.vue`; più gli script in `scripts/`.

## Verifica sulla fonte RHS (08/10/2026)

Nelle pagine RHS locali (`fonti/rhs_from_sitemaps/`, campione casuale di 4.000) il `parentTaxon` di ogni pagina è il genere, mai una specie, e "Botanical Details" non ha un campo specie (solo famiglia, descrizione del genere, stato del nome, gruppo orticolo). Quindi RHS colloca le cultivar "Genere 'Epiteto'" al livello del genere: l'aggancio attuale al genere riflette la fonte, e riagganciarle alle specie non è necessario né ricavabile da RHS. Il difetto da correggere è solo il `nome_scientifico` delle righe di genere.

## Decisioni già prese

1. Il genere è selezionabile come pianta: esiste una riga "Genere spp." in `specie`.
2. La riga "Genere spp." si crea solo per i generi che hanno già cultivar o piante (514), non per tutti (2.920 generi distinti nel catalogo).
3. Criterio per distinguere genere e specie: numero di specie accettate del genere secondo **GBIF**, salvato nella tabella con la data di rilevazione (non si ricalcola da solo).
   - Più di una specie accettata: la riga selezionabile è "Genere spp.".
   - Una sola specie accettata: la riga resta quella della specie, senza "spp.".
4. Nomi italiani dei generi: solo da iNaturalist (o EPPO), come per le specie; altrimenti il nome scientifico. Nessuna traduzione manuale.
5. Le righe di genere esistenti mantengono lo **slug** (le 66 piante restano collegate). Per queste righe il `nome_scientifico` diventa "Genere spp.": è un'eccezione, limitata a queste righe, alla regola per cui `nome_scientifico` non cambia.
6. Contenuti delle righe di genere: controllo riga per riga. Se la descrizione parla di una specie, i dati (descrizione, cura) passano a una riga di specie (nuova se non esiste); se parla del genere restano dove sono.
7. Il caso "azalea" non è parte di questo lavoro.

## Modello dati proposto

- Tabella `generi`: `id`, `nome_scientifico` (unico), `nome` (italiano, unico, come `specie.nome`), `specie_gbif` (intero), `gbif_rilevato_il` (data), `gbif_key`.
- Colonna `specie.genere_id` (FK verso `generi`), valorizzata per tutte le righe `specie` dal primo termine del `nome_scientifico`, dove il genere esiste in tabella. Si crea una riga in `generi` per ogni genere presente (2.920), così il collegamento è completo; la riga "spp." esiste solo per i 514.
- RLS come `specie`: lettura pubblica, scrittura solo service-role.

## Nomi delle cultivar

- Cultivar con nome "Genere 'Epiteto'": nome italiano = `generi.nome` + " 'Epiteto'", se il genere ha un nome italiano e il risultato non è già in uso.
- Le cultivar con nome "<Specie> 'Epiteto'" continuano a usare il nome italiano della madre (lotti 7-10).

## Piano di lavoro (ogni passo con backup, prova in transazione annullata e rollback)

1. Creare `generi` e `specie.genere_id`; popolare da `nome_scientifico`.
2. Rilevare da GBIF le specie accettate per i 514 generi usati.
3. Cercare il nome italiano dei generi su iNaturalist (poi EPPO come riscontro).
4. Nelle righe di genere: classificare descrizione (genere / specie), creare le righe-specie necessarie, passare a "Genere spp." dove il criterio lo richiede.
5. Rinominare le cultivar "Genere 'Epiteto'".
6. Adattare `dati.js` e `SelettoreSpecie.vue` (mostrare il genere, ricerca per nome del genere), con verifica nel browser.

## Rischi e punti aperti

- Le piante che puntano a righe di genere cambiano significato (da "specie rappresentativa" a "genere"): va verificato che i dati di cura mostrati restino sensati.
- GBIF può contare in modo diverso da altre fonti; si registra la data e non si ricalcola in automatico.
- Gli ibridi con la "x" nello slug (es. `viola-x-wittrockiana`) hanno cultivar il cui nome non inizia col nome scientifico della madre: da analizzare prima del passo 5.
- Il passo 6 non è stimato: dipende da come l'app usa oggi i campi della riga di genere.
