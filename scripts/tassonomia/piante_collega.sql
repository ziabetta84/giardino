-- Fase 5 del modello tassonomico: collega ognuna delle piante dell'utente al nuovo catalogo (piante.taxon_id oppure
-- piante.cultivar_id) come da dati/fase5_piante.tsv, approvato dall'utente il 20/10/2026 dalla pagina privata
-- https://claude.ai/artifact/GD8Tsdzinhbba7osCwM2ao («approvo tutte»), e corregge l'epiteto 'Piccante Calabresé' in
-- 'Piccante Calabrese' (refuso del titolo RHS, correzione chiesta dall'utente; ICNCP: si corregge l'ortografia).
-- Le piante puntano al nome trovato in mappa_specie, anche sinonimo (l'app risale all'accettato), oppure alla cultivar.
-- Rifiutato se il file non copre esattamente le piante di oggi o se una pianta è già collegata a qualcos'altro; si può
-- rilanciare (le piante già collegate come nel file restano così). Tocca solo piante.taxon_id/cultivar_id e
-- quell'epiteto. Comando (dalla radice del repository):
--   psql "$URL" -X -1 -v ON_ERROR_STOP=1 -f scripts/tassonomia/piante_collega.sql
set local statement_timeout = '1min';
create temp table fase5 (pianta text primary key, vecchio_slug text not null, taxon_id uuid, cultivar_id uuid,
                         destinazione text not null, motivo text not null, check (num_nonnulls(taxon_id, cultivar_id) = 1));
\copy fase5 from 'scripts/tassonomia/dati/fase5_piante.tsv' with (format text, header true)
do $$
declare n bigint;
begin
  select count(*) into n from public.piante p full join fase5 f on f.pianta = p.id where p.id is null or f.pianta is null;
  if n > 0 then raise exception 'Collegamento rifiutato: il file e le piante di oggi non coincidono (% piante in più o in meno)', n; end if;
  select count(*) into n from public.piante p join fase5 f on f.pianta = p.id where p.specie <> f.vecchio_slug;
  if n > 0 then raise exception 'Collegamento rifiutato: % piante hanno cambiato specie dopo la revisione', n; end if;
  select count(*) into n from public.piante p join fase5 f on f.pianta = p.id
   where (p.taxon_id is not null or p.cultivar_id is not null)
     and (p.taxon_id is distinct from f.taxon_id or p.cultivar_id is distinct from f.cultivar_id);
  if n > 0 then raise exception 'Collegamento rifiutato: % piante sono già collegate a qualcos''altro', n; end if;
end $$;
update public.piante p set taxon_id = f.taxon_id, cultivar_id = f.cultivar_id
  from fase5 f where f.pianta = p.id and (p.taxon_id is distinct from f.taxon_id or p.cultivar_id is distinct from f.cultivar_id);
update public.cultivar set epiteto = 'Piccante Calabrese'
 where slug = 'capsicum-annuum-piccante-calabrese' and epiteto = 'Piccante Calabresé';
do $$
declare n bigint;
begin
  select count(*) into n from public.piante p join fase5 f on f.pianta = p.id
   where p.taxon_id is not distinct from f.taxon_id and p.cultivar_id is not distinct from f.cultivar_id;
  if n <> (select count(*) from fase5) then raise exception 'collegamento incompleto: % piante su %', n, (select count(*) from fase5); end if;
  if not exists (select 1 from public.cultivar where slug = 'capsicum-annuum-piccante-calabrese' and epiteto = 'Piccante Calabrese') then
    raise exception 'epiteto Piccante Calabrese non corretto';
  end if;
  raise notice 'PIANTE COLLEGATE: % (su taxon %, su cultivar %); epiteto Piccante Calabrese corretto', n,
    (select count(*) from fase5 where taxon_id is not null), (select count(*) from fase5 where cultivar_id is not null);
end $$;
