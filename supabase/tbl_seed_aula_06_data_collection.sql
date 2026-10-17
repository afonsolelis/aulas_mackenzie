-- =====================================================================
-- TBL — Data Collection and Storage 2026.2 · Aula 06 (14/11/2026)
-- Caso: O pipeline das estufas que a demonstração colocou no ar
--
-- Três questões sobre a arquitetura de streaming que a demonstração da
-- manhã montou (simulador de 12 sensores, RabbitMQ com exchange topic,
-- filas quorum e DLX, transformador, armazenador em lote e ClickHouse
-- com ReplacingMergeTree, token de deduplicação e TTL, cinco serviços
-- no Railway):
--   1. Idempotência no consumidor  — onde a duplicata é eliminada.
--      Retoma os blocos 3 e 5 (ack, garantias de entrega, token,
--      ReplacingMergeTree, FINAL).
--   2. Backpressure                 — o ClickHouse fica para trás.
--      Retoma os blocos 2, 4 e 5 (vazão medida, prefetch, limite de
--      fila, lote e partes).
--   3. Retenção                     — o que sobra depois do TTL.
--      Retoma os blocos 2 e 5 (fila contra log, TTL por partição,
--      compressão colunar).
--
-- Cada questão traz quatro táticas com ganho e custo declarados, e
-- nenhuma é correta: o que se mede é o deslocamento entre a decisão
-- individual e a decisão posterior à discussão.
--
-- A questão 2 traz um dado novo, liberado só quando a discussão é aberta:
-- uma semana do pipeline no Railway, em cenário construído para a
-- discussão e coerente com as medições da preparação da aula.
--
-- Usa as tabelas e RPCs hubtbl_* já instaladas no Supabase compartilhado.
-- NÃO execute hubtbl-schema.sql nem hubtbl-funcoes.sql.
--
-- O token do professor não fica no SQL versionado: o marcador
-- __TBL_HOST_TOKEN__ é substituído por scripts/tbl_db.mjs a partir do
-- .env, que o Git ignora.
--
-- Idempotente e restrito à sala 'mack-dcs-a06-2026-2'. Recusa alterar a
-- sala depois que ela começou ou recebeu participantes.
-- =====================================================================

begin;

select pg_advisory_xact_lock(hashtext('mack-dcs-a06-2026-2'));

do $$
begin
  if exists (select 1 from hubtbl_sessions
              where slug = 'mack-dcs-a06-2026-2' and fase <> 'lobby')
     or exists (select 1 from hubtbl_participantes
                 where session_slug = 'mack-dcs-a06-2026-2') then
    raise exception 'Sala já iniciada ou com participantes: seed cancelado para preservar a rodada.';
  end if;
end $$;

insert into hubtbl_sessions (slug, titulo)
values ('mack-dcs-a06-2026-2', 'TBL — O pipeline das estufas que a demonstração colocou no ar')
on conflict (slug) do update set titulo = excluded.titulo;

insert into hubtbl_host_tokens (session_slug, token)
values ('mack-dcs-a06-2026-2', '__TBL_HOST_TOKEN__')
on conflict (session_slug) do update set token = excluded.token;

