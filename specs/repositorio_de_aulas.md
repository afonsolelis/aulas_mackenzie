# Especificação do Repositório de Aulas e Hub de Disciplinas

## Objetivo

Organizar o conteúdo do curso em um repositório estático Hub com a página inicial `index.html` (seletor de disciplinas), páginas dedicadas por disciplina em `pages/` e pastas por disciplina em `aulas/` contendo, para cada aula, um arquivo de slide e um arquivo de material escrito.

## Referências obrigatórias

- A estrutura e a navegação deste repositório devem seguir esta especificação.
- O alinhamento visual entre páginas, slides e materiais deve seguir `specs/design_system.md`.

## Estrutura obrigatória

```text
/
├── index.html                           # Hub Central de Disciplinas
├── estudios.html                        # Biblioteca de autoestudo
├── professor.html                       # Perfil do professor
├── assets/
│   ├── styles.css
│   └── slides.css
├── pages/
│   ├── home_cloud_sre.html              # Home da disciplina Cloud Computing e SRE
│   ├── home_data_collection.html        # Home da disciplina Data Collection and Storage
│   └── home_data_visualization.html     # Home da disciplina Data Visualization
├── specs/
│   └── repositorio_de_aulas.md
└── aulas/
    ├── cloud_sre/
    │   └── aula_xx_nome_da_aula/
    │       ├── slides/
    │       │   └── slide_aula_xx_nome_da_aula.html
    │       └── material/
    │           └── material_aula_xx_nome_da_aula.html
    ├── data_collection_and_storage/
    │   └── aula_xx_nome_da_aula/
    │       ├── slides/
    │       │   └── slide_aula_xx_nome_da_aula.html
    │       └── material/
    │           └── material_aula_xx_nome_da_aula.html
    └── data_visualization/
        └── aula_xx_nome_da_aula/
            ├── slides/
            │   └── slide_aula_xx_nome_da_aula.html
            └── material/
                └── material_aula_xx_nome_da_aula.html
```

## Convenções de nomenclatura

- Todo nome de pasta e arquivo deve usar `snake_case`.
- Toda pasta de disciplina em `aulas/` deve ser descritiva (ex: `cloud_sre`, `data_collection_and_storage`).
- Toda pasta de aula deve começar com `aula_` e dois dígitos (ex: `aula_01_...`).
- Todo arquivo de slide deve começar com `slide_`.
- Todo arquivo de material deve começar com `material_`.
- Os nomes devem evitar espaços, hífens e caracteres especiais.

## Regras de conteúdo

- `index.html` deve atuar como o Hub Principal, exibindo os cards das disciplinas ativas, perfil do professor e autoestudo.
- Cada `pages/home_<disciplina>.html` deve listar todas as aulas daquela disciplina específica com links para slide e material.
- Cada slide deve conter:
  - título da aula;
  - data da aula;
  - resumo do tema;
  - link para o material escrito da aula;
  - link de volta para a Home da Disciplina e para o Hub (`index.html`).
- Cada material deve conter:
  - título da aula;
  - data da aula;
  - resumo do conteúdo;
  - link para o slide da aula;
  - link de volta para a Home da Disciplina e para o Hub (`index.html`).
  - link de volta para `index.html`.

## Regra obrigatória de dinâmica da aula

- O horário de cada disciplina deve seguir seu cronograma em `specs/estrutura_curso.md`.
- Aulas noturnas ocorrem das `19h00` às `22h00`; aulas de sábado de Data Collection and Storage e Data Visualization ocorrem das `8h30` às `12h10`.
- A primeira parte da aula deve ser sempre teórica, exceto nas Aulas 04 e 08 de Data Visualization. A Aula 04 é 100% prática: os conceitos são introduzidos durante a execução guiada no terminal, sem bloco teórico separado. A Aula 08 é ateliê de finalização e entrega do projeto do módulo, também sem bloco teórico separado.
- O restante da aula deve ser prático, no ambiente definido para a disciplina: `AWS Student Lab` em Cloud Computing e SRE e em Data Collection and Storage; instância `Metabase` hospedada em Data Visualization, exceto nas Aulas 03 e 04. A Aula 03 usa `GitHub Codespaces`, `D3` e assistência de IA sobre uma API segura; a Aula 04 usa Codespaces e OpenCode Zen para construir o fluxo Excel → SQLite → HTML → DuckDB → HTML. Das Aulas 05 a 08 a prática ocorre no Metabase sobre o conjunto do projeto do módulo — o rastro de trabalho PBL —, e não mais sobre o Olist.
- Slides, materiais e cronograma devem refletir os intervalos da respectiva disciplina de forma consistente.

