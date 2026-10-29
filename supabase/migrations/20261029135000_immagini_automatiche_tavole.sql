-- Toglie 3 tavole botaniche (Britton & Brown) entrate con il riempimento automatico del 29/10/2026: il filtro di
-- scripts/immagini/riempi/riempi.py ora le riconosce. Le schede tornano senza immagine e passano al secondo giro.
-- Rollback: rimettere le immagini da scripts/immagini/dati/riempimento.json (stesse schede e url).
do $$
declare n int;
begin
  update public.schede set immagine = null
  where immagine->>'origine' = 'automatica 29/10/2026'
    and (id, immagine->>'url') in (
      ('1ebf1336-6af1-4baf-a2d5-c48a485dc160'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/b/b1/Erme15_001_pvd.jpg'),  -- Erythronium mesochoreum
      ('813195bc-cc2c-4997-8133-bf7e8e8757e0'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/9/9a/BB-3050_Kneiffia_alleni.png'),  -- Oenothera fruticosa
      ('8c66df92-ead5-40fd-8a9f-fb37e9c03b86'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/8/88/BB-0042_Dryopteris_clintoniana.png'));  -- Dryopteris clintoniana
  get diagnostics n = row_count;
  if n <> 3 then
    raise exception 'schede: % invece di 3', n;
  end if;
end $$;
