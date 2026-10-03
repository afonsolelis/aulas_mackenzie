# Aula 03 · Laboratório: monitor de preços de livros

Data Collection and Storage · MBA Engenharia de Dados · 24/10/2026, 8h30 às 12h10

Roteiro da prática guiada. A explicação de cada passo e os sete prompts CREATE completos estão no material da aula: `../material/material_aula_03_apis_rest_web_scraping_e_ingestao_no_minio.html` (seções 11 a 16).

O código não está aqui. Ele nasce ao vivo, pelos prompts, no repositório do grupo. Esta pasta traz só os arquivos de apoio.

## Arquivos de apoio

| Arquivo | Uso |
|---|---|
| `docker-compose.yml` | MinIO local (`coollabsio/minio:RELEASE.2025-10-15T17-29-55Z`), API S3 na porta 9000 e console na 9001 |
| `.env.example` | variáveis do MinIO, da coleta e das fontes; copie para `.env` |
| `requirements.txt` | dependências Python sugeridas |
| `AGENTS.md` | regras para o OpenCode nesta pasta |

## Fontes

- Scraping: https://books.toscrape.com (site de treino; os preços e as avaliações são aleatórios, como o próprio site avisa).
- API: PTAX do Banco Central, `https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata`, recurso `CotacaoMoedaPeriodo`, moeda `GBP`, datas no formato `MM-DD-AAAA`.

Fatos verificados em 03/10/2026: 50 categorias, 1.000 livros, 20 por página, 80 páginas de categoria; UPC e quantidade em estoque (`In stock (20 available)`) só aparecem na página de detalhe de cada livro, que tem entre 9 e 15 KiB; a coleta completa faz cerca de 1.081 requisições (perto de 18 minutos só de espera com 1 s de intervalo); `robots.txt` devolve 404; o servidor não declara charset no `Content-Type` (use `response.content`); a PTAX devolve `200` com lista vazia em sábado e em data no formato ISO, e `500` em data `DD-MM-AAAA`.

## 1. Preparar a pasta no repositório do grupo

No Codespace do repositório do grupo, na raiz:

```bash
mkdir -p aula_03_api_scraping/{docs/adr,specs,src,tests/fixtures}
# copie para aula_03_api_scraping/ os quatro arquivos de apoio desta pasta
cd aula_03_api_scraping
printf '.env\n.env.*\n!.env.example\n.venv/\n__pycache__/\n' >> .gitignore
cp .env.example .env
git check-ignore .env            # deve imprimir: .env
openssl rand -base64 24          # use como MINIO_ROOT_PASSWORD e S3_SECRET_KEY no .env
```

Edite o `.env`: senha do MinIO (o mesmo valor nas duas variáveis) e `USER_AGENT` com o endereço do repositório do grupo.

## 2. Subir o MinIO local e criar os buckets

```bash
docker compose config --quiet && echo "compose ok"
docker compose up -d --wait
docker compose ps                # STATUS deve mostrar (healthy)
docker compose exec minio sh -c 'mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" && mc mb --ignore-existing local/raw local/bronze'
docker compose exec minio mc ls local
```

O console web fica na porta 9001 (no Codespace, abra a porta encaminhada).

## 3. Ambiente Python

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 4. Conferir as fontes antes dos prompts

```bash
curl -sI https://books.toscrape.com/ | head -5
curl -s -o /dev/null -w "%{http_code}\n" https://books.toscrape.com/robots.txt
B="https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata"
curl -s "$B/CotacaoMoedaPeriodo(moeda=@moeda,dataInicial=@dataInicial,dataFinalCotacao=@dataFinalCotacao)?@moeda='GBP'&@dataInicial='10-17-2026'&@dataFinalCotacao='10-24-2026'&\$format=json&\$select=cotacaoVenda,dataHoraCotacao,tipoBoletim"
```

## 5. Agente

```bash
opencode
```

Dentro do OpenCode: `/models` para confirmar `openrouter/openrouter/free`. Rode os prompts 1 a 7 do material (seção 12), um por vez, e faça a revisão "Revise antes de seguir" depois de cada um. Limite do plano gratuito da OpenRouter: 20 requisições por minuto e 50 por dia para contas com menos de US$ 10 em créditos comprados. Em caso de 429, espere e repita.

Ordem dos artefatos:

1. `docs/00_persona.md`
2. `docs/01_objetivos_negocio.md`
3. `specs/spec.md`
4. `specs/plan.md`
5. `specs/tasks.md`
6. `src/` e `tests/`, uma tarefa por vez
7. `docs/atam.md` e `docs/adr/ADR-001-coleta-e-extracao-separadas.md`

## 6. Layout esperado no MinIO

`raw` guarda os bytes como chegaram da fonte (HTML e JSON); `bronze` guarda os registros extraídos em JSON Lines, ainda sem tipagem forte. Silver e gold vêm na Aula 04.

```text
raw/books_toscrape/data=AAAA-MM-DD/robots.txt.json
raw/books_toscrape/data=AAAA-MM-DD/categoria=_inicio/pagina=001.html
raw/books_toscrape/data=AAAA-MM-DD/categoria=<slug>/pagina=NNN.html
raw/books_toscrape/data=AAAA-MM-DD/livro=<slug_id>/detalhe.html
raw/ptax/moeda=GBP/data=AAAA-MM-DD/cotacao_moeda_periodo.json
raw/manifestos/data=AAAA-MM-DD/execucao=<id>.json
bronze/books_toscrape/data=AAAA-MM-DD/livros.jsonl
bronze/ptax/moeda=GBP/data=AAAA-MM-DD/cotacoes.jsonl
```

