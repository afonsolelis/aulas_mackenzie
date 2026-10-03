-- Aula 05 · Carga idempotente dos fatos para o dia getvariable('data_ref')
-- Estratégia: apaga a partição do dia e insere de novo, na mesma transação.
-- Reexecutar o dia produz exatamente as mesmas linhas.

BEGIN TRANSACTION;

DELETE FROM gold.fato_preco_diario
WHERE data_coleta_sk = CAST(strftime(getvariable('data_ref'), '%Y%m%d') AS INTEGER);

INSERT INTO gold.fato_preco_diario
WITH cot AS (
    SELECT data_cotacao, cotacao_venda FROM stg_cotacao_fechamento
)
SELECT
    CAST(strftime(s.data_coleta, '%Y%m%d') AS INTEGER)     AS data_coleta_sk,
    d.livro_sk,
    c.categoria_sk,
    m.moeda_sk,
    CAST(strftime(cot.data_cotacao, '%Y%m%d') AS INTEGER)  AS data_cotacao_sk,
    getvariable('execucao_id')                             AS execucao_id,
    s.preco_gbp,
    cot.cotacao_venda,
    round(s.preco_gbp * cot.cotacao_venda, 2)              AS preco_brl,
    s.qtd_estoque,
    1                                                      AS qtd_observacoes
FROM stg_livro_dia_unico s
JOIN gold.dim_livro d
  ON d.upc = s.upc
 AND s.data_coleta BETWEEN d.valido_de AND d.valido_ate
JOIN gold.dim_categoria c ON c.categoria_nome = s.categoria
JOIN gold.dim_moeda m     ON m.codigo = 'GBP'
-- ASOF: última cotação de fechamento com data <= data da coleta
-- (sábado, domingo e feriado usam o último dia útil anterior).
ASOF LEFT JOIN cot ON s.data_coleta >= cot.data_cotacao;

-- fato_cotacao_diaria: regrava todas as cotações lidas do silver (volume pequeno).
DELETE FROM gold.fato_cotacao_diaria
WHERE data_sk IN (
    SELECT CAST(strftime(data_cotacao, '%Y%m%d') AS INTEGER) FROM stg_cotacao_fechamento
);

INSERT INTO gold.fato_cotacao_diaria
SELECT
    CAST(strftime(f.data_cotacao, '%Y%m%d') AS INTEGER),
    m.moeda_sk,
    f.cotacao_compra,
    f.cotacao_venda
FROM stg_cotacao_fechamento f
JOIN gold.dim_moeda m ON m.codigo = f.moeda;

COMMIT;
