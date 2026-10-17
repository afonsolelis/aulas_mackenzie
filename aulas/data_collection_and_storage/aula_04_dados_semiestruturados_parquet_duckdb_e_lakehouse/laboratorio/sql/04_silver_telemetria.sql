-- Aula 04 · Silver: posições e alertas do tacógrafo tipados, deduplicados e em UTC.
-- Uso: python sql/rodar_sql.py sql/04_silver_telemetria.sql --var DATA=2026-10-27
-- Rode depois de 03_bronze_telemetria.sql para a mesma data (dia no horário de Brasília).
--
-- Entrada: s3://bronze/telemetria/data_local=D/linhas.jsonl, com esquema declarado na leitura.
-- Saídas (um objeto de nome fixo por dia; reprocessar substitui o objeto):
--   s3://silver/posicoes/data_local=D/posicoes.parquet
--     grão: uma linha por caminhão e minuto (UTC); entre cópias do mesmo minuto,
--     fica a do lote mais recente (um minuto reenviado no lote seguinte não vira duas posições).
--   s3://silver/alertas_tacografo/data_local=D/alertas.parquet
--     grão: um alerta por caminhão e instante.
-- Os horários das linhas estão no horário de Brasília e em três formatos diferentes;
-- a silver guarda o instante em UTC (TIMESTAMPTZ) e a data local que define a partição.
-- Rádio (formato 2) e erro do enlace (formato 4) ficam só no bronze: não há pergunta
-- de negócio que os use nesta aula.

SET TimeZone = 'UTC';

CREATE OR REPLACE TEMP TABLE bronze AS
SELECT *
FROM read_json(
    's3://bronze/telemetria/data_local={{DATA}}/linhas.jsonl',
    format = 'newline_delimited',
    -- esquema declarado: tudo texto, como o bronze promete; os tipos nascem aqui
    columns = {
        arquivo_origem: 'VARCHAR', numero_linha: 'BIGINT', janela_utc: 'VARCHAR',
        caminhao_arquivo: 'VARCHAR', formato: 'INTEGER', caminhao: 'VARCHAR',
        data_hora_txt: 'VARCHAR', latitude_txt: 'VARCHAR', longitude_txt: 'VARCHAR',
        velocidade_txt: 'VARCHAR', tac_mot_txt: 'VARCHAR', temp_bau_txt: 'VARCHAR',
        duracao_txt: 'VARCHAR', status_txt: 'VARCHAR', texto: 'VARCHAR'
    }
);

-- Cada formato traz o horário de um jeito; try_strptime devolve NULL em vez de derrubar a leitura.
CREATE OR REPLACE TEMP MACRO instante_utc(formato, txt) AS
    timezone('America/Sao_Paulo',
        CASE formato
            WHEN 1 THEN try_strptime(txt, '%d/%m/%y %H:%M:%S')   -- 17/10/26 09:14:03
            WHEN 3 THEN try_strptime(txt, '%d-%m-%Y %H:%M:%S')   -- 17-10-2026 09:15:03
            WHEN 5 THEN try_strptime(txt, '%Y%m%dT%H%M%S')       -- 20261017T091500
        END);

