// js/parser.js

function parseMetadata(md) {
  const lines = md.split("\n");
  const data = {};
  let currentKey = null;

  for (let line of lines) {
    const trimmed = line.trim();

    // Se la riga è vuota → continua il valore multilinea
    if (!trimmed) {
      if (currentKey) data[currentKey] += "\n";
      continue;
    }

    // Riconosce una riga "chiave: valore"
    const match = trimmed.match(/^([a-zA-Z0-9_-]+)\s*:\s*(.*)$/);

    if (match) {
      // Nuova chiave trovata
      currentKey = match[1].toLowerCase();
      data[currentKey] = match[2] || "";
    } else if (currentKey) {
      // Riga di valore multilinea
      data[currentKey] += "\n" + line;
    }
  }

  // Pulizia finale: trim su ogni valore
  for (const k in data) {
    data[k] = data[k].trim();
  }

  return data;
}