-- ---------------------------------------------------------------------
-- O contexto comum das três questões
-- ---------------------------------------------------------------------
insert into hubtbl_casos (session_slug, caso_titulo, caso_texto, contexto)
values (
  'mack-dcs-a06-2026-2',
  'O pipeline das estufas que a demonstração colocou no ar',
  'A demonstração desta manhã montou o pipeline da cooperativa de mudas. Doze sensores simulados publicam uma leitura por segundo na exchange iot.leituras do RabbitMQ. O transformador valida, converte Fahrenheit, enriquece com o cadastro e republica as válidas; as inválidas vão para a DLQ com o motivo. O armazenador junta as válidas em lote e grava no ClickHouse, numa tabela ReplacingMergeTree ordenada por (device_id, medido_em). No Codespace, tudo roda com docker compose; no Railway, em cinco serviços, o limite do trial.

As decisões já tomadas são estas: filas quorum, duráveis, com limite de 20 entregas; ack manual só depois do INSERT, o que dá entrega at-least-once; token de deduplicação gerado uma vez por lote e janela de 1.000 blocos na tabela; lote fechado em 1.000 linhas ou 5 segundos, o que vier primeiro; consultas exatas com FINAL e último valor por argMax sobre medido_em; TTL de 90 dias na DDL.

Com os valores do .env.example, o lote fecha por tempo, com cerca de 60 linhas, e o ClickHouse recebe 12 INSERTs por minuto, abaixo das 1.000 linhas por lote que a documentação recomenda. Na preparação da aula, o mesmo lote enviado duas vezes com o mesmo token resultou em 3 linhas; sem token, em 6. O ReplacingMergeTree colapsa duplicatas só no merge, em momento imprevisível. Publicar com confirmação mensagem a mensagem caiu de cerca de 22 mil para cerca de 280 mensagens por segundo no RabbitMQ local. O proxy público do Railway devolve 502 de forma esporádica, e o trial dá 1 GB de RAM e vCPU compartilhada, o que pesa sobretudo sobre o ClickHouse.

A cooperativa ainda não disse em quanto tempo precisa do dado nem por quanto tempo o detalhe tem valor: latência e retenção estão na spec como hipótese. Na Aula 07, o mesmo pipeline ganha contratos e testes integrados. As três questões revisam a arquitetura antes que ela acumule semanas de leituras. Nenhuma alternativa é a correta: cada uma é uma tática com ganho e custo declarados.',
  '[
    {"rotulo":"Carga","valor":"12 leituras por segundo","nota":"12 sensores · 1.036.800 linhas por dia"},
    {"rotulo":"Lote do armazenador","valor":"≈ 60 linhas a cada 5 s","nota":"fecha por tempo · 12 INSERTs por minuto"},
    {"rotulo":"Simulador","valor":"5% inválidas · 3% duplicadas","nota":"TAXA_INVALIDAS e TAXA_DUPLICADAS do .env.example"},
    {"rotulo":"Garantia","valor":"at-least-once","nota":"ack depois do INSERT · token por lote · ReplacingMergeTree"},
    {"rotulo":"Railway trial","valor":"5 de 5 serviços","nota":"1 GB de RAM · vCPU compartilhada · 502 esporádico no proxy"},
    {"rotulo":"Retenção","valor":"90 dias","nota":"TTL na DDL · hipótese, sem resposta da persona"}
  ]'::jsonb
)
on conflict (session_slug) do update set
  caso_titulo = excluded.caso_titulo,
  caso_texto  = excluded.caso_texto,
  contexto    = excluded.contexto;

-- ---------------------------------------------------------------------
-- Questão 1 — Idempotência no consumidor
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a06-2026-2', 1,
  'Idempotência no consumidor',
  'Onde a duplicata morre',
  'O RabbitMQ entrega pelo menos uma vez: se o armazenador cair entre o INSERT e o ack, até um lote inteiro volta para a fila e pode ser agrupado de outro jeito. O simulador ainda repete 3% das leituras. Onde o grupo elimina a duplicata daqui para a frente?',
  '[
    {
      "letra":"A","titulo":"Token por lote e ReplacingMergeTree","tatica":"Duas camadas no destino",
      "texto":"O desenho atual continua: o token descarta o reenvio do mesmo lote, o ReplacingMergeTree colapsa a mesma leitura vinda em lotes diferentes, e as consultas exatas usam FINAL.",
      "ganho":"Cobre os dois casos de duplicata, já foi medido na preparação (3 linhas com token, 6 sem) e não guarda estado no consumidor, então sobrevive a reinícios.",
      "custo":"A contagem física excede a lógica até o merge, e toda consulta exata paga o FINAL. A janela de 1.000 blocos cobre cerca de 83 minutos com 12 INSERTs por minuto; um reenvio depois disso passa só pelo merge."
    },
    {
      "letra":"B","titulo":"Deduplicar no armazenador","tatica":"Estado em memória no consumidor",
      "texto":"O armazenador guarda os event_id da última hora em memória e descarta repetidos antes de montar o lote. A tabela volta a ser um MergeTree simples, sem FINAL.",
      "ganho":"As duplicatas do sensor nem chegam ao ClickHouse, a contagem física coincide com a lógica e as consultas ficam mais baratas.",
      "custo":"O estado se perde quando o processo reinicia, que é justamente o momento da reentrega. Com dois armazenadores na mesma fila, cada um vê só parte das mensagens, e a memória cresce com a janela."
    },
    {
      "letra":"C","titulo":"Guardar tudo e deduplicar na leitura","tatica":"MergeTree simples e regra na consulta",
      "texto":"A tabela guarda cada cópia recebida, com lote_id e ingerido_em. Cada consulta aplica a regra de deduplicação com GROUP BY (device_id, medido_em) ou argMax.",
      "ganho":"Nada desaparece num merge em momento imprevisível: a auditoria vê quantas vezes cada leitura chegou e de qual lote veio.",
      "custo":"A regra passa a morar em todas as consultas, e quem esquecer calcula a média com 3% de duplicatas. O disco cresce com cada reentrega."
    },
    {
      "letra":"D","titulo":"Confirmar antes de gravar","tatica":"Aceitar at-most-once",
      "texto":"O armazenador dá ack ao receber cada mensagem e grava depois, sem retry e sem token. Duplicata deixa de existir; perda passa a ser possível.",
      "ganho":"Código mais curto, sem retry nem token, e nenhuma leitura gravada duas vezes. Para uma média de 5 minutos, perder alguns segundos de leituras pode não mudar a decisão da técnica.",
      "custo":"Se o armazenador cair, o lote em memória se perde sem deixar rastro: cerca de 60 leituras no lote por tempo, até 1.000 com o lote cheio. Viola o RNF de nenhuma leitura válida perdida."
    }
  ]'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 2 — Backpressure
