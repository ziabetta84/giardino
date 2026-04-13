# 🌿 Documentazione del Giardino di Rob

Questo repository contiene la documentazione strutturata del giardino, organizzata in zone, piante, progetti e manutenzione.  
L’obiettivo è mantenere una conoscenza ordinata, versionata e facilmente consultabile dell’evoluzione del giardino nel tempo.

---

## 📁 Struttura del repository

```text
giardino/
├── README.md
├── copilot.json
├── generale/
├── manutenzione/
│   ├── calendario-annuale.md
│   ├── irrigazione.md
│   ├── potature.md
│   └── periodica/
├── notifiche-github/
│   ├── config.giardino.json
│   ├── genera_notifica.py
│   └── README.md
├── progetti/
│   ├── README.md
│   ├── casa.md
│   ├── crinale.md
│   └── est.md
├── scripts/
│   ├── identifyPlants.sh
│   └── README.md
└── zone/
    ├── casa/
    ├── crinale/
    ├── est/
    ├── orto/
    ├── scivolo/
    └── vialetto/
```

La struttura dettagliata delle sottocartelle cambia nel tempo: per questo il README mostra solo i livelli stabili.


---

## 🧭 Linee guida per la documentazione

### **Zone**
Ogni zona contiene:
- esposizione
- microclima
- suolo
- piante presenti
- piante consigliate
- problemi da evitare
- note storiche
- foto contestuali

### **Piante**
Ogni pianta ha una scheda dedicata con:
- esposizione ideale
- esigenze del terreno
- comportamento e crescita
- compatibilità
- posizione nel giardino
- manutenzione
- foto specifiche

Nota: quando presente il nome scientifico, va scritto in corsivo.

### **Progetti**
Ogni progetto documenta:
- obiettivo
- piante coinvolte
- schema visivo
- stato attuale
- prossimi passi

### **Manutenzione**
Include:
- calendario annuale
- potature
- irrigazione
- note operative periodiche

---

## 🤖 Uso con Copilot CLI

Questo repository è pensato per essere usato con Copilot CLI per:

- generare nuove schede (`.md`)
- aggiornare zone o piante
- creare progetti
- proporre modifiche strutturate
- mantenere coerenza tra i file

Per identificare e organizzare automaticamente foto di piante non classificate:

- eseguire `./scripts/identifyPlants.sh zone:<percorso-zona>`
- esempio: `./scripts/identifyPlants.sh zone:scivolo:lato-destro`

### Identificazioni dinamiche (consigliato)

Per evitare elenchi statici nel README, puoi ricavare la situazione aggiornata direttamente dal repository.

- zone documentate:
	`find zone -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort`
- schede piante presenti in una zona:
	`find zone/<zona> -type f -name '*.md' -path '*/piante/*' | sort`
- manutenzioni periodiche disponibili:
	`find manutenzione/periodica -maxdepth 1 -type f -name '*.md' | sort`
- conteggio rapido schede pianta:
	`find zone -type f -name '*.md' -path '*/piante/*' | wc -l`

Esempi di prompt utili:

- “Aggiorna `zone/scivolo/lato-destro/lato-destro.md` aggiungendo la Glechoma.”
- “Crea la scheda della pianta Stipa tenuissima nel lato frontale dello scivolo.”
- “Genera un nuovo progetto per la bordura del lato sinistro dello scivolo.”
- “Aggiungi note storiche alla zona est.”

---

## 📌 Obiettivo del progetto

Costruire una documentazione viva, ordinata e versionata del giardino, utile per:

- progettazione
- manutenzione
- pianificazione stagionale
- evoluzione nel tempo
- sperimentazione con l’AI

---

## 📷 Media

Le foto sono sempre collocate nella cartella `foto/` della zona o della pianta corrispondente, per mantenere ordine e contesto.

Quando disponibili, aggiungere nelle note anche mese e anno di riferimento della foto.

---

## 📝 Licenza

Uso personale.
