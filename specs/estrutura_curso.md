# Especificação da Estrutura do Repositório de Aulas e Hub de Disciplinas

## Visão Geral

Este documento define a estrutura canônica de pastas e convenções de nomenclatura para o repositório **Hub de Disciplinas MBA em Engenharia de Dados & Cloud**, englobando as disciplinas:
1. **Cloud Computing e SRE — Visão Prática com AWS**
2. **Data Collection and Storage**
3. **Data Visualization**
4. **Big Data Processing**
5. **Hands-on na Aplicação de IA nos Negócios** (curso de Inteligência Artificial para Negócios Digitais)

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
│   ├── home_data_visualization.html     # Home da disciplina Data Visualization
│   ├── home_big_data_processing.html    # Home da disciplina Big Data Processing
│   └── home_hands_on_ia_nos_negocios.html   # Home da disciplina Hands-on na Aplicação de IA nos Negócios
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
    ├── data_visualization/
    │   └── aula_xx_nome_da_aula/
    │       ├── slides/slide_aula_xx_nome_da_aula.html
    │       └── material/material_aula_xx_nome_da_aula.html
    ├── big_data_processing/
    │   └── aula_xx_nome_da_aula/
    │       ├── slides/slide_aula_xx_nome_da_aula.html
    │       └── material/material_aula_xx_nome_da_aula.html
    └── hands_on_ia_nos_negocios/
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
- `pages/home_<disciplina>.html` lista todas as aulas daquela disciplina específica (8 na maioria; 6 em Hands-on na Aplicação de IA nos Negócios) com links para Slide, Material e retorno ao Hub (`index.html`).
- Todos os slides e materiais possuem links explícitos de navegação de volta para a Home da Disciplina e para o Hub Central.

## Dinâmica Obrigatória da Aula

- O horário de cada disciplina é definido em seu cronograma.
- Aulas noturnas ocorrem das `19h00` às `22h00`; aulas de sábado de Data Collection and Storage, Data Visualization e Hands-on na Aplicação de IA nos Negócios ocorrem das `8h30` às `12h10`.
- O bloco inicial da aula é sempre teórico, exceto na Aula 04 de Data Visualization e na Aula 08 de Data Collection and Storage. Na Aula 04 de Data Visualization, a aula é 100% prática e os conceitos aparecem durante a execução guiada no terminal. A Aula 08 de Data Collection and Storage é somente mentoria e entrega do projeto final.
- Em Data Collection and Storage, as Aulas 02 a 07 têm teoria das 8h30 às 10h30 (blocos com exemplo numérico, pausa e pontos-chave), prática guiada em SDD das 10h30 às 11h30, atividade interativa das 11h30 às 12h00 (TBL na Aula 02; quiz na Aula 03) e fechamento das 12h00 às 12h10. A Aula 01 mantém o formato original, e a Aula 08 é só mentoria e entrega. Exceção: a Aula 03 tem teoria das 8h30 às 10h00, construção em etapas das 10h00 às 11h30 (Etapas 00 a 10 até 10h55, Etapas 11 a 15 até 11h30, Etapas 16 a 18 na semana), quiz das 11h30 às 12h00 e fechamento das 12h00 às 12h10. Exceção: a Aula 04 é construção em onze etapas das 8h30 às 11h30, conferência do resultado até 12h00 e fechamento, sem atividade interativa; o TBL dela abre a Aula 05. Exceção: a Aula 05 tem retomada das 8h30 às 8h40, o TBL da Aula 04 das 8h40 às 9h20 (sala `mack-dcs-a04-2026-2`, páginas em `aula_05_.../tbl/`), café das 9h20 às 9h40, seis etapas no ClickHouse com a teoria dentro de cada uma das 9h40 às 12h00 e fechamento das 12h00 às 12h10, sem quiz. Exceção: a Aula 06 abre com uma hora de sistemas distribuídos (bloco 0, das 8h30 às 9h30: falha parcial, detector de falha, relógios físicos e de Lamport, consenso, CAP e PACELC, semânticas de entrega e idempotência, no caso da Rede Tatame) e segue com três blocos teóricos (evento, tecnologias de eventos e Kafka, complex event processing), cada um seguido da estação correspondente num simulador que roda no navegador com estado em `localStorage` (seis estações, cada uma com conceito, prompt CREATE e missão), com intervalo das 10h30 às 10h45 e fechamento das 11h55 às 12h10, sem TBL e sem construção em Codespace; os prompts são lidos em sala e executados na semana, e o pipeline IoT com RabbitMQ e ClickHouse fica como laboratório opcional em `aula_06_.../laboratorio/`. Exceção: a Aula 07 trata de qualidade e testes de dados (condensa a disciplina de Qualidade de Software do professor e a aplica a dados com defeito) e alterna cinco blocos teóricos curtos com seis estações de uma bancada embutida nos slides, que roda pytest de verdade no navegador via Pyodide 0.27.7 (`bancada/bancada_aula_07.html`, `bancada_aula_07.js`, motor `bancada.py` e exercícios em `bancada/exercicios/` com `manifesto.json` de mutantes; gabaritos em `bancada/gabarito/`): 8h30 abertura e estação 0 (aquecimento), 8h45 bloco 1 (qualidade de dados pela ISO/IEC 25012 e as quatro camadas de teste), 9h15 bloco 2 (caixa preta no contrato: partição, valor-limite, tabela de decisão e teste de mutação), 9h35 estação 1 (contrato do sensor), 10h00 intervalo de 20 minutos com cronômetro no slide, 10h20 bloco 3 (TDD, Decimal e relógio injetado), 10h40 estações 2 e 3 (limpeza dos livros e PTAX vigente), 11h05 bloco 4 (dublês, cassete VCR e demonstração ao vivo de Testcontainers), 11h20 estação 4 (coletor da PTAX), 11h35 bloco 5 (testes sobre o dado e gate), 11h45 estação 5 (lote bronze, silver e gold) e fechamento das 12h00 às 12h10, sem quiz e sem Codespace em sala; os dados das estações são reais (books.toscrape.com e PTAX de 13 a 24/11/2026) com defeitos plantados; a evidência exportada vai para `aula_07_testes/evidencia_bancada.md`, os seis prompts CREATE ficam para a semana e o roteiro de Pydantic, VCR e Testcontainers fica como laboratório da semana em `aula_07_.../laboratorio/roteiro_pydantic_e_testes.html`.
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
| 07 | 28/11/2026 | `aula_07_qualidade_e_testes_de_dados_com_pytest` | Qualidade e Testes de Dados com pytest |
| 08 | 05/12/2026 | `aula_08_mentoria_e_entrega_do_projeto_final` | Mentoria e Entrega do Projeto Final |

