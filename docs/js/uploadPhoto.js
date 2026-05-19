async function uploadFoto(path, file) {
  const token = localStorage.getItem("github_token");
  if (!token) {
    alert("Devi effettuare il login.");
    return false;
  }

  const apiUrl = `https://api.github.com/repos/ziabetta84/giardino/contents/docs/${path}`;

  const arrayBuffer = await file.arrayBuffer();
  // Use FileReader to get data URL (base64) to avoid large-argument RangeError
  const base64 = await new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error('FileReader error'));
    reader.onload = () => {
      const result = reader.result || '';
      const comma = result.indexOf(',');
      resolve(result.slice(comma + 1));
    };
    reader.readAsDataURL(new Blob([arrayBuffer]));
  });

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
