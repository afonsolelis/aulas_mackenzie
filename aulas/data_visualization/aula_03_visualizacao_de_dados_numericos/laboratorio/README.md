# Laboratório — do modelo ao dashboard com D3 e IA

[Abrir no GitHub Codespaces](https://codespaces.new/afonsolelis/aulas_mackenzie?quickstart=1)

Este template organiza a prática em uma sequência verificável: catálogo do banco, discussão da modelagem, contrato de métricas e dashboard. O frontend usa HTML/CSS/D3; a API Node.js lê o PostgreSQL Olist do Railway. Copilot e OpenCode apoiam a análise e a implementação, mas nenhuma sugestão substitui teste de grão, cardinalidade ou reconciliação.

## Início rápido

1. Entre no GitHub e abra o link acima. Na tela **Create a new codespace**, mantenha o repositório `afonsolelis/aulas_mackenzie`, escolha a branch da aula e clique em **Create codespace**.
2. Copie a URL PostgreSQL exibida no slide 3. Em outra aba, abra **GitHub → Settings → Codespaces → Secrets → New secret**, use o nome `DATABASE_URL`, cole a URL como valor e conceda acesso a este repositório.
3. Se o Codespace já estava aberto quando o secret foi criado, pare e inicie novamente o ambiente ou execute **Codespaces: Rebuild Container** pela paleta de comandos.
4. No terminal, execute:

   ```bash
   npm run lab:aula03
   ```

5. Quando o Codespaces oferecer a porta `3000`, clique em **Open in Browser**.
6. Confirme no topo `Dados: available`. `Dados: not_configured` indica que o secret não entrou no ambiente; `IA: local_fallback` continua válido.

## 1. Preparar os assistentes

O dev container solicita as extensões **GitHub Copilot** e **GitHub Copilot Chat**. Se o chat não aparecer, abra **Extensions**, procure por `GitHub Copilot`, instale e autentique com a conta GitHub que possui acesso ao serviço. Abra o chat pelo ícone do Copilot e confirme que ele consegue explicar um arquivo selecionado sem alterá-lo.

No terminal do Codespaces, instale o OpenCode com Node.js:

```bash
npm install -g opencode-ai
opencode --version
opencode
```

Dentro do OpenCode, digite `/connect`, escolha **OpenCode Zen**, abra a página de autenticação indicada e cole a chave. Em seguida, use `/models` para escolher um modelo disponível. Zen é opcional, cobrado separadamente e requer conta/créditos próprios. Nunca cole a chave no chat, em `.env` versionado, no HTML ou em commits.

## 2. Extrair e discutir a modelagem

Com `DATABASE_URL` configurada, gere um catálogo sem linhas de negócio:

```bash
npm run inspect:aula03
```

O comando grava `docs/00_catalogo_banco.md` com schemas, tabelas, views, colunas e restrições declaradas. Abra também `docs/00_modelagem_e_metricas.md`. No Copilot Chat, use **Add Context** para incluir os dois arquivos; no OpenCode, mencione os caminhos no pedido. Use o prompt registrado no próprio documento.

A resposta do assistente é uma hipótese de modelagem. Antes de aceitá-la, o grupo precisa declarar o grão de cada objeto, testar unicidade das chaves candidatas, verificar fanout nas junções e distinguir as datas do processo. O catálogo mostra estrutura declarada; ele não prova significado de negócio.

## 3. Definir métricas antes do HTML

Preencha o contrato de métricas com pergunta, fórmula, grão, filtros, denominador, unidade, teste de reconciliação e limitação. Só avance quando quatro métricas estiverem aprovadas: evolução, distribuição, magnitude e relação. Cada métrica deve ter uma consulta delimitada e um resultado de teste; código sugerido por IA é revisado antes da execução.

## 4. Construir o dashboard

Inicie o template, abra a porta 3000 e trate cada gráfico como um painel do mesmo dashboard. Use Copilot ou OpenCode para propor pequenas alterações em `public/index.html`, `public/styles.css` e `public/app.js`. Trabalhe uma mudança por vez, inspecione o diff, execute os testes e confirme que a implementação respeita o contrato de métricas.

## Conectar ao Railway e à IA

Cadastre em **GitHub → Settings → Codespaces → Secrets**:

- `DATABASE_URL`: cole aqui o valor da `POSTGRES_URL` PostgreSQL de um usuário exclusivo e somente leitura;
- `OPENAI_API_KEY`: opcional; sem ela, o roteiro crítico local permanece ativo;
- `OPENAI_MODEL`: opcional; o padrão fica em `config/aula_03_codespaces_d3_ia.yaml`.

Recrie ou reinicie o Codespace depois de adicionar secrets. O código aceita `POSTGRES_URL` como alias, mas `DATABASE_URL` é o nome canônico da aula. Não é necessário criar `.env` no Codespaces; secrets são injetados como variáveis de ambiente. Nunca coloque valores reais em HTML, JavaScript do navegador, commits ou capturas de tela.

## Papel PostgreSQL recomendado

Execute administrativamente e adapte o nome do banco/schema antes da aula:

```sql
CREATE ROLE olist_app_read LOGIN PASSWORD '<senha-forte>';
GRANT CONNECT ON DATABASE olist TO olist_app_read;
GRANT USAGE ON SCHEMA public TO olist_app_read;
GRANT SELECT ON TABLE public.olist_orders,
  public.olist_order_items,
  public.olist_products,
  public.product_category_name_translation TO olist_app_read;
REVOKE CREATE ON SCHEMA public FROM olist_app_read;
ALTER ROLE olist_app_read SET default_transaction_read_only = on;
ALTER ROLE olist_app_read SET statement_timeout = '5s';
ALTER ROLE olist_app_read SET lock_timeout = '1s';
ALTER ROLE olist_app_read SET idle_in_transaction_session_timeout = '5s';
```

O Codespace pertence ao aluno; portanto, ele pode ler os secrets injetados no próprio ambiente. Use essa conexão somente com o dataset público Olist e privilégios mínimos. Dados sensíveis exigem uma API centralizada, fora do Codespace.

## Roteiro de 130 minutos

- 15 min: abrir o Codespace, validar a API e os assistentes;
- 20 min: extrair o catálogo e discutir grãos, chaves, relações e fanout;
- 25 min: definir e reconciliar quatro métricas;
- 50 min: adaptar o dashboard D3 com controles e hierarquia de leitura;
- 10 min: auditar a crítica da IA e a linguagem causal;
- 10 min: completar os registros e entregar.

## Contratos disponíveis

- `GET /api/health`
- `GET /api/datasets/evolution?grain=day|week|month`
- `GET /api/datasets/distribution?bins=5..40`
- `GET /api/datasets/magnitude?top=5..20`
- `GET /api/datasets/relation?trimOutliers=true|false&limit=50..500`
- `POST /api/agent` com resumo validado; não existe endpoint de SQL livre.

## Diagnóstico

- `service_unavailable`: verifique conectividade e SSL do Railway; o fallback entra automaticamente quando habilitado.
- `invalid_parameters`: use apenas os valores indicados nos contratos.
- IA em `local_fallback`: configure a chave ou prossiga com o roteiro local.
- Porta não abriu: painel **Ports** → porta `3000` → **Open in Browser**.

## Testes

```bash
npm run test:lab:aula03
```

O endpoint da IA segue a [Responses API da documentação oficial da OpenAI](https://developers.openai.com/api/reference/typescript/resources/beta/subresources/responses/methods/create).
