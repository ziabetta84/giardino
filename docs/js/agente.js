// docs/js/agente.js
//
// Frontend dell'assistente AI.
//
// L'endpoint sul Worker Cloudflare (cloudflare-worker/agente-worker.js) non è
// al momento utilizzabile: l'account Anthropic collegato è bloccato. In
// attesa di una soluzione, le richieste che servono un modello (valutazione
// salute, identificazione specie, chat libera) non vengono più inviate al
// Worker: vengono invece scritte in coda in docs/data/richieste-agente.json
// e restano "in_attesa". Un'altra sessione (o la stessa, richiamata a mano
// o da una Routine schedulata) le elabora leggendo/scrivendo lo stesso file,
// senza bisogno di alcuna chiave API. Vedi cloudflare-worker/README.md per
// lo schema completo della coda.

function getParam(name) {
  return new URLSearchParams(location.search).get(name);
}

// Limite solo di buon senso sul file originale scelto dall'utente: la foto
// viene comunque ridimensionata/compressa prima dell'invio (vedi
// resizeImageForAgente), quindi le foto scattate da smartphone (spesso 8-15MB)
// non vengono più rifiutate.
const MAX_FOTO_BYTES_ORIGINALE = 25 * 1024 * 1024;
const TRACKED_KEY = "richieste_agente_tracked";

let chatHistory = [];

function appendBubble(role, text) {
  const win = document.getElementById("chat-window");
  const bubble = document.createElement("div");
  bubble.className = `chat-bubble chat-bubble-${role}`;
  bubble.textContent = text;
  win.appendChild(bubble);
  win.scrollTop = win.scrollHeight;
}

// Ridimensiona/comprime la foto lato client prima di inviarla: le foto da
// smartphone spesso superano i 5-15MB, ben oltre i limiti pratici di
// dimensione di un commit. maxDim è più alto di quanto servisse per il
// vecchio Worker (che lo usava per stare sotto un limite di payload
// dell'API a pagamento): ora la foto viene letta direttamente da chi elabora
// la coda, quindi conviene preservare più risoluzione per non penalizzare
// l'identificazione della specie. La qualità JPEG resta invece a 0.85: oltre
// quella soglia il file cresce molto (spesso il doppio) per un guadagno
// visivo quasi impercettibile, e le foto restano comunque nella cronologia
// git anche dopo essere state rimosse dall'ultimo commit.
//
// Usa createImageBitmap invece di <img>.onload: quest'ultimo è un evento DOM
// asincrono che alcuni browser (Firefox in modalità anti-fingerprinting) non
// associano più al click originale, bloccando la lettura del canvas con
// "extracting canvas data because no user input was detected". Con
// createImageBitmap l'intera pipeline resta una singola catena di await
// avviata direttamente dal gestore del click.
async function resizeImageForAgente(file, maxDim = 2048, quality = 0.85) {
  const bitmap = await createImageBitmap(file);

  let { width, height } = bitmap;
  if (width > maxDim || height > maxDim) {
    const scale = maxDim / Math.max(width, height);
    width = Math.round(width * scale);
    height = Math.round(height * scale);
  }

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  canvas.getContext("2d").drawImage(bitmap, 0, 0, width, height);
  bitmap.close();

  return new Promise((resolve, reject) => {
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
  });
}

function stripHtml(html) {
  if (!html) return "";
  const div = document.createElement("div");
  div.innerHTML = html;
  return div.textContent || div.innerText || "";
}

function base64ToBlob(base64, mediaType) {
  const bytes = atob(base64);
  const arr = new Uint8Array(bytes.length);
  for (let i = 0; i < bytes.length; i++) arr[i] = bytes.charCodeAt(i);
  return new Blob([arr], { type: mediaType });
}

// Carica la foto allegata a una richiesta in coda, come file a sé stante
// (non dentro il JSON), così può essere rimossa singolarmente una volta
// elaborata senza toccare lo storico delle richieste.
async function uploadRichiestaImage(path, blob) {
  const token = localStorage.getItem("github_token");
  if (!token) throw new Error("Devi effettuare il login per usare l'assistente.");

  const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/docs/${path}`;

  const base64 = await new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error("Errore nella lettura della foto."));
    reader.onload = () => resolve((reader.result || "").split(",")[1] || "");
    reader.readAsDataURL(blob);
  });

  const res = await fetch(apiUrl, {
    method: "PUT",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ message: "Richiesta agente: allega foto", content: base64 })
  });

  if (!res.ok) throw new Error(`Impossibile caricare la foto (${res.status}).`);
}

function nuovaRichiestaId() {
  return `richiesta-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
}

