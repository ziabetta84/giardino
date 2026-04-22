// docs/js/edit-pianta.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

// Valori possibili per la potatura
const POTATURA_VALORI = [
  "nessuna",
  "taglio leggero",
  "taglio medio",
  "taglio drastico",
  "rimozione foglie secche",
  "accorciamento rami",
  "pulizia generale"
];

document.addEventListener("DOMContentLoaded", async () => {
  const nome = getParam("nome");

  const title = document.getElementById("edit-title");
  const form = document.getElementById("edit-form");

  if (!nome) {
    title.textContent = "Pianta non specificata";
    return;
  }

  title.textContent = `Modifica: ${nome}`;

  // Carica tutte le piante
  const piante = await loadJSON("piante.json");

  if (!piante || !piante[nome]) {
    title.textContent = "Pianta non trovata";
    return;
  }

  const p = piante[nome];

  // -----------------------------
  // 1) Popola i campi del form
  // -----------------------------
  document.getElementById("nome").value = p.nome || "";
  document.getElementById("specie").value = p.specie || "";
  document.getElementById("zona").value = p.zona || "";
  document.getElementById("sottozona").value = p.sottozona || "";

  // Irrigazione
  document.getElementById("irr-primavera").value = p.attivita?.irrigazione?.primavera || "";
  document.getElementById("irr-estate").value = p.attivita?.irrigazione?.estate || "";
  document.getElementById("irr-autunno").value = p.attivita?.irrigazione?.autunno || "";
  document.getElementById("irr-inverno").value = p.attivita?.irrigazione?.inverno || "";

  // Concimazione
  document.getElementById("conc-primavera").value = p.attivita?.concimazione?.primavera || "";
  document.getElementById("conc-estate").value = p.attivita?.concimazione?.estate || "";
  document.getElementById("conc-autunno").value = p.attivita?.concimazione?.autunno || "";
  document.getElementById("conc-inverno").value = p.attivita?.concimazione?.inverno || "";

  // Potatura (select)
  for (const stagione of ["primavera", "estate", "autunno", "inverno"]) {
    const select = document.getElementById(`pot-${stagione}`);
    POTATURA_VALORI.forEach(v => {
      const opt = document.createElement("option");
      opt.value = v;
      opt.textContent = v;
      select.appendChild(opt);
    });
    select.value = p.attivita?.potatura?.[stagione] || "nessuna";
  }

  // Alert (wysiwyg)
  document.getElementById("alert").value = p.alert || "";

  // -----------------------------
  // 2) Salvataggio
  // -----------------------------
  form.addEventListener("submit", async (e) => {
    e.preventDefault();

    // Aggiorna i dati nel JSON
    piante[nome] = {
      nome: document.getElementById("nome").value.trim(),
      specie: document.getElementById("specie").value.trim(),
      zona: document.getElementById("zona").value.trim(),
      sottozona: document.getElementById("sottozona").value.trim(),

      attivita: {
        irrigazione: {
          primavera: document.getElementById("irr-primavera").value.trim(),
          estate: document.getElementById("irr-estate").value.trim(),
          autunno: document.getElementById("irr-autunno").value.trim(),
          inverno: document.getElementById("irr-inverno").value.trim()
        },
        concimazione: {
          primavera: document.getElementById("conc-primavera").value.trim(),
          estate: document.getElementById("conc-estate").value.trim(),
          autunno: document.getElementById("conc-autunno").value.trim(),
          inverno: document.getElementById("conc-inverno").value.trim()
        },
        potatura: {
          primavera: document.getElementById("pot-primavera").value,
          estate: document.getElementById("pot-estate").value,
          autunno: document.getElementById("pot-autunno").value,
          inverno: document.getElementById("pot-inverno").value
        }
      },

      alert: document.getElementById("alert").value.trim()
    };

    // Salva su GitHub
    const ok = await saveJSON("piante.json", piante);

    if (ok) {
      alert("Pianta aggiornata con successo.");
      window.location.href = `pianta.html?nome=${encodeURIComponent(nome)}`;
    } else {
      alert("Errore durante il salvataggio.");
    }
  });
});
