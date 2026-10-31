-- Aula 04 · JSON cast no DuckDB, lendo o histórico do lake (Parquet no MinIO).
-- Uso: python sql/rodar_sql.py sql/duckdb_cast.sql
-- Layout: s3://raw/ingestao/data_tag=X/data=AAAA-MM-DD/lote_<ts>_<id>.parquet
-- Cada arquivo tem timestamp (UBIGINT, unix ms) e data_json (VARCHAR).
-- data_tag e data vêm do caminho (hive_partitioning).

-- 1. Linhas por domínio e por dia no lake (gate da Etapa 09).
SELECT data_tag, data, count(*) AS linhas, count(DISTINCT filename) AS arquivos
FROM read_parquet('s3://raw/ingestao/*/*/*.parquet', hive_partitioning = true, filename = true)
GROUP BY ALL
ORDER BY ALL;

-- 2. Livros: preço médio por categoria com o operador ->> (devolve VARCHAR) e CAST explícito.
SELECT data_json ->> 'categoria'                                   AS categoria,
       count(*)                                                    AS livros,
       round(avg(CAST(data_json ->> 'preco_gbp' AS DECIMAL(10, 2))), 2) AS preco_medio_gbp
FROM read_parquet('s3://raw/ingestao/data_tag=livros/*/*.parquet', hive_partitioning = true)
GROUP BY ALL
ORDER BY livros DESC, categoria
LIMIT 10;

-- 3. A mesma conta com json_extract_string / json_extract (caminho JSONPath).
SELECT json_extract_string(data_json, '$.categoria')               AS categoria,
       round(avg(json_extract(data_json, '$.preco_gbp')::DOUBLE), 2) AS preco_medio_gbp
FROM read_parquet('s3://raw/ingestao/data_tag=livros/*/*.parquet', hive_partitioning = true)
GROUP BY ALL
ORDER BY categoria
LIMIT 5;

-- 4. Estrutura declarada: from_json devolve um STRUCT tipado; campos fora da estrutura somem.
SELECT l.categoria, round(avg(l.preco_gbp), 2) AS preco_medio_gbp, sum(l.qtd_estoque) AS estoque
FROM (
    SELECT from_json(data_json, '{"categoria":"VARCHAR","preco_gbp":"DECIMAL(10,2)","qtd_estoque":"INTEGER"}') AS l
    FROM read_parquet('s3://raw/ingestao/data_tag=livros/*/*.parquet', hive_partitioning = true)
)
GROUP BY ALL
ORDER BY estoque DESC
LIMIT 5;

-- 5. PTAX: cotação de venda média por tipo de boletim.
SELECT data_json ->> 'tipoBoletim'                                       AS tipo_boletim,
       count(*)                                                          AS boletins,
       round(avg(CAST(data_json ->> 'cotacaoVenda' AS DECIMAL(12, 5))), 5) AS venda_media
FROM read_parquet('s3://raw/ingestao/data_tag=ptax/*/*.parquet', hive_partitioning = true)
GROUP BY ALL
ORDER BY ALL;

-- 6. Telemetria: data_json só tem a linha de texto. O caminhão sai por expressão regular;
--    linhas sem caminhão (#RADIO, ERR SAT) ficam com caminhao vazio.
SELECT nullif(regexp_extract(data_json ->> 'linha', 'CAM-[0-9]{4}'), '') AS caminhao,
       count(*) AS linhas
FROM read_parquet('s3://raw/ingestao/data_tag=telemetria/*/*.parquet', hive_partitioning = true)
GROUP BY ALL
ORDER BY linhas DESC
LIMIT 5;

-- 7. Duplicatas (entrega pelo menos uma vez): o mesmo data_json no mesmo timestamp.
SELECT data_tag, count(*) AS linhas, count(DISTINCT (timestamp, data_json)) AS distintas
FROM read_parquet('s3://raw/ingestao/*/*/*.parquet', hive_partitioning = true)
GROUP BY ALL
ORDER BY ALL;
