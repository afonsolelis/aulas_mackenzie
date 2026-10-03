-- Aula 04 · Silver: clima tipado, deduplicado e com origem, uma partição por data.
-- Uso: python sql/rodar_sql.py sql/03_silver_clima.sql --var DATA=2026-10-31
-- Grão da silver: uma linha por cidade e hora prevista, com a previsão mais recente.
-- A partição do raw é a data da coleta em UTC; os horários previstos estão no horário
-- de Brasília. Coletas feitas entre 0h e 3h UTC de D+1 ainda falam do dia D local,
-- por isso a leitura cobre as partições D e D+1 e o filtro final fica no horário previsto.
-- Idempotência: o destino é um único objeto com nome fixo por data.
-- Reprocessar a mesma data substitui o objeto (PUT na mesma chave) em vez de somar arquivos.

COPY (
    WITH linhas AS (
        SELECT
            regexp_extract(filename, '([^/]+)\.json$', 1) AS cidade,
            CAST(data AS DATE)                            AS data_coleta,
            CAST(hora AS INTEGER)                         AS hora_coleta,
            timezone                                      AS fuso,
            CAST(latitude AS DOUBLE)                      AS latitude,
            CAST(longitude AS DOUBLE)                     AS longitude,
            unnest(hourly.time)                           AS horario_txt,
            unnest(hourly.temperature_2m)                 AS temperatura,
            unnest(hourly.relative_humidity_2m)           AS umidade,
            filename                                      AS arquivo_origem
        FROM read_json_auto(
            's3://raw/open_meteo/*/*/*.json',
            filename = true,
            hive_partitioning = true,
            union_by_name = true
        )
        -- filtro na coluna de partição: o DuckDB descarta os arquivos das outras datas
        WHERE data BETWEEN DATE '{{DATA}}' AND DATE '{{DATA}}' + INTERVAL 1 DAY
    )
    SELECT
        cidade,
        CAST(CAST(horario_txt AS TIMESTAMP) AS DATE) AS data,
        CAST(horario_txt AS TIMESTAMP)               AS horario_local,
        fuso,
        CAST(temperatura AS DOUBLE)                  AS temperatura_c,
        CAST(umidade AS INTEGER)                     AS umidade_pct,
        latitude,
        longitude,
        data_coleta,
        hora_coleta,
        arquivo_origem,
        now()                                        AS processado_em
    FROM linhas
    WHERE CAST(CAST(horario_txt AS TIMESTAMP) AS DATE) = DATE '{{DATA}}'
    -- Cada coleta horária repete as 24 horas do dia: fica a coleta mais recente.
    QUALIFY row_number() OVER (
        PARTITION BY cidade, horario_local
        ORDER BY data_coleta DESC, hora_coleta DESC
    ) = 1
) TO 's3://silver/clima/data={{DATA}}/clima.parquet' (FORMAT parquet, COMPRESSION zstd);

-- Conferência: linhas, cidades e período gravados (esperado: 24 linhas por cidade).
SELECT cidade, count(*) AS linhas, min(horario_local) AS primeiro, max(horario_local) AS ultimo,
       max(hora_coleta) AS coleta_usada
FROM read_parquet('s3://silver/clima/data={{DATA}}/*.parquet')
GROUP BY cidade
ORDER BY cidade;
