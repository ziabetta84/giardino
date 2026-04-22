// docs/js/edit-sottozona.js

// Inizializza editor WYSIWYG
const descrizioneEditor = pell.init({
  element: document.getElementById('descrizione-editor'),
  onChange: html => {
    document.getElementById('descrizione').value = html;
  },
  defaultParagraphSeparator: 'p',
  styleWithCSS: false
});

// Imposta contenuto iniziale
descrizioneEditor.content.innerHTML = z.descrizione || "";
document.getElementById('descrizione').value = z.descrizione || "";

// Inizializza editor WYSIWYG per la criticità
const criticitaEditor = pell.init({
  element: document.getElementById('criticita-editor'),
  onChange: html => {
    document.getElementById('criticita').value = html;
  },
  defaultParagraphSeparator: 'p',
  styleWithCSS: false
});

// Imposta contenuto iniziale per la criticità
criticitaEditor.content.innerHTML = z.criticita || "";
document.getElementById('criticita').value = z.criticita || "";

// Inizializza editor WYSIWYG per la manutenzione
const manutenzioneEditor = pell.init({
  element: document.getElementById('manutenzione-editor'),
  onChange: html => {
    document.getElementById('manutenzione').value = html;
  },
  defaultParagraphSeparator: 'p',
  styleWithCSS: false
});

// Imposta contenuto iniziale per la manutenzione
manutenzioneEditor.content.innerHTML = z.manutenzione || "";
document.getElementById('manutenzione').value = z.manutenzione || "";


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

  const key = `${zona}/${sottozona}`;
  title.textContent = `Modifica sottozona: ${sottozona}`;

  // Carica tutte le sottozone
  const sottozoneData = await loadJSON("sottozone.json");

  if (!sottozoneData || !sottozoneData[key]) {
    title.textContent = "Sottozona non trovata";
    return;
  }

  const s = sottozoneData[key];

  // -----------------------------
  // 1) Popola i campi del form
  // -----------------------------
  document.getElementById("nome").value = s.nome || "";
  document.getElementById("descrizione").value = s.descrizione || "";
  document.getElementById("microclima").value = s.microclima || "";
  document.getElementById("criticita").value = s.criticita || "";
  document.getElementById("manutenzione").value = s.manutenzione || "";
  document.getElementById("tipo").value = s.tipo || "interno";

  // Esposizione (checkbox)
  const esposizioni = s.esposizione || [];
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
    sottozoneData[key] = {
      nome: document.getElementById("nome").value.trim(),
      zona: zona,
      descrizione: document.getElementById("descrizione").value.trim(),
      esposizione: nuovaEsposizione,
      microclima: document.getElementById("microclima").value.trim(),
      criticita: document.getElementById("criticita").value.trim(),
      manutenzione: document.getElementById("manutenzione").value.trim(),
      tipo: document.getElementById("tipo").value
    };

    // Salva su GitHub
    const ok = await saveJSON("sottozone.json", sottozoneData);

    if (ok) {
      alert("Sottozona aggiornata con successo.");
      window.location.href = `sottozona.html?zona=${encodeURIComponent(zona)}`;
    } else {
      alert("Errore durante il salvataggio.");
    }
  });
});
