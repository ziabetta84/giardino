// docs/js/agente.js
//
// Frontend dell'assistente AI. Il modello vero e proprio gira dietro un
// endpoint sul Worker Cloudflare già usato per il login (la chiave API resta
// lato server, vedi cloudflare-worker/agente-worker.js per il riferimento
// da distribuire manualmente).

function getParam(name) {
  return new URLSearchParams(location.search).get(name);
}

const WORKER_CHAT_URL = "https://giardino.robertagenovese.workers.dev/agente/chat";
// Limite solo di buon senso sul file originale scelto dall'utente: la foto
// viene comunque ridimensionata/compressa prima dell'invio (vedi
// resizeImageForAgente), quindi le foto scattate da smartphone (spesso 8-15MB)
// non vengono più rifiutate.
const MAX_FOTO_BYTES_ORIGINALE = 25 * 1024 * 1024;

let chatHistory = [];

function appendBubble(role, text) {
  const win = document.getElementById("chat-window");
  const bubble = document.createElement("div");
  bubble.className = `chat-bubble chat-bubble-${role}`;
  bubble.textContent = text;
  win.appendChild(bubble);
  win.scrollTop = win.scrollHeight;
}

// Ridimensiona/comprime la foto lato client prima di inviarla al Worker:
// le foto da smartphone spesso superano i 5-15MB, ben oltre quanto serve
// per l'analisi visiva (Claude ridimensiona comunque le immagini oltre
// ~1568px sul lato lungo) e oltre i limiti pratici di dimensione richiesta.
function resizeImageForAgente(file, maxDim = 1568, quality = 0.85) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const objectUrl = URL.createObjectURL(file);

    img.onload = () => {
      URL.revokeObjectURL(objectUrl);

      let { width, height } = img;
      if (width > maxDim || height > maxDim) {
        const scale = maxDim / Math.max(width, height);
        width = Math.round(width * scale);
        height = Math.round(height * scale);
      }

      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      canvas.getContext("2d").drawImage(img, 0, 0, width, height);

      canvas.toBlob(blob => {
        if (!blob) {
          reject(new Error("Impossibile comprimere la foto."));
          return;
        }
        const reader = new FileReader();
        reader.onerror = () => reject(new Error("Errore nella lettura della foto compressa."));
        reader.onload = () => resolve({
          mediaType: "image/jpeg",
          data: (reader.result || "").split(",")[1] || ""
        });
        reader.readAsDataURL(blob);
      }, "image/jpeg", quality);
    };

    img.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      reject(new Error("Impossibile leggere la foto selezionata."));
    };

    img.src = objectUrl;
  });
}

function stripHtml(html) {
  if (!html) return "";
  const div = document.createElement("div");
  div.innerHTML = html;
  return div.textContent || div.innerText || "";
}

async function inviaAlWorker({ message, context, image }) {
  const token = localStorage.getItem("github_token");
  if (!token) throw new Error("Devi effettuare il login per usare l'assistente.");

  const body = { message, context, history: chatHistory };
  if (image) body.image = image;

  let res;
  try {
    res = await fetch(WORKER_CHAT_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    });
  } catch (e) {
    throw new Error("Worker non raggiungibile: verifica che l'endpoint /agente/chat sia stato distribuito.");
  }

  if (!res.ok) {
    throw new Error(`Il Worker ha risposto con errore (${res.status}).`);
  }

  const data = await res.json();
  if (!data.reply) throw new Error("Risposta non valida dal Worker.");

  chatHistory.push({ role: "user", content: message });
  chatHistory.push({ role: "assistant", content: data.reply });

  return data.reply;
}

// Variante per le azioni a risposta strutturata (identificazione specie,
// generazione scheda): non tocca chatHistory, ritorna il body JSON intero
// così il chiamante legge il campo che gli serve (candidati / scheda).
async function chiamaWorkerStrutturato({ action, message, context, image, speciesName }) {
  const token = localStorage.getItem("github_token");
  if (!token) throw new Error("Devi effettuare il login per usare l'assistente.");

  let res;
  try {
    res = await fetch(WORKER_CHAT_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ action, message, context, image, speciesName })
    });
  } catch (e) {
    throw new Error("Worker non raggiungibile: verifica che l'endpoint /agente/chat sia stato distribuito.");
  }

  const data = await res.json().catch(() => ({}));

  if (!res.ok) {
    throw new Error(data.error || `Il Worker ha risposto con errore (${res.status}).`);
  }

  return data;
}

