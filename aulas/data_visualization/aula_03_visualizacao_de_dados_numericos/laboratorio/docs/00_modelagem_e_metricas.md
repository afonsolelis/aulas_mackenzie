# Modelagem e contrato de métricas — Aula 03

Este documento vem antes do HTML. Preencha-o com base no catálogo extraído do banco e valide cada afirmação com SQL delimitado.

## 1. Leitura do modelo

| Objeto | Entidade ou processo | Grão de uma linha | Chave candidata | Relacionamentos | Evidência executada |
|---|---|---|---|---|---|
| | | | | | |

## 2. Perguntas de modelagem

- Qual diferença existe entre `customer_id` e `customer_unique_id`?
- Uma linha de pedido, item e pagamento representa o mesmo grão?
- Qual junção pode multiplicar preço, frete ou pagamento?
- Quais dimensões da Aula 02 podem ser reutilizadas?
- Quais datas autorizam análises de compra, aprovação, envio, entrega e atraso?

## 3. Contrato de métricas

| Métrica | Pergunta de negócio | Fórmula | Grão | Filtros | Denominador | Unidade | Teste de reconciliação | Limitação |
|---|---|---|---|---|---|---|---|---|
| Pedidos entregues | Como o volume evoluiu? | `COUNT(DISTINCT order_id)` | pedido | `order_status = 'delivered'` | — | pedidos | comparar com `olist_orders` | pontas temporais incompletas |
| Ticket de item | Como os preços se distribuem? | mediana de `price` | item do pedido | `price IS NOT NULL` | — | R$ | comparar N e percentis | não representa total do pedido |
| Faturamento por categoria | Quais categorias concentram valor? | `SUM(price)` | item do pedido | categoria tratada | — | R$ | reconciliar soma total | Top N oculta cauda |
| Preço × frete | Há associação entre valores? | pares `price`, `freight_value` | item do pedido | valores válidos | — | R$ × R$ | comparar com/sem P95 | associação não demonstra causa |

## 4. Prompt para discutir o modelo com Copilot ou OpenCode

Anexe ou referencie `docs/00_catalogo_banco.md` e use:

> Atue como revisor de modelagem, não como executor autônomo. Com base apenas no catálogo fornecido, proponha entidades, grãos, chaves candidatas e relacionamentos. Para cada afirmação, classifique-a como evidência do catálogo ou hipótese a validar. Identifique riscos de fanout. Depois proponha métricas com fórmula, grão, filtros, denominador, unidade e teste de reconciliação. Não invente colunas, não solicite credenciais e não gere alterações destrutivas no banco.

## 5. Decisões aceitas e rejeitadas

| Sugestão da IA | Evidência consultada | Decisão humana | Motivo |
|---|---|---|---|
| | | aceitar / rejeitar / adaptar | |

## 6. Contrato do dashboard

- Público e decisão apoiada:
- Quatro métricas aprovadas:
- Filtros compartilhados:
- Ordem de leitura:
- Visual escolhido para cada pergunta:
- Afirmações que o dashboard não autoriza:
- Critério de pronto antes de editar HTML:
