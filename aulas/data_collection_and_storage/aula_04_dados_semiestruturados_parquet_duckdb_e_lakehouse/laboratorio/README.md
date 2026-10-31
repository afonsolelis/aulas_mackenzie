# Aula 04 · Laboratório: servidor de ingestão com fila, DuckDB e ClickHouse

Data Collection and Storage · MBA Engenharia de Dados · 31/10/2026, 8h30 às 12h10

Roteiro da construção em etapas. A explicação de cada etapa e os prompts CREATE completos estão no material da aula: `../material/material_aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse.html`. O formato é o da Aula 03: o prompt vai para o agente e, enquanto ele trabalha, a aula explica e justifica o que o prompt pediu. Depois o grupo revisa o artefato e segue.

O código não está aqui. Ele nasce ao vivo, pelos prompts, no repositório do grupo, na pasta `aula_04_ingestao/`. Esta pasta traz só os arquivos de apoio.

## Arquivos de apoio

| Arquivo | Uso |
|---|---|
| `docker-compose.yml` | MinIO (`coollabsio/minio:RELEASE.2025-10-15T17-29-55Z`, portas 9000 e 9001), `minio-init` (buckets `raw`, `bronze`, `silver`, `gold`, `teste`), RabbitMQ (`rabbitmq:4.3.6-management`, portas 5672 e 15672) e ClickHouse (`clickhouse/clickhouse-server:26.8.15.10`, porta 8123) |
| `.env.example` | variáveis dos três serviços e do servidor de ingestão; copie para `.env` |
| `requirements.txt` | dependências Python validadas em 30/10/2026 |
| `AGENTS.md` | regras para o agente de código, incluindo o registro de prompts |
| `sql/001_db_ingestion.sql` | DDL da tabela de pouso, executado pelo ClickHouse na primeira subida |
| `sql/duckdb_cast.sql` | JSON cast no DuckDB lendo o histórico do lake |
| `sql/clickhouse_cast.sql` | JSON cast no ClickHouse (`JSONExtract*`, `CAST AS JSON`) |
| `sql/silver_livros_ptax.sql` | silver de livros e PTAX para a Aula 05, gerado a partir do lake |
| `sql/rodar_sql.py` | executa um `.sql` no DuckDB com o secret S3 montado a partir do `.env` |
| `fixtures/` | dados pequenos para quem não tem o MinIO das Aulas 02 e 03, e exemplos de envelope |

## Arquitetura

```text
curl / produtor --HTTP POST /ingest--> API (FastAPI) --valida envelope--> publica na fila --+
                                        400, 413, 422 se inválido; 202 depois do ack do broker  |
produtor --AMQP publish------------------------------------------------> fila ingestao (durável)
                                                                                                |
                         consumidor (thread no mesmo processo) <--------------------------------+
                           valida de novo; inválido vai para raw/ingestao_rejeitados/ e recebe ack
                           válido: acumula em memória; flush a cada FLUSH_N envelopes ou FLUSH_SEGUNDOS
                             1. DuckDB grava o lote em Parquet  -> s3://raw/ingestao/data_tag=X/data=D/lote_<ts>_<id>.parquet
                             2. clickhouse-connect insere o lote -> ingestao.db_ingestion
                             3. ack (multiple) das mensagens do lote
```

Envelope (contrato desta aula, só a casca):

```json
{"data_tag": "livros", "data": {"upc": "a897fe39b1053632", "titulo": "A Light in the Attic", "preco_gbp": 51.77}}
{"data_tag": "ptax", "data": [{"moeda": "GBP", "dataHoraCotacao": "2026-10-29 10:10:54.921", "tipoBoletim": "Abertura"}]}
{"data_tag": "telemetria", "data": {"arquivo": "raw/telemetria/pouso/CAM-0451_20261029T0600.txt", "numero_linha": 1, "linha": "CAM-0451|29/10/26 06:00:31|..."}}
```

