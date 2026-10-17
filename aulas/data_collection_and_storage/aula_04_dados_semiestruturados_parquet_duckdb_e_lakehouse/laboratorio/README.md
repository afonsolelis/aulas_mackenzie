# Laboratório da Aula 04: lakehouse raw, bronze, silver e gold com DuckDB sobre o MinIO

Data Collection and Storage, MBA Engenharia de Dados, Mackenzie. Aula de 31/10/2026, 8h30 às 12h10.

Na disciplina, os quatro buckets da Aula 01 têm papéis fixos: `raw` guarda os bytes como a fonte entregou; `bronze` guarda o que já foi extraído, em JSON Lines, ainda sem tipos garantidos; `silver` guarda Parquet tipado e deduplicado; `gold` guarda as tabelas de consumo. O job desta aula lê o `raw` sem alterá-lo, extrai os lotes TXT de telemetria para o bronze, lê o bronze dos livros e da PTAX que a Aula 03 gravou, e escreve silver e gold.

Este roteiro acompanha o material da aula (`../material/material_aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse.html`). O material traz a explicação e os sete prompts CREATE completos; aqui ficam os comandos, na ordem em que são executados.

O código do job não está nesta pasta. Ele nasce durante a aula, pelos prompts, dentro do repositório do grupo. Os arquivos `sql/*.sql` são exemplos de leitura e escrita validados; o job pode reaproveitá-los ou reescrevê-los.

## Arquivos de apoio

| Arquivo | Para que serve |
|---|---|
| `docker-compose.yml` | MinIO local (imagem `ghcr.io/coollabsio/minio:RELEASE.2025-10-15T17-29-55Z`) e um serviço que cria os buckets `raw`, `bronze`, `silver` e `gold` |
| `.env.example` | Variáveis do MinIO local e do job; os nomes `S3_*` são os mesmos da Aula 02 |
| `requirements.txt` | `duckdb`, `boto3`, `beautifulsoup4`, `pytest` e `pytz` (exigido pelo DuckDB para entregar `TIMESTAMPTZ` ao Python), nas versões validadas |
| `AGENTS.md` | Regras para o agente de código: escopo, prefixos somente leitura, idempotência, comandos, segredos, gates |
| `Dockerfile` | Imagem modelo do job, com a extensão `httpfs` já instalada |
| `railway.json` | Configuração como código do serviço: build por Dockerfile, `cronSchedule` e `restartPolicyType` |
| `sql/rodar_sql.py` | Executa um `.sql` no DuckDB criando o secret S3 a partir do `.env`; com `--var DATA=D`, deriva `DATA_SEGUINTE` (D+1) |
| `sql/01_raw_telemetria.sql` | Schema on read dos lotes TXT da Aula 02: um arquivo vira linhas, as linhas são classificadas nos cinco formatos, retransmissões e manifesto |
| `sql/02_raw_bronze_livros_ptax.sql` | Schema on read do JSON da PTAX no raw, do HTML de detalhe como texto e do JSON Lines do bronze (Aula 03) |
| `sql/03_bronze_telemetria.sql` | Bronze da telemetria: extração por expressão regular, uma linha reconhecida por registro em JSON Lines, linhas não reconhecidas em quarentena |
| `sql/04_silver_telemetria.sql` | Silver de posições (uma por caminhão e minuto) e de alertas do tacógrafo, tipadas, em UTC, deduplicadas e com origem |
| `sql/05_silver_ptax.sql` | Silver da PTAX (`silver/ptax/ptax.parquet`), contrato combinado com a Aula 05 |
| `sql/06_silver_livros.sql` | Silver dos livros (`silver/livros/data_coleta=D/`), contrato combinado com a Aula 05 |
| `sql/07_gold.sql` | Gold: jornada diária por caminhão (horas de direção, velocidade média, quilometragem aproximada, alertas acima de 5h30) e preço do livro em BRL por dia (`ASOF JOIN` com o último fechamento da PTAX) |
| `sql/08_parquet_inspecao.sql` | Row groups, estatísticas min/max, a mesma pergunta em TXT, JSON Lines e Parquet, poda de partição no raw e na silver |
| `.gitignore` | Impede que `.env`, `.env.railway`, `.venv/` e Parquet local entrem no Git |

### Contrato das camadas da telemetria

