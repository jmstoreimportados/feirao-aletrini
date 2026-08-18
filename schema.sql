-- ============================================================
-- Feirão Aletrini + Kalil — banco de dados (Supabase)
-- Cole TUDO isto no SQL Editor do Supabase e clique em RUN.
-- ============================================================

-- ---------- 1. cadastros ----------
create table public.leads (
  id          uuid primary key default gen_random_uuid(),
  cupom       int  generated always as identity,
  nome        text not null check (length(trim(nome)) >= 3),
  telefone    text not null check (telefone ~ '^[0-9]{10,11}$'),
  cidade      text not null check (length(trim(cidade)) >= 3),
  consent     boolean not null default true,
  origem      text not null default 'qr' check (origem in ('qr','estande')),
  evento      text not null default 'feirao-2026-08',
  criado_em   timestamptz not null default now()
);

-- mesmo telefone não tira dois cupons no mesmo evento
create unique index leads_tel_evento_idx on public.leads (telefone, evento);
create index leads_criado_idx on public.leads (criado_em desc);

-- ---------- 2. ganhadores ----------
create table public.ganhadores (
  id         uuid primary key default gen_random_uuid(),
  lead_id    uuid not null references public.leads(id) on delete cascade,
  brinde     text,
  criado_em  timestamptz not null default now()
);

-- ---------- 3. quem é da equipe ----------
create table public.perfis (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  nome     text not null,
  papel    text not null default 'consulta' check (papel in ('master','consulta'))
);

create or replace function public.meu_papel() returns text
language sql stable security definer set search_path = public as $$
  select coalesce((select papel from public.perfis where user_id = auth.uid()), 'nenhum')
$$;

-- ---------- 4. travas de acesso ----------
alter table public.leads      enable row level security;
alter table public.ganhadores enable row level security;
alter table public.perfis     enable row level security;

-- o público NÃO lê, NÃO altera e NÃO apaga nada.
-- ele nem insere direto: só chama a função cadastrar() lá embaixo.

create policy "equipe le cadastros" on public.leads
  for select to authenticated using (public.meu_papel() in ('master','consulta'));
create policy "master apaga cadastro" on public.leads
  for delete to authenticated using (public.meu_papel() = 'master');

create policy "equipe le ganhadores" on public.ganhadores
  for select to authenticated using (public.meu_papel() in ('master','consulta'));
create policy "master registra ganhador" on public.ganhadores
  for insert to authenticated with check (public.meu_papel() = 'master');
create policy "master anula ganhador" on public.ganhadores
  for delete to authenticated using (public.meu_papel() = 'master');

create policy "vejo meu perfil" on public.perfis
  for select to authenticated using (user_id = auth.uid());

-- ---------- 5. a única porta aberta ao público ----------
-- Devolve só o número do cupom. Não expõe a lista de ninguém.
-- Número positivo = cadastrou. Negativo = telefone já tinha esse cupom.
create or replace function public.cadastrar(
  p_nome text, p_telefone text, p_cidade text, p_origem text default 'qr'
) returns int
language plpgsql security definer set search_path = public as $$
declare
  v_cupom int;
  v_tel   text := regexp_replace(coalesce(p_telefone,''), '\D', '', 'g');
begin
  if length(trim(coalesce(p_nome,''))) < 3 then raise exception 'nome curto'; end if;
  if length(v_tel) not between 10 and 11   then raise exception 'telefone invalido'; end if;
  if length(trim(coalesce(p_cidade,''))) < 3 then raise exception 'cidade curta'; end if;

  insert into public.leads (nome, telefone, cidade, origem)
  values (trim(p_nome), v_tel, trim(p_cidade),
          case when p_origem = 'estande' then 'estande' else 'qr' end)
  returning cupom into v_cupom;
  return v_cupom;
exception when unique_violation then
  select cupom into v_cupom from public.leads
   where telefone = v_tel and evento = 'feirao-2026-08';
  return -v_cupom;
end $$;

revoke all on function public.cadastrar(text,text,text,text) from public;
grant execute on function public.cadastrar(text,text,text,text) to anon, authenticated;
grant execute on function public.meu_papel() to authenticated;

-- ---------- 6. resumo para o painel ----------
create or replace view public.resumo as
  select count(*)                                             as total,
         count(*) filter (where criado_em::date = current_date) as hoje,
         count(*) filter (where criado_em > now() - interval '1 hour') as ultima_hora,
         count(distinct cidade)                               as cidades
    from public.leads;
