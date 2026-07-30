# GEMINI.md - Diretrizes para o Gemini

Este arquivo fornece as diretrizes para o Gemini ao interagir com o repositório **Hub de Disciplinas MBA em Engenharia de Dados & Cloud** (Universidade Presbiteriana Mackenzie).

## Visão Geral do Repositório

Trata-se de um repositório web estático atuando como **Hub de Disciplinas** contendo o material das disciplinas:
1. **Cloud Computing e SRE — Visão Prática com AWS**
2. **Data Collection and Storage**

Não existem processos de build ou gerenciadores de dependências corporativos. O repositório usa HTML estático e CSS compartilhado (`assets/styles.css` e `assets/slides.css`).

### Especificações Autorizativas

Sempre consulte a pasta `specs/` como fonte da verdade:
1. `specs/estrutura_curso.md`: Define a estrutura de pastas do Hub e convenções de nomenclatura (`snake_case`, prefixo `aula_`).
2. `specs/repositorio_de_aulas.md`: Define as regras de conteúdo e navegação entre Hub, homes das disciplinas, slides e materiais.
3. `specs/design_system.md`: Define as regras visuais "editorial-técnico" (off-white, preto, tipografia Inter + JetBrains Mono, raios de 4px).

## Estrutura do Projeto

```text
/
├── index.html                          # Hub Central (seletor de disciplinas)
├── estudios.html                       # Biblioteca de autoestudo
├── professor.html                      # Perfil do professor
├── pages/
│   ├── home_cloud_sre.html             # Home da disciplina Cloud Computing e SRE
│   └── home_data_collection.html       # Home da disciplina Data Collection and Storage
├── assets/
│   ├── styles.css                      # CSS global de hub, homes e materiais
│   └── slides.css                      # CSS dos slides HTML nativos
├── specs/                              # Especificações (fonte da verdade)
└── aulas/
    ├── cloud_sre/                      # Aulas de Cloud Computing e SRE
    └── data_collection_and_storage/    # Aulas de Data Collection and Storage
```

## Dinâmica Obrigatória da Aula

- **Horário**: Inicia às 19h00, encerra às 22h00.
- **Teoria**: O bloco inicial deve ser sempre exclusivamente teórico.
- **Prática**: As duas últimas horas (20h00 às 22h00) são sempre reservadas para a prática.
- **Ambiente**: Todo hands-on e prática OBRIGATORIAMENTE utilizará o ambiente `AWS Student`.
- Essa dinâmica deve estar explícita em slides, materiais de aula e cronogramas.

## Regras de Conteúdo e Navegação

**Slides:**
- OBRIGATÓRIO o uso do `reveal.js`.
- Capa com título e ano `2026`.
- Slide 2: agenda. Slide 3: placeholder de conteúdo.
- Links explícitos obrigatórios: P/ `material_aula_XX.html` e P/ `index.html`.

**Materiais de Apoio:**
- Extensão, detalhamento e reflexão do conteúdo abordado no slide correspondente.
- Passo a passo completo para os laboratórios/hands-on da AWS.
- Fechamento com orientação para a atividade hands-on em sala (curso 100% prático, sem exercícios escritos).
- Links explícitos obrigatórios: P/ `slide_aula_XX.html` e P/ `index.html`.

## Regras Visuais (Design System)

- **Cores**: Fundo branco ou muito claro, texto preto ou quase preto. Evite baixo contraste.
- **Formas**: Composição visual mais "quadrada", evite bordas excessivamente arredondadas.
- **Tipografia**: Legível, limpa e técnica, refletindo uma disciplina de Engenharia de Dados.
- **Consistência**: Nenhuma nova página deve introduzir estilos desconexos. Use as classes do `assets/styles.css`.

## Agentes de Atuação (Como o Gemini deve agir)

Dependendo do seu contexto de atuação, adote um dos perfis abaixo para gerar a saída perfeita:

1. **Agente de Estrutura**: Ao criar/renomear pastas e arquivos, garanta o formato `aula_XX_tema_resumido`, valide o `snake_case` e a presença das subpastas `slides/` e `material/`. Consulte `specs/estrutura_curso.md`.
2. **Agente de Conteúdo**: Ao construir slides e materiais, garanta a profundidade analítica de Engenharia de Dados, crie laboratórios claros com um passo a passo objetivo e mantenha sempre os links cruzados de navegação. Consulte `specs/repositorio_de_aulas.md`.
3. **Agente de Design**: Ao escrever HTML/CSS, utilize os padrões arquiteturais de design estabelecidos. Garanta responsividade básica para Desktop e Mobile, e a reutilização do `assets/styles.css`. Consulte `specs/design_system.md`.

## Cronograma (Abril-Junho 2026)
1. `aula_01_fundamentos_de_cloud_para_dados_e_governanca_de_acessos` (16/04/2026)
2. `aula_02_a_fundacao_do_data_lake_armazenamento_escalavel_s3_e_athena` (23/04/2026)
3. `aula_03_fontes_de_dados_bancos_relacionais_e_nosql` (30/04/2026)
4. `aula_04_ingestao_e_processamento_near_real_time_streaming` (07/05/2026)
5. `aula_05_integracao_etl_serverless_e_catalogo_de_dados` (14/05/2026)
6. `aula_06_data_warehousing_na_nuvem_de_alta_performance` (21/05/2026)
7. `aula_07_data_reliability_e_sre_aplicados_a_pipelines_de_dados` (28/05/2026)
8. `aula_08_seguranca_de_dados_finops_e_projeto_final_integrado` (11/06/2026)