// Scrive una nuova richiesta in coda in richieste-agente.json. Non chiama
// nessun modello: la richiesta resta "in_attesa" finché qualcuno (io stesso
// su richiesta manuale, o la Routine oraria) non la elabora e riscrive lo
// stesso file con stato "completata"/"errore" e il campo "risposta".
async function creaRichiesta({ tipo, contesto, messaggio, image, speciesName }) {
  const token = localStorage.getItem("github_token");
  if (!token) throw new Error("Devi effettuare il login per usare l'assistente.");

  const id = nuovaRichiestaId();
  let fotoPath = null;

  if (image) {
    fotoPath = `uploads/richieste/${id}.jpg`;
    const blob = base64ToBlob(image.data, image.mediaType || "image/jpeg");
    await uploadRichiestaImage(fotoPath, blob);
  }

  const richieste = await loadJSON("richieste-agente.json");
  if (!richieste) throw new Error("Impossibile leggere la coda delle richieste.");

  richieste[id] = {
    tipo,
    messaggio: messaggio || "",
    contesto: contesto || null,
    speciesName: speciesName || null,
    foto: fotoPath,
    stato: "in_attesa",
    creata: new Date().toISOString(),
    elaborata: null,
    risposta: null
  };

  notifySaving();
  const ok = await saveJSON("richieste-agente.json", richieste);
  if (!ok) throw new Error("Impossibile salvare la richiesta in coda.");

  return id;
}

// -----------------------------
// Tracciamento locale delle richieste inviate da questo browser
// (solo per sapere quali mostrare nel pannello: la coda vera è nel repo)
// -----------------------------
function getTracked() {
  try {
    return JSON.parse(localStorage.getItem(TRACKED_KEY) || "[]");
  } catch {
    return [];
  }
}

function saveTracked(list) {
  localStorage.setItem(TRACKED_KEY, JSON.stringify(list));
}

function trackRichiesta(id, tipo, label) {
  const list = getTracked();
  list.unshift({ id, tipo, label, creata: new Date().toISOString() });
  saveTracked(list);
}

