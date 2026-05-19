async function uploadFoto(path, file) {
  const token = localStorage.getItem("github_token");
  if (!token) {
    alert("Devi effettuare il login.");
    return false;
  }

  const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/docs/${path}`;

  const arrayBuffer = await file.arrayBuffer();
  // Convert ArrayBuffer -> base64 without using spread (evita RangeError su file grandi)
  const bytes = new Uint8Array(arrayBuffer);
  let binary = "";
  const chunkSize = 0x8000; // 32KB chunks
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const sub = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode.apply(null, sub);
  }
  const base64 = btoa(binary);

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

  if (!res.ok) {
    console.error("uploadFoto failed:", res.status, await res.text());
  }
  return res.ok;
}
