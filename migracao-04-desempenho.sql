-- ============================================================
-- Migração 04 — desempenho das permissões
-- Cole no SQL Editor do Supabase e clique em RUN.
--
-- Por quê: do jeito que estava, o banco chamava meu_papel() UMA VEZ
-- POR LINHA ao listar os cadastros. Com 30 leads ninguém sente; com
-- 2.000 no fim do feirão, o painel arrasta. Envolver a chamada em
-- (select ...) faz o Postgres calcular o papel uma única vez.
-- ============================================================

drop policy if exists "equipe le cadastros" on public.leads;
create policy "equipe le cadastros" on public.leads
  for select to authenticated
  using ((select public.meu_papel()) in ('master','consulta'));

drop policy if exists "master apaga cadastro" on public.leads;
create policy "master apaga cadastro" on public.leads
  for delete to authenticated
  using ((select public.meu_papel()) = 'master');

drop policy if exists "equipe atualiza status" on public.leads;
create policy "equipe atualiza status" on public.leads
  for update to authenticated
  using ((select public.meu_papel()) in ('master','consulta'))
  with check ((select public.meu_papel()) in ('master','consulta'));

drop policy if exists "equipe le ganhadores" on public.ganhadores;
create policy "equipe le ganhadores" on public.ganhadores
  for select to authenticated
  using ((select public.meu_papel()) in ('master','consulta'));

drop policy if exists "master registra ganhador" on public.ganhadores;
create policy "master registra ganhador" on public.ganhadores
  for insert to authenticated
  with check ((select public.meu_papel()) = 'master');

drop policy if exists "master anula ganhador" on public.ganhadores;
create policy "master anula ganhador" on public.ganhadores
  for delete to authenticated
  using ((select public.meu_papel()) = 'master');

drop policy if exists "master escreve config" on public.config;
create policy "master escreve config" on public.config
  for all to authenticated
  using ((select public.meu_papel()) = 'master')
  with check ((select public.meu_papel()) = 'master');
