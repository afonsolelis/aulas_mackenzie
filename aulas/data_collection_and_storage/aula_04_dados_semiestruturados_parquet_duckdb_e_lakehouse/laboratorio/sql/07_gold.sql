-- Aula 04 · Gold: tabelas prontas para consumo, recalculadas a partir da silver.
-- Uso: python sql/rodar_sql.py sql/07_gold.sql
-- O gold é pequeno e é refeito por inteiro a cada execução (um objeto por tabela),
-- o que torna a reexecução idempotente sem controle de estado.

-- 1. Jornada diária por caminhão: horas de direção, velocidade, quilometragem e alertas.
--    Grão: uma linha por caminhão e dia no horário de Brasília.
--    A silver tem uma posição por minuto: minutos com velocidade acima de zero viram
--    horas de direção, e a soma das velocidades dividida por 60 aproxima os quilômetros
--    (cada posição vale um minuto). Caminhões com firmware novo não informam o tempo de
--    direção contínua na linha de posição; para eles, o máximo vem só dos alertas.
COPY (
    WITH posicoes AS (
        SELECT
            caminhao,
            data_local,
            count(*)                                                  AS minutos_com_posicao,
            count(*) FILTER (WHERE velocidade_kmh > 0)                AS minutos_em_movimento,
            avg(velocidade_kmh) FILTER (WHERE velocidade_kmh > 0)     AS velocidade_media_kmh,
            sum(velocidade_kmh) / 60.0                                AS km_aproximados,
            max(direcao_continua_min)                                 AS maior_tac_mot_min
        FROM read_parquet('s3://silver/posicoes/*/*.parquet')
        GROUP BY caminhao, data_local
    ),
    alertas AS (
        SELECT
            caminhao,
            data_local,
            count(*) FILTER (WHERE acima_de_5h30)                     AS alertas_acima_5h30,
            max(direcao_continua_min)                                 AS maior_alerta_min
        FROM read_parquet('s3://silver/alertas_tacografo/*/*.parquet')
        GROUP BY caminhao, data_local
    )
    SELECT
        p.caminhao,
        p.data_local,
        p.minutos_com_posicao,
        round(p.minutos_em_movimento / 60.0, 2)                       AS horas_direcao,
        round(p.velocidade_media_kmh, 1)                              AS velocidade_media_kmh,
        round(p.km_aproximados, 1)                                    AS km_aproximados,
        greatest(p.maior_tac_mot_min, a.maior_alerta_min)             AS maior_direcao_continua_min,
        coalesce(a.alertas_acima_5h30, 0)                             AS alertas_acima_5h30
    FROM posicoes AS p
    LEFT JOIN alertas AS a USING (caminhao, data_local)
    ORDER BY p.data_local, p.caminhao
) TO 's3://gold/jornada_caminhao_diaria/jornada_caminhao_diaria.parquet' (FORMAT parquet);

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
SELECT * FROM read_parquet('s3://gold/jornada_caminhao_diaria/*.parquet')
ORDER BY alertas_acima_5h30 DESC, horas_direcao DESC
LIMIT 10;
SELECT * FROM read_parquet('s3://gold/livro_preco_brl_diario/*.parquet') LIMIT 10;
