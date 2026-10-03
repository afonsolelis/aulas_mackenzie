-- Aula 05 · Staging: leitura do silver da Aula 04 no MinIO (schema on read)
-- Pré-requisitos, executados pelo carregador antes deste arquivo:
--   INSTALL httpfs; LOAD httpfs;
--   CREATE OR REPLACE SECRET minio (TYPE s3, KEY_ID '...', SECRET '...',
--       ENDPOINT 'host:porta', URL_STYLE 'path', USE_SSL true|false, REGION 'us-east-1');
--   SET VARIABLE data_ref      = DATE '2026-11-07';
--   SET VARIABLE execucao_id   = '2026-11-07T09:00:00Z';
--   SET VARIABLE silver_livros = 's3://silver/livros/*/*.parquet';
--   SET VARIABLE silver_ptax   = 's3://silver/ptax/*.parquet';
-- As credenciais vêm de variáveis de ambiente lidas pelo carregador, nunca deste arquivo.
--
-- Contrato do silver gravado pela Aula 04 (confira com o que o seu grupo gravou e
-- ajuste os nomes aqui, em um só lugar):
--   livros: s3://silver/livros/data_coleta=AAAA-MM-DD/livros.parquet com upc, url,
--           titulo, categoria, avaliacao, preco_gbp, em_estoque, qtd_estoque,
--           coletado_em (TIMESTAMPTZ); data_coleta existe só no caminho (hive)
--   ptax:   s3://silver/ptax/ptax.parquet (um objeto, recalculado inteiro) com moeda,
--           data_hora_cotacao (horário de Brasília, sem fuso), tipo_boletim,
--           cotacao_compra, cotacao_venda
--   As duas trazem ainda arquivo_origem e processado_em (rastreabilidade), que
--   esta staging não usa.

CREATE OR REPLACE VIEW stg_livro_dia AS
SELECT
    CAST(upc AS VARCHAR)            AS upc,
    CAST(url AS VARCHAR)            AS url,
    trim(CAST(titulo AS VARCHAR))   AS titulo,
    trim(CAST(categoria AS VARCHAR)) AS categoria,
    CAST(avaliacao AS TINYINT)      AS avaliacao,
    CAST(preco_gbp AS DECIMAL(10,2)) AS preco_gbp,
    CAST(em_estoque AS BOOLEAN)     AS em_estoque,
    CAST(qtd_estoque AS INTEGER)    AS qtd_estoque,
    CAST(coletado_em AS TIMESTAMP)  AS coletado_em,
    CAST(data_coleta AS DATE)       AS data_coleta
FROM read_parquet(getvariable('silver_livros'), hive_partitioning = true)
WHERE CAST(data_coleta AS DATE) = getvariable('data_ref');

-- Uma linha por livro no dia: se houve duas coletas, vale a mais recente.
-- Linhas sem chave natural ou sem preço ficam fora e são contadas no relatório.
CREATE OR REPLACE VIEW stg_livro_dia_unico AS
SELECT
    upc,
    arg_max(url, coletado_em)        AS url,
    arg_max(titulo, coletado_em)     AS titulo,
    arg_max(categoria, coletado_em)  AS categoria,
    arg_max(avaliacao, coletado_em)  AS avaliacao,
    arg_max(preco_gbp, coletado_em)  AS preco_gbp,
    arg_max(qtd_estoque, coletado_em) AS qtd_estoque,
    max(coletado_em)                 AS coletado_em,
    any_value(data_coleta)           AS data_coleta,
    md5(concat_ws('|', arg_max(titulo, coletado_em), arg_max(categoria, coletado_em))) AS hash_scd2
FROM stg_livro_dia
WHERE upc IS NOT NULL AND preco_gbp IS NOT NULL AND categoria IS NOT NULL
GROUP BY upc;

-- Cotação de fechamento GBP. Confira o texto real de tipo_boletim no silver.
CREATE OR REPLACE VIEW stg_cotacao_fechamento AS
SELECT
    CAST(data_hora_cotacao AS DATE)       AS data_cotacao,
    CAST(moeda AS VARCHAR)                AS moeda,
    arg_max(CAST(cotacao_compra AS DECIMAL(12,6)), data_hora_cotacao) AS cotacao_compra,
    arg_max(CAST(cotacao_venda  AS DECIMAL(12,6)), data_hora_cotacao) AS cotacao_venda
FROM read_parquet(getvariable('silver_ptax'), hive_partitioning = true)
WHERE moeda = 'GBP' AND tipo_boletim ILIKE 'Fechamento%'
GROUP BY 1, 2;
