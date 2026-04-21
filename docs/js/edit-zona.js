// js/edit-zona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const token = getParam("token");
  const status = document.getElementById("status");

  if (token) {
    localStorage.setItem("github_token", token);
  }

  if (!zona) {
    status.textContent = "Parametro zona mancante.";
    return;
  }

  const path = `zone/${zona}/${zona}.md`;

  status.textContent = "Caricamento dati...";

  // 1. Carica il file dal repo SENZA CACHE
  const md = await fetch(
    `https://raw.githubusercontent.com/ziabetta84/giardino/main/${path}?t=${Date.now()}`,
    { cache: "no-store" }
  )
    .then(r => r.text())
    .catch(() => null);

  if (!md) {
    status.textContent = "Impossibile caricare il file della zona.";
    return;
  }

  const meta = parseMetadata(md);

  // 2. Popola il form
  document.getElementById("nome").value = meta.nome || zona;
  document.getElementById("descrizione").value = meta.descrizione || "";

  // esposizione → array
  if (meta.esposizione) {
    const values = meta.esposizione.split(",").map(v => v.trim().toLowerCase());
    const select = document.getElementById("esposizione");
    for (const opt of select.options) {
      if (values.includes(opt.value)) opt.selected = true;
    }
  }

  // MULTILINEA: ora funziona
  document.getElementById("microclima").value = meta.microclima || "";
  document.getElementById("manutenzione").value = meta.manutenzione || "";

  status.textContent = "";

  // 3. Salvataggio
  document.getElementById("save-btn").onclick = async () => {
    status.textContent = "Salvataggio in corso...";

    const esposizioneSel = Array.from(document.getElementById("esposizione").selectedOptions)
      .map(o => o.value)
      .join(", ");

    const nuovoMeta = {
      nome: document.getElementById("nome").value.trim(),
      descrizione: document.getElementById("descrizione").value.trim(),
      esposizione: esposizioneSel,
      microclima: document.getElementById("microclima").value.trim(),
      manutenzione: document.getElementById("manutenzione").value.trim()
    };

    // Ricostruzione del file .md
    const nuovoMd =
      Object.entries(nuovoMeta)
        .map(([k, v]) => `${k}: ${v}`)
        .join("\n") +
      "\n\n" +
      md; // manteniamo il contenuto originale sotto

    // 4. Recupera SHA del file
    const shaRes = await fetch(
      `https://api.github.com/repos/ziabetta84/giardino/contents/${path}`,
      {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("github_token")}`
        }
      }
    );
    const shaData = await shaRes.json();

    // 5. Commit
    const commitRes = await fetch(
      `https://api.github.com/repos/ziabetta84/giardino/contents/${path}`,
      {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${localStorage.getItem("github_token")}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: `Aggiorna zona ${zona}`,
          content: btoa(unescape(encodeURIComponent(nuovoMd))),
          sha: shaData.sha
        })
      }
    );

    status.textContent = commitRes.ok
      ? "Salvato nel repo ✔️"
      : "Errore nel salvataggio ❌";
  };
});
