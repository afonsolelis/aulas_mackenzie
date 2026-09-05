# Rastro de trabalho PBL — turma T28, grupos G01, G02 e G03

Conjunto do projeto do módulo de **Data Visualization**. Descreve o trabalho de três
grupos de graduação do **Instituto Ápice** — uma instituição de ensino por projetos —
ao longo de um módulo completo de cinco sprints, observado pelo rastro que os grupos
deixaram no GitLab: commits, merge requests, cartões do quadro Kanban e a movimentação
desses cartões entre colunas.

## Procedência e pseudonimização

Os dados são **reais**. As pessoas e a instituição, **não**.

| Campo original | O que foi feito |
|---|---|
| Nome, e-mail e username de aluno | Substituídos por um código estável por grupo: `G01-A01`, `G01-A02`, … |
| Nome da instituição e domínio | Substituídos por nome fictício e `apice.edu.br` |
| Texto livre (título, descrição, mensagem de commit) | Mantido, com scrub de e-mails, URLs, menções, tokens e nomes próprios |
| Pessoa fora do recorte | `[externo]`; automações aparecem como `[bot]` |

O scrub de texto é *best-effort*: padrões e nomes conhecidos são removidos, mas um
apelido incomum escrito no corpo de um cartão pode escapar. Trate o conjunto como
material didático de circulação restrita à turma, não como dado público.

A autoria de commit resolve para um código em **2.136 dos 2.688 commits (79%)**. O
resto é `[externo]` ou `[bot]`: o e-mail configurado no cliente git nem sempre
corresponde à conta institucional. Essa lacuna é dado, não defeito — ela pertence ao
Gate 2 do dossiê.

## Arquivos

| Arquivo | Uma linha é | Linhas |
|---|---|---:|
| `grupos.csv` | um grupo, com branch padrão e janela de atividade | 3 |
| `pessoas.csv` | uma pessoa vinculada a um grupo, com papel | 83 |
| `sprints.csv` | uma sprint de um grupo, com início e prazo | 15 |
| `quadro_colunas.csv` | uma coluna do quadro Kanban de um grupo | 12 |
| `commits.csv` | um commit, com autor, datas e linhas alteradas | 2.688 |
| `merge_requests.csv` | uma solicitação de integração, com revisores e desfecho | 540 |
| `cartoes.csv` | um cartão do quadro, com responsáveis, rótulos e sprint | 1.238 |
| `kanban_eventos.csv` | a entrada ou a saída de um cartão em uma coluna | 13.194 |
| `manifesto.json` | proveniência do recorte e contagem de cada arquivo | — |

Todos em UTF-8, separados por vírgula, com cabeçalho. Datas em ISO 8601. Campos
multivalorados (`responsaveis_ids`, `revisores_ids`, `rotulos`) usam `;` como separador
interno.

## Reconstruir o fluxo do quadro

`kanban_eventos.csv` não registra colunas: registra a aplicação (`add`) e a remoção
(`remove`) de um **rótulo**. Como cada coluna do quadro corresponde a um rótulo, a
passagem de um cartão por *Backlog* → *Doing* → *Waiting Review* → *Review* é
reconstruída pareando cada `add` com o `remove` seguinte do mesmo rótulo, no mesmo
cartão, ordenado por `ocorrido_em`. Essa reconstrução é sua — e é exercício de grão,
não de estética.

Atenção: nem todo rótulo é coluna. Os eventos também trazem rótulos de classificação
(`DOCUMENTATION`, `CODE`, `DESIGN`, `size_P`, `SIZE_M`). Cruze com `quadro_colunas.csv`
para separar movimento de fluxo de marcação de tipo. Note ainda que os rótulos de
tamanho aparecem em grafias divergentes (`size_M` e `SIZE_M`) — normalizar ou não é
decisão sua, e ela pertence ao registro escrito.

## Limitações que pertencem ao dossiê

- **A extração é uma fotografia com data.** Nada posterior a `extraido_em`
  (`manifesto.json`) existe aqui.
- **Não há diff nem texto de revisão.** Há o total de linhas de cada commit e a
  contagem de comentários de cada MR, mas não quais arquivos mudaram nem o que foi
  dito. Afirmações sobre a qualidade do código escrito não se sustentam nesta base.
- **A data do commit é gravada pelo cliente** e pode ser reescrita por `rebase`.
  Há commits datados de 2022 a 2025 — herança do repositório-template, não trabalho
  do módulo. Filtrar pela janela das sprints é uma decisão a declarar, não a esconder.
- **Ausência de rastro não é ausência de trabalho.** Conversa fora da plataforma,
  programação em par no mesmo teclado e código descartado antes do commit não
  aparecem. Um integrante pouco visível nos dados é um integrante sobre o qual esta
  fonte não tem evidência.

## Regeneração

```bash
python3 tools/export_projeto_csv.py --out dados/projeto_pbl
```

A origem é `data/pbl_modulo2.sqlite`, que contém os dados identificados e **nunca é
versionada**. Só o resultado pseudonimizado deste diretório entra no repositório.
