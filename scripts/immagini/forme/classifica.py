"""Forma della pianta per le schede senza foto: l'app ne mostra il disegno (src/assets/forme/) finché non arriva una foto.

Uso, dal Mac (sola lettura sul database):
  psql ... -f scripts/immagini/forme/elenco.sql > scripts/immagini/lavoro/forme_elenco.tsv
  python3 scripts/immagini/forme/classifica.py scripts/immagini/lavoro/forme_elenco.tsv
Scrive dati/forme.tsv (scheda, forma, perché, nome, famiglia, descrizione), la migration e il rollback.

Criteri, in ordine:
- classe o famiglia che decidono da sole (felci, conifere, orchidee, palme, graminacee, succulente, bulbose);
- altrimenti la prima parola di forma nelle prime righe della descrizione («arbusto», «tree», «climber»…), prima di
  «perenne»/«annual», che spesso è solo un aggettivo («perennial climber»);
- altrimenti erbacea se la scheda ha un ciclo vitale; altrimenti nessuna forma (da decidere a mano, DECISE sotto).
"""
import csv, collections, json, os, re, sys

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.join(QUI, '..', '..', '..')
NOME = '20261030100000_schede_forma'
FORME = ['albero', 'arbusto', 'erbacea', 'bulbosa', 'rampicante', 'graminacea', 'orchidea', 'succulenta', 'felce',
         'conifera', 'palma', 'acquatica']
CLASSI = {'Polypodiopsida': 'felce', 'Lycopodiopsida': 'felce', 'Pinopsida': 'conifera', 'Cycadopsida': 'palma'}
FAMIGLIE = {'Cactaceae': 'succulenta', 'Crassulaceae': 'succulenta', 'Aizoaceae': 'succulenta', 'Orchidaceae': 'orchidea',
            'Arecaceae': 'palma', 'Poaceae': 'graminacea', 'Cyperaceae': 'graminacea', 'Juncaceae': 'graminacea',
            'Nymphaeaceae': 'acquatica', 'Amaryllidaceae': 'bulbosa', 'Iridaceae': 'bulbosa', 'Liliaceae': 'bulbosa'}
PAROLE = [('rampicante', r'\b(climber|climbing|twining|vine|liana|scrambl|rampicant|lian[ae])'),
          ('albero', r'\b(tree|albero|alberi|arboreo)'),
          ('arbusto', r'\b(shrub|subshrub|sub-shrub|arbust|cespuglio|suffrutice)'),
          ('succulenta', r'\b(succulent|cactus|carnos)'),
          ('bulbosa', r'\b(bulb|bulbo|bulbos|corm|cormo|tuber|tubero)'),
          ('graminacea', r'\b(grass|graminace|sedge)'),
          ('acquatica', r'\b(aquatic|acquatic|marginal|water plant|palustr)'),
          ('erbacea', r'\b(herbaceous|perennial|annual|biennial|erbace|perenne|annuale|biennale|rosette|rosetta)')]
# Schede senza una descrizione utile, decise a mano (nome → forma), approvate da Roberta il 30/10/2026
DECISE = {'Acantholimon venustum': 'arbusto', 'Euryops × solaris': 'arbusto', 'Hoya tsiangiana': 'rampicante',
          'Mahonia leveilleana': 'arbusto', 'Malus × magdeburgensis': 'albero', 'Prunus himalaica': 'albero',
          'Rhododendron caesium': 'arbusto', 'Rosa banksiopsis': 'arbusto', 'Rosa corymbulosa': 'arbusto',
          'Rosa stylosa': 'arbusto', 'Rubus irenaeus': 'arbusto', 'Sarracenia × popei': 'erbacea',
          'Sorbus helenae': 'albero', 'Thalictrum diffusiflorum': 'erbacea'}


