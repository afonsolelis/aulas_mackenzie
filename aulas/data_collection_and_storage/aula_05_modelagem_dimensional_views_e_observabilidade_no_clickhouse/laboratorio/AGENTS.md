# AGENTS.md · aula_05_dimensional

Regras para o agente de código nesta pasta, qualquer que seja o agente escolhido (Claude Code, Codex CLI, Gemini CLI, Cursor, Copilot ou outro). Leia este arquivo antes de qualquer etapa.

## Escopo

- Projeto: modelo dimensional (os cubos) e observabilidade no ClickHouse da turma, sobre a tabela `mackenzie.db_ingestion` (`timestamp` UInt64 em unix ms, `data_json` no tipo JSON, `data_tag`).
- Servidor: `https://clickhouse.afonsolelis.tech` (HTTPS, porta 443), usuário `turma`, banco `mackenzie`. Não há `clickhouse-client` nem Docker nesta aula: todo SQL vai por `python rodar_sql.py`.
- Domínios: `livros`, `ptax` e `telemetria`, como chegaram pelo servidor de ingestão da Aula 04.
- O banco `mackenzie` é de toda a turma. Todo objeto que o grupo cria começa com o prefixo do grupo. Nos arquivos `.sql`, escreva sempre `g00_`; o `rodar_sql.py` troca pelo `GRUPO` do `.env`.
- Tudo acontece no ClickHouse. Nenhum código Python novo além do `rodar_sql.py`, nenhum outro banco.
- Trabalhe somente dentro de `aula_05_dimensional/`.
- Uma etapa por vez. Mostre o plano antes de editar e pare ao fim da etapa.

## Sequência das etapas

| Etapa | Artefato |
|---|---|
| 00 | `.env` (a partir do `.env.example`), `rodar_sql.py`, `docs/prompts.md`, conexão testada |
| 01 | `specs/04_modelo_dimensional.md` (processo, grão, dimensões, medidas, aditividade, chave do grão) |
| 02 | `sql/001_dimensoes_e_fatos.sql`, `sql/002_carga_historico.sql` |
| 03 | `docs/views.md` (VIEW, MV incremental e MV refreshable, com o EXPLAIN de uma view) |
| 04 | `sql/003_relatorios_fechados.sql` |
| 05 | `sql/004_observabilidade.sql` (contadores por minuto e views em janela) |
| 06 | `sql/005_consultas.sql` e `docs/respostas.md` (as perguntas ao cubo, com o número e a consulta) |
| TBL | `docs/adr/ADR-006` a `ADR-008`, uma por questão do TBL da Aula 04, com status Proposta |

Não pule etapa. Nenhum DDL antes de `specs/04_modelo_dimensional.md` existir e ter o grão de cada fato em uma frase.

## Registro de prompts

Ao fim de cada etapa, acrescente em `docs/prompts.md` uma seção com: número e nome da etapa, data, o prompt recebido copiado literalmente e a lista de arquivos criados ou alterados. Nunca registre a senha.

## Regras de modelagem

- Todo fato declara o grão em uma frase ("uma linha é ...") e a chave do grão. O teste do grão é: com `FINAL`, `count()` igual a `uniqExact(chave do grão)`.
- Medida não aditiva (preço, velocidade, cotação) nunca é somada; use média, mínimo, máximo ou último valor. Medida semiaditiva (estoque) soma entre livros, não entre dias.
- `dim_data` é gerada (chave AAAAMMDD), não vem da fonte. Dimensões de livro e de caminhão são SCD tipo 1.
- `tipo_boletim` da PTAX é dimensão degenerada: fica no fato.
- Fatos e `dim_livro` usam `ReplacingMergeTree(versao_ms)` com `versao_ms = timestamp` da tabela de pouso, porque a ingestão entrega pelo menos uma vez (e o professor reenvia telemetria durante a aula). Leitura de fato e de dimensão usa `FINAL`.
- Campos do JSON são lidos com `data_json.caminho::Tipo`. Conversões dentro de view materializada usam `OrZero` ou `OrNull`: um erro ali faz falhar o INSERT na tabela de pouso.
- Datas e horas ficam em `America/Sao_Paulo`.

## Regras das views

- Dimensões e fatos: view materializada incremental (`CREATE MATERIALIZED VIEW mackenzie.g00_mv_... TO mackenzie.g00_...`). Ela só vê os blocos inseridos depois de existir; o histórico, que já está em `db_ingestion`, entra por `INSERT ... SELECT` com o mesmo SELECT, num arquivo que pode rodar mais de uma vez sem mudar o resultado lido com `FINAL`.
- Relatórios fechados (os cubos): view materializada refreshable (`REFRESH EVERY ...`), só com dias anteriores a hoje. Para rodar na hora: `SYSTEM REFRESH VIEW` seguido de `SYSTEM WAIT VIEW`.
- Observabilidade corrente: view comum com janela `now() - INTERVAL ...` sobre contadores por minuto em `SummingMergeTree`, ou sobre `db_ingestion` filtrada por `timestamp`. Os contadores começam quando a view nasce; não faça carga do histórico deles.
- `WINDOW VIEW` e `LIVE VIEW` ficam fora: a primeira é experimental no ClickHouse 25.8, a segunda está obsoleta.

## Regras de conteúdo

- Não invente números. Todo número em `docs/` vem de uma consulta registrada com o comando que a gerou.
- Separe fato, lacuna e suposição.
- Mermaid sem ponto e vírgula em rótulos.

## Segredos

- A senha do usuário `turma` fica só no `.env`, que não é versionado.
- Não imprima o conteúdo do `.env`. Use os nomes das variáveis.

## Comandos permitidos

- `python rodar_sql.py sql/<arquivo>.sql` e `python rodar_sql.py -q "<consulta>"`
- `git status`, `git diff`

Peça autorização antes de: `DROP` ou `TRUNCATE` de qualquer tabela ou view, qualquer comando sobre `mackenzie.db_ingestion` que não seja SELECT, qualquer comando sobre objeto sem o prefixo do grupo, fazer commit ou push.
