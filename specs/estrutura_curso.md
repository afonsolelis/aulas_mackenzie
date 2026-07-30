# Especificação da Estrutura do Repositório de Aulas e Hub de Disciplinas

## Visão Geral

Este documento define a estrutura canônica de pastas e convenções de nomenclatura para o repositório **Hub de Disciplinas MBA em Engenharia de Dados & Cloud**, englobando as disciplinas:
1. **Cloud Computing e SRE — Visão Prática com AWS**
2. **Data Collection and Storage**

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
│   └── home_data_collection.html        # Home da disciplina Data Collection and Storage
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
    └── data_collection_and_storage/
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

- Toda aula inicia às `19h00` e encerra às `22h00`.
- O bloco inicial da aula é sempre teórico.
- As duas últimas horas (20h00 às 22h00) são reservadas para a prática.
- Toda a prática ocorre com o ambiente `AWS Student`.

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

| Aula | Data | Tema Principal |
|------|------|----------------|
| 01 | 10/10/2026 | Introdução à Coleta e Armazenamento de Dados na Nuvem |
| 02 | 17/10/2026 | Ingestão de Dados com APIs REST e Web Scraping Escalável |
| 03 | 24/10/2026 | Coleta e Armazenamento de Dados Não Estruturados e Semi-estruturados |
| 04 | 31/10/2026 | Bancos de Dados Relacionais e Captura de Mudanças (CDC) |
| 05 | 07/11/2026 | Armazenamento NoSQL e Chave-Valor de Alta Vazão (DynamoDB) |
| 06 | 14/11/2026 | Ingestão em Tempo Real e Streaming de Eventos (Kinesis/Kafka) |
| 07 | 28/11/2026 | Qualidade de Dados, Contratos e Validação de Ingestão |
| 08 | 05/12/2026 | Arquitetura Integrada de Coleta, Storage e Projeto Final |

