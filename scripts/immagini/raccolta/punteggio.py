import re, json, sys, os
LIC_OK = re.compile(r'^(cc0|cc[- ]zero|public domain|pd\b|pd-|cc[- ]by(-sa)?[- ]\d)', re.I)
LIC_NO = re.compile(r'\bnc\b|\bnd\b|non-?commercial|no-?deriv', re.I)
MALE = {5: r'leaf|leaves|foglia|foglie|blatt|bl[aä]tter|feuille|hoja|seed|seme|semi|samen|zaad|graine|mhnt|herbar|specimen|exsicc|section|cross[- ]?section|dried|essicc|root|radic|wurzel|stamen|stami|pollen|anther|bee\b|bees\b|bumble|hummel|biene|abeille|ape\b|apis|spider|araneus|ragno|butterfl|farfall|moth|aphid|afid|larva|caterpillar|bruco|beetle|hoverfl|syrph|wasp|insect|insetto|bug\b|snail|lumaca|market|mercato|supermarket|dish|recipe|ricetta|salad|insalata|sauce|sugo|pasta|pesto|soup|cooked|food|cuisine|meal|kitchen|plate\b|illustration|drawing|painting|k[oö]hler|stamp|francobollo|map\b|diagram|logo|disease|rust\b|mildew|oidio|pest\b|damage|infest|sprout|germinat|seedling|plantul|bulb\b|bulbs|tuber|cutting|talea|wood\b|legno|timber|pollinat|micrograph|sem\b|microscop|cell\b|chloroplast|trichome|thin section|sale\b|price|prezz',
        3: r'focus stack|stacking|bloemknop|knop\b|bl[uü]te|fleur|\bflor\b|flowers\b|white bg|fondo|background|halved|segments|guacamole|wreath|corona d|medal|portrait|nissan|cocktail|liqueur',
        2: r'macro|close[- ]?up|closeup|detail|dettaglio|fruit|frutt|flower\b|fiore|bud\b|bocciol|inflorescence|infiorescenz|capsule|pod\b|baccell|bark|corteccia|stem|fusto|thorn|spine|kz\d|sp\.|spp|hybrid|ibrido'}
BENE = {3: r'habit|habitus|portamento',
        2: r'portamento|plant\b|pianta|garden|giardino|jardin|garten|bush|shrub|cespug|tree\b|albero|in pot|vaso|potted|whole|intera|field|campo|orto'}
def lic_ok(f):
    l = f.get('licenza') or ''
    return bool(LIC_OK.search(l)) and not LIC_NO.search(l) and not (f.get('nonfree') in ('true', True))
def punteggio(f, nome_sci, principali):
    t = f['titolo'].lower() + ' ' + (f.get('descrizione') or '').lower()[:200]
    s = 0
    for peso, rx in MALE.items():
        if re.search(rx, f['titolo'].lower()): s -= peso
        elif re.search(rx, (f.get('descrizione') or '').lower()[:200]): s -= peso / 2
    for peso, rx in BENE.items():
        if re.search(rx, t): s += peso
    if f.get('qualita'): s += 3
    if f['titolo'] in principali: s += 4
    if nome_sci.split(' ')[0].lower() in f['titolo'].lower(): s += 1
    if min(f['w'], f['h']) < 700: s -= 3
    r = f['w'] / max(f['h'], 1)
    if r > 2.2 or r < 0.45: s -= 2
    return s
