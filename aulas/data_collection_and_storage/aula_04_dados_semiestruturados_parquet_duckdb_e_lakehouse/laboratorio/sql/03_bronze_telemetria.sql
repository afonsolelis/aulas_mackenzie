-- Aula 04 · Bronze: telemetria extraída do TXT bruto, um registro por linha reconhecida.
-- Uso: python sql/rodar_sql.py sql/03_bronze_telemetria.sql --var DATA=2026-10-27
-- DATA é o dia no horário de Brasília. rodar_sql.py deriva DATA_SEGUINTE (D+1).
--
-- Entrada: s3://raw/telemetria/data=AAAA-MM-DD/hora=HH/caminhao=CAM-XXXX/lote_HHMM.txt
--   (partições em UTC, início da janela de 15 minutos; linhas no horário de Brasília).
--   O dia D local vai das 03h UTC de D às 02h59 UTC de D+1. As quatro partições
--   ficam escritas no caminho: o DuckDB lista e abre só os lotes desse dia
--   (1.920 com 20 caminhões), em vez de listar o bucket inteiro e filtrar depois.
-- Saídas (bronze = extraído e ainda sem tipos garantidos, em JSON Lines):
--   s3://bronze/telemetria/data_local=D/linhas.jsonl                 linhas dos cinco formatos
--   s3://bronze/telemetria_quarentena/data_local=D/nao_reconhecidas.jsonl  o resto, com a linha original
-- Os campos saem como texto, do jeito que estavam na linha; a conversão de tipos
-- e de fuso fica para a silver (04). Idempotência: um objeto de nome fixo por dia.

-- 1. Uma linha do arquivo por registro, com arquivo, número da linha e início da janela em UTC.
CREATE OR REPLACE TEMP TABLE linhas_raw AS
SELECT
    filename                                                AS arquivo_origem,
    caminhao                                                AS caminhao_arquivo,
    -- com uma lista de globs, as colunas do caminho chegam como texto: o tipo é declarado aqui
    strftime(CAST(data AS DATE) + to_hours(CAST(hora AS INTEGER))
             + to_minutes(CAST(regexp_extract(filename, 'lote_[0-9]{2}([0-9]{2})\.txt$', 1) AS INTEGER)),
             '%Y-%m-%dT%H:%M:00Z')                          AS janela_utc,
    unnest(string_split(content, chr(10)))                  AS linha,
    generate_subscripts(string_split(content, chr(10)), 1)  AS numero_linha
FROM read_text([
    's3://raw/telemetria/data={{DATA}}/hora=0[3-9]/*/*.txt',
    's3://raw/telemetria/data={{DATA}}/hora=1[0-9]/*/*.txt',
    's3://raw/telemetria/data={{DATA}}/hora=2[0-3]/*/*.txt',
    's3://raw/telemetria/data={{DATA_SEGUINTE}}/hora=0[0-2]/*/*.txt'
]);

-- 2. Classificação e extração: uma expressão regular ancorada por formato.
--    regexp_extract com lista de nomes devolve um STRUCT; sem casamento, os campos vêm vazios.
CREATE OR REPLACE TEMP TABLE linhas AS
WITH casamentos AS (
    SELECT
        *,
        regexp_extract(linha,
            '^(CAM-[0-9]{4})\|([0-9]{2}/[0-9]{2}/[0-9]{2} [0-9:]{8})\|(-?[0-9.]+),(-?[0-9.]+)\|VEL ([0-9]{3})\|TAC MOT ([0-9]{2}h[0-9]{2})$',
            ['caminhao', 'data_hora', 'lat', 'lon', 'vel', 'tac'])                     AS f1,
        regexp_extract(linha, '^#RADIO ([0-9]{2}:[0-9]{2}) (.+)$', ['hora', 'texto'])  AS f2,
        regexp_extract(linha,
            '^(CAM-[0-9]{4}) ([0-9]{2}-[0-9]{2}-[0-9]{4} [0-9:]{8}) GPS (-?[0-9.]+) (-?[0-9.]+) v=([0-9]{1,3})(?: TEMP_BAU (-?[0-9]+\.[0-9]))?$',
            ['caminhao', 'data_hora', 'lat', 'lon', 'vel', 'temp'])                    AS f3,
        regexp_extract(linha, '^ERR SAT (.+)$', ['texto'])                             AS f4,
        regexp_extract(linha,
            '^TAC;(CAM-[0-9]{4});([0-9]{8}T[0-9]{6});DIRECAO CONTINUA ([0-9]{2}:[0-9]{2});([A-Z]+)$',
            ['caminhao', 'data_hora', 'duracao', 'status'])                            AS f5
    FROM linhas_raw
    WHERE linha <> ''   -- o fim de linha do último registro gera um elemento vazio
)
SELECT
    arquivo_origem, numero_linha, janela_utc, caminhao_arquivo, linha,
    CASE WHEN f1.caminhao <> '' THEN 1 WHEN f2.hora <> '' THEN 2 WHEN f3.caminhao <> '' THEN 3
         WHEN f4.texto <> '' THEN 4 WHEN f5.caminhao <> '' THEN 5 END                AS formato,
    nullif(coalesce(nullif(f1.caminhao, ''), nullif(f3.caminhao, ''), f5.caminhao), '')    AS caminhao,
    nullif(coalesce(nullif(f1.data_hora, ''), nullif(f2.hora, ''), nullif(f3.data_hora, ''), f5.data_hora), '') AS data_hora_txt,
    nullif(coalesce(nullif(f1.lat, ''), f3.lat), '')                                 AS latitude_txt,
    nullif(coalesce(nullif(f1.lon, ''), f3.lon), '')                                 AS longitude_txt,
    nullif(coalesce(nullif(f1.vel, ''), f3.vel), '')                                 AS velocidade_txt,
    nullif(f1.tac, '')                                                               AS tac_mot_txt,
    nullif(f3.temp, '')                                                              AS temp_bau_txt,
    nullif(f5.duracao, '')                                                           AS duracao_txt,
    nullif(f5.status, '')                                                            AS status_txt,
    nullif(coalesce(nullif(f2.texto, ''), f4.texto), '')                             AS texto
FROM casamentos;

-- 3. Bronze: linhas reconhecidas, sem a linha original (arquivo_origem e numero_linha apontam para ela).
COPY (
    SELECT * EXCLUDE (linha)
    FROM linhas
    WHERE formato IS NOT NULL
    ORDER BY arquivo_origem, numero_linha
) TO 's3://bronze/telemetria/data_local={{DATA}}/linhas.jsonl' (FORMAT json);

-- 4. Quarentena: o que nenhum formato explica fica com a linha original, para investigar.
COPY (
    SELECT arquivo_origem, numero_linha, janela_utc, caminhao_arquivo, linha
    FROM linhas
    WHERE formato IS NULL
    ORDER BY arquivo_origem, numero_linha
) TO 's3://bronze/telemetria_quarentena/data_local={{DATA}}/nao_reconhecidas.jsonl' (FORMAT json);

-- Conferência: lotes lidos e linhas por formato (NULL = quarentena).
SELECT count(DISTINCT arquivo_origem) AS lotes, formato, count(*) AS linhas
FROM linhas
GROUP BY ALL
ORDER BY formato NULLS LAST;

SELECT arquivo_origem, numero_linha, linha
FROM read_json('s3://bronze/telemetria_quarentena/data_local={{DATA}}/*.jsonl',
               format = 'newline_delimited')
LIMIT 10;
