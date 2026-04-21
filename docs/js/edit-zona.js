// js/edit-zona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

// Rimuove il blocco dei metadati iniziali dal file originale
function stripMetadata(md) {
  const lines = md.split("\n");
  let i = 0;

  // Scorri finché trovi righe nel formato "chiave: valore"
  while (i < lines.length && /^[a-zA-Z0-9_-]+\s*:\s*/.test(lines[i].trim())) {
    i++;
  }

  // Salta eventuali righe vuote dopo i metadati
  while (i < lines.length && lines[i].trim() === "") {
    i++;
  }

  // Ritorna SOLO il contenuto originale
  return lines.slice(i).join("\n");
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
  const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/${path}?t=${Date.now()}`;

  status.textContent = "Caricamento dati...";

  // 1. Carica il file dal repo tramite GitHub API
  let fileData;
  try {
    const fileRes = await fetch(apiUrl, {
      headers: { "Accept": "application/vnd.github.v3+json" }
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

    // Rimuove i vecchi metadati dal file originale
    const contenutoOriginale = stripMetadata(md);

    // Ricostruisce il file SENZA duplicazioni
    const nuovoMd =
      Object.entries(nuovoMeta)
        .map(([k, v]) => `${k}: ${v}`)
        .join("\n") +
      "\n\n" +
      contenutoOriginale;

    try {
      const commitRes = await fetch(
        `https://api.github.com/repos/ziabetta84/giardino/contents/${path}`,
        {
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
        }
      );

      status.textContent = commitRes.ok
        ? "Salvato nel repo ✔️"
        : "Errore nel salvataggio ❌";
    } catch (e) {
      status.textContent = "Errore di rete nel salvataggio.";
    }
  };
});