Campos combinados com as Aulas 04 e 05:

- `livros.jsonl`: `upc`, `url`, `titulo`, `categoria`, `avaliacao`, `preco_gbp`, `em_estoque`, `qtd_estoque`, `coletado_em`
- `cotacoes.jsonl`: `moeda`, `dataHoraCotacao`, `tipoBoletim`, `cotacaoCompra`, `cotacaoVenda`

A conversão para reais fica para a Aula 04. Durante o desenvolvimento, use `SCRAPER_CATEGORIAS=mystery_3,poetry_23` para não baixar as 1.000 páginas de detalhe a cada teste.

A data da partição é a data da coleta em `America/Sao_Paulo`. As chaves de páginas e da PTAX são determinísticas: reexecutar no mesmo dia sobrescreve, sem duplicar. Cada execução grava um manifesto próprio.

## 7. Verificação local

Troque `AAAA-MM-DD` pela data da coleta.

```bash
pytest -q
docker compose exec minio mc ls --recursive local/raw/books_toscrape/data=AAAA-MM-DD/ | wc -l
docker compose exec minio mc cat local/raw/ptax/moeda=GBP/data=AAAA-MM-DD/cotacao_moeda_periodo.json
docker compose exec minio mc find local/raw/books_toscrape/data=AAAA-MM-DD/ --name detalhe.html | wc -l
docker compose exec minio mc cat local/bronze/books_toscrape/data=AAAA-MM-DD/livros.jsonl | wc -l
docker compose exec minio mc cat local/bronze/ptax/moeda=GBP/data=AAAA-MM-DD/cotacoes.jsonl
docker compose exec minio mc ls local/raw/manifestos/data=AAAA-MM-DD/
```

Metadados de um objeto (o `mc stat` da imagem não exibiu os metadados de usuário; use o `boto3`):

```bash
python - <<'EOF'
import os, boto3
from dotenv import load_dotenv
load_dotenv()
s3 = boto3.client("s3", endpoint_url=os.environ["S3_ENDPOINT_URL"],
                  aws_access_key_id=os.environ["S3_ACCESS_KEY"],
                  aws_secret_access_key=os.environ["S3_SECRET_KEY"],
                  region_name=os.environ["S3_REGION"])
k = "books_toscrape/data=AAAA-MM-DD/categoria=mystery_3/pagina=001.html"
h = s3.head_object(Bucket="raw", Key=k)
print(h["ContentType"], h["Metadata"])
EOF
```

Checklist:

- [ ] número de linhas do `livros.jsonl` igual ao total que a página inicial declara e ao número de `detalhe.html`
- [ ] todo registro com `upc` preenchido e `qtd_estoque` inteiro
- [ ] resposta PTAX com ao menos um boletim `Fechamento` na janela
- [ ] metadados com `fonte-url`, `coletado-em`, `sha256` (somente ASCII; o `boto3` recusa acentos)
- [ ] reexecução no mesmo dia: mesma contagem de páginas e um manifesto a mais
- [ ] `git status --short` não lista `.env` nem `.env.railway`

## 8. MinIO no Railway

```bash
cp .env .env.railway
git check-ignore .env.railway    # deve imprimir: .env.railway
railway service                  # selecione o serviço minio
railway variable list            # consulte MINIO_ROOT_USER e MINIO_ROOT_PASSWORD
```

No `.env.railway`: `S3_ENDPOINT_URL=https://<dominio-gerado-pelo-railway>` (o domínio da porta 9000 criado na Aula 01), `S3_ACCESS_KEY` e `S3_SECRET_KEY` com os valores do serviço.

Os buckets `raw` e `bronze` já existem no Railway desde a Aula 01. Para conferir, use o `mc` do contêiner local (ele pede as chaves de forma interativa, sem deixá-las no histórico do shell):

```bash
docker compose exec minio mc alias set railway https://<dominio-gerado-pelo-railway>
docker compose exec minio mc mb --ignore-existing railway/raw railway/bronze
```

Depois de rodar coleta e extração com `.env.railway`:

```bash
docker compose exec minio mc ls --recursive railway/raw/books_toscrape/ | wc -l
docker compose exec minio mc cat railway/bronze/books_toscrape/data=AAAA-MM-DD/livros.jsonl | wc -l
```

O proxy do Railway pode devolver 502. Procure no manifesto gravações com mais de uma tentativa.

## 9. Entregável

Pasta `aula_03_api_scraping/` no repositório do grupo com `AGENTS.md`, `docs/` (persona, objetivos, `atam.md`, ADR-001), `specs/` (spec, plan, tasks), `src/` com coletores e extrator rodando, `tests/` passando e objetos de pelo menos uma data no MinIO do Railway em `raw/books_toscrape/`, `raw/ptax/`, `raw/manifestos/`, `bronze/books_toscrape/` e `bronze/ptax/`.

## 10. Encerrar

```bash
docker compose down          # mantém o volume com os dados locais
docker compose down -v       # apaga também o volume local
```
