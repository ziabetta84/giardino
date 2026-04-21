// js/edit-zona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const token = getParam("token");
  const status = document.getElementById("status");

  if (!token) {
    status.textContent = "Token OAuth mancante.";
    return;
  }

  if (!zona) {
    status.textContent = "Parametro zona mancante.";
    return;
  }

  const path = `zone/${zona}/${zona}.md`;

  status.textContent = "Caricamento dati...";

  // 1. Carica il file dal repo
  const md = await fetch(`https://raw.githubusercontent.com/ziabetta84/giardino/main/${path}`)
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
  document.getElementById("esposizione").value = meta.esposizione || "";

  status.textContent = "";

  // 3. Salvataggio
  document.getElementById("save-btn").onclick = async () => {
    status.textContent = "Salvataggio in corso...";

    const nuovoMeta = {
      ...meta,
      nome: document.getElementById("nome").value.trim(),
      descrizione: document.getElementById("descrizione").value.trim(),
      esposizione: document.getElementById("esposizione").value.trim()
    };

    const nuovoMd = Object.entries(nuovoMeta)
      .map(([k, v]) => `${k}: ${v}`)
      .join("\n");

    // 4. Recupera SHA del file
    const shaRes = await fetch(
      `https://api.github.com/repos/ziabetta84/giardino/contents/${path}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    const shaData = await shaRes.json();

    // 5. Commit
    const commitRes = await fetch(
      `https://api.github.com/repos/ziabetta84/giardino/contents/${path}`,
      {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: `Aggiorna zona ${zona}`,
          content: btoa(unescape(encodeURIComponent(nuovoMd))),
          sha: shaData.sha
        })
      }
    );

    if (commitRes.ok) {
      status.textContent = "Salvato nel repo ✔️";
    } else {
      status.textContent = "Errore nel salvataggio ❌";
    }
  };
});
