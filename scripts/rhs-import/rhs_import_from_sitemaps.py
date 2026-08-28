import os
import re
import time
import requests

sitemap_url = "https://www.rhs.org.uk/sitemap-plants"
output_dir = "./fonti/rhs_from_sitemaps"
os.makedirs(output_dir, exist_ok=True)

# Impostiamo la sessione e gli header per simulare un browser reale
session = requests.Session()
session.headers.update({
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
})

# Ciclo attraverso le 7 sitemap
for i in range(1, 8):
    current_sitemap = f"{sitemap_url}-{i}.xml"
    print(f"\n--- Elaborazione sitemap: {current_sitemap} ---")
    
    try:
        resp = session.get(current_sitemap, timeout=15)
        if resp.status_code != 200:
            print(f" Impossibile recuperare la sitemap {i}: Status {resp.status_code}")
            continue
    except Exception as e:
        print(f" Errore nel download della sitemap {i}: {e}")
        continue

    # Estraggiamo solo gli URL contenuti nei tag <loc>...</loc>
    urls = re.findall(r"<loc>(https?://[^<]+)</loc>", resp.text)
    print(f"Trovati {len(urls)} link nella sitemap {i}.")

    for url in urls:
        # Ignora eventuali link che puntano a pagine di errore o esterne
        if "cloudflare" in url:
            continue

        # Cerca il testo prima di /details (es. acacia-hindsii)
        match = re.search(r"/([^/]+)/details/?$", url)
        if match:
            filename = match.group(1) + ".html"
        else:
            filename = url.rstrip("/").split("/")[-1] + ".html"

        filepath = os.path.join(output_dir, filename)

        # Salta il download se il file esiste già (utilissimo se lo script si interrompe)
        if os.path.exists(filepath):
            continue

        print(f"Scaricando: {url} -> {filename}")
        try:
            r = session.get(url, timeout=15)
            if r.status_code == 200 and "cloudflare" not in r.url:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(r.text)
            else:
                print(f" Errore o blocco su {url}: Status {r.status_code}")
        except Exception as e:
            print(f" Errore su {url}: {e}")

        # Pausa di 0.5s per non far scattare i sistemi anti-bot
        time.sleep(0.5)