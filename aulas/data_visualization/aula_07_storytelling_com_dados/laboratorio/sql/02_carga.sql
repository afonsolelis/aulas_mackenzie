-- Passo 2 de 3: carga dos CSVs com \copy.
--
-- Rode com psql a partir da pasta onde os CSVs foram descompactados:
--   cd projeto_pbl_completo
--   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f ../sql/02_carga.sql
--
-- \copy lê o arquivo na máquina de quem roda o psql (o Codespace) e envia pela conexão.
-- O importador de CSV do painel do Supabase serve para arquivos pequenos; com oito
-- arquivos e 183 mil eventos do quadro, o \copy é mais previsível e termina com a
-- reconciliação no mesmo passo. A ordem respeita as chaves estrangeiras: grupos primeiro.

\echo 'Carregando grupos...'
\copy grupos from 'grupos.csv' with (format csv, header true)
\echo 'Carregando pessoas...'
\copy pessoas from 'pessoas.csv' with (format csv, header true)
\echo 'Carregando sprints...'
\copy sprints from 'sprints.csv' with (format csv, header true)
\echo 'Carregando quadro_colunas...'
\copy quadro_colunas from 'quadro_colunas.csv' with (format csv, header true)
\echo 'Carregando commits...'
\copy commits from 'commits.csv' with (format csv, header true)
\echo 'Carregando merge_requests...'
\copy merge_requests from 'merge_requests.csv' with (format csv, header true)
\echo 'Carregando cartoes...'
\copy cartoes from 'cartoes.csv' with (format csv, header true)
\echo 'Carregando kanban_eventos...'
\copy kanban_eventos from 'kanban_eventos.csv' with (format csv, header true)

-- Reconciliação: as contagens precisam bater com o manifesto.json.
select 'grupos' as tabela, count(*) as linhas, 75 as manifesto from grupos
union all select 'pessoas', count(*), 1859 from pessoas
union all select 'sprints', count(*), 376 from sprints
union all select 'quadro_colunas', count(*), 429 from quadro_colunas
union all select 'commits', count(*), 53230 from commits
union all select 'merge_requests', count(*), 9208 from merge_requests
union all select 'cartoes', count(*), 17027 from cartoes
union all select 'kanban_eventos', count(*), 183422 from kanban_eventos;
