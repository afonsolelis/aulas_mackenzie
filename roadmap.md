# Roadmap — Cloud Computing e SRE (visão prática com AWS)

**MBA Engenharia de Dados — Mackenzie — 2026**
Documento vivo de planejamento da trilha das Aulas 02 a 08. A Aula 01 (16/04/2026 — Fundamentos de Cloud e Governança de Acessos) já foi ministrada e permanece como base.

---

## 1. Premissa da reformulação

Os alunos chegam com bagagem prévia de ferramentas e Big Data. Por isso, a trilha 02→08 **abandona o formato "tour de serviços"** e adota **engenharia de confiabilidade como propriedade sistêmica**. Cloud e AWS continuam sendo o substrato prático, mas o centro de gravidade é:

> *"Como modelamos, especificamos, construímos, validamos e operamos um sistema de dados confiável?"*

A teoria não é abstrata — ela vira **spec executável** que alimenta a IA do aluno, que gera código para um projeto real (ETL Olist em Python) que é operado, monitorado e estressado ao longo do semestre.

---

## 2. Arco pedagógico

Sete aulas, uma progressão única:

```
02  Definir o problema              SWEBOK + SEBoK
03  Contratar a confiabilidade      RNFs (ISO 25010) → SLI/SLO/Error Budget
04  Modelar a arquitetura           RM-ODP (5 viewpoints)
05  Dominar concorrência            CAP, idempotência, exactly-once
06  Dominar escalabilidade          Little, Amdahl, USL, capacity
07  Simular o sistema               Gêmeos digitais, FMEA, chaos
08  Validar por análise             ATAM + defesa do projeto final
```

Cada aula produz **um artefato de spec** (conceitual) e **um incremento do projeto** (engenharia). A aula seguinte consome os dois.

---

## 3. Stack técnica definitiva

### Ambiente de desenvolvimento

- **GitHub Codespaces** — dev environment padrão para todos os alunos.
- **IAs no Codespace**: cada aluno usa o agente de código ou a IA de sua preferência (Claude Code, Codex CLI, Gemini CLI, OpenCode, Cursor ou Copilot). Comparar saídas entre IAs é exercício natural da trilha SDD.

### Spec-Driven Development

- Spec **não é imposto** — na Aula 02 os alunos **pesquisam guias de especificação** (IEEE 830, Volere, EARS, Gherkin/BDD, ARC42, Kiro/GitHub Spec Kit) e a turma consolida o template que será usado no projeto.
- A própria pesquisa é exercício de "Software Engineering Professional Practice" do SWEBOK.
- A spec evolui aula a aula e é o **input primário** da IA para gerar código.

### Projeto prático — ETL Olist

- Linguagem: **Python**
- Dataset: **Olist Brazilian E-commerce** (Kaggle) — fio condutor único do curso.
- Pipeline: ingestão CSV → transformação → carga em Postgres → dashboards.

### Infraestrutura como código

- **AWS CloudFormation** (YAML) — IaC nativa da AWS, 100% autorizada pelo LabRole, sem dependência de state externo, com rollback automático.
- Decisão tomada em detrimento de Terraform (problema de state no Student Lab) e CDK (overhead desnecessário para o escopo).

### Arquitetura-alvo

```
Codespace (dev + agente de código do aluno)
       │ git push
       ▼
CloudFormation stacks
       │
       ├── ec2-app (t3.micro): Python ETL + scheduler
       │     └── CloudWatch Agent → CloudWatch (SRE: latência, erro, CPU, memória)
       │
       └── ec2-data (t3.micro): Postgres (self-hosted) + Grafana
             ├── Grafana lê Postgres → dashboards de negócio (receita, SLA entrega)
             └── Acesso ao Grafana via SSH tunnel do Codespace
```

**Separação de responsabilidades:**
- **Grafana** lê o **banco** e mostra dados de **negócio** (KPIs do Olist).
- **CloudWatch** observa o **pipeline** e mostra dados de **SRE** (saúde do sistema).

### Restrições do AWS Student Lab aceitas no design

- Apenas **LabRole** — sem criação de usuários/roles IAM.
- Região única: **us-east-1**.
- Instâncias: **t3.micro** (1 GB RAM). Nano fica pequeno para Postgres + Grafana.
- Sem RDS — Postgres self-hosted via `user-data`.
- Sessão do Learner Lab expira em 4h; EBS persiste dados entre sessões.
- Elastic IP não usado — preferência por SSH tunnel (mais didático para SRE).
- Budget ~US$100; duas t3.micro por 3h/semana ficam muito abaixo.

