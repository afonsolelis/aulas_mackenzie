-- Aula 05 · Modelo relacional (OLTP) do monitor de preços de livros
-- Alvo: PostgreSQL 16 (local via docker compose ou Postgres do Railway)
-- Executar: psql "$DATABASE_PUBLIC_URL" -v ON_ERROR_STOP=1 -f sql/relacional/001_schema.sql
-- O script é idempotente: pode ser executado de novo sem erro.
--
-- Normalizado até a 3FN:
--   categoria 1:N livro; livro 1:N livro_url; livro 1:N observacao_preco;
--   moeda 1:N cotacao. O preço em BRL não é gravado: é derivado na view vw_preco_brl.

CREATE SCHEMA IF NOT EXISTS livraria;
SET search_path TO livraria;

CREATE TABLE IF NOT EXISTS categoria (
    categoria_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          text NOT NULL,
    CONSTRAINT uq_categoria_nome UNIQUE (nome),
    CONSTRAINT ck_categoria_nome CHECK (length(trim(nome)) > 0)
);

-- Chave substituta (livro_id) + chave natural (upc) protegida por UNIQUE.
-- A URL fica fora da chave porque pode mudar (ver livro_url).
CREATE TABLE IF NOT EXISTS livro (
    livro_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    upc            varchar(32) NOT NULL,
    titulo         text NOT NULL,
    categoria_id   integer NOT NULL,
    avaliacao      smallint,
    criado_em      timestamptz NOT NULL DEFAULT now(),
    atualizado_em  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_livro_upc UNIQUE (upc),
    CONSTRAINT ck_livro_avaliacao CHECK (avaliacao BETWEEN 1 AND 5),
    CONSTRAINT fk_livro_categoria FOREIGN KEY (categoria_id)
        REFERENCES categoria (categoria_id) ON DELETE RESTRICT
);
-- O PostgreSQL não cria índice automático para FK.
CREATE INDEX IF NOT EXISTS ix_livro_categoria ON livro (categoria_id);

-- Histórico de URLs: uma URL pertence a um livro; um livro pode ter várias URLs ao longo do tempo.
CREATE TABLE IF NOT EXISTS livro_url (
    url            text PRIMARY KEY,
    livro_id       bigint NOT NULL,
    vista_primeiro date NOT NULL,
    vista_ultimo   date NOT NULL,
    CONSTRAINT ck_livro_url_periodo CHECK (vista_ultimo >= vista_primeiro),
    CONSTRAINT fk_livro_url_livro FOREIGN KEY (livro_id)
        REFERENCES livro (livro_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS ix_livro_url_livro ON livro_url (livro_id);

-- Grão: um livro por dia de coleta. A PK composta impede duplicata em reexecução.
CREATE TABLE IF NOT EXISTS observacao_preco (
    livro_id        bigint NOT NULL,
    data_coleta     date NOT NULL,
    preco_gbp       numeric(10,2) NOT NULL,
    em_estoque      boolean NOT NULL,
    qtd_estoque     integer,
    coletado_em     timestamptz NOT NULL,
    arquivo_origem  text NOT NULL,
    CONSTRAINT pk_observacao_preco PRIMARY KEY (livro_id, data_coleta),
    CONSTRAINT ck_observacao_preco_valor CHECK (preco_gbp >= 0),
    CONSTRAINT ck_observacao_qtd CHECK (qtd_estoque IS NULL OR qtd_estoque >= 0),
    CONSTRAINT fk_observacao_livro FOREIGN KEY (livro_id)
        REFERENCES livro (livro_id) ON DELETE RESTRICT
);
-- A PK começa por livro_id; consultas por período precisam de índice próprio.
CREATE INDEX IF NOT EXISTS ix_observacao_data ON observacao_preco (data_coleta);

CREATE TABLE IF NOT EXISTS moeda (
    codigo  char(3) PRIMARY KEY,
    nome    text NOT NULL,
    CONSTRAINT ck_moeda_codigo CHECK (codigo ~ '^[A-Z]{3}$')
);

-- PTAX: vários boletins por dia (abertura, intermediários, fechamento).
-- O texto exato de tipo_boletim vem do silver da Aula 04; confira antes de filtrar.
CREATE TABLE IF NOT EXISTS cotacao (
    moeda_codigo       char(3) NOT NULL,
    data_hora_cotacao  timestamp NOT NULL,
    tipo_boletim       text NOT NULL,
    data_cotacao       date GENERATED ALWAYS AS (CAST(data_hora_cotacao AS date)) STORED,
    cotacao_compra     numeric(12,6) NOT NULL,
    cotacao_venda      numeric(12,6) NOT NULL,
    CONSTRAINT pk_cotacao PRIMARY KEY (moeda_codigo, data_hora_cotacao, tipo_boletim),
    CONSTRAINT ck_cotacao_positiva CHECK (cotacao_compra > 0 AND cotacao_venda > 0),
    CONSTRAINT fk_cotacao_moeda FOREIGN KEY (moeda_codigo)
        REFERENCES moeda (codigo) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS ix_cotacao_moeda_data ON cotacao (moeda_codigo, data_cotacao);

INSERT INTO moeda (codigo, nome) VALUES
    ('GBP', 'Libra esterlina'),
    ('BRL', 'Real brasileiro')
ON CONFLICT (codigo) DO NOTHING;

-- Preço em BRL derivado: usa a última cotação de venda de fechamento
-- disponível até a data da coleta (a PTAX não sai em sábado, domingo e feriado).
-- Ajuste o filtro de tipo_boletim ao valor real encontrado no silver.
CREATE OR REPLACE VIEW vw_preco_brl AS
SELECT
    o.livro_id,
    o.data_coleta,
    o.preco_gbp,
    c.data_cotacao,
    c.cotacao_venda,
    round(o.preco_gbp * c.cotacao_venda, 2) AS preco_brl
FROM observacao_preco o
LEFT JOIN LATERAL (
    SELECT ct.data_cotacao, ct.cotacao_venda
    FROM cotacao ct
    WHERE ct.moeda_codigo = 'GBP'
      AND ct.tipo_boletim ILIKE 'Fechamento%'
      AND ct.data_cotacao <= o.data_coleta
    ORDER BY ct.data_hora_cotacao DESC
    LIMIT 1
) c ON true;