// Gestisce anteprima + validazione di un input file, richiamando onChange(file|null).
function wireUploadPreview(inputId, previewId, onChange) {
  document.getElementById(inputId).onchange = (e) => {
    const file = e.target.files[0];
    const preview = document.getElementById(previewId);

    if (!file) {
      preview.innerHTML = "";
      onChange(null);
      return;
    }

    if (file.size > MAX_FOTO_BYTES_ORIGINALE) {
      alert("La foto è troppo grande (limite 25MB).");
      e.target.value = "";
      preview.innerHTML = "";
      onChange(null);
      return;
    }

    preview.innerHTML = `<img src="${URL.createObjectURL(file)}" class="salute-foto-thumb">`;
    onChange(file);
  };
}

document.addEventListener("DOMContentLoaded", async () => {
  const piantaParam = getParam("pianta");
  const azioneParam = getParam("azione");

  const [piante, specieData, zone, sottozone] = await Promise.all([
    loadJSON("piante.json"),
    loadJSON("specie.json"),
    loadJSON("zone.json"),
    loadJSON("sottozone.json")
  ]);

  // -----------------------------
  // Selettore pianta (per la valutazione salute)
  // -----------------------------
  const selettore = document.getElementById("salute-pianta-select");
  const pianteKeys = Object.keys(piante || {}).sort((a, b) => {
    const nomeA = specieData?.[piante[a].specie]?.nome || piante[a].specie || "";
    const nomeB = specieData?.[piante[b].specie]?.nome || piante[b].specie || "";
    return nomeA.localeCompare(nomeB);
  });

  pianteKeys.forEach(id => {
    const p = piante[id];
    const opt = document.createElement("option");
    opt.value = id;
    opt.textContent = `${specieData?.[p.specie]?.nome || p.specie} (${p.zona || "?"})`;
    selettore.appendChild(opt);
  });

  if (piantaParam && piante?.[piantaParam]) {
    selettore.value = piantaParam;
  }

  const salutePanel = document.getElementById("salute-panel");

  document.getElementById("azione-salute").onclick = () => {
    salutePanel.style.display = salutePanel.style.display === "none" ? "block" : "none";
  };

  if (azioneParam === "salute") {
    salutePanel.style.display = "block";
  }

  const identificaPanel = document.getElementById("identifica-panel");

  document.getElementById("azione-identifica").onclick = () => {
    identificaPanel.style.display = identificaPanel.style.display === "none" ? "block" : "none";
  };

  // -----------------------------
  // Anteprima foto
  // -----------------------------
  let fotoFile = null;
  wireUploadPreview("salute-foto-input", "salute-foto-preview", file => { fotoFile = file; });

  let fotoIdentifica = null;
  wireUploadPreview("identifica-foto-input", "identifica-foto-preview", file => { fotoIdentifica = file; });

  // -----------------------------
  // Azione rapida: Cosa fare oggi (nessuna chiamata LLM)
  // -----------------------------
  document.getElementById("azione-oggi").onclick = async () => {
    appendBubble("user", "Cosa fare oggi?");

    const settings = await loadJSON("settings.json");
    let meteo = null;
    if (settings?.location) {
      meteo = await fetchMeteoPerRegole(settings.location.lat, settings.location.lon);
    }

    const righe = [];
    for (const id of Object.keys(piante || {})) {
      const p = piante[id];
      const specie = specieData?.[p.specie];
      if (!specie) continue;
      const zonaInfo = zone?.[p.zona];

      ["irrigazione", "concimazione"].forEach(tipo => {
        const esito = valutaCura(p, specie, zonaInfo, meteo, tipo);
        if (esito.daFare) {
          righe.push(`${tipo === "irrigazione" ? "💧" : "🌱"} ${specie.nome || p.specie} (${p.zona}): ${tipo}`);
        }
      });

      const pot = valutaPotatura(specie);
      if (pot.priorita > 0) {
        righe.push(`✂️ ${specie.nome || p.specie} (${p.zona}): potatura (${pot.priorita === 1 ? "priorità alta" : "priorità normale"})`);
      }
    }

    appendBubble("assistant", righe.length
      ? `Ecco le attività da svolgere oggi:\n${righe.join("\n")}`
      : "Nessuna attività da svolgere oggi. 🎉");
  };

  // -----------------------------
  // Azione: Valuta salute pianta (con foto, chiamata LLM multimodale)
  // -----------------------------
  document.getElementById("salute-invia").onclick = async () => {
    const id = selettore.value;

    if (!id || !piante?.[id]) {
      alert("Seleziona una pianta.");
      return;
    }
    if (!fotoFile) {
      alert("Allega una foto della pianta.");
      return;
    }

    const p = piante[id];
    const specie = specieData?.[p.specie];
    const zonaInfo = zone?.[p.zona];
    const sottozonaInfo = p.sottozona ? sottozone?.[p.zona]?.[p.sottozona] : null;

    appendBubble("user", `🩺 Valuta lo stato di salute di ${specie?.nome || p.specie} (${p.zona}) dalla foto allegata.`);

    const contesto = {
      pianta: {
        nome: specie?.nome || p.specie,
        specieBotanica: specie?.specie,
        varieta: p.varieta,
        note: p.note,
        ultimaCura: p.ultima_cura || {}
      },
      zona: zonaInfo ? {
        nome: zonaInfo.nome,
        esposizione: zonaInfo.esposizione,
        microclima: stripHtml(zonaInfo.microclima),
        criticita: stripHtml(zonaInfo.criticita)
      } : null,
      sottozona: sottozonaInfo ? { nome: sottozonaInfo.nome } : null,
      esigenze: specie?.esigenze || null,
      manutenzione: specie?.manutenzione || null,
      alertNoti: specie?.alert || []
    };

    const btn = document.getElementById("salute-invia");
    btn.disabled = true;
    btn.textContent = "Comprimo la foto...";

    try {
      const { mediaType, data: base64 } = await resizeImageForAgente(fotoFile);

      btn.textContent = "Invio in corso...";

      if (document.getElementById("salute-salva-galleria").checked) {
        const token = localStorage.getItem("github_token");
        if (!token) {
          alert("Devi effettuare il login per salvare la foto in galleria.");
        } else {
          const safeName = fotoFile.name.replace(/\s+/g, "_");
          const filename = `${Date.now()}_${safeName}`;
          const path = `gallery/piante/${id}/${filename}`;
          const okUpload = await uploadFoto(path, fotoFile);
          if (okUpload) {
            piante[id].foto = piante[id].foto || [];
            piante[id].foto.push({ filename, date: new Date().toISOString() });
            await saveJSON("piante.json", piante);
          }
        }
      }

      const reply = await inviaAlWorker({
        message: "Valuta lo stato di salute di questa pianta a partire dalla foto allegata, tenendo conto del contesto fornito.",
        context: contesto,
        image: { mediaType, data: base64 }
      });

      appendBubble("assistant", reply);
    } catch (err) {
      appendBubble("assistant", `⚠️ ${err.message}`);
    } finally {
      btn.disabled = false;
      btn.textContent = "Invia per la valutazione";
    }
  };

  // -----------------------------
  // Azione: Identifica nuova specie da foto (identificazione + scheda)
  // -----------------------------
  function popolaFormSpecie(scheda, nomeFallback) {
    const s = scheda || {};
    document.getElementById("specie-nome").value = s.nome || nomeFallback || "";
    document.getElementById("specie-specie").value = s.specie || "";
    document.getElementById("specie-descrizione").value = s.descrizione || "";
    document.getElementById("specie-luce").value = s.esigenze?.luce || "";
    document.getElementById("specie-acqua").value = s.esigenze?.acqua || "";
    document.getElementById("specie-terreno").value = s.esigenze?.terreno || "";
    document.getElementById("specie-alert").value = (s.alert || []).join("\n");

    const m = s.manutenzione || {};
    [
      ["irrigazione", "man-irrig"],
      ["concimazione", "man-conc"],
      ["potatura", "man-pot"]
    ].forEach(([tipo, prefix]) => {
      ["primavera", "estate", "autunno", "inverno"].forEach(stagione => {
        document.getElementById(`${prefix}-${stagione}`).value = m[tipo]?.[stagione] || "";
      });
    });

    const form = document.getElementById("specie-editor");
    form.style.display = "block";
    form.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  async function confermaSpecieScelta(nomeScelto) {
    appendBubble("user", `🔍 Prepara la scheda per: ${nomeScelto}`);

    try {
      let image;
      if (fotoIdentifica) {
        image = await resizeImageForAgente(fotoIdentifica);
      }

      const result = await chiamaWorkerStrutturato({
        action: "genera_scheda_specie",
        speciesName: nomeScelto,
        message: `Genera la scheda di cura completa per "${nomeScelto}".`,
        image
      });

      popolaFormSpecie(result.scheda, nomeScelto);
      appendBubble("assistant", `Ho preparato una bozza di scheda per "${nomeScelto}". Controllala e modificala prima di salvare.`);
    } catch (err) {
      appendBubble("assistant", `⚠️ ${err.message}`);
    }
  }

  function renderCandidati(candidati) {
    const container = document.getElementById("identifica-candidati");

    container.innerHTML = candidati.length
      ? candidati.map((c, i) => `
          <label class="candidato-specie-row">
            <input type="radio" name="candidato-specie" value="${i}">
            <strong>${c.nome}</strong>
            <span class="small">(${c.specieBotanica || ""} — confidenza ${c.confidenza || "?"})</span>
            ${c.note ? `<div class="small">${c.note}</div>` : ""}
          </label>
        `).join("")
      : "<p>Nessun candidato identificato con sicurezza. Indica tu il nome qui sotto.</p>";

    container.querySelectorAll('input[name="candidato-specie"]').forEach((radio, i) => {
      radio.onchange = () => confermaSpecieScelta(candidati[i].nome);
    });

    document.getElementById("identifica-manuale").style.display = "block";
  }

  document.getElementById("identifica-conferma-manuale").onclick = () => {
    const nome = document.getElementById("identifica-nome-manuale").value.trim();
    if (!nome) {
      alert("Indica un nome.");
      return;
    }
    confermaSpecieScelta(nome);
  };

  document.getElementById("identifica-invia").onclick = async () => {
    if (!fotoIdentifica) {
      alert("Allega una foto della pianta da identificare.");
      return;
    }

    appendBubble("user", "🔍 Identifica questa pianta dalla foto allegata.");

    const btn = document.getElementById("identifica-invia");
    btn.disabled = true;
    btn.textContent = "Comprimo la foto...";

    try {
      const image = await resizeImageForAgente(fotoIdentifica);
      btn.textContent = "Identificazione in corso...";

      const specieEsistenti = Object.values(specieData || {}).map(s => s.nome);

      const result = await chiamaWorkerStrutturato({
        action: "identifica_specie",
        message: "Identifica questa pianta dalla foto allegata.",
        context: { specieEsistenti },
        image
      });

      const candidati = result.candidati || [];
      renderCandidati(candidati);

      appendBubble("assistant", candidati.length
        ? `Ecco le specie candidate:\n${candidati.map(c => `- ${c.nome} (${c.specieBotanica || "?"})`).join("\n")}`
        : "Non sono riuscito a identificare la specie con sicurezza. Indica tu il nome qui sotto.");
    } catch (err) {
      appendBubble("assistant", `⚠️ ${err.message}`);
    } finally {
      btn.disabled = false;
      btn.textContent = "Identifica";
    }
  };

  document.getElementById("salva-specie-btn").onclick = async () => {
    const nome = document.getElementById("specie-nome").value.trim();
    if (!nome) {
      alert("Il nome della specie è obbligatorio.");
      return;
    }

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

    const nuovaSpecie = {
      nome,
      specie: document.getElementById("specie-specie").value.trim(),
      descrizione: document.getElementById("specie-descrizione").value.trim(),
      esigenze: {
        luce: document.getElementById("specie-luce").value.trim(),
        acqua: document.getElementById("specie-acqua").value.trim(),
        terreno: document.getElementById("specie-terreno").value.trim()
      },
      alert: document.getElementById("specie-alert").value.split("\n").map(s => s.trim()).filter(Boolean),
      manutenzione
    };

    const slug = nome.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-+|-+$)/g, "");

    const btn = document.getElementById("salva-specie-btn");
    btn.disabled = true;
    btn.textContent = "Salvataggio...";

    try {
      const specieAggiornate = await loadJSON("specie.json");
      if (!specieAggiornate) throw new Error("Impossibile leggere il database specie.");

      if (specieAggiornate[slug] && !confirm(`Esiste già una specie "${specieAggiornate[slug].nome}" con questo nome. Sovrascriverla?`)) {
        return;
      }

      specieAggiornate[slug] = nuovaSpecie;
      notifySaving();
      const ok = await saveJSON("specie.json", specieAggiornate);
      if (!ok) throw new Error("Salvataggio non riuscito. Controlla di essere ancora loggato e riprova.");

      specieData[slug] = nuovaSpecie;
      appendBubble("assistant", `✅ Specie "${nome}" salvata nel database.`);
      document.getElementById("specie-editor").style.display = "none";
    } catch (err) {
      alert(`Errore: ${err.message}`);
    } finally {
      btn.disabled = false;
      btn.textContent = "💾 Salva nel database specie";
    }
  };

  // -----------------------------
  // Chat libera
  // -----------------------------
  document.getElementById("chat-form").onsubmit = async (e) => {
    e.preventDefault();

    const input = document.getElementById("chat-input");
    const message = input.value.trim();
    if (!message) return;

    appendBubble("user", message);
    input.value = "";

    try {
      const settings = await loadJSON("settings.json");
      let meteo = null;
      if (settings?.location) {
        meteo = await fetchMeteoPerRegole(settings.location.lat, settings.location.lon);
      }

      const progetti = await loadJSON("progetti.json");
      const contesto = {
        numeroPiante: Object.keys(piante || {}).length,
        zone: Object.keys(zone || {}),
        progettiAttivi: Object.values(progetti || {}).filter(p => p.stato === "in_corso").map(p => p.nome),
        meteo
      };

      const reply = await inviaAlWorker({ message, context: contesto });
      appendBubble("assistant", reply);
    } catch (err) {
      appendBubble("assistant", `⚠️ ${err.message}`);
    }
  };
});
