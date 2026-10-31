-- Aula 04 · JSON cast no ClickHouse, sobre ingestao.db_ingestion.
-- Uso: docker compose exec -T clickhouse clickhouse-client --user "$CLICKHOUSE_USER" \
--        --password "$CLICKHOUSE_PASSWORD" --time --multiquery < sql/clickhouse_cast.sql

-- 1. Linhas por domínio (gate da Etapa 09) e o intervalo de ingestão em hora legível.
SELECT data_tag, count() AS linhas,
       fromUnixTimestamp64Milli(toInt64(min(timestamp)), 'America/Sao_Paulo') AS primeira,
       fromUnixTimestamp64Milli(toInt64(max(timestamp)), 'America/Sao_Paulo') AS ultima
FROM ingestao.db_ingestion
GROUP BY data_tag
ORDER BY data_tag;

-- 2. Livros: preço médio por categoria com JSONExtract* (lê o texto a cada consulta).
SELECT JSONExtractString(data_json, 'categoria')           AS categoria,
       count()                                             AS livros,
       round(avg(JSONExtractFloat(data_json, 'preco_gbp')), 2) AS preco_medio_gbp
FROM ingestao.db_ingestion
WHERE data_tag = 'livros'          -- primeira coluna do ORDER BY: lê só os grânulos de livros
GROUP BY categoria
ORDER BY livros DESC, categoria
LIMIT 10;

-- 3. A mesma conta com simpleJSONExtract* (mais rápido, supõe JSON simples e sem espaços).
SELECT simpleJSONExtractString(data_json, 'categoria')         AS categoria,
       round(avg(simpleJSONExtractFloat(data_json, 'preco_gbp')), 2) AS preco_medio_gbp
FROM ingestao.db_ingestion
WHERE data_tag = 'livros'
GROUP BY categoria
ORDER BY categoria
LIMIT 5;

-- 4. CAST para o tipo JSON e acesso por caminho. O valor sai como Dynamic: converta para somar.
SELECT CAST(data_json AS JSON).categoria::String                     AS categoria,
       round(avg(toDecimal64(CAST(data_json AS JSON).preco_gbp::String, 2)), 2) AS preco_medio_gbp
FROM ingestao.db_ingestion
WHERE data_tag = 'livros'
GROUP BY categoria
ORDER BY categoria
LIMIT 5;

-- 5. PTAX: venda média por tipo de boletim.
SELECT JSONExtractString(data_json, 'tipoBoletim')               AS tipo_boletim,
       count()                                                   AS boletins,
       round(avg(JSONExtractFloat(data_json, 'cotacaoVenda')), 5) AS venda_media
FROM ingestao.db_ingestion
WHERE data_tag = 'ptax'
GROUP BY tipo_boletim
ORDER BY tipo_boletim;

-- 6. Telemetria: caminhão extraído da linha de texto por expressão regular.
SELECT nullIf(extract(JSONExtractString(data_json, 'linha'), 'CAM-[0-9]{4}'), '') AS caminhao,
       count() AS linhas
FROM ingestao.db_ingestion
WHERE data_tag = 'telemetria'
GROUP BY caminhao
ORDER BY linhas DESC
LIMIT 5;

-- 7. Duplicatas: o par (timestamp, data_json) repetido indica reentrega.
SELECT data_tag, count() AS linhas, uniqExact(timestamp, data_json) AS distintas
FROM ingestao.db_ingestion
GROUP BY data_tag
ORDER BY data_tag;

-- 8. Partes e compressão da tabela (micro-lote e tamanho).
SELECT count() AS partes_ativas, sum(rows) AS linhas,
       formatReadableSize(sum(data_compressed_bytes))   AS comprimido,
       formatReadableSize(sum(data_uncompressed_bytes)) AS descomprimido
FROM system.parts
WHERE database = 'ingestao' AND table = 'db_ingestion' AND active;
