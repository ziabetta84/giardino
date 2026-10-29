# Scrive la migration con le foto scelte da Roberta sulla pagina (dati/scelte.json) e il suo rollback.
#   python3 scripts/immagini/migrazione.py
# Voce di specie o genere: cambia «immagine» della scheda mostrata del suo livello (dati/immagini_prima.json tiene
# il valore di prima, letto dal reale il 29/10/2026, e la migration si ferma se nel frattempo è cambiato).
# Voce di cultivar senza scheda: aggiunge una scheda mostrata con la sola immagine, così le altre informazioni
# continuano a venire dalla specie.
import json, os, re, urllib.parse

QUI = os.path.dirname(os.path.abspath(__file__))
DATI = os.path.join(QUI, 'dati')
RADICE = os.path.dirname(os.path.dirname(QUI))
NOME = '20261029120000_immagini_scelte'
NOTA = 'immagine scelta da Roberta il 29/10/2026 (scripts/immagini)'
FONTE = 'Wikimedia Commons — immagine scelta da Roberta (29/10/2026)'

# scheda mostrata del livello della voce (catalogo.livelli, ord 0), letta dal reale il 29/10/2026
SCHEDE = {
    't:12a40c77-38f2-4981-a1a1-8c44cb170701': '66114206-868e-432e-af86-1f9ab870e800',  # Calibrachoa
    't:1d56ca82-978c-410b-bd15-368745c6d701': 'c837e0fd-9ffa-45af-a6fa-f64c5288ec3c',  # Spiraea × arguta
    't:3c85ee24-79c8-4553-ae34-9e8db65bbd4e': '8ba1c2fd-ab2a-497f-baaf-e5477c3d53f6',  # Thymus × citriodorus
    't:4ae9ea82-18f3-4581-b955-a1c050db5393': '7d32179f-ebee-4780-ba32-c7dd08c082b0',  # Allium ascalonicum
    't:5f4ff97b-7f8f-49e7-b81b-d906705b5e04': '11d3bbb7-4ead-40a1-8bcd-a51bd718a767',  # Laurus nobilis
    't:86575acb-9e7b-4b57-bf4e-56b32d7d2692': '394e790d-4b52-442a-bbb7-49eb0b478c5c',  # Echeveria
    't:8af24d1e-a329-4d63-8d54-0f8e3b53ddff': '4f1f39fc-bb35-48cc-b8a3-89d60c52c50e',  # Olea europaea
    't:8b75d73a-1b08-4246-94e8-557b02d69686': 'c3dde517-8cc6-4386-9178-1028d046f5b2',  # Prunus persica
    't:9beef9ff-7c50-421d-b73e-79441f5f8110': 'd8bc3c75-dbb0-4531-b50f-c37cfbe95c57',  # Pisum sativum → Lathyrus oleraceus
    't:a67a91e6-c6e7-48a6-bc2a-b8f4de4174d3': 'c120594f-a819-40f4-aef7-c21530f2c36a',  # Dianthus
    't:ab27a9e4-2636-4bf5-a120-f12f61179960': '12186d62-26d2-4c8b-b6c0-933b8b097d42',  # Lampranthus
    't:b335f317-18b3-4c11-ae7f-b79e1a16a414': 'b34d5ab4-3274-401d-9ba5-1a27cee7431c',  # Aquilegia
    't:b6ab2fba-d8ac-4bc3-9d44-98709e06d483': '9d55f737-0638-4c71-b705-4b4ff7feef30',  # Daucus carota
    't:bf4c9976-f912-4a37-b90d-8adf9906a252': 'a030ad7d-1ac7-46ca-a9a2-c5ef0a508e44',  # Gasteria
    't:c0c73a46-790c-4c1e-9146-0c80ae341306': '57cec4ab-7ed8-407b-92b8-5275f97f0ce2',  # Ocimum basilicum
    't:d3bb1b04-5f0d-4d6f-bc10-0c74d561ad87': 'd613d76e-9e5f-4c00-ac67-e016a6ae80c2',  # Sisyrinchium californicum
    't:d8fb0d20-5faa-48ad-8355-46a260615c4a': 'd4c17fd9-10b9-4ae7-870a-27fad30c9f65',  # Narcissus
    't:ebddf5a2-e862-4f43-a681-514a5c1d5a59': '199b52cd-8974-4d38-af42-dca5898de906',  # Pelargonium zonale
    't:f1a62688-3a0a-442a-8d4a-a7a346ee6e80': '8eb4cb7a-7e7c-41e8-8193-5e76cefc28a4',  # Persea americana
    't:fc703d55-e3e3-47e4-8da8-6935e623e98a': '68c8cea2-c46a-44db-b71c-da53bd86e0d5',  # Plumbago
}


def lit(x):
    return "'" + x.replace("'", "''") + "'"


