-- =====================================================================
-- TBL: Data Collection and Storage 2026.2 · Aula 04 (31/10/2026, 11h30)
-- Caso: O servidor de ingestão que a turma montou
--
-- Três questões sobre a arquitetura de ingestão que a turma montou de
-- manhã (um processo Python sempre no ar; POST /ingest valida o envelope
-- e publica na fila RabbitMQ ingestao, com 202 ou 422; o consumidor
-- junta micro-lotes de N=500 envelopes ou T=2 s e, a cada flush, grava
-- Parquet no MinIO com DuckDB, insere em ingestao.db_ingestion no
-- ClickHouse e só então dá o ack; contrato só do envelope, com data_tag
-- em telemetria, livros e ptax; JSON cast no DuckDB e no ClickHouse):
--   1. Contrato e mudança de payload: o envelope continua válido e o
--      payload muda de forma. Retoma as etapas 02 e 04 (envelope fechado
--      e payload aberto, schema on read, rejeitados pela fila).
--   2. Ordem dos destinos: o ClickHouse cai com a fila cheia. Retoma as
--      etapas 05, 08 e 09 (lake antes do ClickHouse, ack depois de
--      gravar, at-least-once, reentrega).
--   3. Forma da tabela para consulta: JSONExtract em toda consulta.
--      Retoma as etapas 04 e 10 (tabela de três colunas, String contra
--      tipo JSON, JSON cast medido).
--
-- Cada questão traz quatro táticas com ganho e custo declarados, e
-- nenhuma é correta: o que se mede é o deslocamento entre a decisão
-- individual e a decisão posterior à discussão.
--
-- Números do caso e das táticas: medições da preparação (30/10/2026,
-- ClickHouse 26.8.15.10, RabbitMQ 4.3.6, DuckDB 1.5.6, MinIO local,
-- telemetria de 24 h do gerar_lotes.py da Aula 02 com 31.265 linhas,
-- 1.000 livros reais, 40 boletins PTAX reais).
--
-- A questão 2 traz um dado novo, liberado só quando a discussão é aberta:
-- um ensaio de queda do ClickHouse em cenário construído para a
-- discussão e coerente com as medições. Contas do cenário:
--   * taxa assumida: 50 mensagens de telemetria por segundo, publicadas
--     direto na fila (sem o cabeçalho recebido_em_ms);
--   * queda de 20 min = 1.200 s, logo 50 x 1.200 = 60.000 mensagens;
--   * tamanho: o dia de telemetria em JSON Lines deu 5.847.088 B para
--     31.265 linhas (187 B por linha); o envelope tem tamanho parecido,
--     cerca de 190 B, logo 60.000 x 190 B = 11,4 MB, cerca de 11 MB;
--   * comportamento do consumidor de referência (src/consumidor.py): na
--     exceção, descarta o lote sem ack, fecha a conexão (o broker
--     devolve as mensagens à fila) e espera 5 s. Com a fila acima de 500
--     mensagens, o lote enche na hora, o lake grava (5,2 ms medidos) e o
--     INSERT falha por conexão recusada; ciclo de cerca de 5 s, logo
--     1.200 / 5 = cerca de 240 ciclos, cada um com um Parquet das mesmas
--     500 mensagens da cabeça da fila: 240 x 500 = 120.000 linhas
--     repetidas no lake; as outras 60.000 - 500 = 59.500 não chegam ao
--     lake durante a queda;
--   * sem o cabeçalho, o consumidor marca timestamp na hora em que
--     consome, então cada reentrega recebe timestamp novo;
--   * drenagem na volta: 60.000 / 8.147 linhas/s (N=500 medido) = 7,4 s,
--     mais as 50 msg/s que continuam chegando, cerca de 8 s.
--
-- Usa as tabelas e RPCs hubtbl_* já instaladas no Supabase compartilhado.
-- NÃO execute hubtbl-schema.sql nem hubtbl-funcoes.sql.
--
-- O token do professor não fica no SQL versionado: o marcador
-- __TBL_HOST_TOKEN__ é substituído por scripts/tbl_db.mjs a partir do
-- .env, que o Git ignora.
--
-- Idempotente e restrito à sala 'mack-dcs-a04-2026-2'. Recusa alterar a
-- sala depois que ela começou ou recebeu participantes.
-- =====================================================================

begin;

select pg_advisory_xact_lock(hashtext('mack-dcs-a04-2026-2'));

do $$
begin
  if exists (select 1 from hubtbl_sessions
              where slug = 'mack-dcs-a04-2026-2' and fase <> 'lobby')
     or exists (select 1 from hubtbl_participantes
                 where session_slug = 'mack-dcs-a04-2026-2') then
    raise exception 'Sala já iniciada ou com participantes: seed cancelado para preservar a rodada.';
  end if;
