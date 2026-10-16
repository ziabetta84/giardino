-- Fase 3: applica alle proposte (col.mappa_proposte, copia locale) le decisioni dell'utente sull'elenco da rivedere.
-- Standard input: TSV numero, vecchio_slug, decisione (si | no | col:<col_id di COL>), una riga per ogni caso di
-- col.mappa_revisione. si = proposta confermata (esito invariato, nota con la conferma); no = vale l'alternativa;
-- col:<id> = il nome indicato dall'utente. Si rifiuta se manca una decisione o se un numero non corrisponde allo slug.
-- Vale solo per le proposte ancora da rivedere: per cambiare una decisione si rigenerano proposte ed elenco.
set statement_timeout = 0;
create temp table decisioni (numero int primary key, vecchio_slug text not null, decisione text not null);
\copy decisioni from pstdin with (format csv, delimiter E'\t', header)
do $$
declare n bigint;
begin
  select count(*) into n from col.mappa_revisione v left join decisioni d on d.numero = v.numero where d.numero is null;
  if n > 0 then raise exception 'decisioni mancanti: %', n; end if;
  select count(*) into n from decisioni d left join col.mappa_revisione v on v.numero = d.numero and v.vecchio_slug = d.vecchio_slug
   where v.numero is null;
  if n > 0 then raise exception 'decisioni che non corrispondono all''elenco (numero o slug): %', n; end if;
  select count(*) into n from decisioni where decisione !~ '^(si|no|col:[A-Za-z0-9]+)$';
  if n > 0 then raise exception 'decisioni non valide: %', n; end if;
  select count(*) into n from decisioni d where d.decisione like 'col:%'
     and not exists (select 1 from col.nome_uso u where u.id = substr(d.decisione, 5));
  if n > 0 then raise exception 'col_id indicati che non esistono in COL: %', n; end if;
end $$;
update col.mappa_proposte p set
  nota = p.nota || ' — confermato dall''utente il ' || to_char(current_date, 'DD/MM/YYYY'), da_rivedere = false,
  -- una proposta per un nome «non trovato» (Cetraria islandica fuori da Plantae), confermata, è una decisione dell'utente
  esito = case when p.esito = 'non trovato' and p.col_id is not null then 'deciso dall''utente' else p.esito end
  from col.mappa_revisione v join decisioni d on d.numero = v.numero
 where p.vecchia_specie_id = v.vecchia_specie_id and p.da_rivedere and d.decisione = 'si';
update col.mappa_proposte p set
  col_id = v.alt_col_id, taxon_locale = null, famiglia_locale = null, esito = v.alt_esito, da_rivedere = false,
  nota = 'proposta «' || v.proposta || '» respinta dall''utente il ' || to_char(current_date, 'DD/MM/YYYY') || ': ' || v.alternativa
  from col.mappa_revisione v join decisioni d on d.numero = v.numero
 where p.vecchia_specie_id = v.vecchia_specie_id and p.da_rivedere and d.decisione = 'no';
update col.mappa_proposte p set
  col_id = substr(d.decisione, 5), taxon_locale = null, famiglia_locale = null, esito = 'deciso dall''utente', da_rivedere = false,
  nota = 'indicato dall''utente il ' || to_char(current_date, 'DD/MM/YYYY') || ': ' || u.nome || coalesce(' ' || u.autore, '')
  from col.mappa_revisione v join decisioni d on d.numero = v.numero join col.nome_uso u on u.id = substr(d.decisione, 5)
 where p.vecchia_specie_id = v.vecchia_specie_id and p.da_rivedere and d.decisione like 'col:%';
\pset tuples_only on
\pset format unaligned
select 'decisioni ' || count(*) || ' (si ' || count(*) filter (where decisione = 'si') || ', no ' || count(*) filter (where decisione = 'no')
       || ', nome indicato ' || count(*) filter (where decisione like 'col:%') || ')' from decisioni;
select 'ancora da rivedere ' || count(*) from col.mappa_proposte where da_rivedere;
