#!/usr/bin/env python3
"""Fase 3: pagina dell'elenco da rivedere (dal TSV di mappa_revisione.sql), da pubblicare come Artifact privato.

Uno strumento interno di revisione: per ogni caso mostra il nome della riga, la proposta e l'alternativa; l'utente
risponde in chat con le sole eccezioni. Scrive solo il contenuto della pagina (titolo, stile, testo): lo scheletro
HTML lo aggiunge la pubblicazione. Colori e caratteri del progetto (CLAUDE.md, "Palette e design").
Uso: python3 scripts/tassonomia/mappa_revisione_pagina.py revisione.tsv [INTRODUZIONE] > revisione.html
  INTRODUZIONE (facoltativa) sostituisce la prima frase dell'introduzione, per esempio per un elenco di sole correzioni.
"""
import csv
import html
import sys
from itertools import groupby

righe = list(csv.DictReader(open(sys.argv[1], encoding='utf-8'), delimiter='\t'))
e = html.escape
apertura = e(sys.argv[2]) if len(sys.argv) > 2 else (
    f'{len(righe)} nomi del catalogo del giardino non coincidono esattamente con quelli di Catalogue of Life.')
sezioni = []
for gruppo, casi in groupby(righe, key=lambda r: r['gruppo']):
    casi = list(casi)
    voci = []
    for r in casi:
        acc = f'<span class="acc">oggi si chiama <i>{e(r["accettato"])}</i></span>' if r['accettato'] else ''
        piante = (f'<span class="piante">{r["piante"]} {"pianta" if r["piante"] == "1" else "piante"} tue</span>'
                  if r['piante'] not in ('', '0') else '')
        voci.append(
            f'<li><span class="num">{r["numero"]}</span><div class="caso">'
            f'<p class="nome"><i>{e(r["vecchio_nome_scientifico"])}</i>{piante}</p>'
            f'<p class="prop"><span class="freccia" aria-hidden="true">→</span> {e(r["proposta"])} {acc}</p>'
            f'<p class="alt">se no: {e(r["alternativa"])}</p></div></li>')
    sezioni.append(f'<section><h2>{e(gruppo)} <span class="conta">{len(casi)}</span></h2>'
                   f'<ol class="casi">{"".join(voci)}</ol></section>')

print(f"""<title>Revisione abbinamenti</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=DM+Sans:opsz,wght@9..40,400;9..40,600&family=Fraunces:opsz,wght@9..144,600&display=swap">
<style>
/* elenco a una colonna, un caso per riga: numero, nome della riga, proposta, alternativa */
:root {{
  --sfondo: #faf7f2; --testo: #2d2a26; --tenue: #6f685e; --linea: #e6ddd0;
  --salvia: #557a5e; --oro: #8a6d17; --carta: #fffdf9;
  --titoli: "Fraunces", Georgia, serif; --corpo: "DM Sans", system-ui, sans-serif;
}}
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{ --sfondo: #1c1e1c; --testo: #ece8e1; --tenue: #a8a196; --linea: #383b36;
    --salvia: #9cc2a4; --oro: #e0b84a; --carta: #232623; color-scheme: dark; }}
}}
:root[data-theme="dark"] {{ --sfondo: #1c1e1c; --testo: #ece8e1; --tenue: #a8a196; --linea: #383b36;
  --salvia: #9cc2a4; --oro: #e0b84a; --carta: #232623; color-scheme: dark; }}
body {{ background: var(--sfondo); color: var(--testo); font: 16px/1.5 var(--corpo); padding-inline: 16px; }}
main {{ max-width: 46rem; margin: 0 auto; padding-block: 28px 48px; }}
h1 {{ font: 600 1.75rem/1.2 var(--titoli); margin: 0 0 .75rem; text-wrap: balance; }}
h2 {{ font: 600 1.2rem/1.3 var(--titoli); color: var(--salvia); margin: 2.25rem 0 .5rem; }}
.conta {{ color: var(--tenue); font: 400 1rem var(--corpo); font-variant-numeric: tabular-nums; }}
.intro {{ max-width: 62ch; color: var(--tenue); margin: 0; }}
.intro b {{ color: var(--testo); font-weight: 600; }}
ol.casi {{ list-style: none; margin: 0; padding: 0; display: grid; }}
ol.casi li {{ display: grid; grid-template-columns: 2.75rem 1fr; gap: .25rem .75rem; padding: .7rem 0; border-top: 1px solid var(--linea); }}
.num {{ color: var(--tenue); font-variant-numeric: tabular-nums; text-align: right; padding-top: .05rem; }}
.caso {{ min-width: 0; display: grid; gap: .1rem; }}
.caso p {{ margin: 0; overflow-wrap: anywhere; }}
.prop {{ color: var(--testo); }}
.freccia {{ color: var(--salvia); }}
.acc, .alt {{ color: var(--tenue); font-size: .9rem; }}
.piante {{ margin-left: .5rem; padding: 0 .45rem; border: 1px solid var(--oro); border-radius: 999px; color: var(--oro);
  font-size: .78rem; letter-spacing: .02em; font-style: normal; white-space: nowrap; }}
</style>
<main>
<h1>Revisione degli abbinamenti</h1>
<p class="intro">{apertura}
Per ognuno c'è già una proposta e, sotto, l'alternativa che vale se la respingi. Rispondi in chat <b>solo con le
eccezioni</b>: «12 no» per l'alternativa, «12 è Celosia cristata» per indicare il nome giusto, oppure «tutte ok».</p>
{''.join(sezioni)}
</main>""")
