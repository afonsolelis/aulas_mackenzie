-- Aula 05 · Consultas de conferência e perguntas ao cubo: grão, estrela, views e observabilidade.
-- Uso: python rodar_sql.py sql/005_consultas.sql

-- 1. Teste do grão: com FINAL, linhas = combinações distintas da chave do grão.
--    Sem FINAL, a diferença são as cópias que o ReplacingMergeTree ainda não juntou.
SELECT 'fato_preco_livro' AS fato,
       (SELECT count() FROM mackenzie.g00_fato_preco_livro)                                    AS linhas_sem_final,
       (SELECT count() FROM mackenzie.g00_fato_preco_livro FINAL)                              AS linhas_final,
       (SELECT uniqExact(data_key, upc) FROM mackenzie.g00_fato_preco_livro)                   AS chaves_do_grao
UNION ALL
SELECT 'fato_cotacao_ptax',
       (SELECT count() FROM mackenzie.g00_fato_cotacao_ptax),
       (SELECT count() FROM mackenzie.g00_fato_cotacao_ptax FINAL),
       (SELECT uniqExact(moeda, data_hora, tipo_boletim) FROM mackenzie.g00_fato_cotacao_ptax)
UNION ALL
SELECT 'fato_leitura_telemetria',
       (SELECT count() FROM mackenzie.g00_fato_leitura_telemetria),
       (SELECT count() FROM mackenzie.g00_fato_leitura_telemetria FINAL),
       (SELECT uniqExact(caminhao, instante) FROM mackenzie.g00_fato_leitura_telemetria)
UNION ALL
SELECT 'fato_alerta_direcao',
       (SELECT count() FROM mackenzie.g00_fato_alerta_direcao),
       (SELECT count() FROM mackenzie.g00_fato_alerta_direcao FINAL),
       (SELECT uniqExact(caminhao, instante) FROM mackenzie.g00_fato_alerta_direcao)
FORMAT PrettyCompactNoEscapes;

-- 2. Para onde foi cada linha de telemetria da tabela de pouso.
SELECT multiIf(match(l, '^CAM-[0-9]{4}\\|'), 'leitura, formato barra',
               match(l, '^CAM-[0-9]{4} [0-9]{2}-[0-9]{2}-'), 'leitura, formato espaço',
               startsWith(l, 'TAC;'), 'alerta de direção',
               startsWith(l, 'ERR SAT'), 'descarte: ERR SAT',
               startsWith(l, '#RADIO'), 'descarte: #RADIO',
               'descarte: outro') AS destino,
       count() AS linhas
FROM (SELECT data_json.linha::String AS l FROM mackenzie.db_ingestion WHERE data_tag = 'telemetria')
GROUP BY destino
ORDER BY linhas DESC
FORMAT PrettyCompactNoEscapes;

-- 3. Estrela: preço médio por categoria e dia da semana da coleta (fato + duas dimensões).
SELECT d.nome_dia, l.categoria, count() AS livros, round(avg(p.preco_gbp), 2) AS preco_medio_gbp
FROM mackenzie.g00_fato_preco_livro AS p FINAL
INNER JOIN mackenzie.g00_dim_livro AS l FINAL ON l.upc = p.upc
INNER JOIN mackenzie.g00_dim_data AS d ON d.data_key = p.data_key
GROUP BY d.nome_dia, l.categoria
ORDER BY livros DESC
LIMIT 5
FORMAT PrettyCompactNoEscapes;

-- 4. Alertas de direção contínua por caminhão, com a velocidade média do dia (dois fatos, mesma dimensão).
SELECT a.caminhao, count() AS alertas, max(a.direcao_continua_min) AS maior_direcao_min,
       any(r.velocidade_media) AS velocidade_media_dia
FROM mackenzie.g00_fato_alerta_direcao AS a FINAL
LEFT JOIN mackenzie.g00_rel_telemetria_caminhao_dia AS r ON r.caminhao = a.caminhao AND r.data_key = a.data_key
GROUP BY a.caminhao
ORDER BY alertas DESC
LIMIT 5
SETTINGS join_use_nulls = 1          -- caminhão sem linha no relatório aparece como NULL, não como 0
FORMAT PrettyCompactNoEscapes;

