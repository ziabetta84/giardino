"""Disegni per forma della pianta (src/assets/forme/*.svg), nel linguaggio delle icone dell'app (DESIGN.md): macchie di
pigmento con il colore che si raccoglie più scuro, bordi bagnati, un tratto a china, la grana della carta.
Un disegno per forma, uguale per tutte le schede (scelta di Roberta).
  python3 scripts/immagini/forme/disegna.py
"""
import math, random, sys, os
FAM = {'sage': ('#7a9e82', '#5a7e62', '#37543f'), 'olive': ('#9aaa5a', '#6d7a3e', '#545e2a'),
       'rose': ('#cc6e6e', '#b85f5f', '#8a3f3a'), 'gold': ('#e0b84a', '#b8902a', '#7a5a15'),
       'acqua': ('#8fb6cf', '#6f9fc0', '#2b566e'), 'terra': ('#b08a68', '#8a6a4f', '#5a4e3e'),
       'petalo': ('#e9a6c6', '#c97fa3', '#8a3f5e')}
INK = '#2a2218'

def blob(cx, cy, rx, ry, rnd, n=9, j=.16):
    """Macchia irregolare chiusa (curva morbida per punti)."""
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n + rnd.uniform(-.2, .2)
        k = 1 + rnd.uniform(-j, j)
        pts.append((cx + rx * k * math.cos(a), cy + ry * k * math.sin(a)))
    d = ''
    for i in range(n):
        p0, p1, p2 = pts[i - 1], pts[i], pts[(i + 1) % n]
        m1 = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2); m2 = ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)
        d += (f'M{m1[0]:.1f} {m1[1]:.1f}' if i == 0 else '') + f'Q{p1[0]:.1f} {p1[1]:.1f} {m2[0]:.1f} {m2[1]:.1f}'
    return d + 'Z'

class Tela:
    def __init__(s, seed):
        s.r = random.Random(seed); s.defs = []; s.body = []; s.n = 0
    def pool(s, d, fam, cx, cy, rx, ry):
        """Pigmento che si raccoglie: ellisse scura ritagliata nella forma."""
        b, dk, _ = FAM[fam]; s.n += 1; i = s.n
        s.defs.append(f'<clipPath id="k{i}"><path d="{d}"/></clipPath>')
        s.body.append(f'<g filter="url(#bagnato)"><path d="{d}" fill="{b}" fill-opacity=".85"/>'
                      f'<ellipse clip-path="url(#k{i})" cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{dk}" fill-opacity=".42"/>'
                      f'<path d="{d}" fill="none" stroke="{dk}" stroke-opacity=".45" stroke-width="1.3"/></g>')
    def ink(s, d, w=1.4, op=.8):
        s.body.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{w}" stroke-opacity="{op}" stroke-linecap="round" stroke-linejoin="round" filter="url(#china)"/>')
    def svg(s, specchio=False):
        sd = s.r.randint(1, 99)
        defs = ''.join(s.defs) + f'''
<filter id="bagnato" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency=".045" numOctaves="2" seed="{sd}"/><feDisplacementMap in="SourceGraphic" scale="4.5"/></filter>
<filter id="china" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency=".08" numOctaves="1" seed="{sd+3}"/><feDisplacementMap in="SourceGraphic" scale="1.8"/></filter>
<filter id="grana"><feTurbulence type="fractalNoise" baseFrequency=".85" numOctaves="2" seed="7"/><feColorMatrix values="0 0 0 0 .35  0 0 0 0 .3  0 0 0 0 .22  0 0 0 .09 0"/></filter>'''
        t = ' transform="translate(160 0) scale(-1 1)"' if specchio else ''
        terra = f'<path d="{blob(80, 104, 52, 5.5, s.r, 11, .1)}" fill="#e8dfcf" filter="url(#bagnato)"/>'
        return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 120"><defs>{defs}</defs>'
                f'<rect width="160" height="120" fill="#faf7f2"/>{terra}<g{t}>{"".join(s.body)}</g>'
                f'<rect width="160" height="120" filter="url(#grana)"/></svg>\n')

def albero(t, v):
    r = t.r; tono = ['sage', 'olive'][v % 2]; altro = ['olive', 'sage'][v % 2]
    t.pool('M76 104 C77 92 76 80 78 64 L84 64 C84 80 83 92 86 104Z', 'terra', 80, 98, 5, 8)
    t.ink('M80 76 C86 70 92 66 98 58 M79 82 C72 76 66 70 62 62', 1.6)
    d = blob(80, 44, 42, 32, r, 12, .13); t.pool(d, tono, 72, 58, 36, 16)
    t.pool(blob(56, 56, 17, 13, r), altro, 52, 62, 13, 6)
    t.pool(blob(106, 50, 16, 13, r), altro, 110, 56, 11, 6)
    t.pool(blob(84, 22, 15, 10, r), altro, 84, 28, 10, 4)

