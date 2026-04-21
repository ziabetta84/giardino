function parseMetadata(md) {
  const lines = md.split("\n");
  const data = {};
  let currentKey = null;

  for (let line of lines) {
    const trimmed = line.trim();

    // Nuova chiave: "chiave: valore"
    const match = trimmed.match(/^([a-zA-Z0-9_-]+)\s*:\s*(.*)$/);

    if (match) {
      currentKey = match[1].toLowerCase();
      data[currentKey] = match[2] || "";
      continue;
    }

    // Se NON è una nuova chiave e abbiamo una chiave corrente → multilinea
    if (currentKey !== null) {
      data[currentKey] += "\n" + line;
    }
  }

  // Pulizia finale
  for (const k in data) {
    data[k] = data[k].trim();
  }

  return data;
}