- `data_tag` obrigatório, texto, em `DOMINIOS` do `.env`. Desconhecido: 422.
- `data` obrigatório: objeto, ou lista não vazia de objetos (cada objeto vira uma linha). Outro tipo: 422.
- Campo extra no envelope: 422. O envelope é fechado; o conteúdo de `data` é aberto e não é validado nesta aula (Aula 07).
- Corpo que não é JSON: 400. Corpo acima de `HTTP_MAX_BYTES` (1 MiB): 413.
- O servidor acrescenta o `timestamp` (unix em milissegundos); o produtor não manda.

Tabela de pouso (`sql/001_db_ingestion.sql`):

```sql
CREATE TABLE IF NOT EXISTS ingestao.db_ingestion
(
    timestamp UInt64,                  -- unix em milissegundos, hora da ingestão
    data_json String,                  -- o dado recebido, como texto JSON
    data_tag  LowCardinality(String)   -- o domínio
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(fromUnixTimestamp64Milli(toInt64(timestamp)))
ORDER BY (data_tag, timestamp);
```

## Horário

A teoria entra dentro das etapas. O TBL fica às 11h30.

| Horário | Parte |
|---|---|
| 8h30 às 8h45 | abertura: ingestão por puxar (Aulas 02 e 03) e por empurrar; a arquitetura inteira |
| 8h45 às 9h00 | Etapa 00: pasta, compose, buckets, venv, `docs/prompts.md` |
| 9h00 às 9h10 | Etapa 01: persona e objetivos |
| 9h10 às 9h30 | Etapa 02: contrato do envelope |
| 9h30 às 9h45 | Etapa 03: requisitos |
| 9h45 às 10h10 | Etapa 04: modelo de dados e DDL |
| 10h10 às 10h30 | Etapa 05: arquitetura e ADRs |
| 10h30 às 10h40 | Etapa 06: plano, tarefas e testes vermelhos |
| 10h40 às 10h50 | Etapa 07: contrato e API |
| 10h50 às 11h05 | Etapa 08: consumidor e gravadores |
| 11h05 às 11h15 | Etapa 09: produtores, execução e teste de queda |
| 11h15 às 11h30 | Etapa 10: JSON cast e silver para a Aula 05 |
| 11h30 às 12h00 | TBL |
| 12h00 às 12h10 | fechamento |
| semana | ATAM e Railway |

## Etapas e artefatos

| Etapa | Tema | Artefato |
|---|---|---|
| 00 | Preparação | pasta, três serviços no ar, buckets, venv, `docs/prompts.md` |
| 01 | Persona e objetivos | `docs/00_persona.md`, `docs/01_objetivos.md` |
| 02 | Contrato do envelope | `specs/01_contrato_envelope.md`, `specs/exemplos/*.json` |
| 03 | Requisitos | `specs/02_requisitos.md` (RF com Dado/Quando/Então, RNF com número) |
| 04 | Modelo de dados | `specs/03_modelo_de_dados.md`, `sql/001_db_ingestion.sql` |
| 05 | Arquitetura e ADRs | `docs/arquitetura.md`, `docs/adr/ADR-001` a `ADR-005` |
| 06 | Plano, tarefas e testes vermelhos | `specs/plan.md`, `specs/tasks.md`, `tests/` |
| 07 | Código: contrato e API | `src/contrato.py`, `src/api.py` |
| 08 | Código: consumidor e gravadores | `src/consumidor.py`, `src/lake.py`, `src/clickhouse.py` |
| 09 | Produtores e execução | `src/produtores/*.py`, gate de contagens, teste de queda |
| 10 | JSON cast e silver | `sql/duckdb_cast.sql`, `sql/clickhouse_cast.sql`, `sql/silver_livros_ptax.sql` |
| semana | ATAM e Railway | `docs/atam.md`, servidor e serviços no Railway |

Árvore final:

