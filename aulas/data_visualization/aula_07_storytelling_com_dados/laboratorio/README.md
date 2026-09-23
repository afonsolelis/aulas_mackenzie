# Laboratório da Aula 07: do protótipo ao painel com Supabase

Kit usado na demonstração do professor e no início da implementação pelos grupos.
Leva o recorte pseudonimizado das 15 turmas para um Postgres no Supabase e liga o
protótipo HTML da Aula 06 a views agregadas, com login.

```
laboratorio/
├── sql/
│   ├── 01_tabelas.sql   # oito tabelas, índices e RLS de leitura para authenticated
│   ├── 02_carga.sql     # \copy dos CSVs e reconciliação com o manifesto
│   └── 03_views.sql     # ritmo, participação e revisão, com security_invoker
└── public/
    └── painel_exemplo.html   # login, consulta às views e gráfico de ritmo
```

## Dados

`projeto_pbl_completo.zip` circula só no canal da turma. O repositório do curso é
público, e o recorte completo não entra nele. Para regenerar a partir da base original:

```bash
python3 tools/export_projeto_csv.py --completo --out dados/projeto_pbl_completo
cd dados && zip -r projeto_pbl_completo.zip projeto_pbl_completo
```

| Arquivo | Linhas |
|---|---:|
| grupos.csv | 75 |
| pessoas.csv | 1.859 |
| sprints.csv | 376 |
| quadro_colunas.csv | 429 |
| commits.csv | 53.230 |
| merge_requests.csv | 9.208 |
| cartoes.csv | 17.027 |
| kanban_eventos.csv | 183.422 |

## Roteiro

1. Em supabase.com, crie um projeto. Anote a senha do banco.
2. Em **Connect**, copie a string do **Session pooler** (porta 5432). A conexão direta
   usa só IPv6 e não funciona no Codespaces.
3. No Codespace:

   ```bash
   sudo apt-get update && sudo apt-get install -y postgresql-client unzip
   export SUPABASE_DB_URL='postgresql://postgres.xxxx:SENHA@aws-0-sa-east-1.pooler.supabase.com:5432/postgres'
   unzip projeto_pbl_completo.zip
   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f sql/01_tabelas.sql
   cd projeto_pbl_completo && psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f ../sql/02_carga.sql && cd ..
   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f sql/03_views.sql
   ```

   A consulta final do `02_carga.sql` mostra as linhas carregadas ao lado do manifesto.
   As duas colunas precisam ser iguais.
4. Em **Authentication > Users > Add user**, crie um usuário com **Auto Confirm User**.
5. Em **Project Settings > API Keys**, copie a URL e a chave publicável para o topo do
   `<script>` de `public/painel_exemplo.html`.
6. Sirva a página e entre com o usuário criado:

   ```bash
   cd public && python3 -m http.server 8000
   ```

## Controle de acesso

A chave publicável fica no código da página e qualquer pessoa pode lê-la. Por isso ela
sozinha não pode abrir o dado:

- as oito tabelas têm RLS ligado, com política de leitura só para `authenticated`;
- as views usam `security_invoker = true` e herdam esse RLS. Sem essa opção, a view
  roda com os privilégios de quem a criou e devolve tudo para a chave publicável;
- `anon` perde o acesso às views com `revoke`.

Sem login, a API responde `401 permission denied`. A chave secreta (`service_role`)
ignora o RLS e nunca entra em arquivo servido ao navegador.

## Decisões do recorte que entram no dossiê

- **Histórico herdado.** 2.475 commits (4,6%) são anteriores à criação do repositório
  do grupo, com datas de 2022 a 2025, vindos do repositório-modelo. `v_commits_do_modulo`
  os exclui, e `v_participacao.commits_herdados_excluidos` mostra quantos foram excluídos.
  Sem esse corte, o autor do modelo conta como integrante ativo de todos os grupos.
- **Sprints sem data.** 371 das 376 sprints não têm início nem prazo. Não dá para
  atribuir commit a sprint por data; cartões e merge requests trazem a sprint pelo nome.
- **Autoria.** 88,5% dos commits resolvem para um integrante. O resto aparece como
  `[externo]` ou `[bot]`, porque o e-mail configurado no git não corresponde à conta.
- **Limite da API.** A API devolve no máximo 1.000 linhas por requisição. A agregação
  fica nas views, e o navegador recebe no máximo uma linha por grupo e semana.

## Verificação

O kit foi testado num Postgres 15 local com os papéis `anon` e `authenticated`, e num
PostgREST local, que é a camada REST do Supabase. A carga das oito tabelas terminou em
menos de 4 segundos, as contagens bateram com o manifesto, `anon` recebeu `401` nas
views e o painel de exemplo abriu com login, 75 grupos no seletor e os números iguais
aos do SQL.
