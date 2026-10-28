-- Galleria foto fuori da GitHub: le foto delle piante passano dal repository (docs/gallery/piante/, scritte con il
-- token GitHub personale) a un bucket privato di Supabase Storage, con una tabella che le elenca.
-- Ogni foto ha tre versioni, come prima: originale (al più 1600px), media (640px) e miniatura (120px), in WebP, o in
-- JPEG quando il browser non sa scrivere WebP (Safari).
-- Percorsi nel bucket: {owner_id}/{pianta_id oppure 'generale'}/{timestamp}_{caso}.webp, _medium.webp, _thumb.webp.
-- Rollback (solo con il bucket vuoto, Supabase non lascia cancellare i file da SQL):
--   drop table public.foto; drop policy ... (le tre "galleria: ...") on storage.objects; delete from storage.buckets where id = 'galleria';

create table public.foto (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  -- null = foto generica del giardino, non legata a una pianta. L'app cancella le foto (file e righe) prima della
  -- pianta; la cascata è solo una sicurezza.
  pianta_id text references public.piante(id) on delete cascade,
  scattata_il timestamptz not null,
  percorso text not null unique,
  -- Le derivate possono mancare (generazione fallita al caricamento, o foto vecchie): si ripiega sull'originale.
  percorso_media text,
  percorso_miniatura text,
  creata_il timestamptz not null default now()
);
create index foto_owner_scattata on public.foto (owner_id, scattata_il desc);
create index foto_pianta on public.foto (pianta_id);

alter table public.foto enable row level security;
-- Solo le proprie foto, solo nella propria cartella del bucket, solo sulle proprie piante.
create policy "foto: proprietario" on public.foto for all to authenticated
  using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and split_part(percorso, '/', 1) = auth.uid()::text
    and (percorso_media is null or split_part(percorso_media, '/', 1) = auth.uid()::text)
    and (percorso_miniatura is null or split_part(percorso_miniatura, '/', 1) = auth.uid()::text)
    and (pianta_id is null or exists (select 1 from public.piante p where p.id = pianta_id and p.owner_id = auth.uid()))
  );
-- Nessun aggiornamento: una foto si carica o si elimina.
revoke all on public.foto from anon, authenticated;
grant select, insert, delete on public.foto to authenticated;

-- Bucket privato: le immagini si mostrano con link firmati a scadenza.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('galleria', 'galleria', false, 2097152, array['image/webp', 'image/jpeg']) on conflict (id) do nothing;
create policy "galleria: lettura del proprietario" on storage.objects for select to authenticated
  using (bucket_id = 'galleria' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "galleria: caricamento del proprietario" on storage.objects for insert to authenticated
  with check (bucket_id = 'galleria' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "galleria: eliminazione del proprietario" on storage.objects for delete to authenticated
  using (bucket_id = 'galleria' and (storage.foldername(name))[1] = auth.uid()::text);
