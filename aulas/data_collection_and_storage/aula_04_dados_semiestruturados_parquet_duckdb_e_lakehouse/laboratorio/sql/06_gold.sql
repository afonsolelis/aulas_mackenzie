-- Aula 04 · Gold: tabelas prontas para consumo, recalculadas a partir da silver.
-- Uso: python sql/rodar_sql.py sql/06_gold.sql
-- O gold é pequeno e é refeito por inteiro a cada execução (um objeto por tabela),
-- o que torna a reexecução idempotente sem controle de estado.

-- 1. Temperatura média diária por capital (média das 24 horas da previsão mais recente).
COPY (
    SELECT
        cidade,
        data,
        round(avg(temperatura_c), 2)  AS temperatura_media_c,
        min(temperatura_c)            AS temperatura_min_c,
        max(temperatura_c)            AS temperatura_max_c,
        count(*)                      AS horas_com_previsao
    FROM read_parquet('s3://silver/clima/*/*.parquet', hive_partitioning = true)
    GROUP BY cidade, data
    ORDER BY data, cidade
) TO 's3://gold/clima_media_diaria/clima_media_diaria.parquet' (FORMAT parquet);

-- 2. Preço do livro em BRL por dia de coleta.
--    Cotação: o último boletim de fechamento com data menor ou igual à da coleta.
--    A PTAX não sai em fim de semana e feriado; a coleta de sábado usa o fechamento de sexta.
--    A consulta de um dia (CotacaoMoedaDia) rotula o fechamento como 'Fechamento PTAX';
--    a de período (CotacaoMoedaPeriodo), como 'Fechamento'. Os dois contam.
COPY (
    WITH fechamento AS (
        SELECT CAST(data_hora_cotacao AS DATE) AS data_ptax, cotacao_venda, tipo_boletim
        FROM read_parquet('s3://silver/ptax/*.parquet')
        WHERE moeda = 'GBP' AND tipo_boletim IN ('Fechamento PTAX', 'Fechamento')
        QUALIFY row_number() OVER (
            PARTITION BY CAST(data_hora_cotacao AS DATE) ORDER BY data_hora_cotacao DESC
        ) = 1
    )
    SELECT
        l.data_coleta,
        l.upc,
        l.titulo,
        l.preco_gbp,
        p.data_ptax,
        p.cotacao_venda                                        AS ptax_venda_gbp_brl,
        CAST(l.preco_gbp * p.cotacao_venda AS DECIMAL(12, 2))  AS preco_brl
    FROM read_parquet('s3://silver/livros/*/*.parquet', hive_partitioning = true) AS l
    ASOF JOIN fechamento AS p ON l.data_coleta >= p.data_ptax
    ORDER BY l.data_coleta, l.upc
) TO 's3://gold/livro_preco_brl_diario/livro_preco_brl_diario.parquet' (FORMAT parquet);

-- Conferência rápida das duas tabelas.
SELECT * FROM read_parquet('s3://gold/clima_media_diaria/*.parquet') LIMIT 10;
SELECT * FROM read_parquet('s3://gold/livro_preco_brl_diario/*.parquet') LIMIT 10;