end $$;

insert into hubtbl_sessions (slug, titulo)
values ('mack-dcs-a04-2026-2', 'TBL: o servidor de ingestão que a turma montou')
on conflict (slug) do update set titulo = excluded.titulo;

insert into hubtbl_host_tokens (session_slug, token)
values ('mack-dcs-a04-2026-2', '__TBL_HOST_TOKEN__')
on conflict (session_slug) do update set token = excluded.token;

-- ---------------------------------------------------------------------
-- O contexto comum das três questões
-- ---------------------------------------------------------------------
insert into hubtbl_casos (session_slug, caso_titulo, caso_texto, contexto)
values (
  'mack-dcs-a04-2026-2',
  'O servidor de ingestão que a turma montou',
  'Nesta manhã, cada grupo montou um servidor de ingestão: um processo Python que fica no ar e recebe dados por dois caminhos. Pelo HTTP, o POST /ingest valida o envelope, publica a mensagem na fila ingestao do RabbitMQ e responde 202; envelope inválido recebe 422. Pela fila, qualquer sistema publica direto. Uma thread do mesmo processo consome a fila, valida o envelope de novo, porque a fila aceita qualquer coisa, e grava o inválido em raw/ingestao_rejeitados/ com ack. O válido entra num micro-lote em memória.

O flush acontece a cada 500 envelopes ou 2 segundos, o que vier primeiro, e segue uma ordem fixa: o DuckDB grava o lote em Parquet no MinIO, em raw/ingestao/data_tag=X/data=D/, que serve de histórico e backup; o clickhouse-connect insere o lote em ingestao.db_ingestion; só então o consumidor dá o ack. A tabela tem três colunas: timestamp (UInt64, unix em milissegundos, hora da ingestão), data_json (String, o objeto recebido como texto) e data_tag (LowCardinality). O contrato vale só para o envelope: data_tag em telemetria, livros ou ptax, e data como objeto ou lista não vazia de objetos. O conteúdo de data não é validado. A leitura extrai os campos com JSONExtract no ClickHouse ou com ->> no DuckDB, e o DuckDB gera a partir do lake a silver de livros e PTAX que a Aula 05 vai usar.

A preparação mediu: o POST /ingest responde 202 em 1,51 ms e 422 em 0,53 ms (p50); um dia de telemetria, 31.265 mensagens, drena a 8.147 linhas/s com N=500 e a 60 linhas/s com N=1, que cria uma parte no MergeTree e um objeto no lake por mensagem; a linha fica consultável cerca de 2 s depois do POST com N=500 e o servidor ocioso; um kill entre o INSERT e o ack deixou 500 linhas duplicadas no lake e no ClickHouse, sem perda. O ClickHouse 26.8 vem com async_insert ligado, e cada INSERT esperava pelo menos 50 ms até o cliente desligar a opção. Em 1 milhão de linhas, o preço médio por categoria levou 146 ms com JSONExtract sobre String e 20,8 ms numa coluna do tipo JSON, que inferiu coletado_em como DateTime e perdeu o -03:00.

As três questões revisam o servidor antes que ele receba fontes reais. A Aula 06 aprofunda a fila e o ClickHouse, e a Aula 07 trata do schema de cada domínio. Nenhuma alternativa é a correta: cada uma é uma tática com ganho e custo declarados.',
  '[
    {"rotulo":"POST /ingest","valor":"202 em 1,51 ms","nota":"p50 · 422 em 0,53 ms · 1.000 requisições por caso"},
    {"rotulo":"Micro-lote","valor":"8.147 contra 60 linhas/s","nota":"N=500 contra N=1 · 63 contra 31.265 partes no MergeTree"},
    {"rotulo":"Até consultável","valor":"cerca de 2 s","nota":"p50 de 2.030 ms com N=500 e T=2 s · 34 ms com N=1"},
    {"rotulo":"Kill entre INSERT e ack","valor":"500 duplicadas","nota":"em cada destino · nenhuma mensagem perdida"},
    {"rotulo":"Lake de um dia","valor":"632 KB contra 5,8 MB","nota":"63 Parquet ZSTD contra JSON Lines · telemetria"},
    {"rotulo":"JSON cast","valor":"146 ms contra 20,8 ms","nota":"JSONExtract em String contra coluna JSON · 1 milhão de linhas"}
  ]'::jsonb
)
on conflict (session_slug) do update set
  caso_titulo = excluded.caso_titulo,
  caso_texto  = excluded.caso_texto,
  contexto    = excluded.contexto;

