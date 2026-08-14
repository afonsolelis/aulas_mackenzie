# Roadmap — Data Visualization

**MBA Engenharia de Dados — Mackenzie — 2026**
Documento vivo de planejamento das 8 aulas da disciplina. Sábados, 8h30 – 12h10, de 15/08/2026 a 03/10/2026. Carga total: 32 h/a.

---

## 1. Premissa da disciplina

A ementa institucional pede percepção humana, representações para dados numéricos e não numéricos, tabelas, gráficos, mapas, indicadores de performance, dashboards e storytelling. O risco de uma disciplina assim é virar catálogo de tipos de gráfico — o aluno aprende a nomear um treemap e continua sem saber quando usá-lo.

A trilha evita isso invertendo a ordem natural do catálogo:

> *"Antes de escolher como mostrar, é preciso saber o que existe e o que se quer perguntar."*

Por isso a Aula 01 não é sobre percepção — é sobre **descobrir os dados**. O aluno abre um dataset real que nunca viu, perfila, encontra buracos, formula perguntas de negócio e só então, na Aula 02, aprende por que certas representações comunicam melhor que outras. Toda escolha visual das aulas seguintes se apoia em perguntas que o próprio aluno levantou na primeira semana.

---

## 2. Arco pedagógico

Oito aulas, uma progressão única:

```
01  Descobrir os dados            Data Discovery, perfilamento, perguntas de negócio
02  Entender a percepção          Gestalt, pré-atentivos, canais de codificação
03  Comparar números              distribuições, séries temporais, magnitude
04  Representar categorias        categóricos, hierarquias, texto livre
05  Escolher a representação      tabela vs. gráfico, matriz de decisão
06  Situar no espaço              mapas, geoespacial, escolha de projeção
07  Medir desempenho              KPI, SLA, dashboards, filtros e alertas
08  Contar a história             storytelling, narrativa, defesa do projeto
```

Cada aula produz **um artefato no Metabase** (perguntas salvas, dashboard, coleção organizada) e **um registro escrito** (`docs/NN_*.md` no repositório do aluno). A aula seguinte consome os dois.

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

O produto da disciplina não é apenas um dashboard. É um dossiê auditável que mostra como cada decisão foi tomada:

| Aula | Documento | Evidência profissional |
|---|---|---|
| 01 | `01_brief_e_qualidade.md` | brief, perfil ISO-aligned, regras e limitações |
| 02 | `02_auditoria_heuristica.md` | problemas, severidade, evidência e correção |
| 03 | `03_registro_numerico.md` | escala, agregação, incerteza e alternativas |
| 04 | `04_protocolo_categorias.md` | taxonomia, corte, perda e viés de classificação |
| 05 | `05_especificacao_visual.md` | matriz de decisão e alternativa acessível |
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
| Percepção humana | Aula 02 (núcleo), reforçada em 03, 04 e 05 |
| Dados numéricos | Aula 03 |
| Dados não numéricos | Aula 04 |
| Tabelas e gráficos | Aula 05 |
| Mapas | Aula 06 |
| Indicadores de performance | Aula 07 |
| Dashboards | Aula 07 (construção), Aula 08 (narrativa) |
| Storytelling com dados | Aula 08 |

Data Discovery (Aula 01) não consta explicitamente na ementa — entra como pré-requisito prático e como setup da ferramenta, sem deslocar nenhum tópico obrigatório.

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
│   ├── 02_auditoria_heuristica.md    # Aula 02 — achados, severidade e reteste
│   ├── 03_registro_numerico.md       # Aula 03 — decisões numéricas e alternativas
│   ├── 04_protocolo_categorias.md    # Aula 04 — taxonomia, corte, perda e viés
│   ├── 05_especificacao_visual.md    # Aula 05 — matriz, especificação e acessibilidade
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

Todas as aulas seguem o mesmo formato: **8h30 – 10h00 teoria**, **10h00 – 12h10 prática no Metabase**.

