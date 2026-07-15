// cloudflare-worker/agente-worker.js
//
// Riferimento per l'endpoint POST /agente/chat da aggiungere al Worker
// Cloudflare esistente (quello che oggi gestisce già /login su
// giardino.robertagenovese.workers.dev). Questo file NON viene deployato
// automaticamente: il codice del Worker vero non è in questo repository.
// Vedi README.md in questa cartella per i passi di deploy manuale.
//
// Contratto atteso dal frontend (docs/js/agente.js):
//   POST /agente/chat
//   Authorization: Bearer <github_token>
//   Body: { action?, message, context, history, image?, speciesName? }
//
//   action "chat" (default, anche per la valutazione salute pianta):
//     Body: { message, context, history, image? }
//     Risposta: { reply: string }
//
//   action "identifica_specie" (identificazione da foto, passo 1):
//     Body: { action: "identifica_specie", message, context: { specieEsistenti }, image }
//     Risposta: { candidati: [{ nome, specieBotanica, confidenza, note }] }
//
//   action "genera_scheda_specie" (passo 2, dopo scelta/conferma utente):
//     Body: { action: "genera_scheda_specie", speciesName, image? }
//     Risposta: { scheda: { nome, specie, descrizione, esigenze, alert, manutenzione } }
//     (stesso schema di un record in docs/data/specie.json)

const ANTHROPIC_MODEL = "claude-sonnet-5";
const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

// Dominio da cui è servita la webapp (GitHub Pages). Aggiorna se usi un dominio custom.
const ALLOWED_ORIGIN = "https://ziabetta84.github.io";

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type"
  };
}

function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() }
  });
}

// Verifica che il token GitHub sia valido, così solo chi può già autenticarsi
// nella webapp può generare chiamate a pagamento verso Anthropic.
async function validaTokenGitHub(token, env) {
  const res = await fetch("https://api.github.com/user", {
    headers: {
      "Authorization": `Bearer ${token}`,
      "Accept": "application/vnd.github.v3+json",
      "User-Agent": "giardino-agente-worker"
    }
  });

  if (!res.ok) return false;

  // Opzionale: limita l'uso al solo proprietario del repo, se configurato.
  if (env.ALLOWED_GITHUB_LOGIN) {
    const user = await res.json();
    return user.login === env.ALLOWED_GITHUB_LOGIN;
  }

  return true;
}

// ------------------------------------------------------------------
// Chat generica / valutazione salute pianta (risposta testuale libera)
// ------------------------------------------------------------------

function buildAnthropicMessages(history, message, image) {
  const messages = (history || []).map(h => ({ role: h.role, content: h.content }));

  const content = [{ type: "text", text: message }];
  if (image?.data && image?.mediaType) {
    content.unshift({
      type: "image",
      source: { type: "base64", media_type: image.mediaType, data: image.data }
    });
  }

  messages.push({ role: "user", content });
  return messages;
}

function buildSystemPrompt(context) {
  return [
    "Sei l'assistente del 'Giardino di Zorba', un giardino domestico documentato in una webapp.",
    "Rispondi in italiano, in modo pratico e conciso, basandoti sul contesto JSON fornito qui sotto.",
    "Se il contesto include una foto di una pianta, valutane lo stato di salute tenendo conto di zona, esposizione, microclima ed esigenze indicate.",
    "Contesto:",
    JSON.stringify(context ?? {}, null, 2)
  ].join("\n");
}

async function chat({ message, context, history, image, env }) {
  if (!message) return jsonResponse({ error: "Messaggio mancante." }, 400);

  const anthropicRes = await fetch(ANTHROPIC_API_URL, {
    method: "POST",
    headers: {
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": ANTHROPIC_VERSION,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: 1024,
      system: buildSystemPrompt(context),
      messages: buildAnthropicMessages(history, message, image)
    })
  });

  if (!anthropicRes.ok) {
    const errText = await anthropicRes.text();
    console.error("Errore Anthropic:", anthropicRes.status, errText);
    // Il dettaglio vero arriva fino alla chat: comodo per un'app a uso
    // personale, evita di dover andare a cercare nei log del Worker.
    return jsonResponse({ error: `Errore Anthropic (${anthropicRes.status}): ${errText.slice(0, 300)}` }, 502);
  }

  const data = await anthropicRes.json();
  const reply = (data.content || [])
    .filter(block => block.type === "text")
    .map(block => block.text)
    .join("\n")
    .trim();

  return jsonResponse({ reply: reply || "(nessuna risposta)" });
}

// ------------------------------------------------------------------
// Identificazione specie da foto + generazione scheda (risposta strutturata)
//
// Usa il tool-use di Anthropic con tool_choice forzato: è più affidabile del
// chiedere "rispondi in JSON" a un modello che genera testo libero, perché
// garantisce un output conforme allo schema invece di dover fare parsing
// difensivo di markdown/prosa mescolati a JSON.
// ------------------------------------------------------------------

async function callAnthropicTool({ env, systemPrompt, userContent, tool }) {
  const res = await fetch(ANTHROPIC_API_URL, {
    method: "POST",
    headers: {
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": ANTHROPIC_VERSION,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: ANTHROPIC_MODEL,
      max_tokens: 1536,
      system: systemPrompt,
      tools: [tool],
      tool_choice: { type: "tool", name: tool.name },
      messages: [{ role: "user", content: userContent }]
    })
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error("Errore Anthropic (tool-use):", res.status, errText);
    throw new Error(`Errore Anthropic (${res.status}): ${errText.slice(0, 300)}`);
  }

  const data = await res.json();
  const toolUse = (data.content || []).find(block => block.type === "tool_use");
  if (!toolUse) throw new Error("Il modello non ha restituito una risposta strutturata.");
  return toolUse.input;
}