```text
aula_04_ingestao/
├── AGENTS.md
├── docker-compose.yml  .env.example  requirements.txt
├── docs/
│   ├── prompts.md
│   ├── 00_persona.md
│   ├── 01_objetivos.md
│   ├── arquitetura.md
│   ├── adr/ADR-001 ... ADR-005
│   └── atam.md                      (semana)
├── specs/
│   ├── 01_contrato_envelope.md
│   ├── exemplos/*.json
│   ├── 02_requisitos.md
│   ├── 03_modelo_de_dados.md
│   ├── plan.md, tasks.md
├── sql/
│   ├── 001_db_ingestion.sql
│   ├── duckdb_cast.sql, clickhouse_cast.sql, silver_livros_ptax.sql
│   └── rodar_sql.py
├── fixtures/
├── src/
│   ├── contrato.py, api.py, consumidor.py, lake.py, clickhouse.py, servidor.py
│   └── produtores/
└── tests/
```

## 1. Etapa 00 · Preparar a pasta e subir os serviços

No Codespace do repositório do grupo, na raiz:

```bash
mkdir -p aula_04_ingestao/{docs/adr,specs/exemplos,sql,src/produtores,tests}
# copie para aula_04_ingestao/ os arquivos de apoio desta pasta (incluindo sql/ e fixtures/)
cd aula_04_ingestao
printf '.env\n.env.*\n!.env.example\n.venv/\n__pycache__/\n.pytest_cache/\n' >> .gitignore
cp .env.example .env
git check-ignore .env            # deve imprimir: .env
openssl rand -base64 24          # gere uma senha para cada serviço
printf '# Registro de prompts\n' > docs/prompts.md
```

No `.env`, a senha do MinIO vai em `MINIO_ROOT_PASSWORD` e em `S3_SECRET_KEY` (o mesmo valor); RabbitMQ e ClickHouse recebem senhas próprias.

```bash
docker compose config --quiet && echo "compose ok"
docker compose up -d
docker compose up -d --wait minio rabbitmq clickhouse   # volta quando os três estão healthy
docker compose ps
docker compose logs minio-init                          # deve listar raw, bronze, silver, gold e teste
```

O `docker compose up -d --wait` sem nomes de serviço devolve código 1 mesmo com tudo no ar, porque o `minio-init` termina depois de criar os buckets (Compose 5.6.1). Por isso o `--wait` vai com os três serviços nomeados.

Ambiente Python:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Conferir o ClickHouse e a tabela criada pelo DDL montado em `docker-entrypoint-initdb.d`:

```bash
set -a; source .env; set +a
docker compose exec clickhouse clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" \
  -q "SELECT version(); SHOW CREATE TABLE ingestao.db_ingestion"
```

O DDL só roda na primeira subida, com o volume vazio. Se a tabela mudar depois, rode o arquivo de novo pelo `clickhouse-client` (`< sql/001_db_ingestion.sql`) ou recrie o volume com autorização.

Consoles: MinIO na porta 9001, RabbitMQ na 15672 (no Codespace, abra as portas encaminhadas).

## 2. Agente

```bash
echo "@AGENTS.md" > CLAUDE.md    # só no Claude Code
```

Use o agente de código de sua preferência, aberto nesta pasta. Outros agentes leem o `AGENTS.md` diretamente ou aceitam o arquivo colado no contexto. Rode os prompts das Etapas 01 a 10 do material, um por vez, e faça a revisão "Revise antes de seguir" depois de cada um. Ao fim de cada etapa, o agente acrescenta em `docs/prompts.md` o prompt literal, a data e os arquivos gerados.

## 3. Dados de entrada

Os produtores leem o que o grupo gravou nas aulas anteriores, no MinIO local:

- `livros`: `bronze/books_toscrape/data=D/livros.jsonl` (Aula 03), um envelope por linha, por HTTP;
- `ptax`: `bronze/ptax/moeda=GBP/data=D/cotacoes.jsonl` (Aula 03), uma mensagem com a lista, pela fila;
- `telemetria`: linhas dos TXT de `raw/telemetria/...` (Aula 02), cada uma como `{"arquivo", "numero_linha", "linha"}`, pela fila.

Quem não tem esses dados usa as fixtures desta pasta:

