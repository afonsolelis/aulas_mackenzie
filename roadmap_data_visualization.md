# Roadmap — Data Visualization

**MBA Engenharia de Dados — Mackenzie — 2026**
Documento vivo de planejamento das 8 aulas da disciplina. Sábados, 8h30 – 12h10, de 15/08/2026 a 03/10/2026. Carga total: 32 h/a.

---

## 1. Premissa da disciplina

A ementa institucional contempla percepção humana, representações para dados numéricos e não numéricos, tabelas, gráficos, mapas, indicadores de performance, dashboards e storytelling. A disciplina organiza esses conteúdos como um processo analítico completo, no qual a representação visual depende de dados compreendidos, arquitetura identificável e semântica consistente.

A disciplina tem dois tempos. Nas Aulas 01 a 04 o conjunto Olist funciona como bancada: a Aula 01 estabelece o perfil dos dados e formula perguntas de negócio; a Aula 02 localiza aquisição, persistência, camada semântica e consumo nas principais arquiteturas de BI e converte o esquema operacional em fatos e dimensões; a Aula 03 trata a codificação de quantidades; a Aula 04 constrói uma cadeia analítica local completa, do Excel ao OLAP.

A partir da Aula 05 o objeto muda. O trabalho passa a incidir sobre o projeto do módulo — o dashboard do processo PBL, com um cliente concreto — e o eixo deixa de ser a construção do gráfico para ser a distância entre o que o usuário acredita que o número significa e o que o dado de fato registra. As Aulas 05, 06 e 07 tratam, nessa ordem, da divergência entre modelo mental e ciclo de vida do dado, das heurísticas de avaliação e dos vieses de julgamento, e da narrativa que leva a audiência da pergunta à recomendação. A Aula 08 é ateliê de finalização e entrega.

---

## 2. Arco pedagógico

Oito aulas, uma progressão única:

```
01  Descobrir os dados            Data Discovery, perfilamento, perguntas de negócio
02  Arquitetar e modelar          plataformas de BI, fatos, dimensões, SCD, barramento
03  Comparar números              percepção, distribuições, séries temporais, magnitude
04  Construir a cadeia local      Excel, SQLite, HTML, DuckDB, OLAP e IA
05  Confrontar modelos mentais    fluxo de interação anotado, divergência, decisão e suporte
06  Auditar o julgamento          heurísticas de avaliação, vieses cognitivos, severidade
07  Contar a história             exploração vs. explicação, dashboard narrativo, defesa
08  Fechar e entregar             ateliê, rastreabilidade contra requisitos, entrega
```

Cada aula produz artefatos verificáveis e um registro escrito no repositório do aluno. Nas aulas regulares, o artefato principal fica no **Metabase**; a Aula 03 produz uma visualização D3 e a Aula 04 produz scripts, dois bancos, dois HTMLs e reconciliações no Codespaces. Das Aulas 05 a 08 o artefato deixa de ser um exercício sobre o Olist e passa a ser uma peça do projeto do módulo: o fluxo anotado, a auditoria cruzada, a narrativa e a entrega final incidem sobre o mesmo painel, que cresce de aula em aula.

### Método transversal C-D-P-V-D

As oito aulas executam o mesmo método profissional. O tema semanal muda; o processo de decisão permanece:

```text
CONTEXTO ──► DADOS ──► PERGUNTA ──► VISUAL ──► DECISÃO
   │            │           │            │           │
 público     qualidade    métrica      codificação   ação
 tarefa      grão         recorte      interação     evidência
 ambiente    limitações   hipótese     acessibilidade validação
```

Cada passagem é um **gate**. O aluno só avança quando consegue demonstrar a saída anterior:

| Gate | Pergunta de controle | Evidência mínima |
|---|---|---|
| G1 · Contexto | Quem usa e qual decisão precisa tomar? | Brief com público, tarefa e consequência |
| G2 · Dados | Os dados sustentam a pergunta? | Perfil de qualidade, grão e limitações |
| G3 · Pergunta | A pergunta é mensurável e tem recorte? | Métrica, dimensão, período, filtro e decisão |
| G4 · Visual | A codificação é perceptiva e semanticamente adequada? | Registro de alternativas e justificativa |
| G5 · Decisão | A audiência interpreta e sabe como agir? | Teste, achados, correções e recomendação |

O método é inspirado por quatro famílias de referência, sem alegar certificação ou conformidade formal:

- `ISO/IEC 25012:2008` — modelo de qualidade de dados, aplicado no Gate 2;
- `ISO/TS 8000-82:2022` — criação de regras de dados a partir do perfilamento;
- `ISO 9241-112:2025` — princípios para apresentação da informação, aplicados no Gate 4;
- `ISO 9241-110:2020` e `ISO 9241-210:2019` — interação e design centrado nas pessoas, aplicados nos Gates 1 e 5;
- `WCAG 2.2 / ISO/IEC 40500:2025` — acessibilidade verificável em todas as saídas visuais.

### Dossiê progressivo do aluno

O produto da disciplina é um dossiê auditável que registra como cada decisão foi tomada e inclui o dashboard como uma de suas entregas:

| Aula | Documento | Evidência profissional |
|---|---|---|
| 01 | `01_brief_e_qualidade.md` | brief, perfil ISO-aligned, regras e limitações |
| 02 | `02_arquitetura_e_modelo.md` | fluxos de consumo, grãos, matriz de barramento e testes SQL |
| 03 | `03_registro_numerico.md` | escala, agregação, incerteza e alternativas |
| 04 | `04_pipeline_excel_olap.md` | proveniência, reconciliação, tempos e limitações dos dois bancos |
| 05 | `05_fluxo_de_interacao_anotado.md` | fluxo por raias, divergências, decisão de projeto e suporte exigido |
| 06 | `06_auditoria_heuristica_e_vieses.md` | achados com severidade, viés nomeado, correção e reteste |
| 07 | `07_narrativa_e_defesa.md` | ideia central, storyboard, fichas de KPI e roteiro da defesa |
| 08 | `08_dossie_final.md` | consolidação, rastreabilidade contra os requisitos e limitações |

### Auditoria heurística transversal

Toda entrega é revisada por dez heurísticas, com severidade `0` (não é problema), `1` (cosmético), `2` (menor), `3` (grave) ou `4` (impede a decisão):

1. adequação à tarefa;
2. clareza da mensagem;
3. integridade e rastreabilidade dos dados;
4. adequação da codificação visual;
5. hierarquia e carga cognitiva;
6. consistência e expectativas do usuário;
7. contexto, unidades e incerteza;
8. prevenção de interpretação errada;
9. acessibilidade e equivalência da informação;
10. acionabilidade.

Uma crítica válida registra `evidência → heurística → severidade → consequência → correção → reteste`. Opiniões estéticas sem evidência não encerram o gate.

### Relação com a ementa

| Tópico da ementa | Onde é coberto |
|---|---|
| Percepção humana | Aula 03, na codificação de quantidade; Aula 06, nos limites do julgamento de quem lê |
| Dados numéricos | Aula 03 |
| Dados não numéricos | Aula 06, como objeto de auditoria: cardinalidade, corte da cauda longa sem prestação de contas e ordinal tratado como número contínuo |
| Tabelas e gráficos | Aulas 03 e 06 |
| Integração de fontes e publicação | Aula 04, do Excel aos HTMLs via SQLite e DuckDB |
| Mapas | Aula 06, como caso canônico de viés: o coroplético de volume sem normalização |
| Indicadores de performance | Aula 05, quando a ficha técnica do KPI é o suporte exigido por uma divergência de definição; Aula 07, na composição do painel |
| Dashboards | Aula 07, na construção do painel narrativo; Aula 08, na entrega |
| Storytelling com dados | Aula 07 |

Data Discovery (Aula 01) e arquitetura/modelagem de BI (Aula 02) funcionam como pré-requisitos práticos para os tópicos de representação e asseguram que os gráficos posteriores utilizem métricas rastreáveis.

**Revisão de 05/09/2026.** Dados não numéricos, mapas e indicadores de performance deixaram de ter aula dedicada e passaram a ser tratados dentro das Aulas 05, 06 e 07, sempre aplicados ao projeto do módulo. A troca é deliberada e tem uma razão: com quatro aulas restantes e um cliente real esperando um painel, uma aula gasta em escolher entre treemap e barras aninhadas rende menos que uma aula gasta em descobrir que o orientador e o grupo chamam de "entrega" duas coisas diferentes. Os três tópicos continuam sendo praticados — como material de auditoria e como exigência de suporte —, mas dentro de um trabalho que precisa ser defendido diante de quem vai usá-lo.

