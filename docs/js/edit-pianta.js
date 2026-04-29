// docs/js/edit-pianta.js

function getParam(name) {
  return new URLSearchParams(location.search).get(name);
}

document.addEventListener("DOMContentLoaded", async () => {

  // 🔐 Controllo token GitHub
  const token = localStorage.getItem("github_token");
  if (!token) {
    window.location.href = "https://giardino.robertagenovese.workers.dev/login";
    return;
  }

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
  // POPOLA SELECT ZONE (usa NOME)
  // -----------------------------
  const zonaSel = document.getElementById("zona");
  for (const key of Object.keys(zone)) {
    const opt = document.createElement("option");
    opt.value = zone[key].nome;      // valore = "Casa"
    opt.textContent = zone[key].nome;
    zonaSel.appendChild(opt);
  }

  // -----------------------------
  // AGGIORNA SOTTOZONE
  // -----------------------------
  zonaSel.onchange = () => {
    const z = zonaSel.value; // "Casa", "Est", ecc.
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
    // -----------------------------
    // NUOVA PIANTA
    // -----------------------------
    title.textContent = "Nuova Pianta";

    if (zonaParam) zonaSel.value = zonaParam;
    zonaSel.onchange();

    if (sottoParam) {
      document.getElementById("sottozona").value = sottoParam;
    }
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

      [
        "man-irrig-primavera","man-irrig-estate","man-irrig-autunno","man-irrig-inverno",
        "man-conc-primavera","man-conc-estate","man-conc-autunno","man-conc-inverno",
        "man-pot-primavera","man-pot-estate","man-pot-autunno","man-pot-inverno"
      ].forEach(id => document.getElementById(id).value = "");

    } else {
      title.textContent = "Modifica specie";
      document.getElementById("specie-nome").value = data.nome;
      document.getElementById("specie-specie").value = data.specie;
      document.getElementById("specie-descrizione").value = data.descrizione;
      document.getElementById("specie-luce").value = data.esigenze.luce;
      document.getElementById("specie-acqua").value = data.esigenze.acqua;
      document.getElementById("specie-terreno").value = data.esigenze.terreno;
      document.getElementById("specie-alert").value = data.alert.join("\n");

      const man = data.manutenzione || {
        irrigazione: {}, concimazione: {}, potatura: {}
      };

      document.getElementById("man-irrig-primavera").value = man.irrigazione.primavera || "";
      document.getElementById("man-irrig-estate").value = man.irrigazione.estate || "";
      document.getElementById("man-irrig-autunno").value = man.irrigazione.autunno || "";
      document.getElementById("man-irrig-inverno").value = man.irrigazione.inverno || "";

      document.getElementById("man-conc-primavera").value = man.concimazione.primavera || "";
      document.getElementById("man-conc-estate").value = man.concimazione.estate || "";
      document.getElementById("man-conc-autunno").value = man.concimazione.autunno || "";
      document.getElementById("man-conc-inverno").value = man.concimazione.inverno || "";

      document.getElementById("man-pot-primavera").value = man.potatura.primavera || "";
      document.getElementById("man-pot-estate").value = man.potatura.estate || "";
      document.getElementById("man-pot-autunno").value = man.potatura.autunno || "";
      document.getElementById("man-pot-inverno").value = man.potatura.inverno || "";
    }

    box.style.display = "block";
  }

  document.getElementById("new-specie-btn").onclick = () => {
    openSpecieEditor(null, null);
  };

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

    // Salva specie se editor aperto
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

      const manutenzione = {
        irrigazione: {
          primavera: document.getElementById("man-irrig-primavera").value.trim(),
          estate: document.getElementById("man-irrig-estate").value.trim(),
          autunno: document.getElementById("man-irrig-autunno").value.trim(),
          inverno: document.getElementById("man-irrig-inverno").value.trim()
        },
        concimazione: {
          primavera: document.getElementById("man-conc-primavera").value.trim(),
          estate: document.getElementById("man-conc-estate").value.trim(),
          autunno: document.getElementById("man-conc-autunno").value.trim(),
          inverno: document.getElementById("man-conc-inverno").value.trim()
        },
        potatura: {
          primavera: document.getElementById("man-pot-primavera").value.trim(),
          estate: document.getElementById("man-pot-estate").value.trim(),
          autunno: document.getElementById("man-pot-autunno").value.trim(),
          inverno: document.getElementById("man-pot-inverno").value.trim()
        }
      };

      let key = editingSpecieKey;

      if (!key) {
        key = nome.toLowerCase().replace(/[^a-z0-9]+/g, "-");
        specieSel.value = key;
      }

      specie[key] = {
        nome,
        specie: specieBot,
        descrizione: descr,
        esigenze: { luce, acqua, terreno },
        alert: alertList,
        manutenzione
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
      sottozona: document.getElementById("sottozona").value || "",
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