| Arquivo | Conteúdo |
|---|---|
| `fixtures/livros.jsonl` | 20 livros coletados do books.toscrape.com em 30/10/2026, no contrato do bronze da Aula 03 |
| `fixtures/ptax_cotacoes.jsonl` | 5 boletins PTAX GBP de 29/10/2026 (API Olinda do BCB), com `moeda` |
| `fixtures/telemetria/*.txt` | 12 lotes do caminhão CAM-0451, 29/10/2026 das 6h00 às 8h45, 200 linhas (gerador da Aula 02) |
| `fixtures/exemplos/valido_*.json` | 3 envelopes válidos, um por domínio |
| `fixtures/exemplos/invalido_*` | 7 inválidos (6 com 422 e 1 com 400), o código esperado está no nome |

Para um dia inteiro de telemetria, o gerador da Aula 02: `python ../aula_02_.../gerar_lotes.py --inicio 2026-10-29T00:00 --horas 24 --saida pouso` (1.920 lotes, 31.265 linhas, 1.956.243 bytes).

## 4. Etapa 07 · Gate da API

Com o servidor no ar (`python -m src.servidor` ou o comando definido no `plan.md`):

```bash
curl -s -w ' %{http_code}\n' localhost:8000/health
for f in fixtures/exemplos/*; do
  printf '%s ' "$(curl -s -o /dev/null -w '%{http_code}' -X POST localhost:8000/ingest \
    -H 'content-type: application/json' --data-binary @"$f")"; echo "$f"
done
# esperado: 202 para valido_*, 422 para invalido_422_*, 400 para invalido_400_*
head -c 1100000 /dev/zero | tr '\0' ' ' > /tmp/grande.json
curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:8000/ingest --data-binary @/tmp/grande.json   # 413
```

## 5. Etapa 09 · Gate de contagens

Depois de rodar os três produtores, a mesma contagem nos três lugares, por `data_tag`. Mensagens e linhas não são a mesma coisa: um envelope de PTAX com 40 boletins é uma mensagem e 40 linhas.

ClickHouse:

```bash
docker compose exec clickhouse clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" -q "
  SELECT data_tag, count() AS linhas, uniqExact(timestamp, data_json) AS distintas
  FROM ingestao.db_ingestion GROUP BY data_tag ORDER BY data_tag"
```

Lake, pelo DuckDB (primeira consulta de `sql/duckdb_cast.sql`):

```bash
python sql/rodar_sql.py sql/duckdb_cast.sql
```

Fila vazia e rejeitados:

```bash
docker compose exec rabbitmq rabbitmqctl list_queues name messages messages_unacknowledged
docker compose exec minio sh -c 'mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null && mc ls --recursive local/raw/ingestao_rejeitados/'
```

Teste de queda (no meio da carga de telemetria):

```bash
python -m src.servidor & SERVIDOR=$!
python -m src.produtores.telemetria_fila pouso &      # ou o produtor definido no plano
sleep 3; kill -9 $SERVIDOR                            # derruba sem flush e sem ack
docker compose exec rabbitmq rabbitmqctl list_queues name messages messages_unacknowledged
python -m src.servidor                                # reinicia; a fila reentrega o que não teve ack
```

Depois da drenagem, refaça as contagens. Nada se perde. Linhas repetidas só aparecem se o processo cair entre a gravação e o ack; a consulta 7 de cada arquivo de cast mostra quantas.

Checklist:

- [ ] `pytest -q` verde
- [ ] curl: 202, 422, 400 e 413 nos casos esperados
- [ ] por `data_tag`: linhas esperadas = linhas no ClickHouse = linhas no lake
- [ ] fila com 0 mensagens e 0 sem ack depois da drenagem
- [ ] envelope inválido publicado direto na fila aparece em `raw/ingestao_rejeitados/` com o motivo
- [ ] teste de queda: nenhuma linha perdida; duplicadas contadas e explicadas
- [ ] `git status --short` não lista `.env`

## 6. Etapa 10 · JSON cast e silver