---

## 4. Repositório do aluno (estrutura-alvo ao final da Aula 08)

```
olist-sre-pipeline/
├── spec/
│   ├── 00_problem.md            # Aula 02 — modelagem SWEBOK/SEBoK
│   ├── 01_nfr.md                # Aula 03 — utility tree + SLI/SLO
│   ├── 02_architecture.md       # Aula 04 — 5 viewpoints RM-ODP
│   ├── 03_concurrency.md        # Aula 05 — decisões de concorrência
│   ├── 04_scalability.md        # Aula 06 — capacity plan
│   ├── 05_chaos.md              # Aula 07 — FMEA + plano de chaos
│   └── 06_atam.md               # Aula 08 — relatório ATAM
├── iac/
│   ├── network.yaml             # Aula 04
│   ├── ec2-app.yaml             # Aula 04
│   ├── ec2-data.yaml            # Aula 04
│   └── cloudwatch.yaml          # Aula 06/07
├── src/
│   ├── etl/                     # Aulas 04→06
│   └── tests/                   # Aulas 05→06 (pytest + hypothesis)
├── observability/
│   ├── grafana/dashboards/      # Aula 06
│   └── cloudwatch/alarms.yaml   # Aula 07
├── chaos/
│   └── experiments/             # Aula 07
└── reports/
    ├── capacity.md              # Aula 06
    ├── gameday.md               # Aula 07
    └── atam.md                  # Aula 08
```

---

## 5. Mapa detalhado das aulas

### Aula 02 — 23/04/2026 — Modelagem do problema SRE
**Conceitual:** SWEBOK (Quality, Models & Methods, Professional Practice) + SEBoK (systems thinking, propriedades emergentes, system of systems).
**Pesquisa dos alunos:** guias de especificação — cada grupo apresenta 1 guia.
**Artefato de spec:** `spec/00_problem.md` + template de spec adotado pela turma.
**Engenharia:** bootstrap do Codespace, abertura do agente de código escolhido pelo aluno, criação do repositório do projeto, primeiro commit.
**Saída verificável:** repo inicializado, IA respondendo no terminal, `00_problem.md` descrevendo o problema SRE do Olist.

### Aula 03 — 30/04/2026 — RNFs como contrato
**Conceitual:** ISO/IEC 25010, RNFs → SLI/SLO/SLA, error budget, burn rate, taxonomia de reliability.
**Artefato de spec:** `spec/01_nfr.md` — utility tree priorizada, SLIs/SLOs definidos.
**Engenharia:** IA gera **esqueleto de testes de SLO** (pytest) e **stub de dashboard Grafana** a partir do spec. Postgres local no Codespace para desenvolvimento.
**Saída verificável:** testes de SLO rodando verde contra mock, dashboard Grafana JSON versionado no repo.

### Aula 04 — 07/05/2026 — Arquitetura por viewpoints (RM-ODP)
**Conceitual:** ISO/IEC 10746 — Enterprise, Information, Computational, Engineering, Technology viewpoints aplicados ao Olist ETL.
**Artefato de spec:** `spec/02_architecture.md` — 5 viewpoints preenchidos.
**Engenharia:** IA gera **CloudFormation base** (VPC simples, 2x t3.micro, Security Groups, user-data para Postgres e Grafana) e **scaffold Python** do ETL. Deploy inicial no AWS Student Lab.
**Saída verificável:** `cloudformation create-stack` sobe o ambiente; Grafana acessível via SSH tunnel; ETL "hello-world" roda na EC2.

### Aula 05 — 14/05/2026 — Concorrência, consistência e coordenação
**Conceitual:** CAP/PACELC, idempotência, at-least-once vs exactly-once, clocks lógicos (Lamport), backpressure, outbox, saga.
**Artefato de spec:** `spec/03_concurrency.md` — decisões de consistência do pipeline.
**Engenharia:** ingestão e carga implementadas com **checkpoints idempotentes**; testes de **concorrência** (pytest + hypothesis) reproduzem race condition e validam a correção.
**Saída verificável:** ETL processa Olist completo sem duplicatas mesmo com reexecução; suite de testes passa; logs de CloudWatch mostram reruns seguros.