---

## 3. Stack técnica

### Ferramenta de visualização — Metabase

**Instância única hospedada pelo professor.** Decisão tomada em detrimento de instalação individual (atrito alto na primeira aula, 3h40 é pouco para depurar Docker em 30 máquinas diferentes) e de Metabase Cloud (trial de 14 dias não cobre as 8 semanas).

Justificativa da escolha do Metabase sobre Power BI / Tableau:

- **Open source e gratuito** — o aluno pode reinstalar depois do curso sem licença.
- **Query builder visual + SQL nativo no mesmo produto** — permite subir a régua de complexidade ao longo do semestre sem trocar de ferramenta.
- **X-ray automático** — gera exploração instantânea de qualquer tabela, ideal para a Aula 01 de discovery.
- **Modelo de permissões por coleção** — cada aluno trabalha isolado na mesma instância.

### Topologia da instância

```
VM do professor (Docker Compose)
   │
   ├── metabase            :3000   → aplicação, acesso HTTPS pelos alunos
   ├── metabase-appdb      :5432   → Postgres interno do Metabase (nunca H2 em uso real)
   └── olist-db            :5433   → Postgres com o dataset Olist, acesso read-only
```

**Organização do trabalho:** a turma acessa com uma conta compartilhada e cada aluno cria uma coleção nomeada com o próprio nome, onde salva todo o trabalho. O usuário do banco é read-only, então nenhuma ação de aluno altera o dado de origem.

A conta compartilhada troca isolamento por atrito zero na primeira aula. A contrapartida é convivência: as coleções são visíveis e editáveis por todos, o que exige a regra explícita de duplicar em vez de editar o trabalho alheio — combinada em sala na Aula 01 e repetida no slide de acesso.

**Riscos aceitos e mitigações:**

| Risco | Mitigação |
|---|---|
| Instância é ponto único de falha da aula | Export de serialização semanal; dump do Postgres versionado |
| Query pesada de um aluno degrada a sessão | Timeout de query configurado; índices nas colunas de junção |
| Aluno perde trabalho ao final do curso | Exportação das perguntas e dashboards em `.json` na Aula 08 |
| Aluno edita ou apaga o trabalho de outro | Regra de convivência combinada na Aula 01; serialização semanal permite restaurar |
| Aluno quer continuar depois do curso | `docker-compose.yml` da instância entregue no repositório da disciplina |

### Dataset — Olist Brazilian E-commerce

Fio condutor único das 8 aulas. Escolhido por cobrir, num só conjunto, todos os tipos de representação exigidos pela ementa:

| Necessidade da ementa | O que o Olist oferece |
|---|---|
| Séries temporais | `order_purchase_timestamp` ao longo de 2016–2018 |
| Magnitude e distribuição | `price`, `freight_value`, `payment_value` |
| Categorias | 71 categorias de produto, 5 métodos de pagamento |
| Hierarquia | categoria → produto → item de pedido |
| Texto livre | `review_comment_message` em ~40 mil avaliações |
| Geoespacial | estado, cidade, CEP e lat/long em `olist_geolocation` |
| Indicadores de performance | prazo prometido vs. entrega real, score de review |

Tabelas principais: `olist_orders`, `olist_order_items`, `olist_products`, `olist_customers`, `olist_sellers`, `olist_order_payments`, `olist_order_reviews`, `olist_geolocation`, `product_category_name_translation`.

### Segundo conjunto — rastro de trabalho PBL (projeto do módulo)

O Olist é o fio condutor das aulas. O **projeto do módulo** usa um conjunto próprio: o
rastro real de três grupos de graduação (turma T28, grupos G01–G03) num módulo de cinco
sprints — commits, merge requests, cartões e movimentação de quadro Kanban.

O cliente do projeto é o **professor orientador** desses grupos, e o trabalho abre por
**elicitação de requisitos**: o professor da disciplina interpreta o papel do orientador
e cada equipe conduz sua entrevista. A lista de requisitos priorizada é o primeiro
artefato e o contrato contra o qual o dashboard final é avaliado.

Duas vias de acesso, com regimes de privacidade distintos:

