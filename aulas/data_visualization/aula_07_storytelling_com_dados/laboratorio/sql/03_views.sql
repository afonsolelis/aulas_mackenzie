-- Passo 3 de 3: views que o painel consome.
--
-- Duas regras valem para toda view deste projeto:
--
-- 1. A agregação acontece no banco, não no navegador. A API do Supabase devolve no
--    máximo 1.000 linhas por requisição; um painel que baixa 53 mil commits para somar
--    no JavaScript está errado antes de ficar lento.
-- 2. security_invoker = true. Sem essa opção, a view roda com os privilégios de quem a
--    criou e ignora o RLS das tabelas, abrindo o dado para a chave publicável.
--
-- A unidade de análise é sempre o grupo. Nenhuma view expõe pessoa_id ou autor_id:
-- a participação individual aparece só como distribuição interna do grupo.
--
-- Recorte temporal: 2.475 dos 53.230 commits (4,6%) são anteriores à criação do
-- repositório do grupo. São o histórico herdado do repositório-modelo, com datas de
-- 2022 a 2025. As views de ritmo e participação contam só commits a partir de
-- grupos.criado_em; v_participacao mostra quantos ficaram de fora.

-- Commits do período do grupo, já sem o histórico herdado.
create or replace view v_commits_do_modulo with (security_invoker = true) as
select c.*
from commits c
join grupos g using (turma, grupo)
where c.commitado_em >= g.criado_em;

-- Ritmo: o grupo trabalhou ao longo do módulo ou na véspera?
-- Usa commitado_em, e não autorado_em, porque a data de autoria pode ser reescrita por rebase.
create or replace view v_ritmo_semanal with (security_invoker = true) as
select
  turma,
  grupo,
  date_trunc('week', commitado_em at time zone 'America/Sao_Paulo')::date as semana,
  count(*) filter (where not e_merge)                                     as commits,
  count(distinct autor_id) filter (where not e_merge and autor_id ~ '^T\d') as integrantes_com_commit,
  coalesce(sum(linhas_total) filter (where not e_merge), 0)               as linhas_alteradas
from v_commits_do_modulo
group by 1, 2, 3;

-- Participação: o trabalho está distribuído ou concentrado em poucos integrantes?
-- pct_maior_autor é a fatia do integrante que mais commitou, sem dizer quem é.
-- commits_sem_autoria são os de [externo] e [bot]: o e-mail do git não resolveu
-- para um integrante. Essa lacuna precisa aparecer ao lado do número.
create or replace view v_participacao with (security_invoker = true) as
with por_autor as (
  select turma, grupo, autor_id, count(*) as n
  from v_commits_do_modulo
  where not e_merge
  group by 1, 2, 3
),
herdados as (
  select c.turma, c.grupo, count(*) as n_herdados
  from commits c
  join grupos g using (turma, grupo)
  where c.commitado_em < g.criado_em
  group by 1, 2
)
select
  turma,
  grupo,
  sum(n)                                                 as commits,
  coalesce(max(h.n_herdados), 0)                         as commits_herdados_excluidos,
  coalesce(sum(n) filter (where autor_id !~ '^T\d'), 0)  as commits_sem_autoria,
  count(*) filter (where autor_id ~ '^T\d')              as integrantes_com_commit,
  round(100.0 * max(n) filter (where autor_id ~ '^T\d')
        / nullif(sum(n) filter (where autor_id ~ '^T\d'), 0), 1) as pct_maior_autor
from por_autor
left join herdados h using (turma, grupo)
group by 1, 2;

-- Revisão: a revisão de código foi genuína?
-- Um merge request integrado pelo próprio autor, sem revisor e em poucos minutos é sinal
-- a investigar, não veredito.
create or replace view v_revisao with (security_invoker = true) as
select
  turma,
  grupo,
  count(*) filter (where situacao = 'merged') as mr_integrados,
  round(100.0 * count(*) filter (where situacao = 'merged' and coalesce(revisores_ids, '') <> '')
        / nullif(count(*) filter (where situacao = 'merged'), 0), 1) as pct_com_revisor,
  round(100.0 * count(*) filter (where situacao = 'merged' and merged_por_id = autor_id)
        / nullif(count(*) filter (where situacao = 'merged'), 0), 1) as pct_integrado_pelo_autor,
  round((percentile_cont(0.5) within group (order by extract(epoch from merged_em - criado_em) / 3600.0)
         filter (where situacao = 'merged'))::numeric, 1) as mediana_horas_ate_merge
from merge_requests
group by 1, 2;

-- A chave publicável entra como anon. Sem login, nenhuma view responde.
revoke all on v_commits_do_modulo, v_ritmo_semanal, v_participacao, v_revisao from anon;
grant select on v_commits_do_modulo, v_ritmo_semanal, v_participacao, v_revisao to authenticated;

-- Modelo para a view do seu grupo: copie, troque o nome e escreva a consulta que
-- sustenta a pergunta de decisão do seu protótipo.
--
-- create or replace view v_minha_pergunta with (security_invoker = true) as
-- select turma, grupo, ...
-- from ...
-- group by turma, grupo;
--
-- revoke all on v_minha_pergunta from anon;
-- grant select on v_minha_pergunta to authenticated;
