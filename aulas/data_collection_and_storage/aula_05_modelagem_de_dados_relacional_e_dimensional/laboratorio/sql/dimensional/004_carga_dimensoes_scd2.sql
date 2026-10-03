-- Aula 05 · Carga das dimensões com SCD tipo 2 em dim_livro
-- Entrada: stg_livro_dia_unico (002) para o dia getvariable('data_ref').
-- Regra: os dias são carregados em ordem cronológica. Reexecutar o mesmo dia
-- com o mesmo silver não altera nada (o hash não muda).

BEGIN TRANSACTION;

-- 1. dim_categoria: novas categorias recebem a próxima chave substituta.
INSERT INTO gold.dim_categoria (categoria_sk, categoria_nome)
SELECT
    (SELECT coalesce(max(categoria_sk), 0) FROM gold.dim_categoria)
        + row_number() OVER (ORDER BY n.categoria),
    n.categoria
FROM (
    SELECT DISTINCT s.categoria
    FROM stg_livro_dia_unico s
    WHERE NOT EXISTS (
        SELECT 1 FROM gold.dim_categoria c WHERE c.categoria_nome = s.categoria
    )
) n;

-- 2. Atributos tipo 1: sobrescreve em todas as versões do livro (sem histórico).
UPDATE gold.dim_livro AS d
SET avaliacao = s.avaliacao,
    url       = s.url
FROM stg_livro_dia_unico AS s
WHERE d.upc = s.upc
  AND (d.avaliacao IS DISTINCT FROM s.avaliacao OR d.url IS DISTINCT FROM s.url);

-- 3. Atributos tipo 2: encerra a versão vigente quando titulo ou categoria mudaram.
UPDATE gold.dim_livro AS d
SET valido_ate   = getvariable('data_ref') - INTERVAL 1 DAY,
    versao_atual = false
FROM stg_livro_dia_unico AS s
WHERE d.upc = s.upc
  AND d.versao_atual
  AND d.hash_scd2 <> s.hash_scd2
  AND d.valido_de < getvariable('data_ref');

-- 4. Abre versão nova para livros sem versão vigente (novos ou recém-encerrados).
INSERT INTO gold.dim_livro
    (livro_sk, upc, titulo, categoria_nome, avaliacao, url, hash_scd2,
     valido_de, valido_ate, versao_atual)
SELECT
    (SELECT coalesce(max(livro_sk), 0) FROM gold.dim_livro)
        + row_number() OVER (ORDER BY s.upc),
    s.upc, s.titulo, s.categoria, s.avaliacao, s.url, s.hash_scd2,
    getvariable('data_ref'), DATE '9999-12-31', true
FROM stg_livro_dia_unico AS s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.dim_livro d WHERE d.upc = s.upc AND d.versao_atual
);

COMMIT;

-- Verificação: nenhum livro pode ter duas versões vigentes.
SELECT count(*) AS livros_com_duas_versoes_vigentes
FROM (
    SELECT upc FROM gold.dim_livro WHERE versao_atual GROUP BY upc HAVING count(*) > 1
);
