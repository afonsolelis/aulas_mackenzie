-- Aula 05 · Esquema estrela da camada gold (DuckDB)
-- Processo de negócio: acompanhamento diário de preços de livros.
-- Grão de fato_preco_diario: um livro por dia de coleta.
-- Executar: duckdb gold.duckdb < sql/dimensional/001_schema.sql   (idempotente)
--
-- Não há FOREIGN KEY: a integridade entre fato e dimensões é verificada por consulta
-- (ver 007_consultas.sql, bloco "testes"), como é comum em data warehouse.
-- Chaves substitutas são calculadas na carga (max + row_number) para sobreviver
-- à restauração a partir dos arquivos Parquet do MinIO.

CREATE SCHEMA IF NOT EXISTS gold;

-- Dimensão de calendário: gerada, não coletada. Conformada entre os fatos.
CREATE TABLE IF NOT EXISTS gold.dim_data (
    data_sk          INTEGER PRIMARY KEY,      -- AAAAMMDD
    data             DATE NOT NULL UNIQUE,
    ano              SMALLINT NOT NULL,
    trimestre        TINYINT NOT NULL,
    mes              TINYINT NOT NULL,
    nome_mes         VARCHAR NOT NULL,
    ano_mes          VARCHAR NOT NULL,         -- '2026-11'
    dia              TINYINT NOT NULL,
    dia_semana_iso   TINYINT NOT NULL,         -- 1 = segunda ... 7 = domingo
    nome_dia_semana  VARCHAR NOT NULL,
    fim_de_semana    BOOLEAN NOT NULL
);

INSERT OR IGNORE INTO gold.dim_data
SELECT
    CAST(strftime(d, '%Y%m%d') AS INTEGER),
    CAST(d AS DATE),
    year(d),
    quarter(d),
    month(d),
    (['janeiro','fevereiro','março','abril','maio','junho','julho',
      'agosto','setembro','outubro','novembro','dezembro'])[month(d)],
    strftime(d, '%Y-%m'),
    day(d),
    isodow(d),
    (['segunda','terça','quarta','quinta','sexta','sábado','domingo'])[isodow(d)],
    isodow(d) IN (6, 7)
FROM generate_series(DATE '2026-01-01', DATE '2027-12-31', INTERVAL 1 DAY) AS t(d);

CREATE TABLE IF NOT EXISTS gold.dim_categoria (
    categoria_sk    INTEGER PRIMARY KEY,
    categoria_nome  VARCHAR NOT NULL UNIQUE
);

-- SCD híbrida:
--   tipo 2 (gera nova versão): titulo, categoria_nome
--   tipo 1 (sobrescreve todas as versões): avaliacao, url
CREATE TABLE IF NOT EXISTS gold.dim_livro (
    livro_sk        BIGINT PRIMARY KEY,
    upc             VARCHAR NOT NULL,          -- chave natural
    titulo          VARCHAR NOT NULL,
    categoria_nome  VARCHAR NOT NULL,
    avaliacao       TINYINT,
    url             VARCHAR,
    hash_scd2       VARCHAR NOT NULL,          -- md5 dos atributos tipo 2
    valido_de       DATE NOT NULL,
    valido_ate      DATE NOT NULL,             -- 9999-12-31 na versão vigente
    versao_atual    BOOLEAN NOT NULL,
    UNIQUE (upc, valido_de)
);

CREATE TABLE IF NOT EXISTS gold.dim_moeda (
    moeda_sk  SMALLINT PRIMARY KEY,
    codigo    VARCHAR NOT NULL UNIQUE,
    nome      VARCHAR NOT NULL
);

INSERT OR IGNORE INTO gold.dim_moeda VALUES
    (1, 'GBP', 'Libra esterlina'),
    (2, 'BRL', 'Real brasileiro');

-- Fato de snapshot periódico: o estado de preço de cada livro em cada dia de coleta.
CREATE TABLE IF NOT EXISTS gold.fato_preco_diario (
    data_coleta_sk   INTEGER NOT NULL,         -- dim_data (papel: data da coleta)
    livro_sk         BIGINT NOT NULL,          -- versão de dim_livro vigente no dia
    categoria_sk     INTEGER NOT NULL,         -- categoria no dia da coleta
    moeda_sk         SMALLINT NOT NULL,        -- moeda do preço original
    data_cotacao_sk  INTEGER,                  -- dim_data (papel: data da PTAX usada)
    execucao_id      VARCHAR NOT NULL,         -- dimensão degenerada
    preco_gbp        DECIMAL(10,2) NOT NULL,   -- não aditiva
    cotacao_venda    DECIMAL(12,6),            -- não aditiva
    preco_brl        DECIMAL(12,2),            -- não aditiva
    qtd_estoque      INTEGER,                  -- semiaditiva (soma entre livros, não entre dias)
    qtd_observacoes  INTEGER NOT NULL,         -- aditiva (sempre 1 no grão)
    PRIMARY KEY (data_coleta_sk, livro_sk)
);

-- Segundo fato, que compartilha dim_data e dim_moeda (dimensões conformadas).
CREATE TABLE IF NOT EXISTS gold.fato_cotacao_diaria (
    data_sk         INTEGER NOT NULL,
    moeda_sk        SMALLINT NOT NULL,
    cotacao_compra  DECIMAL(12,6) NOT NULL,
    cotacao_venda   DECIMAL(12,6) NOT NULL,
    PRIMARY KEY (data_sk, moeda_sk)
);
