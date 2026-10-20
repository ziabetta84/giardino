-- Prove della fase 7 sulla copia locale, con la migration applicata: la colonna non c'è più, gli slug sono tutti in
-- piante_vecchie_specie (confronto con la fotografia prima, tabella prima_fase7 creata da prova_fase7.sh), la tabella
-- non è leggibile dai client, le funzioni del catalogo funzionano. Errore al primo controllo che fallisce.
do $$
declare n bigint;
begin
  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'piante' and column_name = 'specie') then
    raise exception 'piante.specie c''è ancora';
  end if;
  select count(*) into n from public.prima_fase7 a full join public.piante_vecchie_specie v on v.pianta_id = a.id
   where a.id is null or v.pianta_id is null or a.specie is distinct from v.specie;
  if n > 0 then raise exception 'slug salvati diversi da quelli di prima: %', n; end if;
  if (select count(*) from public.piante_vecchie_specie) <> 122 then raise exception 'slug salvati: % invece di 122', (select count(*) from public.piante_vecchie_specie); end if;
  if (select count(*) from jsonb_object_keys(public.catalogo_mie_piante())) = 0 then raise exception 'catalogo_mie_piante vuota'; end if;
  execute 'set local role anon';
  begin
    perform 1 from public.piante_vecchie_specie limit 1;
    raise exception 'piante_vecchie_specie leggibile con il ruolo pubblico';
  exception when insufficient_privilege then null;
  end;
  if not exists (select 1 from jsonb_array_elements(public.cerca_catalogo('rosmarino')) e where e ->> 'specie' = 'Salvia rosmarinus') then
    raise exception 'ricerca pubblica non funziona';
  end if;
  execute 'reset role';
  raise notice 'PROVA FASE 7 OK';
end $$;
