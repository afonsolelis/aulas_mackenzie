-- Aula 04 · Silver: livros tipados e deduplicados, uma partição por data de coleta.
-- Uso: python sql/rodar_sql.py sql/05_silver_livros.sql --var DATA=2026-10-24
-- Fonte: bronze da Aula 03, s3://bronze/books_toscrape/data=D/livros.jsonl,
--   extraído das páginas de detalhe; chave natural upc.
-- Contrato combinado com a Aula 05: s3://silver/livros/data_coleta=D/ com upc, url, titulo,
-- categoria, avaliacao, preco_gbp, em_estoque, qtd_estoque, coletado_em,
-- mais arquivo_origem e processado_em. data_coleta vem do caminho (hive).

-- coletado_em sem deslocamento explícito é interpretado no horário de Brasília.
SET TimeZone = 'America/Sao_Paulo';

COPY (
    SELECT
        upc,
        url,
        titulo,
        categoria,
        CAST(avaliacao AS TINYINT)               AS avaliacao,
        CAST(preco_gbp AS DECIMAL(10, 2))        AS preco_gbp,
        em_estoque,
        CAST(qtd_estoque AS INTEGER)             AS qtd_estoque,
        -- lido como texto: a conversão respeita o deslocamento -03:00 gravado pela Aula 03
        CAST(coletado_em AS TIMESTAMPTZ)         AS coletado_em,
        filename                                 AS arquivo_origem,
        now()                                    AS processado_em
    FROM read_json(
        's3://bronze/books_toscrape/data={{DATA}}/*.jsonl',
        format = 'newline_delimited',
        filename = true,
        -- esquema declarado na leitura: campos fora do contrato (chave_origem) são ignorados
        columns = {
            upc: 'VARCHAR', url: 'VARCHAR', titulo: 'VARCHAR', categoria: 'VARCHAR',
            avaliacao: 'BIGINT', preco_gbp: 'DOUBLE', em_estoque: 'BOOLEAN',
            qtd_estoque: 'BIGINT', coletado_em: 'VARCHAR'
        }
    )
    -- reexecução da Aula 03 no mesmo dia pode repetir um livro: fica a coleta mais recente
    QUALIFY row_number() OVER (PARTITION BY upc ORDER BY CAST(coletado_em AS TIMESTAMPTZ) DESC) = 1
    ORDER BY upc
) TO 's3://silver/livros/data_coleta={{DATA}}/livros.parquet' (FORMAT parquet, COMPRESSION zstd);

SELECT data_coleta, count(*) AS livros, count(DISTINCT upc) AS upcs,
       min(preco_gbp) AS menor, max(preco_gbp) AS maior,
       min(coletado_em) AS primeira_coleta,
       count(*) FILTER (WHERE arquivo_origem IS NULL) AS sem_origem
FROM read_parquet('s3://silver/livros/data_coleta={{DATA}}/*.parquet', hive_partitioning = true)
GROUP BY data_coleta;