```bash
python sql/rodar_sql.py sql/duckdb_cast.sql
docker compose exec -T clickhouse clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" \
  --time --multiquery < sql/clickhouse_cast.sql
python sql/rodar_sql.py sql/silver_livros_ptax.sql --var DATA=AAAA-MM-DD   # dia da coleta dos livros
```

O silver sai no mesmo contrato que a Aula 05 lê:

- `s3://silver/livros/data_coleta=D/livros.parquet`: `upc`, `url`, `titulo`, `categoria`, `avaliacao` (TINYINT), `preco_gbp` (DECIMAL(10,2)), `em_estoque` (BOOLEAN), `qtd_estoque` (INTEGER), `coletado_em` (TIMESTAMPTZ), `arquivo_origem`, `processado_em`; um por `upc`, fica a coleta mais recente;
- `s3://silver/ptax/ptax.parquet`: `moeda`, `data_hora_cotacao` (TIMESTAMP), `tipo_boletim`, `cotacao_compra` e `cotacao_venda` (DECIMAL(12,5)), `arquivo_origem`, `processado_em`; um por (`moeda`, `data_hora_cotacao`, `tipo_boletim`).

`arquivo_origem` passa a ser o Parquet do lake de onde a linha veio.

## 7. Layout esperado no MinIO

```text
raw/ingestao/data_tag=livros/data=AAAA-MM-DD/lote_<timestamp>_<id>.parquet
raw/ingestao/data_tag=ptax/data=AAAA-MM-DD/lote_<timestamp>_<id>.parquet
raw/ingestao/data_tag=telemetria/data=AAAA-MM-DD/lote_<timestamp>_<id>.parquet
raw/ingestao_rejeitados/data=AAAA-MM-DD/rejeitado_<timestamp>_<id>.json
silver/livros/data_coleta=AAAA-MM-DD/livros.parquet
silver/ptax/ptax.parquet
```

Cada Parquet do lake tem duas colunas, `timestamp` (UBIGINT, unix ms) e `data_json` (VARCHAR), com compressão ZSTD; `data_tag` e `data` vêm do caminho. A data é a da ingestão no horário de Brasília. Um flush com dois domínios grava dois arquivos. Cada rejeitado guarda `recebido_em_ms`, `motivo` e o `corpo` como chegou.

## 8. O que foi validado em 30/10/2026

Implementação de referência montada e medida na preparação (fora do repositório; o código do grupo nasce dos prompts). Máquina: notebook Intel Core i5-1345U (12 threads), 15 GiB de RAM, Linux, Docker 29.9.2, Compose 5.6.1, Python 3.12.3. Serviços e servidor na mesma máquina, sem rede entre eles. Cliente sequencial, uma conexão keep-alive. Mediana (p50) e percentil 95 (p95).

Dados usados: 1.000 livros coletados do books.toscrape.com em 30/10/2026 (páginas de detalhe, 50 categorias, 1 s entre requisições, 25 minutos); 40 boletins PTAX GBP de 20/10 a 29/10/2026 (API Olinda, 8 dias úteis, 5 boletins por dia); um dia de telemetria do gerador da Aula 02 (`--inicio 2026-10-29T00:00 --horas 24`, 20 caminhões, 1.920 lotes, 31.265 linhas, 1.956.243 bytes).

Contrato e DDL:

- `PARTITION BY toYYYYMM(fromUnixTimestamp64Milli(toInt64(timestamp)))` aceito pelo ClickHouse 26.8.15.10 sem ajuste; `1793452800123` cai na partição `202610`.
- Os 10 exemplos de `fixtures/exemplos/` devolveram o código do nome do arquivo (3 com 202, 6 com 422, 1 com 400); corpo de 1,1 MB devolveu 413.
- Três envelopes inválidos publicados direto na fila (tag `vendas`, `data` vazia, texto que não é JSON) foram para `raw/ingestao_rejeitados/data=2026-10-30/`, um arquivo cada, com `recebido_em_ms`, `motivo` e `corpo`; a fila terminou com 0 mensagens e 0 sem ack.

Latência do `POST /ingest` (1.000 requisições por caso, depois de 50 de aquecimento):

