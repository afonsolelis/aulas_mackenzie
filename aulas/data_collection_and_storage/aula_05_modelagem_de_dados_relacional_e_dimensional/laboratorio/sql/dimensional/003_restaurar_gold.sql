-- Aula 05 · Restaura o estado da gold a partir do MinIO
-- O estado persistente do modelo dimensional mora no MinIO; o arquivo .duckdb é descartável
-- (no Railway, o contêiner do cron começa vazio a cada execução).
-- Pule este arquivo na primeira execução, quando ainda não há Parquet na gold.
-- Pré-requisito: SET VARIABLE gold_prefix = 's3://gold/dimensional/';

BEGIN TRANSACTION;

DELETE FROM gold.dim_categoria;
INSERT INTO gold.dim_categoria
SELECT * FROM read_parquet(getvariable('gold_prefix') || 'dim_categoria.parquet');

DELETE FROM gold.dim_livro;
INSERT INTO gold.dim_livro
SELECT * FROM read_parquet(getvariable('gold_prefix') || 'dim_livro.parquet');

DELETE FROM gold.fato_preco_diario;
INSERT INTO gold.fato_preco_diario
SELECT * FROM read_parquet(getvariable('gold_prefix') || 'fato_preco_diario.parquet');

DELETE FROM gold.fato_cotacao_diaria;
INSERT INTO gold.fato_cotacao_diaria
SELECT * FROM read_parquet(getvariable('gold_prefix') || 'fato_cotacao_diaria.parquet');

COMMIT;
