-- Aula 04 · Raw: leitura exploratória dos lotes TXT de telemetria gravados na Aula 02.
-- Uso: python sql/rodar_sql.py sql/01_raw_telemetria.sql --var DATA=2026-10-27
-- Schema on read: nenhuma tabela foi criada; o TXT chega como texto e o esquema
-- sai de padrões de linha. Layout da Aula 02 (contrato da telemetria):
--   s3://raw/telemetria/data=AAAA-MM-DD/hora=HH/caminhao=CAM-XXXX/lote_HHMM.txt
--   data, hora e HHMM são o INÍCIO da janela de 15 minutos, em UTC;
--   os horários dentro das linhas estão no horário de Brasília.
--   s3://raw/_manifestos/telemetria/data=.../hora=.../execucao_*.jsonl
-- O dia D no horário de Brasília vai das 03h UTC de D às 02h59 UTC de D+1:
-- as consultas abaixo leem exatamente essas partições, escritas no caminho.

-- 1. Quantos lotes existem por partição de data? glob() só lista as chaves, não baixa conteúdo.
SELECT regexp_extract(file, 'data=([0-9-]+)/', 1) AS data_utc, count(*) AS lotes
FROM glob('s3://raw/telemetria/*/*/*/*.txt')
GROUP BY ALL
ORDER BY data_utc;

-- 2. read_text devolve um registro por arquivo, com o conteúdo inteiro como texto.
--    As partições Hive do caminho (data, hora, caminhao) viram colunas.
DESCRIBE
SELECT * FROM read_text('s3://raw/telemetria/data={{DATA}}/hora=12/*/*.txt');

SELECT caminhao, hora, size, left(content, 70) AS inicio
FROM read_text('s3://raw/telemetria/data={{DATA}}/hora=12/*/*.txt')
ORDER BY caminhao
LIMIT 5;

-- 3. Um arquivo vira várias linhas: string_split + unnest, com o número da linha.
--    A classificação usa só o começo de cada linha, e por isso é grosseira: uma linha
--    cortada depois do caminhão e do horário passaria por formato 1. A extração completa,
--    com a linha inteira casada por expressão regular, está em 03.
CREATE OR REPLACE TEMP TABLE linhas_dia AS
SELECT
    filename                                                AS arquivo_origem,
    unnest(string_split(content, chr(10)))                  AS linha,
    generate_subscripts(string_split(content, chr(10)), 1)  AS numero_linha
FROM read_text([
    's3://raw/telemetria/data={{DATA}}/hora=0[3-9]/*/*.txt',
    's3://raw/telemetria/data={{DATA}}/hora=1[0-9]/*/*.txt',
    's3://raw/telemetria/data={{DATA}}/hora=2[0-3]/*/*.txt',
    's3://raw/telemetria/data={{DATA_SEGUINTE}}/hora=0[0-2]/*/*.txt'
]);

SELECT
    CASE
        WHEN regexp_matches(linha, '^CAM-[0-9]{4}\|')        THEN '1 posição (pipe)'
        WHEN starts_with(linha, '#RADIO ')                   THEN '2 rádio'
        WHEN regexp_matches(linha, '^CAM-[0-9]{4} .* GPS ')  THEN '3 posição (firmware novo)'
        WHEN starts_with(linha, 'ERR SAT')                   THEN '4 erro do enlace'
        WHEN starts_with(linha, 'TAC;')                      THEN '5 alerta do tacógrafo'
        WHEN linha = ''                                      THEN 'vazia (fim de arquivo)'
        ELSE 'não reconhecida'
    END                       AS formato,
    count(*)                  AS linhas,
    any_value(linha)          AS exemplo
FROM linhas_dia
GROUP BY ALL
ORDER BY formato;

-- 4. Linhas que nenhum dos cinco formatos explica, com o arquivo de origem.
SELECT arquivo_origem, numero_linha, linha
FROM linhas_dia
WHERE linha <> ''
  AND NOT regexp_matches(linha, '^(CAM-[0-9]{4}\||CAM-[0-9]{4} .* GPS |#RADIO |ERR SAT|TAC;)')
LIMIT 10;

-- 5. A mesma posição em mais de um lote. O contrato não garante que o provedor
--    nunca reenvie um minuto; se reenviar, a silver precisa escolher uma das cópias.
--    Lista vazia também é resultado: anote-o na spec.
SELECT left(linha, 30) AS caminhao_e_horario, count(*) AS copias,
       list(arquivo_origem ORDER BY arquivo_origem) AS lotes
FROM linhas_dia
WHERE regexp_matches(linha, '^CAM-[0-9]{4}[| ]')
GROUP BY ALL
HAVING count(*) > 1
ORDER BY caminhao_e_horario
LIMIT 5;

-- 6. JSON Lines: o manifesto de execução da Aula 02 tem um objeto JSON por linha.
SELECT status, count(*) AS lotes, sum(linhas) AS linhas, sum(alertas) AS alertas
FROM read_json_auto('s3://raw/_manifestos/telemetria/data={{DATA}}/*/*.jsonl',
                    format = 'newline_delimited')
GROUP BY status
ORDER BY status;
