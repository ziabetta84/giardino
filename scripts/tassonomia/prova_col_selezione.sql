-- Prove della selezione della fase 2 (col_selezione.sql), sulla copia locale. Errore al primo controllo che fallisce.
-- I numeri valgono per COL26.9 XR e per specie e generi del 15/10/2026 (fase 2, misure del prototipo).
do $$
declare
  n bigint;
begin
  if col.chiave('Laburnum x watereri') <> 'Laburnum watereri' or col.chiave('Petunia spp.') <> 'Petunia'
     or col.chiave('x Fatshedera lizei') <> 'Fatshedera lizei' or col.chiave('×Fatshedera') <> 'Fatshedera'
     or col.chiave('× Burrageara') <> 'Burrageara' or col.chiave('Mentha × piperita') <> 'Mentha piperita'
     or col.chiave('  Rosa   canina ') <> 'Rosa canina'
     or col.chiave('Apium graveolens var. dulce') <> 'Apium graveolens var. dulce' then
    raise exception 'col.chiave non normalizza come atteso';
  end if;
  -- i segnaposto di COL "Genere spp" (rango species, accettati sotto il genere) non sono specie: non entrano, e
  -- nemmeno i sinonimi che puntano a loro
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id where u.nome ~ '\sspp?\.?\s*$';
  if n > 0 then raise exception 'segnaposto "spp" di COL nella selezione: %', n; end if;
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id
    join col.nome_uso p on p.id = u.parent_id where p.nome ~ '\sspp?\.?\s*$';
  if n > 0 then raise exception 'righe della selezione che puntano a un segnaposto "spp": %', n; end if;
  select count(*) into n from col.selezione;
  if n <> 234514 then raise exception 'selezione: % righe (attese 234514)', n; end if;
  -- chiusura: il padre di ogni accettato e l'accettato di ogni sinonimo sono nella selezione
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id
   where u.parent_id <> '' and not exists (select 1 from col.selezione p where p.col_id = u.parent_id);
  if n > 0 then raise exception 'selezione non chiusa: % righe con il padre o l''accettato fuori', n; end if;
  -- solo piante: gli accettati sono in Plantae, tranne Eukaryota e Plantae stessa (il regno vuoto in COL)
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id
   where u.status in ('accepted', 'provisionally accepted') and u.regno <> 'Plantae' and u.nome not in ('Eukaryota', 'Plantae');
  if n > 0 then raise exception 'accettati fuori da Plantae: %', n; end if;
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id where u.nome = 'Prunella';
  if n <> 1 then raise exception 'Prunella: % righe (attesa 1, il genere delle piante)', n; end if;
  -- misapplied solo se corrispondono direttamente a un nostro nome
  select count(*) into n from col.selezione s join col.nome_uso u on u.id = s.col_id
   where u.status = 'misapplied' and not exists (select 1 from col.nostri x where x.chiave = col.chiave(u.nome));
  if n > 0 then raise exception 'misapplied senza corrispondenza diretta: %', n; end if;
  perform 1 from col.selezione s join col.nome_uso u on u.id = s.col_id where u.nome = 'Lycopersicon esculentum' and u.status = 'synonym';
  if not found then raise exception 'manca il sinonimo Lycopersicon esculentum'; end if;
  perform 1 from col.selezione s join col.nome_uso u on u.id = s.col_id where u.nome = 'Fatshedera' and u.rango = 'genus';
  if not found then raise exception 'manca il genere Fatshedera'; end if;
  select count(*) - count(distinct id) into n from col.selezione;
  if n > 0 then raise exception 'chiavi uuid doppie: %', n; end if;
  raise notice 'SELEZIONE CORRETTA: % righe', (select count(*) from col.selezione);
end $$;