## Regra obrigatória para slides

- Todo slide de aula deve ser implementado com o sistema de slides HTML nativo, sem dependência de frameworks externos.
- Cada slide é um `<div class="slide">` dentro de um `<div class="slide-container">`. Apenas o slide com a classe `.slide.active` é visível por vez.
- Um `<div class="slide-footer">` fixo no rodapé fornece navegação: botões anterior/próximo, contador de slides, alternância de tela cheia e links de navegação (Home/Material).
- A navegação por teclado é obrigatória: `ArrowRight`/`Space` = próximo, `ArrowLeft` = anterior, `F` = tela cheia.
- O CSS compartilhado dos slides deve estar em `assets/slides.css`.
- O JavaScript de navegação dos slides deve estar embutido no próprio HTML ou em arquivo compartilhado, sem dependências externas.
- Novas aulas, revisões e migrações de slides existentes devem adotar o sistema HTML nativo como padrão canônico.
- Todo slide deve começar com uma capa.
- A capa deve exibir o título da aula e o ano `2026`.
- O segundo slide deve apresentar a agenda da aula.
- O terceiro slide deve existir como placeholder inicial para a construção do conteúdo.
- Todo slide deve conter link explícito para o material escrito da mesma aula.
- Todo slide deve conter link explícito de volta para `index.html`.
- Esses links de navegação são obrigatórios e não devem ser omitidos em nenhuma aula.
- Cada slide deve ter um foco único e claro.
- Cada slide deve conter somente os elementos necessários para comunicar esse foco com boa leitura.
- Cada slide deve priorizar um título forte e no máximo um bloco principal de conteúdo por vez.
- Quando houver listas, tabelas, cards ou painéis, a quantidade deve ser limitada para evitar poluição visual.
- Não usar rodapés fixos extras, barras redundantes ou controles duplicados além do `.slide-footer` padrão.
- Evitar excesso de texto no slide; detalhes longos devem ir para o material escrito.

## Regra obrigatória para materiais

- Todo material deve espelhar os mesmos tópicos apresentados no slide da aula correspondente.
- O material deve aprofundar cada tópico do slide com explicações mais descritivas e mais completas.
- O material deve conter textos mais longos, voltados à reflexão, contextualização e entendimento conceitual.
- O material deve incluir orientações passo a passo sempre que houver processo, laboratório, configuração ou execução prática.
- O material deve funcionar como apoio de estudo e revisão após a aula, e não apenas como resumo curto.
- Todo material deve conter link explícito para o slide da mesma aula.
- Todo material deve conter link explícito de volta para `index.html`.
- Esses links de navegação são obrigatórios e não devem ser omitidos em nenhuma aula.
- O fechamento do material é orientação para a atividade prática em sala (Codespace, IA, AWS Student Lab). O curso é 100% prático — não há seção de exercícios escritos.

## Regras visuais iniciais

- Fundo branco.
- Texto preto.
- Contraste alto e leitura simples.
- Layout responsivo básico para desktop e mobile.
- O design dos slides deve seguir uma direção visual mais atual.
- Cards, painéis e áreas de destaque devem priorizar composição mais quadrada.
- Bordas excessivamente arredondadas devem ser evitadas nos elementos principais.

## Lista inicial de aulas

1. `aula_01_fundamentos_de_cloud_para_dados_e_governanca_de_acessos`
2. `aula_02_a_fundacao_do_data_lake_armazenamento_escalavel_s3_e_athena`
3. `aula_03_fontes_de_dados_bancos_relacionais_e_nosql`
4. `aula_04_ingestao_e_processamento_near_real_time_streaming`
5. `aula_05_integracao_etl_serverless_e_catalogo_de_dados`
6. `aula_06_data_warehousing_na_nuvem_de_alta_performance`
7. `aula_07_data_reliability_e_sre_aplicados_a_pipelines_de_dados`
8. `aula_08_seguranca_de_dados_finops_e_projeto_final_integrado`
