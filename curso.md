# Proposta de Minicurso: Modelagem, SRE e Arquitetura de Software com IA

## 1. Objetivo

Este documento descreve a proposta para um novo minicurso focado em **Modelagem, SRE e Arquitetura de Software utilizando Inteligência Artificial**. O curso será estruturado em 8 aulas, seguindo o mesmo padrão de organização, nomenclatura e profundidade técnica do curso existente de "Cloud Computing e SRA".

O objetivo é capacitar os alunos a utilizar ferramentas de IA como copilotos no ciclo de vida de desenvolvimento de software, desde a concepção e modelagem até a operação e confiabilidade em produção.

## 2. Estrutura e Convenções

O curso seguirá rigorosamente as convenções estabelecidas nos documentos `specs/estrutura_curso.md` e `specs/repositorio_de_aulas.md`. Isso inclui:

-   **Nomenclatura de Pastas:** `aulas/aula_XX_tema_resumido` em `snake_case`.
-   **Estrutura de Arquivos:** Cada aula terá as subpastas `slides/` e `material/`, contendo os respectivos arquivos HTML.
-   **Navegação:** Todos os slides e materiais terão links de navegação para o `index.html` e para seus pares (slide aponta para material e vice-versa).
-   **Design System:** O visual seguirá as diretrizes de `specs/design_system.md`, reutilizando o CSS global de `assets/styles.css`.

## 3. Módulos Propostos

A seguir, a proposta para as 8 aulas do minicurso:

---

### **Aula 01: Introdução à Engenharia de Software Assistida por IA**

-   **Pasta:** `aula_01_introducao_a_engenharia_de_software_assistida_por_ia`
-   **Conteúdo dos Slides:**
    -   Apresentação do curso e da jornada de 8 semanas.
    -   O papel do engenheiro de software em 2026: de codificador a orquestrador de IAs.
    -   Panorama de ferramentas: code assistants (Copilot, Gemini), agentes de modelagem e geradores de teste.
    -   O conceito de "Spec-Driven Development" (SDD): a especificação como prompt.
-   **Conteúdo do Material:**
    -   Aprofundamento sobre a história da IA no desenvolvimento de software.
    -   Glossário de termos (LLM, prompt engineering, RAG, agentes).
    -   **Prática:** Setup do ambiente de desenvolvimento no Codespaces com o agente de código de preferência do aluno (por exemplo Claude Code, Codex CLI, Gemini CLI ou OpenCode).

---

### **Aula 02: Modelagem de Requisitos e Domínio com IA**

-   **Pasta:** `aula_02_modelagem_de_requisitos_e_dominio_com_ia`
-   **Conteúdo dos Slides:**
    -   Técnicas para extrair requisitos funcionais e não funcionais de briefings de produto usando IA.
    -   Uso de IAs para gerar User Stories, casos de uso e critérios de aceitação (Gherkin).
    -   Modelagem de domínio: gerando diagramas de entidade-relacionamento (ER) e de classes a partir de descrições em linguagem natural.
-   **Conteúdo do Material:**
    -   Estudo de caso: aplicando as técnicas em um problema de e-commerce.
    -   **Prática:** Usar a IA para gerar o arquivo `spec/00_problem.md` e os primeiros diagramas em Mermaid para o projeto do curso.

---

### **Aula 03: Arquitetura de Software e Padrões de Projeto com IA**

-   **Pasta:** `aula_03_arquitetura_de_software_e_padroes_de_projeto_com_ia`
-   **Conteúdo dos Slides:**
    -   A IA como um "consultor de arquitetura": prós e contras de monolitos, microsserviços, arquitetura hexagonal.
    -   Gerando diagramas de componentes e de sequência com IA.
    -   Identificando e aplicando padrões de projeto (Design Patterns) com assistência de IA.
-   **Conteúdo do Material:**
    -   Análise comparativa de arquiteturas geradas por diferentes IAs para o mesmo problema.
    -   **Prática:** Gerar o `documents/03_architecture.md` com viewpoints RM-ODP e diagramas Mermaid.

---

### **Aula 04: Geração de Código, Testes e Documentação com "aiox"**

-   **Pasta:** `aula_04_geracao_de_codigo_testes_e_documentacao_com_aiox`
-   **Conteúdo dos Slides:**
    -   O conceito de "aiox": uma abstração para "AI Orchestration & eXecution".
    -   Geração de código boilerplate (APIs REST, clientes de banco de dados) a partir da especificação.
    -   Geração de testes unitários e de integração.
    -   Geração de documentação de API (OpenAPI/Swagger) a partir do código.
