-- Aula 05 · Publica a gold dimensional no MinIO (um Parquet por tabela)
-- Cada COPY sobrescreve um objeto inteiro; o PUT de um objeto é atômico, mas o
-- conjunto de quatro arquivos não é. Publique a fato por último e registre o
-- execucao_id no relatório para identificar uma publicação incompleta.
-- Os caminhos precisam ser literais no COPY; o carregador pode gerá-los a partir
-- da variável de ambiente GOLD_PREFIX.

COPY gold.dim_data            TO 's3://gold/dimensional/dim_data.parquet'            (FORMAT parquet);
COPY gold.dim_categoria       TO 's3://gold/dimensional/dim_categoria.parquet'       (FORMAT parquet);
COPY gold.dim_moeda           TO 's3://gold/dimensional/dim_moeda.parquet'           (FORMAT parquet);
COPY gold.dim_livro           TO 's3://gold/dimensional/dim_livro.parquet'           (FORMAT parquet);
COPY gold.fato_cotacao_diaria TO 's3://gold/dimensional/fato_cotacao_diaria.parquet' (FORMAT parquet);
COPY gold.fato_preco_diario   TO 's3://gold/dimensional/fato_preco_diario.parquet'   (FORMAT parquet);
