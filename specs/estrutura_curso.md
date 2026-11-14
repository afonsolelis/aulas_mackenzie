# Especificação da Estrutura do Repositório de Aulas e Hub de Disciplinas

## Visão Geral

Este documento define a estrutura canônica de pastas e convenções de nomenclatura para o repositório **Hub de Disciplinas MBA em Engenharia de Dados & Cloud**, englobando as disciplinas:
1. **Cloud Computing e SRE — Visão Prática com AWS**
2. **Data Collection and Storage**
3. **Data Visualization**

## Referências obrigatórias

- Este documento define a estrutura, nomenclatura e contratos de conteúdo.
- O alinhamento visual do projeto deve seguir `specs/design_system.md`.

## Estrutura de Diretórios (Hub de Disciplinas)

```text
/
├── index.html                           # Hub Principal (seletor de disciplinas)
├── estudios.html                        # Biblioteca de autoestudo
├── professor.html                       # Perfil do professor
├── assets/
│   ├── styles.css                       # CSS de hubs, páginas home e materiais
│   └── slides.css                       # CSS dos slides HTML nativos
├── pages/
│   ├── home_cloud_sre.html              # Home da disciplina Cloud Computing e SRE
│   ├── home_data_collection.html        # Home da disciplina Data Collection and Storage
│   └── home_data_visualization.html     # Home da disciplina Data Visualization
├── specs/
│   ├── estrutura_curso.md
│   ├── repositorio_de_aulas.md
│   ├── design_system.md
│   └── assets_cloudinary.md
└── aulas/
    ├── cloud_sre/
    │   └── aula_xx_nome_da_aula/
    │       ├── slides/slide_aula_xx_nome_da_aula.html
    │       └── material/material_aula_xx_nome_da_aula.html
    ├── data_collection_and_storage/
    │   └── aula_xx_nome_da_aula/
    │       ├── slides/slide_aula_xx_nome_da_aula.html
    │       ├── material/material_aula_xx_nome_da_aula.html
    │       ├── laboratorio/README.md     # opcional: roteiro e arquivos de apoio
    │       └── simulador/                # opcional: laboratório simulado no navegador (Aulas 06 e 07)
    └── data_visualization/
        └── aula_xx_nome_da_aula/
            ├── slides/slide_aula_xx_nome_da_aula.html
            └── material/material_aula_xx_nome_da_aula.html
```

## Convenções de Nomenclatura

### Pastas

- As pastas de disciplina dentro de `aulas/` usam `snake_case` (ex: `cloud_sre`, `data_collection_and_storage`).
- As pastas de aula dentro de cada disciplina usam `snake_case` e começam com `aula_XX_` (dois dígitos).
- Exemplo: `aulas/cloud_sre/aula_01_fundamentos_de_cloud_para_dados_e_governanca_de_acessos`

### Arquivos

- Páginas home de disciplina: em `pages/home_<nome_da_disciplina>.html`.
- Slides: iniciam com `slide_`.
- Materiais: iniciam com `material_`.
- Todos os arquivos usam `snake_case`.

## Regras de Conteúdo e Navegação

- `index.html` atua como **Hub Central**, apresentando cards destacados para cada disciplina, link para o professor, autoestudo e formulário.
- `pages/home_<disciplina>.html` lista todas as 8 aulas daquela disciplina específica com links para Slide, Material e retorno ao Hub (`index.html`).
- Todos os slides e materiais possuem links explícitos de navegação de volta para a Home da Disciplina e para o Hub Central.

## Dinâmica Obrigatória da Aula

