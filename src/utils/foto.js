// Ridimensiona nel browser a lato lungo 1568 px, JPEG 0,85: le foto dei telefoni pesano 3-8 MB e Claude le
// ridurrebbe comunque. L'orientamento EXIF lo applica createImageBitmap. Il risultato è sempre JPEG (anche da HEIC/PNG).
const LATO = 1568

export async function ridimensionaFoto(file) {
  const img = await createImageBitmap(file, { imageOrientation: 'from-image' })
  const scala = Math.min(1, LATO / Math.max(img.width, img.height))
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(img.width * scala)
  canvas.height = Math.round(img.height * scala)
  canvas.getContext('2d').drawImage(img, 0, 0, canvas.width, canvas.height)
  img.close()
  const anteprima = canvas.toDataURL('image/jpeg', 0.85)
  return { base64: anteprima.split(',')[1], anteprima }
}
