-- ============================================================
-- Migração 02 — acompanhamento de leads
-- Cole no SQL Editor do Supabase e clique em RUN.
-- Pode rodar com o feirão acontecendo: não apaga nada.
-- ============================================================

-- Em que pé está cada lead depois do feirão.
alter table public.leads
  add column if not exists status text not null default 'novo'
    check (status in ('novo','contatado','agendado','vendido','perdido')),
  add column if not exists nota text,
  add column if not exists atualizado_em timestamptz;

create index if not exists leads_status_idx on public.leads (status);

-- A equipe logada pode mudar status e anotação (mas não o cadastro em si).
drop policy if exists "equipe atualiza status" on public.leads;
create policy "equipe atualiza status" on public.leads
  for update to authenticated
  using (public.meu_papel() in ('master','consulta'))
  with check (public.meu_papel() in ('master','consulta'));

-- Carimba a hora sempre que alguém mexer no status.
create or replace function public.marca_atualizacao() returns trigger
language plpgsql as $$
begin
  new.atualizado_em := now();
  -- protege os dados do cadastro: só status e nota podem mudar por aqui
  new.nome     := old.nome;
  new.telefone := old.telefone;
  new.cidade   := old.cidade;
  new.cupom    := old.cupom;
  new.criado_em := old.criado_em;
  return new;
end $$;

drop trigger if exists leads_atualizacao on public.leads;
create trigger leads_atualizacao before update on public.leads
  for each row execute function public.marca_atualizacao();
