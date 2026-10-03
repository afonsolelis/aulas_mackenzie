# AGENTS.md · aula_05_modelagem

Regras para o agente de código (OpenCode) nesta pasta do repositório do grupo.

## Escopo

- Trabalhe somente dentro de `aula_05_modelagem/`. Leia, sem alterar, `aula_04_*/` (silver e gold da Aula 04) e `aula_01_*/docs/` (convenções SDD).
- Domínio: monitor de preços de livros (books.toscrape.com) com cotação GBP→BRL da PTAX, já gravados no silver do MinIO.
- Duas trilhas: modelo relacional no PostgreSQL (local e Railway) e modelo dimensional em DuckDB, com a gold gravada no MinIO.

## Sequência SDD

Uma etapa por prompt: persona → objetivos de negócio → spec → plan → tasks → implementação → ATAM. Ao terminar a etapa, pare e mostre o que mudou. Mostre o plano antes de editar arquivos.

## Fontes de verdade

1. `docs/00_persona.md`, `docs/01_objetivos_negocio.md`, `specs/spec.md`, `specs/plan.md`, `specs/tasks.md`.
2. O schema real do silver, lido com `DESCRIBE SELECT * FROM read_parquet(...)` no DuckDB. Não presuma nomes de colunas.
3. `sql/` com os DDLs versionados. Toda mudança de esquema vira um arquivo novo numerado (`004_...sql`); arquivos já aplicados não são editados.

## Regras

- Não invente números, volumes, SLAs ou prazos. Quando faltar valor, escreva "hipótese — validação pendente".
- Separe fato, lacuna e suposição.
- Preserve IDs RF-xx, RNF-xx, CEN-xx e ADR-xxx.
- Segredos só em `.env` (no `.gitignore`) ou em variáveis do Railway. Nunca em prompt, commit, log ou arquivo versionado. Nunca imprima `DATABASE_PUBLIC_URL` inteira.
- Toda carga é idempotente: reexecutar o mesmo dia produz as mesmas contagens.
- Todo DDL roda duas vezes seguidas sem erro.

## Comandos permitidos

- `docker compose up -d`, `docker compose ps`, `docker compose logs`, `docker compose down` (sem `-v`, salvo pedido explícito).
- `docker compose exec -T postgres psql ...` e `docker run --rm -i postgres:16 psql ...`.
- `python -m venv`, `pip install` dentro do venv, `pytest`, `duckdb`.
- `railway variable list`, `railway logs`, `railway status`. Comandos que criam ou apagam serviços no Railway (`railway add`, `railway delete`, `railway volume`) só com confirmação do grupo.

## Gates de cada tarefa

1. DDL aplicado duas vezes sem erro.
2. Contagens do silver = contagens carregadas + rejeitadas (com motivo).
3. Reexecução do mesmo dia não muda contagens.
4. Testes de grão, órfãos e vigência SCD2 retornam zero.
5. Evidência registrada em `docs/evidencias/` (saída de comando, sem segredos).