-- ---------------------------------------------------------------------
-- Questão 1: contrato e mudança de payload
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a04-2026-2', 1,
  'Contrato e mudança de payload',
  'O payload da telemetria mudou de forma',
  'O time da telemetria passa a mandar o campo texto no lugar de linha e acrescenta um campo firmware. O envelope continua válido, as mensagens chegam pela fila e entram no lake e no ClickHouse. A consulta da manhã, que extrai o caminhão com JSONExtractString sobre o campo linha, recebe texto vazio nas linhas novas, sem erro, e elas se somam às 2.396 linhas sem caminhão que a medição já registrava. Que tática o servidor adota para mudança de payload?',
  '[
    {
      "letra":"A","titulo":"Aceitar e resolver na leitura","tatica":"Manter o contrato só do envelope",
      "texto":"O servidor continua sem olhar o conteúdo de data. Quem consulta trata as duas formas, por exemplo com coalesce entre linha e texto, e documenta a mudança na consulta.",
      "ganho":"Nenhuma mensagem é recusada, a fonte muda sem coordenar com o servidor, e o texto original fica no lake e no ClickHouse para reprocessar quando a leitura for corrigida.",
      "custo":"A consulta erra em silêncio até alguém notar o texto vazio. Cada leitor descobre a mudança sozinho e acumula um ramo por forma, e o mesmo vale para livros e PTAX, de que a silver da Aula 05 depende."
    },
    {
      "letra":"B","titulo":"Schema registrado por domínio","tatica":"422 para o que não casa",
      "texto":"Cada data_tag ganha um schema registrado no servidor, e o objeto que não casa é recusado com 422 no HTTP. A mudança só passa depois que o time registra a nova forma.",
      "ganho":"O produtor HTTP recebe 422 com o motivo no momento do envio, em cerca de 0,5 ms, e nada com forma desconhecida entra no lake nem no ClickHouse.",
      "custo":"O contrato deixa de valer só para o envelope e antecipa o trabalho da Aula 07, e toda mudança de fonte passa por registro e deploy. A telemetria chega pela fila, onde não existe 422: as mensagens vão para raw/ingestao_rejeitados/ e o produtor só descobre se alguém olhar."
    },
    {
      "letra":"C","titulo":"Versão declarada no envelope","tatica":"Campo data_version",
      "texto":"O envelope ganha o campo data_version, gravado com cada linha. O produtor sobe a versão quando muda o payload, e os leitores tratam cada versão separadamente.",
      "ganho":"A mudança fica declarada em cada linha e o leitor filtra por versão sem adivinhar a forma. O servidor continua sem validar o payload.",
      "custo":"O envelope fechado muda: hoje um campo extra recebe 422, então todos os produtores e a tabela, com uma coluna nova ou a versão dentro do data_json, precisam acompanhar. Ninguém confere a versão declarada, e um time que esquece de subi-la volta ao problema."
    },
    {
      "letra":"D","titulo":"Quarentena por forma divergente","tatica":"Comparar com o último schema visto",
      "texto":"O consumidor guarda, por data_tag, o conjunto de chaves do último lote aceito e grava em raw/ingestao_quarentena/, com ack, os objetos cujas chaves divergem, até alguém aprovar a forma nova.",
      "ganho":"A mudança aparece na primeira mensagem, sem que o produtor avise, e o ClickHouse só recebe a forma nova depois de revisada. Vale também para o caminho da fila.",
      "custo":"Toda a telemetria nova deixa de chegar ao ClickHouse até a aprovação. O último schema visto é estado que precisa sobreviver ao reinício, um campo opcional ausente vira falso alarme, e a comparação roda no processo da API: com o consumidor ocupado, o p95 do 422 subiu de 1 para 10 ms."
    }
  ]'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 2: ordem dos destinos e queda do ClickHouse
