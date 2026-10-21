// Ridimensiona nel browser a lato lungo 1568 px, JPEG 0,85: le foto dei telefoni pesano 3-8 MB e Claude le
// ridurrebbe comunque. L'orientamento EXIF lo applica createImageBitmap. Il risultato è sempre JPEG (anche da HEIC/PNG).
const LATO = 1568

// Safari/iOS meno recenti rifiutano l'opzione imageOrientation: si ripiega su createImageBitmap senza opzioni
// e, in ultimo, su un <img> decodificato dal browser (che applica l'orientamento EXIF da sé).
async function decodifica(file) {
  try {
    return await createImageBitmap(file, { imageOrientation: 'from-image' })
  } catch { /* ripiego */ }
  try {
    return await createImageBitmap(file)
  } catch { /* ripiego */ }
  const url = URL.createObjectURL(file)
  try {
    const img = new Image()
    img.src = url
    await img.decode()
    return { sorgente: img, width: img.naturalWidth, height: img.naturalHeight, close() {} }
  } catch {
    throw new Error('Formato di foto non supportato da questo browser.')
  } finally {
    URL.revokeObjectURL(url)
  }
}

export async function ridimensionaFoto(file) {
  const img = await decodifica(file)
  try {
    const scala = Math.min(1, LATO / Math.max(img.width, img.height))
    const canvas = document.createElement('canvas')
    canvas.width = Math.round(img.width * scala)
    canvas.height = Math.round(img.height * scala)
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('Il browser non riesce a elaborare la foto.')
    ctx.fillStyle = '#fff'
    ctx.fillRect(0, 0, canvas.width, canvas.height)
    ctx.drawImage(img.sorgente ?? img, 0, 0, canvas.width, canvas.height)
    const anteprima = canvas.toDataURL('image/jpeg', 0.85)
    return { base64: anteprima.split(',')[1], anteprima }
  } finally {
    img.close?.()
  }
}
