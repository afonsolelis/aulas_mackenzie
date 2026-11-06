# Aula 05 · Laboratório: modelo dimensional e views no ClickHouse da turma

A Aula 04 terminou com tudo o que chegou pelo servidor de ingestão numa tabela de três colunas: `timestamp`, `data_json` no tipo JSON e `data_tag`. Esta aula parte dessa tabela, já carregada no ClickHouse da turma como `mackenzie.db_ingestion`, e monta sobre ela os cubos de dados: dimensões e fatos alimentados por views materializadas incrementais, relatórios fechados por views materializadas refreshable e a observabilidade corrente por views comuns com janela de tempo. No fim, o grupo responde perguntas de negócio a partir do modelo, e não da tabela de pouso.

Nada roda na máquina do aluno além do agente de código e de um script Python sem dependências (`rodar_sql.py`). Não há Docker nem `clickhouse-client` nesta aula.

Esta pasta é a referência do professor. O grupo reproduz as etapas no próprio repositório, na pasta `aula_05_dimensional/`, com o agente de código de sua preferência e os prompts CREATE dos slides e do material.

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `.env.example` | URL, usuário e senha do ClickHouse da turma e o `GRUPO`; o grupo copia para `.env` |
| `rodar_sql.py` | roda um `.sql` pela interface HTTPS, um comando por vez, trocando `g00_` pelo prefixo do grupo; só biblioteca padrão |
| `AGENTS.md` | regras para o agente de código na pasta `aula_05_dimensional/` |
| `sql/000_db_ingestion.sql` | a estrutura da tabela de pouso, já criada; o grupo não roda |
| `sql/001_dimensoes_e_fatos.sql` | `g00_dim_data`, `g00_dim_livro`, `g00_dim_caminhao`, quatro fatos e as views materializadas incrementais que os alimentam |
| `sql/002_carga_historico.sql` | carga do que já estava em `db_ingestion` antes das views existirem |
| `sql/003_relatorios_fechados.sql` | dois relatórios fechados (cubos) com views materializadas refreshable |
| `sql/004_observabilidade.sql` | contadores por minuto e três views em janela |
| `sql/005_consultas.sql` | teste do grão, consultas na estrela, tipo de cada view, janelas e as cinco perguntas ao cubo |
| `professor/carregar_pouso.py` | recarrega `db_ingestion` a partir do `dados_aula_04.zip`, se a turma apagar a tabela |
| `professor/reenviar_ao_vivo.py` | durante a aula, reinsere telemetria com o horário de agora para as janelas mostrarem dado |

## O servidor da turma

| Item | Valor |
|---|---|
| Endereço | `https://clickhouse.afonsolelis.tech` (HTTPS, porta 443) |
| Console no navegador | `https://clickhouse.afonsolelis.tech/play` |
| Usuário | `turma` (senha no `.env.example` e no slide da aula) |
| Banco | `mackenzie`, compartilhado por toda a turma |
| Prefixo | cada grupo cria seus objetos com `gNN_` (`g01_dim_livro`, `g01_mv_fato_preco_livro` ...) |
| Versão | ClickHouse 25.8 |
| Limites por consulta | 1 GB de memória e 300 s |

O banco é de aprendizado: a turma pode criar, apagar e recriar qualquer objeto, inclusive `db_ingestion`. Um `DROP TABLE` acidental se desfaz em até 8 minutos com `UNDROP TABLE mackenzie.db_ingestion` (usuário administrador); depois disso, ou depois de um `TRUNCATE`, o professor recarrega com `professor/carregar_pouso.py`.

## Horário (07/11/2026)

Em cada etapa o grupo cola o prompt CREATE no agente, e a teoria da etapa é apresentada enquanto o agente trabalha. O gate fecha a etapa.

| Horário | Parte |
|---|---|
| 8h30 às 8h40 | Etapa 00: retomada da Aula 04 e conexão com o ClickHouse da turma |
| 8h40 às 9h20 | TBL da Aula 04, três questões (sala `mack-dcs-a04-2026-2`) |
| 9h20 às 9h40 | café |
| 9h40 às 10h00 | Etapa 01: o grão de cada fato |
| 10h00 às 10h30 | Etapa 02: dimensões, fatos e views materializadas incrementais |
| 10h30 às 10h50 | Etapa 03: o que é uma view e como ela funciona no ClickHouse |
| 10h50 às 11h15 | Etapa 04: os cubos fechados com view materializada refreshable |
| 11h15 às 11h35 | Etapa 05: observabilidade corrente com views em janela |
| 11h35 às 12h00 | Etapa 06: perguntas ao cubo |
| 12h00 às 12h10 | fechamento |

