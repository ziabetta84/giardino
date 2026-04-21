function get(key) {
  return JSON.parse(localStorage.getItem(key) || "[]");
}

function set(key, value) {
  localStorage.setItem(key, JSON.stringify(value));
}

function saveZone(z) {
  const zones = get("zones");
  const idx = zones.findIndex(x => x.nome === z.nome);
  if (idx >= 0) zones[idx] = z;
  else zones.push(z);
  set("zones", zones);
}

function savePlant(p) {
  const plants = get("plants");
  const idx = plants.findIndex(x => x.nome === p.nome);
  if (idx >= 0) plants[idx] = p;
  else plants.push(p);
  set("plants", plants);
}

function saveProject(p) {
  const projects = get("projects");
  const idx = projects.findIndex(x => x.nome === p.nome);
  if (idx >= 0) projects[idx] = p;
  else projects.push(p);
  set("projects", projects);
}