-- 5. As views do grupo: tipo de cada uma e de onde vem o dado.
SELECT name, engine,
       multiIf(engine = 'View', 'consulta guardada, roda a cada leitura',
               engine = 'MaterializedView' AND create_table_query LIKE '%REFRESH%', 'refreshable: recalcula no horário',
               engine = 'MaterializedView', 'incremental: roda a cada INSERT na origem',
               'tabela') AS como_funciona
FROM system.tables
WHERE database = 'mackenzie' AND startsWith(name, 'g00_') AND engine LIKE '%View%'
ORDER BY engine, name
FORMAT PrettyCompactNoEscapes;

-- 6. Uma view comum é só o SELECT dela: o plano mostra a leitura de g00_obs_ingestao_minuto.
EXPLAIN SELECT * FROM mackenzie.g00_v_saude_ingestao_15min;

-- 7. Estado das refreshable: último sucesso e próximo horário.
SELECT view, status, last_success_time, next_refresh_time, exception
FROM system.view_refreshes
WHERE database = 'mackenzie' AND startsWith(view, 'g00_')
FORMAT PrettyCompactNoEscapes;

-- 8. Observabilidade corrente (views em janela). Vazias se não chegou dado nos últimos minutos.
SELECT * FROM mackenzie.g00_v_saude_ingestao_15min FORMAT PrettyCompactNoEscapes;
SELECT * FROM mackenzie.g00_v_caminhoes_5min ORDER BY linhas_5min DESC FORMAT PrettyCompactNoEscapes;
SELECT * FROM mackenzie.g00_v_descartes_telemetria_1h FORMAT PrettyCompactNoEscapes;

-- ===========================================================================
-- Perguntas ao cubo. Cada resposta sai do modelo, não da tabela de pouso.
-- ===========================================================================

-- P1. Entre as categorias com pelo menos 5 livros, quais têm o preço médio mais alto em reais (último Fechamento PTAX)?
SELECT categoria, livros, preco_medio_gbp, ptax_venda, preco_medio_brl
FROM mackenzie.g00_rel_preco_categoria_dia
WHERE livros >= 5
ORDER BY preco_medio_brl DESC
LIMIT 5
FORMAT PrettyCompactNoEscapes;

-- P2. Quantos exemplares há em estoque por categoria no dia da coleta? (semiaditiva: soma entre livros)
SELECT l.categoria, count() AS livros, sum(p.qtd_estoque) AS exemplares
FROM mackenzie.g00_fato_preco_livro AS p FINAL
INNER JOIN mackenzie.g00_dim_livro AS l FINAL ON l.upc = p.upc
GROUP BY l.categoria
ORDER BY exemplares DESC
LIMIT 5
FORMAT PrettyCompactNoEscapes;

-- P3. Em que hora do dia os caminhões andam mais rápido? (não aditiva: média, nunca soma)
SELECT toHour(instante) AS hora, count() AS leituras, round(avg(velocidade_kmh), 1) AS velocidade_media
FROM mackenzie.g00_fato_leitura_telemetria FINAL
GROUP BY hora
ORDER BY velocidade_media DESC
LIMIT 5
FORMAT PrettyCompactNoEscapes;

-- P4. Qual caminhão passou mais tempo ao volante sem pausa, e quantos alertas teve?
SELECT caminhao, count() AS alertas, max(direcao_continua_min) AS maior_direcao_min
FROM mackenzie.g00_fato_alerta_direcao FINAL
GROUP BY caminhao
ORDER BY maior_direcao_min DESC
LIMIT 5
FORMAT PrettyCompactNoEscapes;

-- P5. A cotação de venda do GBP subiu ou caiu entre o primeiro e o último Fechamento?
SELECT argMin(cotacao_venda, data_hora) AS primeiro_fechamento, argMax(cotacao_venda, data_hora) AS ultimo_fechamento,
       round(100 * (ultimo_fechamento - primeiro_fechamento) / primeiro_fechamento, 2) AS variacao_pct
FROM mackenzie.g00_fato_cotacao_ptax FINAL
WHERE moeda = 'GBP' AND tipo_boletim IN ('Fechamento', 'Fechamento PTAX')
FORMAT PrettyCompactNoEscapes;
