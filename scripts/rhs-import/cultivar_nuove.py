"""
Cultivar nuove dalle pagine RHS recuperate (controllo periodico, issue #153).

Prende dal confronto (confronta_catalogo.py) le pagine con esito
cultivar_assente e prepara l'inserimento in `cultivar` come nella fase 4a:
- epiteto, Gruppo e nome commerciale letti dal titolo (cultivar_titoli.leggi_titolo);
- taxon: il nome trovato per la base del titolo (anche sinonimo, l'app risale
  all'accettato); tra omonimi vince l'unico accettato, altrimenti si scarta;
- scartate: serie e miscugli, epiteti già presenti nello stesso genere sotto
  un'altra specie (da controllare a parte), doppioni nella stessa lista.

Uso:
    python3 cultivar_nuove.py CONFRONTO.tsv CARTELLA_CATALOGO CARTELLA_OUT [--lotto=N]
Scrive in CARTELLA_OUT: cultivar_nuove_NN.sql (un lotto per file, N righe),
rollback_cultivar_nuove.sql (cancella per slug, solo se nessuna scheda o
pianta punta alla cultivar), scartate.tsv con il motivo.
"""
import collections, json, os, re, sys, unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tassonomia'))
sys.path.insert(0, HERE)
from cultivar_titoli import leggi_titolo, SERIE_MISCUGLIO  # noqa: E402
from confronta_catalogo import norm_nome, norm_ep, leggi  # noqa: E402

DATA = '18/11/2026'


def slugify(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()
    return re.sub(r'[^a-z0-9]+', '-', s.lower()).strip('-')


def q(s):
    return 'null' if s is None else "'" + s.replace("'", "''") + "'"


def main():
    conf, cat, out = sys.argv[1:4]
    lotto = next((int(a.split('=')[1]) for a in sys.argv[4:] if a.startswith('--lotto=')), 2000)
    os.makedirs(out, exist_ok=True)
    taxa = {t['id']: t for t in leggi(os.path.join(cat, 'taxa.jsonl'))}
    per_nome = collections.defaultdict(set)
    for t in taxa.values():
        per_nome[norm_nome(t['nome_scientifico'])].add(t['id'])
    genere = lambda nome: norm_nome(nome).replace('x ', '').split(' ')[0]
    per_genere = collections.defaultdict(set)
    for c in leggi(os.path.join(cat, 'cultivar.jsonl')):
        if c['taxon_id'] in taxa:
            per_genere[genere(taxa[c['taxon_id']]['nome_scientifico'])].add(norm_ep(c['epiteto']))
    slugs = set(open(os.path.join(cat, 'cultivar_slug.txt'), encoding='utf-8').read().split())

    righe, scartate, viste = [], [], set()
    for l in open(conf, encoding='utf-8'):
        rhs_id, tipo, esito, titolo, _ = l.rstrip('\n').split('\t')
        if esito != 'cultivar_assente':
            continue
        r = leggi_titolo(titolo)
        ep = r['epiteto']
        if not ep or SERIE_MISCUGLIO.search(titolo) or r['serie']:
            scartate.append((rhs_id, titolo, 'serie, miscuglio o senza epiteto')); continue
        parole = norm_nome(r['base']).split(' ')
        ids = set()
        for n in (len(parole), 3, 2, 1):
            ids = per_nome.get(' '.join(parole[:n]), set())
            if ids:
                break
        if len(ids) > 1:  # un accettato vince sugli omonimi (regola della fase 3)
            accettati = {i for i in ids if taxa[i].get('stato') == 'accepted'}
            if len(accettati) == 1:
                ids = accettati
        if len(ids) != 1:
            scartate.append((rhs_id, titolo, 'nome del taxon ambiguo' if ids else 'taxon non trovato')); continue
        tid = next(iter(ids))
        g = genere(taxa[tid]['nome_scientifico'])
        if norm_ep(ep) in per_genere[g]:
            scartate.append((rhs_id, titolo, 'epiteto già nel genere sotto un\'altra specie')); continue
        chiave = (g, norm_ep(ep))
        if chiave in viste:
            scartate.append((rhs_id, titolo, 'doppione nella lista')); continue
        viste.add(chiave)
        base_slug = slugify(taxa[tid]['nome_scientifico'] + ' ' + ep)
        slug, k = base_slug, 2
        while slug in slugs:
            slug, k = f'{base_slug}-{k}', k + 1
        slugs.add(slug)
        comm = ' | '.join(r['commerciale']) or None
        fonte = f"RHS (rhs.org.uk) — pagina {rhs_id}, controllo del {DATA}"
        righe.append((slug, tid, ep, r['gruppo'], comm, fonte))

    for i in range(0, len(righe), lotto):
        with open(os.path.join(out, f'cultivar_nuove_{i // lotto + 1:02d}.sql'), 'w', encoding='utf-8') as f:
            f.write('-- Cultivar nuove da RHS, controllo del %s (scripts/rhs-import/cultivar_nuove.py)\n' % DATA)
            f.write('insert into public.cultivar (slug, taxon_id, categoria, epiteto, gruppo, nome_commerciale, fonti) values\n')
            f.write(',\n'.join(f"({q(s)}, '{t}', 'cultivar', {q(e)}, {q(g)}, {q(c)}, array[{q(fo)}])"
                              for s, t, e, g, c, fo in righe[i:i + lotto]))
            f.write('\non conflict (slug) do nothing;\n')
    with open(os.path.join(out, 'rollback_cultivar_nuove.sql'), 'w', encoding='utf-8') as f:
        f.write('-- Rollback delle cultivar nuove del %s: si rifiuta se una scheda o una pianta punta a una di esse\n' % DATA)
        f.write("do $$ begin if exists (select 1 from public.cultivar c where c.fonti[1] like 'RHS (rhs.org.uk) — pagina %% controllo del " + DATA + "' and (exists (select 1 from public.schede s where s.cultivar_id = c.id) or exists (select 1 from public.piante p where p.cultivar_id = c.id))) then raise exception 'cultivar in uso: rollback rifiutato'; end if; end $$;\n")
        f.write("delete from public.cultivar where fonti[1] like 'RHS (rhs.org.uk) — pagina % controllo del " + DATA + "';\n")
    with open(os.path.join(out, 'scartate.tsv'), 'w', encoding='utf-8') as f:
        for x in scartate:
            f.write('\t'.join(x) + '\n')
    print('nuove', len(righe), 'scartate', collections.Counter(m for _, _, m in scartate))


if __name__ == '__main__':
    main()