| Via | Conteúdo | Regime |
|---|---|---|
| CSVs em `dados/projeto_pbl/` | T28, grupos G01–G03 — 2.688 commits, 540 MRs, 1.238 cartões, 13.194 eventos de quadro | **Pseudonimizado**: pessoas viram `G01-A01`, instituição vira *Instituto Ápice*. Versionado e baixável na página do projeto |
| Schema `pbl` no Metabase | 75 grupos de 15 turmas do ciclo 2026-1b | **Identificado**. Restrito ao ambiente da disciplina |

A partir da Aula 05 esse conjunto deixa de ser apenas o material do projeto e passa a ser o
objeto das aulas: o fluxo anotado, a auditoria cruzada e a narrativa incidem sobre ele.

O SQLite intermediário (`data/pbl_modulo2.sqlite`) contém os dados identificados e nunca
é versionado. `tools/export_projeto_csv.py` é a fronteira entre ele e o material
publicável — ver `tools/README.md` para as armadilhas da pseudonimização.

### Repositório do aluno

O trabalho escrito acompanha o trabalho visual. Estrutura-alvo ao final da Aula 08:

```
olist-dataviz/
├── docs/
│   ├── 01_brief_e_qualidade.md       # Aula 01 — contexto, perfil e regras de dados
│   ├── 02_arquitetura_e_modelo.md    # Aula 02 — arquitetura, grãos, barramento e testes
│   ├── 03_registro_numerico.md       # Aula 03 — decisões numéricas e alternativas
│   ├── 04_pipeline_excel_olap.md      # Aula 04 — reconciliação, tempos e limitações
│   ├── 05_fluxo_de_interacao_anotado.md   # Aula 05 — divergências, decisão e suporte
│   ├── 06_auditoria_heuristica_e_vieses.md # Aula 06 — achados, severidade e reteste
│   ├── 07_narrativa_e_defesa.md           # Aula 07 — ideia central, storyboard e KPI
│   └── 08_dossie_final.md                 # Aula 08 — consolidação e rastreabilidade
├── sql/                       # consultas nativas relevantes, versionadas
└── export/
    ├── perguntas.json         # serialização das perguntas do Metabase
    └── dashboard.json         # serialização do dashboard final
```

---

## 4. Mapa detalhado das aulas

As aulas combinam fundamentação, demonstração e prática. Duas são exceções deliberadas: a Aula 04, 100% prática, com os conceitos introduzidos durante a execução guiada; e a Aula 08, ateliê de finalização e entrega, sem bloco teórico. O Metabase sustenta as aulas regulares; as Aulas 03 e 04 usam GitHub Codespaces e assistência de IA para produzir artefatos versionáveis. A partir da Aula 05 o conjunto de trabalho é o rastro PBL do projeto do módulo, e o Olist permanece disponível como fonte de contraexemplos na auditoria.

### Aula 01 — 15/08/2026 — Data Discovery com Metabase
**Conceitual:** o que é data discovery e por que antecede a visualização; perfilamento de dados (completude, cardinalidade, distribuição, outliers); tipos semânticos vs. tipos físicos; da pergunta vaga à pergunta respondível; grão da análise.
**Prática:** primeiro acesso à instância; navegação pelo schema Olist; X-ray automático de tabelas; query builder (filtro, sumarização, agrupamento, junção); perfilamento das 9 tabelas; formulação de 10 perguntas de negócio.
**Artefato:** coleção nomeada com 5 perguntas salvas + `docs/01_brief_e_qualidade.md` com contexto, perfil, regras, limitações e backlog.
**Saída verificável:** o aluno consegue afirmar, com evidência na tela, quantos pedidos existem, qual o período coberto, onde há nulos e quais três perguntas de negócio valem ser investigadas no semestre.

### Aula 02 — 22/08/2026 — Arquitetura de BI e Modelagem Dimensional com Olist
**Conceitual:** camadas de uma solução de BI; aquisição, persistência, estado da aplicação e consumo em Power BI Desktop, Power BI Service, Power BI Report Server, Grafana e Metabase; Data Warehouse, data mart, data lake, lakehouse e data mesh; processo, grão, fato, dimensão, chave substituta, esquema estrela, snowflake, SCD Tipo 1 e Tipo 2, matriz de barramento e dimensões conformadas.
**Prática:** extração do schema Olist pelo `information_schema`; discussão de perguntas e contratos dimensionais; construção de `dim_data`, `dim_cliente_scd2`, `dim_produto`, `dim_vendedor`, `fato_item` e `fato_pagamento` como consultas reutilizáveis; demonstração de fanout; grade com `CROSS JOIN`; drill-across por mês e UF; extensão do modelo com metadados fornecidos a uma IA e validação humana.
**Artefato:** consultas dimensionais salvas na coleção + `docs/02_arquitetura_e_modelo.md` com diagramas de fluxo, declarações de grão, matriz de barramento, SQL e resultados dos testes.
**Saída verificável:** o grupo localiza onde dados e artefatos residem em cada plataforma, preserva 112.650 itens no fato, associa fatos às versões SCD2 corretas e reconcilia as medidas com as tabelas de origem.

