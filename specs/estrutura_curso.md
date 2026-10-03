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
    │       └── laboratorio/README.md     # opcional: roteiro e arquivos de apoio
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
- Em Data Collection and Storage o bloco teórico é curto (cerca de 8h30 às 9h30) e o resto da aula é demonstração prática guiada, construída ao vivo pelo professor.
- O restante da aula é reservado à prática, conforme os intervalos publicados no cronograma e na agenda.
- O ambiente prático varia por disciplina: Cloud Computing e SRE usa o `AWS Student Lab`; Data Collection and Storage não usa AWS e roda em `GitHub Codespaces` (ou máquina local) com Docker, OpenCode + OpenRouter (modelo `openrouter/free`) e Railway (MinIO, Postgres, RabbitMQ, ClickHouse), com todas as aulas em Spec-Driven Development e prompts no formato CREATE; Data Visualization usa a instância `Metabase` hospedada nas aulas regulares. A Aula 03 usa `GitHub Codespaces`, `D3` e assistência de IA sobre uma API segura; a Aula 04 usa Codespaces e OpenCode Zen para transformar arquivos Excel em SQLite e DuckDB e gerar relatórios HTML reproduzíveis; a Aula 05 registra fluxos e divergências no Miro; e a Aula 06 usa o Metabase como fonte de evidência para construir e auditar um protótipo HTML de alta fidelidade com IA agêntica e skills de análise.

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
| 04 | 31/10/2026 | `aula_04_dados_semiestruturados_parquet_duckdb_e_lakehouse` | Dados Semiestruturados, Parquet, DuckDB e Lakehouse |
| 05 | 07/11/2026 | `aula_05_modelagem_de_dados_relacional_e_dimensional` | Modelagem de Dados Relacional e Dimensional |
| 06 | 14/11/2026 | `aula_06_streaming_com_rabbitmq_e_clickhouse` | Streaming com RabbitMQ e ClickHouse |
| 07 | 28/11/2026 | `aula_07_validacao_com_pydantic_e_testes_integrados` | Validação com Pydantic e Testes Integrados |
| 08 | 05/12/2026 | `aula_08_mentoria_e_entrega_do_projeto_final` | Mentoria e Entrega do Projeto Final |

Não há aula em 21/11/2026; a Aula 07 acontece em 28/11/2026.

**Formato:** as aulas de Data Collection and Storage são demonstrações práticas completas, mais tutorial do que slide. O professor constrói o projeto ao vivo; o slide projeta o roteiro (contexto, passos, comandos, gates) e o material é o tutorial completo, com os prompts para o aluno reproduzir. A Aula 08 é somente mentoria e entrega do projeto final, sem bloco teórico e sem conteúdo novo.

**Ambiente prático:** a disciplina não usa AWS nem AWS Student Lab. Tudo roda em GitHub Codespaces (ou na máquina do aluno) com Docker, com o agente OpenCode autenticado na OpenRouter (modelo `openrouter/free`), e é publicado no Railway (MinIO, Postgres, RabbitMQ, ClickHouse). Todas as aulas são construídas em Spec-Driven Development (persona, objetivos de negócio, especificação, plano, tarefas, implementação e validação ATAM), e todo prompt para o agente segue o formato CREATE.

**Laboratório:** cada aula de 01 a 07 pode ter a pasta opcional `laboratorio/` ao lado de `slides/` e `material/`, com `README.md` de roteiro e arquivos de apoio (ex.: `docker-compose.yml`, `.env.example`, `AGENTS.md` modelo, `Dockerfile`).

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