def forma(antenati, descrizione, ciclo, nome):
    if nome in DECISE:
        return DECISE[nome], 'a mano'
    if antenati.get('class') in CLASSI:
        return CLASSI[antenati['class']], 'classe'
    f = FAMIGLIE.get(antenati.get('family'))
    if f and f != 'bulbosa':
        return f, 'famiglia'
    testo = descrizione.lower()
    trovate = [(m.start(), k) for k, rx in PAROLE for m in [re.search(rx, testo)] if m and k != 'erbacea' and m.start() < 160]
    if f:  # bulbose: la famiglia vale, salvo una forma legnosa o rampicante nella descrizione
        trovate = [x for x in trovate if x[1] in ('albero', 'arbusto', 'rampicante')]
        return (min(trovate)[1], 'descrizione') if trovate else (f, 'famiglia')
    if not trovate:
        trovate = [(m.start(), k) for k, rx in PAROLE for m in [re.search(rx, testo)] if m]
    if trovate:
        return min(trovate)[1], 'descrizione'
    return ('erbacea', 'ciclo vitale') if ciclo else (None, '')


def lit(x):
    return "'" + x.replace("'", "''") + "'"


def funzione_voce(con_forma):
    """catalogo.voce della fase 6, con o senza il campo forma (ereditato come gli altri campi della scheda)."""
    s = open(os.path.join(RADICE, 'supabase', 'migrations', '20261021100000_tassonomia_fase6_catalogo.sql')).read()
    s = s[s.index('create function catalogo.voce('):]
    s = s[:s.index('end $$;') + len('end $$;')].replace('create function', 'create or replace function')
    if con_forma:
        s = s.replace('s.ciclo_vitale, s.vaso, s.alert, s.immagine\n', 's.ciclo_vitale, s.vaso, s.alert, s.immagine, s.forma\n')
        s = s.replace("'immagine', s.immagine)) x", "'immagine', s.immagine, 'forma', s.forma)) x")
        assert s.count('s.immagine, s.forma') == 2 and "'forma', s.forma" in s
    return s


def main(elenco):
    righe, conti = [], collections.Counter()
    for sid, rango, nome, ciclo, lin, desc in csv.reader(open(elenco), delimiter='\t'):
        antenati = dict(x.split(':', 1) for x in lin.split('|') if ':' in x)
        f, perche = forma(antenati, desc, ciclo, nome)
        conti[f or 'da decidere'] += 1
        righe.append((sid, f or '', perche, nome, antenati.get('family', ''), desc[:160]))
    with open(os.path.join(QUI, '..', 'dati', 'forme.tsv'), 'w') as out:
        csv.writer(out, delimiter='\t', lineterminator='\n').writerows(sorted(righe, key=lambda r: r[3]))
    date = sorted((r for r in righe if r[1]), key=lambda r: r[0])
    valori = ',\n'.join(f'    ({lit(r[0])}::uuid, {lit(r[1])})' for r in date)
    n = len(date)
    sql = f"""-- Forma della pianta per le schede mostrate senza foto (approvato da Roberta): l'app mostra il disegno di quella forma
-- (src/assets/forme/) finché la scheda non ha una foto. La forma si eredita dal livello sopra come gli altri campi.
-- Generata da scripts/immagini/forme/classifica.py (criteri nell'intestazione dello script): non modificare a mano.
-- Rollback: scripts/immagini/forme/rollback_{NOME}.sql

alter table public.schede add column forma text
  check (forma in ({', '.join(lit(f) for f in FORME)}));
grant select (forma) on public.schede to anon, authenticated, service_role;

do $$
declare n int;
begin
  update public.schede s set forma = v.forma
  from (values
{valori}
  ) as v(id, forma)
  where s.id = v.id and s.mostrata and (s.immagine is null or s.immagine->>'url' is null);
  get diagnostics n = row_count;
  if n <> {n} then
    raise exception 'schede aggiornate: % invece di {n}', n;
  end if;
end $$;

{funzione_voce(True)}
"""
    rb = f"""-- Rollback di supabase/migrations/{NOME}.sql: catalogo.voce torna alla versione della fase 6, poi via la colonna.
-- psql "$SUPABASE_DB_URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/immagini/forme/rollback_{NOME}.sql
{funzione_voce(False)}

alter table public.schede drop column forma;
"""
    open(os.path.join(RADICE, 'supabase', 'migrations', NOME + '.sql'), 'w').write(sql)
    open(os.path.join(QUI, f'rollback_{NOME}.sql'), 'w').write(rb)
    for k, v in conti.most_common():
        print(f'{v:5}  {k}')
    print(n, 'schede nella migration')


if __name__ == '__main__':
    main(sys.argv[1])