-- O dado novo é uma semana do pipeline no Railway, liberada na discussão.
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas, dado_novo)
values (
  'mack-dcs-a06-2026-2', 2,
  'Backpressure',
  'Quando o ClickHouse fica para trás',
  'No trial do Railway, o ClickHouse divide 1 GB de RAM entre merges, consultas e INSERTs. Quando ele responde devagar, o armazenador segura o ack, e a fila leituras.validas cresce. Que resposta ao backpressure o grupo adota?',
  '[
    {
      "letra":"A","titulo":"Lote maior, menos INSERTs","tatica":"Trocar latência por partes",
      "texto":"LOTE_MAX_SEGUNDOS passa de 5 para 30. O lote sobe de cerca de 60 para cerca de 360 linhas, e o ClickHouse recebe 2 INSERTs por minuto em vez de 12.",
      "ganho":"Seis vezes menos partes novas para o servidor juntar, menos merges disputando a memória e nenhum serviço novo. O prefetch de 1.000 continua acima do lote.",
      "custo":"Cada leitura pode esperar até 30 s antes de ser gravada, e a última janela de 5 minutos fica incompleta por mais tempo. O armazenador segura mais mensagens sem ack em memória."
    },
    {
      "letra":"B","titulo":"Limitar a fila de válidas","tatica":"x-max-length com overflow explícito",
      "texto":"A fila leituras.validas ganha um limite de tamanho, por exemplo 50 mil mensagens, com política de overflow declarada: recusar o publicador ou descartar as mais antigas para a DLX.",
      "ganho":"O broker nunca chega ao alarme de memória ou disco, e o comportamento no limite fica escrito e testável, em vez de depender do Railway.",
      "custo":"No limite, leitura válida é recusada ou descartada, o que contraria o RNF de nenhuma perda. Mudar argumentos de uma fila quorum exige recriá-la ou usar política."
    },
    {
      "letra":"C","titulo":"Segundo armazenador na mesma fila","tatica":"Mais consumidores",
      "texto":"O grupo junta transformador e armazenador num serviço (ADR-002) e usa a vaga liberada para um segundo armazenador consumindo leituras.validas.",
      "ganho":"Dobra a capacidade de consumo se o gargalo for o cliente, e cada armazenador continua simples. O RabbitMQ distribui as mensagens sem código novo.",
      "custo":"Se o gargalo for o ClickHouse, dois armazenadores dobram os INSERTs e as partes e pioram o problema. A ordem de chegada deixa de seguir a ordem de medição, e a validação passa a depender do ClickHouse."
    },
    {
      "letra":"D","titulo":"Inserção assíncrona no servidor","tatica":"async_insert=1 com wait_for_async_insert=1",
      "texto":"O armazenador envia lotes menores e mais frequentes, e o ClickHouse acumula os INSERTs num buffer antes de criar a parte. O ack só acontece quando o servidor confirma a gravação em disco.",
      "ganho":"O servidor decide o tamanho da parte, e o armazenador deixa de segurar mensagens por segundos para montar o lote. A documentação do ClickHouse recomenda esse par de configurações para muitos INSERTs pequenos.",
      "custo":"O buffer passa a ocupar a memória do próprio ClickHouse, que é o recurso escasso no trial. A interação com o token de deduplicação precisa ser testada antes, e o momento do ack deixa de ser visível no código."
    }
  ]'::jsonb,
  '{
    "titulo":"Uma semana do pipeline no Railway",
    "texto":"O grupo deixou o pipeline rodando por sete dias e cruzou list_queues, o log do armazenador, system.parts e a consulta de latência entre medido_em e ingerido_em. Os números são de um cenário construído para a discussão, coerente com as medições da preparação da aula.",
    "evidencias":[
      "Em operação normal, leituras.validas oscilou entre 0 e cerca de 60 mensagens prontas, o tamanho de um lote, e a latência p95 ficou em 6 s.",
      "Na terça à tarde, um merge grande coincidiu com as consultas da técnica. O ClickHouse passou de 900 MB de memória e levou até 40 s para responder cada INSERT.",
      "Durante 20 minutos, leituras.validas acumulou cerca de 14 mil mensagens (12 por segundo × 1.200 s) e levou 12 minutos para drenar depois que o ClickHouse voltou ao normal.",
      "As leituras desse intervalo chegaram ao ClickHouse com até 21 minutos de atraso, e a média de 5 minutos das estufas ficou vazia nesse período.",
      "Na mesma semana, a cooperativa respondeu à pergunta da latência: a técnica precisa saber de uma estufa fora da faixa em até 10 minutos."
    ],
    "pergunta":"Diante do que a semana registrou, qual resposta ao backpressure permanece? Declare se a sua escolha anterior sobrevive a este dado e por quê."
  }'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 3 — Retenção
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a06-2026-2', 3,
  'Retenção',
  'O que sobra depois de 90 dias',
  'O TTL de 90 dias apaga o detalhe por partição mensal, e as filas do RabbitMQ não guardam nada depois do ack. Em 90 dias são cerca de 93 milhões de linhas. Se a faixa física da validação mudar, ou se a cooperativa quiser comparar este verão com o próximo, o que precisa existir?',
  '[
    {
      "letra":"A","titulo":"Manter só o TTL de 90 dias","tatica":"Detalhe curto e nada mais",
      "texto":"A tabela continua como está: o detalhe vive 90 dias e expira em partes mensais inteiras. O ADR registra que comparação entre anos fica fora do escopo até a persona pedir.",
      "ganho":"Remoção barata, disco do trial sob controle e nenhum componente novo. A decisão é reversível enquanto o dado ainda existe.",
      "custo":"Depois de 90 dias não há como recalcular nada, e o RabbitMQ não guarda o passado para reprocessar. A retenção continua uma hipótese que ninguém validou."
    },
    {
      "letra":"B","titulo":"Agregar antes de apagar","tatica":"View materializada de 5 minutos",
      "texto":"Uma view materializada grava a média de 5 minutos por sensor numa segunda tabela, sem TTL. O detalhe continua expirando em 90 dias.",
      "ganho":"A história de longo prazo cabe em 3.456 linhas por dia (12 sensores × 288 janelas), contra 1.036.800 do detalhe, e responde à comparação entre verões.",
      "custo":"O agregado fixa a pergunta: um percentil ou outra janela não se recalcula depois. A view recebe cada INSERT antes do merge, então as duplicatas que o ReplacingMergeTree colapsaria entram na média."
    },
    {
      "letra":"C","titulo":"Exportar Parquet para o lake","tatica":"Arquivar no object storage",
      "texto":"Antes de cada partição expirar, um job exporta o mês com FINAL em Parquet para o MinIO das Aulas 02 a 04, numa chave particionada por mês.",
      "ganho":"O detalhe fica preservado em formato colunar e barato, legível pelo DuckDB da Aula 04, e o ClickHouse continua leve.",
      "custo":"Mais um job para operar, sem vaga livre no Railway, e que precisa rodar antes do TTL. Se falhar num mês, aquele mês se perde sem aviso."
    },
    {
      "letra":"D","titulo":"Trocar a fila por um stream","tatica":"Log com retenção no broker",
      "texto":"As leituras brutas passam a ir para um stream do RabbitMQ com retenção por tempo, e o transformador consome por offset. Mudou a regra de validação, o grupo relê o período.",
      "ganho":"Reprocessar o passado vira operação do broker, inclusive para as leituras que a regra antiga mandou para a DLQ.",
      "custo":"Muda o modelo de consumo de ack para offset e exige reescrever os consumidores. O disco do broker no trial passa a guardar o histórico, e a retenção fica duplicada em dois lugares."
    }
  ]'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- Remove questões excedentes de uma execução anterior desta mesma sala.
delete from hubtbl_questoes where session_slug = 'mack-dcs-a06-2026-2' and ordem > 3;

do $$
begin
  if (select count(*) from hubtbl_questoes where session_slug = 'mack-dcs-a06-2026-2') <> 3 then
    raise exception 'A sala deve conter exatamente 3 questões.';
  end if;
end $$;

commit;
