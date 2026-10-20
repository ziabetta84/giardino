-- Prove delle funzioni del catalogo (fase 6) sulla copia locale, con la migration applicata e le piante collegate come
-- dati/fase5_piante.tsv. Errore al primo controllo che fallisce. Lancio: prova_fase6.sh.
create temp table attesi (pianta text primary key, nome text not null);
\copy attesi from 'scripts/tassonomia/dati/fase6_nomi_attesi.tsv' with (format text, header true)
do $$
declare
  n bigint; v jsonb; r record; k text; t0 timestamptz;
begin
  -- jsonb vuoti
  if not (catalogo.vuoto(null) and catalogo.vuoto('null') and catalogo.vuoto('{}') and catalogo.vuoto('[]')
          and catalogo.vuoto('""') and catalogo.vuoto('{"a": null, "b": {"c": null, "d": []}}')) then
    raise exception 'vuoto: un valore vuoto non è riconosciuto';
  end if;
  if catalogo.vuoto('{"a": 0}') or catalogo.vuoto('"x"') or catalogo.vuoto('[false]') then
    raise exception 'vuoto: un valore pieno è preso per vuoto';
  end if;
  -- ogni pianta ha la sua voce, con il nome approvato nella fase 5
  select count(*) into n from public.piante p
   where catalogo.voce(case when p.cultivar_id is not null then 'c:' || p.cultivar_id else 't:' || p.taxon_id end) is null;
  if n > 0 then raise exception 'piante senza voce: %', n; end if;
  for r in select p.id, a.nome atteso,
                  catalogo.voce(case when p.cultivar_id is not null then 'c:' || p.cultivar_id else 't:' || p.taxon_id end) ->> 'nome' trovato
             from public.piante p join attesi a on a.pianta = p.id loop
    if r.trovato is distinct from r.atteso then raise exception 'pianta %: nome «%» invece di «%»', r.id, r.trovato, r.atteso; end if;
  end loop;
  select count(*) into n from public.piante p join attesi a on a.pianta = p.id;
  if n <> 122 then raise exception 'nomi attesi confrontati: % invece di 122', n; end if;
  -- catalogo_mie_piante (qui senza RLS: tutte le piante) dà una voce per chiave
  select count(*) into n from jsonb_object_keys(public.catalogo_mie_piante());
  if n <> (select count(distinct coalesce(cultivar_id, taxon_id)) from public.piante) then
    raise exception 'catalogo_mie_piante: % voci', n;
  end if;
  -- sinonimo: nome e scheda dell'accettato, e il nome con cui la pianta era conosciuta
  v := catalogo.voce('t:' || (select id from public.taxa where nome_scientifico = 'Gaura lindheimeri' and stato = 'synonym' limit 1));
  if v ->> 'specie' <> 'Oenothera lindheimeri' or v ->> 'nome_noto' <> 'Gaura lindheimeri' then
    raise exception 'sinonimo: specie %, nome_noto %', v ->> 'specie', v ->> 'nome_noto';
  end if;
  -- cultivar su un sinonimo che porta a un autonimo: nome sulla specie accettata, e il nome con cui era conosciuta
  v := catalogo.voce('c:' || (select id from public.cultivar where slug = 'sedum-spurium-tricolor'));
  if v ->> 'specie' <> 'Phedimus spurius ''Tricolor''' or v ->> 'nome_noto' <> 'Sedum spurium ''Tricolor''' then
    raise exception 'cultivar su sinonimo: specie %, nome_noto %', v ->> 'specie', v ->> 'nome_noto';
  end if;
  -- cultivar senza scheda propria: i campi vengono dal taxon, con il livello indicato
  select c.id into k from public.cultivar c where c.slug = 'carex-oshimensis-evergold';
  v := catalogo.voce('c:' || k);
  if exists (select 1 from public.schede where cultivar_id = k::uuid and mostrata) then
    raise exception 'la prova presuppone che carex-oshimensis-evergold non abbia una scheda propria';
  end if;
  if v ->> 'descrizione' is null or v #>> '{livelli,descrizione,rango}' <> 'species'
     or v #>> '{livelli,descrizione,nome}' <> 'Carex oshimensis' then
    raise exception 'eredità della cultivar: %', v -> 'livelli';
  end if;
  if v ->> 'tipo' <> 'cultivar' or v ->> 'specie' <> 'Carex oshimensis ''Evergold''' then
    raise exception 'cultivar: tipo %, specie %', v ->> 'tipo', v ->> 'specie';
  end if;
  -- un taxon con la scheda propria non indica livelli per la descrizione
  v := catalogo.voce('t:' || (select taxon_id from public.schede where mostrata and taxon_id is not null and descrizione is not null limit 1));
  if v -> 'livelli' ? 'descrizione' then raise exception 'livello indicato per una descrizione propria'; end if;
  -- schede non idonee: mai usate, nemmeno quando sono l'unica scheda del taxon
  select s.taxon_id, s.descrizione into r from public.schede s
   where s.taxon_id is not null and s.descrizione is not null
     and not exists (select 1 from public.schede m where m.taxon_id = s.taxon_id and m.mostrata) limit 1;
  v := catalogo.voce('t:' || r.taxon_id);
  if v ->> 'descrizione' is not distinct from r.descrizione and not (v -> 'livelli' ? 'descrizione') then
    raise exception 'scheda non idonea usata come propria per %', r.taxon_id;
  end if;
  -- un genere senza nessuna scheda: voce con il nome e senza campi
  v := catalogo.voce('t:' || (select t.id from public.taxa t where t.rango = 'genus' and t.stato = 'accepted'
                                and not exists (select 1 from public.schede s where s.taxon_id = t.id) limit 1));
  if v ->> 'nome' is null or v ? 'descrizione' then raise exception 'genere senza schede: %', v; end if;
  -- ambiguità (decisione 22): stesso nome su genere e specie non è ambiguo; su un'altra linea sì
  select c.id into k from public.cultivar c join public.taxa t on t.id = c.taxon_id
   where t.nome_scientifico = 'Lavandula angustifolia' and c.categoria = 'cultivar' order by c.slug limit 1;
  v := catalogo.voce('c:' || k);
  if v ->> 'nome' not like 'Lavanda ''%''' then raise exception 'lavanda: %', v ->> 'nome'; end if;
  begin
    insert into public.nomi_comuni (taxon_id, lingua, nome, preferito, fonti)
    select t.id, 'it', 'Lavanda', true, '{prova}' from public.taxa t
     where t.nome_scientifico = 'Rosa canina' and t.stato = 'accepted'
       and not exists (select 1 from public.nomi_comuni n where n.taxon_id = t.id and n.lingua = 'it' and n.preferito);
    if not found then raise exception 'la prova di ambiguità presuppone Rosa canina senza preferito'; end if;
    v := catalogo.voce('c:' || k);
    if v ->> 'nome' not like 'Lavandula angustifolia ''%''' then raise exception 'ambiguo non riconosciuto: %', v ->> 'nome'; end if;
    raise sqlstate 'P0099';
  exception when sqlstate 'P0099' then null;
  end;
  -- Gruppo come categoria
  v := catalogo.voce('c:' || (select id from public.cultivar where slug = 'brachyglottis-dunedin-hybrids'));
  if v ->> 'nome' not like '% Dunedin Group' or v ->> 'categoria' <> 'gruppo' then raise exception 'gruppo: %', v ->> 'nome'; end if;
  -- ricerca
  for r in select * from (values
      ('rosmarino', 't', 'Salvia rosmarinus', null::text),
      ('Rosmarinus officinalis', 't', 'Salvia rosmarinus', 'Rosmarinus officinalis'),
      ('evergold', 'c', 'Carex oshimensis ''Evergold''', null),
      ('‘Evergold’', 'c', 'Carex oshimensis ''Evergold''', null),
      ('carex evergold', 'c', 'Carex oshimensis ''Evergold''', null)
    ) x(q, tipo, specie, via) loop
    select count(*) into n from jsonb_array_elements(public.cerca_catalogo(r.q)) e
     where e ->> 'specie' = r.specie and left(e ->> 'chiave', 1) = r.tipo and (r.via is null or e ->> 'via' = r.via);
    if n <> 1 then raise exception 'ricerca «%»: % risultati per %', r.q, n, r.specie; end if;
  end loop;
  -- revisione: i nomi esatti dei generi grandi e i nomi con l'apostrofo si trovano, la ricerca su due parole è veloce
  for r in select * from (values
      ('rosa', 'specie', 'Rosa'), ('acer', 'specie', 'Acer'), ('salvia', 'specie', 'Salvia'), ('ribes', 'specie', 'Ribes'),
      ('pino', 'nome', 'Pino'), ('Lavanda dell''Egitto', 'nome', 'Lavanda dell''Egitto'),
      ('lavanda dell’egitto', 'nome', 'Lavanda dell''Egitto'), ('edera glacier', 'specie', 'Hedera helix ''Glacier''')
    ) x(q, campo, valore) loop
    select count(*) into n from jsonb_array_elements(public.cerca_catalogo(r.q)) e where e ->> r.campo = r.valore;
    if n < 1 then raise exception 'ricerca «%»: manca %', r.q, r.valore; end if;
  end loop;
  foreach k in array array['qx a', 'rosmarino b', 'basilico g'] loop
    t0 := clock_timestamp();
    perform public.cerca_catalogo(k);
    if clock_timestamp() - t0 > interval '700 milliseconds' then raise exception 'ricerca «%» lenta: %', k, clock_timestamp() - t0; end if;
  end loop;
  if jsonb_array_length(public.cerca_catalogo('%')) <> 0 or jsonb_array_length(public.cerca_catalogo('a')) <> 0
     or jsonb_array_length(public.cerca_catalogo('')) <> 0 or jsonb_array_length(public.cerca_catalogo(null)) <> 0 then
    raise exception 'ricerca troppo corta o con soli caratteri speciali: risultati non vuoti';
  end if;
  perform public.cerca_catalogo('a_b%c');
  t0 := clock_timestamp();
  if jsonb_array_length(public.cerca_catalogo('rosa')) not between 1 and 30 then raise exception 'ricerca «rosa»: troppi o nessun risultato'; end if;
  if clock_timestamp() - t0 > interval '3 seconds' then raise exception 'ricerca «rosa» lenta: %', clock_timestamp() - t0; end if;
  if (select count(*) from jsonb_object_keys(public.catalogo_voci(array(select 't:' || id from public.taxa limit 300)))) > 200 then
    raise exception 'catalogo_voci accetta più di 200 chiavi';
  end if;
  if public.catalogo_voci(array['x', 't:non-uuid', 'c:00000000-0000-0000-0000-000000000000']) <> '{}' then
    raise exception 'chiavi non valide: risultato non vuoto';
  end if;
  -- permessi: con il ruolo pubblico le funzioni girano (non leggono colonne interne)
  execute 'set local role anon';
  perform public.catalogo_voci(array['c:' || k]);
  perform public.cerca_catalogo('evergold');
  execute 'reset role';
  raise notice 'PROVA CATALOGO OK';
end $$;