### Aula 03 — 29/08/2026 — Visualização de Dados Numéricos
**Conceitual:** os quatro trabalhos do gráfico numérico — comparar magnitude, mostrar distribuição, revelar evolução, expor relação; escolha do gráfico por trabalho; quando o eixo pode e não pode ser truncado; média vs. mediana em cauda longa; agregação e o paradoxo de Simpson.
**Prática:** série temporal de pedidos com granularidade variável; histograma de ticket; comparação de magnitude entre categorias; dispersão preço × frete; tratamento de outliers.
**Artefato:** 4 perguntas numéricas salvas, uma por tipo de trabalho + `docs/03_registro_numerico.md`.
**Saída verificável:** cada gráfico declara qual dos quatro trabalhos executa e por que o tipo escolhido é superior às alternativas descartadas.

### Aula 04 — 05/09/2026 — Do Excel ao OLAP com SQLite, DuckDB e IA
**Conceitos em execução:** diferença entre planilha, banco e relatório; SQLite como banco embutido orientado a linhas; DuckDB como mecanismo colunar vetorizado para OLAP; grão, fanout, reconciliação e limites de comparação de desempenho.
**Prática integral:** configuração do OpenCode Zen no terminal do Codespaces; download e perfil de quatro arquivos Excel com as nove tabelas Olist; carga em SQLite; geração de HTML operacional; materialização em DuckDB; construção de fato e mart; geração de HTML analítico.
**Artefato:** seis scripts, `olist.sqlite`, `olist.duckdb`, dois relatórios HTML, registros de reconciliação e `docs/04_pipeline_excel_olap.md`.
**Saída verificável:** o grupo reconstrói os dois HTMLs a partir dos Excels, demonstra a fonte de cada número e compara a mesma consulta nos dois mecanismos sem exceder a evidência medida.

### Aula 05 — 12/09/2026 — Modelo Mental do Usuário e Ciclo de Vida do Dado
**Conceitual:** modelo do usuário, modelo do projetista e imagem do sistema; golfo de execução e golfo de avaliação; o ciclo de vida do dado em oito estações, do evento no mundo até a decisão tomada; seis famílias de divergência — vocabulário, grão, temporalidade, completude, causalidade e agência; notação do fluxo de interação anotado por raias; a diferença entre decisão de projeto e preferência estética; suporte exigido como entregável verificável, incluindo a ficha técnica do KPI quando a divergência é de definição.
**Prática:** reconstituição do ciclo de vida do dado do próprio grupo, estação por estação, com a perda declarada em cada uma; teste de vocabulário com o cliente — o professor interpreta o orientador e define seis termos que o grupo compara com a definição operacional do dado; desenho do fluxo de interação anotado sobre uma tarefa real de decisão; registro das divergências `D1..Dn` com decisão e suporte; teste de interpretação em voz alta com um grupo que não construiu o fluxo.
**Artefato:** fluxo de interação anotado com as raias usuário, interface e dado + `docs/05_fluxo_de_interacao_anotado.md` com o registro de divergências, decisão fundamentada, suporte exigido, custo e forma de reteste + os suportes já implementados nas perguntas do Metabase.
**Saída verificável:** para cada divergência registrada, o grupo mostra a evidência no dado, nomeia o tipo, declara a consequência de decidir errado, aponta a decisão de projeto tomada e demonstra na tela o suporte que a sustenta.

