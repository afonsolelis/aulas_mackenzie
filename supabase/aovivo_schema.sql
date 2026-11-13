-- =====================================================================
-- Respostas ao vivo · painel do que a turma escreve durante a atividade
--
-- Usado primeiro pelas missões do simulador da Aula 06 de Data Collection:
-- cada grupo escreve as respostas no simulador, e o slide seguinte às
-- missões mostra as respostas da turma, por missão, enquanto chegam.
--
-- Mesmo padrão das entregas: tabelas com RLS ligado e sem política, acesso
-- só pelas funções abaixo (security definer), que validam cada entrada.
-- O token do professor não fica neste arquivo: o marcador
-- __AOVIVO_HOST_TOKEN__ é trocado por scripts/aovivo_db.mjs a partir do
-- .env, e o banco guarda só o hash SHA-256.
--
-- Idempotente: pode rodar de novo sem apagar respostas.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- Tabelas
-- ---------------------------------------------------------------------
create table if not exists aovivo_professor (
  id            smallint primary key default 1 check (id = 1),
  token_hash    bytea not null,
  atualizado_em timestamptz not null default now()
);

create table if not exists aovivo_salas (
  slug       text primary key check (slug ~ '^[a-z0-9-]{3,64}$'),
  titulo     text not null,
  perguntas  smallint not null check (perguntas between 1 and 30),
  aberta     boolean not null default true,
  criada_em  timestamptz not null default now()
);

-- Uma linha por navegador e pergunta. O cliente é um UUID gerado no
-- navegador do grupo, então trocar o nome do grupo atualiza a mesma linha.
create table if not exists aovivo_respostas (
  sala_slug     text not null references aovivo_salas (slug) on delete cascade,
  cliente       uuid not null,
  pergunta      smallint not null,
  grupo         text not null,
  texto         text not null,
  atualizado_em timestamptz not null default now(),
  primary key (sala_slug, cliente, pergunta)
);

create index if not exists aovivo_respostas_painel
  on aovivo_respostas (sala_slug, pergunta, atualizado_em);

create table if not exists aovivo_tentativas (
  ocorrido_em timestamptz not null default now()
);

alter table aovivo_professor  enable row level security;
alter table aovivo_salas      enable row level security;
alter table aovivo_respostas  enable row level security;
alter table aovivo_tentativas enable row level security;

revoke all on aovivo_professor, aovivo_salas, aovivo_respostas, aovivo_tentativas
  from anon, authenticated;

-- ---------------------------------------------------------------------
-- Token do professor
-- ---------------------------------------------------------------------
insert into aovivo_professor (id, token_hash)
values (1, extensions.digest('__AOVIVO_HOST_TOKEN__', 'sha256'))
on conflict (id) do update set token_hash = excluded.token_hash, atualizado_em = now();

