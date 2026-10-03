-- Aula 05 · Carga idempotente do silver para o modelo relacional
-- Fluxo: o carregador (Python ou DuckDB com a extensão postgres) esvazia e preenche
-- as tabelas stg_*; depois este script move os dados para as tabelas normalizadas.
-- Executar duas vezes seguidas deve produzir as mesmas contagens.

SET search_path TO livraria;

-- Staging com o formato do silver (uma linha por livro por coleta).
CREATE TABLE IF NOT EXISTS stg_livro_dia (
    upc             varchar(32),
    url             text,
    titulo          text,
    categoria       text,
    avaliacao       smallint,
    preco_gbp       numeric(10,2),
    em_estoque      boolean,
    qtd_estoque     integer,
    data_coleta     date,
    coletado_em     timestamptz,
    arquivo_origem  text
);

CREATE TABLE IF NOT EXISTS stg_cotacao (
    moeda_codigo       char(3),
    data_hora_cotacao  timestamp,
    tipo_boletim       text,
    cotacao_compra     numeric(12,6),
    cotacao_venda      numeric(12,6)
);

BEGIN;

-- 1. Categorias novas
INSERT INTO categoria (nome)
SELECT DISTINCT trim(categoria)
FROM stg_livro_dia
WHERE categoria IS NOT NULL AND trim(categoria) <> ''
ON CONFLICT (nome) DO NOTHING;

-- 2. Livros: insere novos e atualiza atributos que mudaram (modelo OLTP guarda o estado atual).
--    Se o mesmo UPC aparecer duas vezes no lote, vale a coleta mais recente.
INSERT INTO livro (upc, titulo, categoria_id, avaliacao)
SELECT DISTINCT ON (s.upc) s.upc, s.titulo, c.categoria_id, s.avaliacao
FROM stg_livro_dia s
JOIN categoria c ON c.nome = trim(s.categoria)
WHERE s.upc IS NOT NULL
ORDER BY s.upc, s.coletado_em DESC
ON CONFLICT (upc) DO UPDATE
SET titulo        = EXCLUDED.titulo,
    categoria_id  = EXCLUDED.categoria_id,
    avaliacao     = EXCLUDED.avaliacao,
    atualizado_em = now()
WHERE (livro.titulo, livro.categoria_id, livro.avaliacao)
      IS DISTINCT FROM (EXCLUDED.titulo, EXCLUDED.categoria_id, EXCLUDED.avaliacao);

-- 3. URLs: registra URL nova e estende o período de uso das conhecidas.
INSERT INTO livro_url (url, livro_id, vista_primeiro, vista_ultimo)
SELECT s.url, l.livro_id, min(s.data_coleta), max(s.data_coleta)
FROM stg_livro_dia s
JOIN livro l ON l.upc = s.upc
WHERE s.url IS NOT NULL
GROUP BY s.url, l.livro_id
ON CONFLICT (url) DO UPDATE
SET vista_primeiro = least(livro_url.vista_primeiro, EXCLUDED.vista_primeiro),
    vista_ultimo   = greatest(livro_url.vista_ultimo, EXCLUDED.vista_ultimo);

-- 4. Observações: a PK (livro_id, data_coleta) torna a reexecução segura.
INSERT INTO observacao_preco
    (livro_id, data_coleta, preco_gbp, em_estoque, qtd_estoque, coletado_em, arquivo_origem)
SELECT DISTINCT ON (l.livro_id, s.data_coleta)
       l.livro_id, s.data_coleta, s.preco_gbp, s.em_estoque, s.qtd_estoque,
       s.coletado_em, s.arquivo_origem
FROM stg_livro_dia s
JOIN livro l ON l.upc = s.upc
WHERE s.preco_gbp IS NOT NULL
ORDER BY l.livro_id, s.data_coleta, s.coletado_em DESC
ON CONFLICT (livro_id, data_coleta) DO UPDATE
SET preco_gbp      = EXCLUDED.preco_gbp,
    em_estoque     = EXCLUDED.em_estoque,
    qtd_estoque    = EXCLUDED.qtd_estoque,
    coletado_em    = EXCLUDED.coletado_em,
    arquivo_origem = EXCLUDED.arquivo_origem;

-- 5. Cotações PTAX
INSERT INTO cotacao (moeda_codigo, data_hora_cotacao, tipo_boletim, cotacao_compra, cotacao_venda)
SELECT DISTINCT moeda_codigo, data_hora_cotacao, tipo_boletim, cotacao_compra, cotacao_venda
FROM stg_cotacao
WHERE moeda_codigo IN (SELECT codigo FROM moeda)
ON CONFLICT (moeda_codigo, data_hora_cotacao, tipo_boletim) DO NOTHING;

COMMIT;

-- Contagens para o relatório de carga (compare com o silver).
SELECT 'categoria' AS tabela, count(*) AS linhas FROM categoria
UNION ALL SELECT 'livro', count(*) FROM livro
UNION ALL SELECT 'livro_url', count(*) FROM livro_url
UNION ALL SELECT 'observacao_preco', count(*) FROM observacao_preco
UNION ALL SELECT 'cotacao', count(*) FROM cotacao
UNION ALL SELECT 'stg_livro_dia (rejeitadas sem upc ou preço)', count(*)
    FROM stg_livro_dia WHERE upc IS NULL OR preco_gbp IS NULL;
