# Laboratório da Aula 04: lakehouse raw, bronze, silver e gold com DuckDB sobre o MinIO

Data Collection and Storage, MBA Engenharia de Dados, Mackenzie. Aula de 31/10/2026, 8h30 às 12h10.

Na disciplina, os quatro buckets da Aula 01 têm papéis fixos: `raw` guarda os bytes como a fonte entregou; `bronze` guarda o que já foi extraído, em JSON Lines, ainda sem tipos garantidos (Aula 03); `silver` guarda Parquet tipado e deduplicado; `gold` guarda as tabelas de consumo. Este job lê `raw` e `bronze` e escreve só em `silver` e `gold`.

Este roteiro acompanha o material da aula (`../material/material_aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse.html`). O material traz a explicação e os sete prompts CREATE completos; aqui ficam os comandos, na ordem em que são executados.

O código do job não está nesta pasta. Ele nasce durante a aula, pelos prompts, dentro do repositório do grupo. Os arquivos `sql/*.sql` são exemplos de leitura e escrita validados; o job pode reaproveitá-los ou reescrevê-los.

## Arquivos de apoio

| Arquivo | Para que serve |
|---|---|
| `docker-compose.yml` | MinIO local (imagem `ghcr.io/coollabsio/minio:RELEASE.2025-10-15T17-29-55Z`) e um serviço que cria os buckets `raw`, `bronze`, `silver` e `gold` |
| `.env.example` | Variáveis do MinIO local e do job; os nomes `S3_*` são os mesmos da Aula 02 |
| `requirements.txt` | `duckdb`, `boto3`, `beautifulsoup4`, `pytest` e `pytz` (exigido pelo DuckDB para entregar `TIMESTAMPTZ` ao Python), nas versões validadas |
| `AGENTS.md` | Regras para o OpenCode: escopo, raw e bronze somente leitura, idempotência, comandos, segredos, gates |
| `Dockerfile` | Imagem modelo do job, com a extensão `httpfs` já instalada |
| `railway.json` | Configuração como código do serviço: build por Dockerfile, `cronSchedule` e `restartPolicyType` |
| `sql/rodar_sql.py` | Executa um `.sql` no DuckDB criando o secret S3 a partir do `.env` |
| `sql/01_raw_clima.sql` | Schema on read do JSON da Open-Meteo (Aula 02) |
| `sql/02_raw_bronze_livros_ptax.sql` | Schema on read do JSON da PTAX no raw, do HTML de detalhe como texto e do JSON Lines do bronze (Aula 03) |
| `sql/03_silver_clima.sql` | Silver do clima: tipada, deduplicada, com `arquivo_origem`, uma partição por data |
| `sql/04_silver_ptax.sql` | Silver da PTAX (`silver/ptax/ptax.parquet`), contrato combinado com a Aula 05 |
| `sql/05_silver_livros.sql` | Silver dos livros (`silver/livros/data_coleta=D/`), contrato combinado com a Aula 05 |
| `sql/06_gold.sql` | Gold: temperatura média diária por capital e preço do livro em BRL por dia (`ASOF JOIN` com o último fechamento da PTAX) |
| `sql/07_parquet_inspecao.sql` | Row groups, estatísticas min/max, projeção, pushdown e poda de partição |
| `.gitignore` | Impede que `.env`, `.env.railway`, `.venv/` e Parquet local entrem no Git |

### O que foi validado em 03/10/2026