| Camada | Objeto | Grão | O que se promete |
|---|---|---|---|
| Raw | `raw/telemetria/data=D/hora=H/caminhao=CAM-XXXX/lote_HHMM.txt` (D, H e HHMM em UTC, início da janela) | um lote de 15 minutos por caminhão | bytes como o provedor entregou; gravado pela Aula 02; o job só lê |
| Bronze | `bronze/telemetria/data_local=D/linhas.jsonl` (D no horário de Brasília) | uma linha reconhecida do TXT | `arquivo_origem`, `numero_linha`, `janela_utc`, `caminhao_arquivo`, `formato` (1 a 5) e os campos da linha como texto (`caminhao`, `data_hora_txt`, `latitude_txt`, `longitude_txt`, `velocidade_txt`, `tac_mot_txt`, `temp_bau_txt`, `duracao_txt`, `status_txt`, `texto`) |
| Bronze | `bronze/telemetria_quarentena/data_local=D/nao_reconhecidas.jsonl` | uma linha que nenhum formato explica | `arquivo_origem`, `numero_linha`, `janela_utc`, `caminhao_arquivo` e a `linha` original |
| Silver | `silver/posicoes/data_local=D/posicoes.parquet` | caminhão e minuto (UTC); entre cópias do mesmo minuto, a do lote mais recente | `caminhao`, `minuto_utc`, `instante_utc` (TIMESTAMPTZ), `data_local`, `latitude`, `longitude`, `velocidade_kmh`, `direcao_continua_min` (só formato 1), `temp_bau_c` (só firmware novo), `formato`, `janela_utc`, `arquivo_origem`, `numero_linha`, `processado_em` |
| Silver | `silver/alertas_tacografo/data_local=D/alertas.parquet` | caminhão e instante do alerta | `caminhao`, `instante_utc`, `data_local`, `direcao_continua_min`, `acima_de_5h30`, `status`, `janela_utc`, `arquivo_origem`, `numero_linha`, `processado_em` |
| Gold | `gold/jornada_caminhao_diaria/jornada_caminhao_diaria.parquet` | caminhão e dia no horário de Brasília | `minutos_com_posicao`, `horas_direcao`, `velocidade_media_kmh`, `km_aproximados`, `maior_direcao_continua_min`, `alertas_acima_5h30` |

Rádio (formato 2) e erro do enlace (formato 4) ficam só no bronze. As tabelas de livros e PTAX não mudam e seguem o contrato combinado com a Aula 05.

### O que foi validado em 16/10/2026

