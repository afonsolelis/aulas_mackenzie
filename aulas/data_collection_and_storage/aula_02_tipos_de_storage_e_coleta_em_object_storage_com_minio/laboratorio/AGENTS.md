# AGENTS.md (modelo para aula_02_coleta_json/)

Copie este arquivo para a raiz de `aula_02_coleta_json/` no repositório do grupo e ajuste o que estiver entre `<>`.

## Escopo

- Projeto: coletor horário de previsão do tempo da Open-Meteo para capitais brasileiras, gravando o JSON bruto no bucket `raw` de um MinIO.
- Trabalhe somente dentro de `aula_02_coleta_json/`. Não edite arquivos de outras aulas.
- Fontes de verdade, nesta ordem: `docs/00_persona.md`, `docs/01_objetivos_negocio.md`, `specs/spec.md`, `specs/plan.md`, `specs/tasks.md`.
- Preserve os identificadores `RF-xx`, `RNF-xx` e `T-xx`. Não renumere.

## Regras de trabalho

- Mostre o plano de alteração antes de editar arquivos.
- Execute uma etapa por vez e pare ao final dela, aguardando revisão humana.
- Não invente números, SLAs ou limites. Quando faltar um valor, escreva "hipótese, validação pendente".
- Separe fato, lacuna e suposição em toda análise.
- Toda tarefa de código vem acompanhada de teste em `tests/` e só termina com `pytest` passando.

## Comandos permitidos

- `python -m pytest -q`
- `python -m src.coletor` (ou o ponto de entrada definido em `specs/plan.md`)
- `docker compose up -d`, `docker compose ps`, `docker compose logs minio`
- `docker compose exec minio mc ...` apenas para leitura (`ls`, `stat`, `cat`, `du`, `find`)

Peça autorização antes de: instalar pacotes fora do `requirements.txt`, apagar objetos no bucket, rodar `docker compose down -v`, qualquer comando `railway`.

## Segredos

- Credenciais vêm de variáveis de ambiente (`S3_ACCESS_KEY`, `S3_SECRET_KEY`). Nunca escreva valores reais em código, testes, documentação ou mensagens de commit.
- `.env` e `.env.railway` estão no `.gitignore`. Se uma chave aparecer no diff, pare e avise.

## Gates

1. `python -m pytest -q` sem falhas.
2. Duas execuções seguidas na mesma hora não aumentam o número de objetos de dados no bucket.
3. Todo objeto gravado tem os metadados de coleta definidos na spec (fonte, horário de coleta, versão do coletor, hash).
4. Nenhum segredo em `git diff --staged`.
