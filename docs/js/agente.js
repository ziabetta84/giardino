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
const MAX_FOTO_BYTES = 5 * 1024 * 1024;

let chatHistory = [];

function appendBubble(role, text) {
  const win = document.getElementById("chat-window");
  const bubble = document.createElement("div");
  bubble.className = `chat-bubble chat-bubble-${role}`;
  bubble.textContent = text;
  win.appendChild(bubble);
  win.scrollTop = win.scrollHeight;
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

  // -----------------------------
  // Anteprima foto
  // -----------------------------
  let fotoFile = null;

  document.getElementById("salute-foto-input").onchange = (e) => {
    const file = e.target.files[0];
    const preview = document.getElementById("salute-foto-preview");

    if (!file) {
      preview.innerHTML = "";
      fotoFile = null;
      return;
    }

    if (file.size > MAX_FOTO_BYTES) {
      alert("La foto è troppo grande (limite 5MB).");
      e.target.value = "";
      preview.innerHTML = "";
      fotoFile = null;
      return;
    }

    fotoFile = file;
    preview.innerHTML = `<img src="${URL.createObjectURL(file)}" class="salute-foto-thumb">`;
  };

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
    btn.textContent = "Invio in corso...";

    try {
      const base64 = await new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onerror = () => reject(new Error("Errore nella lettura della foto."));
        reader.onload = () => resolve((reader.result || "").split(",")[1] || "");
        reader.readAsDataURL(fotoFile);
      });

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
        image: { mediaType: fotoFile.type, data: base64 }
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