Não há aula em 21/11/2026; a Aula 07 acontece em 28/11/2026.

**Formato:** as aulas de Data Collection and Storage são demonstrações práticas completas, mais tutorial do que slide. O professor constrói o projeto ao vivo; o slide projeta o roteiro (contexto, passos, comandos, gates) e o material é o tutorial completo, com os prompts para o aluno reproduzir. A Aula 08 é somente mentoria e entrega do projeto final, sem bloco teórico e sem conteúdo novo. As Aulas 06 e 07 são as exceções ao formato de construção ao vivo: na Aula 06 a turma percorre um simulador no navegador; na Aula 07, uma bancada de testes embutida nos slides. Nas duas, os prompts ficam para a semana.

**Ambiente prático:** a disciplina não usa AWS nem AWS Student Lab. Tudo roda em GitHub Codespaces (ou na máquina do aluno) com Docker, com o agente de código ou a IA de preferência de cada aluno (por exemplo Claude Code, Codex CLI, Gemini CLI, OpenCode, Cursor ou Copilot), e é publicado no Railway (MinIO, Postgres, RabbitMQ, ClickHouse). Todas as aulas são construídas em Spec-Driven Development (persona, objetivos de negócio, especificação, plano, tarefas, implementação e validação ATAM), e todo prompt para o agente segue o formato CREATE. As Aulas 06 e 07 não exigem Codespace nem Docker em sala: o simulador e a bancada rodam no navegador de cada aluno.

**Laboratório:** cada aula de 01 a 07 pode ter a pasta opcional `laboratorio/` ao lado de `slides/` e `material/`, com `README.md` de roteiro e arquivos de apoio (ex.: `docker-compose.yml`, `.env.example`, `AGENTS.md` modelo, `Dockerfile`). A Aula 06 tem também a pasta `simulador/` (`simulador_aula_06.html`, `simulador_aula_06.js` e `medicoes_preparo.py`), e a Aula 07 tem a pasta `bancada/` (laboratório de testes com Pyodide, descrito acima); os estilos de simuladores e da bancada ficam em `assets/simulador.css`.

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

### 4. Big Data Processing (Código: ENLS54628 · Turma 0931.01J · Carga Horária: 32h)

**Horário:** Quartas-feiras &middot; 19h00 às 22h40 &middot; 100% online ao vivo

