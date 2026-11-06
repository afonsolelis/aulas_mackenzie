-- Aula 05 · Observabilidade da ingestão com views em janela.
-- Duas fontes: a própria db_ingestion (o que chegou) e as linhas de telemetria que não viraram fato.
-- Durante a aula o professor reenvia telemetria (reenviar_ao_vivo.py); sem dado novo, as janelas ficam vazias.
-- Uso: python rodar_sql.py sql/004_observabilidade.sql

-- ---------------------------------------------------------------------------
-- Linhas ingeridas por minuto e domínio. View materializada incremental.
-- Cada INSERT agrega só o próprio bloco; SummingMergeTree soma os blocos do mesmo minuto no merge,
-- e a leitura soma de novo com sum(), porque o merge pode não ter acontecido ainda.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mackenzie.g00_obs_ingestao_minuto
(
    minuto    DateTime('America/Sao_Paulo'),
    data_tag  LowCardinality(String),
    linhas    UInt64
)
ENGINE = SummingMergeTree
ORDER BY (data_tag, minuto);

CREATE MATERIALIZED VIEW IF NOT EXISTS mackenzie.g00_mv_obs_ingestao_minuto TO mackenzie.g00_obs_ingestao_minuto AS
SELECT toStartOfMinute(fromUnixTimestamp64Milli(toInt64(timestamp), 'America/Sao_Paulo')) AS minuto,
       data_tag,
       count() AS linhas
FROM mackenzie.db_ingestion
GROUP BY minuto, data_tag;

-- ---------------------------------------------------------------------------
-- Linhas de telemetria que não viraram fato (nem leitura nem alerta), por minuto e motivo. Incremental.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mackenzie.g00_obs_telemetria_descartes_minuto
(
    minuto  DateTime('America/Sao_Paulo'),
    motivo  LowCardinality(String),
    linhas  UInt64
)
ENGINE = SummingMergeTree
ORDER BY (motivo, minuto);

CREATE MATERIALIZED VIEW IF NOT EXISTS mackenzie.g00_mv_obs_telemetria_descartes_minuto TO mackenzie.g00_obs_telemetria_descartes_minuto AS
WITH data_json.linha::String AS linha
SELECT toStartOfMinute(fromUnixTimestamp64Milli(toInt64(timestamp), 'America/Sao_Paulo')) AS minuto,
       multiIf(startsWith(linha, 'ERR SAT'), 'ERR SAT',
               startsWith(linha, '#RADIO'), '#RADIO',
               'outro') AS motivo,
       count() AS linhas
FROM mackenzie.db_ingestion
WHERE data_tag = 'telemetria'
  AND NOT match(linha, '^CAM-[0-9]{4}(\\|| [0-9]{2}-[0-9]{2}-)')
  AND NOT startsWith(linha, 'TAC;')
GROUP BY minuto, motivo;

-- ===========================================================================
-- Views em janela: views comuns com um filtro relativo a now(). Não guardam nada;
-- cada consulta roda o SELECT de novo, e a janela anda com o relógio.
-- ===========================================================================

-- Saúde por domínio nos últimos 15 minutos: volume e há quanto tempo não chega nada.
CREATE OR REPLACE VIEW mackenzie.g00_v_saude_ingestao_15min AS
SELECT data_tag,
       sum(linhas)                                AS linhas_15min,
       max(minuto)                                AS ultimo_minuto_com_dado,
       dateDiff('second', max(minuto), now())     AS segundos_desde_ultimo_minuto
FROM mackenzie.g00_obs_ingestao_minuto
WHERE minuto >= now() - INTERVAL 15 MINUTE
GROUP BY data_tag;

-- Caminhões que transmitiram nos últimos 5 minutos de ingestão, direto da tabela de pouso.
-- Lê db_ingestion inteira filtrada pelo timestamp: a ordenação (data_tag, timestamp) faz o filtro ler poucos grânulos.
CREATE OR REPLACE VIEW mackenzie.g00_v_caminhoes_5min AS
SELECT substring(data_json.linha::String, 1, 8)                                AS caminhao,
       count()                                                                AS linhas_5min,
       max(fromUnixTimestamp64Milli(toInt64(timestamp), 'America/Sao_Paulo')) AS ultima_chegada
FROM mackenzie.db_ingestion
WHERE data_tag = 'telemetria'
  AND timestamp >= toUnixTimestamp64Milli(now64(3) - INTERVAL 5 MINUTE)
  AND match(data_json.linha::String, '^CAM-[0-9]{4}')
GROUP BY caminhao;

-- Descartes de telemetria na última hora, por motivo, com a parte do total.
CREATE OR REPLACE VIEW mackenzie.g00_v_descartes_telemetria_1h AS
SELECT d.motivo,
       sum(d.linhas)                                                         AS descartadas,
       (SELECT sum(linhas) FROM mackenzie.g00_obs_ingestao_minuto
        WHERE data_tag = 'telemetria' AND minuto >= now() - INTERVAL 1 HOUR) AS telemetria_total,
       round(100 * descartadas / telemetria_total, 2)                        AS pct
FROM mackenzie.g00_obs_telemetria_descartes_minuto AS d
WHERE d.minuto >= now() - INTERVAL 1 HOUR
GROUP BY d.motivo;