### Aula 06 — 21/05/2026 — Escalabilidade e capacity
**Conceitual:** Little's Law, Amdahl, Universal Scalability Law (Gunther), sharding, replication, hotspots, cascading failures.
**Artefato de spec:** `spec/04_scalability.md` + `reports/capacity.md`.
**Engenharia:** **load test** (Locust) contra o ETL; métricas customizadas publicadas no **CloudWatch**; dashboards Grafana para **dados de negócio** (receita por estado, SLA de entrega, top categorias); relatório de capacity com gráfico USL ajustado.
**Saída verificável:** dashboards Grafana renderizam KPIs do Olist em tempo real; CloudWatch mostra throughput do ETL; capacity report identifica o gargalo.

### Aula 07 — 28/05/2026 — Gêmeos digitais e chaos engineering
**Conceitual:** digital twin como modelo executável, FMEA, STAMP, fault injection, game days, princípios do Chaos Engineering.
**Artefato de spec:** `spec/05_chaos.md` + `reports/gameday.md`.
**Engenharia:** experimentos de chaos (derrubar `ec2-app` durante um run, introduzir latência, corromper batch); alarmes CloudWatch; validação de que o SLO da Aula 03 **se mantém** sob falha.
**Saída verificável:** registro de game day com hipótese, experimento, observação e decisão; alarmes disparando corretamente; SLO resiliente.

### Aula 08 — 11/06/2026 — Validação com ATAM + projeto final
**Conceitual:** ATAM (SEI/Carnegie Mellon) — utility tree, cenários growth/exploratory/direct, sensitivity points, tradeoffs, risks, non-risks.
**Artefato de spec:** `spec/06_atam.md` + `reports/atam.md`.
**Engenharia:** nenhum código novo — foco em **defesa** do sistema construído.
**Saída verificável:** apresentação final integrando os 6 artefatos de spec, a arquitetura deployed, os dashboards, o game day e o relatório ATAM.

---

## 6. Loop Spec-Driven Development que se repete em cada aula

1. **Conceito** — aula expositiva introduz o framework da semana.
2. **Spec** — aluno escreve/atualiza o artefato `spec/XX_*.md`.
3. **Geração** — aluno invoca o agente de código de sua preferência passando o spec como contexto.
4. **Revisão** — aluno lê o código gerado, identifica divergências, ajusta.
5. **Testes** — suite pytest roda localmente e no Codespace.
6. **Deploy** — `aws cloudformation update-stack` ou push direto via `scp`/`aws ssm`.
7. **Observação** — Grafana (negócio) + CloudWatch (SRE) validam o comportamento.

Este loop é a tese do curso: **a qualidade da spec é a qualidade do sistema**.

---

## 7. Entregáveis do aluno ao final do curso

- Repositório GitHub público com 7 specs, IaC, código Python, testes e dashboards.
- Sistema Olist ETL operante no AWS Student Lab (demonstrável em vídeo ou ao vivo).
- Relatório ATAM de no máximo 10 páginas.
- Apresentação final de 15 minutos cobrindo o arco completo.

---

## 8. Status de implementação do material

- [x] Aula 01 — ministrada em 16/04/2026
- [ ] Aula 02 — 23/04/2026 — material a ser reformulado
- [ ] Aula 03 — 30/04/2026 — material a ser reformulado
- [ ] Aula 04 — 07/05/2026 — material a ser reformulado
- [ ] Aula 05 — 14/05/2026 — material a ser reformulado
- [ ] Aula 06 — 21/05/2026 — material a ser reformulado
- [ ] Aula 07 — 28/05/2026 — material a ser reformulado
- [ ] Aula 08 — 11/06/2026 — material a ser reformulado
- [ ] `index.html` — reescrever ementa da home para refletir o novo escopo

---

## 9. Convenções mantidas do CLAUDE.md

- Pastas e arquivos em `snake_case`.
- Slides em `aulas/aula_xx_*/slides/`, materiais em `aulas/aula_xx_*/material/`.
- Sistema de slides HTML-nativo (`assets/slides.css`).
- Todo slide-deck tem capa + agenda + placeholder inicial + links para material e `index.html`.
- Todo material encerra com orientação para a atividade hands-on em sala — o curso é 100% prático, não há seção de exercícios escritos.
- Design system: fundo branco, texto preto, alta densidade, cantos retos, responsivo.

As pastas de aula **não serão renomeadas** — o nome da pasta fica por conta da estrutura original; o conteúdo interno é que muda de foco.
