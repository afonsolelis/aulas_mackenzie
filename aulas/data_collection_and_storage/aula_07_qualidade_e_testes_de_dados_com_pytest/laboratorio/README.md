# Aula 07 · Laboratório opcional de Pydantic, VCR e Testcontainers

Data Collection and Storage · MBA Engenharia de Dados · semana de 28/11 a 05/12/2026

Laboratório opcional para a semana depois da aula de 28/11/2026. Em sala, a Aula 07 usa a bancada de `../bancada/bancada_aula_07.html`, que roda pytest no navegador. Na semana, os testes vão para o código real do projeto pelos seis prompts CREATE do material da Aula 07 (`../material/material_aula_07_qualidade_e_testes_de_dados_com_pytest.html`, seção 15). Este laboratório não tem prompts próprios: ele explica o mecanismo de Pydantic, VCR e Testcontainers e traz um exemplo de referência que roda.

Roteiro completo: `roteiro_pydantic_e_testes.html`

## O que fica nesta pasta

| Arquivo | Para que serve |
|---|---|
| `README.md` | este resumo |
| `roteiro_pydantic_e_testes.html` | roteiro com o mecanismo de cada ferramenta, a preparação do ambiente e a conferência antes do commit |
| `requirements-dev.txt` | dependências de validação e teste, com versões testadas em 03/10/2026 |
| `exemplo/` | referência mínima: contrato da leitura IoT da Aula 06 (`LeituraBruta` e `LeituraNormalizada`), testes de unidade e um teste com Testcontainers subindo o MinIO |

O `exemplo/` mostra o mecanismo e serve de régua para conferir o que o agente produz. Ele não é a solução do projeto.

## Pré-requisitos

- Codespace aberto no repositório do grupo (a imagem universal traz Docker e Python 3).
- Pastas das Aulas 03 (scraping de books.toscrape.com e PTAX, com `bronze/books_toscrape/` e `bronze/ptax/` no MinIO) e 06 (sensores, RabbitMQ, transformador e ClickHouse) no repositório.
- `.env` com `S3_ENDPOINT_URL`, `S3_ACCESS_KEY`, `S3_SECRET_KEY` e `S3_REGION=us-east-1`, como nas Aulas 02 a 04.
- Agente de código de sua preferência (Claude Code, Codex CLI, Gemini CLI, OpenCode, Cursor ou Copilot).

## Passo 0 · Conferir o Docker

```bash
docker version --format '{{.Server.Version}}'
docker run --rm hello-world
```

Se o segundo comando falhar, os testes de integração serão pulados. Resolva antes de seguir (seção 9.5 do roteiro).

## Passo 1 · Preparar o repositório do grupo

Rode o prompt 0 do material na raiz do repositório. Ele cria `tests/unit`, `tests/contract`, `tests/integration` e `tests/qualidade`, o `pytest.ini` com o marcador `integracao` e a matriz de rastreabilidade. Use `exemplo/pytest.ini` como modelo e as versões de `requirements-dev.txt` no arquivo de dependências de desenvolvimento do projeto.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements-dev.txt
python -c "import pydantic, testcontainers, vcr; print(pydantic.VERSION)"
```

Acrescente ao `.gitignore` do repositório: `.venv/`, `.env`, `.pytest_cache/`, `__pycache__/`.

## Passo 2 · Rodar o exemplo de referência (opcional, 5 minutos)

```bash
LAB=<caminho>/aulas_mackenzie/aulas/data_collection_and_storage/aula_07_qualidade_e_testes_de_dados_com_pytest/laboratorio
rm -rf /tmp/exemplo_aula07 && cp -r $LAB/exemplo /tmp/exemplo_aula07
cd /tmp/exemplo_aula07
pytest -m "not integracao" -q   # unidade: sem Docker, sem rede
pytest -q --durations=5         # inclui o MinIO em contêiner
```

Resultado registrado pelo professor em 03/10/2026 (Python 3.12, Docker 29, imagem já baixada): 10 testes passaram em 1,86 s; a subida do MinIO consumiu 1,59 s; os 9 testes de unidade levaram 0,11 s. Sem Docker, o teste de integração aparece como `SKIPPED` com o motivo "Docker indisponível neste ambiente". No primeiro uso, o download da imagem soma tempo.

## Passo 3 · Prompts da semana

Rode os seis prompts CREATE do material (seção 15), um por vez, com um commit por prompt. As seções 6 a 9 do roteiro dão o mecanismo que os prompts 1, 4 e 5 usam.

## Passo 4 · Comandos de teste

```bash
pytest tests/unit -q                                  # segundos, sem rede nem Docker
pytest tests/contract --record-mode=once -q           # grava cassetes na primeira execução
pytest tests/contract --block-network -q              # reproduz cassetes; rede bloqueada
pytest tests/integration -m integracao -q --durations=10
pytest tests/qualidade -q                             # testes sobre o dado
pytest -q                                             # suíte inteira antes do commit
```

O `pytest-recording` usa o modo `none` por padrão: sem cassete gravado, o teste falha com `CannotOverwriteExistingCassetteException` em vez de chamar a rede.

## Entregável

O entregável da semana é o do material da Aula 07 (seção 16.1): os testes de cada camada no repositório do projeto, ligados aos requisitos na matriz de rastreabilidade.

## Segredos

Credenciais do MinIO, do RabbitMQ, do ClickHouse e qualquer chave de API do agente ficam em `.env` ou no campo seguro do próprio agente, fora do Git. Antes de cada commit, procure nos cassetes:

```bash
grep -RniE "authorization|password|secret|token|api[_-]?key" tests/ || echo "nenhum segredo aparente"
```
