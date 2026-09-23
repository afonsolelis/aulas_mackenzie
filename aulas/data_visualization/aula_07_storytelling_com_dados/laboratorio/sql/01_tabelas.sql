-- Aula 07 · Data Visualization · Do protótipo ao painel com Supabase
-- Passo 1 de 3: tabelas do recorte pseudonimizado (15 turmas, 75 grupos).
--
-- Cada tabela espelha um CSV de projeto_pbl_completo.zip, com as mesmas colunas e na
-- mesma ordem, para que o \copy do passo 2 funcione sem lista de colunas.
-- Rode no SQL Editor do Supabase ou com psql, antes da carga.

create table if not exists grupos (
  turma                text not null,
  grupo                text not null,
  branch_padrao        text,
  criado_em            timestamptz,
  ultima_atividade_em  timestamptz,
  primary key (turma, grupo)
);

create table if not exists pessoas (
  turma      text not null,
  grupo      text not null,
  pessoa_id  text primary key,          -- T28-G01-A01: estável dentro do repositório
  papel      text,                      -- owner, maintainer, developer, reporter, guest
  situacao   text,
  foreign key (turma, grupo) references grupos (turma, grupo)
);

-- 371 das 376 sprints não têm início nem prazo registrados. Cruzar commit com sprint
-- por data não se sustenta nesta base; cartões e merge requests trazem a sprint por nome.
create table if not exists sprints (
  turma      text not null,
  grupo      text not null,
  sprint     text not null,
  situacao   text,
  inicio_em  date,
  prazo_em   date,
  primary key (turma, grupo, sprint),
  foreign key (turma, grupo) references grupos (turma, grupo)
);

create table if not exists quadro_colunas (
  turma    text not null,
  grupo    text not null,
  quadro   text not null,
  posicao  integer not null,
  coluna   text,
  primary key (turma, grupo, quadro, posicao),
  foreign key (turma, grupo) references grupos (turma, grupo)
);

-- autorado_em é gravado pelo cliente git e pode ser reescrito por rebase;
-- commitado_em é a hora de gravação do commit. Toda leitura de cadência declara qual usa.
create table if not exists commits (
  turma               text not null,
  grupo               text not null,
  commit_id           text not null,
  autor_id            text,           -- código da pessoa, [externo] ou [bot]
  autorado_em         timestamptz,
  commitado_em        timestamptz,
  e_merge             boolean,
  linhas_adicionadas  integer,
  linhas_removidas    integer,
  linhas_total        integer,
  titulo              text,
  mensagem            text,
  primary key (turma, grupo, commit_id),
  foreign key (turma, grupo) references grupos (turma, grupo)
);

create table if not exists merge_requests (
  turma             text not null,
  grupo             text not null,
  mr_numero         integer not null,
  titulo            text,
  descricao         text,
  situacao          text,             -- merged, closed, opened
  criado_em         timestamptz,
  atualizado_em     timestamptz,
  merged_em         timestamptz,
  fechado_em        timestamptz,
  branch_origem     text,
  branch_destino    text,
  autor_id          text,
  merged_por_id     text,
  revisores_ids     text,             -- lista separada por ;
  responsaveis_ids  text,             -- lista separada por ;
  e_rascunho        boolean,
  comentarios       integer,
  sprint            text,
  rotulos           text,             -- lista separada por ;
  primary key (turma, grupo, mr_numero),
  foreign key (turma, grupo) references grupos (turma, grupo)
);

create table if not exists cartoes (
  turma             text not null,
  grupo             text not null,
  cartao_numero     integer not null,
  titulo            text,
  descricao         text,
  situacao          text,             -- opened, closed
  criado_em         timestamptz,
  atualizado_em     timestamptz,
  fechado_em        timestamptz,
  prazo_em          date,
  autor_id          text,
  fechado_por_id    text,
  responsaveis_ids  text,
  rotulos           text,
  sprint            text,
  peso              integer,
  comentarios       integer,
  tempo_estimado_s  integer,
  tempo_gasto_s     integer,
  primary key (turma, grupo, cartao_numero),
  foreign key (turma, grupo) references grupos (turma, grupo)
);

-- Cada linha é a aplicação (add) ou a remoção (remove) de um rótulo. Como cada coluna
-- do quadro corresponde a um rótulo, a passagem por uma coluna se reconstrói pareando
-- cada add com o remove seguinte do mesmo rótulo no mesmo cartão.
create table if not exists kanban_eventos (
  turma          text not null,
  grupo          text not null,
  cartao_numero  integer not null,
  acao           text not null,       -- add, remove
  coluna         text,
  pessoa_id      text,
  ocorrido_em    timestamptz not null,
  foreign key (turma, grupo) references grupos (turma, grupo)
);

create index if not exists commits_grupo_data on commits (turma, grupo, commitado_em);
create index if not exists mr_grupo_data on merge_requests (turma, grupo, criado_em);
create index if not exists cartoes_grupo_sprint on cartoes (turma, grupo, sprint);
create index if not exists kanban_cartao on kanban_eventos (turma, grupo, cartao_numero, ocorrido_em);

-- Controle de acesso. O painel usa a chave publicável, que qualquer pessoa enxerga no
-- código da página. Com RLS ligado e política só para authenticated, a chave sozinha
-- não lê nada: é preciso entrar com um usuário criado em Authentication > Users.
do $$
declare t text;
begin
  foreach t in array array['grupos','pessoas','sprints','quadro_colunas','commits',
                           'merge_requests','cartoes','kanban_eventos'] loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists leitura_autenticada on %I', t);
    execute format('create policy leitura_autenticada on %I for select to authenticated using (true)', t);
  end loop;
end $$;
