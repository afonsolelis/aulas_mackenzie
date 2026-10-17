-- Aula 04 · Medir em vez de citar: o que o Parquet guarda e quanto a leitura economiza.
-- Uso: python sql/rodar_sql.py sql/08_parquet_inspecao.sql --var DATA=2026-10-27
-- Rode depois de 03 e 04 para pelo menos dois dias. Compare os números do seu ambiente
-- com os colegas e com os exemplos numéricos do material.

-- 1. Row groups, compressão e estatísticas min/max por coluna.
SELECT file_name, row_group_id, path_in_schema AS coluna, compression,
       stats_min, stats_max, total_compressed_size, total_uncompressed_size
FROM parquet_metadata('s3://silver/posicoes/data_local={{DATA}}/posicoes.parquet')
WHERE path_in_schema IN ('caminhao', 'velocidade_kmh', 'instante_utc', 'arquivo_origem');

-- 2. Esquema gravado no arquivo: tipos explícitos, sem inferência na leitura.
SELECT DISTINCT name, type, converted_type, logical_type
FROM parquet_schema('s3://silver/posicoes/data_local={{DATA}}/posicoes.parquet');

-- 3. A mesma pergunta (velocidade média em movimento por caminhão no dia D) em três camadas.
--    No plano, compare "HTTPFS HTTP Stats" (bytes e requisições) e "Total Time".
--    No TXT, cada lote é baixado e cada linha passa por expressão regular a cada consulta;
--    no JSON Lines do bronze, o arquivo inteiro é parseado; no Parquet, só as colunas pedidas
--    são lidas (Projections) e o filtro chega ao leitor (Filters).
EXPLAIN ANALYZE
SELECT caminhao, avg(v) AS velocidade_media_kmh
FROM (
    SELECT caminhao,
           CAST(coalesce(nullif(regexp_extract(linha, '\|VEL ([0-9]{3})\|', 1), ''),
                         nullif(regexp_extract(linha, ' v=([0-9]{1,3})', 1), '')) AS INTEGER) AS v
    FROM (
        SELECT caminhao, unnest(string_split(content, chr(10))) AS linha
        FROM read_text([
            's3://raw/telemetria/data={{DATA}}/hora=0[3-9]/*/*.txt',
            's3://raw/telemetria/data={{DATA}}/hora=1[0-9]/*/*.txt',
            's3://raw/telemetria/data={{DATA}}/hora=2[0-3]/*/*.txt',
            's3://raw/telemetria/data={{DATA_SEGUINTE}}/hora=0[0-2]/*/*.txt'
        ])
    )
)
WHERE v > 0
GROUP BY ALL;

EXPLAIN ANALYZE
SELECT caminhao, avg(CAST(velocidade_txt AS INTEGER)) AS velocidade_media_kmh
FROM read_json('s3://bronze/telemetria/data_local={{DATA}}/linhas.jsonl',
               format = 'newline_delimited',
               columns = {caminhao: 'VARCHAR', formato: 'INTEGER', velocidade_txt: 'VARCHAR'})
WHERE formato IN (1, 3) AND CAST(velocidade_txt AS INTEGER) > 0
GROUP BY ALL;

EXPLAIN ANALYZE
SELECT caminhao, avg(velocidade_kmh) AS velocidade_media_kmh
FROM read_parquet('s3://silver/posicoes/*/*.parquet')
WHERE data_local = DATE '{{DATA}}' AND velocidade_kmh > 0
GROUP BY ALL;

-- 4. Poda de partição no raw. O filtro na coluna de partição (data) descarta lotes,
--    mas o glob amplo ainda lista o bucket inteiro; um filtro em filename não descarta nada.
--    Compare #GET e "Total Time" com a leitura do caminho exato (consulta 3, primeira).
EXPLAIN ANALYZE
SELECT count(*) AS linhas
FROM (
    SELECT unnest(string_split(content, chr(10))) AS linha
    FROM read_text('s3://raw/telemetria/*/*/*/*.txt')
    WHERE data BETWEEN DATE '{{DATA}}' AND DATE '{{DATA_SEGUINTE}}'
);

-- 5. Poda de partição na silver: procure "Scanning Files: 1/N" no plano.
EXPLAIN
SELECT count(*)
FROM read_parquet('s3://silver/posicoes/*/*.parquet')
WHERE data_local = DATE '{{DATA}}';