## Antes da aula (professor)

```bash
cd laboratorio/professor
export CLICKHOUSE_INGESTAO_PASSWORD=...   # DCS_CLICKHOUSE_INGESTAO_PASSWORD, no .env da raiz do repositório
python3 - <<'PY'                          # confere a tabela de pouso: 1.000, 40 e 31.265
import os, base64, urllib.request
a = base64.b64encode(f"ingestao:{os.environ['CLICKHOUSE_INGESTAO_PASSWORD']}".encode()).decode()
r = urllib.request.Request("https://clickhouse.afonsolelis.tech/", data=b"SELECT data_tag, count() FROM mackenzie.db_ingestion GROUP BY data_tag ORDER BY data_tag", headers={"Authorization": f"Basic {a}"})
print(urllib.request.urlopen(r).read().decode())
PY
```

Às 11h10, antes da Etapa 05, deixe o reenvio rodando num terminal até o fim da aula:

```bash
python reenviar_ao_vivo.py                # 40 linhas de telemetria a cada 5 s, com timestamp de agora
```

Cada reenvio é um INSERT em `db_ingestion` e dispara as views materializadas de todos os grupos. O script usa `materialized_views_ignore_errors = 1`: a view quebrada de um grupo não derruba o INSERT dos outros.

## Etapa 00 · Conexão com o ClickHouse da turma

```bash
mkdir -p aula_05_dimensional/sql && cd aula_05_dimensional
# copie para cá o rodar_sql.py, o AGENTS.md e o .env.example desta pasta
cp .env.example .env                      # troque GRUPO=g00 pelo número do grupo
python rodar_sql.py -q "SELECT currentUser(), version()"
python rodar_sql.py -q "SELECT data_tag, count() AS linhas FROM mackenzie.db_ingestion GROUP BY data_tag ORDER BY data_tag"
python rodar_sql.py -q "SELECT data_tag, toJSONString(data_json) FROM mackenzie.db_ingestion LIMIT 1 BY data_tag"
```

Esperado: `turma` e `25.8.33.6`; livros 1.000, ptax 40, telemetria 31.265. O mesmo SELECT roda no console `https://clickhouse.afonsolelis.tech/play` (usuário `turma`, senha do `.env`).

`rodar_sql.py` separa o arquivo nos `;` que estão fora de texto e de comentário, troca `g00_` pelo `GRUPO` do `.env` e envia cada comando na mesma sessão pela interface HTTPS, que aceita um comando por requisição.

## Etapa 01 · O grão de cada fato

Antes de qualquer DDL, o grupo escreve `specs/04_modelo_dimensional.md` com, para cada processo de negócio, o grão em uma frase, as dimensões, as medidas e se cada medida soma (aditiva, semiaditiva ou não aditiva).

| Fato | Processo | Grão: uma linha é... | Chave do grão | Medidas |
|---|---|---|---|---|
| `g00_fato_preco_livro` | coleta de preço | um livro num dia de coleta | `data_key`, `upc` | `preco_gbp` (não aditiva), `qtd_estoque` (semiaditiva: soma entre livros, não entre dias) |
| `g00_fato_cotacao_ptax` | boletim do BCB | um boletim PTAX | `moeda`, `data_hora`, `tipo_boletim` | `cotacao_compra`, `cotacao_venda` (não aditivas) |
| `g00_fato_leitura_telemetria` | posição do caminhão | uma leitura de um caminhão num instante | `caminhao`, `instante` | `velocidade_kmh` (não aditiva), contagem de leituras |
| `g00_fato_alerta_direcao` | alerta do tacógrafo | um alerta de direção contínua de um caminhão num instante | `caminhao`, `instante` | `direcao_continua_min` (não aditiva) |

O teste do grão é uma consulta: com `FINAL`, o número de linhas do fato é igual ao número de combinações distintas da chave do grão (`sql/005_consultas.sql`, consulta 1). Se for maior, a tabela tem duas linhas para o mesmo fato e o grão declarado está errado.