def immagine(f):
    autore = re.sub(r'^(Photo by |User:)', '', f['autore']).strip()
    return {'url': f['url'].split('?')[0], 'licenza': f['licenza'], 'licenza_url': f.get('licenza_url') or '',
            'attribuzione': autore, 'fonte_pagina': urllib.parse.unquote(f['pagina'].split('?')[0]), 'verificata': True}


def righe(lista):
    # la virgola va prima del commento con il nome della voce
    return '\n'.join(r + (',' if i < len(lista) - 1 else '') + '  -- ' + nome for i, (r, nome) in enumerate(lista))


def main():
    voci = json.load(open(os.path.join(DATI, 'voci.json')))
    scelte = json.load(open(os.path.join(DATI, 'scelte.json')))
    candidati = json.load(open(os.path.join(DATI, 'candidati.json')))
    prima = json.load(open(os.path.join(DATI, 'immagini_prima.json')))
    agg, nuove = [], []
    for k, s in sorted(scelte.items()):
        if s['scelta'] in ('attuale', 'nessuna'):
            continue
        f = next(f for f in candidati[k] if f['url'].split('?')[0] == s['scelta'])
        img = json.dumps(immagine(f), ensure_ascii=False)
        nome = voci[k]['nome'].replace('\n', ' ')
        if k.startswith('t:'):
            sid = SCHEDE[k]
            vecchia = 'null' if prima[sid] is None else lit(json.dumps(prima[sid], ensure_ascii=False)) + '::jsonb'
            agg.append((f"    ({lit(sid)}::uuid, {vecchia}, {lit(img)}::jsonb)", nome))
        else:
            nuove.append((f"    ({lit(k[2:])}::uuid, {lit(img)}::jsonb)", nome))
    sql = f"""-- Foto del catalogo scelte da Roberta il 29/10/2026 (pagina privata delle candidate, scripts/immagini/).
-- Generata da scripts/immagini/migrazione.py: non modificare a mano.
-- {len(agg)} schede mostrate di specie e generi cambiano «immagine»; {len(nuove)} cultivar senza scheda ne ricevono
-- una mostrata con la sola immagine (le altre informazioni continuano a venire dalla specie).
-- Si ferma se una scheda ha un'immagine diversa da quella letta il 29/10 o se una cultivar ha già una scheda mostrata.
-- Rollback: scripts/immagini/rollback_{NOME}.sql

do $$
declare n int;
begin
  update public.schede s set immagine = v.nuova
  from (values
{righe(agg)}
  ) as v(id, vecchia, nuova)
  where s.id = v.id and s.mostrata and s.immagine is not distinct from v.vecchia;
  get diagnostics n = row_count;
  if n <> {len(agg)} then
    raise exception 'schede aggiornate: % invece di {len(agg)} (immagine cambiata dopo il 29/10?)', n;
  end if;

  insert into public.schede (cultivar_id, fonti, immagine, mostrata, nota)
  select v.cultivar_id, array[{lit(FONTE)}], v.immagine, true, {lit(NOTA)}
  from (values
{righe(nuove)}
  ) as v(cultivar_id, immagine)
  where not exists (select 1 from public.schede s where s.cultivar_id = v.cultivar_id and s.mostrata);
  get diagnostics n = row_count;
  if n <> {len(nuove)} then
    raise exception 'schede di cultivar aggiunte: % invece di {len(nuove)}', n;
  end if;
end $$;
"""
    vecchie = [f"    ({lit(SCHEDE[k])}::uuid, " + ('null' if prima[SCHEDE[k]] is None else lit(json.dumps(prima[SCHEDE[k]], ensure_ascii=False)) + '::jsonb') + ')'
               for k, s in sorted(scelte.items()) if k.startswith('t:') and s['scelta'] not in ('attuale', 'nessuna')]
    rb = f"""-- Rollback di supabase/migrations/{NOME}.sql: rimette le immagini di prima e toglie le schede di cultivar aggiunte.
-- psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/immagini/rollback_{NOME}.sql
-- Generato da scripts/immagini/migrazione.py.

update public.schede s set immagine = v.vecchia
from (values
{(','+chr(10)).join(vecchie)}
) as v(id, vecchia)
where s.id = v.id;

delete from public.schede
where nota = {lit(NOTA)} and fonti = array[{lit(FONTE)}]
  and taxon_id is null and descrizione is null and esigenze is null and manutenzione is null;
"""
    open(os.path.join(RADICE, 'supabase', 'migrations', NOME + '.sql'), 'w').write(sql)
    open(os.path.join(QUI, f'rollback_{NOME}.sql'), 'w').write(rb)
    print(len(agg), 'aggiornate,', len(nuove), 'nuove')


if __name__ == '__main__':
    main()