-- 1. Posições (formatos 1 e 3).
COPY (
    WITH posicoes AS (
        SELECT
            caminhao,
            instante_utc(formato, data_hora_txt)                AS instante_utc,
            CAST(latitude_txt AS DOUBLE)                        AS latitude,
            CAST(longitude_txt AS DOUBLE)                       AS longitude,
            CAST(velocidade_txt AS SMALLINT)                    AS velocidade_kmh,
            -- TAC MOT 03h12: só o formato 1 informa o tempo de direção contínua
            CAST(split_part(tac_mot_txt, 'h', 1) AS INTEGER) * 60
              + CAST(split_part(tac_mot_txt, 'h', 2) AS INTEGER) AS direcao_continua_min,
            CAST(temp_bau_txt AS DECIMAL(4, 1))                 AS temp_bau_c,
            CAST(formato AS TINYINT)                            AS formato,
            CAST(janela_utc AS TIMESTAMPTZ)                     AS janela_utc,
            arquivo_origem,
            numero_linha
        FROM bronze
        WHERE formato IN (1, 3)
    )
    SELECT
        caminhao,
        date_trunc('minute', instante_utc)                      AS minuto_utc,
        instante_utc,
        CAST(timezone('America/Sao_Paulo', instante_utc) AS DATE) AS data_local,
        latitude, longitude, velocidade_kmh, direcao_continua_min, temp_bau_c,
        formato, janela_utc, arquivo_origem, numero_linha,
        now()                                                   AS processado_em
    FROM posicoes
    -- o lote das 00h00 de D pode trazer a retransmissão das 23h59 de D-1: fica fora
    WHERE CAST(timezone('America/Sao_Paulo', instante_utc) AS DATE) = DATE '{{DATA}}'
    QUALIFY row_number() OVER (
        PARTITION BY caminhao, date_trunc('minute', instante_utc)
        ORDER BY janela_utc DESC, numero_linha DESC
    ) = 1
    ORDER BY caminhao, minuto_utc
) TO 's3://silver/posicoes/data_local={{DATA}}/posicoes.parquet' (FORMAT parquet, COMPRESSION zstd);

-- 2. Alertas do tacógrafo (formato 5). Acima de 05:30 de direção contínua,
--    a jornada viola o limite da Lei 13.103/2015.
COPY (
    SELECT
        caminhao,
        instante_utc(formato, data_hora_txt)                    AS instante_utc,
        CAST(timezone('America/Sao_Paulo', instante_utc(formato, data_hora_txt)) AS DATE) AS data_local,
        CAST(split_part(duracao_txt, ':', 1) AS INTEGER) * 60
          + CAST(split_part(duracao_txt, ':', 2) AS INTEGER)    AS direcao_continua_min,
        direcao_continua_min > 330                              AS acima_de_5h30,
        status_txt                                              AS status,
        CAST(janela_utc AS TIMESTAMPTZ)                         AS janela_utc,
        arquivo_origem,
        numero_linha,
        now()                                                   AS processado_em
    FROM bronze
    WHERE formato = 5
      AND CAST(timezone('America/Sao_Paulo', instante_utc(formato, data_hora_txt)) AS DATE) = DATE '{{DATA}}'
    QUALIFY row_number() OVER (
        PARTITION BY caminhao, instante_utc ORDER BY janela_utc DESC, numero_linha DESC
    ) = 1
    ORDER BY caminhao, instante_utc
) TO 's3://silver/alertas_tacografo/data_local={{DATA}}/alertas.parquet' (FORMAT parquet, COMPRESSION zstd);

-- Conferência: posições lidas no bronze, gravadas na silver e descartadas.
SELECT
    (SELECT count(*) FROM bronze WHERE formato IN (1, 3))                       AS posicoes_bronze,
    (SELECT count(*) FROM bronze WHERE formato IN (1, 3)
                                   AND instante_utc(formato, data_hora_txt) IS NULL) AS horario_invalido,
    count(*)                                                                    AS posicoes_silver,
    count(DISTINCT caminhao)                                                    AS caminhoes,
    min(minuto_utc) AS primeiro_minuto_utc, max(minuto_utc) AS ultimo_minuto_utc,
    count(*) FILTER (WHERE arquivo_origem IS NULL)                              AS sem_origem
FROM read_parquet('s3://silver/posicoes/data_local={{DATA}}/*.parquet');

-- Esperado com o lote completo: 1.440 minutos por caminhão (24 h x 60).
SELECT caminhao, count(*) AS minutos, count(temp_bau_c) AS com_temp_bau
FROM read_parquet('s3://silver/posicoes/data_local={{DATA}}/*.parquet')
GROUP BY caminhao
ORDER BY minutos, caminhao
LIMIT 5;

SELECT count(*) AS alertas, count(*) FILTER (WHERE acima_de_5h30) AS acima_de_5h30,
       max(direcao_continua_min) AS maior_direcao_continua_min
FROM read_parquet('s3://silver/alertas_tacografo/data_local={{DATA}}/*.parquet');