| Aula | Data | Pasta | Tema Principal |
|------|------|-------|----------------|
| 01 | 24/02/2027 | `aula_01_processamento_distribuido_do_mapreduce_ao_spark` | Processamento Distribuído: do MapReduce ao Spark |
| 02 | 03/03/2027 | `aula_02_arquitetura_do_spark_e_dataframes` | Arquitetura do Spark e DataFrames |
| 03 | 10/03/2027 | `aula_03_spark_sql_parquet_e_particionamento` | Spark SQL, Parquet e Particionamento |
| 04 | 17/03/2027 | `aula_04_otimizacao_de_jobs_spark` | Otimização de Jobs Spark |
| 05 | 24/03/2027 | `aula_05_lakehouse_com_delta_lake_e_iceberg` | Lakehouse com Delta Lake e Iceberg |
| 06 | 31/03/2027 | `aula_06_structured_streaming_com_kafka` | Structured Streaming com Kafka |
| 07 | 07/04/2027 | `aula_07_orquestracao_e_custo_do_processamento_em_escala` | Orquestração e Custo do Processamento em Escala |
| 08 | 14/04/2027 | `aula_08_mentoria_e_entrega_do_projeto_final` | Mentoria e Entrega do Projeto Final |

**Agenda padrão:** abertura das 19h00 às 19h10, teoria das 19h10 às 20h40, intervalo das 20h40 às 21h00, prática guiada das 21h00 às 22h20 e fechamento das 22h20 às 22h40. A Aula 08 é somente mentoria e entrega do projeto final.

**Ambiente prático:** tudo roda no computador do aluno (Python, Java e PySpark instalados localmente), sem AWS e sem serviço de nuvem. A capa dos slides e a home da disciplina usam o ano 2027.

**Situação:** esqueleto criado em 25/11/2026 com temas propostos pelo professor; slides com capa, agenda e placeholder, e materiais com as seções de cada tópico ainda em construção.

### 5. Hands-on na Aplicação de IA nos Negócios (Código: ENLS20108 · Turma 1386.000.01B · Carga Horária: 24h)

**Curso:** Inteligência Artificial para Negócios Digitais (unidade FCI, turma de ago/25, Multicompany presencial, turno B). É a única disciplina do hub fora do MBA em Engenharia de Dados.

**Horário:** Sábados &middot; 8h30 às 12h10 &middot; presencial

| Aula | Data | Pasta | Tema Principal |
|------|------|-------|----------------|
| 01 | 20/02/2027 | `aula_01_mapeamento_de_oportunidades_de_ia_no_negocio` | Mapeamento de Oportunidades de IA no Negócio |
| 02 | 27/02/2027 | `aula_02_engenharia_de_prompt_e_de_contexto_para_tarefas_de_negocio` | Engenharia de Prompt e de Contexto para Tarefas de Negócio |
| 03 | 06/03/2027 | `aula_03_ia_sobre_os_dados_da_empresa_com_rag` | IA sobre os Dados da Empresa com RAG |
| 04 | 13/03/2027 | `aula_04_agentes_e_automacao_de_processos` | Agentes e Automação de Processos |
| 05 | 20/03/2027 | `aula_05_avaliacao_custo_e_governanca_de_solucoes_de_ia` | Avaliação, Custo e Governança de Soluções de IA |
| 06 | 03/04/2027 | `aula_06_mentoria_e_entrega_do_projeto_final` | Mentoria e Entrega do Projeto Final |

Não há aula em 27/03/2027; a Aula 06 acontece em 03/04/2027.

**Agenda padrão:** abertura das 8h30 às 8h40, teoria das 8h40 às 10h00, intervalo das 10h00 às 10h20, prática guiada das 10h20 às 12h00 e fechamento das 12h00 às 12h10. A Aula 06 é somente mentoria e entrega do projeto final.

**Ambiente prático:** aula presencial, com prática no computador do aluno e na IA de preferência de cada um; nenhuma aula exige ferramenta específica. Cada aluno escolhe na Aula 01 um caso de uso do próprio trabalho e o leva até o projeto final. A pasta da disciplina é `aulas/hands_on_ia_nos_negocios/`. A capa dos slides e a home da disciplina usam o ano 2027.

**Situação:** esqueleto criado em 28/11/2026 com temas propostos como ponto de partida, a confirmar pelo professor; o horário de término (12h10) foi inferido do padrão das turmas de sábado, porque a grade recebida estava cortada. Slides com capa, agenda e placeholder, e materiais com as seções de cada tópico ainda em construção.
