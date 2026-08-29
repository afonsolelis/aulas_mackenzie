# Roadmap — Data Visualization

**MBA Engenharia de Dados — Mackenzie — 2026**
Documento vivo de planejamento das 8 aulas da disciplina. Sábados, 8h30 – 12h10, de 15/08/2026 a 03/10/2026. Carga total: 32 h/a.

---

## 1. Premissa da disciplina

A ementa institucional contempla percepção humana, representações para dados numéricos e não numéricos, tabelas, gráficos, mapas, indicadores de performance, dashboards e storytelling. A disciplina organiza esses conteúdos como um processo analítico completo, no qual a representação visual depende de dados compreendidos, arquitetura identificável e semântica consistente.

A Aula 01 estabelece o perfil do conjunto Olist e formula perguntas de negócio. A Aula 02 localiza aquisição, persistência, camada semântica e consumo nas principais arquiteturas de BI e converte o esquema operacional em fatos e dimensões. As aulas seguintes utilizam esse modelo para estudar percepção, comparação, construção de uma cadeia analítica local, categorias, espaço, indicadores e narrativa.

---

## 2. Arco pedagógico

Oito aulas, uma progressão única:

```
01  Descobrir os dados            Data Discovery, perfilamento, perguntas de negócio
02  Arquitetar e modelar          plataformas de BI, fatos, dimensões, SCD, barramento
03  Comparar números              percepção, distribuições, séries temporais, magnitude
04  Construir a cadeia local      Excel, SQLite, HTML, DuckDB, OLAP e IA
05  Representar categorias        categóricos, texto, tabela vs. gráfico
06  Situar no espaço              mapas, geoespacial, escolha de projeção
07  Medir desempenho              KPI, SLA, dashboards, filtros e alertas
08  Contar a história             storytelling, narrativa, defesa do projeto
```

Cada aula produz artefatos verificáveis e um registro escrito no repositório do aluno. Nas aulas regulares, o artefato principal fica no **Metabase**; a Aula 03 produz uma visualização D3 e a Aula 04 produz scripts, dois bancos, dois HTMLs e reconciliações no Codespaces.

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
| 05 | `05_protocolo_categorias.md` | taxonomia, corte, perda, viés e alternativa de representação |
| 06 | `06_revisao_geoespacial.md` | normalização, unidade espacial, privacidade e risco |
| 07 | `07_kpis_e_teste.md` | dicionário de KPI e teste de tarefas do dashboard |
| 08 | `08_estudo_de_caso.md` | narrativa, evidências, limitações e recomendação |

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
| Percepção humana | Aulas 03 e 05, aplicada aos diferentes trabalhos visuais |
| Dados numéricos | Aula 03 |
| Dados não numéricos | Aula 05 |
| Tabelas e gráficos | Aulas 03 e 05 |
| Integração de fontes e publicação | Aula 04, do Excel aos HTMLs via SQLite e DuckDB |
| Mapas | Aula 06 |
| Indicadores de performance | Aula 07 |
| Dashboards | Aula 07 (construção), Aula 08 (narrativa) |
| Storytelling com dados | Aula 08 |

Data Discovery (Aula 01) e arquitetura/modelagem de BI (Aula 02) funcionam como pré-requisitos práticos para os tópicos de representação e asseguram que os gráficos posteriores utilizem métricas rastreáveis.

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

### Repositório do aluno

O trabalho escrito acompanha o trabalho visual. Estrutura-alvo ao final da Aula 08:

```
olist-dataviz/
├── docs/
│   ├── 01_brief_e_qualidade.md       # Aula 01 — contexto, perfil e regras de dados
│   ├── 02_arquitetura_e_modelo.md    # Aula 02 — arquitetura, grãos, barramento e testes
│   ├── 03_registro_numerico.md       # Aula 03 — decisões numéricas e alternativas
│   ├── 04_pipeline_excel_olap.md      # Aula 04 — reconciliação, tempos e limitações
│   ├── 05_protocolo_categorias.md    # Aula 05 — taxonomia, corte, perda e viés
│   ├── 06_revisao_geoespacial.md     # Aula 06 — normalização, risco e privacidade
│   ├── 07_kpis_e_teste.md            # Aula 07 — fichas de KPI e teste de tarefas
│   └── 08_estudo_de_caso.md          # Aula 08 — narrativa, evidências e limitações
├── sql/                       # consultas nativas relevantes, versionadas
└── export/
    ├── perguntas.json         # serialização das perguntas do Metabase
    └── dashboard.json         # serialização do dashboard final
```

---

## 4. Mapa detalhado das aulas

As aulas combinam fundamentação, demonstração e prática. A Aula 04 é a exceção deliberada: 100% prática, com os conceitos introduzidos durante a execução guiada. O Metabase sustenta as aulas regulares; as Aulas 03 e 04 usam GitHub Codespaces e assistência de IA para produzir artefatos versionáveis.

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
**Prática integral:** configuração do OpenCode Zen no terminal do Codespaces; download e perfil de nove Excels Olist; carga em SQLite; geração de HTML operacional; materialização em DuckDB; construção de fato e mart; geração de HTML analítico.
**Artefato:** seis scripts, `olist.sqlite`, `olist.duckdb`, dois relatórios HTML, registros de reconciliação e `docs/04_pipeline_excel_olap.md`.
**Saída verificável:** o grupo reconstrói os dois HTMLs a partir dos Excels, demonstra a fonte de cada número e compara a mesma consulta nos dois mecanismos sem exceder a evidência medida.

