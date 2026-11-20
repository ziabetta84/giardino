-- Su Supabase auth.uid() esiste già: qui la rifacciamo per il database di prova (legge il sub del JWT come fa Supabase).
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
