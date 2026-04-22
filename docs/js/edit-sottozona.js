// docs/js/edit-sottozona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const sottozona = getParam("sottozona");

  const title = document.getElementById("edit-title");
  const form = document.getElementById("edit-form");

  if (!zona || !sottozona) {
    title.textContent = "Zona o sottozona non specificata";
    return;
  }

  title.textContent = `Modifica sottozona: ${sottozona}`;

  // Carica tutte le sottozone
  const data = await loadJSON("sottozone.json");

  if (!data || !data[zona] || !data[zona][sottozona]) {
    title.textContent = "Sottozona non trovata";
    return;
  }

  const sz = data[zona][sottozona];

  // -----------------------------
  // 1) Popola i campi del form
  // -----------------------------
  document.getElementById("nome").value = sz.nome || "";

  // DESCRIZIONE
  const descrizioneEditor = pell.init({
    element: document.getElementById("descrizione-editor"),
    onChange: html => {
      document.getElementById("descrizione").value = html;
    }
  });
  descrizioneEditor.content.innerHTML = sz.descrizione || "";
  document.getElementById("descrizione").value = sz.descrizione || "";

  // CRITICITÀ
  const criticitaEditor = pell.init({
    element: document.getElementById("criticita-editor"),
    onChange: html => {
      document.getElementById("criticita").value = html;
    }
  });
  criticitaEditor.content.innerHTML = sz.criticita || "";
  document.getElementById("criticita").value = sz.criticita || "";

  // MANUTENZIONE (aggiunta da te)
  const manutenzioneEditor = pell.init({
    element: document.getElementById("manutenzione-editor"),
    onChange: html => {
      document.getElementById("manutenzione").value = html;
    }
  });
  manutenzioneEditor.content.innerHTML = sz.manutenzione || "";
  document.getElementById("manutenzione").value = sz.manutenzione || "";

  // MICROCLIMA
  const microclimaEditor = pell.init({
    element: document.getElementById("microclima-editor"),
    onChange: html => {
      document.getElementById("microclima").value = html;
    }
  });
  microclimaEditor.content.innerHTML = sz.microclima || "";
  document.getElementById("microclima").value = sz.microclima || "";

  // TIPO
  document.getElementById("tipo").value = sz.tipo || "interno";

  // ESPOSIZIONE
  const esposizioni = sz.esposizione || [];
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

    data[zona][sottozona] = {
      nome: document.getElementById("nome").value.trim(),
      descrizione: document.getElementById("descrizione").value,
      esposizione: nuovaEsposizione,
      microclima: document.getElementById("microclima").value,
      criticita: document.getElementById("criticita").value,
      manutenzione: document.getElementById("manutenzione").value,
      tipo: document.getElementById("tipo").value
    };

    const ok = await saveJSON("sottozone.json", data);

    if (ok) {
      alert("Sottozona aggiornata con successo.");
      window.location.href = `sottozona.html?zona=${zona}&sottozona=${sottozona}`;
    } else {
      alert("Errore durante il salvataggio.");
    }
  });
});
