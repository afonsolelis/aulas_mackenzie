-- Aula 04 · Tabela de pouso da ingestão no ClickHouse.
-- Executado pelo contêiner na primeira subida (docker-entrypoint-initdb.d).
-- Três colunas: hora da ingestão, o dado como texto JSON e o domínio.
CREATE DATABASE IF NOT EXISTS ingestao;

CREATE TABLE IF NOT EXISTS ingestao.db_ingestion
(
    timestamp UInt64,                  -- unix em milissegundos, hora da ingestão (dada pelo servidor)
    data_json String,                  -- o dado recebido, como texto JSON, sem alteração
    data_tag  LowCardinality(String)   -- o domínio: telemetria, livros, ptax
)
ENGINE = MergeTree
-- uma partição por mês da ingestão
PARTITION BY toYYYYMM(fromUnixTimestamp64Milli(toInt64(timestamp)))
-- índice esparso: filtros por data_tag e por intervalo de tempo leem poucos grânulos
ORDER BY (data_tag, timestamp);
