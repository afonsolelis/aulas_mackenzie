-- Banco afonso · Fato de pedidos por região do cliente.
-- Pergunta: qual a diferença de pedidos entre Norte e Nordeste e qual o ticket médio de cada região?
-- Grão: um pedido. A região vem da UF do cliente (dim_cliente) e o valor vem do que foi pago (fato_pagamento).
-- A tabela é reconstruída inteira pela view materializada refreshable, uma vez por dia.
-- Para rodar agora: SYSTEM REFRESH VIEW afonso.rmv_fato_pedido_regiao; SYSTEM WAIT VIEW afonso.rmv_fato_pedido_regiao;

CREATE TABLE IF NOT EXISTS afonso.fato_pedido_regiao
(
    order_id          String,
    customer_id       String,
    data_compra_key   UInt32,
    status            LowCardinality(String),
    uf_cliente        LowCardinality(String),
    regiao            LowCardinality(String),
    qtd_itens         UInt32,
    valor_produtos    Decimal(18, 2),
    valor_frete       Decimal(18, 2),
    valor_pedido      Decimal(18, 2),   -- produtos + frete
    valor_pago        Decimal(18, 2)    -- soma dos pagamentos; base do ticket médio
)
ENGINE = MergeTree
ORDER BY (regiao, uf_cliente, order_id);

CREATE MATERIALIZED VIEW IF NOT EXISTS afonso.rmv_fato_pedido_regiao
REFRESH EVERY 1 DAY OFFSET 1 HOUR          -- todo dia à 01h00 UTC (22h00 em Brasília)
TO afonso.fato_pedido_regiao AS
WITH itens AS
(
    SELECT order_id,
           toUInt32(count())  AS qtd_itens,
           sum(preco)         AS valor_produtos,
           sum(frete)         AS valor_frete
    FROM afonso.fato_item_pedido FINAL
    GROUP BY order_id
),
pagamentos AS
(
    SELECT order_id, sum(valor) AS valor_pago
    FROM afonso.fato_pagamento FINAL
    GROUP BY order_id
)
SELECT p.order_id                                   AS order_id,
       p.customer_id                                AS customer_id,
       p.data_compra_key                            AS data_compra_key,
       p.status                                     AS status,
       c.uf                                         AS uf_cliente,
       multiIf(c.uf IN ('AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO'),                   'Norte',
               c.uf IN ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE'),       'Nordeste',
               c.uf IN ('DF', 'GO', 'MT', 'MS'),                                     'Centro-Oeste',
               c.uf IN ('ES', 'MG', 'RJ', 'SP'),                                     'Sudeste',
               c.uf IN ('PR', 'RS', 'SC'),                                           'Sul',
               'Sem UF')                            AS regiao,
       i.qtd_itens                                  AS qtd_itens,
       toDecimal128(i.valor_produtos, 2)            AS valor_produtos,
       toDecimal128(i.valor_frete, 2)               AS valor_frete,
       toDecimal128(i.valor_produtos + i.valor_frete, 2) AS valor_pedido,
       toDecimal128(pg.valor_pago, 2)               AS valor_pago
FROM afonso.fato_pedido AS p FINAL
LEFT JOIN (SELECT customer_id, uf FROM afonso.dim_cliente FINAL) AS c ON c.customer_id = p.customer_id
LEFT JOIN itens      AS i  ON i.order_id  = p.order_id
LEFT JOIN pagamentos AS pg ON pg.order_id = p.order_id;

-- ---------------------------------------------------------------------------
-- Resposta: pedidos e ticket médio no Norte e no Nordeste, e a diferença entre eles.
-- ---------------------------------------------------------------------------
-- SELECT
--     countIf(regiao = 'Nordeste')                                        AS pedidos_nordeste,
--     countIf(regiao = 'Norte')                                           AS pedidos_norte,
--     countIf(regiao = 'Nordeste') - countIf(regiao = 'Norte')            AS diferenca_pedidos,
--     round(avgIf(valor_pago, regiao = 'Nordeste'), 2)                    AS ticket_medio_nordeste,
--     round(avgIf(valor_pago, regiao = 'Norte'), 2)                       AS ticket_medio_norte
-- FROM afonso.fato_pedido_regiao;
