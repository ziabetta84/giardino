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

  // DESCRIZIONE
  const descrizioneEditor = pell.init({
    element: document.getElementById('descrizione-editor'),
    onChange: html => {
      document.getElementById('descrizione').value = html;
    }
  });
  descrizioneEditor.content.innerHTML = z.descrizione || "";
  document.getElementById('descrizione').value = z.descrizione || "";

  // CRITICITÀ
  const criticitaEditor = pell.init({
    element: document.getElementById('criticita-editor'),
    onChange: html => {
      document.getElementById('criticita').value = html;
    }
  });
  criticitaEditor.content.innerHTML = z.criticita || "";
  document.getElementById('criticita').value = z.criticita || "";

  // MANUTENZIONE (aggiunta da te)
  const manutenzioneEditor = pell.init({
    element: document.getElementById('manutenzione-editor'),
    onChange: html => {
      document.getElementById('manutenzione').value = html;
    }
  });
  manutenzioneEditor.content.innerHTML = z.manutenzione || "";
  document.getElementById('manutenzione').value = z.manutenzione || "";

  // MICROCLIMA
  const microclimaEditor = pell.init({
    element: document.getElementById('microclima-editor'),
    onChange: html => {
      document.getElementById('microclima').value = html;
    }
  });
  microclimaEditor.content.innerHTML = z.microclima || "";
  document.getElementById('microclima').value = z.microclima || "";

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

    const nuovaEsposizione = ["nord", "sud", "est", "ovest"].filter(dir =>
      document.getElementById(`exp-${dir}`).checked
    );

    zoneData[zona] = {
      nome: document.getElementById("nome").value.trim(),
      descrizione: document.getElementById("descrizione").value,
      esposizione: nuovaEsposizione,
      microclima: document.getElementById("microclima").value,
      criticita: document.getElementById("criticita").value,
      manutenzione: document.getElementById("manutenzione").value,
      tipo: document.getElementById("tipo").value
    };

    const ok = await saveJSON("zone.json", zoneData);

    if (ok) {
      alert("Zona aggiornata con successo.");
      window.location.href = "zone.html";
    } else {
      alert("Errore durante il salvataggio.");
    }
  });
});