def arbusto(t, v):
    r = t.r
    for cx, cy, rx, ry, f in [(62, 84, 22, 18, 'sage'), (98, 84, 22, 18, 'olive'), (80, 72, 26, 22, 'sage')]:
        d = blob(cx, cy, rx, ry, r); t.pool(d, f, cx + 4, cy + 10, rx * .8, ry * .45)
    for _ in range(7):
        x, y = r.uniform(56, 104), r.uniform(60, 92)
        t.pool(blob(x, y, 3.2, 3, r, 6, .2), 'rose', x + 1, y + 1.5, 2.5, 1.5)

def erbacea(t, v):
    r = t.r
    t.pool(blob(80, 99, 30, 7, r), 'olive', 80, 102, 26, 4)
    for x, h, f in [(62, 46, 'rose'), (74, 34, 'gold'), (88, 50, 'rose'), (100, 40, 'petalo')]:
        t.ink(f'M80 100 Q{(x + 80) / 2 + r.uniform(-4, 4):.0f} 74 {x} {h + 6}', 1.3)
        t.pool(blob(x, h, 8, 7, r, 7, .22), f, x + 2, h + 3, 6, 3.5)
        t.body.append(f'<circle cx="{x}" cy="{h}" r="2.2" fill="{FAM["gold"][1]}" filter="url(#bagnato)"/>')

def bulbosa(t, v):
    r = t.r
    t.pool(blob(80, 99, 11, 8, r, 8, .1), 'terra', 82, 102, 8, 4)
    t.ink('M80 92 C80 74 81 60 80 44', 1.5)
    t.pool('M80 97 C66 84 58 64 60 42 C68 62 74 78 80 97Z', 'olive', 66, 70, 6, 20)
    t.pool('M80 97 C94 84 102 66 100 46 C92 64 86 80 80 97Z', 'sage', 94, 72, 6, 18)
    t.pool('M80 46 C70 40 68 28 72 20 C76 28 78 30 80 30 C82 30 84 28 88 20 C92 28 90 40 80 46Z', 'rose', 80, 40, 8, 5)

def rampicante(t, v):
    r = t.r
    t.ink('M56 104 L58 22 M102 104 L104 22 M52 36 L108 34 M52 64 L108 62', 1.6, .55)
    t.ink('M80 104 C62 92 98 82 78 68 C60 56 100 48 82 32 C76 26 84 20 88 18', 1.4)
    for i, (x, y, a) in enumerate([(70, 94, -30), (92, 84, 30), (68, 72, -20), (94, 58, 25), (70, 46, -35), (90, 32, 20)]):
        d = blob(x, y, 8, 4.5, r, 7, .12); t.pool(d, ['sage', 'olive'][i % 2], x, y + 2, 6, 2)
    for x, y, f in [(96, 44, 'rose'), (64, 60, 'gold'), (86, 22, 'rose')]:
        t.pool(blob(x, y, 5, 5, r, 6, .2), f, x + 1, y + 2, 4, 2)

def graminacea(t, v):
    r = t.r
    for dx, h, f in [(-46, 52, 'sage'), (-30, 34, 'olive'), (-14, 24, 'sage'), (2, 18, 'olive'), (16, 26, 'sage'), (32, 36, 'olive'), (46, 54, 'sage')]:
        x2 = 80 + dx; w = 2.6
        t.pool(f'M{78 - w} 104 Q{80 + dx * .35:.0f} 70 {x2} {h} Q{80 + dx * .35 + w:.0f} 72 {82 + w} 104Z', f, 80 + dx * .3, 84, 3, 14)
    for x, y, a in [(64, 26, -18), (82, 16, 0), (98, 28, 18)]:
        t.pool(blob(x, y, 3.5, 9, r, 7, .1), 'gold', x, y + 3, 2.5, 4)

def orchidea(t, v):
    r = t.r
    t.pool('M48 104 C56 88 72 90 80 100 C88 90 104 88 112 104Z', 'sage', 80, 102, 26, 4)
    t.ink('M80 100 C78 78 86 56 106 34', 1.4)
    for x, y in [(84, 64), (94, 48), (108, 34)]:
        for a in (0, 72, 144, 216, 288):
            px, py = x + 8 * math.sin(math.radians(a)), y - 8 * math.cos(math.radians(a))
            t.pool(blob(px, py, 5, 5, r, 6, .15), 'petalo', px, py + 1, 3, 2)
        t.pool(blob(x, y + 3, 4.5, 5, r, 6, .1), 'rose', x, y + 5, 3, 2.5)

