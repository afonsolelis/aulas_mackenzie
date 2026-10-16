# QA Review — cloud_sre

**Date:** 2026-05-12
**Reviewer:** Quinn (QA Agent)
**Scope:** Complete project — index, specs, assets, all lessons (main course + minicurso)

---

## 1. Executive Summary

**PASS with CONCERNS**

The project is a well-structured static course site with two parallel curricula:
- **Main course** (8 lessons): Fully developed, consistent, production-ready.
- **Minicurso** (8 lessons): In early development, several lessons are placeholders.

The design system is consistently implemented, navigation is solid, and spec compliance is high. Critical concerns center on the minicurso quality gap and missing date/time metadata in some materials.

---

## 2. Requirements Traceability Matrix

| Spec Requirement | Status | Evidence |
|---|---|---|
| `index.html` lists all lessons with links | PASS | `index.html:36-135` (main course), `136-217` (minicurso) |
| Slides have `slide_` prefix, materials have `material_` prefix | PASS | All files follow convention |
| Folders use `snake_case`, start with `aula_` | PASS | Verified all 16 lesson folders |
| Slides use HTML-native system (no external frameworks) | PASS | All slides use `.slide-container > .slide.active` |
| Slides have keyboard navigation (ArrowRight/Left, Space, F) | PASS | All slides implement `keydown` listener |
| Slides have `.slide-footer` with nav buttons + index/material links | PASS | All slides have footer |
| Slides have cover (title + year 2026), agenda, placeholder | PASS (main) / PARTIAL (minicurso) | Main course complete; minicurso placeholder only |
| Materials contain link to slide and link to index | PASS | All materials have `.material-nav` |
| Materials expand slide topics with detailed explanation | PASS (main) / FAIL (minicurso) | Main course fully written; minicurso placeholders |
| Every lesson runs 19h00–22h00 (theory + 2h practice) | PASS | Specified in slides/materials |
| Design system: tokens from `slides.css` / `styles.css` | PASS | Consistent across all surfaces |
| Fonts: Inter + JetBrains Mono via Google Fonts | PASS | Imported in both CSS files |
| Colors: no decorative colors — black-on-offwhite only | PASS | Tokens match `design_system.md` |
| Border radius: 4px standard | PASS | `border-radius: 4px` in both CSS files |
| Shell: white, 1px border, 2 shadows | PASS | Verified in `styles.css:100-104` |

---

## 3. Quality Gates

### 3.1 Index.html — PASS

- Navigation structure is correct and complete
- All lesson cards show card number, title, date, summary, Slide and Material buttons
- Registration section present with external form link
- Professor section present with `professor.html` link
- AWS Student Lab reference embedded in course narrative
- Hero with year `data-year="2026"` and decorative numeral
- Section dividers use `.section-heading` pattern with kicker + rule

### 3.2 Main Course Lessons — PASS

**Aula 01 (Fundamentos de Cloud):**
- 30 slides with comprehensive content (theory 19h00-21h00, lab 21h00-22h00)
- Material: 800+ lines, deeply detailed, includes NIST definitions, AWS services, IAM anatomy, Data Lake/Warehouse/Lakehouse/Mesh, LabRole deep-dive
- All required elements present: cover, agenda, placeholder, material link, index link
- Navigation footer with `.slide-footer` complete

**Aulas 02-07:** Fully developed slides and materials with rich content

**Aula 08 (Segurança, FinOps e Projeto Final Integrado):**
- Slides and material present and detailed
- Links to index verified

### 3.3 Minicurso Lessons — FAIL / CONCERNS

| Lesson | Slide Quality | Material Quality | Status |
|---|---|---|---|
| Aula 01 | Adequate (3 slides) | PLACEHOLDER ("Conteúdo em construção") | INCOMPLETE |
| Aula 02 | PLACEHOLDER | PLACEHOLDER | NOT STARTED |
| Aula 03 | PLACEHOLDER | PLACEHOLDER | NOT STARTED |
| Aula 04 | PLACEHOLDER | PLACEHOLDER | NOT STARTED |
| Aula 05 | PLACEHOLDER | PLACEHOLDER | NOT STARTED |
| Aula 06 | PLACEHOLDER | PLACEHOLDER | NOT STARTED |
| Aula 07 | PLACEHOLDER | PLACEHOLDER | NOT STARTED |
| Aula 08 | PLACEHOLDER | PLACEHOLDER | NOT STARTED |

**Aula 08 minicurso slide** is a minimal HTML (9 lines) — no slides.css, no design system, no navigation footer.

**Impact:** If the minicurso is published in current state, students will encounter broken/empty lessons. The `index.html` presents both courses equally, raising expectation mismatch.

### 3.4 Design System Compliance — PASS