- `docker compose config` e `docker compose up` com a imagem e a tag acima: os quatro buckets foram criados pelo `minio-init`.
- Todos os arquivos `sql/*.sql` rodaram com `duckdb==1.5.6` contra o MinIO local, sobre JSON real da Open-Meteo (bloco `hourly`), JSON real da PTAX (`CotacaoMoedaDia` e `CotacaoMoedaPeriodo`), HTML real da página de detalhe de um livro do books.toscrape.com e JSON Lines de bronze no formato da Aula 03.
- Reprocessar a mesma data com `03_silver_clima.sql` manteve um objeto e as mesmas linhas por partição.
- O manifesto em JSON Lines da Aula 02 (`raw/_manifestos/open_meteo/...jsonl`) foi lido com `format = 'newline_delimited'`.
- A silver do dia D usa a coleta da partição D+1 quando ela é a mais recente (coletas entre 0h e 3h UTC ainda falam do dia D no horário de Brasília). O filtro na coluna `data` descartou as partições fora da janela (`Scanning Files: 21/23` no plano).
- Um JSON com campo novo em `hourly` foi lido sem quebrar a silver; um JSON truncado derrubou a leitura da partição inteira (`Malformed JSON`), e `ignore_errors` não se aplica a JSON que não seja JSON Lines.
- `COPY ... (PARTITION_BY ...)` para `s3://` falha na segunda execução sem opção de sobrescrita; com `APPEND`, cria arquivos novos com UUID e duplica linhas. Por isso os exemplos gravam um objeto de nome fixo por data.
- `coletado_em` com deslocamento (`2026-10-03T09:31:12-03:00`) foi inferido por `read_json_auto` como `TIMESTAMP` 12:31:12 sem fuso; lido como texto com `columns` e convertido com `CAST(... AS TIMESTAMPTZ)`, ficou 09:31:12-03, que é o valor correto.
- A coleta de sábado (03/10/2026) recebeu na gold o fechamento PTAX de sexta (02/10/2026, venda 6,91210) pelo `ASOF JOIN`. `CotacaoMoedaPeriodo` rotula o fechamento como `Fechamento`; `CotacaoMoedaDia`, como `Fechamento PTAX`.
- O `Dockerfile` foi construído e executado contra o MinIO local; a extensão `httpfs` carregou a partir da imagem e o processo terminou com código 0.

O deploy no Railway não foi executado nesta validação. Os comandos da Etapa 8 seguem a documentação do Railway consultada em 03/10/2026.

## Pré-requisitos (feitos nas Aulas 01 a 03)

- Codespace aberto no repositório do grupo.
- OpenCode conectado à OpenRouter com o modelo `openrouter/free` (no OpenCode, `openrouter/openrouter/free`).
- MinIO publicado no Railway com domínio público para a porta 9000, e o bucket `raw` com dados da Aula 02 (`raw/open_meteo/...`) e da Aula 03 (PTAX e páginas do books.toscrape.com).

Os modelos gratuitos da OpenRouter aceitam 20 requisições por minuto e 50 por dia para contas que compraram menos de US$ 10 em créditos. Rode um prompt por vez; se aparecer erro 429, espere e repita.

## Etapa 1. Criar a pasta da aula no repositório do grupo

```bash
cd /workspaces/<repositorio-do-grupo>
mkdir -p aula_04_lakehouse/{docs/adr,specs,src,tests,sql}
cd aula_04_lakehouse

BASE=https://raw.githubusercontent.com/afonsolelis/aulas_mackenzie/main/aulas/data_collection_and_storage/aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse/laboratorio
for f in docker-compose.yml .env.example requirements.txt AGENTS.md Dockerfile railway.json .gitignore; do
  curl -fsSLO "$BASE/$f"
done
for f in rodar_sql.py 01_raw_clima.sql 02_raw_bronze_livros_ptax.sql 03_silver_clima.sql 04_silver_ptax.sql 05_silver_livros.sql 06_gold.sql 07_parquet_inspecao.sql; do
  curl -fsSL -o "sql/$f" "$BASE/sql/$f"
done
touch src/__init__.py
ls -la . sql
```

Gate: sete arquivos na raiz, oito em `sql/`.

## Etapa 2. Subir o MinIO local e trazer uma cópia do raw do Railway

Se o MinIO da Aula 02 ainda estiver rodando no Codespace, pare-o antes (`docker compose down` na pasta da Aula 02), porque as portas 9000 e 9001 são as mesmas.

```bash
cp .env.example .env
SENHA=$(openssl rand -base64 24)
sed -i "s|^MINIO_ROOT_PASSWORD=.*|MINIO_ROOT_PASSWORD=$SENHA|; s|^S3_SECRET_KEY=.*|S3_SECRET_KEY=$SENHA|" .env
unset SENHA

docker compose config -q && echo "compose ok"
docker compose up -d
docker compose ps -a
docker compose logs minio-init
```

Gates: `minio` aparece como `healthy`; `minio-init` termina com `Exited (0)` e o log lista `bronze/`, `gold/`, `raw/` e `silver/`; `git status` não lista `.env`.

Registre os aliases do `mc` dentro do contêiner. O alias `railway` sem chaves na linha de comando pede os valores de forma interativa, e eles não ficam no histórico do shell:

```bash
docker compose exec minio sh -c 'mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"'
docker compose exec minio mc alias set railway https://<dominio-da-porta-9000>
docker compose exec minio mc ls railway/raw
```

Copie o raw e o bronze do Railway para o MinIO local. O desenvolvimento acontece sobre a cópia; os dados do Railway continuam intocados:

```bash
docker compose exec minio mc mirror railway/raw local/raw
docker compose exec minio mc mirror railway/bronze local/bronze
docker compose exec minio mc du local/raw
docker compose exec minio mc du local/bronze
docker compose exec minio mc ls --recursive local/raw | head -20
```

Anote os prefixos que aparecem. Os exemplos SQL assumem, da Aula 02, `raw/open_meteo/data=AAAA-MM-DD/hora=HH/<cidade>.json` (data e hora em UTC) e `raw/_manifestos/open_meteo/.../*.jsonl`; da Aula 03, `raw/ptax/moeda=GBP/data=AAAA-MM-DD/*.json`, `raw/books_toscrape/data=AAAA-MM-DD/livro=<slug>/detalhe.html`, `bronze/books_toscrape/data=AAAA-MM-DD/livros.jsonl` e `bronze/ptax/moeda=GBP/data=AAAA-MM-DD/cotacoes.jsonl`. Se o grupo gravou com outros nomes, ajuste os caminhos nos `.sql` antes de seguir. Os caminhos e colunas de `silver/livros` e `silver/ptax` não mudam: a Aula 05 depende deles.

## Etapa 3. Ambiente Python

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -c "import duckdb, boto3, bs4, pytest, pytz; print(duckdb.__version__)"
```

## Etapa 4. Schema on read no raw e no bronze, antes de escrever a spec

Escolha uma data que exista no raw (`mc ls local/raw/open_meteo/`):

```bash
python sql/rodar_sql.py sql/01_raw_clima.sql
python sql/rodar_sql.py sql/02_raw_bronze_livros_ptax.sql
```

Observe e anote para a spec: o tipo inferido de `hourly` (STRUCT com listas), quantas vezes a mesma hora prevista se repete entre coletas, o envelope `value` da PTAX no raw, o UPC extraído do HTML de detalhe comparado com o bronze e o tipo que a inferência deu a `coletado_em`.

## Etapa 5. Prompts SDD no OpenCode

```bash
opencode
```

Execute os prompts do material, seção 10, um por vez. Depois de cada um, faça a revisão indicada antes de seguir.

| Prompt | Artefato | Gate antes do próximo |
|---|---|---|
| 1. Persona | `docs/00_persona.md` | duas personas de consumo, com decisão e frequência |
| 2. Objetivos de negócio | `docs/01_objetivos_negocio.md` | métricas sem números inventados |
| 3. Especificação | `specs/spec.md` | contrato de cada tabela silver e gold; todo RF/RNF com Dado/Quando/Então |
| 4. Plano | `specs/plan.md` | C4 em Mermaid, layout dos buckets, estratégia de idempotência |
| 5. Tarefas | `specs/tasks.md` | cada tarefa com RF/RNF e teste |
| 6. Implementação | `src/`, `tests/` | `python -m pytest -q` sem falhas, tarefa a tarefa |
| 7. Validação ATAM | `docs/atam.md`, `docs/adr/` | seis cenários de seis partes com evidência medida |

## Etapa 6. Rodar o job contra o MinIO local

```bash
set -a; source .env; set +a
python -m pytest -q
DATA_PROCESSAMENTO=<AAAA-MM-DD> python -m src.job_lakehouse
DATA_PROCESSAMENTO=<AAAA-MM-DD> python -m src.job_lakehouse   # segunda vez: mesmo resultado