-- Devolve null quando o token confere e a mensagem de erro quando não.
-- Não levanta exceção: a exceção desfaria o registro da tentativa errada.
create or replace function aovivo_checar_token(p_token text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_falhas int;
begin
  delete from aovivo_tentativas where ocorrido_em < now() - interval '1 day';
  select count(*) into v_falhas
    from aovivo_tentativas where ocorrido_em > now() - interval '10 minutes';
  if v_falhas >= 20 then
    return 'Muitas tentativas erradas. Aguarde 10 minutos.';
  end if;
  if exists (select 1 from aovivo_professor
              where token_hash = digest(coalesce(p_token, ''), 'sha256')) then
    return null;
  end if;
  insert into aovivo_tentativas default values;
  perform pg_sleep(1);
  return 'Token inválido.';
end $$;

revoke all on function aovivo_checar_token(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Lado do aluno
-- ---------------------------------------------------------------------
-- Grava ou atualiza a resposta de um grupo a uma pergunta. Texto vazio
-- apaga a resposta, para o painel não mostrar um cartão em branco.
create or replace function aovivo_enviar(
  p_sala text, p_cliente uuid, p_pergunta int, p_grupo text, p_texto text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  s       aovivo_salas;
  v_grupo text := left(btrim(coalesce(p_grupo, '')), 120);
  v_texto text := btrim(coalesce(p_texto, ''));
begin
  select * into s from aovivo_salas where slug = p_sala;
  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Sala não encontrada.');
  end if;
  if not s.aberta then
    return jsonb_build_object('ok', false, 'erro', 'A sala está fechada.');
  end if;
  if p_cliente is null or p_pergunta is null or p_pergunta < 1 or p_pergunta > s.perguntas then
    return jsonb_build_object('ok', false, 'erro', 'Pergunta inválida.');
  end if;
  if v_grupo = '' then
    return jsonb_build_object('ok', false, 'erro', 'Informe o nome do grupo.');
  end if;
  if length(v_texto) > 4000 then
    return jsonb_build_object('ok', false, 'erro', 'Resposta acima de 4.000 caracteres.');
  end if;

  if v_texto = '' then
    delete from aovivo_respostas
     where sala_slug = s.slug and cliente = p_cliente and pergunta = p_pergunta;
  else
    -- Freio contra abuso: no máximo 3.000 respostas por sala.
    if not exists (select 1 from aovivo_respostas
                    where sala_slug = s.slug and cliente = p_cliente and pergunta = p_pergunta)
       and (select count(*) from aovivo_respostas where sala_slug = s.slug) >= 3000 then
      return jsonb_build_object('ok', false, 'erro', 'A sala atingiu o limite de respostas.');
    end if;
    insert into aovivo_respostas (sala_slug, cliente, pergunta, grupo, texto)
    values (s.slug, p_cliente, p_pergunta, v_grupo, v_texto)
    on conflict (sala_slug, cliente, pergunta)
    do update set grupo = excluded.grupo, texto = excluded.texto, atualizado_em = now();
  end if;

  -- O nome do grupo vale para todas as respostas do mesmo navegador.
  update aovivo_respostas set grupo = v_grupo
   where sala_slug = s.slug and cliente = p_cliente and grupo <> v_grupo;

  return jsonb_build_object('ok', true, 'em', now());
end $$;

-- ---------------------------------------------------------------------
-- Lado do professor
-- ---------------------------------------------------------------------
create or replace function aovivo_painel(p_token text, p_sala text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_erro text := aovivo_checar_token(p_token);
  s      aovivo_salas;
begin
  if v_erro is not null then
    return jsonb_build_object('ok', false, 'erro', v_erro);
  end if;
  select * into s from aovivo_salas where slug = p_sala;
  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Sala não encontrada.');
  end if;
  return jsonb_build_object(
    'ok', true,
    'titulo', s.titulo,
    'perguntas', s.perguntas,
    'aberta', s.aberta,
    'agora', now(),
    'respostas', coalesce((
      select jsonb_agg(jsonb_build_object(
               'cliente', r.cliente, 'pergunta', r.pergunta, 'grupo', r.grupo,
               'texto', r.texto, 'em', r.atualizado_em)
             order by r.pergunta, r.atualizado_em)
        from aovivo_respostas r where r.sala_slug = s.slug), '[]'::jsonb)
  );
end $$;

-- Abre ou fecha a sala para novos envios.
create or replace function aovivo_abrir(p_token text, p_sala text, p_aberta boolean)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_erro text := aovivo_checar_token(p_token);
begin
  if v_erro is not null then
    return jsonb_build_object('ok', false, 'erro', v_erro);
  end if;
  update aovivo_salas set aberta = coalesce(p_aberta, true) where slug = p_sala;
  if not found then
    return jsonb_build_object('ok', false, 'erro', 'Sala não encontrada.');
  end if;
  return jsonb_build_object('ok', true, 'aberta', coalesce(p_aberta, true));
end $$;

-- Apaga as respostas da sala, por exemplo depois de um ensaio.
create or replace function aovivo_limpar(p_token text, p_sala text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_erro text := aovivo_checar_token(p_token);
  v_n    int;
begin
  if v_erro is not null then
    return jsonb_build_object('ok', false, 'erro', v_erro);
  end if;
  delete from aovivo_respostas where sala_slug = p_sala;
  get diagnostics v_n = row_count;
  return jsonb_build_object('ok', true, 'apagadas', v_n);
end $$;

revoke all on function aovivo_enviar(text, uuid, int, text, text),
  aovivo_painel(text, text), aovivo_abrir(text, text, boolean),
  aovivo_limpar(text, text) from public;
grant execute on function aovivo_enviar(text, uuid, int, text, text),
  aovivo_painel(text, text), aovivo_abrir(text, text, boolean),
  aovivo_limpar(text, text) to anon, authenticated;

-- ---------------------------------------------------------------------
-- Salas
-- ---------------------------------------------------------------------
insert into aovivo_salas (slug, titulo, perguntas)
values ('mack-dcs-a06-2026-2', 'Data Collection · Aula 06 · Missões do simulador', 7)
on conflict (slug) do update set titulo = excluded.titulo, perguntas = excluded.perguntas;

commit;

-- O PostgREST guarda o esquema em cache: avisa que há funções novas.
notify pgrst, 'reload schema';