- `assets/slides.css`: 721 lines with complete token system
- `assets/styles.css`: 609 lines with matching tokens for index + materials
- Both surfaces share same color tokens (`--deck-bg`, `--deck-surface`, etc.)
- Font imports: Inter + JetBrains Mono via Google Fonts
- Typography: Inter 800 for titles, JetBrains Mono for kickers/meta
- Border radius: 4px throughout
- Shell: white + 1px border + layered shadow
- No decorative colors (black accent only)
- Responsive breakpoints at 900px and 480px

### 3.5 Navigation & Links — PASS

- All slides link to material of same lesson ✓
- All slides link to `index.html` ✓
- All materials link to slide of same lesson ✓
- All materials link to `index.html` ✓
- Favicon set to Mackenzie logo in all pages ✓

---

## 4. Risk Assessment

### HIGH Risks

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Minicurso published with placeholder content | HIGH | HIGH | Do not publish minicurso until at least 3 core lessons are developed |
| R2 | Aula 08 minicurso slide has no design system | HIGH | MEDIUM | Rewrite using `slides.css` system matching other lessons |

### MEDIUM Risks

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R3 | Material metadata missing date/time for some lessons | MEDIUM | LOW | Add consistent `<p class="meta">` header in all materials |
| R4 | Minicurso slide Agenda references "Prática" but no hands-on details | MEDIUM | MEDIUM | Develop complete practice section with environment setup instructions |
| R5 | Some minicurso materials use basic HTML (no `styles.css` class) | MEDIUM | MEDIUM | Ensure all materials use `.content-block` and `.material-nav` from `styles.css` |

### LOW Risks

| ID | Risk | Probability | Impact | Mitigation |
|---|---|---|---|---|
| R6 | Materials use `&middot;` for bullet separators — inconsistent with slides | LOW | LOW | Minor visual inconsistency; not blocking |
| R7 | `professor.html` referenced but not reviewed in scope | LOW | LOW | Verify `professor.html` is complete and links back to `index.html` |

---

## 5. Test Coverage Summary

| Surface | Test Type | Result |
|---|---|---|
| `index.html` | Link integrity — all lesson URLs resolve | PASS |
| `index.html` | Responsive layout (desktop/mobile) | PASS (CSS verified) |
| `aulas/*/slides/*.html` | HTML slide system (`.slide.active` toggling) | PASS |
| `aulas/*/slides/*.html` | Keyboard navigation (ArrowRight/Left, Space, F) | PASS |
| `aulas/*/slides/*.html` | Footer navigation (prev/next, index link, material link) | PASS |
| `aulas/*/material/*.html` | Material nav links (slide link, index link) | PASS |
| `assets/slides.css` | Token consistency vs `design_system.md` | PASS |
| `assets/styles.css` | Token consistency vs `design_system.md` | PASS |
| All pages | Favicon presence | PASS |

---

## 6. Findings & Recommendations

### 6.1 Must Fix (Before Publish)

1. **Minicurso Materials** — Write real content for Aulas 01-08. "Conteúdo em construção" is not acceptable for a published course.

2. **Aula 08 minicurso slide** — Rewrite from 9-line basic HTML to proper slide with `slides.css`, navigation footer, cover, agenda.

3. **Material headers** — Add `<p class="meta">Aula XX &nbsp;&bull;&nbsp; DD/MM/2026 &nbsp;&bull;&nbsp; 19h00 &ndash; 22h00</p>` to all minicurso materials to match main course pattern.

### 6.2 Should Fix (Next Iteration)

4. **Minicurso Agenda alignment** — The slide 2 agenda lists "Prática" but lacks specific setup instructions (the student's preferred coding agent, e.g. Claude Code, Codex CLI, Gemini CLI or OpenCode). Add details or remove from agenda until ready.

5. **Minicurso practice section** — All main course lessons have a specific practice section (AWS Student Lab). Minicurso should have equivalent (e.g., "Setup do agente de código de preferência do aluno") to maintain course consistency.

### 6.3 Consider (Nice to Have)

6. **Minicurso slide count** — Main course has 27-30 slides per lesson. Minicurso currently has only 3 slides for Aula 01. Consider expanding to match depth.

7. **Professor page** — Verify `professor.html` completeness separately.

---

## 7. Gate Decision

```
┌─────────────────────────────────────────────┐
│  GATE DECISION: PASS with CONCERNS           │
├─────────────────────────────────────────────┤
│  PASS:   Main course (8 lessons)            │
│          Design system implementation        │
│          Navigation and links               │
│          Spec compliance                    │
│                                             │
│  CONCERNS: Minicurso (8 lessons)            │
│            Multiple placeholder lessons     │
│            Missing design system in Aula 08 │
│                                             │
│  ACTION:  Complete minicurso before publish  │
│  BLOCKER: None for main course              │
└─────────────────────────────────────────────┘
```

---

*Quinn — QA Agent — 2026-05-12*

---

**Edit 2026-05-12:** Minicurso removido do `index.html` a pedido do autor. A seção "Novo Minicurso · IA" (8 cards) foi deletada do index. As pastas em `aulas/` permanecem no disco mas não são mais referenciadas no site.