### Aula 06 — 19/09/2026 — Heurísticas e Vieses
**Conceitual:** as duas famílias que dividem o nome "heurística" — a heurística de avaliação como instrumento deliberado de inspeção e a heurística cognitiva como atalho automático de julgamento; disponibilidade, representatividade, ancoragem e afeto; negligência da taxa-base, denominador ausente, regressão à média, viés de sobrevivência, padrão em ruído, enquadramento, recência e erro fundamental de atribuição; os vieses que o artefato produz — eixo truncado, coroplético sem normalização, corte de cauda longa sem prestação de contas, ordinal tratado como número contínuo, ranking de pessoas, cor semântica e precisão espúria; o viés do próprio autor na curadoria; as dez heurísticas da disciplina e a escala de severidade de `0` a `4`.
**Prática:** bateria caça-viés sobre quatro artefatos preparados — um mapa de volume sem normalização, um "top 10 + outros" mudo, um ranking de commits por pessoa e uma série com eixo truncado; auditoria cruzada entre grupos, cada um inspecionando o painel de outro com as dez heurísticas; devolutiva com severidade e consequência; correção e reteste pelo grupo dono do painel; redação das contramedidas permanentes.
**Artefato:** `docs/06_auditoria_heuristica_e_vieses.md` com os achados recebidos, o viés nomeado em cada um, a severidade, a correção aplicada e o resultado do reteste + a lista de contramedidas incorporadas ao painel.
**Saída verificável:** o grupo apresenta pelo menos um achado de severidade `3` ou `4` que recebeu, mostra o painel antes e depois da correção e explica qual viés a versão anterior induzia em quem lia.

### Aula 07 — 26/09/2026 — Storytelling com Dados
**Conceitual:** exploração e explicação como atividades distintas; a ideia central em uma frase e o que a torna falsificável; contexto, conflito e resolução aplicados a evidência; sequenciamento e a ordem que a audiência consegue seguir; anotação como camada de significado e o título que afirma em vez de rotular; atenção pré-atentiva e a economia da remoção; adequação ao público — o orientador, a coordenação e o próprio grupo observado; narrativa honesta e o lugar da limitação dentro da história; ética de narrar sobre pessoas que aprendem; ficha técnica do KPI e o painel narrativo em abas como suporte da história; recomendação, próximo passo e a defesa oral sob pergunta hostil.
**Prática:** redação da ideia central em uma frase e crítica cruzada dessa frase; storyboard de sete quadros com a mensagem de cada um escrita antes do gráfico; montagem do dashboard narrativo em três abas — situação, evidência e decisão — com filtros e a aba explícita do que o painel não pode afirmar; ensaio cronometrado de doze minutos diante de outro grupo; rodada de perguntas hostis e ajuste do roteiro.
**Artefato:** dashboard narrativo em abas + `docs/07_narrativa_e_defesa.md` com ideia central, storyboard, fichas de KPI, roteiro da defesa e as perguntas difíceis previstas com suas respostas.
**Saída verificável:** o grupo conduz a audiência da pergunta do cliente à recomendação em doze minutos, sem apresentar um único gráfico que não sustente a ideia central e sem omitir a limitação que a evidência impõe.

### Aula 08 — 03/10/2026 — Entrega do Projeto Final
**Sem bloco teórico.** Ateliê de finalização e entrega. O professor circula em dois papéis: cliente, para a validação final contra a lista de requisitos elicitada, e banca, na rodada de entregas.
**Prática:** abertura com os critérios de aceite e o checklist de entrega; ateliê com atendimento por grupo; verificação de rastreabilidade requisito a requisito, incluindo o registro das lacunas que os dados não sustentam; fechamento do dossiê das oito aulas; congelamento do painel e exportação da coleção em `.json`; entrega e defesa.
**Artefato:** dashboard narrativo publicado, coleção exportada, `docs/08_dossie_final.md` consolidando as sete aulas anteriores e a defesa apresentada.
**Saída verificável:** cada requisito da lista elicitada tem, no painel ou no dossiê, o item que o atende ou a razão declarada de não ser atendido; nada fica sem resposta.

---

## 5. Loop que se repete em cada aula

1. **Contextualizar** — público, tarefa, decisão e consequência do erro.
2. **Inspecionar** — qualidade, grão, origem, recorte e limitações dos dados.
3. **Especificar** — pergunta mensurável e critérios de sucesso antes do gráfico.
4. **Comparar** — pelo menos duas representações candidatas e seus trade-offs.
5. **Construir** — implementar a resposta no Metabase com título, unidades e fonte.
6. **Auditar** — aplicar heurísticas, acessibilidade e severidade em revisão por pares.
7. **Testar** — observar interpretação e tarefa sem explicar previamente o artefato.
8. **Registrar** — documentar decisão, evidência, limitações e mudança realizada.
9. **Curar** — manter apenas o que contribui para a decisão final.

