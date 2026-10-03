# Laboratório da Aula 02: coleta da Open-Meteo em JSON bruto no MinIO

Data Collection and Storage, MBA Engenharia de Dados, Mackenzie. Aula de 17/10/2026, 8h30 às 12h10.

Este roteiro acompanha o material da aula (`../material/material_aula_02_tipos_de_storage_e_coleta_em_object_storage_com_minio.html`). O material traz a explicação e os sete prompts CREATE completos; aqui ficam os comandos, na ordem em que são executados.

O código do coletor não está nesta pasta. Ele nasce durante a aula, pelos prompts, dentro do repositório do grupo.

## Arquivos de apoio

| Arquivo | Para que serve |
|---|---|
| `docker-compose.yml` | MinIO local (imagem `ghcr.io/coollabsio/minio:RELEASE.2025-10-15T17-29-55Z`) e um serviço que cria o bucket `raw` |
| `.env.example` | Variáveis do MinIO local e do coletor; vira `.env` e `.env.railway` |
| `requirements.txt` | Dependências sugeridas: `requests`, `boto3`, `pytest`, `responses` |
| `AGENTS.md` | Regras para o OpenCode: escopo, comandos permitidos, segredos, gates |
| `.gitignore` | Impede que `.env`, `.env.railway` e `.venv/` entrem no Git |

O `docker-compose.yml` foi validado com `docker compose config` e executado de ponta a ponta (bucket criado, versionamento ligado, objeto gravado com metadados e lido com `mc stat`).

## Pré-requisitos (feitos na Aula 01)

- Codespace aberto no repositório do grupo.
- OpenCode instalado e conectado à OpenRouter com o modelo `openrouter/free` (no OpenCode, `openrouter/openrouter/free`).
- MinIO publicado no Railway, com domínio público para a porta 9000, usuário e senha guardados fora do Git.

Os modelos gratuitos da OpenRouter aceitam 20 requisições por minuto e 50 por dia para contas que compraram menos de US$ 10 em créditos. Uma sessão do agente consome várias requisições por prompt. Rode um prompt por vez; se aparecer erro 429, espere e repita.

## Etapa 1. Criar a pasta da aula no repositório do grupo

```bash
cd /workspaces/<repositorio-do-grupo>
mkdir -p aula_02_coleta_json/{docs/adr,specs,src,tests}
cd aula_02_coleta_json

BASE=https://raw.githubusercontent.com/afonsolelis/aulas_mackenzie/main/aulas/data_collection_and_storage/aula_02_tipos_de_storage_e_coleta_em_object_storage_com_minio/laboratorio
for f in docker-compose.yml .env.example requirements.txt AGENTS.md .gitignore; do
  curl -fsSLO "$BASE/$f"
done
ls -la
```

Gate: os cinco arquivos aparecem em `ls -la`.

## Etapa 2. Subir o MinIO local

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

Gates:

- `minio` aparece como `healthy`.
- `minio-init` termina com `Exited (0)` e o log mostra `Bucket created successfully` (ou nada a criar, se o bucket já existia).
- `git status` não lista `.env`.

Para usar o `mc` local, registre o alias dentro do próprio contêiner (a imagem já traz o `mc`):

```bash
docker compose exec minio sh -c 'mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"'
docker compose exec minio mc ls local
docker compose exec minio mc version enable local/raw
docker compose exec minio mc version info local/raw
```

O console web fica na porta 9001. No Codespace, abra pela aba PORTS.

## Etapa 3. Ambiente Python

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -c "import requests, boto3, pytest, responses; print('ok')"
```

## Etapa 4. Conferir a fonte antes de escrever a spec

```bash
curl -s "https://api.open-meteo.com/v1/forecast?latitude=-23.55&longitude=-46.63&hourly=temperature_2m,relative_humidity_2m&timezone=America/Sao_Paulo&forecast_days=1" | python -m json.tool | head -30

