# Pós-Graduação EAD: Arquitetura de Software, IA e SRE (360h)
---

## 1. Apresentação do Curso

**Carga Horária Total:** 360 horas (12 módulos de 30 horas)
**Formato:** Ensino a Distância (EAD) com encontros síncronos e atividades assíncronas.
**Foco:** Formar arquitetos de software capazes de projetar, construir e operar sistemas complexos, resilientes e escaláveis, utilizando práticas ágeis, computação em nuvem e inteligência artificial como ferramentas estratégicas.

O curso é desenhado para profissionais que buscam liderança técnica, combinando uma base sólida em engenharia de software com as habilidades mais demandadas pelo mercado em 2026: arquitetura cloud-native, engenharia de confiabilidade (SRE) e o uso pragmático de IA no ciclo de vida de desenvolvimento.

---

## 2. Estrutura Curricular Detalhada

### **Módulo 1: Liderança e Cultura Ágil para Arquitetos**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Diferenciar papéis de liderança técnica. Facilitar cerimônias ágeis com foco em resultados de engenharia. Promover uma cultura de feedback construtivo e segurança psicológica. Mediar e resolver conflitos técnicos com base em dados e trade-offs.
-   **Tópicos Abordados:** O Manifesto Ágil na prática. Papéis: Tech Lead, Arquiteto, Engineering Manager. Psicologia da segurança em times de alta performance. Comunicação não-violenta para Code Reviews. Técnicas de facilitação para retrospectivas e postmortems blameless.
-   **Ferramentas e Tecnologias:** Jira, Trello, Miro, frameworks de feedback (ex: Radical Candor).
-   **Atividade Prática:** Simulação de um postmortem de incidente, com alunos assumindo os papéis de IC, Ops e Scribe, focando na identificação de fatores sistêmicos em vez de culpa individual.

### **Módulo 2: Gestão de Produtos e Projetos Ágeis**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Traduzir requisitos de negócio em épicos e estórias técnicas fatiáveis. Priorizar o backlog técnico e de produto usando frameworks quantitativos. Calcular e interpretar métricas de fluxo (DORA, Lead Time).
-   **Tópicos Abordados:** User Story Mapping, Behavior-Driven Development (BDD) com Gherkin. Técnicas de priorização (MoSCoW, WSJF, Cost of Delay). Métricas DORA (Deployment Frequency, Lead Time for Changes, Change Failure Rate, Time to Restore Service).
-   **Ferramentas e Tecnologias:** Jira, Confluence, Cucumber, Gherkin.
-   **Atividade Prática:** Decompor uma feature complexa (ex: "sistema de busca de um e-commerce") em um User Story Map detalhado, escrevendo os critérios de aceitação em Gherkin.

### **Módulo 3: Versionamento e Engenharia de Software Moderna**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Implementar estratégias de branching e merging para times distribuídos. Construir um pipeline de CI/CD do zero. Automatizar gates de qualidade e segurança. Empacotar aplicações em containers Docker.
-   **Tópicos Abordados:** Estratégias de Git (Trunk-Based Development vs. Git Flow). CI/CD com GitHub Actions. Infrastructure as Code (IaC) com Terraform. Containerização com Docker e Docker Compose.
-   **Ferramentas e Tecnologias:** Git, GitHub Actions, Docker, Terraform.
-   **Atividade Prática:** Construir um pipeline CI/CD completo que executa lint, testes, build de imagem Docker, e a publica em um registry (ex: GitHub Container Registry).

### **Módulo 4: Modelando Arquiteturas de Software**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Aplicar o C4 Model para documentar arquitetura em diferentes níveis de abstração. Utilizar Domain-Driven Design (DDD) para identificar Bounded Contexts. Documentar decisões arquiteturais de forma explícita e auditável.
-   **Tópicos Abordados:** C4 Model (Contexto, Contêineres, Componentes, Código). Padrões de Arquitetura (Microsserviços, Monolito Modular, Hexagonal). DDD Estratégico e Tático. Architecture Decision Records (ADRs).
-   **Ferramentas e Tecnologias:** Mermaid.js, PlantUML, Structurizr Lite.
-   **Atividade Prática:** Modelar um sistema conhecido (ex: Netflix, Uber) usando C4 Model e identificar seus principais Bounded Contexts, documentando duas decisões arquiteturais críticas como ADRs.

### **Módulo 5: Desenvolvimento Assistido por IA e Agentes**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Acelerar o desenvolvimento de código e testes usando LLMs. Orquestrar múltiplos agentes de IA para resolver tarefas complexas. Implementar um ciclo de Spec-Driven Development (SDD).
-   **Tópicos Abordados:** Prompt Engineering para código. Retrieval-Augmented Generation (RAG) para dar contexto de domínio à IA. Construção de squads de agentes com CrewAI/AutoGen. Fine-tuning de modelos para estilos de código específicos.
-   **Ferramentas e Tecnologias:** agente de código de preferência do aluno (Claude Code, Codex CLI, Gemini CLI ou OpenCode), CrewAI, LangChain, Vector Databases (ChromaDB).
-   **Atividade Prática:** Criar uma "squad" de agentes (Arquiteto, Desenvolvedor, Revisor de Código) para gerar, testar e documentar uma API CRUD completa a partir de um arquivo de especificação.