function untrackRichiesta(id) {
  saveTracked(getTracked().filter(r => r.id !== id));
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
  // Pannello "Le mie richieste"
  // -----------------------------
  function statoBadge(stato) {
    if (stato === "completata") return "✅ Completata";
    if (stato === "errore") return "⚠️ Errore";
    return "⏳ In attesa";
  }

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

  async function richiediSchedaPerCandidato(nomeScelto, fotoIdentificaAttuale) {
    try {
      let image;
      if (fotoIdentificaAttuale) {
        image = await resizeImageForAgente(fotoIdentificaAttuale);
      }

      const id = await creaRichiesta({
        tipo: "genera_scheda_specie",
        speciesName: nomeScelto,
        messaggio: `Genera la scheda di cura completa per "${nomeScelto}".`,
        image
      });

      trackRichiesta(id, "genera_scheda_specie", `Scheda per "${nomeScelto}"`);
      await renderRichiestePanel();
    } catch (err) {
      alert(`Errore: ${err.message}`);
    }
  }

  async function renderRichiestePanel() {
    const container = document.getElementById("richieste-lista");
    const tracked = getTracked();

    if (!tracked.length) {
      container.innerHTML = "<p class=\"small\">Nessuna richiesta in corso. Le richieste che invii con l'assistente compariranno qui.</p>";
      return;
    }

    const richieste = await loadJSON("richieste-agente.json") || {};
    container.innerHTML = "";

    tracked.forEach(t => {
      const r = richieste[t.id];
      const box = document.createElement("div");
      box.className = "richiesta-item";

      if (!r) {
        box.innerHTML = `
          <div class="richiesta-header">
            <strong>${t.label}</strong>
            <span class="richiesta-badge">⚠️ Non trovata</span>
          </div>
          <button type="button" class="richiesta-rimuovi">Rimuovi dall'elenco</button>
        `;
        box.querySelector(".richiesta-rimuovi").onclick = () => {
          untrackRichiesta(t.id);
          renderRichiestePanel();
        };
        container.appendChild(box);
        return;
      }

      const header = document.createElement("div");
      header.className = "richiesta-header";
      header.innerHTML = `<strong>${t.label}</strong><span class="richiesta-badge">${statoBadge(r.stato)}</span>`;
      box.appendChild(header);

      if (r.stato === "in_attesa") {
        const p = document.createElement("p");
        p.className = "small";
        p.textContent = "In coda: verrà elaborata entro un'ora circa, o prima se qualcuno controlla manualmente la coda.";
        box.appendChild(p);
      } else if (r.stato === "errore") {
        const p = document.createElement("p");
        p.textContent = `⚠️ ${r.risposta?.messaggio || "Elaborazione non riuscita."}`;
        box.appendChild(p);
      } else if (r.stato === "completata") {
        if (r.tipo === "salute" || r.tipo === "chat") {
          const p = document.createElement("p");
          p.textContent = r.risposta?.testo || "(nessuna risposta)";
          box.appendChild(p);
        } else if (r.tipo === "identifica_specie") {
          const candidati = r.risposta?.candidati || [];

          if (!candidati.length) {
            const p = document.createElement("p");
            p.className = "small";
            p.textContent = "Nessun candidato identificato con sicurezza. Indica tu il nome qui sotto.";
            box.appendChild(p);
          } else {
            candidati.forEach((c, i) => {
              const row = document.createElement("div");
              row.className = "candidato-specie-row";
              row.innerHTML = `
                <strong>${c.nome}</strong>
                <span class="small">(${c.specieBotanica || ""} — confidenza ${c.confidenza || "?"})</span>
                ${c.note ? `<div class="small">${c.note}</div>` : ""}
              `;
              const btn = document.createElement("button");
              btn.type = "button";
              btn.textContent = (i === 0 && r.risposta?.schedaTop) ? "Usa la bozza già pronta" : "Genera scheda per questa";
              btn.onclick = () => {
                if (i === 0 && r.risposta?.schedaTop) {
                  popolaFormSpecie(r.risposta.schedaTop, c.nome);
                } else {
                  richiediSchedaPerCandidato(c.nome, window.__fotoIdentificaAttuale || null);
                }
              };
              row.appendChild(btn);
              box.appendChild(row);
            });
          }

          const manualRow = document.createElement("div");
          manualRow.className = "identifica-manuale-row";
          manualRow.innerHTML = `<input type="text" placeholder="Non è tra questi? indica tu il nome">`;
          const manualBtn = document.createElement("button");
          manualBtn.type = "button";
          manualBtn.textContent = "Usa questo nome";
          manualRow.appendChild(manualBtn);
          box.appendChild(manualRow);

          manualBtn.onclick = () => {
            const nome = manualRow.querySelector("input").value.trim();
            if (!nome) {
              alert("Indica un nome.");
              return;
            }
            richiediSchedaPerCandidato(nome, window.__fotoIdentificaAttuale || null);
          };
        } else if (r.tipo === "genera_scheda_specie") {
          const btn = document.createElement("button");
          btn.type = "button";
          btn.className = "save-btn";
          btn.textContent = "Usa questa bozza";
          btn.onclick = () => popolaFormSpecie(r.risposta?.scheda, r.speciesName);
          box.appendChild(btn);
        }
      }

      const rimBtn = document.createElement("button");
      rimBtn.type = "button";
      rimBtn.className = "richiesta-rimuovi";
      rimBtn.textContent = "Rimuovi dall'elenco";
      rimBtn.onclick = () => {
        untrackRichiesta(t.id);
        renderRichiestePanel();
      };
      box.appendChild(rimBtn);

      container.appendChild(box);
    });
  }

  document.getElementById("richieste-refresh").onclick = () => renderRichiestePanel();
  await renderRichiestePanel();

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
  wireUploadPreview("identifica-foto-input", "identifica-foto-preview", file => {
    fotoIdentifica = file;
    window.__fotoIdentificaAttuale = file;
  });

  // -----------------------------
  // Azione rapida: Cosa fare oggi (nessuna chiamata LLM, resta istantanea)
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
  // Azione: Valuta salute pianta (con foto) — messa in coda
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
      const image = await resizeImageForAgente(fotoFile);

      btn.textContent = "Metto in coda...";

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

      const richiestaId = await creaRichiesta({
        tipo: "salute",
        messaggio: "Valuta lo stato di salute di questa pianta a partire dalla foto allegata, tenendo conto del contesto fornito.",
        contesto,
        image
      });

      trackRichiesta(richiestaId, "salute", `Salute: ${specie?.nome || p.specie}`);
      await renderRichiestePanel();

      appendBubble("assistant", "📥 Richiesta inviata e in coda. Trovi l'esito nel pannello \"Le mie richieste\" qui sotto (di solito entro un'ora).");
    } catch (err) {
      appendBubble("assistant", `⚠️ ${err.message}`);
    } finally {
      btn.disabled = false;
      btn.textContent = "Invia per la valutazione";
    }
  };

  // -----------------------------
  // Azione: Identifica nuova specie da foto — messa in coda
  // -----------------------------
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
      btn.textContent = "Metto in coda...";

      const specieEsistenti = Object.values(specieData || {}).map(s => s.nome);

      const richiestaId = await creaRichiesta({
        tipo: "identifica_specie",
        messaggio: "Identifica questa pianta dalla foto allegata e proponi una bozza di scheda per il candidato più probabile.",
        contesto: { specieEsistenti },
        image
      });

      trackRichiesta(richiestaId, "identifica_specie", "Identificazione da foto");
      await renderRichiestePanel();

      appendBubble("assistant", "📥 Richiesta inviata e in coda. Trovi i candidati nel pannello \"Le mie richieste\" qui sotto (di solito entro un'ora).");
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
  // Chat libera — messa in coda
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

      const richiestaId = await creaRichiesta({ tipo: "chat", messaggio: message, contesto });
      trackRichiesta(richiestaId, "chat", `Chat: "${message.slice(0, 40)}${message.length > 40 ? "…" : ""}"`);
      await renderRichiestePanel();

      appendBubble("assistant", "📥 Messaggio inviato e in coda. Trovi la risposta nel pannello \"Le mie richieste\" qui sotto (di solito entro un'ora).");
    } catch (err) {
      appendBubble("assistant", `⚠️ ${err.message}`);
    }
  };
});
