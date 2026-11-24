# Bancada da Aula 07

Laboratório embutido nos slides da Aula 07 de Data Collection and Storage (28/11/2026). Roda pytest de verdade no navegador, com o Pyodide 0.27.7 (Python 3.12.7, pytest 8.1.1, Pydantic 2.10.5), sem servidor.

| Arquivo | Papel |
|---|---|
| `bancada_aula_07.html` e `bancada_aula_07.js` | tela da bancada; `?embed=1` esconde a navegação para o iframe dos slides |
| `bancada.py` | motor: grava os arquivos numa pasta temporária, roda `pytest.main` e aplica os mutantes; o mesmo arquivo roda no navegador e no terminal |
| `exercicios/manifesto.json` | arquivos de cada estação, quais são editáveis, referência, verificação e mutantes (trecho `de` trocado por `para`) |
| `exercicios/<estação>/` | código e dados que o aluno vê; os arquivos que começam com `_` são ocultos (referência e verificação do professor) |
| `gabarito/<estação>/` | uma solução que atinge a meta de cada estação |

## Conferir as estações no terminal

```bash
cd bancada
uv venv /tmp/bancada && VIRTUAL_ENV=/tmp/bancada uv pip install pytest pydantic
/tmp/bancada/bin/python bancada.py ex1_contrato                       # arquivos iniciais
/tmp/bancada/bin/python bancada.py ex1_contrato gabarito/ex1_contrato # com o gabarito
```

Resultado registrado em 24/11/2026 (pytest 9.2.0, Pydantic 2.14.4): os arquivos iniciais matam 1 de 1, 1 de 9, 1 de 7, 0 de 5, 0 de 7 e 0 de 6 mutantes; os gabaritos matam todos. No navegador, com Chromium, o Python ficou pronto em 10,8 s, com 17,5 MB transferidos, e cada avaliação completa levou de 0,2 s a 0,7 s.

## Dados

- Livros: os 20 livros da primeira página de books.toscrape.com, coletados em 24/11/2026 com `requests` sem corrigir o encoding (por isso o preço vem como `Â£51.77`). Defeitos plantados em `ex5_lote/lote_bronze.json`: duas linhas repetidas, preço vazio em "The Requiem Red", nota vazia em "Rip it Up and Start Again" e categoria `"Poetry "` em "Olio".
- PTAX: resposta real da API Olinda do Banco Central para o dólar entre 13 e 24/11/2026 (`ex4_dubles/boletim_ptax.json`), também usada em `ex3_relogio/ptax_vigente.py`.

## Ao mudar um arquivo

O GitHub Pages guarda cache por 10 minutos. Ao alterar o JS, o motor ou os exercícios, troque `VERSAO` em `bancada_aula_07.js` e o `?v=` da bancada no slide (`SIM_URL`) e no HTML da bancada.