## Etapa 02 · Dimensões, fatos e views materializadas incrementais

```bash
python rodar_sql.py sql/001_dimensoes_e_fatos.sql
python rodar_sql.py -q "SELECT count() FROM mackenzie.g00_fato_preco_livro"     # 0: a view só vê INSERT novo
python rodar_sql.py sql/002_carga_historico.sql
```

Cada fato tem uma view materializada `g00_mv_*` que lê `mackenzie.db_ingestion` e grava na tabela do fato (`TO mackenzie.g00_fato_...`). A view é um gatilho de INSERT: a cada bloco inserido na tabela de pouso, o ClickHouse roda o SELECT da view sobre esse bloco e insere o resultado no destino. Ela não vê o que já estava na tabela. Como as 32.305 linhas já estão lá quando a aula começa, o fato nasce vazio, e o `002` carrega o histórico com o mesmo SELECT.

- `g00_dim_livro` e os fatos usam `ReplacingMergeTree(versao_ms)`: a reentrega (pelo menos uma vez, e o reenvio do professor na Etapa 05) e uma segunda carga do histórico geram cópias, que o `FINAL` junta na leitura.
- `g00_dim_caminhao` sai do fato de leitura por uma view em cascata (`g00_mv_dim_caminhao`), com `SimpleAggregateFunction(min/max)` para a primeira e a última leitura.
- A telemetria chega em dois formatos (`CAM-0451|29/10/26 06:00:55|...` e `CAM-0451 29-10-2026 06:05:55 GPS ...`), mais alertas `TAC;` e ruído (`ERR SAT`, `#RADIO`). A view usa `OrZero` e `OrNull` nas conversões, porque um erro de conversão dentro da view faz falhar o INSERT na tabela de pouso.

Gate: `sql/005_consultas.sql`, consultas 1 e 2.

## Etapa 03 · O que é uma view e como ela funciona

| Objeto | Guarda dado? | Quando o SELECT roda | Sobre o quê | Uso nesta aula |
|---|---|---|---|---|
| `VIEW` | não, guarda a consulta | a cada leitura da view | as tabelas inteiras, no estado do momento | views em janela |
| `MATERIALIZED VIEW ... TO` | sim, na tabela de destino | a cada INSERT na tabela de origem | só o bloco recém-inserido | dimensões, fatos e contadores |
| `MATERIALIZED VIEW ... REFRESH` | sim, na tabela de destino | no horário do `REFRESH` | as tabelas inteiras; troca o conteúdo de uma vez | cubos fechados |

`EXPLAIN SELECT * FROM mackenzie.g00_v_saude_ingestao_15min` mostra que a view comum é só o SELECT dela. A consulta 5 do `005` lista as 13 views do grupo com o tipo de cada uma. O ClickHouse também tem `WINDOW VIEW`, que agrega por janelas de tempo no próprio motor, mas no 25.8 ela é experimental e só funciona com o analisador antigo (`allow_experimental_analyzer = 0`), na criação e na leitura; fica fora do laboratório.

## Etapa 04 · Os cubos fechados com view materializada refreshable

```bash
python rodar_sql.py sql/003_relatorios_fechados.sql
python rodar_sql.py -q "SYSTEM REFRESH VIEW mackenzie.g00_rmv_preco_categoria_dia; SYSTEM WAIT VIEW mackenzie.g00_rmv_preco_categoria_dia;
                        SYSTEM REFRESH VIEW mackenzie.g00_rmv_telemetria_caminhao_dia; SYSTEM WAIT VIEW mackenzie.g00_rmv_telemetria_caminhao_dia"
python rodar_sql.py -q "SELECT * FROM mackenzie.g00_rel_preco_categoria_dia ORDER BY livros DESC LIMIT 5"
```

- `g00_rel_preco_categoria_dia`: preço médio por categoria e dia em GBP e em BRL, com o último Fechamento PTAX até o dia (`ASOF LEFT JOIN`). Grão do cubo: categoria × dia.
- `g00_rel_telemetria_caminhao_dia`: leituras, velocidade média e máxima, primeira e última leitura e a parte das leituras no formato com espaço. Grão do cubo: caminhão × dia.

