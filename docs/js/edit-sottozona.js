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

  let data = await loadJSON("sottozone.json");
  let sz = null;
  let isNew = false;

  if (!data[zona]) data[zona] = {};

  // -----------------------------
  // NUOVA SOTTOZONA
  // -----------------------------
  if (sottozona === "NUOVA") {
    isNew = true;
    title.textContent = `Nuova sottozona in: ${zona}`;

    sz = {
      nome: "",
      descrizione: "",
      esposizione: [],
      microclima: "",
      criticita: "",
      manutenzione: "",
      tipo: "interno"
    };
  } else {
    // -----------------------------
    // MODIFICA SOTTOZONA
    // -----------------------------
    if (!zona || !sottozona || !data[zona][sottozona]) {
      title.textContent = "Sottozona non trovata";
      return;
    }

    title.textContent = `Modifica sottozona: ${sottozona}`;
    sz = data[zona][sottozona];
  }

  // -----------------------------
  // POPOLA FORM
  // -----------------------------
  document.getElementById("nome").value = sz.nome || "";

  // DESCRIZIONE
  const descrizioneEditor = pell.init({
    element: document.getElementById("descrizione-editor"),
    onChange: html => document.getElementById("descrizione").value = html
  });
  descrizioneEditor.content.innerHTML = sz.descrizione || "";
  document.getElementById("descrizione").value = sz.descrizione || "";

  // CRITICITÀ
  const criticitaEditor = pell.init({
    element: document.getElementById("criticita-editor"),
    onChange: html => document.getElementById("criticita").value = html
  });
  criticitaEditor.content.innerHTML = sz.criticita || "";
  document.getElementById("criticita").value = sz.criticita || "";

  // MANUTENZIONE
  const manutenzioneEditor = pell.init({
    element: document.getElementById("manutenzione-editor"),
    onChange: html => document.getElementById("manutenzione").value = html
  });
  manutenzioneEditor.content.innerHTML = sz.manutenzione || "";
  document.getElementById("manutenzione").value = sz.manutenzione || "";

  // MICROCLIMA
  const microclimaEditor = pell.init({
    element: document.getElementById("microclima-editor"),
    onChange: html => document.getElementById("microclima").value = html
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
  // SALVATAGGIO
  // -----------------------------
  form.addEventListener("submit", async (e) => {
    e.preventDefault();

    const nuovoNome = document.getElementById("nome").value.trim();
    if (!nuovoNome) {
      alert("Il nome della sottozona è obbligatorio.");
      return;
    }

    const nuovaEsposizione = ["nord", "sud", "est", "ovest"].filter(dir =>
      document.getElementById(`exp-${dir}`).checked
    );

    const key = isNew ? nuovoNome : sottozona;

    data[zona][key] = {
      nome: nuovoNome,
      descrizione: document.getElementById("descrizione").value,
      esposizione: nuovaEsposizione,
      microclima: document.getElementById("microclima").value,
      criticita: document.getElementById("criticita").value,
      manutenzione: document.getElementById("manutenzione").value,
      tipo: document.getElementById("tipo").value
    };

    if (!isNew && nuovoNome !== sottozona) {
      delete data[zona][sottozona];
    }

    const ok = await saveJSON("sottozone.json", data);

    if (ok) {
      alert(isNew ? "Sottozona creata con successo." : "Sottozona aggiornata con successo.");
      window.location.href = `sottozona.html?zona=${zona}`;
    } else {
      alert("Errore durante il salvataggio.");
    }
  });
});
