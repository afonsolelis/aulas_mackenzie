-- Aula 04 · Silver: boletins PTAX tipados, um por linha, sem repetição.
-- Uso: python sql/rodar_sql.py sql/04_silver_ptax.sql
-- Fonte: bronze da Aula 03, s3://bronze/ptax/moeda=GBP/data=D/cotacoes.jsonl,
--   com moeda, dataHoraCotacao, tipoBoletim, cotacaoCompra, cotacaoVenda.
-- Coletas de dias diferentes podem repetir o mesmo boletim. A silver é pequena:
-- é recalculada inteira, em um objeto de nome fixo.
-- Contrato combinado com a Aula 05 (snake_case): moeda, data_hora_cotacao, tipo_boletim,
-- cotacao_compra, cotacao_venda, mais arquivo_origem e processado_em.
-- data_hora_cotacao fica sem fuso: a PTAX publica no horário de Brasília.

COPY (
    SELECT
        CAST(moeda AS VARCHAR)                         AS moeda,
        CAST(dataHoraCotacao AS TIMESTAMP)             AS data_hora_cotacao,
        CAST(tipoBoletim AS VARCHAR)                   AS tipo_boletim,
        CAST(cotacaoCompra AS DECIMAL(12, 5))          AS cotacao_compra,
        CAST(cotacaoVenda AS DECIMAL(12, 5))           AS cotacao_venda,
        filename                                       AS arquivo_origem,
        now()                                          AS processado_em
    FROM read_json(
        's3://bronze/ptax/*/*/*.jsonl',
        format = 'newline_delimited',
        filename = true,
        -- esquema declarado na leitura: o que não está aqui é ignorado
        columns = {
            moeda: 'VARCHAR', dataHoraCotacao: 'VARCHAR', tipoBoletim: 'VARCHAR',
            cotacaoCompra: 'DOUBLE', cotacaoVenda: 'DOUBLE'
        }
    )
    -- o mesmo boletim em vários arquivos: fica o do arquivo mais recente
    QUALIFY row_number() OVER (
        PARTITION BY moeda, data_hora_cotacao, tipo_boletim
        ORDER BY arquivo_origem DESC
    ) = 1
    ORDER BY data_hora_cotacao
) TO 's3://silver/ptax/ptax.parquet' (FORMAT parquet, COMPRESSION zstd);

SELECT moeda, CAST(data_hora_cotacao AS DATE) AS dia, count(*) AS boletins,
       max(cotacao_venda) FILTER (WHERE tipo_boletim IN ('Fechamento PTAX', 'Fechamento')) AS fechamento_venda
FROM read_parquet('s3://silver/ptax/*.parquet')
GROUP BY ALL
ORDER BY dia;