- `docker compose config` e `docker compose up` com a imagem e a tag acima: os quatro buckets foram criados pelo `minio-init` (portas remapeadas por variável, porque a 9000 estava ocupada na máquina da preparação).
- Lotes TXT de sete dias (24/10 a 30/10/2026, no horário de Brasília) gerados pelo `gerar_lotes.py` da Aula 02 com `--caminhoes 20 --inicio 2026-10-24T00:00 --horas 168 --seed 42 --firmware-novo 2026-10-28` (a data do firmware foi antecipada para que `TEMP_BAU` aparecesse na semana; o padrão do gerador é 2027-03-01), carregados no bucket `raw` com a chave e os metadados do contrato: 13.440 objetos, 13.779.255 bytes, e 168 manifestos em JSON Lines particionados pelo início da execução. Dois defeitos foram inseridos de propósito no caminhão `CAM-0451`: o lote das 11h15 de 27/10 cortado no meio da última linha, e duas posições repetidas no começo do lote seguinte (uma delas, 23h59 de 26/10, no lote das 00h00 de 27/10).
- Todos os arquivos `sql/*.sql` rodaram com `duckdb==1.5.6` contra o MinIO local. `05`, `06` e a parte de livros do `07` rodaram sobre um bronze sintético mínimo no formato da Aula 03; a validação com dados reais da PTAX e do books.toscrape.com é a de 03/10/2026.
- O dia local D vai das 03h UTC de D às 02h59 UTC de D+1. Com as quatro partições escritas no caminho, `read_text` abriu os 1.920 lotes do dia (1.924 `GET`). O mesmo dia lido pelo glob da semana inteira, sem filtro de partição, fez 13.454 `GET`; com filtro em `filename`, também (o filtro em `filename` não poda arquivos); com filtro nas colunas `data` e `hora`, 1.934 `GET`, porque a poda acontece mas o glob ainda lista o bucket. Os tempos estão no material, exemplo numérico 4.
- Com uma lista de globs, as colunas do caminho (`data`, `hora`) chegam como texto; o `03` declara o tipo. `?` no glob de `s3://` é tratado como início de query string e não encontra nada; use classes como `0[3-9]`.
- A classificação por expressão regular ancorada reconheceu 31.285 de 31.286 linhas do dia 27/10 (22.413 no formato 1, 6.388 no 3, 1.475 de rádio, 936 de erro do enlace, 73 alertas); a linha truncada foi para a quarentena com o arquivo e o número da linha.
- A silver do dia 27/10 ficou com 28.799 posições (1.440 minutos para 19 caminhões e 1.439 para o caminhão do lote truncado) e descartou as duas cópias inseridas: uma pela deduplicação, outra pelo filtro de data local. Com os lotes do gerador sem alteração, nenhum minuto aparece em dois lotes.
- A partir de 28/10, seis caminhões trazem `TEMP_BAU` (1.932 linhas no dia 28); uma expressão sem o trecho opcional rejeitaria essas linhas.
- Reprocessar 27/10 com `03`, `04` e `07` manteve os 28 objetos de bronze, silver e gold com os mesmos nomes e tamanhos.
- Durante as medições, rajadas de cerca de 13 mil requisições seguidas esgotaram as conexões locais e o DuckDB recebeu `Failure when receiving data from the peer`; com pausas entre as consultas, o erro não se repetiu.
- Um lote com um byte fora do UTF-8 (`ã` em Latin-1 numa mensagem de rádio) derrubou a leitura do dia inteiro: `read_text: could not read content of file ... as valid UTF-8 encoded text`. `read_blob` com `try(decode(content))` identifica o arquivo sem parar a leitura.
- `COPY ... (PARTITION_BY ...)` para `s3://` falha na segunda execução sem opção de sobrescrita; com `APPEND`, cria arquivos novos com UUID e duplica linhas (preparação de 03/10/2026). Por isso os exemplos gravam um objeto de nome fixo por data.
- `coletado_em` com deslocamento (`2026-10-03T09:31:12-03:00`) foi inferido por `read_json_auto` como `TIMESTAMP` 12:31:12 sem fuso; lido como texto com `columns` e convertido com `CAST(... AS TIMESTAMPTZ)`, ficou 09:31:12-03, que é o valor correto.
- A coleta de sábado (03/10/2026) recebeu na gold o fechamento PTAX de sexta (02/10/2026, venda 6,91210) pelo `ASOF JOIN`. `CotacaoMoedaPeriodo` rotula o fechamento como `Fechamento`; `CotacaoMoedaDia`, como `Fechamento PTAX`.
- O `Dockerfile` foi construído e executado contra o MinIO local em 03/10/2026; a extensão `httpfs` carregou a partir da imagem e o processo terminou com código 0.

O deploy no Railway não foi executado nesta validação. Os comandos da Etapa 8 seguem a documentação do Railway consultada em 03/10/2026.

## Pré-requisitos (feitos nas Aulas 01 a 03)

- Codespace aberto no repositório do grupo.
- Agente de código de sua preferência (Claude Code, Codex CLI, Gemini CLI, OpenCode, Cursor ou Copilot) lendo o `AGENTS.md`.
- MinIO publicado no Railway com domínio público para a porta 9000, e o bucket `raw` com dados da Aula 02 (`raw/telemetria/...`) e da Aula 03 (PTAX e páginas do books.toscrape.com).

Rode um prompt por vez e revise antes do próximo. Nenhuma chave de API entra no Git.

## Etapa 1. Criar a pasta da aula no repositório do grupo

```bash
cd /workspaces/<repositorio-do-grupo>
mkdir -p aula_04_lakehouse/{docs/adr,specs,src,tests,sql}
cd aula_04_lakehouse

BASE=https://raw.githubusercontent.com/afonsolelis/aulas_mackenzie/main/aulas/data_collection_and_storage/aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse/laboratorio
for f in docker-compose.yml .env.example requirements.txt AGENTS.md Dockerfile railway.json .gitignore; do
  curl -fsSLO "$BASE/$f"
done
for f in rodar_sql.py 01_raw_telemetria.sql 02_raw_bronze_livros_ptax.sql 03_bronze_telemetria.sql 04_silver_telemetria.sql 05_silver_ptax.sql 06_silver_livros.sql 07_gold.sql 08_parquet_inspecao.sql; do
  curl -fsSL -o "sql/$f" "$BASE/sql/$f"
done
touch src/__init__.py
ls -la . sql
```