- O horário de cada disciplina é definido em seu cronograma.
- Aulas noturnas ocorrem das `19h00` às `22h00`; aulas de sábado de Data Collection and Storage e Data Visualization ocorrem das `8h30` às `12h10`.
- O bloco inicial da aula é sempre teórico, exceto na Aula 04 de Data Visualization e na Aula 08 de Data Collection and Storage. Na Aula 04 de Data Visualization, a aula é 100% prática e os conceitos aparecem durante a execução guiada no terminal. A Aula 08 de Data Collection and Storage é somente mentoria e entrega do projeto final.
- Em Data Collection and Storage, as Aulas 02 a 07 têm teoria das 8h30 às 10h30 (blocos com exemplo numérico, pausa e pontos-chave), prática guiada em SDD das 10h30 às 11h30, atividade interativa das 11h30 às 12h00 (TBL na Aula 02; quiz na Aula 03) e fechamento das 12h00 às 12h10. A Aula 01 mantém o formato original, e a Aula 08 é só mentoria e entrega. Exceção: a Aula 03 tem teoria das 8h30 às 10h00, construção em etapas das 10h00 às 11h30 (Etapas 00 a 10 até 10h55, Etapas 11 a 15 até 11h30, Etapas 16 a 18 na semana), quiz das 11h30 às 12h00 e fechamento das 12h00 às 12h10. Exceção: a Aula 04 é construção em onze etapas das 8h30 às 11h30, conferência do resultado até 12h00 e fechamento, sem atividade interativa; o TBL dela abre a Aula 05. Exceção: a Aula 05 tem retomada das 8h30 às 8h40, o TBL da Aula 04 das 8h40 às 9h20 (sala `mack-dcs-a04-2026-2`, páginas em `aula_05_.../tbl/`), café das 9h20 às 9h40, seis etapas no ClickHouse com a teoria dentro de cada uma das 9h40 às 12h00 e fechamento das 12h00 às 12h10, sem quiz. Exceção: a Aula 06 abre com uma hora de sistemas distribuídos (bloco 0, das 8h30 às 9h30: falha parcial, detector de falha, relógios físicos e de Lamport, consenso, CAP e PACELC, semânticas de entrega e idempotência, no caso da Rede Tatame) e segue com três blocos teóricos (evento, tecnologias de eventos e Kafka, complex event processing), cada um seguido da estação correspondente num simulador que roda no navegador com estado em `localStorage` (seis estações, cada uma com conceito, prompt CREATE e missão), com intervalo das 10h30 às 10h45 e fechamento das 11h55 às 12h10, sem TBL e sem construção em Codespace; os prompts são lidos em sala e executados na semana, e o pipeline IoT com RabbitMQ e ClickHouse fica como laboratório opcional em `aula_06_.../laboratorio/`. Exceção: a Aula 07 repete o formato da Aula 06, com teoria das 8h30 às 9h50 em três blocos (ingestão em lotes no ClickHouse, views materializadas incrementais, embeddings e busca vetorial para o contexto de uma IA), intervalo das 9h50 às 10h10, seis estações das 10h10 às 12h00 no simulador `simulador_aula_07.html` (contrato, ingestão, views, busca vetorial, contexto para IA e testes) e fechamento das 12h00 às 12h10, sem quiz; o roteiro anterior de Pydantic, VCR e Testcontainers fica como laboratório opcional em `aula_07_.../laboratorio/roteiro_pydantic_e_testes.html`.
- O restante da aula é reservado à prática, conforme os intervalos publicados no cronograma e na agenda.
- O ambiente prático varia por disciplina: Cloud Computing e SRE usa o `AWS Student Lab`; Data Collection and Storage não usa AWS e roda em `GitHub Codespaces` (ou máquina local) com Docker, o agente de código ou a IA de preferência de cada aluno (por exemplo Claude Code, Codex CLI, Gemini CLI, OpenCode, Cursor ou Copilot) e Railway (MinIO, Postgres, RabbitMQ, ClickHouse), com todas as aulas em Spec-Driven Development e prompts no formato CREATE; Data Visualization usa a instância `Metabase` hospedada nas aulas regulares. A Aula 03 usa `GitHub Codespaces`, `D3` e assistência de IA sobre uma API segura; a Aula 04 usa Codespaces e o agente de código de preferência do aluno para transformar arquivos Excel em SQLite e DuckDB e gerar relatórios HTML reproduzíveis; a Aula 05 registra fluxos e divergências no Miro; e a Aula 06 usa o Metabase como fonte de evidência para construir e auditar um protótipo HTML de alta fidelidade com IA agêntica e skills de análise.

---

## Cronogramas de Aulas

### 1. Cloud Computing e SRE — Visão Prática com AWS

| Aula | Data | Tema Principal |
|------|------|----------------|
| 01 | 16/04/2026 | Fundamentos de Cloud para Dados e Governança de Acessos |
| 02 | 23/04/2026 | A Fundação do Data Lake: Armazenamento Escalável (S3 & Athena) |
| 03 | 30/04/2026 | Fontes de Dados: Bancos Relacionais e NoSQL |
| 04 | 07/05/2026 | Ingestão e Processamento Near Real-time (Streaming) |
| 05 | 14/05/2026 | Integração, ETL Serverless e Catálogo de Dados |
| 06 | 21/05/2026 | Data Warehousing na Nuvem de Alta Performance |
| 07 | 28/05/2026 | Data Reliability & SRE aplicados a Pipelines de Dados |
| 08 | 11/06/2026 | Segurança de Dados, FinOps e Projeto Final Integrado |

