function exportPlant() {
  const nome = document.getElementById("nome").value;
  const specie = document.getElementById("specie").value;
  const zona = document.getElementById("zona").value;
  const sottozona = document.getElementById("sottozona").value;
  const alert = document.getElementById("alert").value.split("\n");

  const md = `---
nome: ${nome}
specie: ${specie}
zona: ${zona}
sottozona: ${sottozona}

attivita:
  irrigazione:
    primavera: da definire
    estate: da definire
    autunno: da definire
    inverno: da definire
  concimazione:
    primavera: da definire
    estate: da definire
    autunno: da definire
    inverno: da definire
  potatura:
    primavera: da definire
    estate: da definire
    autunno: da definire
    inverno: da definire

alert:
${alert.map(a => `  - ${a}`).join("\n")}

ultimo_controllo: ${new Date().toISOString().slice(0,10)}
---`;

  navigator.clipboard.writeText(md);
  alert("File .md copiato negli appunti");
}