### **Módulo 6: Arquitetura Cloud-Native e SRE**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Projetar aplicações seguindo os princípios do 12-Factor App. Entender a arquitetura de orquestradores de contêineres. Definir, medir e monitorar SLOs para um serviço.
-   **Tópicos Abordados:** 12-Factor App. Padrões de design para microsserviços. Kubernetes (Pods, Services, Deployments, Ingress). Service Mesh (conceitos de Istio/Linkerd). Princípios de SRE (SLIs, SLOs, Error Budgets).
-   **Ferramentas e Tecnologias:** Docker, Kubernetes (Minikube/Kind), Prometheus, Grafana.
-   **Atividade Prática:** Fazer o deploy de um microsserviço em um cluster Kubernetes local, expô-lo via Ingress e definir seu SLO de latência e disponibilidade, monitorando com Prometheus/Grafana.

### **Módulo 7: Arquitetura de Dados e Persistência Poliglota**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Escolher o modelo de banco de dados (SQL/NoSQL) adequado para diferentes casos de uso. Projetar schemas para bancos de documentos e chave-valor. Implementar estratégias de caching para otimizar a performance.
-   **Tópicos Abordados:** Teorema CAP e suas implicações práticas. Análise comparativa: Document (MongoDB), Key-Value (Redis), Column-Family (Cassandra), Graph (Neo4j). Padrões de caching (Cache-Aside, Read-Through, Write-Through).
-   **Ferramentas e Tecnologias:** PostgreSQL, MongoDB, Redis, Neo4j.
-   **Atividade Prática:** Projetar a camada de persistência para uma aplicação de rede social, justificando a escolha de pelo menos 3 tipos diferentes de bancos de dados para diferentes funcionalidades (ex: perfil, feed, conexões).

### **Módulo 8: Padrões de Comunicação e Integração de Sistemas**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Projetar e implementar APIs robustas e evolutivas. Construir sistemas reativos e resilientes com arquitetura orientada a eventos. Garantir idempotência em comunicações assíncronas.
-   **Tópicos Abordados:** REST, gRPC e GraphQL. Padrões de Arquitetura Orientada a Eventos (EDA): Coreografia vs. Orquestração. Padrões de idempotência. Message Queues (RabbitMQ) vs. Logs de Eventos (Apache Kafka).
-   **Ferramentas e Tecnologias:** FastAPI, gRPC, Apollo GraphQL, RabbitMQ, Kafka.
-   **Atividade Prática:** Implementar um sistema com dois microsserviços que se comunicam de forma assíncrona via RabbitMQ para processar um pedido, garantindo que uma re-execução não gere duplicidade.

### **Módulo 9: Arquitetura de Segurança e DevSecOps**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Conduzir uma sessão de modelagem de ameaças. Implementar fluxos de autenticação e autorização seguros. Automatizar a verificação de segurança no pipeline de CI/CD.
-   **Tópicos Abordados:** Modelagem de ameaças com STRIDE. Fluxos OAuth 2.0 e OpenID Connect (OIDC). Segurança de JWTs. Automação com SAST (Static), DAST (Dynamic) e SCA (Composition Analysis). Gestão de segredos com Vault.
-   **Ferramentas e Tecnologias:** OWASP ZAP, Trivy, Gitleaks, HashiCorp Vault.
-   **Atividade Prática:** Identificar e corrigir vulnerabilidades de segurança em uma aplicação de exemplo, integrando as ferramentas de verificação ao pipeline de GitHub Actions.

### **Módulo 10: Qualidade de Software e Estratégias de Teste Arquitetural**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Implementar testes de contrato para garantir a estabilidade entre microsserviços. Executar experimentos de Chaos Engineering para validar a resiliência. Medir e agir sobre métricas de qualidade de código.
-   **Tópicos Abordados:** Testes de Contrato (Consumer-Driven Contracts). Princípios de Chaos Engineering. Métricas de qualidade de código (Complexidade Ciclomática, Maintainability Index). ATAM (Architecture Tradeoff Analysis Method).
-   **Ferramentas e Tecnologias:** Pact, Toxiproxy, Radon, Pytest.
-   **Atividade Prática:** Rodar um "Game Day": injetar latência em um serviço dependente e observar se o sistema se comporta conforme a hipótese de resiliência, mantendo seus SLOs.

### **Módulo 11: Arquitetura de Frontend e Experiência do Usuário**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Projetar Backends for Frontends (BFFs) para otimizar a experiência de diferentes clientes. Avaliar os trade-offs de estratégias de renderização. Implementar observabilidade no frontend.
-   **Tópicos Abordados:** Padrão BFF. SPA vs. SSR vs. SSG. Micro-frontends. Observabilidade de Frontend (Real User Monitoring - RUM, Core Web Vitals).
-   **Ferramentas e Tecnologias:** Next.js, GraphQL, Sentry RUM.
-   **Atividade Prática:** Projetar uma camada de BFF em GraphQL que atenda às necessidades específicas de um cliente mobile e um cliente web, consumindo um conjunto compartilhado de microsserviços backend.

### **Módulo 12: Projeto Final Integrado**
-   **Carga Horária:** 30h
-   **Objetivos de Aprendizagem:** Aplicar de forma integrada os conhecimentos de todos os módulos para conceber, projetar, documentar e implementar parcialmente um sistema distribuído complexo.
-   **Tópicos Abordados:** Consolidação de todos os conceitos do curso.
-   **Ferramentas e Tecnologias:** Todas as ferramentas vistas ao longo dos módulos.
-   **Atividade Prática:** Em grupo, desenvolver um projeto de arquitetura completo para um desafio de negócio proposto. A entrega inclui a documentação (C4, ADRs), o pipeline de CI/CD, a infraestrutura como código e uma implementação parcial (MVP) dos serviços mais críticos, com defesa final para uma banca de instrutores.