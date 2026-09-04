# Laboratório — do Excel ao OLAP com SQLite, DuckDB e IA

[Abrir no GitHub Codespaces](https://codespaces.new/afonsolelis/aulas_mackenzie?quickstart=1)

Esta prática usa o OpenCode Zen no terminal para construir um pipeline reproduzível. A IA propõe o código; o grupo inspeciona o diff, executa cada etapa e valida a evidência. Os quatro Excels, com as nove tabelas distribuídas em abas, permanecem imutáveis.

## Resultado esperado

```text
laboratorio/
├── docs/
│   └── 04_pipeline_excel_olap.md
├── entrada/                         # cópia local dos quatro .xlsx
├── src/
│   ├── 00_perfil_excel.py
│   ├── 01_excel_para_sqlite.py
│   ├── 02_html_sqlite.py
│   ├── 03_sqlite_para_duckdb.py
│   ├── 04_criar_mart_olap.py
│   └── 05_html_duckdb.py
└── saida/
    ├── perfil_excel.json
    ├── olist.sqlite
    ├── relatorio_sqlite.html
    ├── olist.duckdb
    ├── reconciliacao_duckdb.json
    └── dashboard_duckdb.html
```

## 1. Configurar OpenCode Zen

No terminal do Codespace:

```bash
npm install -g opencode-ai
opencode --version
cd aulas/data_visualization/aula_04_do_excel_ao_olap_com_sqlite_duckdb_e_ia/laboratorio
opencode
```

Dentro da interface do OpenCode:

1. Digite `/connect`.
2. Selecione **OpenCode Zen**.
3. Abra a autenticação indicada, adicione créditos e copie a API key.
4. Cole a chave somente no campo seguro.
5. Digite `/models` e escolha um modelo disponível.
6. Peça: `Leia ../../../../AGENTS.md e README.md. Resuma os gates sem editar arquivos.`
7. Mantenha o OpenCode aberto e use um segundo terminal para executar os comandos do laboratório.

Nunca registre a chave em prompt, `.env`, HTML, captura de tela ou commit. Consulte a [documentação oficial do OpenCode](https://opencode.ai/docs) e do [OpenCode Zen](https://opencode.ai/docs/zen).

## 2. Preparar os arquivos e o Python

```bash
cd aulas/data_visualization/aula_04_do_excel_ao_olap_com_sqlite_duckdb_e_ia/laboratorio
mkdir -p entrada src saida
cp ../dados/*.xlsx entrada/
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

O contrato de origem está em [`../dados/manifesto_olist.json`](../dados/manifesto_olist.json). O gate de entrada exige quatro arquivos, nove abas e as contagens abaixo.

| Tabela | Linhas |
|---|---:|
| `olist_customers` | 99.441 |
| `olist_geolocation` | 1.000.163 |
| `olist_order_items` | 112.650 |
| `olist_order_payments` | 103.886 |
| `olist_order_reviews` | 99.224 |
| `olist_orders` | 99.441 |
| `olist_products` | 32.951 |
| `olist_sellers` | 3.095 |
| `product_category_name_translation` | 71 |

## 3. Construir com o OpenCode

Execute um prompt por vez. Inspecione o diff antes de autorizar a execução.

### A. Perfil dos Excels

```text
Leia README.md. Inspecione os quatro arquivos em entrada/*.xlsx e suas
nove abas em modo read_only, sem carregar uma aba inteira em memória. Crie
src/00_perfil_excel.py para registrar arquivo, aba, cabeçalhos,
quantidade de linhas e amostra de tipos. Grave saida/perfil_excel.json.
Não altere a entrada. Mostre o plano antes de editar.
```

```bash
python src/00_perfil_excel.py
python -m json.tool saida/perfil_excel.json
```

Gate: quatro arquivos, nove abas e nove contagens iguais ao manifesto.

### B. Excel para SQLite

```text
Crie src/01_excel_para_sqlite.py. Use openpyxl em read_only,
sqlite3 da biblioteca padrão, esquema explícito para as nove tabelas,
localize cada tabela pela aba indicada no manifesto, use transação por aba e inserção em lotes de 5.000 linhas. Converta
datas para ISO 8601 e preserve nulos. Ative PRAGMA foreign_keys=ON,
declare as seis FKs abaixo e carregue pais antes de filhos. Crie índices
após a carga e grave saida/olist.sqlite. Reconcilie contagens, unicidade
e FKs; falhe em qualquer divergência. Não use pandas nem números fixos.
```

Relações obrigatórias: `orders.customer_id → customers.customer_id`; `order_items.order_id → orders.order_id`; `order_items.product_id → products.product_id`; `order_items.seller_id → sellers.seller_id`; `order_payments.order_id → orders.order_id`; `order_reviews.order_id → orders.order_id`. Geolocalização não recebe FK por prefixo de CEP, que não é único.

```bash
python src/01_excel_para_sqlite.py
sqlite3 saida/olist.sqlite ".tables"
sqlite3 saida/olist.sqlite "PRAGMA integrity_check;"
sqlite3 saida/olist.sqlite "PRAGMA foreign_key_check;"
```

Gate: nove tabelas, contagens reconciliadas, `integrity_check = ok` e nenhuma linha em `foreign_key_check`.

### C. HTML lido do SQLite

```text
Crie src/02_html_sqlite.py. Abra saida/olist.sqlite em modo somente
leitura e gere saida/relatorio_sqlite.html com HTML semântico e CSS
embutido. Mostre contagem das nove tabelas, pedidos por status, cinco
pedidos recentes e duração de cada consulta. Escape texto, registre a
fonte e a data de geração. Nenhuma métrica pode ser digitada no HTML.
```

```bash
python src/02_html_sqlite.py
python -m http.server 8000 -d saida
```

Gate: o HTML declara `olist.sqlite` e uma contagem confere com o terminal.

### D. SQLite para DuckDB

```text
Crie src/03_sqlite_para_duckdb.py. Conecte a saida/olist.duckdb,
instale e carregue a extensão sqlite, anexe saida/olist.sqlite como
sqlite_src e materialize as nove tabelas no catálogo main com
CREATE OR REPLACE TABLE ... AS SELECT. Execute ANALYZE, reconcilie as
contagens entre os dois bancos e grave saida/reconciliacao_duckdb.json.
Falhe se qualquer tabela divergir.
```

Gate: o DuckDB possui nove tabelas nativas e nenhuma contagem diverge.

### E. Mart OLAP

```text
Crie src/04_criar_mart_olap.py. No DuckDB, materialize
fato_item_venda no grão order_id + order_item_id, juntando pedidos,
clientes, itens, produtos e tradução; derive mes da data de compra.
Depois crie mart_vendas_mensais
no grão mês + estado_cliente + categoria somente com medidas aditivas:
receita_produtos, frete e itens. Pedidos e ticket devem ser calculados
da fato_item_venda, com count(distinct order_id) no grão da consulta.
Nunca some contagens distintas entre categorias. Não junte pagamentos
ou avaliações sem pré-agregar. Inclua testes de unicidade e fanout.
```

Gate: `order_id + order_item_id` continua único, o total de `price` reconcilia antes e depois dos joins e o mart não armazena pedidos distintos nem ticket.

### F. HTML lido do DuckDB

```text
Crie src/05_html_duckdb.py. Leia somente saida/olist.duckdb e gere
saida/dashboard_duckdb.html. Mostre KPIs de receita, pedidos e ticket;
série mensal; top 10 categorias com cobertura; estados com receita e
pedidos; duração e SQL resumido de cada consulta. Calcule pedidos e
ticket da fato_item_venda com count(distinct order_id) no grão de cada
consulta; nunca some contagens distintas do mart categórico. Use HTML
semântico, CSS embutido e tabela equivalente. Não use números fixos
nem leia o SQLite neste script.
```

Gate: o HTML declara `olist.duckdb`, as métricas reconciliam e o top 10 informa cobertura.

## 4. Direcionamento de leitura

Leia primeiro o SQLite para compreender catálogo, tipos, índices, integridade, status dos pedidos e linhas recentes. Depois leia o DuckDB para agregar mês, estado e categoria, aplicar janelas, calcular cobertura e inspecionar o plano com `EXPLAIN ANALYZE`.

Compare uma mesma consulta em ambos os bancos com cinco execuções e mediana. Registre máquina, consulta, execução fria e aquecida. O resultado descreve este caso; não prova superioridade universal.

## 5. Revisão final com IA

```text
Revise os seis scripts contra README.md. Liste divergências
sem editar. Verifique entrada imutável, ausência de números fixos,
contagens, integridade, tipos, fanout, fonte dos HTMLs e limitações.
Depois proponha a menor correção para cada gate que falhou.
```

Depois que todos os gates passarem:

```text
Crie docs/04_pipeline_excel_olap.md somente a partir dos manifestos,
relatórios e medições produzidos. Registre proveniência, contagens, FKs,
reconciliação, consulta comparada, mediana, limitações e caminhos dos
dois HTMLs. Não invente números.
```

O laboratório termina quando a pasta `saida/` pode ser reconstruída integralmente a partir dos quatro Excels e o registro em `docs/` aponta para as evidências realmente produzidas.

## Diagnóstico

- `opencode: command not found`: feche e abra o terminal depois de `npm install -g opencode-ai` e execute `npm prefix -g` para confirmar o prefixo global.
- Zen sem modelos: confirme a conexão em `/connect`, os créditos da conta e depois execute `/models` novamente.
- `No module named openpyxl` ou `duckdb`: execute `source .venv/bin/activate` e reinstale `requirements.txt`.
- `sqlite3: command not found`: execute **Codespaces: Rebuild Container**; o dev container instala o cliente SQLite na criação.
- Falha ao instalar a extensão `sqlite` no DuckDB: confirme a conexão de rede do Codespace e repita a etapa. A extensão é obtida do repositório oficial na primeira execução.
- Porta 8000 não abriu: painel **Ports** → porta `8000` → **Open in Browser**.
