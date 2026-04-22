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

  // Popola specie
  const specieSel = document.getElementById("specie");
  for (const key of Object.keys(specie)) {
    const opt = document.createElement("option");
    opt.value = key;
    opt.textContent = specie[key].nome;
    specieSel.appendChild(opt);
  }

  // Popola zone
  const zonaSel = document.getElementById("zona");
  for (const key of Object.keys(zone)) {
    const opt = document.createElement("option");
    opt.value = key;
    opt.textContent = zone[key].nome;
    zonaSel.appendChild(opt);
  }

  // Aggiorna sottozone quando cambia zona
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

  // Se stiamo modificando una pianta
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

  // Salvataggio
  form.onsubmit = async (e) => {
    e.preventDefault();

    const data = {
      specie: specieSel.value,
      zona: zonaSel.value,
      sottozona: document.getElementById("sottozona").value || null,
      varieta: document.getElementById("varieta").value.trim(),
      impianto: document.getElementById("impianto").value,
      note: document.getElementById("note").value.trim()
    };

    let newId = id;

    if (!id) {
      newId = `${data.specie}-${Date.now()}`;
    }

    piante[newId] = data;

    const ok = await saveJSON("piante.json", piante);

    if (ok) {
      alert("Pianta salvata.");
      window.location.href = `piante.html?zona=${data.zona}${data.sottozona ? "&sottozona=" + data.sottozona : ""}`;
    }
  };
});