def succulenta(t, v):
    r = t.r
    t.pool(blob(80, 101, 22, 5, r), 'terra', 80, 103, 18, 2.5)
    for dx, h, f in [(-34, 22, 'olive'), (34, 22, 'olive'), (-22, 40, 'sage'), (22, 40, 'sage'), (-9, 52, 'sage'), (9, 52, 'olive'), (0, 58, 'sage')]:
        tip = (80 + dx * 1.1, 98 - h)
        d = f'M{80 + dx * .25 - 7:.0f} 98 Q{80 + dx * .8 - 8:.0f} {98 - h * .55:.0f} {tip[0]:.0f} {tip[1]:.0f} Q{80 + dx * .8 + 8:.0f} {98 - h * .45:.0f} {80 + dx * .25 + 7:.0f} 98Z'
        t.pool(d, f, 80 + dx * .5, 98 - h * .3, 5, h * .25)

def felce(t, v):
    r = t.r
    for dx, h, f in [(-46, 48, 'olive'), (-18, 22, 'sage'), (16, 20, 'sage'), (44, 46, 'olive')]:
        x2 = 80 + dx; n = 9; sx = 80 + dx * .45
        L, R = [], []
        for k in range(n + 1):
            tt = k / n; px = (1-tt)**2*80 + 2*(1-tt)*tt*sx + tt*tt*x2; py = (1-tt)**2*104 + 2*(1-tt)*tt*66 + tt*tt*h
            w = 9 * math.sin(math.pi * min(1, tt * 1.15)) * (1 if k % 2 else .55) + .5
            ang = math.atan2(2*(1-tt)*(66-104) + 2*tt*(h-66), 2*(1-tt)*(sx-80) + 2*tt*(x2-sx)) + math.pi / 2
            L.append((px + w * math.cos(ang), py + w * math.sin(ang))); R.append((px - w * math.cos(ang), py - w * math.sin(ang)))
        pts = L + R[::-1]
        d = 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + 'Z'
        t.pool(d, f, 80 + dx * .55, 104 - (104 - h) * .55, 6, 14)
        t.ink(f'M80 104 Q{sx:.0f} 66 {x2} {h}', 1.1, .7)

def conifera(t, v):
    t.ink('M80 104 L80 86', 2.4)
    d = 'M80 14 C86 26 92 36 100 46 L92 46 C100 58 106 66 114 76 L102 76 C110 84 116 88 122 94 L38 94 C44 88 50 84 58 76 L46 76 C54 66 60 58 68 46 L60 46 C68 36 74 26 80 14Z'
    t.pool(d, 'sage', 92, 80, 26, 14)

def palma(t, v):
    t.pool('M74 104 C72 84 76 62 82 42 L87 43 C82 62 80 84 82 104Z', 'terra', 78, 90, 4, 14)
    for dx, up, dn, f in [(-46, 18, 16, 'sage'), (46, 18, 16, 'sage'), (-32, 26, -4, 'olive'), (32, 26, -4, 'olive'), (-10, 30, -24, 'sage'), (14, 30, -22, 'olive')]:
        ex, ey = 84 + dx, 42 + dn; cx, cy = 84 + dx * .5, 42 - up
        d = f'M84 42 Q{cx:.0f} {cy - 4:.0f} {ex} {ey} Q{cx:.0f} {cy + 6:.0f} 84 46Z'
        t.pool(d, f, cx, cy + 4, 10, 3)

def acquatica(t, v):
    r = t.r
    t.pool(blob(80, 96, 64, 13, r, 13, .06), 'acqua', 80, 100, 50, 6)
    t.pool('M44 96 C44 88 60 86 68 90 L58 96 L70 98 C62 104 44 102 44 96Z', 'sage', 54, 98, 8, 3)
    t.pool(blob(112, 100, 16, 5.5, r), 'olive', 114, 102, 10, 2)
    for a, f in [(-52, 'petalo'), (52, 'petalo'), (-26, 'rose'), (26, 'rose'), (0, 'rose')]:
        c, s_ = math.cos(math.radians(a)), math.sin(math.radians(a))
        d = f'M80 90 Q{80 + 9 * c + 10 * s_:.1f} {90 - 10 * c + 9 * s_ * .3:.1f} {80 + 16 * s_:.1f} {90 - 16 * c:.1f} Q{80 - 9 * c + 10 * s_:.1f} {90 - 10 * c:.1f} 80 90Z'
        t.pool(d, f, 80 + 10 * s_, 90 - 10 * c, 3, 4)
    t.body.append(f'<circle cx="80" cy="86" r="2.6" fill="{FAM["gold"][0]}" filter="url(#bagnato)"/>')

FORME = dict(albero=albero, arbusto=arbusto, erbacea=erbacea, bulbosa=bulbosa, rampicante=rampicante, graminacea=graminacea,
             orchidea=orchidea, succulenta=succulenta, felce=felce, conifera=conifera, palma=palma, acquatica=acquatica)

SEME = 4  # fissa macchie e grana: rilanciando lo script i disegni restano identici


if __name__ == '__main__':
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'src', 'assets', 'forme')
    for nome, f in FORME.items():
        t = Tela(SEME)
        f(t, SEME)
        open(os.path.join(out, nome + '.svg'), 'w').write(t.svg())
    print(len(FORME), 'disegni in', os.path.normpath(out))
