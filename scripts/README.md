# identifyPlants - Automazione dell'identificazione e catalogazione delle piante

Questo script automatizza il processo di identificazione e organizzazione delle foto di piante nel giardino.

## Uso

```bash
./scripts/identifyPlants.sh zone:<zone_path>
```

### Esempi

```bash
# Identificare le piante nella zona crinale
./scripts/identifyPlants.sh zone:crinale

# Identificare le piante nel lato destro dello scivolo
./scripts/identifyPlants.sh zone:scivolo:lato-destro

# Identificare le piante nel lato sinistro dello scivolo
./scripts/identifyPlants.sh zone:scivolo:lato-sinistro
```

## Come funziona

1. **Ricerca foto non identificate**: Lo script cerca le foto con pattern `00_da_identificare.*` nella cartella `zona/foto/`

2. **Identificazione interattiva**: Per ogni foto:
   - Lo script chiede di eseguire Copilot CLI con un prompt specifico
   - Incolla il risultato nel formato: `nome_italiano|nome_scientifico`
   - Esempio: `lavanda|Lavandula angustifolia`

3. **Organizzazione automatica**:
   - Crea la cartella `zona/piante/[nome-pianta]/`
   - Sposta la foto da `00_da_identificare.jpg` a `00_[nome-pianta].jpg`
   - Se esiste già la cartella della pianta, aggiunge la foto

4. **Generazione documentazione**: 
   - Se il file `.md` non esiste, lo script richiede di generare la documentazione usando Copilot
   - La documentazione segue il template standard del progetto

## Workflow completo

### Passo 1: Preparare le foto

Metti le foto da identificare nella cartella foto della zona:

```
zone/[zona]/foto/00_da_identificare.jpg
zone/[zona]/foto/00_da_identificare_2.jpg
```

### Passo 2: Lanciare lo script

```bash
./scripts/identifyPlants.sh zone:scivolo:lato-destro
```

### Passo 3: Identificare la pianta con Copilot

Lo script mostrerà il comando da eseguire:

```bash
copilot -p "Analizza questa foto di una pianta nel giardino.

Identifica il nome comune italiano e il nome scientifico della pianta.

Rispondi in questo formato (UNA sola riga):
nome_italiano|nome_scientifico

Esempi:
lavanda|Lavandula angustifolia"
```

Esegui il comando in un'altra finestra di terminale, copia la risposta e incollala nello script.

### Passo 4: Generare la documentazione

Lo script mostrerà il comando per generare la documentazione markdown della pianta.

Esegui il comando in un'altra finestra di terminale, copia la risposta e incollala nello script.

## Naming Conventions

### Nome della pianta
- Usa il nome comune italiano
- Convertito in **kebab-case** (lettere minuscole, spazi convertiti a trattini)
- Esempi:
  - `lavanda` (Lavandula angustifolia)
  - `spiraea-arguta` (Spiraea arguta)
  - `heuchera` (Heuchera sanguinea)

### File foto
- Il file viene rinominato da `00_da_identificare.jpg` a `00_[nome-pianta].jpg`
- Esempio: `00_lavanda.jpg`

### Struttura creata

```
zone/scivolo/lato-destro/piante/lavanda/
├── lavanda.md
└── 00_lavanda.jpg
```

## Comportamento speciale

### Pianta già esistente
Se la cartella della pianta esiste già:
- Aggiunge la foto senza sovrascrivere la documentazione
- Incrementa il numero di sequenza se necessario

### Foto già identificate
Se il file non ha il pattern `00_da_identificare.*`, viene ignorato dallo script.

## Tips e Troubleshooting

### Come usare Copilot per l'identificazione

Quando lo script chiede l'identificazione, esegui questo comando in un'altra finestra:

```bash
copilot -p "Analizza questa foto di una pianta nel giardino.

Identifica il nome comune italiano e il nome scientifico della pianta.

Rispondi in questo formato (UNA sola riga):
nome_italiano|nome_scientifico

Esempi:
lavanda|Lavandula angustifolia"
```

Se vuoi passare la foto direttamente, puoi usare uno script wrapper (vedi sezione avanzata).

### Come usare Copilot per la documentazione

Quando lo script chiede la documentazione, esegui:

```bash
copilot -p "Analizza questa foto e genera documentazione botanica.

Nome: [nome-pianta]
Nome scientifico: [scientifico]
Zona: [zona]

Rispondi con SOLO il markdown usando questo template:

# [nome-pianta] ([scientifico])

## Informazioni generali
[descrizione]

## Esposizione
- **Luce**: [...]
- **Temperatura**: [...]
- **Umidità**: [...]

## Coltivazione
- **Terreno**: [...]
- **Annaffiature**: [...]
- **Concimazione**: [...]

## Potatura e manutenzione
[...]

## Parassiti e malattie
[...]

## Fioritura
- Periodo: [...]
- Colori fiori: [...]
- Profumo: [...]

## Note sulla foto
- **Data foto**: [Mese Anno]
- **Stato di salute**: [...]
- **Osservazioni**: [...]"
```

### Saltare la generazione documentazione

Se vuoi solo organizzare le foto senza generare la documentazione, premi `Enter` quando richiesto.

## Avanzate: Script wrapper per Copilot con foto

Se vuoi automatizzare completamente l'identificazione con la foto, puoi creare uno script wrapper che passa la foto a Copilot. Questo richiede di configurare MCP (Model Context Protocol) o usare un approccio diverso a seconda della tua versione di Copilot CLI.

Contatta il maintainer per una versione avanzata.
