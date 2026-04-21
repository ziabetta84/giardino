// js/edit-zona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

document.addEventListener("DOMContentLoaded", async () => {
  const zona = getParam("zona");
  const tokenFromUrl = getParam("token");
  const status = document.getElementById("status");

  if (tokenFromUrl) {
    localStorage.setItem("github_token", tokenFromUrl);
  }
  const token = localStorage.getItem("github_token");

  if (!zona) {
    status.textContent = "Parametro zona mancante.";
    return;
  }

  const path = `zone/${zona}/${zona}.md`;
  const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/${path}`;

  status.textContent = "Caricamento dati...";

  // 1. Carica il file dal repo tramite GitHub API (CORS OK)
  let fileData;
  try {
    const fileRes = await fetch(apiUrl, {
      headers: {
        "Accept": "application/vnd.github.v3+json",
        "Cache-Control": "no-cache"
      }
    });

    if (!fileRes.ok) {
      status.textContent = "Impossibile caricare il file della zona.";
      return;
    }

    fileData = await fileRes.json();
  } catch (e) {
    status.textContent = "Errore di rete nel caricamento del file.";
    return;
  }

  // Decodifica base64 → testo markdown
  const md = decodeURIComponent(escape(atob(fileData.content.replace(/\n/g, ""))));
  const meta = parseMetadata(md);

  // 2. Popola il form
  document.getElementById("nome").value = meta.nome || zona;
  document.getElementById("descrizione").value = meta.descrizione || "";

  if (meta.esposizione) {
    const values = meta.esposizione.split(",").map(v => v.trim().toLowerCase());
    const select = document.getElementById("esposizione");
    for (const opt of select.options) {
      if (values.includes(opt.value)) opt.selected = true;
    }
  }

  document.getElementById("microclima").value = meta.microclima || "";
  document.getElementById("manutenzione").value = meta.manutenzione || "";

  status.textContent = "";

  // 3. Salvataggio
  document.getElementById("save-btn").onclick = async () => {
    if (!token) {
      status.textContent = "Token mancante: effettua di nuovo il login.";
      return;
    }

    status.textContent = "Salvataggio in corso...";

    const esposizioneSel = Array.from(
      document.getElementById("esposizione").selectedOptions
    )
      .map(o => o.value)
      .join(", ");

    const nuovoMeta = {
      nome: document.getElementById("nome").value.trim(),
      descrizione: document.getElementById("descrizione").value.trim(),
      esposizione: esposizioneSel,
      microclima: document.getElementById("microclima").value.trim(),
      manutenzione: document.getElementById("manutenzione").value.trim()
    };

    const nuovoMd =
      Object.entries(nuovoMeta)
        .map(([k, v]) => `${k}: ${v}`)
        .join("\n") +
      "\n\n" +
      md;

    try {
      const commitRes = await fetch(apiUrl, {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
          "Accept": "application/vnd.github.v3+json"
        },
        body: JSON.stringify({
          message: `Aggiorna zona ${zona}`,
          content: btoa(unescape(encodeURIComponent(nuovoMd))),
          sha: fileData.sha
        })
      });

      status.textContent = commitRes.ok
        ? "Salvato nel repo ✔️"
        : "Errore nel salvataggio ❌";
    } catch (e) {
      status.textContent = "Errore di rete nel salvataggio.";
    }
  };
});