-- O dado novo é um ensaio de queda, liberado na discussão (contas no
-- cabeçalho deste arquivo).
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas, dado_novo)
values (
  'mack-dcs-a04-2026-2', 2,
  'Ordem dos destinos',
  'O ClickHouse caiu com a fila cheia',
  'Hoje o flush grava o lake, depois o ClickHouse, e só então dá o ack. Se o INSERT falha, o consumidor descarta o lote sem ack, a fila reentrega as mensagens e o consumidor tenta de novo depois de 5 s. A entrega é pelo menos uma vez: no kill entre o INSERT e o ack, 500 linhas ficaram duplicadas em cada destino. O lake é o histórico e o backup, e o ClickHouse é onde o analista consulta. Que ordem de gravação e que regra de ack o servidor adota?',
  '[
    {
      "letra":"A","titulo":"Lake, ClickHouse e ack","tatica":"Manter a ordem atual",
      "texto":"O flush continua gravando o lake, inserindo no ClickHouse e dando o ack só depois dos dois. Se qualquer destino falha, o lote volta para a fila.",
      "ganho":"Uma mensagem só sai da fila quando está nos dois destinos, e a fila segura tudo durante uma queda: a queda simulada da manhã terminou com 0 mensagens perdidas. Um consumidor e uma regra só.",
      "custo":"Uma queda do ClickHouse também para o lake, que deveria ser o backup. Cada nova tentativa grava o lote no lake outra vez, e o tempo até consultável passa a ser a duração da queda."
    },
    {
      "letra":"B","titulo":"Lake e ack, carregador separado","tatica":"ClickHouse derivado do lake",
      "texto":"O consumidor grava o lake e dá o ack. Um carregador separado lista a cada 30 s os arquivos novos em raw/ingestao/, insere no ClickHouse e guarda o nome do último arquivo carregado.",
      "ganho":"A queda do ClickHouse para só o carregador: o lake continua recebendo e a fila continua andando. O ClickHouse vira derivado do lake e pode ser recriado a partir dele.",
      "custo":"O tempo até consultável sobe de cerca de 2 s para até 32 s. O estado do carregador é um ponto novo de falha, um arquivo carregado duas vezes duplica no ClickHouse, e há mais um processo para operar."
    },
    {
      "letra":"C","titulo":"Uma fila por destino","tatica":"Dois consumidores independentes",
      "texto":"Uma exchange fanout copia cada mensagem para duas filas, uma do lake e outra do ClickHouse, cada uma com seu consumidor, seu micro-lote e seu ack. A Aula 06 aprofunda exchanges.",
      "ganho":"Cada destino segue no seu ritmo: a queda do ClickHouse acumula mensagens só na fila dele, e o lake continua gravando com o atraso de 2 s. O tempo até consultável não muda fora da queda.",
      "custo":"Durante a queda os destinos divergem, e a conferência de contagens por data_tag passa a ser obrigatória. Cada fila tem sua reentrega e suas duplicatas, e o grupo opera dois consumidores e duas filas."
    },
    {
      "letra":"D","titulo":"ClickHouse primeiro, lake diário","tatica":"Exportação diária do ClickHouse",
      "texto":"O flush insere no ClickHouse e dá o ack. Um job diário exporta o dia anterior de db_ingestion para Parquet no lake, um arquivo por data_tag e dia.",
      "ganho":"O caminho do flush faz uma gravação em vez de duas, 4,0 ms em vez de 9,2 ms medidos, e o lake recebe um arquivo por domínio e dia em vez de 63 arquivos por dia de telemetria.",
      "custo":"Até a exportação, o ClickHouse é a única cópia, e uma queda dele continua parando o consumidor. O lake passa a guardar o que a tabela guardou, e um erro na tabela vai junto para o backup."
    }
  ]'::jsonb,
  '{
    "titulo":"Um ensaio de queda do ClickHouse",
    "texto":"Numa sexta-feira à tarde, com o servidor da manhã no ar e a ordem atual, o contêiner do ClickHouse ficou parado por 20 minutos enquanto a telemetria chegava pela fila a 50 mensagens por segundo. O grupo cruzou o painel do RabbitMQ, o log do servidor, a listagem do lake e as contagens do ClickHouse. Os números são de um cenário construído para a discussão, coerente com as medições da preparação da aula.",
    "evidencias":[
      "A fila acumulou 60.000 mensagens em 20 minutos (50 por segundo durante 1.200 s), cerca de 11 MB a 190 bytes por mensagem. O POST /ingest continuou respondendo 202, porque a API só depende da fila, e nenhum produtor percebeu a queda.",
      "O consumidor entrou num ciclo de cerca de 5 s: recebia as 500 mensagens da cabeça da fila, gravava o Parquet no lake, falhava no INSERT, descartava o lote sem ack e esperava. Foram cerca de 240 ciclos e 240 arquivos no lake com as mesmas 500 mensagens, ou 120.000 linhas repetidas.",
      "As outras 59.500 mensagens só chegaram ao lake depois que o ClickHouse voltou. Durante a queda, o backup ficou parado junto com o destino que ele deveria cobrir.",
      "A telemetria é publicada direto na fila, sem o cabeçalho recebido_em_ms, e o consumidor marca o timestamp na hora em que consome. Cada reentrega recebeu um timestamp novo, e a deduplicação pelo par timestamp e data_json não reconhece as cópias do lake.",
      "Quando o ClickHouse voltou, a fila drenou em cerca de 8 s (60.000 mensagens a 8.147 linhas/s), e o ClickHouse terminou sem perda e sem duplicata. O log registrou cerca de 240 exceções, e nenhum alerta foi disparado."
    ],
    "pergunta":"Diante do que o ensaio registrou, qual ordem permanece? Declare se a sua escolha anterior sobrevive a este dado e por quê."
  }'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 3: forma da tabela para consulta
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a04-2026-2', 3,
  'Forma da tabela para consulta',
  'Extrair o JSON na escrita ou na leitura',
  'Os analistas consultam livros, PTAX e telemetria em db_ingestion e escrevem JSONExtract em toda consulta. Na medição com 1 milhão de linhas, o preço médio por categoria levou 146 ms com JSONExtract sobre String, 75 ms com simpleJSONExtract, 957 ms com CAST para JSON na consulta e 20,8 ms numa coluna do tipo JSON. O Parquet tipado, lido pelo DuckDB, levou 7,5 ms. Que forma a tabela assume para quem consulta?',
  '[
    {
      "letra":"A","titulo":"Três colunas e uma view por domínio","tatica":"Extração na leitura, escondida",
      "texto":"A tabela fica como está. Cada domínio ganha uma view, como ingestao.livros, que faz o JSONExtract e entrega colunas com nome e tipo ao analista.",
      "ganho":"Nada muda na escrita nem no servidor, o analista consulta colunas e não JSON, e uma fonte nova ganha uma view sem tocar na tabela.",
      "custo":"A view não guarda nada: toda consulta continua pagando a extração, 146 ms por milhão de linhas contra 20,8 ms. Cada mudança de payload, como a da questão 1, exige editar a view, e um tipo errado só aparece na leitura."
    },
    {
      "letra":"B","titulo":"data_json com o tipo JSON","tatica":"Subcolunas inferidas na escrita",
      "texto":"A coluna data_json passa a ser do tipo JSON do ClickHouse, que separa cada caminho em subcolunas tipadas no INSERT. A migração é um INSERT ... SELECT da tabela atual.",
      "ganho":"A consulta medida cai de 146 ms para 20,8 ms, e o armazenamento comprimido caiu de 97,6 MB para 23,4 MB na amostra de 1 milhão de linhas. A migração levou 1,02 s por milhão de linhas.",
      "custo":"Os tipos são inferidos na inserção: coletado_em virou DateTime em UTC e perdeu o -03:00. O texto exato que chegou deixa de existir no ClickHouse, e um produtor que mande o preço como texto muda o tipo da subcoluna."
    },
    {
      "letra":"C","titulo":"Materialized view por domínio","tatica":"Colunas tipadas na inserção",
      "texto":"A tabela de três colunas continua sendo a entrada. Para cada domínio, uma materialized view extrai as colunas na hora do INSERT e grava numa tabela tipada, como ingestao.livros_tipado.",
      "ganho":"O analista consulta colunas nativas sem extrair nada na leitura, como o Parquet tipado que o DuckDB leu em 7,5 ms (o equivalente no ClickHouse não foi medido). A landing segue genérica, e uma fonte nova entra sem DDL nela.",
      "custo":"Cada domínio e cada mudança de payload pedem DDL, e a view só vale para o que entrar depois dela, sem carga do histórico. Por padrão, um erro de conversão na view faz falhar o INSERT do lote inteiro, e o consumidor entra no ciclo de reentrega da questão 2."
    },
    {
      "letra":"D","titulo":"Uma tabela por domínio","tatica":"O servidor escreve tabelas tipadas",
      "texto":"O consumidor deixa a tabela de três colunas e insere cada data_tag numa tabela própria, com tipos declarados e ORDER BY do domínio, como upc para livros e caminhão e hora para telemetria.",
      "ganho":"Tipos declarados, ORDER BY pensado para as consultas de cada domínio e SQL direto para o analista, sem JSON na leitura.",
      "custo":"O servidor passa a conhecer o payload e o contrato deixa de ser só do envelope. Uma fonte nova exige DDL, código e deploy, e um payload que mude, como o da questão 1, falha no INSERT e trava o lote de todos os domínios."
    }
  ]'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- Remove questões excedentes de uma execução anterior desta mesma sala.
delete from hubtbl_questoes where session_slug = 'mack-dcs-a04-2026-2' and ordem > 3;

do $$
begin
  if (select count(*) from hubtbl_questoes where session_slug = 'mack-dcs-a04-2026-2') <> 3 then
    raise exception 'A sala deve conter exatamente 3 questões.';
  end if;
end $$;

commit;
