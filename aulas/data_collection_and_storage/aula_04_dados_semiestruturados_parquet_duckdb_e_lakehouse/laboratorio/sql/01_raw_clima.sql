-- Aula 04 · Raw: leitura exploratória do JSON da Open-Meteo gravado na Aula 02.
-- Schema on read: nenhuma tabela foi criada; o DuckDB infere o esquema na leitura.
-- Layout da Aula 02: s3://raw/open_meteo/data=AAAA-MM-DD/hora=HH/<cidade>.json
-- Cada arquivo guarda a resposta inteira da API, com o bloco "hourly"
-- (listas paralelas: time[], temperature_2m[], relative_humidity_2m[]).

-- 1. Quantos arquivos existem por partição de coleta?
SELECT data, hora, count(*) AS arquivos
FROM read_json_auto('s3://raw/open_meteo/*/*/*.json', filename = true, hive_partitioning = true)
GROUP BY ALL
ORDER BY data, hora;

-- 2. Qual esquema o DuckDB inferiu? Note os STRUCT com listas (hourly, hourly_units).
DESCRIBE
SELECT *
FROM read_json_auto('s3://raw/open_meteo/*/*/*.json', filename = true, hive_partitioning = true);

-- 3. Um arquivo vira várias linhas: UNNEST de listas paralelas no mesmo SELECT.
--    A cidade vem do nome do arquivo e o arquivo de origem acompanha cada linha.
SELECT
    regexp_extract(filename, '([^/]+)\.json$', 1) AS cidade,
    data                                          AS data_coleta,
    hora                                          AS hora_coleta,
    unnest(hourly.time)                           AS horario_local,
    unnest(hourly.temperature_2m)                 AS temperatura_c,
    filename                                      AS arquivo_origem
FROM read_json_auto('s3://raw/open_meteo/*/*/*.json', filename = true, hive_partitioning = true)
ORDER BY cidade, horario_local, hora_coleta
LIMIT 12;

-- 4. Quantas vezes a mesma hora prevista aparece? Cada coleta horária repete o dia inteiro.
SELECT cidade, horario_local, count(*) AS repeticoes
FROM (
    SELECT regexp_extract(filename, '([^/]+)\.json$', 1) AS cidade,
           unnest(hourly.time) AS horario_local
    FROM read_json_auto('s3://raw/open_meteo/*/*/*.json', filename = true)
)
GROUP BY ALL
ORDER BY repeticoes DESC, cidade, horario_local
LIMIT 5;

-- 5. JSON Lines: o manifesto de execução da Aula 02 tem um objeto JSON por linha.
--    O mesmo leitor detecta o formato; cada linha vira um registro.
SELECT status, count(*) AS cidades
FROM read_json_auto('s3://raw/_manifestos/open_meteo/*/*/*.jsonl', format = 'newline_delimited')
GROUP BY status
ORDER BY status;
