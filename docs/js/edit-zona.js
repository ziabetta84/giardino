// js/edit-zona.js

function getParam(name) {
  const params = new URLSearchParams(location.search);
  return params.get(name);
}

// Estrae il frontmatter YAML (tra --- e ---)
function extractFrontmatter(md) {
  const match = md.match(/^---\s*([\s\S]*?)\s*---/);
  return match ? match[1] : null;
}

// Rimuove il frontmatter e restituisce il contenuto sotto
function stripFrontmatter(md) {
  return md.replace(/^---[\s\S]*?---/, "").trim();
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

  let fileData;
  try {
    const headers = { "Accept": "application/vnd.github.v3+json" };
    if (token) headers["Authorization"] = `Bearer ${token}`;

    const fileRes = await fetch(apiUrl, { headers });

    if (!fileRes.ok) {
      status.textContent = "Impossibile caricare il file della zona.";
      return;
    }

    fileData = await fileRes.json();
  } catch (e) {
    status.textContent = "Errore di rete nel caricamento del file.";
    return;
  }

  // Decodifica UTF‑8 corretta
  const md = new TextDecoder("utf-8").decode(
    Uint8Array.from(atob(fileData.content), c => c.charCodeAt(0))
  );

  // Estrai YAML
  const fm = extractFrontmatter(md);
  let meta = {};
  if (fm) meta = jsyaml.load(fm);

  // Popola il form
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

  // Salvataggio
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

    // Ricostruisci YAML frontmatter
    const nuovoYaml = jsyaml.dump(nuovoMeta);

    const nuovoMd = `---\n${nuovoYaml}---\n`;

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
