-- Aula 05 · Consultas de exemplo e testes no esquema estrela (DuckDB)
-- Rodam sobre as tabelas locais gold.* ou, trocando os nomes por
-- read_parquet('s3://gold/dimensional/<tabela>.parquet'), direto no MinIO.

-- Q2 (mesma pergunta do modelo relacional):
-- "Qual o preço médio em BRL por categoria e mês, e quantos livros foram observados?"
-- Duas junções, sem regra de cotação: o preço em BRL já foi resolvido na carga.
SELECT
    c.categoria_nome                    AS categoria,
    d.ano_mes                           AS mes,
    count(DISTINCT l.upc)               AS livros_observados,
    round(avg(f.preco_gbp), 2)          AS preco_medio_gbp,
    round(avg(f.preco_brl), 2)          AS preco_medio_brl
FROM gold.fato_preco_diario f
JOIN gold.dim_data d      ON d.data_sk = f.data_coleta_sk
JOIN gold.dim_categoria c ON c.categoria_sk = f.categoria_sk
JOIN gold.dim_livro l     ON l.livro_sk = f.livro_sk
GROUP BY ALL
ORDER BY mes, categoria;

-- Q5 (SCD tipo 2): a mesma série com a categoria do dia da coleta e com a categoria atual.
-- A diferença entre as duas colunas mostra o efeito de reclassificar um livro.
SELECT
    d.ano_mes,
    c.categoria_nome           AS categoria_no_dia,
    atual.categoria_nome       AS categoria_atual,
    count(*)                   AS observacoes
FROM gold.fato_preco_diario f
JOIN gold.dim_data d      ON d.data_sk = f.data_coleta_sk
JOIN gold.dim_categoria c ON c.categoria_sk = f.categoria_sk
JOIN gold.dim_livro l     ON l.livro_sk = f.livro_sk
JOIN gold.dim_livro atual ON atual.upc = l.upc AND atual.versao_atual
WHERE c.categoria_nome <> atual.categoria_nome
GROUP BY ALL
ORDER BY 1, 2;

-- Q6: histórico de versões de um livro.
SELECT upc, livro_sk, titulo, categoria_nome, valido_de, valido_ate, versao_atual
FROM gold.dim_livro
WHERE upc IN (SELECT upc FROM gold.dim_livro GROUP BY upc HAVING count(*) > 1)
ORDER BY upc, valido_de;

-- Q7 (medida semiaditiva): estoque total do dia soma os livros, mas entre dias usa média ou último valor.
SELECT
    d.ano_mes,
    round(avg(estoque_dia), 1)        AS estoque_medio_diario,
    arg_max(estoque_dia, d.data)      AS estoque_no_ultimo_dia
FROM (
    SELECT data_coleta_sk, sum(qtd_estoque) AS estoque_dia
    FROM gold.fato_preco_diario
    GROUP BY data_coleta_sk
) e
JOIN gold.dim_data d ON d.data_sk = e.data_coleta_sk
GROUP BY d.ano_mes
ORDER BY d.ano_mes;

-- Q8 (dimensão conformada): preço médio em GBP e cotação média no mesmo mês,
-- vindos de dois fatos diferentes ligados pela mesma dim_data.
WITH preco AS (
    SELECT d.ano_mes, avg(f.preco_gbp) AS preco_medio_gbp
    FROM gold.fato_preco_diario f JOIN gold.dim_data d ON d.data_sk = f.data_coleta_sk
    GROUP BY d.ano_mes
), cambio AS (
    SELECT d.ano_mes, avg(x.cotacao_venda) AS cotacao_media
    FROM gold.fato_cotacao_diaria x JOIN gold.dim_data d ON d.data_sk = x.data_sk
    GROUP BY d.ano_mes
)
SELECT p.ano_mes, round(p.preco_medio_gbp, 2) AS preco_medio_gbp, round(c.cotacao_media, 4) AS cotacao_media
FROM preco p LEFT JOIN cambio c USING (ano_mes)
ORDER BY p.ano_mes;

-- ===================== testes (todos devem retornar 0) =====================

-- T1 grão: no máximo uma linha por livro (chave natural) por dia.
SELECT count(*) AS violacoes_grao FROM (
    SELECT f.data_coleta_sk, l.upc
    FROM gold.fato_preco_diario f JOIN gold.dim_livro l ON l.livro_sk = f.livro_sk
    GROUP BY ALL HAVING count(*) > 1
);

-- T2 órfãos: toda chave da fato existe na dimensão.
SELECT count(*) AS orfaos
FROM gold.fato_preco_diario f
LEFT JOIN gold.dim_livro l     ON l.livro_sk = f.livro_sk
LEFT JOIN gold.dim_categoria c ON c.categoria_sk = f.categoria_sk
LEFT JOIN gold.dim_data d      ON d.data_sk = f.data_coleta_sk
WHERE l.livro_sk IS NULL OR c.categoria_sk IS NULL OR d.data_sk IS NULL;

-- T3 SCD2: a versão ligada à fato estava vigente na data da coleta.
SELECT count(*) AS versao_fora_da_vigencia
FROM gold.fato_preco_diario f
JOIN gold.dim_livro l ON l.livro_sk = f.livro_sk
JOIN gold.dim_data d  ON d.data_sk = f.data_coleta_sk
WHERE d.data NOT BETWEEN l.valido_de AND l.valido_ate;

-- T4 SCD2: períodos de um mesmo livro não se sobrepõem.
SELECT count(*) AS sobreposicoes
FROM gold.dim_livro a
JOIN gold.dim_livro b
  ON a.upc = b.upc AND a.livro_sk < b.livro_sk
 AND a.valido_de <= b.valido_ate AND b.valido_de <= a.valido_ate;

-- T5 cobertura cambial: observações sem cotação (esperado 0 quando a PTAX cobre o período).
SELECT count(*) AS sem_cotacao FROM gold.fato_preco_diario WHERE preco_brl IS NULL;
