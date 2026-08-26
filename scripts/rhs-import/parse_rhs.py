import json, os, re, sys
from html.parser import HTMLParser

HERE = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(HERE, "..", "..", "fonti", "rhs-varietà")
OUT_FILE = os.path.join(HERE, "rhs_varieta_parsed.json")

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.lines = []
        self.skip = False
    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style', 'nav', 'footer', 'noscript'):
            self.skip = True
    def handle_endtag(self, tag):
        if tag in ('script', 'style', 'nav', 'footer', 'noscript'):
            self.skip = False
    def handle_data(self, data):
        if not self.skip:
            d = data.strip()
            if d:
                self.lines.append(d)

SECTION_MARKERS = [
    "Cultivation", "Propagation", "Suggested planting locations and garden types",
    "Pruning", "Pests", "Diseases",
]

def find_between(lines, start_marker, end_markers):
    try:
        i = lines.index(start_marker)
    except ValueError:
        return None
    j = i + 1
    out = []
    while j < len(lines) and lines[j] not in end_markers:
        out.append(lines[j])
        j += 1
    return " ".join(out).strip() or None

def find_after_label(lines, label):
    try:
        i = lines.index(label)
        return lines[i + 1]
    except (ValueError, IndexError):
        return None

def parse_file(path):
    with open(path, encoding="utf-8", errors="ignore") as fh:
        html = fh.read()
    p = TextExtractor()
    p.feed(html)
    lines = p.lines

    data = {"file": os.path.basename(path)}

    # Title line: "Genus species 'Cultivar' | common name"
    title = lines[0] if lines else ""
    if "|" in title:
        latin, common = title.split("|", 1)
        data["nome_scientifico_titolo"] = latin.strip()
        data["nome_comune_titolo"] = common.strip()
    else:
        data["nome_scientifico_titolo"] = title.strip()

    all_end_markers = set(SECTION_MARKERS) | {"Grow", "How to Grow", "Botanical Details"}

    data["descrizione_breve"] = None
    # one-liner description sits right before "Position" near the top (before Buy/Grow app block)
    if "Position" in lines:
        idx_pos = lines.index("Position")
        # walk backward to find the descriptive sentence (skip short labels)
        for k in range(idx_pos - 1, max(idx_pos - 6, 0), -1):
            if len(lines[k]) > 40:
                data["descrizione_breve"] = lines[k]
                break

    data["famiglia_botanica"] = find_after_label(lines, "Family")

    # "Foliage"/"Fruit" also appear earlier as bare category headers in
    # "Colour & Scent", so anchor on "Native to GB/Ireland" (unique) and
    # scan forward label-by-label instead of assuming fixed offsets: some
    # rare/wild species pages skip Foliage/Habit entirely and go straight
    # to Genus (or omit everything and end at "Name Status").
    data["nativa_gb_irlanda"] = None
    data["fogliame"] = None
    data["habit"] = None
    data["genere_descrizione"] = None
    data["range_geografico"] = None
    if "Native to GB/Ireland" in lines:
        i = lines.index("Native to GB/Ireland")
        try:
            data["nativa_gb_irlanda"] = lines[i + 1]
        except IndexError:
            pass
        label_to_key = {
            "Foliage": "fogliame", "Habit": "habit",
            "Genus": "genere_descrizione", "Plant Range": "range_geografico",
        }
        known_labels = set(label_to_key) | {"Name Status", "Grow", "How to Grow", "Cultivation", "Buy Now"}
        j = i + 2
        stop_labels = {"Grow", "How to Grow", "Cultivation", "Buy Now"}
        while j < len(lines) - 1 and j < i + 30 and lines[j] not in stop_labels:
            if lines[j] in label_to_key:
                # some genus pages leave the value empty in RHS's own data,
                # so the "value" slot is actually the next label already
                if lines[j + 1] not in known_labels:
                    data[label_to_key[lines[j]]] = lines[j + 1]
                    j += 2
                else:
                    j += 1
            elif lines[j] == "Name Status":
                j += 2
            else:
                j += 1

    if data["range_geografico"] is None:
        data["range_geografico"] = find_after_label(lines, "Plant Range")
    data["altezza_max"] = find_after_label(lines, "Max Height")
    data["diffusione_max"] = find_after_label(lines, "Max Spread")
    data["tempo_maturita"] = find_after_label(lines, "Time to Maturity")

    data["cultivation"] = find_between(lines, "Cultivation", all_end_markers)
    data["propagation"] = find_between(lines, "Propagation", all_end_markers)
    data["suggested_locations"] = find_between(lines, "Suggested planting locations and garden types", all_end_markers)
    data["pruning"] = find_between(lines, "Pruning", all_end_markers)
    data["pests"] = find_between(lines, "Pests", all_end_markers)
    data["diseases"] = find_between(lines, "Diseases", all_end_markers)

    # Hardiness code: the actual rating for this plant is the standalone line
    # right after the "H7: hardy in the severest..." description line (fixed
    # last row of the ratings legend), not any of the H1..H7 legend labels.
    data["hardiness"] = None
    if "H7:" in lines:
        i = lines.index("H7:")
        try:
            candidate = lines[i + 2]
            if re.fullmatch(r"H[1-7][ABC]?", candidate):
                data["hardiness"] = candidate
        except IndexError:
            pass

    # Position / Soil / Moisture / pH quick facts (first occurrence, near top box)
    def after(label):
        try:
            i = lines.index(label)
            return lines[i + 1]
        except (ValueError, IndexError):
            return None

    data["moisture"] = after("Moisture")
    data["ph"] = after("pH")
    data["position"] = after("Position")
    data["soil_types"] = after("Soil Types")

    return data


def main():
    files = sorted(f for f in os.listdir(SRC_DIR) if f.lower().endswith(".html"))
    results = []
    errors = []
    for fn in files:
        path = os.path.join(SRC_DIR, fn)
        try:
            results.append(parse_file(path))
        except Exception as e:
            errors.append((fn, str(e)))

    with open(OUT_FILE, "w", encoding="utf-8") as out:
        json.dump(results, out, ensure_ascii=False, indent=1)

    print(f"Parsed {len(results)} files, {len(errors)} errors")
    for fn, e in errors[:20]:
        print("ERROR:", fn, e)

if __name__ == "__main__":
    main()
