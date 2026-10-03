# Laboratório da Aula 05 · Modelagem relacional e dimensional

Data Collection and Storage · MBA Engenharia de Dados · 07/11/2026 · 8h30–12h10

Material completo: `../material/material_aula_05_modelagem_de_dados_relacional_e_dimensional.html`
Slides: `../slides/slide_aula_05_modelagem_de_dados_relacional_e_dimensional.html`

## O que este laboratório entrega

Sobre o silver de livros e PTAX construído na Aula 04, o grupo constrói duas modelagens dos mesmos dados:

1. Modelo relacional normalizado (3FN) num PostgreSQL publicado no Railway, com DDL versionado e carga idempotente a partir do silver.
2. Modelo dimensional (esquema estrela) em DuckDB, com SCD tipo 2 em `dim_livro`, gravado como Parquet na camada gold do MinIO.

O código do carregador nasce ao vivo pelos prompts CREATE do material. Esta pasta traz só os arquivos de apoio.

## Conteúdo da pasta

```text
laboratorio/
├── README.md               # este roteiro
├── AGENTS.md               # regras do agente para a pasta aula_05_modelagem/
├── docker-compose.yml      # Postgres 16 + MinIO local
├── .env.example            # variáveis (copie para .env, que fica fora do Git)
└── sql/
    ├── relacional/
    │   ├── 001_schema.sql          # DDL 3FN: categoria, livro, livro_url, observacao_preco, moeda, cotacao
    │   ├── 002_staging_e_carga.sql # staging + upsert idempotente
    │   └── 003_consultas.sql       # consultas de exemplo e EXPLAIN
    └── dimensional/
        ├── 001_schema.sql              # dim_data, dim_categoria, dim_livro (SCD2), dim_moeda, fatos
        ├── 002_staging_silver.sql      # views sobre o silver no MinIO
        ├── 003_restaurar_gold.sql      # recarrega a gold do MinIO (pule na 1ª execução)
        ├── 004_carga_dimensoes_scd2.sql
        ├── 005_carga_fatos.sql         # partição do dia apagada e regravada
        ├── 006_publicar_gold.sql       # COPY para s3://gold/dimensional/
        └── 007_consultas.sql           # mesma pergunta do relacional + testes que devem dar 0
```

Os SQLs foram validados em PostgreSQL 16 e DuckDB 1.5 com dados sintéticos no formato do contrato de silver descrito em `sql/dimensional/002_staging_silver.sql`. Os nomes de coluna do silver do seu grupo podem ser outros: ajuste as views de staging, não as tabelas.

## Passo 0 · Pasta no repositório do grupo

No Codespace do repositório do grupo:

```bash
mkdir -p aula_05_modelagem/{docs/adr,docs/evidencias,specs,src,tests}
cd aula_05_modelagem
# copie desta pasta: AGENTS.md, docker-compose.yml, .env.example e sql/
cp .env.example .env
grep -qxF '.env' ../.gitignore || echo '.env' >> ../.gitignore
openssl rand -base64 24   # use para POSTGRES_PASSWORD
openssl rand -base64 24   # use para MINIO_ROOT_PASSWORD
```

## Passo 1 · Ambiente local

```bash
docker compose up -d --wait
docker compose ps
docker compose exec -T postgres psql -U livraria -d livraria -v ON_ERROR_STOP=1 -f /sql/relacional/001_schema.sql
docker compose exec -T postgres psql -U livraria -d livraria -v ON_ERROR_STOP=1 -f /sql/relacional/001_schema.sql   # 2ª vez: deve passar
docker compose exec -T postgres psql -U livraria -d livraria -c '\dt livraria.*'
```

Se o silver da Aula 04 está no MinIO do Railway, aponte `S3_ENDPOINT` para ele. Se quiser trabalhar offline, copie o silver para o MinIO local com `mc mirror`.

## Passo 2 · Postgres no Railway

```bash
npm i -g @railway/cli          # se ainda não estiver instalado
railway login --browserless
railway link                   # escolha o projeto onde está o MinIO
railway add --database postgres
railway service                # confirme o nome do serviço criado (em geral "Postgres")
railway variable list --service Postgres --kv | cut -d= -f1   # lista só os nomes
```

O serviço expõe `DATABASE_URL`, `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD` e `PGDATABASE`. `DATABASE_URL` serve a outros serviços do mesmo projeto. Para conectar a partir do Codespace, abra no painel o serviço Postgres → Settings → Networking → Public Access. Isso cria um TCP Proxy e a variável `DATABASE_PUBLIC_URL`. O tráfego pelo TCP Proxy é cobrado como egress.

Copie `DATABASE_PUBLIC_URL` para o `.env` sem imprimi-la no terminal compartilhado e aplique o DDL com o cliente da imagem oficial:

```bash
set -a; source .env; set +a
docker run --rm -i postgres:16 psql "$DATABASE_PUBLIC_URL" -v ON_ERROR_STOP=1 < sql/relacional/001_schema.sql
docker run --rm -i postgres:16 psql "$DATABASE_PUBLIC_URL" -c '\dt livraria.*'
```

Alternativa para console interativo: `railway connect` abre `psql` direto (exige `psql` instalado; usa o TCP Proxy quando existe e, sem ele, um túnel SSH).

## Passo 3 · Prompts SDD

Siga os sete prompts CREATE do material, um por vez, com o OpenCode aberto em `aula_05_modelagem/`. Depois de cada um, responda ao quadro "Revise antes de seguir" antes do próximo. Os modelos gratuitos têm limite de 20 requisições por minuto e de 50 por dia para contas com menos de US$ 10 comprados: um prompt por vez.

## Passo 4 · Gates de aceite

| Gate | Comando ou evidência | Esperado |
|---|---|---|
| DDL idempotente | aplicar `001_schema.sql` duas vezes | sem erro |
| Integridade | `INSERT` com `livro_id` inexistente (`003_consultas.sql`, Q4) | violação de FK |
| Carga relacional | contagens do silver vs tabelas + rejeitadas | soma confere |
| Reexecução | rodar a carga do mesmo dia de novo | contagens iguais |
| SCD2 | `007_consultas.sql`, Q6 | livro com duas versões e períodos contíguos |
| Testes dimensionais | `007_consultas.sql`, T1 a T5 | todos 0 |
| Gold publicada | `mc ls railway/gold/dimensional/` | seis arquivos Parquet |
| Comparação | Q2 no Postgres e no DuckDB | mesmos números quando a categoria não mudou |

## Passo 5 · Encerramento e custo

O trial do Railway tem crédito único de US$ 5 por até 30 dias e limite de 5 serviços por projeto. Com MinIO, Postgres e o cron da Aula 04 no ar, acompanhe o consumo no painel. Ao fim da aula, se o Postgres não for usado na semana, desligue o Public Access ou exporte e remova o serviço. Antes de remover:

```bash
docker run --rm -i postgres:16 pg_dump "$DATABASE_PUBLIC_URL" --schema=livraria --no-owner > docs/evidencias/livraria_dump.sql
```

Não versione o dump se ele contiver dados que o grupo não quer publicar.

## Entregável

Pasta `aula_05_modelagem/` no repositório do grupo com: esqueleto SDD completo, ER e estrela em Mermaid (`specs/plan.md`), DDLs em `sql/`, Postgres no Railway carregado (evidência de contagens em `docs/evidencias/`), gold dimensional no MinIO (saída de `mc ls`) e `docs/atam.md` com os seis cenários da aula.
