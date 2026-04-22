async function uploadFoto(path, file) {
  const token = localStorage.getItem("github_token");
  if (!token) {
    alert("Devi effettuare il login.");
    return false;
  }

  const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/docs/${path}`;

  const arrayBuffer = await file.arrayBuffer();
  const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));

  const res = await fetch(apiUrl, {
    method: "PUT",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      message: `Upload foto ${file.name}`,
      content: base64
    })
  });

  return res.ok;
}
