# AGENTS.md — aulas_mackenzie

## Project Type

Static course site (HTML/CSS, no build pipeline, no test suite).

## Project Structure

```
/
├── index.html              # Hub Central — seletor de disciplinas
├── estudios.html           # Biblioteca de autoestudo
├── professor.html          # Perfil do professor
├── assets/
│   ├── styles.css          # Estilos compartilhados: hub, homes e materiais
│   └── slides.css          # Estilos dos slides: tokens, shell, cards, tabelas, footer
├── pages/
│   ├── home_cloud_sre.html       # Home da disciplina Cloud Computing e SRE
│   └── home_data_collection.html # Home da disciplina Data Collection and Storage
├── specs/
│   ├── repositorio_de_aulas.md   # Estrutura canônica, regras de navegação e conteúdo
│   ├── estrutura_curso.md        # Cronogramas e convenções de nomenclatura
│   └── design_system.md          # Tokens visuais, tipografia e componentes
└── aulas/
    ├── cloud_sre/
    │   └── aula_XX_nome_da_aula/
    │       ├── slides/slide_aula_XX_*.html
    │       └── material/material_aula_XX_*.html
    └── data_collection_and_storage/
        └── aula_XX_nome_da_aula/
            ├── slides/slide_aula_XX_*.html
            └── material/material_aula_XX_*.html
```

Surfaces principais: Hub principal (`index.html`), homes das disciplinas em `pages/` e arquivos HTML de aulas em `aulas/`.

## Naming Conventions (mandatory)

- Folders: `aula_01_nome_da_aula` — snake_case, starts with `aula_`
- Slides: `slide_aula_01_nome_da_aula.html` — snake_case, starts with `slide_`
- Materials: `material_aula_01_nome_da_aula.html` — snake_case, starts with `material_`
- No spaces, no hyphens, no special characters in names

## How to Preview

```bash
python3 -m http.server 8000
# then open http://localhost:8000/index.html
```

## How to Validate

There is no automated test suite. Manual validation checklist:

1. Open changed HTML pages in a browser
2. Verify navigation links work (index → slide → material → index)
3. Check slide footer has: prev/next buttons, slide counter, index link, material link
4. Confirm keyboard navigation: `→` / `Space` = next, `←` = prev, `F` = fullscreen
5. Verify `data-year="2026"` and `deck-year` are present on covers
6. Confirm lesson timing (`19h00–22h00`) and `AWS Student` practice are in slides and materials
7. Check visual consistency against `specs/design_system.md`

## Specs First Rule

Read `specs/repositorio_de_aulas.md`, `specs/estrutura_curso.md`, and `specs/design_system.md` **before** editing. If code and specs disagree, treat specs as the contract unless the user explicitly overrides them.

## Slide Requirements (per spec)

Every slide file must include:
- **Slide 1 (cover):** title + `2026` year + `.deck-shell data-aula-number` + Mackenzie logo
- **Slide 2 (agenda):** theory + practice breakdown with time slots
- **Slide 3 (placeholder):** for content construction
- **`.slide-footer`:** index link + material link + prev/next + slide counter + fullscreen
- **Keyboard nav:** `ArrowRight`/`Space`=next, `ArrowLeft`=prev, `F`=fullscreen
- **No external frameworks** — pure HTML/CSS with `assets/slides.css`

## Material Requirements (per spec)

Every material file must include:
- `<p class="meta">` with lesson number, date, time range
- Deep expansion of slide topics (longer than slide, reflective)
- Step-by-step for labs (AWS Student Lab hands-on)
- `.material-nav` with link to slide and link to `index.html`
- No written exercises section — ends with hands-on guidance

## Style

- 2-space indentation for HTML/CSS
- Fonts: Inter (body) + JetBrains Mono (kickers/meta/code) via Google Fonts
- Colors: black on off-white (`#fafaf7`) — no decorative colors
- Border radius: 4px standard, 6px for code blocks
- Shell: white background, 1px border, layered box-shadow

## Commit Convention

Short imperative commits. Example: `Remove minicurso section from index.html`.

## QA Review

Run `*review` via the QA agent before significant changes: `curl -s <deployed-url>` to verify the deployed site matches local changes. Wait ~30s for GitHub Pages rebuild after push.