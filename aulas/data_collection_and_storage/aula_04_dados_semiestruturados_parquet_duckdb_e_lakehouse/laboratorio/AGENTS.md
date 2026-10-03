# AGENTS.md (modelo para aula_04_lakehouse/)

Copie este arquivo para a raiz de `aula_04_lakehouse/` no repositório do grupo e ajuste o que estiver entre `<>`.

## Escopo

- Projeto: job batch que lê os buckets `raw` (bytes como a fonte entregou, Aulas 02 e 03) e `bronze` (extração em JSON Lines da Aula 03), grava Parquet tipado no bucket `silver` e tabelas de consumo no bucket `gold`, usando DuckDB com a extensão httpfs sobre a API compatível com S3 do MinIO.
- Trabalhe somente dentro de `aula_04_lakehouse/`. Não edite as pastas das outras aulas.
- Fontes de verdade, nesta ordem: `docs/00_persona.md`, `docs/01_objetivos_negocio.md`, `specs/spec.md`, `specs/plan.md`, `specs/tasks.md`.
- Preserve os identificadores `RF-xx`, `RNF-xx` e `T-xx`. Não renumere.

## Regras do lakehouse

- Os buckets `raw` e `bronze` são somente leitura para este job. Nunca escreva, mova ou apague objetos neles.
- Os caminhos e colunas de `silver/livros/data_coleta=D/` e `silver/ptax/` são o contrato da Aula 05. Não renomeie.
- Toda linha da silver carrega `arquivo_origem` (caminho do objeto bruto) e `processado_em`.
- Escrita em `silver` e `gold` é idempotente: reprocessar a mesma data substitui o objeto da partição, não acrescenta arquivos. Não use a opção `APPEND` do `COPY`.
- Um arquivo bruto inválido não derruba o lote inteiro sem registro: ele é listado no log com o caminho e o erro, e a decisão (pular ou falhar) segue a spec.
- O job processa uma data, imprime um resumo e termina com código 0 (sucesso) ou diferente de 0 (falha). Nada de laços infinitos nem `sleep` de espera: o cron do Railway pula a execução seguinte se a anterior não terminou.

## Regras de trabalho

- Mostre o plano de alteração antes de editar arquivos.
- Execute uma etapa por vez e pare ao final dela, aguardando revisão humana.
- Não invente números, SLAs, volumes ou limites. Quando faltar um valor, escreva "hipótese, validação pendente".
- Separe fato, lacuna e suposição em toda análise.
- Toda tarefa de código vem acompanhada de teste em `tests/` e só termina com `pytest` passando.

## Comandos permitidos

- `python -m pytest -q`
- `python -m src.job_lakehouse` (ou o ponto de entrada definido em `specs/plan.md`)
- `python sql/rodar_sql.py sql/<arquivo>.sql --var DATA=AAAA-MM-DD`
- `docker compose up -d`, `docker compose ps`, `docker compose logs minio`
- `docker compose exec minio mc ...` apenas para leitura (`ls`, `stat`, `cat`, `du`, `find`)
- `docker build -t aula04-job .` e `docker run --rm --env-file .env --network host aula04-job`

Peça autorização antes de: instalar pacotes fora do `requirements.txt`, apagar objetos em qualquer bucket, rodar `docker compose down -v`, qualquer comando `railway`.

## Segredos

- Credenciais vêm de variáveis de ambiente (`S3_ENDPOINT_URL`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`). Nunca escreva valores reais em código, SQL, testes, documentação ou mensagens de commit.
- O secret do DuckDB é criado em tempo de execução como `TEMPORARY`, a partir das variáveis. Não use secret persistente em disco.
- `.env` e `.env.railway` estão no `.gitignore`. Se uma chave aparecer no diff, pare e avise.

## Gates

1. `python -m pytest -q` sem falhas.
2. Rodar o job duas vezes para a mesma data não muda a contagem de objetos nem a contagem de linhas da silver.
3. Toda linha da silver tem `arquivo_origem` preenchido e apontando para um objeto que existe em `raw` ou `bronze`.
4. O processo termina sozinho; o tempo de execução aparece no resumo final.
5. Nenhum segredo em `git diff --staged`.