| Caso | Corpo | p50 | p95 |
|---|---|---|---|
| inválido, `data_tag` desconhecida (422) | 317 B | 0,53 ms | 1,00 ms |
| inválido, `data` vazia (422) | 34 B | 0,50 ms | 0,98 ms |
| válido, um objeto (202) | 319 B | 1,51 ms | 2,19 ms |
| válido, lista de 10 livros (202) | 2.922 B | 1,55 ms | 2,08 ms |
| válido, lista de 100 livros (202) | 28.932 B | 2,47 ms | 3,62 ms |

O 422 não toca a fila. A diferença para o 202, cerca de 1 ms, é a publicação com confirmação do broker.

Do POST até a linha aparecer no ClickHouse (30 POSTs, consulta ao ClickHouse a cada 10 ms):

| Configuração | p50 | p95 |
|---|---|---|
| `FLUSH_N=500`, `FLUSH_SEGUNDOS=2`, sem outro tráfego | 2.030 ms | 2.039 ms |
| `FLUSH_N=1` (flush a cada envelope), sem outro tráfego | 34 ms | 52 ms |
| `FLUSH_N=500`, `FLUSH_SEGUNDOS=2`, durante a carga de 31.265 linhas de telemetria | 145 ms | 2.039 ms |

Com pouco tráfego, quem dispara o flush é o relógio: a latência é `FLUSH_SEGUNDOS` mais uns 30 ms. Durante a carga, o lote enche antes e a latência cai para a casa de 150 ms.

Micro-lote: fila pré-carregada com o dia de telemetria (31.265 mensagens), consumidor sobe e drena. O tempo inclui a subida do servidor (cerca de 1 s).

| `FLUSH_N` | Tempo para drenar | Linhas/s | INSERTs | Partes criadas | Partes ativas ao fim | Objetos no lake | Bytes no lake |
|---|---|---|---|---|---|---|---|
| 1 | 524,5 s | 60 | 31.265 | 31.265 | 5 | 31.265 | 33.339.527 |
| 500 | 3,8 s | 8.147 | 63 | 63 | 3 | 63 | 619.050 |
| 5.000 | 3,3 s | 9.554 | 7 | 7 | 2 | 7 | 567.283 |

Com `FLUSH_N=1`, o ClickHouse fez cerca de 19.600 merges durante os 9 minutos para manter as partes ativas em 5 (contagem por minuto em `system.part_log`). O lake guardou 54 vezes mais bytes que com `FLUSH_N=500`, porque cada Parquet de uma linha carrega cabeçalho, rodapé e metadados.

Mesma carga menor (2.000 mensagens): `FLUSH_N=1` levou 22,0 s (91 linhas/s, 2.000 partes, 399 merges); `FLUSH_N=500`, 0,48 s (4 partes); `FLUSH_N=5000`, 2,53 s, porque o lote nunca enche e o flush espera os 2 s.

Queda (kill -9 do servidor no meio da carga de telemetria, `FLUSH_N=500`, reinício e drenagem):

| Momento do kill | Publicadas | Linhas no ClickHouse | Linhas no lake | Duplicadas | Perdidas |
|---|---|---|---|---|---|
| com 10.000 linhas no ClickHouse | 31.265 | 31.265 | 31.265 | 0 | 0 |
| com 20.000 linhas no ClickHouse | 31.265 | 31.265 | 31.265 | 0 | 0 |
| dentro do flush, entre o INSERT e o ack (pausa de teste de 3 s) | 31.265 | 31.765 | 31.765 | 500 (um lote) | 0 |

Morto fora do flush, o processo perde só o lote em memória, que não tinha ack, e a fila reentrega. Morto entre a gravação e o ack, o lote inteiro volta e é gravado de novo nos dois destinos: entrega pelo menos uma vez. A janela é curta (cerca de 10 ms por flush de 500), por isso o terceiro caso precisou de uma pausa artificial para acontecer de forma reproduzível.

Tamanho do dia de telemetria (31.265 linhas):

