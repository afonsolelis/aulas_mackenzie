# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Repository

Static HTML course material repository for **CLOUD COMPUTING E SRA - VISÃO PRÁTICA COM AWS** (MBA em Engenharia de Dados), covering 8 lectures from April 16 to June 11, 2026 (19:00–22:00). No build steps, package managers, or test suites.

Authoritative specs live in `specs/` — always consult them before creating or editing content.

## Specs & Agents

There are three spec files, each backed by a dedicated sub-agent:

| Spec | Arquivo | Agente |
|------|---------|--------|
| Estrutura do curso (cronograma, pastas) | `specs/estrutura_curso.md` | `.claude/agents/estrutura-curso.md` |
| Repositório de aulas (conteúdo, navegação) | `specs/repositorio_de_aulas.md` | `.claude/agents/repositorio-aulas.md` |
| Design system (visual, tipografia, componentes) | `specs/design_system.md` | `.claude/agents/design-system.md` |

Use the appropriate sub-agent when creating or reviewing slides, materials, or visual design.

## Directory Structure

```
/
├── index.html                          # Landing page listing all lectures
├── assets/styles.css                   # Shared CSS (use before creating new classes)
├── specs/                              # Authoritative specs
└── aulas/
    └── aula_xx_nome_da_aula/
        ├── slides/slide_aula_xx_nome_da_aula.html
        └── material/material_aula_xx_nome_da_aula.html
```

## Naming Conventions

- All folder and file names: `snake_case`, no spaces, hyphens, or special characters
- Lecture folders: `aula_xx_nome_da_aula/` (two-digit number)
- Slide files: `slide_aula_xx_nome_da_aula.html`
- Material files: `material_aula_xx_nome_da_aula.html`

## Lecture Schedule

| Aula | Data | Pasta |
|------|------|-------|
| 1 | 16/04/2026 | `aula_01_fundamentos_de_cloud_para_dados_e_governanca_de_acessos` |
| 2 | 23/04/2026 | `aula_02_a_fundacao_do_data_lake_armazenamento_escalavel_s3_e_athena` |
| 3 | 30/04/2026 | `aula_03_fontes_de_dados_bancos_relacionais_e_nosql` |
| 4 | 07/05/2026 | `aula_04_ingestao_e_processamento_near_real_time_streaming` |
| 5 | 14/05/2026 | `aula_05_integracao_etl_serverless_e_catalogo_de_dados` |
| 6 | 21/05/2026 | `aula_06_data_warehousing_na_nuvem_de_alta_performance` |
| 7 | 28/05/2026 | `aula_07_data_reliability_e_sre_aplicados_a_pipelines_de_dados` |
| 8 | 11/06/2026 | `aula_08_seguranca_de_dados_finops_e_projeto_final_integrado` |

## Slide Rules (summary)

- Must use the **HTML-native slide system** (`assets/slides.css`)
- Slide 1: capa with lecture title + year 2026
- Slide 2: agenda
- Slide 3: initial placeholder
- Must include explicit link to the corresponding material file
- Must include explicit link back to `index.html`

## Material Rules (summary)

- Must mirror the same topics as the corresponding slide
- Must deepen each topic with longer, descriptive, conceptual text
- Must include step-by-step instructions for labs/practice sections
- Must end with guidance for the in-class hands-on activity (Codespace, AI tools, AWS Student Lab). Course is 100% practical — no written exercises section.
- Must include explicit link to the corresponding slide
- Must include explicit link back to `index.html`

## Visual Rules (summary)

- White/near-white background; black/near-black text; high contrast
- Square-leaning composition; avoid excessively rounded corners
- Consistent typography, spacing, and card patterns across all pages
- Responsive layout (desktop and mobile)
- Shared styles go in `assets/styles.css` — check existing classes before creating new ones

## Escrita (obrigatório)

Todo texto destinado ao aluno (slides, materiais, páginas, quizzes, atividades) segue as skills `escrita-afonso` e `humanizacao`, em `.claude/skills/`. Aplique-as já na redação, e não só numa revisão posterior. Evite linguagem de rede social: título em forma de aforismo, travessão como conector, "não é X, é Y", negrito na prosa, setas decorativas e frases de efeito no fechamento. Títulos de slide devem ser descritivos e curtos, cabendo em uma linha na projeção. Preserve números, fatos, código e prompts.