### Aula 01 — 15/08/2026 — Data Discovery com Metabase
**Conceitual:** o que é data discovery e por que antecede a visualização; perfilamento de dados (completude, cardinalidade, distribuição, outliers); tipos semânticos vs. tipos físicos; da pergunta vaga à pergunta respondível; grão da análise.
**Prática:** primeiro acesso à instância; navegação pelo schema Olist; X-ray automático de tabelas; query builder (filtro, sumarização, agrupamento, junção); perfilamento das 9 tabelas; formulação de 10 perguntas de negócio.
**Artefato:** coleção nomeada com 5 perguntas salvas + `docs/01_brief_e_qualidade.md` com contexto, perfil, regras, limitações e backlog.
**Saída verificável:** o aluno consegue afirmar, com evidência na tela, quantos pedidos existem, qual o período coberto, onde há nulos e quais três perguntas de negócio valem ser investigadas no semestre.

### Aula 02 — 22/08/2026 — Percepção Visual e Processo de Criação
**Conceitual:** sistema visual humano e carga cognitiva; atributos pré-atentivos; princípios de Gestalt; ranking de canais de codificação (Cleveland & McGill); razão dado-tinta (Tufte); lie factor e distorção de escala; o ciclo de criação e interpretação.
**Prática:** reconstrução de uma visualização deliberadamente ruim construída sobre uma das perguntas da Aula 01; ajuste de ordenação, cor, rótulo e eixo no Metabase; teste dos cinco segundos com um colega.
**Artefato:** par antes/depois salvo na coleção + `docs/02_auditoria_heuristica.md` com achados, severidade, correção e reteste.
**Saída verificável:** o colega consegue dizer a mensagem do gráfico revisado em cinco segundos; cada mudança tem justificativa perceptiva, não estética.

### Aula 03 — 29/08/2026 — Visualização de Dados Numéricos
**Conceitual:** os quatro trabalhos do gráfico numérico — comparar magnitude, mostrar distribuição, revelar evolução, expor relação; escolha do gráfico por trabalho; quando o eixo pode e não pode ser truncado; média vs. mediana em cauda longa; agregação e o paradoxo de Simpson.
**Prática:** série temporal de pedidos com granularidade variável; histograma de ticket; comparação de magnitude entre categorias; dispersão preço × frete; tratamento de outliers.
**Artefato:** 4 perguntas numéricas salvas, uma por tipo de trabalho + `docs/03_registro_numerico.md`.
**Saída verificável:** cada gráfico declara qual dos quatro trabalhos executa e por que o tipo escolhido é superior às alternativas descartadas.

### Aula 04 — 05/09/2026 — Visualização de Dados Não Numéricos
**Conceitual:** o que muda quando o dado é categórico, hierárquico, textual ou relacional; cardinalidade alta e a armadilha do "top N + outros"; ordenação de categorias nominais vs. ordinais; por que gráficos de pizza falham; representação de texto livre.
**Prática:** ranking de 71 categorias de produto; agrupamento de cauda longa; análise dos comentários de review por score; construção de uma hierarquia categoria → produto.
**Artefato:** 3 perguntas categóricas + uma análise textual + `docs/04_protocolo_categorias.md`.
**Saída verificável:** o aluno defende o corte da cauda longa com critério explícito e mostra o que se perde nesse corte.

### Aula 05 — 12/09/2026 — Tabelas, Gráficos e Escolha da Representação
**Conceitual:** quando a tabela é a resposta certa; tabela como instrumento de leitura precisa vs. gráfico como instrumento de padrão; tabela dinâmica; formatação condicional e micrográficos embutidos; construção coletiva de uma matriz de decisão de representação.
**Prática:** mesma pergunta respondida como tabela, tabela dinâmica e gráfico; formatação condicional; consolidação da matriz de decisão da turma.
**Artefato:** matriz de decisão consolidada + `docs/05_especificacao_visual.md`.
**Saída verificável:** dada uma pergunta nova, o aluno percorre a matriz e justifica a representação escolhida em menos de um minuto.

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
| Artefatos semanais no Metabase e no repositório | 40% | Aulas 01 a 07 |
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
- [ ] Aula 02 — 22/08/2026 — Percepção Visual e Processo de Criação
- [ ] Aula 03 — 29/08/2026 — Visualização de Dados Numéricos
- [ ] Aula 04 — 05/09/2026 — Visualização de Dados Não Numéricos
- [ ] Aula 05 — 12/09/2026 — Tabelas, Gráficos e Escolha da Representação
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