-   **Conteúdo do Material:**
    -   Frameworks de orquestração de agentes (ex: CrewAI, AutoGen).
    -   **Prática:** Usar o `aiox` (ou um script de orquestração) para gerar o esqueleto da aplicação do projeto.

---

### **Aula 05: Fundamentos de SRE e Observabilidade para Sistemas de IA**

-   **Pasta:** `aula_05_fundamentos_de_sre_e_observabilidade_para_sistemas_de_ia`
-   **Conteúdo dos Slides:**
    -   Introdução ao SRE: SLI, SLO, SLA e Error Budgets.
    -   Os três pilares da observabilidade: logs, métricas e traces.
    -   Como instrumentar código gerado por IA para ser observável.
-   **Conteúdo do Material:**
    -   Padrões de logging estruturado (JSON, EMF).
    -   **Prática:** Adicionar logging e métricas customizadas (CloudWatch) na aplicação gerada.

---

### **Aula 06: Análise de Causa Raiz e Remediação Assistida por IA**

-   **Pasta:** `aula_06_analise_de_causa_raiz_e_remediacao_assistida_por_ia`
-   **Conteúdo dos Slides:**
    -   Usando IAs para analisar logs de erro e sugerir causas prováveis.
    -   Gerando runbooks automatizados (SSM Documents) a partir de descrições de incidentes.
    -   O conceito de "closed loop": alarm &rarr; EventBridge &rarr; SSM.
-   **Conteúdo do Material:**
    -   Estudo de caso de um postmortem blameless.
    -   **Prática:** Simular uma falha, usar a IA para analisar os logs e gerar um runbook de remediação.

---

### **Aula 07: Chaos Engineering e Validação de Resiliência**

-   **Pasta:** `aula_07_chaos_engineering_e_validacao_de_resiliencia`
-   **Conteúdo dos Slides:**
    -   Princípios de Chaos Engineering.
    -   Usando IA para projetar experimentos de caos: hipótese, método, métricas.
    -   Ferramentas: AWS FIS (conceito) e alternativas open-source (Toxiproxy).
-   **Conteúdo do Material:**
    -   Anatomia de um Game Day.
    -   **Prática:** Executar um experimento de caos (ex: injetar latência na rede) e observar a reação do sistema.

---

### **Aula 08: Projeto Final - Construindo uma Solução E2E com IA**

-   **Pasta:** `aula_08_projeto_final_construindo_uma_solucao_e2e_com_ia`
-   **Conteúdo dos Slides:**
    -   Recapitulação da jornada das 8 aulas.
    -   Apresentação do desafio final: construir um pequeno serviço (ex: uma API de recomendação simples) do zero, usando a squad de IAs.
-   **Conteúdo do Material:**
    -   Roteiro detalhado do projeto.
    -   **Prática:** 3 horas de execução em sala para entregar o projeto, com apresentação de 3 minutos ao final.

## 4. O Projeto Prático ("aiox")

A menção a "codar uma solução com IA e aiox" será interpretada como o fio condutor do curso. "aiox" será tratado como um conceito de **AI Orchestration & eXecution**, onde uma "squad" de agentes de IA (cada um com um papel: arquiteto, dev, tester, etc.) é orquestrada para construir a solução.

O projeto será a construção de uma **API REST para um sistema de gerenciamento de tarefas (To-Do List)**, com as seguintes características:

-   **Backend:** Python com FastAPI ou Node.js com Express.
-   **Banco de dados:** PostgreSQL no Amazon RDS.
-   **Infraestrutura:** Provisionada via CloudFormation gerado por IA.
-   **CI/CD:** Pipeline no GitHub Actions para testes e deploy.
-   **Observabilidade:** Logs e métricas no CloudWatch.

Cada aula contribuirá com uma parte do projeto, culminando na entrega funcional na Aula 08.

## 5. Próximos Passos

Se esta proposta for aprovada, os próximos passos serão:

1.  **Criar a estrutura de pastas** para as 8 aulas propostas.
2.  **Gerar os arquivos HTML vazios** (`slide_aula_XX.html` e `material_aula_XX.html`) para cada aula, já com a estrutura básica e os links de navegação.
3.  **Atualizar o `index.html`** para listar as novas aulas.
4.  Começar a desenvolver o conteúdo da **Aula 01**.
