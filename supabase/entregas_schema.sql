-- =====================================================================
-- Entregas de projeto · formulário dos alunos e área do professor
--
-- Roda no mesmo projeto Supabase do quiz e do TBL, com prefixo próprio
-- (entrega_*). As tabelas ficam com RLS ligado e sem política: o navegador
-- só chega a elas pelas funções abaixo, que rodam como security definer e
-- validam cada entrada.
--
-- O token do professor não fica neste arquivo. O marcador
-- __ENTREGA_HOST_TOKEN__ é substituído por scripts/entregas_db.mjs a partir
-- do .env, e o banco guarda só o hash SHA-256.
--
-- Idempotente: pode rodar de novo sem apagar entregas nem correções.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- Tabelas
-- ---------------------------------------------------------------------
create table if not exists entrega_professor (
  id            smallint primary key default 1 check (id = 1),
  token_hash    bytea not null,
  atualizado_em timestamptz not null default now()
);

create table if not exists entrega_formularios (
  slug        text primary key check (slug ~ '^[a-z0-9-]{3,64}$'),
  disciplina  text not null,
  turma       text not null,
  titulo      text not null,
  instrucoes  text,
  prazo       timestamptz not null,
  aberto      boolean not null default true,
  criado_em   timestamptz not null default now()
);

-- Cada envio é uma linha nova. Reenviar não apaga o anterior: a área do
-- professor mostra o envio mais recente de cada grupo e guarda o histórico.
create table if not exists entrega_respostas (
  id               uuid primary key default gen_random_uuid(),
  formulario_slug  text not null references entrega_formularios (slug),
  grupo            text not null,
  integrantes      text not null,
  repositorio_url  text not null,
  plataforma       text check (plataforma in ('metabase', 'supabase')),
  painel_url       text,
  acesso_painel    text,
  observacoes      text,
  enviado_em       timestamptz not null default now(),
  nota             numeric(4, 2) check (nota between 0 and 10),
  comentario       text,
  corrigido_em     timestamptz
);

-- Tabela criada antes do formulário de grupo: a plataforma deixa de ser obrigatória.
alter table entrega_respostas alter column plataforma drop not null;

-- Formulários por turma, sem prazo. Formulários da mesma série compartilham o
-- endereço do aluno: só a turma aberta recebe envios, e fechar uma turma abre
-- a próxima com numero + 1. As turmas fechadas ficam guardadas para consulta.
alter table entrega_formularios alter column prazo drop not null;
alter table entrega_formularios add column if not exists serie text;
alter table entrega_formularios add column if not exists numero int;
alter table entrega_formularios add column if not exists fechado_em timestamptz;
create unique index if not exists entrega_formularios_serie_aberta
  on entrega_formularios (serie) where aberto and serie is not null;

create index if not exists entrega_respostas_form
  on entrega_respostas (formulario_slug, grupo, enviado_em desc);

-- Tentativas de token erradas, para frear tentativa e erro no token de 6 dígitos.
create table if not exists entrega_tentativas (
  ocorrido_em timestamptz not null default now()
);

alter table entrega_professor   enable row level security;
alter table entrega_formularios enable row level security;
alter table entrega_respostas   enable row level security;
alter table entrega_tentativas  enable row level security;

revoke all on entrega_professor, entrega_formularios, entrega_respostas, entrega_tentativas
  from anon, authenticated;

-- ---------------------------------------------------------------------
-- Token do professor
-- ---------------------------------------------------------------------
insert into entrega_professor (id, token_hash)
values (1, extensions.digest('__ENTREGA_HOST_TOKEN__', 'sha256'))
on conflict (id) do update set token_hash = excluded.token_hash, atualizado_em = now();