| Forma | Bytes |
|---|---|
| TXT original (1.920 arquivos) | 1.956.243 |
| JSON Lines `{"timestamp", "data"}` | 5.847.088 |
| JSON Lines com gzip | 550.383 |
| Parquet ZSTD no lake (63 arquivos, `FLUSH_N=500`) | 631.827 |
| Parquet ZSTD em um arquivo só | 580.547 |
| ClickHouse, LZ4 padrão, depois de `OPTIMIZE FINAL` | 1.012.247 comprimido, 5.253.229 descomprimido |

O envelope JSON triplica o texto original (nomes de campo e escapes repetidos em cada linha). O Parquet ZSTD guarda o mesmo dia em um terço do TXT.

JSON cast (tempo de consulta, mediana de 5 execuções depois de uma de aquecimento):

| Consulta | Dados reais (1.000 livros) | Livros x1.000 (1.000.000 linhas) |
|---|---|---|
| DuckDB `->>` com `CAST` sobre o Parquet do lake | 3,8 ms | 211 ms |
| DuckDB `json_extract_string` / `json_extract` | 3,9 ms | 194 ms |
| DuckDB `from_json` com estrutura declarada | 3,5 ms | 130 ms |
| DuckDB sobre Parquet já tipado (silver) | | 7,5 ms |
| ClickHouse `JSONExtractString` / `JSONExtractFloat` | 3,4 ms | 146 ms |
| ClickHouse `simpleJSONExtract*` | 4,6 ms | 75 ms |
| ClickHouse `CAST(data_json AS JSON)` na consulta | 6,4 ms | 957 ms |
| ClickHouse coluna do tipo `JSON` (subcolunas na escrita) | | 21 ms |
| ClickHouse coluna `JSON` com tipo declarado (`data.preco_gbp.:Float64`) | | 16 ms |

Telemetria (contar linhas por caminhão com expressão regular sobre `linha`): 8,7 ms no DuckDB e 12,6 ms no ClickHouse; 2.396 das 31.265 linhas não têm caminhão (`#RADIO` e `ERR SAT`).

Com mil livros, todas as formas respondem em poucos milissegundos. Com um milhão de linhas, `CAST AS JSON` na hora da consulta é a mais lenta (o texto é convertido de novo a cada consulta) e a coluna do tipo `JSON` é a mais rápida (as subcolunas já estão separadas no disco). A coluna `JSON` inferiu `coletado_em` como `DateTime` e converteu `2026-10-30T19:27:52-03:00` para `2026-10-30 22:27:52` em UTC: o deslocamento original se perde.

Silver para a Aula 05 (`sql/silver_livros_ptax.sql --var DATA=2026-10-30`): 1.000 livros, 1.000 UPCs, preço de 10,00 a 59,99, nenhum sem `arquivo_origem`; 40 boletins PTAX, 5 por dia. Tipos conferidos com `DESCRIBE`, iguais aos do contrato.

## 9. Semana · ATAM e Railway

- `docs/atam.md` com os cenários: ClickHouse fora por 20 minutos, MinIO fora, processo morto entre a gravação e o ack, produtor que manda 10 vezes o volume normal, payload que muda de forma (`linha` vira `texto`), envelope com `data_tag` nova. Cada cenário com estímulo, resposta esperada, medida e evidência (comando e número).
- Railway: o plano de teste permite até cinco serviços. MinIO (já existe desde a Aula 01), RabbitMQ, ClickHouse e o servidor de ingestão somam quatro. Confira quantos o grupo já usa antes de criar.

## 10. Entregável

Pasta `aula_04_ingestao/` no repositório do grupo com `AGENTS.md`, `docs/` (prompts, persona, objetivos, arquitetura, cinco ADRs), `specs/` (contrato, exemplos, requisitos, modelo, plano, tarefas), `sql/`, `src/` rodando, `tests/` passando e o gate da Etapa 09 registrado em `docs/prompts.md` com os números do grupo.

## 11. Encerrar

```bash
docker compose down          # mantém os volumes com os dados locais
docker compose down -v       # apaga também os volumes (pede autorização no agente)
```
