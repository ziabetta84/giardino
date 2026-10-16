-- Prove dell'abbinamento della fase 3 (mappa_righe, mappa_esatti, mappa_altri, mappa_proposte), sulla copia locale.
-- Errore al primo controllo che fallisce. Numeri e casi valgono per COL26.9 XR e specie del 15/10/2026.
do $$
declare
  n bigint;
  atteso record;
begin
  select count(*) into n from col.mappa_righe;
  if n <> 15713 then raise exception 'righe da abbinare: % (attese 15713: 15678 di specie + 35 dai rollback)', n; end if;
  select count(*) into n from col.mappa_proposte;
  if n <> 15713 then raise exception 'proposte: % su 15713', n; end if;
  select count(*) into n from col.mappa_proposte where col_id is null and taxon_locale is null and esito <> 'non trovato';
  if n > 0 then raise exception 'proposte senza taxon: %', n; end if;
  -- casi verificati a mano nella ricerca (slug, origine, esito atteso, nome del taxon proposto)
  for atteso in select * from (values
      ('pomodoro', 'specie', 'esatto', 'Solanum lycopersicum'),
      ('solanum-lycopersicum', 'rollback', 'esatto', 'Solanum lycopersicum'),
      ('rosmarino', 'specie', 'sinonimo', 'Rosmarinus officinalis'),
      ('sansevieria', 'specie', 'sinonimo', 'Sansevieria'),
      ('helleborus', 'specie', 'esatto', 'Helleborus'),
      ('pinus-sylvestris', 'specie', 'esatto', 'Pinus sylvestris'),
      ('galium-palustre', 'specie', 'ambiguo', 'Galium palustre'),
      ('sedum-hybridum', 'specie', 'ambiguo', 'Sedum hybridum'),
      ('physalis-alkekengi', 'specie', 'ambiguo', 'Physalidinae'),
      ('albizzia', 'specie', 'variante', 'Albizzia'),
      ('peperoncino', 'specie', 'variante', 'Capsicum annuum'),
      ('pianta-delle-monete', 'specie', 'variante', 'Pilea peperomioides'),
      ('sedum-morganianum', 'specie', 'variante', 'Sedum morganianum'),
      ('ferocactus', 'specie', 'rango superiore', 'Ferocactus'),
      ('agave', 'specie', 'rango superiore', 'Agave'),
      ('agapanthus', 'rollback', 'rango superiore', 'Agapanthus')
    ) v(slug, origine, esito, nome) loop
    select count(*) into n from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
     where p.vecchio_slug = atteso.slug and p.origine = atteso.origine and p.esito = atteso.esito and u.nome = atteso.nome;
    if n <> 1 then raise exception 'caso % (%): atteso % su %', atteso.slug, atteso.origine, atteso.esito, atteso.nome; end if;
  end loop;
  -- nomi di Plantae con la X iniziale (Xanthoceras): la x non è un segno d'ibrido
  perform 1 from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
   where p.vecchio_nome_scientifico = 'Xanthoceras sorbifolium' and u.nome = 'Xanthoceras sorbifolia';
  if not found then raise exception 'Xanthoceras sorbifolium non porta a Xanthoceras sorbifolia'; end if;
  -- grex: al genere, mai a una specie
  select count(*) into n from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
   where p.nota like 'grex%' and u.rango <> 'genus';
  if n > 0 then raise exception 'grex collegati a un taxon che non è un genere: %', n; end if;
  -- notogeneri locali sotto una famiglia
  select count(*) into n from col.mappa_proposte where taxon_locale is not null and famiglia_locale is null;
  if n > 0 then raise exception 'taxon locali senza famiglia: %', n; end if;
  -- refusi: mai senza conferma
  select count(*) into n from col.mappa_proposte where nota like 'possibile refuso%' and not da_rivedere;
  if n > 0 then raise exception 'refusi non da rivedere: %', n; end if;
  -- segnaposto "Genere spp" di COL: mai proposti
  select count(*) into n from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id where u.nome ~ '\sspp?\.?\s*$';
  if n > 0 then raise exception 'proposti segnaposto spp: %', n; end if;
  raise notice 'ABBINAMENTO CORRETTO: % proposte, % da rivedere', (select count(*) from col.mappa_proposte),
    (select count(*) from col.mappa_proposte where da_rivedere);
end $$;