As duas rodam todo dia à 01h00 UTC, 22h00 em Brasília (`REFRESH EVERY 1 DAY OFFSET 1 HOUR`), e só incluem dias anteriores a hoje: um dia publicado não muda depois. O `SYSTEM REFRESH VIEW` antecipa o horário. `system.view_refreshes` mostra o último sucesso, o próximo horário e a exceção, se houver (consulta 7 do `005`).

## Etapa 05 · Observabilidade corrente com views em janela

Com o `reenviar_ao_vivo.py` do professor rodando:

```bash
python rodar_sql.py sql/004_observabilidade.sql
python rodar_sql.py -q "SELECT * FROM mackenzie.g00_v_saude_ingestao_15min"
python rodar_sql.py -q "SELECT * FROM mackenzie.g00_v_caminhoes_5min ORDER BY linhas_5min DESC"
```

Duas views materializadas incrementais contam por minuto o que entra (`g00_obs_ingestao_minuto`, por `data_tag`) e o que a telemetria descartou (`g00_obs_telemetria_descartes_minuto`, por motivo), em `SummingMergeTree`. As três views em janela usam `now() - INTERVAL`:

- `g00_v_saude_ingestao_15min`: linhas por `data_tag` nos últimos 15 minutos e há quantos segundos chegou o último dado;
- `g00_v_caminhoes_5min`: caminhões que transmitiram nos últimos 5 minutos, lido direto de `db_ingestion` pelo `timestamp`;
- `g00_v_descartes_telemetria_1h`: descartes por motivo e a parte do total.

Os contadores começam a contar quando a view nasce. As 32.305 linhas da carga não aparecem neles, e as janelas ficam vazias enquanto não chega dado novo: é o reenvio do professor que as acende. Uma carga do histórico com `SummingMergeTree` somaria duas vezes se fosse repetida, e a observabilidade mede o processo de agora em diante.

## Etapa 06 · Perguntas ao cubo

```bash
python rodar_sql.py sql/005_consultas.sql
```

O grupo responde em `docs/respostas.md`, cada resposta com o número e a consulta que o gerou:

| Pergunta | De onde sai | Resposta na preparação |
|---|---|---|
| P1. Entre as categorias com pelo menos 5 livros, qual tem o preço médio mais alto em reais? | `g00_rel_preco_categoria_dia` | New Adult, 6 livros, £ 46,38 × 7,1899 = R$ 333,49 |
| P2. Quantos exemplares há em estoque por categoria? (semiaditiva) | `g00_fato_preco_livro` + `g00_dim_livro` | Default 1.345, Nonfiction 975, Sequential Art 686 |
| P3. Em que hora do dia os caminhões andam mais rápido? (não aditiva) | `g00_fato_leitura_telemetria` | 0h, 78,4 km/h de média em 1.200 leituras |
| P4. Qual caminhão passou mais tempo ao volante sem pausa? | `g00_fato_alerta_direcao` | CAM-3126, 360 min (6h00), 9 alertas |
| P5. A venda do GBP subiu ou caiu entre o primeiro e o último Fechamento? | `g00_fato_cotacao_ptax` | subiu 7,2%, de 6,7072 para 7,1899 |

## Números da preparação (05/11/2026, ClickHouse 25.8.33.6 da VPS)

Rodado como grupo `g00` com `rodar_sql.py`, do 001 ao 005; os objetos foram apagados depois.

| Medida | Valor |
|---|---|
| `db_ingestion` | livros 1.000, ptax 40, telemetria 31.265 (32.305 linhas) |
| Teste do grão (com `FINAL` = chaves do grão) | `fato_preco_livro` 1.000, `fato_cotacao_ptax` 40, `fato_leitura_telemetria` 28.800, `fato_alerta_direcao` 69 |
| Destino das 31.265 linhas de telemetria | leitura no formato barra 22.432, leitura no formato espaço 6.368, descarte `#RADIO` 1.464, descarte `ERR SAT` 932, alerta de direção 69 |
| Views do grupo | 13: 8 incrementais, 2 refreshable, 3 comuns |
| Reenvio de 40 linhas | `g00_v_saude_ingestao_15min` passa a mostrar telemetria 40; o fato de leitura continua com 28.800 linhas com `FINAL` |
