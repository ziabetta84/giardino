// js/parser.js

function parseMetadata(md) {
  const lines = md.split("\n");
  const data = {};

  for (const line of lines) {
    if (!line.trim()) continue;
    const [key, ...rest] = line.split(":");
    if (!rest.length) continue;
    data[key.trim()] = rest.join(":").trim();
  }

  return data;
}