-- Devolve null quando o token confere e a mensagem de erro quando não.
-- Não levanta exceção de propósito: a exceção desfaria o registro da tentativa.
create or replace function entrega_checar_token(p_token text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_falhas int;
begin
  delete from entrega_tentativas where ocorrido_em < now() - interval '1 day';
  select count(*) into v_falhas
    from entrega_tentativas where ocorrido_em > now() - interval '10 minutes';
  if v_falhas >= 20 then
    return 'Muitas tentativas erradas. Aguarde 10 minutos.';
  end if;
  if exists (select 1 from entrega_professor
              where token_hash = digest(coalesce(p_token, ''), 'sha256')) then
    return null;
  end if;
  insert into entrega_tentativas default values;
  perform pg_sleep(1);
  return 'Token inválido.';
end $$;

revoke all on function entrega_checar_token(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Lado do aluno
-- ---------------------------------------------------------------------
create or replace function entrega_formulario(p_slug text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'slug', slug, 'disciplina', disciplina, 'turma', turma, 'titulo', titulo,
    'instrucoes', instrucoes, 'prazo', prazo,
    'aceitando', aberto and (prazo is null or now() <= prazo))
  from entrega_formularios where slug = p_slug;
$$;

-- Turma aberta de uma série; o formulário do aluno pergunta por ela ao carregar.
create or replace function entrega_turma_aberta(p_serie text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'slug', slug, 'disciplina', disciplina, 'turma', turma, 'titulo', titulo,
    'instrucoes', instrucoes, 'criado_em', criado_em)
  from entrega_formularios where serie = p_serie and aberto;
$$;

create or replace function entrega_enviar(
  p_slug text, p_grupo text, p_integrantes text, p_repositorio text,
  p_plataforma text, p_painel text, p_acesso text, p_observacoes text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  f     entrega_formularios;
  v_rep text := regexp_replace(trim(coalesce(p_repositorio, '')), '(\.git)?/?$', '');
  v_id  uuid;
  v_em  timestamptz;
begin
  select * into f from entrega_formularios where slug = p_slug;
  if not found then
    raise exception 'Formulário não encontrado.';
  end if;
  if not f.aberto or now() > f.prazo then
    raise exception 'O formulário está fechado. O prazo era %.',
      to_char(f.prazo at time zone 'America/Sao_Paulo', 'DD/MM/YYYY HH24:MI');
  end if;
  if length(trim(coalesce(p_grupo, ''))) not between 1 and 60 then
    raise exception 'Informe o nome do grupo.';
  end if;
  if length(trim(coalesce(p_integrantes, ''))) not between 3 and 2000 then
    raise exception 'Informe os integrantes do grupo.';
  end if;
  if v_rep !~ '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' then
    raise exception 'O repositório precisa ser um link do GitHub no formato https://github.com/usuario/repositorio.';
  end if;
  if p_plataforma not in ('metabase', 'supabase') then
    raise exception 'Escolha a plataforma do painel.';
  end if;
  if coalesce(p_painel, '') <> '' and p_painel !~ '^https?://' then
    raise exception 'O link do painel precisa começar com http:// ou https://.';
  end if;
  if length(coalesce(p_painel, '')) > 500 or length(coalesce(p_acesso, '')) > 1000
     or length(coalesce(p_observacoes, '')) > 4000 then
    raise exception 'Algum campo passou do tamanho máximo.';
  end if;
  -- Freio contra envio repetido por engano ou por script.
  if (select count(*) from entrega_respostas
       where formulario_slug = p_slug and lower(trim(grupo)) = lower(trim(p_grupo))
         and enviado_em > now() - interval '10 minutes') >= 5 then
    raise exception 'Muitos envios deste grupo em poucos minutos. Aguarde e tente de novo.';
  end if;

  insert into entrega_respostas (formulario_slug, grupo, integrantes, repositorio_url,
                                 plataforma, painel_url, acesso_painel, observacoes)
  values (p_slug, trim(p_grupo), trim(p_integrantes), v_rep, p_plataforma,
          nullif(trim(p_painel), ''), nullif(trim(p_acesso), ''), nullif(trim(p_observacoes), ''))
  returning id, enviado_em into v_id, v_em;

  return jsonb_build_object('id', v_id, 'enviado_em', v_em, 'repositorio', v_rep);
end $$;

-- Formulário curto: integrantes (1 obrigatório, até 5) e repositório. O grupo
-- é identificado pelo repositório, então reenviar com o mesmo link substitui
-- a versão anterior na área do professor.
create or replace function entrega_enviar_grupo(
  p_slug text, p_integrantes text[], p_repositorio text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  f      entrega_formularios;
  v_rep  text := regexp_replace(trim(coalesce(p_repositorio, '')), '(\.git)?/?$', '');
  v_nome text[];
  v_grp  text;
  v_id   uuid;
  v_em   timestamptz;
begin
  select * into f from entrega_formularios where slug = p_slug;
  if not found then
    raise exception 'Formulário não encontrado.';
  end if;
  if not f.aberto or now() > coalesce(f.prazo, 'infinity') then
    raise exception 'Esta turma foi encerrada. Recarregue a página e envie de novo.';
  end if;
  select coalesce(array_agg(n order by ord), '{}') into v_nome
    from (select trim(x) as n, ord from unnest(coalesce(p_integrantes, '{}')) with ordinality as t(x, ord)) s
   where n <> '';
  if cardinality(v_nome) = 0 then
    raise exception 'Informe o nome de pelo menos um integrante.';
  end if;
  if cardinality(v_nome) > 5 then
    raise exception 'O grupo tem no máximo 5 integrantes.';
  end if;
  if exists (select 1 from unnest(v_nome) n where length(n) not between 3 and 120) then
    raise exception 'Cada nome precisa ter entre 3 e 120 caracteres.';
  end if;
  if v_rep !~ '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' then
    raise exception 'O repositório precisa ser um link do GitHub no formato https://github.com/usuario/repositorio.';
  end if;
  v_grp := substr(v_rep, length('https://github.com/') + 1);
  if (select count(*) from entrega_respostas
       where formulario_slug = p_slug and lower(grupo) = lower(v_grp)
         and enviado_em > now() - interval '10 minutes') >= 5 then
    raise exception 'Muitos envios deste repositório em poucos minutos. Aguarde e tente de novo.';
  end if;

  insert into entrega_respostas (formulario_slug, grupo, integrantes, repositorio_url)
  values (p_slug, v_grp, array_to_string(v_nome, E'\n'), v_rep)
  returning id, enviado_em into v_id, v_em;

  return jsonb_build_object('id', v_id, 'enviado_em', v_em, 'repositorio', v_rep);
end $$;

-- ---------------------------------------------------------------------
-- Lado do professor
-- ---------------------------------------------------------------------
create or replace function entrega_painel(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_erro text := entrega_checar_token(p_token);
begin
  if v_erro is not null then
    return jsonb_build_object('ok', false, 'erro', v_erro);
  end if;
  return jsonb_build_object('ok', true, 'formularios', coalesce((
    select jsonb_agg(jsonb_build_object(
      'slug', f.slug, 'disciplina', f.disciplina, 'turma', f.turma, 'titulo', f.titulo,
      'prazo', f.prazo, 'aberto', f.aberto, 'serie', f.serie, 'numero', f.numero,
      'criado_em', f.criado_em, 'fechado_em', f.fechado_em,
      'respostas', coalesce((
        select jsonb_agg(to_jsonb(r) - 'formulario_slug' order by r.grupo, r.enviado_em desc)
        from entrega_respostas r where r.formulario_slug = f.slug), '[]'::jsonb))
      order by f.aberto desc, coalesce(f.fechado_em, f.prazo, f.criado_em) desc, f.slug)
    from entrega_formularios f), '[]'::jsonb));
end $$;

create or replace function entrega_corrigir(
  p_token text, p_id uuid, p_nota numeric, p_comentario text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_erro text := entrega_checar_token(p_token);
begin
  if v_erro is not null then
    return jsonb_build_object('ok', false, 'erro', v_erro);
  end if;
  if p_nota is not null and (p_nota < 0 or p_nota > 10) then
    return jsonb_build_object('ok', false, 'erro', 'A nota vai de 0 a 10.');
  end if;
  update entrega_respostas
     set nota = p_nota,
         comentario = nullif(trim(p_comentario), ''),
         corrigido_em = case when p_nota is null and nullif(trim(p_comentario), '') is null
                             then null else now() end
   where id = p_id;
  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Entrega não encontrada.');
  end if;
  return jsonb_build_object('ok', true, 'corrigido_em', now());
end $$;

create or replace function entrega_ajustar(
  p_token text, p_slug text, p_aberto boolean, p_prazo timestamptz)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_erro text := entrega_checar_token(p_token);
begin
  if v_erro is not null then
    return jsonb_build_object('ok', false, 'erro', v_erro);
  end if;
  update entrega_formularios
     set aberto = coalesce(p_aberto, aberto), prazo = coalesce(p_prazo, prazo)
   where slug = p_slug and serie is null;
  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Formulário não encontrado ou organizado por turmas.');
  end if;
  return jsonb_build_object('ok', true);
end $$;

-- Fecha a turma aberta de uma série e abre a próxima, vazia. As respostas da
-- turma fechada continuam na tabela e aparecem na área do professor.
create or replace function entrega_fechar_turma(p_token text, p_slug text, p_nova_turma text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_erro text := entrega_checar_token(p_token);
  f      entrega_formularios;
  v_num  int;
  v_nome text;
  v_slug text;
begin
  if v_erro is not null then
    return jsonb_build_object('ok', false, 'erro', v_erro);
  end if;
  select * into f from entrega_formularios where slug = p_slug for update;
  if not found or f.serie is null then
    return jsonb_build_object('ok', false, 'erro', 'Formulário não encontrado ou sem turmas.');
  end if;
  if not f.aberto then
    return jsonb_build_object('ok', false, 'erro', 'Esta turma já está fechada.');
  end if;
  v_num  := coalesce((select max(numero) from entrega_formularios where serie = f.serie), 0) + 1;
  v_nome := coalesce(nullif(trim(p_nova_turma), ''), 'Turma ' || v_num);
  if length(v_nome) > 80 then
    return jsonb_build_object('ok', false, 'erro', 'O nome da turma tem no máximo 80 caracteres.');
  end if;
  v_slug := f.serie || '-' || v_num;

  update entrega_formularios set aberto = false, fechado_em = now() where slug = f.slug;
  insert into entrega_formularios (slug, disciplina, turma, titulo, instrucoes, serie, numero)
  values (v_slug, f.disciplina, v_nome, f.titulo, f.instrucoes, f.serie, v_num);
  return jsonb_build_object('ok', true, 'slug', v_slug, 'turma', v_nome);
end $$;

revoke all on function entrega_formulario(text), entrega_enviar(text, text, text, text, text, text, text, text),
  entrega_turma_aberta(text), entrega_enviar_grupo(text, text[], text),
  entrega_painel(text), entrega_corrigir(text, uuid, numeric, text),
  entrega_ajustar(text, text, boolean, timestamptz),
  entrega_fechar_turma(text, text, text) from public;
grant execute on function entrega_formulario(text), entrega_enviar(text, text, text, text, text, text, text, text),
  entrega_turma_aberta(text), entrega_enviar_grupo(text, text[], text),
  entrega_painel(text), entrega_corrigir(text, uuid, numeric, text),
  entrega_ajustar(text, text, boolean, timestamptz),
  entrega_fechar_turma(text, text, text) to anon, authenticated;

-- ---------------------------------------------------------------------
-- Formulários
-- ---------------------------------------------------------------------
insert into entrega_formularios (slug, disciplina, turma, titulo, instrucoes, prazo)
values (
  'mack-dv-2026-2-final',
  'Data Visualization',
  'MBA Engenharia de Dados · 2026.2',
  'Entrega do projeto final',
  'Um envio por grupo. Se precisar corrigir algo, envie de novo: vale o envio mais recente até o prazo. Se o repositório for privado, adicione o usuário afonsolelis como colaborador antes de enviar.',
  '2026-10-10 23:59:59-03'
)
on conflict (slug) do update set
  disciplina = excluded.disciplina, turma = excluded.turma, titulo = excluded.titulo,
  instrucoes = excluded.instrucoes;

-- Série sem prazo: cria só a primeira turma. As seguintes nascem pelo botão
-- "Fechar turma" da área do professor (entrega_fechar_turma).
insert into entrega_formularios (slug, disciplina, turma, titulo, instrucoes, serie, numero)
select 'mack-dv-grupos-1', 'Data Visualization', 'MBA Engenharia de Dados · 2026.2',
       'Integrantes e repositório do grupo',
       'Um envio por grupo, feito por um integrante. Para corrigir, envie de novo com o mesmo link do GitHub: vale o envio mais recente.',
       'mack-dv-grupos', 1
where not exists (select 1 from entrega_formularios where serie = 'mack-dv-grupos');

commit;