A tese da disciplina: **a qualidade da pergunta determina a qualidade da visualização**. Um gráfico bonito que responde a pergunta errada não tem valor.

---

## 6. Avaliação

| Componente | Peso | Quando |
|---|---|---|
| Artefatos semanais no ambiente da aula e no repositório | 40% | Aulas 01 a 07 |
| Dashboard narrativo final | 30% | Aula 08 |
| Apresentação e defesa | 20% | Aula 08 |
| Participação nas revisões por pares | 10% | Contínuo |

Critério transversal: toda escolha de representação precisa de justificativa explícita e evidência de teste. Trabalho sem brief, rastreabilidade, alternativa considerada, auditoria e limitação declarada é avaliado como incompleto, ainda que visualmente correto.

### Rubrica comum dos artefatos

| Dimensão | Peso | Evidência esperada |
|---|---:|---|
| Contexto e pergunta | 15% | público, tarefa, decisão e pergunta verificável |
| Qualidade e integridade | 20% | fonte, grão, regra, limitação e risco de viés |
| Representação e percepção | 20% | codificação adequada e alternativa descartada |
| Acessibilidade | 15% | cor não exclusiva, contraste, texto e tabela equivalente |
| Validação | 15% | teste, achados, severidade, correção e reteste |
| Comunicação e ação | 15% | mensagem, recomendação e próximo passo explícitos |

---

## 7. Preparação de infraestrutura — checklist do professor

Antes da Aula 01 (15/08):

- [ ] VM provisionada com Docker e Docker Compose
- [ ] `docker-compose.yml` com Metabase, Postgres de aplicação e Postgres do Olist
- [ ] Dataset Olist carregado e com índices nas colunas de junção
- [ ] Usuário read-only criado no banco Olist e conectado ao Metabase
- [ ] Grupo `Alunos` com permissão de leitura e de criação de perguntas
- [ ] Contas dos alunos criadas e credenciais distribuídas
- [ ] Metadados revisados no admin: tipos semânticos, campos ocultos, descrições de tabela
- [ ] Timeout de query configurado
- [ ] Backup inicial: dump do Postgres de aplicação + serialização

Semanalmente:

- [ ] Serialização exportada após cada aula
- [ ] Verificação de espaço em disco e de queries lentas

---

## 8. Status de implementação do material

- [x] Aula 01 — 15/08/2026 — Data Discovery com Metabase
- [x] Aula 02 — 22/08/2026 — Arquitetura de BI e Modelagem Dimensional com Olist
- [x] Aula 03 — 29/08/2026 — Visualização de Dados Numéricos
- [x] Aula 04 — 05/09/2026 — Do Excel ao OLAP com SQLite, DuckDB e IA
- [x] Aula 05 — 12/09/2026 — Modelo Mental do Usuário e Ciclo de Vida do Dado
- [x] Aula 06 — 19/09/2026 — Heurísticas e Vieses
- [x] Aula 07 — 26/09/2026 — Storytelling com Dados
- [x] Aula 08 — 03/10/2026 — Entrega do Projeto Final

---

## 9. Convenções mantidas

- Pastas e arquivos em `snake_case`, conforme `specs/estrutura_curso.md`.
- Slides em `aulas/data_visualization/aula_xx_*/slides/`, materiais em `.../material/`.
- Sistema de slides HTML nativo com `assets/slides.css`.
- Todo slide-deck tem capa, agenda, placeholder inicial e links para material, home da disciplina e `index.html`.
- Todo material encerra com orientação para a atividade prática em sala — a disciplina é 100% prática, sem seção de exercícios escritos.
- Design system conforme `specs/design_system.md`: off-white, texto preto, cantos de 4px, alta densidade, responsivo.

**Desvios conscientes da spec:** a Aula 08 não tem bloco teórico — é ateliê de finalização e entrega, e `specs/repositorio_de_aulas.md` foi atualizada para registrar essa segunda exceção ao lado da Aula 04. Além disso, `specs/repositorio_de_aulas.md` determina que a parte prática use o ambiente AWS Student Lab. Data Visualization usa a instância Metabase hospedada pelo professor — a disciplina não tem componente de infraestrutura em nuvem, e o AWS Student Lab expira em 4 horas, o que inviabilizaria a persistência do trabalho ao longo das 8 semanas.
