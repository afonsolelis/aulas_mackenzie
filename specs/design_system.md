# Especificação de Design System

## Objetivo

Definir um sistema visual único e "editorial-técnico" para manter `index.html`, slides e materiais com identidade consistente, navegação previsível e aparência moderna em toda a disciplina.

## Princípios de design

- **Editorial antes de brutalist** — bordas finas de 1px, sombras sutis, acento preto reservado a kickers e regras de topo.
- Clareza antes de ornamentação.
- Contraste alto e leitura simples.
- Tipografia profissional e técnica (Inter + JetBrains Mono).
- Composição visual mais quadrada do que arredondada (raios de 4px).
- Consistência rígida entre `index.html`, slides e materiais.

## Tokens visuais obrigatórios

Implementados em `assets/slides.css` como custom properties em `:root`.

### Cores

| Token | Hex | Uso |
|-------|-----|-----|
| `--deck-bg` | `#fafaf7` | Fundo da página (off-white quente) |
| `--deck-surface` | `#f2f2ee` | Cards, callouts, code inline, hovers de tabela |
| `--deck-surface-2` | `#e9e9e3` | Superfície alternativa (pouco usada) |
| `--deck-panel` | `#ffffff` | Fundo do `.deck-shell` e dos `.deck-panel` |
| `--deck-line` | `#d6d6d1` | Borda 1px neutra padrão |
| `--deck-line-soft` | `#e7e7e2` | Linhas finas em tabelas e code inline |
| `--deck-border` | `#0f0f0f` | Acento de topo, regras editoriais |
| `--deck-text` | `#0f0f0f` | Texto principal |
| `--deck-muted` | `#5c5c5c` | Kickers, meta, labels mono |
| `--deck-accent` | `#0f0f0f` | Botões de navegação, acento de kicker |
| `--deck-code-bg` | `#0d1117` | Fundo de code block (estilo GitHub dark) |
| `--deck-code-fg` | `#e6edf3` | Texto de code block |

**Não** adicionar cores decorativas (azul, verde, laranja) — o contraste vem do preto sobre off-white, nunca de matizes.

### Tipografia

Duas famílias carregadas automaticamente via `@import` no topo de `slides.css`:

| Família | Peso | Uso |
|---------|------|-----|
| **Inter** | 400–900 | Títulos, subtítulos, corpo de texto, summary |
| **JetBrains Mono** | 400–700 | Kickers, `.deck-meta`, year, contador de slides, botões de navegação, code, labels de tabela, decorative numeral |

Tokens: `--font-sans`, `--font-mono`.

- `.deck-title`: Inter 800, `font-size: 2.55em`, `letter-spacing: -0.025em`.
- `.deck-kicker`: JetBrains Mono 600, uppercase, `letter-spacing: 0.14em`, precedido de regra horizontal 1×28px.
- `.deck-year`: JetBrains Mono 700, `4em`.
- Code blocks: JetBrains Mono 400 sobre fundo `#0d1117` com três dots tipo "terminal chrome" no topo-esquerdo (`::before`).

### Espaçamento

- Shell: `padding: 44px 52px`, `margin: 22px`.
- Cards e painéis: `padding: 24px 26px`.
- Callouts: `padding: 22px 28px`.
- Grids: `gap: 20px`.

### Bordas e raios

- Bordas padrão: 1px em `--deck-line`. Preto só em acentos (regra de topo do shell, borda-esquerda do callout, underline do header de card).
- Raio padrão: **4px** (shell, cards, painéis, callouts, botões).
- Raio de code block: 6px.
- **Evitar** bordas pretas 2px em todas as superfícies — isso era do estilo antigo "brutalist" e foi substituído.

### Sombras e profundidade

- Shell: `box-shadow: 0 1px 2px rgba(15,15,15,.04), 0 10px 28px rgba(15,15,15,.06)`.
- Cards no hover: levantam 2px com `box-shadow: 0 6px 16px rgba(15,15,15,.08)`.
- Code blocks: `0 10px 24px rgba(13,17,23,.18)` — sombra mais densa para isolá-los visualmente.
- **Nunca** usar sombras offset duras (`18px 18px 0 ...`).

## Componentes obrigatórios

### Shell do slide (`.deck-shell`)

- Fundo branco, borda 1px, raio 4px, duas sombras em camadas.
- `::before` gera uma regra preta 3×140px no canto superior-esquerdo — assinatura editorial presente em todos os slides.
- `::after` é **reservado** para o numeral decorativo da capa (ver abaixo).

### Numeral decorativo da capa

O slide 1 (capa) pode exibir um numeral gigante translúcido usando o atributo `data-aula-number`:

```html
<div class="deck-shell" data-aula-number="01">
  ...
</div>
```

O CSS usa `content: attr(data-aula-number)` para renderizar o número em JetBrains Mono 22em com opacidade 4.5% no canto inferior-direito. Usar **apenas** na capa de cada aula.

### Kicker (`.deck-kicker`)

Label editorial monoespaçado em caps, precedido por uma regra horizontal de 28×1px. Substitui o antigo "badge com borda".

```html
<span class="deck-kicker">Teoria &middot; SWEBOK V4</span>
```

### Cards, painéis, callouts

- `.deck-card`: hover levanta 2px. Header do card é mono uppercase com underline de 1px.
- `.deck-panel`: plain white box, sem hover.
- `.deck-callout`: borda esquerda preta de 3px + fundo `--deck-surface`.

### Tabela editorial

`.deck-table` abandona a grade completa. Usa **duas regras pretas** (topo e base do header + última linha do body) e regras claras entre linhas. Hover zebra sutil.

Header em JetBrains Mono 600 uppercase letter-spacing 0.08em — aparece como "tag" da coluna.

### Code blocks

- Dark theme com fundo `#0d1117`.
- Três dots sutis no canto superior-esquerdo (`::before` com `box-shadow`) simulando chrome de terminal.
- `pre` interno: sempre em JetBrains Mono, line-height 1.65.

### Rodapé de navegação (`.slide-footer`)

- Fundo translúcido `rgba(250,250,247,.96)` com `backdrop-filter: blur(6px)`.
- Botões em JetBrains Mono caps com letter-spacing.
- Links **Índice** / **Material** em mono caps.

## Regras específicas por superfície

### Index

- Mesmo token de cor, fonte e raio. Cards de aula seguem o padrão editorial.

### Slides

- Usam o sistema HTML nativo com `assets/slides.css`.
- Estrutura mínima: **capa, agenda, placeholder inicial**.
- Cada slide tem **foco único**. Regra 1-estrutura-por-slide:
  - lista; ou grid de cards; ou tabela; ou callout; ou 2 colunas.
- Texto breve, leitura rápida, alta legibilidade.

### Materiais

- Textos mais longos organizados com hierarquia clara.
- Devem usar as mesmas bordas, cores e tipografia dos slides.
- Materiais podem usar `assets/styles.css` para formatação de texto corrido (headings, parágrafos, listas). Tokens visuais e tipografia vêm de `slides.css` sempre que aplicável.

## Animações e diagramas de conteúdo

### Transição base

- Definida em `slides.css` via keyframe `slideIn` (fade + translateY de 10px, easing `cubic-bezier(.22,.61,.36,1)`, 450ms).
- **Não sobrescrever** essa transição por aula.

### Anime.js v4 (content-level)

Diagramas interativos de processo podem usar **Anime.js v4** via ESM jsdelivr:

```html
<script type="module">
  import { animate, stagger, createTimeline, createMotionPath, utils }
    from 'https://cdn.jsdelivr.net/npm/animejs@4/+esm';
</script>
```

Regras:

- Sempre **scoped** no arquivo HTML do slide (não em CSS/JS compartilhado).
- Se animar elementos SVG com transform, usar estrutura de **2 camadas**: `<g>` externo com `transform="translate(x,y)"` para posicionamento + `<g>` interno para a anime.js animar via CSS transform. Misturar os dois no mesmo elemento quebra posicionamento.
- Ativar entrada via `MutationObserver` no `class="active"` do slide correspondente — não rodar em segundo plano em slides não visíveis.

## Responsividade

- Desktop e mobile obrigatórios.
- `html/body` reduzem para `17px` em `max-width: 900px` e `15px` em `max-width: 480px`.
- Grids colapsam para 1 coluna.
- Navegação fixa nunca desaparece.
- Numeral decorativo da capa reduz para 14em em telas pequenas.

## Consistência obrigatória

- Tokens e componentes definidos em `assets/slides.css` são **fonte única de verdade** visual.
- Nenhum arquivo de aula deve redefinir fonte, cor, borda ou raio em `<style data-design-tokens>` inline.
- Estilos inline em slides são **permitidos apenas** para conteúdo específico do slide (diagramas SVG, animações scoped). Qualquer estilo reaproveitável vai para `slides.css`.

## Implementação

- `assets/slides.css` — tokens + todos os componentes de slide.
- `assets/styles.css` — tipografia e componentes do `index.html` e materiais (texto corrido, botões, cards de listagem).
- Especificação visual é autoritativa — ao criar qualquer página nova, consultar este arquivo antes de escrever CSS.
- Antes de criar nova classe, verificar se o padrão já existe.
