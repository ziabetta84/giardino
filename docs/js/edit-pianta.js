// docs/js/edit-pianta.js

function getParam(name) {
  return new URLSearchParams(location.search).get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const id = getParam("id");
  const zonaParam = getParam("zona");
  const sottoParam = getParam("sottozona");

  const form = document.getElementById("edit-form");
  const title = document.getElementById("edit-title");

  const specie = await loadJSON("specie.json");
  const zone = await loadJSON("zone.json");
  const sottozone = await loadJSON("sottozone.json");
  const piante = await loadJSON("piante.json");

  let editingSpecieKey = null;

  // -----------------------------
  // POPOLA SELECT SPECIE
  // -----------------------------
  const specieSel = document.getElementById("specie");
  for (const key of Object.keys(specie)) {
    const opt = document.createElement("option");
    opt.value = key;
    opt.textContent = specie[key].nome;
    specieSel.appendChild(opt);
  }

  // -----------------------------
  // POPOLA SELECT ZONE
  // -----------------------------
  const zonaSel = document.getElementById("zona");
  for (const key of Object.keys(zone)) {
    const opt = document.createElement("option");
    opt.value = key;
    opt.textContent = zone[key].nome;
    zonaSel.appendChild(opt);
  }

  // -----------------------------
  // AGGIORNA SOTTOZONE
  // -----------------------------
  zonaSel.onchange = () => {
    const z = zonaSel.value;
    const sottoSel = document.getElementById("sottozona");
    sottoSel.innerHTML = `<option value="">(nessuna)</option>`;

    if (sottozone[z]) {
      for (const s of Object.keys(sottozone[z])) {
        const opt = document.createElement("option");
        opt.value = s;
        opt.textContent = sottozone[z][s].nome;
        sottoSel.appendChild(opt);
      }
    }
  };

  // -----------------------------
  // SE MODIFICA PIANTA
  // -----------------------------
  let current = null;

  if (id && piante[id]) {
    current = piante[id];
    title.textContent = "Modifica Pianta";

    specieSel.value = current.specie;
    zonaSel.value = current.zona;
    zonaSel.onchange();

    document.getElementById("sottozona").value = current.sottozona || "";
    document.getElementById("varieta").value = current.varieta || "";
    document.getElementById("impianto").value = current.impianto || "";
    document.getElementById("note").value = current.note || "";
  } else {
    title.textContent = "Nuova Pianta";

    if (zonaParam) zonaSel.value = zonaParam;
    zonaSel.onchange();
    if (sottoParam) document.getElementById("sottozona").value = sottoParam;
  }

  // ============================================================
  //  EDITOR SPECIE (NUOVA / MODIFICA)
  // ============================================================

  function openSpecieEditor(key, data) {
    const box = document.getElementById("specie-editor");
    const title = document.getElementById("specie-editor-title");

    editingSpecieKey = key;

    if (key === null) {
      title.textContent = "Nuova specie";
      document.getElementById("specie-nome").value = "";
      document.getElementById("specie-specie").value = "";
      document.getElementById("specie-descrizione").value = "";
      document.getElementById("specie-luce").value = "";
      document.getElementById("specie-acqua").value = "";
      document.getElementById("specie-terreno").value = "";
      document.getElementById("specie-alert").value = "";
    } else {
      title.textContent = "Modifica specie";
      document.getElementById("specie-nome").value = data.nome;
      document.getElementById("specie-specie").value = data.specie;
      document.getElementById("specie-descrizione").value = data.descrizione;
      document.getElementById("specie-luce").value = data.esigenze.luce;
      document.getElementById("specie-acqua").value = data.esigenze.acqua;
      document.getElementById("specie-terreno").value = data.esigenze.terreno;
      document.getElementById("specie-alert").value = data.alert.join("\n");
    }

    box.style.display = "block";
  }

  // Pulsante: Nuova specie
  document.getElementById("new-specie-btn").onclick = () => {
    openSpecieEditor(null, null);
  };

  // Pulsante: Modifica specie
  document.getElementById("edit-specie-btn").onclick = () => {
    const key = specieSel.value;
    if (!key) return alert("Seleziona una specie da modificare.");
    openSpecieEditor(key, specie[key]);
  };

  // ============================================================
  //  SALVATAGGIO PIANTA + SPECIE
  // ============================================================

  form.onsubmit = async (e) => {
    e.preventDefault();

    // ---------------------------------------
    // SALVA SPECIE SE L'EDITOR È APERTO
    // ---------------------------------------
    if (document.getElementById("specie-editor").style.display === "block") {
      const nome = document.getElementById("specie-nome").value.trim();
      const specieBot = document.getElementById("specie-specie").value.trim();
      const descr = document.getElementById("specie-descrizione").value.trim();
      const luce = document.getElementById("specie-luce").value.trim();
      const acqua = document.getElementById("specie-acqua").value.trim();
      const terreno = document.getElementById("specie-terreno").value.trim();
      const alertList = document.getElementById("specie-alert").value
        .split("\n")
        .map(s => s.trim())
        .filter(s => s);

      let key = editingSpecieKey;

      // Se è nuova specie → genera slug
      if (!key) {
        key = nome.toLowerCase().replace(/[^a-z0-9]+/g, "-");
        specieSel.value = key;
      }

      specie[key] = {
        nome,
        specie: specieBot,
        descrizione: descr,
        esigenze: { luce, acqua, terreno },
        alert: alertList
      };

      const okSpecie = await saveJSON("specie.json", specie);
      if (!okSpecie) return alert("Errore nel salvataggio della specie.");
    }

    // ---------------------------------------
    // SALVA PIANTA
    // ---------------------------------------
    const data = {
      specie: specieSel.value,
      zona: zonaSel.value,
      sottozona: document.getElementById("sottozona").value || null,
      varieta: document.getElementById("varieta").value.trim(),
      impianto: document.getElementById("impianto").value,
      note: document.getElementById("note").value.trim()
    };

    let newId = id;
    if (!id) newId = `${data.specie}-${Date.now()}`;

    piante[newId] = data;

    const ok = await saveJSON("piante.json", piante);

    if (ok) {
      alert("Pianta salvata.");
      window.location.href =
        `piante.html?zona=${data.zona}` +
        (data.sottozona ? "&sottozona=" + data.sottozona : "");
    }
  };
});