curl -s -w "\nHTTP %{http_code}\n" "https://api.open-meteo.com/v1/forecast?latitude=-23.55&longitude=-46.63&hourly=temperatura"
```

O segundo comando mostra o formato de erro da API: HTTP 400 com `{"error": true, "reason": "..."}`.

## Etapa 5. Prompts SDD no OpenCode

Abra o OpenCode dentro de `aula_02_coleta_json/`:

```bash
opencode
```

Execute os prompts do material, seção 9, um por vez. Depois de cada um, faça a revisão indicada antes de seguir.

| Prompt | Artefato | Gate antes do próximo |
|---|---|---|
| 1. Persona | `docs/00_persona.md` | decisão, dor e frequência explícitas |
| 2. Objetivos de negócio | `docs/01_objetivos_negocio.md` | métricas sem números inventados |
| 3. Especificação | `specs/spec.md` | todo RF e RNF tem critério Dado/Quando/Então |
| 4. Plano | `specs/plan.md` | C4 em Mermaid e escolhas ligadas a RF/RNF |
| 5. Tarefas | `specs/tasks.md` | cada tarefa tem RF/RNF e teste |
| 6. Implementação | `src/`, `tests/` | `python -m pytest -q` sem falhas, tarefa a tarefa |
| 7. Validação ATAM | `docs/atam.md`, `docs/adr/` | cenários de seis partes com evidência |

## Etapa 6. Rodar contra o MinIO local

```bash
set -a; source .env; set +a
python -m pytest -q
python -m src.coletor
python -m src.coletor   # segunda vez na mesma hora: não pode criar objetos novos

docker compose exec minio mc ls --recursive local/raw/open_meteo/
docker compose exec -T minio mc find local/raw/open_meteo --name "*.json" | wc -l
docker compose exec -T minio mc ls --recursive --versions local/raw/open_meteo/ | wc -l
```

Gates:

- O número de objetos `.json` é igual ao número de cidades vezes o número de horas coletadas.
- A segunda execução na mesma hora não muda a contagem de objetos nem a de versões.

Inspecione um objeto (troque data, hora e cidade):

```bash
docker compose exec minio mc stat local/raw/open_meteo/data=2026-10-17/hora=12/sao_paulo.json
docker compose exec -T minio mc cat local/raw/open_meteo/data=2026-10-17/hora=12/sao_paulo.json | python -m json.tool | head -20
```

Confira o hash gravado nos metadados contra o conteúdo:

```bash
docker compose exec -T minio mc cat local/raw/open_meteo/data=2026-10-17/hora=12/sao_paulo.json | sha256sum
```

O valor precisa ser igual ao metadado de hash mostrado por `mc stat`.

## Etapa 7. Rodar contra o MinIO do Railway

Crie um segundo arquivo de ambiente, também fora do Git:

```bash
cp .env .env.railway
# edite .env.railway: S3_ENDPOINT_URL=https://<dominio-da-porta-9000>, S3_ACCESS_KEY e S3_SECRET_KEY do Railway
git status --short   # .env.railway não pode aparecer
```

Registre o alias `railway` no `mc`. Sem as chaves na linha de comando, o `mc` pede os valores de forma interativa e eles não ficam no histórico do shell:

```bash
docker compose exec minio mc alias set railway https://<dominio-da-porta-9000>
docker compose exec minio mc mb --ignore-existing railway/raw
docker compose exec minio mc version enable railway/raw
```

Rode o coletor apontando para o Railway:

```bash
set -a; source .env.railway; set +a
python -m src.coletor
python -m src.coletor

docker compose exec minio mc ls --recursive railway/raw/open_meteo/
docker compose exec -T minio mc find railway/raw/open_meteo --name "*.json" | wc -l
docker compose exec minio mc du railway/raw
```

Se aparecer erro 502 do proxy do Railway, o coletor deve tentar de novo com espera crescente e, por usar chave determinística, não pode duplicar objetos. Registre o que aconteceu no `docs/atam.md`.

Volte ao ambiente local antes de continuar desenvolvendo:

```bash
set -a; source .env; set +a
```

## Etapa 8. Entrega

Na pasta `aula_02_coleta_json/` do repositório do grupo:

- `AGENTS.md`, `docs/00_persona.md`, `docs/01_objetivos_negocio.md`, `docs/atam.md`, `docs/adr/ADR-001-*.md`;
- `specs/spec.md`, `specs/plan.md`, `specs/tasks.md`;
- `src/` com o coletor e `tests/` com testes passando;
- objetos no bucket `raw` do MinIO do Railway, com a saída de `mc ls --recursive` e de `mc stat` de um objeto colada em `docs/atam.md` como evidência.

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
