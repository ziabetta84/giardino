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
//   Body: { message: string, context: object, history: Array<{role, content}>, image?: { mediaType, data } }
//   Risposta: { reply: string }

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

  const { message, context, history, image } = body;
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
    return jsonResponse({ error: "Errore nella chiamata al modello." }, 502);
  }

  const data = await anthropicRes.json();
  const reply = (data.content || [])
    .filter(block => block.type === "text")
    .map(block => block.text)
    .join("\n")
    .trim();

  return jsonResponse({ reply: reply || "(nessuna risposta)" });
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
