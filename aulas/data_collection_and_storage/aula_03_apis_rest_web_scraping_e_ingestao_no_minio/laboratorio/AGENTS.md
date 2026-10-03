# AGENTS.md · aula_03_api_scraping

Regras para o agente de código (OpenCode) nesta pasta. Leia este arquivo antes de qualquer etapa.

## Escopo

- Projeto: monitor de preços de livros. Scraping de https://books.toscrape.com e cotação GBP para BRL pela API PTAX do Banco Central (https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata), com gravação direta no MinIO.
- Trabalhe somente dentro de `aula_03_api_scraping/`.
- Siga a sequência SDD: `docs/00_persona.md`, `docs/01_objetivos_negocio.md`, `specs/spec.md`, `specs/plan.md`, `specs/tasks.md`, implementação tarefa a tarefa, `docs/atam.md` e `docs/adr/`.
- Uma etapa por vez. Mostre o plano antes de editar e pare ao fim da etapa.

## Fontes de verdade

- Os arquivos em `docs/` e `specs/`, nesta ordem de precedência: spec > plan > tasks.
- `docker-compose.yml`, `.env.example` e `requirements.txt` desta pasta.
- Se dois documentos se contradisserem, pare e pergunte.

## Regras de conteúdo

- Não invente números, SLAs, volumes ou limites. Valor sem origem recebe a marcação "hipótese — validação pendente".
- Separe fato, lacuna e suposição.
- Preserve os IDs existentes (P1, OBJ-01, RF-01, RNF-01, T-01, ADR-001).
- Toda escolha técnica aponta para um RF ou RNF.

## Regras de coleta

- Toda requisição HTTP tem timeout explícito.
- Requisições ao books.toscrape.com usam o `USER_AGENT` do `.env`, respeitam `SCRAPER_INTERVALO_SEGUNDOS` e nunca rodam em paralelo.
- Consulte `robots.txt` em cada execução e registre o resultado.
- Retry apenas para timeout, erro de conexão, 408, 429 e 5xx, com backoff exponencial, jitter, respeito a `Retry-After` e limite de `HTTP_MAX_TENTATIVAS`.
- O HTML é tratado como bytes: o parser recebe `response.content` e o MinIO recebe os bytes originais.
- O bruto é gravado antes de qualquer extração. A extração lê do MinIO, não da rede.

## Segredos

- Credenciais só no `.env` (ou `.env.railway`), que não são versionados.
- Nunca escreva segredos em código, testes, logs, manifestos, metadados de objeto, prompts ou commits.
- Não leia nem imprima o conteúdo do `.env`. Use os nomes das variáveis.

## Comandos permitidos

- `python`, `pytest`, `pip install -r requirements.txt`
- `docker compose up -d --wait`, `docker compose ps`, `docker compose logs minio`, `docker compose exec minio mc ...` (somente leitura e criação de buckets)
- `curl -sI` para inspecionar cabeçalhos das fontes
- `git status`, `git diff`

Peça autorização antes de: apagar objetos ou buckets, rodar a coleta completa contra o site, apontar para o MinIO do Railway, instalar pacotes fora do `requirements.txt`, fazer commit ou push.

## Gates

- Testes unitários não acessam a rede; usam fixtures em `tests/fixtures/`.
- Testes de gravação usam o MinIO local e um bucket de teste.
- Uma tarefa só é marcada como concluída em `specs/tasks.md` com o teste passando e o comando de verificação anotado.