const TOOL_CANDIDATI_SPECIE = {
  name: "proponi_candidati_specie",
  description: "Proponi fino a 4 specie candidate identificate dalla foto di una pianta",
  input_schema: {
    type: "object",
    properties: {
      candidati: {
        type: "array",
        items: {
          type: "object",
          properties: {
            nome: { type: "string", description: "Nome comune della pianta" },
            specieBotanica: { type: "string", description: "Nome scientifico" },
            confidenza: { type: "string", enum: ["alta", "media", "bassa"] },
            note: { type: "string", description: "Breve motivazione o caratteristiche distintive osservate nella foto" }
          },
          required: ["nome", "specieBotanica", "confidenza"]
        }
      }
    },
    required: ["candidati"]
  }
};

async function identificaSpecie({ message, context, image, env }) {
  if (!image?.data) return jsonResponse({ error: "Foto mancante." }, 400);

  const content = [
    { type: "image", source: { type: "base64", media_type: image.mediaType, data: image.data } },
    { type: "text", text: message || "Identifica questa pianta dalla foto." }
  ];

  const systemPrompt = [
    "Sei l'assistente botanico del 'Giardino di Zorba'.",
    "Analizza la foto e proponi fino a 4 specie candidate plausibili, ordinate dalla più alla meno probabile.",
    "Se una delle specie già presenti nel database corrisponde, segnalalo nel campo 'note'.",
    "Specie già presenti nel database (per riferimento):",
    JSON.stringify(context?.specieEsistenti ?? [], null, 2)
  ].join("\n");

  try {
    const input = await callAnthropicTool({ env, systemPrompt, userContent: content, tool: TOOL_CANDIDATI_SPECIE });
    return jsonResponse({ candidati: input.candidati || [] });
  } catch (e) {
    return jsonResponse({ error: e.message }, 502);
  }
}

const STAGIONI_SCHEMA = {
  type: "object",
  properties: {
    primavera: { type: "string" },
    estate: { type: "string" },
    autunno: { type: "string" },
    inverno: { type: "string" }
  },
  required: ["primavera", "estate", "autunno", "inverno"]
};

const TOOL_SCHEDA_SPECIE = {
  name: "genera_scheda_specie",
  description: "Genera la scheda di cura completa per una specie da inserire nel database del giardino",
  input_schema: {
    type: "object",
    properties: {
      nome: { type: "string", description: "Nome comune" },
      specie: { type: "string", description: "Nome scientifico" },
      descrizione: { type: "string", description: "Breve descrizione in HTML semplice, es. <p>...</p>" },
      esigenze: {
        type: "object",
        properties: { luce: { type: "string" }, acqua: { type: "string" }, terreno: { type: "string" } },
        required: ["luce", "acqua", "terreno"]
      },
      alert: { type: "array", items: { type: "string" }, description: "Punti di attenzione/rischi noti per questa specie" },
      manutenzione: {
        type: "object",
        properties: {
          irrigazione: STAGIONI_SCHEMA,
          concimazione: STAGIONI_SCHEMA,
          potatura: STAGIONI_SCHEMA
        },
        required: ["irrigazione", "concimazione", "potatura"]
      }
    },
    required: ["nome", "specie", "descrizione", "esigenze", "alert", "manutenzione"]
  }
};

async function generaSchedaSpecie({ message, speciesName, image, env }) {
  if (!speciesName) return jsonResponse({ error: "Nome specie mancante." }, 400);

  const content = [];
  if (image?.data) {
    content.push({ type: "image", source: { type: "base64", media_type: image.mediaType, data: image.data } });
  }
  content.push({ type: "text", text: message || `Genera la scheda di cura completa per "${speciesName}".` });

  const systemPrompt = [
    "Sei l'assistente botanico del 'Giardino di Zorba'.",
    `Genera una scheda di cura completa e realistica per la specie "${speciesName}", in italiano.`,
    "Le indicazioni di manutenzione (irrigazione, concimazione, potatura) devono essere specifiche per ciascuna delle 4 stagioni.",
    "Se una cura non è necessaria in una stagione, scrivi esplicitamente 'sospesa' o 'nessuna' invece di lasciare il campo vuoto."
  ].join("\n");

  try {
    const input = await callAnthropicTool({ env, systemPrompt, userContent: content, tool: TOOL_SCHEDA_SPECIE });
    return jsonResponse({ scheda: input });
  } catch (e) {
    return jsonResponse({ error: e.message }, 502);
  }
}

// ------------------------------------------------------------------

async function handleChat(request, env) {
  const authHeader = request.headers.get("Authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "");

  if (!token) return jsonResponse({ error: "Token mancante." }, 401);

  const tokenValido = await validaTokenGitHub(token, env);
  if (!tokenValido) return jsonResponse({ error: "Token non valido." }, 401);

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ error: "Body non valido." }, 400);
  }

  const { action, message, context, history, image, speciesName } = body;

  if (action === "identifica_specie") {
    return await identificaSpecie({ message, context, image, env });
  }
  if (action === "genera_scheda_specie") {
    return await generaSchedaSpecie({ message, speciesName, image, env });
  }

  return await chat({ message, context, history, image, env });
}

// Da integrare nel router del Worker esistente, es.:
//
//   if (url.pathname === "/agente/chat") return handleAgenteChat(request, env);
//
export async function handleAgenteChat(request, env) {
  if (request.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders() });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Metodo non consentito." }, 405);
  }
  try {
    return await handleChat(request, env);
  } catch (e) {
    console.error("Errore handleAgenteChat:", e);
    return jsonResponse({ error: "Errore interno del Worker." }, 500);
  }
}
