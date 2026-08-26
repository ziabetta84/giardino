-- Fase 2: abilita le scritture da SelettoreSpecie.vue (chiave anon, nessun
-- sistema di login nell'app per ora). Solo INSERT/UPDATE, mai DELETE: nel
-- caso peggiore (chiave anon trovata in devtools) i dati restano recuperabili
-- da backup/migration invece di poter essere cancellati. Soluzione interinale
-- concordata con l'utente: quando l'app avrà un vero sistema di login, va
-- sostituita con policy basate su auth.uid().
create policy "specie: scrittura pubblica temporanea (insert)"
  on specie for insert
  with check (true);

create policy "specie: scrittura pubblica temporanea (update)"
  on specie for update
  using (true)
  with check (true);
