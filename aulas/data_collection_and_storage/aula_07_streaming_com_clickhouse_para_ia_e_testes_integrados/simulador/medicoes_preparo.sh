#!/usr/bin/env bash
# Medições de preparo da Aula 07 (Data Collection and Storage).
#
# Sobe um ClickHouse descartável em contêiner e mede os números citados no slide
# e no material: custo do índice vector_similarity, busca exata e aproximada,
# view materializada contra a tabela bruta e o efeito de uma linha duplicada.
#
# Uso: bash medicoes_preparo.sh [n_vetores]      (padrão: 100000)
# Requer Docker. Os tempos variam com a máquina; valem como ordem de grandeza.
set -eu
IMAGEM="clickhouse/clickhouse-server:26.8.15.10"
NOME="ch_medicoes_aula07"
N="${1:-100000}"
Q() { docker exec "$NOME" clickhouse-client --time -mn -q "$1" 2>&1; }

docker rm -f "$NOME" >/dev/null 2>&1 || true
docker run -d --name "$NOME" --ulimit nofile=262144:262144 -e CLICKHOUSE_SKIP_USER_SETUP=1 "$IMAGEM" >/dev/null
trap 'docker rm -f "$NOME" >/dev/null' EXIT
for _ in $(seq 1 30); do docker exec "$NOME" clickhouse-client -q "SELECT version()" 2>/dev/null && break; sleep 1; done

echo "== Busca vetorial: $N vetores sintéticos de 384 dimensões =="
Q "CREATE DATABASE tatame;
CREATE TABLE tatame.exato (id UInt32, vetor Array(Float32)) ENGINE = MergeTree ORDER BY id;
CREATE TABLE tatame.aprox (id UInt32, vetor Array(Float32),
  INDEX idx vetor TYPE vector_similarity('hnsw', 'cosineDistance', 384)) ENGINE = MergeTree ORDER BY id;" >/dev/null
echo "INSERT sem índice (s):"
Q "INSERT INTO tatame.exato SELECT number, arrayMap(x -> toFloat32(cityHash64(number, x) % 20001) / 10000 - 1, range(384)) FROM numbers($N)"
echo "INSERT com índice, que constrói o grafo (s):"
Q "INSERT INTO tatame.aprox SELECT * FROM tatame.exato"
Q "OPTIMIZE TABLE tatame.aprox FINAL" >/dev/null
Q "SELECT table, sum(rows) AS linhas, formatReadableSize(sum(data_compressed_bytes)) AS coluna, formatReadableSize(sum(secondary_indices_compressed_bytes)) AS indice
   FROM system.parts WHERE database = 'tatame' AND active AND table IN ('exato', 'aprox') GROUP BY table FORMAT TSVWithNames" | head -3
for K in 1 2 3; do
  REF="(SELECT arrayMap(x -> toFloat32(cityHash64(999000 + $K, x) % 20001) / 10000 - 1, range(384)))"
  echo "consulta $K, exata (10 vizinhos e tempo em s):"
  Q "WITH $REF AS ref SELECT groupArray(id) FROM (SELECT id FROM tatame.exato ORDER BY cosineDistance(vetor, ref) LIMIT 10)"
  echo "consulta $K, aproximada:"
  Q "WITH $REF AS ref SELECT groupArray(id) FROM (SELECT id FROM tatame.aprox ORDER BY cosineDistance(vetor, ref) LIMIT 10)"
done
# Os vetores são aleatórios, sem estrutura: é o pior caso para o grafo de vizinhança.

echo
echo "== View materializada: um dia da hipótese (1.742.400 eventos) =="
Q "CREATE TABLE tatame.eventos (event_id UUID, tipo LowCardinality(String), ocorrido_em DateTime64(3, 'UTC'),
  regiao LowCardinality(String), academia LowCardinality(String), aluno String, motivo String DEFAULT '')
  ENGINE = ReplacingMergeTree PARTITION BY toYYYYMM(ocorrido_em) ORDER BY (academia, ocorrido_em, event_id);
CREATE TABLE tatame.checkins_por_minuto (minuto DateTime('UTC'), regiao LowCardinality(String),
  eventos AggregateFunction(count), alunos AggregateFunction(uniq, String))
  ENGINE = AggregatingMergeTree ORDER BY (regiao, minuto);
CREATE MATERIALIZED VIEW tatame.mv_checkins TO tatame.checkins_por_minuto AS
  SELECT toStartOfMinute(ocorrido_em) AS minuto, regiao, countState() AS eventos, uniqState(aluno) AS alunos
  FROM tatame.eventos WHERE tipo = 'checkin' GROUP BY minuto, regiao;" >/dev/null
echo "INSERT de um dia (s):"
Q "INSERT INTO tatame.eventos (event_id, tipo, ocorrido_em, regiao, academia, aluno)
   SELECT generateUUIDv4(), if(number % 25 = 0, 'checkin', 'app_aberto'), toDateTime64('2026-11-28 11:00:00', 3, 'UTC') + number / 20.2,
          'eu-estocolmo', concat('SE-STO-', leftPad(toString(number % 48 + 1), 3, '0')), toString(number % 7200) FROM numbers(1742400)"
Q "SELECT 'linhas na view', count() FROM tatame.checkins_por_minuto" | head -1
Q "SELECT 'consulta bruta', count(), uniq(aluno) FROM tatame.eventos WHERE tipo = 'checkin'" | head -1
Q "SELECT 'consulta view', countMerge(eventos), uniqMerge(alunos) FROM tatame.checkins_por_minuto" | head -1

echo
echo "== A mesma linha inserida duas vezes =="
DUP="INSERT INTO tatame.eventos (event_id, tipo, ocorrido_em, regiao, academia, aluno) VALUES ('7f3b1c9e-52a4-4d0e-9c1b-6a2f8e4d7b10', 'checkin', '2026-11-28 11:02:07.412', 'eu-estocolmo', 'SE-STO-014', 'a8f3c1d9e2b47f60')"
Q "SELECT 'check-ins no minuto antes', countMerge(eventos) FROM tatame.checkins_por_minuto WHERE minuto = '2026-11-28 11:02:00'" | head -1
Q "$DUP" >/dev/null; Q "$DUP" >/dev/null
Q "SELECT 'count()', count() FROM tatame.eventos WHERE aluno = 'a8f3c1d9e2b47f60'" | head -1
Q "SELECT 'count() FINAL', count() FROM tatame.eventos FINAL WHERE aluno = 'a8f3c1d9e2b47f60'" | head -1
Q "SELECT 'check-ins no minuto depois', countMerge(eventos) FROM tatame.checkins_por_minuto WHERE minuto = '2026-11-28 11:02:00'" | head -1

echo
echo "== Linhas lidas e duração das duas consultas =="
Q "SYSTEM FLUSH LOGS" >/dev/null
Q "SELECT query_duration_ms, read_rows, substring(query, 1, 40) FROM system.query_log
   WHERE type = 'QueryFinish' AND query LIKE 'SELECT \\'consulta%' ORDER BY event_time_microseconds DESC LIMIT 2" | head -2