### 2. Data Collection and Storage (Código: ENLS54627 · Carga Horária: 32h)

**Horário:** Sábados &middot; 8h30 às 12h10

| Aula | Data | Pasta | Tema Principal |
|------|------|-------|----------------|
| 01 | 10/10/2026 | `aula_01_arquitetura_de_software_de_dados_e_spec_driven_development` | Arquitetura de Software de Dados e Spec-Driven Development |
| 02 | 17/10/2026 | `aula_02_tipos_de_storage_e_coleta_em_object_storage_com_minio` | Tipos de Storage e Coleta em Object Storage com MinIO |
| 03 | 24/10/2026 | `aula_03_apis_rest_web_scraping_e_ingestao_no_minio` | APIs REST, Web Scraping e Ingestão no MinIO |
| 04 | 31/10/2026 | `aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse` | Arquitetura de Ingestão com Fila, DuckDB e ClickHouse |
| 05 | 07/11/2026 | `aula_05_modelagem_dimensional_views_e_observabilidade_no_clickhouse` | Modelagem Dimensional, Views e Observabilidade no ClickHouse |
| 06 | 14/11/2026 | `aula_06_eventos_cep_e_coleta_com_kafka_influxdb_e_elasticsearch` | Eventos, CEP e Coleta com Kafka, InfluxDB e Elasticsearch |
| 07 | 28/11/2026 | `aula_07_streaming_com_clickhouse_para_ia_e_testes_integrados` | Streaming com ClickHouse para IA e Testes Integrados |
| 08 | 05/12/2026 | `aula_08_mentoria_e_entrega_do_projeto_final` | Mentoria e Entrega do Projeto Final |

Não há aula em 21/11/2026; a Aula 07 acontece em 28/11/2026.

**Formato:** as aulas de Data Collection and Storage são demonstrações práticas completas, mais tutorial do que slide. O professor constrói o projeto ao vivo; o slide projeta o roteiro (contexto, passos, comandos, gates) e o material é o tutorial completo, com os prompts para o aluno reproduzir. A Aula 08 é somente mentoria e entrega do projeto final, sem bloco teórico e sem conteúdo novo. A Aula 06 é a exceção ao formato de construção ao vivo: a turma percorre um simulador no navegador, e os prompts ficam para a semana.

**Ambiente prático:** a disciplina não usa AWS nem AWS Student Lab. Tudo roda em GitHub Codespaces (ou na máquina do aluno) com Docker, com o agente de código ou a IA de preferência de cada aluno (por exemplo Claude Code, Codex CLI, Gemini CLI, OpenCode, Cursor ou Copilot), e é publicado no Railway (MinIO, Postgres, RabbitMQ, ClickHouse). Todas as aulas são construídas em Spec-Driven Development (persona, objetivos de negócio, especificação, plano, tarefas, implementação e validação ATAM), e todo prompt para o agente segue o formato CREATE. A Aula 06 não exige Codespace nem Docker em sala: o simulador roda no navegador de cada aluno.

**Laboratório:** cada aula de 01 a 07 pode ter a pasta opcional `laboratorio/` ao lado de `slides/` e `material/`, com `README.md` de roteiro e arquivos de apoio (ex.: `docker-compose.yml`, `.env.example`, `AGENTS.md` modelo, `Dockerfile`). As Aulas 06 e 07 têm também a pasta `simulador/`: na Aula 06, `simulador_aula_06.html`, `simulador_aula_06.js` e `medicoes_preparo.py`; na Aula 07, `simulador_aula_07.html`, `simulador_aula_07.js` e `medicoes_preparo.sh`; os estilos de simuladores ficam em `assets/simulador.css`.

### 3. Data Visualization (Disciplina 02 · Carga Horária: 32 h/a)

**Horário:** Sábados &middot; 8h30 às 12h10

| Aula | Data | Tema Principal |
|------|------|----------------|
| 01 | 15/08/2026 | Data Discovery com Metabase |
| 02 | 22/08/2026 | Arquitetura de BI e Modelagem Dimensional com Olist |
| 03 | 29/08/2026 | Visualização de Dados Numéricos |
| 04 | 05/09/2026 | Do Excel ao OLAP com SQLite, DuckDB e IA |
| 05 | 12/09/2026 | Modelo Mental do Usuário e Ciclo de Vida do Dado |
| 06 | 19/09/2026 | Heurísticas e Vieses |
| 07 | 26/09/2026 | Do Protótipo ao Painel com Supabase |
| 08 | 03/10/2026 | Acompanhamento do Projeto Final |