### Aula 05 — 12/09/2026 — Visualização de Dados Não Numéricos
**Conceitual:** dado categórico, hierárquico, textual ou relacional; cardinalidade alta e a armadilha do "top N + outros"; ordenação nominal e ordinal; tabela simples, tabela dinâmica, formatação condicional e gráfico conforme a tarefa.
**Prática:** ranking de 71 categorias em tabela, forma híbrida e barras; corte da cauda longa; comentários por score; hierarquia categoria → produto; construção e teste de uma matriz coletiva de representação.
**Artefato:** tabela completa, versão híbrida, perguntas categóricas, análise textual e `docs/05_protocolo_categorias.md` com a matriz.
**Saída verificável:** o aluno defende corte, ordem e representação com critério explícito, mostra o que se perde em cada decisão e testa a matriz contra uma pergunta nova.

### Aula 06 — 19/09/2026 — Mapas e Visualização Geoespacial
**Conceitual:** quando o espaço é a variável relevante e quando é distração; mapa de pontos vs. mapa de regiões; o problema do mapa que só mostra densidade populacional; normalização por população ou por base de clientes; projeções e distorção de área.
**Prática:** mapa de regiões por estado com GeoJSON do Brasil; mapa de pontos com a base de geolocalização; normalização de métrica; análise de frete e prazo por distância.
**Artefato:** 2 mapas com justificativa de normalização + `docs/06_revisao_geoespacial.md`.
**Saída verificável:** o aluno demonstra, com o mesmo dado, como a falta de normalização produz uma conclusão errada.

### Aula 07 — 26/09/2026 — Indicadores de Performance e Dashboards
**Conceitual:** o que separa métrica de indicador; ficha técnica do KPI (definição, fórmula, grão, meta, dono, frequência); indicadores de resultado vs. de tendência; o dashboard como instrumento de decisão e não de exibição; layout, ordem de leitura e densidade; alertas.
**Prática:** definição de 4 KPIs do Olist; construção do dashboard com filtros e parâmetros; comportamento de clique para drill-down; configuração de alerta.
**Artefato:** dashboard funcional com 4 KPIs e filtros + `docs/07_kpis_e_teste.md` com fichas técnicas e teste de tarefas.
**Saída verificável:** cada KPI tem fórmula explícita e meta declarada; o dashboard responde a uma pergunta de decisão, não apenas exibe números.

### Aula 08 — 03/10/2026 — Storytelling com Dados e Projeto Final
**Conceitual:** narrativa aplicada a dados — contexto, conflito, resolução; a diferença entre exploração e explicação; sequenciamento; anotação como camada de significado; adequação ao público; apresentação e defesa.
**Prática:** curadoria do trabalho das 7 aulas anteriores; montagem do dashboard narrativo em abas; ensaio; apresentação final de 12 minutos.
**Artefato:** dashboard narrativo + `docs/08_estudo_de_caso.md` + exportação completa da coleção.
**Saída verificável:** apresentação de 12 minutos que leva a audiência de uma pergunta de negócio a uma recomendação sustentada por evidência visual.

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

- [ ] Aula 01 — 15/08/2026 — Data Discovery com Metabase
- [x] Aula 02 — 22/08/2026 — Arquitetura de BI e Modelagem Dimensional com Olist
- [ ] Aula 03 — 29/08/2026 — Visualização de Dados Numéricos
- [x] Aula 04 — 05/09/2026 — Do Excel ao OLAP com SQLite, DuckDB e IA
- [x] Aula 05 — 12/09/2026 — Visualização de Dados Não Numéricos
- [ ] Aula 06 — 19/09/2026 — Mapas e Visualização Geoespacial
- [ ] Aula 07 — 26/09/2026 — Indicadores de Performance e Dashboards
- [ ] Aula 08 — 03/10/2026 — Storytelling com Dados e Projeto Final

---

## 9. Convenções mantidas

- Pastas e arquivos em `snake_case`, conforme `specs/estrutura_curso.md`.
- Slides em `aulas/data_visualization/aula_xx_*/slides/`, materiais em `.../material/`.
- Sistema de slides HTML nativo com `assets/slides.css`.
- Todo slide-deck tem capa, agenda, placeholder inicial e links para material, home da disciplina e `index.html`.
- Todo material encerra com orientação para a atividade prática em sala — a disciplina é 100% prática, sem seção de exercícios escritos.
- Design system conforme `specs/design_system.md`: off-white, texto preto, cantos de 4px, alta densidade, responsivo.

**Desvio consciente da spec:** `specs/repositorio_de_aulas.md` determina que a parte prática use o ambiente AWS Student Lab. Data Visualization usa a instância Metabase hospedada pelo professor — a disciplina não tem componente de infraestrutura em nuvem, e o AWS Student Lab expira em 4 horas, o que inviabilizaria a persistência do trabalho ao longo das 8 semanas.