docker compose exec minio mc ls --recursive local/silver
docker compose exec minio mc ls --recursive local/gold
```

Gates:

- A segunda execução não muda o número de objetos em `silver` nem a contagem de linhas da partição.
- Toda linha da silver tem `arquivo_origem`.
- O processo termina sozinho e imprime o tempo total.

Meça em vez de citar números:

```bash
docker compose exec minio mc du local/raw/open_meteo
docker compose exec minio mc du local/silver/clima
python sql/rodar_sql.py sql/07_parquet_inspecao.sql --var DATA=<AAAA-MM-DD>
```

Registre no `docs/atam.md` os bytes de cada camada, os bytes lidos e o tempo das duas consultas do `EXPLAIN ANALYZE`, com a data e o volume em que foram medidos.

## Etapa 7. Testar a imagem do job localmente

```bash
docker build -t aula04-job .
docker run --rm --env-file .env --network host -e DATA_PROCESSAMENTO=<AAAA-MM-DD> aula04-job
echo "código de saída: $?"
```

Gate: o contêiner termina com código 0 e o resumo aparece no log. Se ele não terminar, o cron do Railway vai pular as execuções seguintes.

## Etapa 8. Publicar o job no Railway como serviço com cron

Dentro de `aula_04_lakehouse/`, ligue a pasta ao projeto da Aula 01 e crie o serviço do job:

```bash
npm i -g @railway/cli        # se ainda não estiver instalado no Codespace
railway login --browserless
railway link                 # escolha o projeto onde está o serviço minio
railway add --service lakehouse-job
railway service              # selecione lakehouse-job
```

Variáveis do serviço. As credenciais usam referência ao serviço `minio` (sintaxe `${{SERVICE_NAME.VAR}}` do Railway), então nenhuma senha passa pelo terminal. As aspas simples impedem o shell de interpretar `${{...}}`:

```bash
railway variable set 'S3_ACCESS_KEY=${{minio.MINIO_ROOT_USER}}'
railway variable set 'S3_SECRET_KEY=${{minio.MINIO_ROOT_PASSWORD}}'
railway variable set S3_ENDPOINT_URL=https://<dominio-da-porta-9000>
railway variable set S3_REGION=us-east-1 BUCKET_RAW=raw BUCKET_SILVER=silver BUCKET_GOLD=gold
railway variable list
```

Crie os buckets de destino no MinIO do Railway, uma vez:

```bash
docker compose exec minio mc mb --ignore-existing railway/silver railway/gold
```

O `railway.json` desta pasta define o build por Dockerfile, `cronSchedule` e `restartPolicyType`. Confira o horário antes do deploy: o cron do Railway usa UTC, execuções precisam estar a pelo menos 5 minutos de distância, e se a execução anterior ainda estiver rodando a seguinte é pulada.

```bash
cat railway.json
railway up . --path-as-root --service lakehouse-job --ci
railway logs
```

Depois do deploy, abra o serviço no painel do Railway, em Settings, e confira se o campo Cron Schedule mostra a expressão do `railway.json`. Se não mostrar, preencha o campo manualmente com a mesma expressão.

Gates:

- O log do build mostra o uso do Dockerfile.
- Na primeira execução agendada, o log mostra o resumo e o fim do processo.
- `docker compose exec minio mc ls --recursive railway/silver` lista as partições da data processada.

Rede privada (opcional, a testar): o Railway resolve `SERVICE_NAME.railway.internal` entre serviços do mesmo projeto, com HTTP. Trocar `S3_ENDPOINT_URL` para `http://minio.railway.internal:9000` evita o proxy público e o 502 esporádico visto na Aula 02. Se o job não conectar, volte ao domínio público e registre o resultado no `docs/atam.md`.

## Etapa 9. Entrega

Na pasta `aula_04_lakehouse/` do repositório do grupo:

- `AGENTS.md`, `docs/00_persona.md`, `docs/01_objetivos_negocio.md`, `docs/atam.md`, `docs/adr/ADR-001-*.md`;
- `specs/spec.md`, `specs/plan.md`, `specs/tasks.md`;
- `src/` com o job, `tests/` com testes passando, `sql/` com as consultas usadas;
- `Dockerfile` e `railway.json`;
- silver e gold no MinIO do Railway, com a saída de `mc ls --recursive railway/silver railway/gold` colada em `docs/atam.md`;
- print ou log da execução agendada do cron (sem segredos).

Antes do commit:

```bash
git status --short
git diff --staged -- . ':!.env.example' | grep -nE "SECRET_KEY=|PASSWORD=|ACCESS_KEY=" && echo "PARE: possível segredo no diff"
```

## Encerrar

```bash
docker compose down        # mantém os dados no volume
docker compose down -v     # apaga também o volume local (só quando quiser recomeçar)
```

Ao fim da disciplina, decida com o grupo se o serviço `lakehouse-job` continua agendado. Cada execução consome crédito do Railway; se o projeto final não usar o job, apague o serviço no painel e confira em `railway logs` que nenhuma execução nova aparece.
