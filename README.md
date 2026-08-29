# Hub de Disciplinas — MBA em Engenharia de Dados & Cloud (Mackenzie)

Repositório centralizador de disciplinas e materiais do **MBA em Engenharia de Dados** da Universidade Presbiteriana Mackenzie.

## 📚 Disciplinas

1. **Cloud Computing e SRE — Visão Prática com AWS** ([pages/home_cloud_sre.html](pages/home_cloud_sre.html))
2. **Data Collection and Storage** ([pages/home_data_collection.html](pages/home_data_collection.html))
3. **Data Visualization** ([pages/home_data_visualization.html](pages/home_data_visualization.html))

## Laboratório da Aula 03 — Codespaces, D3 e IA

[Abrir o laboratório no GitHub Codespaces](https://codespaces.new/afonsolelis/aulas_mackenzie?quickstart=1)

Depois que o Codespace terminar a preparação, execute um único comando:

```bash
npm run lab:aula03
```

Abra a porta `3000` quando o Codespaces solicitar. O laboratório funciona imediatamente com dados e crítica locais. Para consultar o Olist no Railway, cadastre `DATABASE_URL` em **GitHub → Settings → Codespaces → Secrets**; para habilitar a crítica pela OpenAI, cadastre também `OPENAI_API_KEY`. Nenhum dos dois é obrigatório para completar a atividade.

O guia de segurança, diagnóstico e roteiro de 130 minutos está em [laboratório da Aula 03](aulas/data_visualization/aula_03_visualizacao_de_dados_numericos/laboratorio/README.md).

---

## 🚀 Como Executar Localmente

```bash
python3 -m http.server 8000
# Acesse no navegador: http://localhost:8000/index.html
```

---

## 📁 Estrutura de Arquivos

```text
/
├── index.html              # Hub Central (seletor de disciplinas)
├── estudios.html           # Biblioteca de autoestudo
├── professor.html          # Perfil do professor Afonso Lelis
├── assets/
│   ├── styles.css          # Estilos de hub, homes e materiais
│   └── slides.css          # Estilos dos slides HTML nativos
├── pages/
│   ├── home_cloud_sre.html       # Home da disciplina Cloud Computing e SRE
│   ├── home_data_collection.html # Home da disciplina Data Collection and Storage
│   └── home_data_visualization.html # Home da disciplina Data Visualization
├── specs/                  # Especificações técnicas e cronogramas
└── aulas/
    ├── cloud_sre/                      # Slides e materiais de Cloud & SRE
    ├── data_collection_and_storage/    # Slides e materiais de Data Collection & Storage
    └── data_visualization/             # Slides, materiais e laboratórios de Data Visualization
```

---

## 📄 Licença

Material didático desenvolvido para as disciplinas do MBA em Engenharia de Dados — Universidade Presbiteriana Mackenzie.
