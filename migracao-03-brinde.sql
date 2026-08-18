-- ============================================================
-- Migração 03 — configuração do brinde (texto e foto)
-- Cole no SQL Editor do Supabase e clique em RUN.
-- Pode rodar com o feirão acontecendo.
-- ============================================================

-- ---------- textos do evento ----------
create table if not exists public.config (
  chave          text primary key,
  valor          text,
  atualizado_em  timestamptz not null default now()
);

alter table public.config enable row level security;

-- todo mundo lê (a página do QR precisa saber qual é o brinde)
drop policy if exists "todos leem config" on public.config;
create policy "todos leem config" on public.config
  for select to anon, authenticated using (true);

-- só o master escreve
drop policy if exists "master escreve config" on public.config;
create policy "master escreve config" on public.config
  for all to authenticated
  using (public.meu_papel() = 'master')
  with check (public.meu_papel() = 'master');

insert into public.config (chave, valor) values
  ('evento',     'Feirão Boulevard Rio'),
  ('titulo',     'Concorra ao brinde'),
  ('brinde',     'uma Alexa'),
  ('resultado',  ''),
  ('brinde_img', '')
on conflict (chave) do nothing;

create or replace function public.toca_config() returns trigger
language plpgsql as $$
begin new.atualizado_em := now(); return new; end $$;

drop trigger if exists config_atualizacao on public.config;
create trigger config_atualizacao before update on public.config
  for each row execute function public.toca_config();

-- ---------- foto do brinde ----------
insert into storage.buckets (id, name, public)
values ('publico', 'publico', true)
on conflict (id) do nothing;

drop policy if exists "todos veem arquivos publicos" on storage.objects;
create policy "todos veem arquivos publicos" on storage.objects
  for select to anon, authenticated using (bucket_id = 'publico');

drop policy if exists "master envia arquivos" on storage.objects;
create policy "master envia arquivos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'publico' and public.meu_papel() = 'master');

drop policy if exists "master troca arquivos" on storage.objects;
create policy "master troca arquivos" on storage.objects
  for update to authenticated
  using (bucket_id = 'publico' and public.meu_papel() = 'master')
  with check (bucket_id = 'publico' and public.meu_papel() = 'master');

drop policy if exists "master apaga arquivos" on storage.objects;
create policy "master apaga arquivos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'publico' and public.meu_papel() = 'master');
