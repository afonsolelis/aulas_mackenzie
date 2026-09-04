# Pipeline de dados do projeto do módulo — Data Visualization

Extrai o rastro de trabalho dos grupos PBL da graduação no GitLab institucional e
publica o recorte no Postgres lido pelo Metabase da disciplina, no schema `pbl`.

## Ordem de execução

```bash
python3 tools/extract_gitlab_pbl.py --ciclo 2026-1b --out data/pbl_modulo2.sqlite
python3 tools/extract_kanban_events.py --db data/pbl_modulo2.sqlite
python3 tools/load_via_metabase.py --db data/pbl_modulo2.sqlite
```

| Script | O que faz |
|---|---|
| `extract_gitlab_pbl.py` | Canal de estado: projetos, membros, branches, sprints, quadros, commits (com estatísticas de linhas), merge requests e cartões. Parametrizado por ciclo. |
| `extract_kanban_events.py` | Movimento dos cartões pelas colunas do quadro (`resource_label_events`). Retomável: reexecutar só busca o que falta. |
| `load_via_metabase.py` | Recria o schema `pbl` no Postgres do Metabase e carrega tudo em lotes. |

O SQLite intermediário fica em `data/`, que está no `.gitignore` — os dados são
reais e identificados, e não devem ser versionados em hipótese alguma.

## Credenciais

O GitLab vem do `.env` do repositório `gitlab-admin` (`GITLAB_URL`, `GITLAB_PAT`);
nenhum token é gravado aqui. O Metabase usa a credencial compartilhada da turma,
já publicada na home da disciplina, e pode ser trocada por `--user` / `--password`.

## Por que a carga passa pelo Metabase

O Postgres que o Metabase lê fica na rede interna do Railway e não aceita conexão
externa, então `psql` não alcança. O endpoint `/api/dataset` executa SQL nativo
contra ele, e o usuário configurado tem privilégio para criar schemas. Um detalhe
do Metabase: comandos que não produzem `ResultSet` retornam HTTP 400 **mas são
executados**; `run()` trata esse erro específico como sucesso e propaga os demais.

Se um dia esse Postgres ganhar um proxy TCP público no Railway, a carga fica mais
rápida por `COPY` — foi o caminho original, preservado no histórico deste repo.

## Recorte

Repositórios de grupo em `graduacao/<ciclo>/<turma>/<grupo>`; ponderadas
individuais e repositórios de coordenação ficam de fora. Não inclui o diff de cada
commit (só o total de linhas) nem o texto dos comentários de revisão (só a
contagem). A tabela `pbl.extracao` registra a proveniência de cada execução.
