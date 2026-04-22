// docs/js/edit-zona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");

  const title = document.getElementById("edit-title");
  const form = document.getElementById("edit-form");

  if (!zona) {
    title.textContent = "Zona non specificata";
    return;
  }

  title.textContent = `Modifica zona: ${zona}`;

  // Carica tutte le zone
  const zoneData = await loadJSON("zone.json");

  if (!zoneData || !zoneData[zona]) {
    title.textContent = "Zona non trovata";
    return;
  }

  const z = zoneData[zona];

  // -----------------------------
  // 1) Popola i campi del form
  // -----------------------------
  document.getElementById("nome").value = z.nome || "";
  document.getElementById("descrizione").value = z.descrizione || "";
  document.getElementById("microclima").value = z.microclima || "";
  document.getElementById("criticita").value = z.criticita || "";
  document.getElementById("manutenzione").value = z.manutenzione || "";
  document.getElementById("tipo").value = z.tipo || "interno";

  // Esposizione (checkbox)
  const esposizioni = z.esposizione || [];
  ["nord", "sud", "est", "ovest"].forEach(dir => {
    document.getElementById(`exp-${dir}`).checked = esposizioni.includes(dir);
  });

  // -----------------------------
  // 2) Salvataggio
  // -----------------------------
  form.addEventListener("submit", async (e) => {
    e.preventDefault();

    // Ricostruisci array esposizione
    const nuovaEsposizione = ["nord", "sud", "est", "ovest"].filter(dir =>
      document.getElementById(`exp-${dir}`).checked
    );

    // Aggiorna dati
    zoneData[zona] = {
      nome: document.getElementById("nome").value.trim(),
      descrizione: document.getElementById("descrizione").value.trim(),
      esposizione: nuovaEsposizione,
      microclima: document.getElementById("microclima").value.trim(),
      criticita: document.getElementById("criticita").value.trim(),
      manutenzione: document.getElementById("manutenzione").value.trim(),
      tipo: document.getElementById("tipo").value
    };

    // Salva su GitHub
    const ok = await saveJSON("zone.json", zoneData);

    if (ok) {
      alert("Zona aggiornata con successo.");
      window.location.href = "zone.html";
    } else {
      alert("Errore durante il salvataggio.");
    }
  });
});
