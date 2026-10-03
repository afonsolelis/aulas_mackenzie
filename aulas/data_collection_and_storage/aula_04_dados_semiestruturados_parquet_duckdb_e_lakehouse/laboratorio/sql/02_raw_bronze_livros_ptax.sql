-- Aula 04 · Raw e bronze: leitura exploratória do que a Aula 03 gravou.
-- Na disciplina, raw guarda os bytes como a fonte entregou e bronze guarda o que já foi
-- extraído, em JSON Lines, ainda sem tipos garantidos. Layout da Aula 03
-- (confira com mc ls e ajuste se o grupo gravou diferente):
--   s3://raw/ptax/moeda=GBP/data=AAAA-MM-DD/*.json                    resposta da API PTAX, intacta
--   s3://raw/books_toscrape/data=AAAA-MM-DD/livro=<slug>/detalhe.html  página de detalhe de cada livro
--   s3://bronze/books_toscrape/data=AAAA-MM-DD/livros.jsonl          um livro por linha
--   s3://bronze/ptax/moeda=GBP/data=AAAA-MM-DD/cotacoes.jsonl        um boletim por linha

-- 1. PTAX no raw: o JSON tem um envelope OData; os boletins estão na lista "value".
DESCRIBE
SELECT * FROM read_json_auto('s3://raw/ptax/*/*/*.json', filename = true, hive_partitioning = true);

-- 2. Um boletim por linha com UNNEST. A consulta de período repete dias entre coletas.
SELECT b.dataHoraCotacao, b.tipoBoletim, b.cotacaoVenda, count(*) AS arquivos_com_o_boletim
FROM (
    SELECT unnest(value) AS b
    FROM read_json_auto('s3://raw/ptax/*/*/*.json', hive_partitioning = true)
)
GROUP BY ALL
ORDER BY b.dataHoraCotacao DESC
LIMIT 10;

-- 3. HTML não tem esquema que o leitor JSON entenda: chega como texto.
SELECT filename, size, left(content, 40) AS inicio
FROM read_text('s3://raw/books_toscrape/*/*/detalhe.html')
LIMIT 5;

-- 4. Exploração: UPC, preço e estoque saem de padrões da página de detalhe.
--    Só para entender o mecanismo; a extração oficial é a da Aula 03 (parser de HTML).
SELECT
    regexp_extract(content, '<th>UPC</th><td>([^<]+)</td>', 1)          AS upc,
    regexp_extract(content, '<p class="price_color">£([0-9.]+)</p>', 1) AS preco_gbp_txt,
    regexp_extract(content, 'In stock \(([0-9]+) available\)', 1)       AS qtd_estoque_txt,
    filename
FROM read_text('s3://raw/books_toscrape/*/*/detalhe.html')
LIMIT 5;

-- 5. Bronze em JSON Lines: esquema inferido de um objeto por linha.
--    Repare no tipo inferido de coletado_em: TIMESTAMP sem fuso. O valor com
--    deslocamento (-03:00) é convertido para UTC e o fuso se perde; por isso a
--    silver lê esse campo como texto e converte de forma explícita.
DESCRIBE
SELECT *
FROM read_json_auto('s3://bronze/books_toscrape/*/*.jsonl',
                    format = 'newline_delimited', filename = true, hive_partitioning = true);

SELECT moeda, tipoBoletim, count(*) AS boletins
FROM read_json_auto('s3://bronze/ptax/*/*/*.jsonl', format = 'newline_delimited', hive_partitioning = true)
GROUP BY ALL
ORDER BY ALL;
