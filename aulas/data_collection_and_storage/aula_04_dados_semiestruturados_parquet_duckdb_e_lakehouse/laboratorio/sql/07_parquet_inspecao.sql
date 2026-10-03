-- Aula 04 · Medir em vez de citar: o que o Parquet guarda e quanto a leitura economiza.
-- Uso: python sql/rodar_sql.py sql/07_parquet_inspecao.sql --var DATA=2026-10-31
-- Rode depois de 03_silver_clima.sql. Compare os números do seu ambiente com os colegas.

-- 1. Row groups, compressão e estatísticas min/max por coluna.
SELECT file_name, row_group_id, path_in_schema AS coluna, compression,
       stats_min, stats_max, total_compressed_size, total_uncompressed_size
FROM parquet_metadata('s3://silver/clima/*/*.parquet')
WHERE path_in_schema IN ('temperatura_c', 'cidade', 'horario_local');

-- 2. Esquema gravado no arquivo: tipos explícitos, sem inferência na leitura.
SELECT DISTINCT name, type, converted_type
FROM parquet_schema('s3://silver/clima/*/*.parquet');

-- 3. A mesma pergunta sobre o JSON bruto e sobre o Parquet.
--    No plano, compare "HTTPFS HTTP Stats" (bytes e requisições) e "Total Time".
--    No Parquet, só as colunas pedidas são lidas (Projections) e o filtro
--    chega ao leitor (Filters); no JSON, cada arquivo é baixado e parseado inteiro.
EXPLAIN ANALYZE
SELECT cidade, avg(t)
FROM (
    SELECT regexp_extract(filename, '([^/]+)\.json$', 1) AS cidade,
           unnest(hourly.temperature_2m) AS t
    FROM read_json_auto('s3://raw/open_meteo/*/*/*.json', filename = true)
)
WHERE t > 20
GROUP BY ALL;

EXPLAIN ANALYZE
SELECT cidade, avg(temperatura_c)
FROM read_parquet('s3://silver/clima/*/*.parquet', hive_partitioning = true)
WHERE temperatura_c > 20
GROUP BY ALL;

-- 4. Poda de partição: filtrar pela coluna de partição evita abrir as outras datas.
--    Procure "Scanning Files: 1/N" no plano.
EXPLAIN
SELECT count(*)
FROM read_parquet('s3://silver/clima/*/*.parquet', hive_partitioning = true)
WHERE data = DATE '{{DATA}}';
