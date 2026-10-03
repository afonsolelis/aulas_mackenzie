-- Aula 05 · Consultas de exemplo no modelo relacional (PostgreSQL)
SET search_path TO livraria;

-- Q1 (operacional): histórico de preço de um livro pelo UPC.
-- Leitura estreita, poucas linhas, servida pela PK e pela UNIQUE de upc.
SELECT l.titulo, o.data_coleta, o.preco_gbp, o.em_estoque
FROM livro l
JOIN observacao_preco o ON o.livro_id = l.livro_id
WHERE l.upc = 'a897fe39b1053632'
ORDER BY o.data_coleta;

-- Q2 (analítica, a mesma pergunta respondida no esquema estrela):
-- "Qual o preço médio em BRL por categoria e mês, e quantos livros foram observados?"
-- No modelo normalizado, a pergunta exige quatro tabelas e a regra da cotação
-- (última de fechamento até a data da coleta) precisa ser reescrita em toda consulta
-- ou escondida numa view.
SELECT
    c.nome                                  AS categoria,
    date_trunc('month', o.data_coleta)::date AS mes,
    count(DISTINCT o.livro_id)              AS livros_observados,
    round(avg(o.preco_gbp), 2)              AS preco_medio_gbp,
    round(avg(o.preco_gbp * ct.cotacao_venda), 2) AS preco_medio_brl
FROM observacao_preco o
JOIN livro l     ON l.livro_id = o.livro_id
JOIN categoria c ON c.categoria_id = l.categoria_id
LEFT JOIN LATERAL (
    SELECT x.cotacao_venda
    FROM cotacao x
    WHERE x.moeda_codigo = 'GBP'
      AND x.tipo_boletim ILIKE 'Fechamento%'
      AND x.data_cotacao <= o.data_coleta
    ORDER BY x.data_hora_cotacao DESC
    LIMIT 1
) ct ON true
GROUP BY c.nome, date_trunc('month', o.data_coleta)
ORDER BY mes, categoria;

-- Atenção: Q2 usa a categoria ATUAL do livro (livro.categoria_id).
-- Se um livro mudou de categoria em outubro, todo o histórico dele migra junto.
-- É a limitação que a SCD tipo 2 resolve no modelo dimensional.

-- Q3: plano de execução para o cenário ATAM de consulta analítica lenta.
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.nome, count(*), avg(o.preco_gbp)
FROM observacao_preco o
JOIN livro l     ON l.livro_id = o.livro_id
JOIN categoria c ON c.categoria_id = l.categoria_id
GROUP BY c.nome;

-- Q4: integridade referencial na prática (deve falhar com violação de FK).
-- INSERT INTO observacao_preco (livro_id, data_coleta, preco_gbp, em_estoque, coletado_em, arquivo_origem)
-- VALUES (999999, DATE '2026-11-07', 10.00, true, now(), 'teste');