Gate: sete arquivos na raiz, nove em `sql/`.

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
docker compose exec minio mc ls --recursive local/raw/telemetria | head -20
```

Anote os prefixos que aparecem. Os exemplos SQL assumem, da Aula 02, `raw/telemetria/data=AAAA-MM-DD/hora=HH/caminhao=CAM-XXXX/lote_HHMM.txt` (data, hora e HHMM em UTC, início da janela de 15 minutos) e `raw/_manifestos/telemetria/.../*.jsonl`; da Aula 03, `raw/ptax/moeda=GBP/data=AAAA-MM-DD/*.json`, `raw/books_toscrape/data=AAAA-MM-DD/livro=<slug>/detalhe.html`, `bronze/books_toscrape/data=AAAA-MM-DD/livros.jsonl` e `bronze/ptax/moeda=GBP/data=AAAA-MM-DD/cotacoes.jsonl`. Se o grupo gravou com outros nomes, ajuste os caminhos nos `.sql` antes de seguir. Os caminhos e colunas de `silver/livros` e `silver/ptax` não mudam: a Aula 05 depende deles.

Se o raw do grupo tiver poucas horas de telemetria, gere mais lotes com o gerador da Aula 02 e carregue com o coletor do grupo, como na Aula 02. Para ter um dia local completo, a coleta precisa cobrir das 0h às 23h59 no horário de Brasília.

## Etapa 3. Ambiente Python

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -c "import duckdb, boto3, bs4, pytest, pytz; print(duckdb.__version__)"
```

## Etapa 4. Schema on read no raw e no bronze, antes de escrever a spec

Escolha um dia local completo (`mc ls local/raw/telemetria/`; o dia D precisa das partições D e D+1):

```bash
python sql/rodar_sql.py sql/01_raw_telemetria.sql --var DATA=<AAAA-MM-DD>
python sql/rodar_sql.py sql/02_raw_bronze_livros_ptax.sql
python sql/rodar_sql.py sql/03_bronze_telemetria.sql --var DATA=<AAAA-MM-DD>
python sql/rodar_sql.py sql/04_silver_telemetria.sql --var DATA=<AAAA-MM-DD>
```

Observe e anote para a spec: quantos lotes e linhas o dia tem; quantas linhas cabem em cada um dos cinco formatos; que linhas foram para a quarentena e de que arquivo; quantas posições se repetem entre lotes; a diferença entre a partição em UTC e o horário de Brasília dentro das linhas; o envelope `value` da PTAX no raw; o UPC extraído do HTML de detalhe comparado com o bronze; e o tipo que a inferência deu a `coletado_em`.

## Etapa 5. Prompts SDD no agente de código

```bash
claude            # ou o agente que você usa
```

No Claude Code, crie antes um `CLAUDE.md` que importe as regras: `echo "@AGENTS.md" > CLAUDE.md`. Outros agentes leem o `AGENTS.md` diretamente ou aceitam o arquivo colado no contexto.

Execute os prompts do material, seção 11, um por vez. Depois de cada um, faça a revisão indicada antes de seguir.

| Prompt | Artefato | Gate antes do próximo |
|---|---|---|
| 1. Persona | `docs/00_persona.md` | duas personas de consumo, com decisão e frequência |
| 2. Objetivos de negócio | `docs/01_objetivos_negocio.md` | métricas sem números inventados |
| 3. Especificação | `specs/spec.md` | contrato de cada tabela bronze, silver e gold; todo RF/RNF com Dado/Quando/Então |
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

docker compose exec minio mc ls --recursive local/bronze/telemetria
docker compose exec minio mc ls --recursive local/silver
docker compose exec minio mc ls --recursive local/gold
```

Gates:

- A segunda execução não muda o número de objetos em `bronze/telemetria`, `silver` e `gold` nem a contagem de linhas da partição.
- Toda linha do bronze e da silver tem `arquivo_origem` e `numero_linha`.
- O resumo mostra quantas linhas foram para a quarentena.
- O processo termina sozinho e imprime o tempo total.

Meça em vez de citar números:

```bash
docker compose exec minio mc du local/raw/telemetria
docker compose exec minio mc du local/bronze/telemetria
docker compose exec minio mc du local/silver/posicoes
python sql/rodar_sql.py sql/08_parquet_inspecao.sql --var DATA=<AAAA-MM-DD>
```

Registre no `docs/atam.md` os bytes de cada camada, os bytes lidos, as requisições e o tempo das consultas do `EXPLAIN ANALYZE`, com a data e o volume em que foram medidos.

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
railway variable set S3_REGION=us-east-1 BUCKET_RAW=raw BUCKET_BRONZE=bronze BUCKET_SILVER=silver BUCKET_GOLD=gold
railway variable list
```

Crie os buckets de destino no MinIO do Railway, uma vez:

```bash
docker compose exec minio mc mb --ignore-existing railway/bronze railway/silver railway/gold
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
