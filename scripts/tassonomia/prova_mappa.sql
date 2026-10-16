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
  -- casi della revisione del 16/10/2026 (slug, esito atteso, nome del taxon proposto)
  for atteso in select * from (values
      ('arctotis-x-hybrida', 'rango superiore', 'Arctotis'),          -- non Arctotis hybrida Anon. (Cosmos)
      ('passiflora-x-violacea', 'rango superiore', 'Passiflora'),     -- non P. violacea Vell.
      ('erysimum-x-allionii', 'sinonimo', 'Erysimum × allionii'),     -- l'ibrido, non E. allionii (DC.) Kuntze (Arabis)
      ('quercus-x-crenata', 'sinonimo', 'Quercus crenata'),           -- l'accettato è un ibrido (Q. × hispanica): resta
      ('promenaea-xanthina', 'sinonimo', 'Promenaea xanthina'),       -- la x di xanthina non è un segno d'ibrido
      ('helianthus-x-multiflorus', 'rango superiore', 'Helianthus'),  -- COL lo mette sotto H. debilis: un'altra pianta
      ('osmanthus-x-fortunei', 'rango superiore', 'Osmanthus'),       -- COL lo mette sotto Fontanesia fortunei
      ('dryopteris-x-remota', 'sinonimo', 'Dryopteris × remota'),     -- stessa pianta scritta senza ×: resta
      ('x-cuprocyparis-leylandii', 'sinonimo', 'Cuprocyparis leylandii'), -- notogenere: la regola dell'ibrido non vale
      ('alyssum-saxatile', 'ambiguo', 'Alyssum saxatile'),            -- omotipico per autore ed epiteto (basionimo non registrato)
      ('festuca-arundinacea', 'ambiguo', 'Festuca arundinacea'),      -- omotipico (Lolium arundinaceum)
      ('asclepias-decumbens', 'ambiguo', 'Asclepias'),                -- stesso autore, epiteto diverso: antenato comune
      ('sambucus-nigra-spp-canadensis', 'variante', 'Sambucus nigra subsp. canadensis')
    ) v(slug, esito, nome) loop
    select count(*) into n from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
     where p.vecchio_slug = atteso.slug and p.origine = 'specie' and p.esito = atteso.esito and u.nome = atteso.nome;
    if n <> 1 then raise exception 'caso % : atteso % su %', atteso.slug, atteso.esito, atteso.nome; end if;
  end loop;
  -- la regola: il tipo vale più dell'autore (Rubus fruticosus L. non è omotipico di Dasiphora fruticosa (L.) Rydb.)
  select count(*) into n from col.mappa_esatti e join col.mappa_righe r on r.id = e.sid
   where r.slug in ('rubus-fruticosus', 'vitis-cordifolia') and e.nota like '%antenato comune%';
  if n <> 2 then raise exception 'rubus-fruticosus e vitis-cordifolia non vanno all''antenato comune: %', n; end if;
  -- ibridi con nome sotto un accettato non ibrido: solo se è la stessa pianta (stesso genere e stesso epiteto)
  select count(*) into n from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
    join col.nome_uso a on a.id = u.parent_id and u.status <> 'accepted'
   where p.vecchio_nome_scientifico ~ '^[A-Z][a-z-]+\s+(×\s*|x\s+)[a-z]' and p.esito in ('sinonimo', 'ambiguo')
     and a.nome !~ '×' and coalesce(a.notho, '') = ''
     and not (split_part(a.nome, ' ', 1) = split_part(p.vecchio_nome_scientifico, ' ', 1)
              and col.stessa_radice(p.vecchio_nome_scientifico, a.nome))
     and p.motivo is distinct from 'correzione';
  if n > 0 then raise exception 'ibridi con nome sotto un accettato non ibrido di un''altra pianta: %', n; end if;
  -- forme: genere scritto male su un nome di tre parole (l'epiteto infraspecifico conta), "Hybrids" non è un grex
  perform 1 from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
   where p.vecchio_slug = 'siegesbeckia-orientalis-pubescens' and u.nome ~ 'pubescens';
  if not found then raise exception 'siegesbeckia-orientalis-pubescens non porta a una pubescens'; end if;
  perform 1 from col.mappa_proposte where vecchio_slug = 'brachyglottis-dunedin-hybrids' and nota like 'grex%';
  if found then raise exception 'brachyglottis-dunedin-hybrids trattato come grex'; end if;
  -- più candidati senza una scelta sicura: l'antenato comune, non il genere scritto (Aleurites cordata -> Vernicia)
  perform 1 from col.mappa_proposte p join col.nome_uso u on u.id = p.col_id
   where p.vecchio_slug = 'aleurites-cordata' and u.nome = 'Aleurites';
  if found then raise exception 'aleurites-cordata collegato al genere Aleurites'; end if;
  -- correzioni a mano (dati/fase3_correzioni.tsv): proposte da far confermare, con la loro alternativa
  select count(*) into n from col.mappa_correzioni c
    left join col.mappa_proposte p on p.vecchio_slug = c.vecchio_slug and p.origine = c.origine
       and p.col_id = c.proposta and p.esito = 'deciso dall''utente' and p.da_rivedere and p.motivo = 'correzione'
   where p.vecchio_slug is null;
  if n > 0 then raise exception 'correzioni non applicate come proposte da rivedere: %', n; end if;
  raise notice 'ABBINAMENTO CORRETTO: % proposte, % da rivedere', (select count(*) from col.mappa_proposte),
    (select count(*) from col.mappa_proposte where da_rivedere);
end $$;
