-- =====================================================================
-- TBL: Data Collection and Storage 2026.2 · Aula 04 (31/10/2026, 11h30)
-- Caso: O servidor de ingestão que a turma montou
--
-- Três questões sobre a arquitetura de ingestão que a turma montou de
-- manhã (um processo Python sempre no ar; POST /ingest valida o envelope
-- e publica na fila RabbitMQ ingestao, com 202 ou 422; o consumidor
-- junta micro-lotes de N=500 envelopes ou T=2 s e, a cada flush, grava
-- no RustFS o raw (envelopes em JSON Lines) e o bronze (Parquet, pelo
-- DuckDB), insere em ingestao.db_ingestion no ClickHouse, grava o
-- manifesto do lote com SHA-256 de cada arquivo e só então dá o ack;
-- contrato só do envelope, com data_tag em telemetria, livros e ptax;
-- JSON cast no DuckDB e no ClickHouse):
--   1. Contrato e mudança de payload: o envelope continua válido e o
--      payload muda de forma. Retoma as etapas 02 e 04 (envelope fechado
--      e payload aberto, schema on read, rejeitados pela fila).
--   2. Ordem dos destinos: o ClickHouse cai com a fila cheia. Retoma as
--      etapas 05, 08 e 09 (raw e bronze antes do ClickHouse, manifesto
--      como recibo do lote, ack depois de tudo, at-least-once,
--      reentrega).
--   3. Forma da tabela para consulta: caminho e tipo em toda consulta.
--      Retoma as etapas 04 e 10 (tabela de três colunas, data_json no
--      tipo JSON com tipos inferidos, JSON cast medido).
--
-- Cada questão traz quatro táticas com ganho e custo declarados, e
-- nenhuma é correta: o que se mede é o deslocamento entre a decisão
-- individual e a decisão posterior à discussão.
--
-- Números do caso e das táticas: medições da preparação (30/10/2026,
-- ClickHouse 26.8.15.10, RabbitMQ 4.3.6, DuckDB 1.5.6, RustFS 1.0.4
-- local, servidor de referência com FLUSH_N=500 e FLUSH_SEGUNDOS=2,
-- telemetria de 24 h com 31.265 linhas em 1.920 TXT, 1.000 livros
-- reais, 40 boletins PTAX reais; ver laboratorio/README.md). O POST
-- /ingest (202 em 1,51 ms, 422 em 0,53 ms) e o JSON cast não tocam a
-- gravação no lake e não foram refeitos com o RustFS.
--
-- Flush medido (mediana de 30 repetições), raw + bronze + ClickHouse +
-- manifesto:
--   * 1 linha:   7,0 + 10,5 + 5,0 + 7,7 = 30,8 ms
--   * 500 linhas: 8,0 + 10,7 + 5,7 + 7,5 = 31,6 ms
--   * dia de telemetria na fila: 6,19 s e 5,98 s (5.049 e 5.226
--     linhas/s), cerca de 5.100 linhas/s; 63 partes no MergeTree e
--     189 objetos (63 raw, 63 bronze, 63 manifestos); raw 7.347.808 B,
--     bronze 617.737 B, manifestos 82.579 B, 8.048.124 B no total.
--   * kill entre o manifesto e o ack: 500 duplicadas em cada camada e
--     no ClickHouse, 64 manifestos para 63 lotes, 0 perdidas.
--
-- A questão 2 traz um dado novo, liberado só quando a discussão é aberta:
-- um ensaio de queda do ClickHouse em cenário construído para a
-- discussão e coerente com as medições. Contas do cenário:
--   * taxa assumida: 50 mensagens de telemetria por segundo, publicadas
--     direto na fila (sem o cabeçalho recebido_em_ms);
--   * queda de 20 min = 1.200 s, logo 50 x 1.200 = 60.000 mensagens;
--   * tamanho do envelope: a linha do raw do dia de telemetria tem em
--     média 7.347.808 B / 31.265 = 235 B, dos quais cerca de 45 B são o
--     invólucro {"recebido_em_ms":...,"envelope":...} e a quebra de
--     linha; o envelope fica em cerca de 190 B, logo 60.000 x 190 B =
--     11,4 MB, cerca de 11 MB na fila;
--   * comportamento do consumidor de referência
--     (laboratorio/referencia/src/consumidor.py): grava raw e bronze;
--     o INSERT falha (conexão recusada, em poucos ms, assumido); grava o
--     manifesto com status erro_clickhouse e o erro; não dá ack e
--     relança a exceção; rodar() registra a exceção, descarta o lote em
--     memória e dorme 5 s (time.sleep(5)) ainda com a conexão aberta,
--     então as 500 mensagens ficam sem ack no consumidor durante a
--     espera; só no finally a conexão fecha e o broker as devolve à
--     cabeça da fila; o laço reconecta com prefetch 500 e recebe de
--     novo as mesmas 500;
--   * ciclo: 5 s de espera + raw 8,0 + bronze 10,7 + manifesto 7,5 ms
--     + INSERT recusado + reconexão, cerca de 5,03 s; 1.200 / 5,03 =
--     239, cerca de 240 ciclos. Os dois primeiros ciclos saem com lote
--     parcial (a fila ainda tem menos de 500 e o relógio de 2 s dispara
--     antes); a partir do terceiro (cerca de 14 s) o lote enche na hora.
--     A conta usa 240 lotes de 500;
--   * cada ciclo grava 3 objetos (só telemetria, uma data): 1 JSON Lines
--     no raw, 1 Parquet no bronze e 1 manifesto com erro_clickhouse;
--     240 x 3 = 720 objetos; 240 x 500 = 120.000 envelopes repetidos
--     no raw e 120.000 linhas repetidas no bronze;
--   * bytes repetidos, pelas médias por lote do dia medido: raw
--     7.347.808 / 63 = 116.632 B por lote, x 240 = 28,0 MB; bronze
--     617.737 / 63 = 9.805 B por lote, x 240 = 2,4 MB; manifesto
--     82.579 / 63 = 1.311 B, mais até 500 B do campo erro, x 240 = 0,3
--     a 0,4 MB; total cerca de 31 MB, quase 4 vezes os 8,0 MB do dia
--     inteiro de telemetria nas três camadas;
--   * o lote nunca chega ao ClickHouse durante a queda: as outras
--     60.000 - 500 = 59.500 mensagens não chegam ao lake;
--   * sem o cabeçalho, o consumidor marca timestamp na hora em que
--     consome, então cada reentrega recebe timestamp novo (e
--     recebido_em_ms novo no raw) e um nome de lote novo (hora do
--     primeiro envelope e sufixo aleatório): nenhuma cópia sobrescreve
--     a anterior;
--   * volta: o ClickHouse volta durante uma espera de 5 s, então a
--     próxima tentativa sai em até 5 s; a drenagem leva
--     60.000 / (5.100 - 50) = 11,9 s, cerca de 12 s (as 50 msg/s
--     continuam chegando; com 5.049 e 5.226 linhas/s, 12,0 e 11,6 s);
--     do retorno à fila vazia, entre 12 e 17 s. São cerca de 121 lotes
--     com manifesto ok (60.000 + 50 x 12 = 60.600 mensagens / 500);
--   * ClickHouse sem perda e sem duplicata, porque nenhum INSERT da
--     queda chegou a gravar; o log registra uma exceção por ciclo,
--     cerca de 240.
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

O flush acontece a cada 500 envelopes ou 2 segundos, o que vier primeiro, e grava no RustFS, um object storage compatível com a API S3, com a organização da Aula 03. A ordem é fixa: os envelopes, como chegaram, vão em JSON Lines para raw/ingestao/data_tag=X/data=D/; o DuckDB grava o lote em Parquet em bronze/ingestao/data_tag=X/data=D/, uma linha por objeto de data; o clickhouse-connect insere o lote em ingestao.db_ingestion; o manifesto do lote, com contagens, chaves, bytes e SHA-256 de cada arquivo e o status, vai para raw/_manifestos/ingestao/data=D/; só então o consumidor dá o ack. O mesmo nome de lote liga as três chaves, e um manifesto com status ok quer dizer lote completo em raw, bronze e ClickHouse. A tabela tem três colunas: timestamp (UInt64, unix em milissegundos, hora da ingestão), data_json (JSON, o objeto recebido, com o tipo de cada caminho inferido no INSERT e datas guardadas como texto) e data_tag (LowCardinality). O contrato vale só para o envelope: data_tag em telemetria, livros ou ptax, e data como objeto ou lista não vazia de objetos. O conteúdo de data não é validado. A leitura pega os campos com data_json.caminho::Tipo no ClickHouse ou com ->> no DuckDB, e o DuckDB gera a partir do bronze a silver de livros e PTAX que a Aula 05 vai usar.

A preparação mediu: o POST /ingest responde 202 em 1,51 ms e 422 em 0,53 ms (p50); o flush de 500 linhas custa 31,6 ms (raw 8,0, bronze 10,7, ClickHouse 5,7 e manifesto 7,5 ms), e o de uma linha, 30,8 ms, porque o custo fixo dos três PUTs domina; um dia de telemetria, 31.265 mensagens, drena a cerca de 5.100 linhas/s com N=500 e deixa 63 partes no MergeTree e 189 objetos no lake, enquanto N=1 criaria uma parte e três objetos por mensagem; a linha fica consultável cerca de 2 s depois do POST com N=500 e o servidor ocioso; um kill entre o manifesto e o ack deixou 500 linhas duplicadas em cada camada e no ClickHouse, com dois manifestos ok para o mesmo conteúdo, sem perda. O ClickHouse 26.8 vem com async_insert ligado, e cada INSERT esperava pelo menos 50 ms até o cliente desligar a opção. Em 1 milhão de linhas, o preço médio por categoria levou 20,8 ms na coluna do tipo JSON e 146 ms com JSONExtract sobre uma coluna String. Com a inferência padrão, a coluna JSON tinha transformado coletado_em em DateTime e perdido o -03:00; o consumidor passou a inserir com a inferência de datas desligada.

As três questões revisam o servidor antes que ele receba fontes reais. A Aula 06 aprofunda a fila e o ClickHouse, e a Aula 07 trata do schema de cada domínio. Nenhuma alternativa é a correta: cada uma é uma tática com ganho e custo declarados.',
  '[
    {"rotulo":"POST /ingest","valor":"202 em 1,51 ms","nota":"p50 · 422 em 0,53 ms · 1.000 requisições por caso"},
    {"rotulo":"Flush de 500 linhas","valor":"31,6 ms","nota":"raw 8,0 · bronze 10,7 · ClickHouse 5,7 · manifesto 7,5 ms · drena cerca de 5.100 linhas/s"},
    {"rotulo":"Até consultável","valor":"cerca de 2 s","nota":"p50 de 2.053 ms com N=500 e T=2 s · 49 ms com N=1"},
    {"rotulo":"Kill entre manifesto e ack","valor":"500 duplicadas","nota":"em cada camada e no ClickHouse · 64 manifestos para 63 lotes · nenhuma perdida"},
    {"rotulo":"Lake de um dia","valor":"7,3 MB no raw, 618 KB no bronze","nota":"189 objetos: 63 JSON Lines, 63 Parquet ZSTD e 63 manifestos · telemetria"},
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
  'O time da telemetria passa a mandar o campo texto no lugar de linha e acrescenta um campo firmware. O envelope continua válido, as mensagens chegam pela fila e entram no raw, no bronze e no ClickHouse. A consulta da manhã, que extrai o caminhão de data_json.linha::String, recebe texto vazio nas linhas novas, sem erro, e elas se somam às 2.396 linhas sem caminhão que a medição já registrava. Que tática o servidor adota para mudança de payload?',
  '[
    {
      "letra":"A","titulo":"Aceitar e resolver na leitura","tatica":"Manter o contrato só do envelope",
      "texto":"O servidor continua sem olhar o conteúdo de data. Quem consulta trata as duas formas, por exemplo com coalesce entre linha e texto, e documenta a mudança na consulta.",
      "ganho":"Nenhuma mensagem é recusada, a fonte muda sem coordenar com o servidor, e o envelope original fica no raw, com o objeto no bronze e no ClickHouse, para reprocessar quando a leitura for corrigida.",
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
-- Números das táticas: flush sem o INSERT = 8,0 + 10,7 + 7,5 = 26,2 ms
-- (B e C); só o INSERT = 5,7 ms contra 31,6 ms (D); carregador a cada
-- 30 s + T=2 s = até 32 s até consultável (B).
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas, dado_novo)
values (
  'mack-dcs-a04-2026-2', 2,
  'Ordem dos destinos',
  'O ClickHouse caiu com a fila cheia',
  'Hoje o flush grava o raw, depois o bronze, insere no ClickHouse, grava o manifesto do lote e só então dá o ack. Se o INSERT falha, o consumidor grava o manifesto com status erro_clickhouse, não dá o ack, espera 5 s e fecha a conexão; a fila reentrega as mensagens e o consumidor tenta de novo. A entrega é pelo menos uma vez: no kill entre o manifesto e o ack, 500 linhas ficaram duplicadas em cada camada e no ClickHouse, com dois manifestos ok para o mesmo conteúdo. O lake é o histórico e o backup, e o ClickHouse é onde o analista consulta. Que ordem de gravação e que regra de ack o servidor adota?',
  '[
    {
      "letra":"A","titulo":"Raw, bronze, ClickHouse, manifesto e ack","tatica":"Manter a ordem atual",
      "texto":"O flush continua gravando raw e bronze, inserindo no ClickHouse e gravando o manifesto, e dá o ack só depois de tudo. Se o INSERT falha, o manifesto registra erro_clickhouse e o lote volta para a fila.",
      "ganho":"Uma mensagem só sai da fila quando está nos três destinos, e manifesto ok quer dizer lote completo, sem outra regra para conferir. A fila segura tudo durante uma queda: a queda simulada da manhã terminou com 0 mensagens perdidas.",
      "custo":"Uma queda do ClickHouse também para o lake, que deveria ser o backup. Cada nova tentativa grava outra vez o mesmo lote no raw e no bronze, com mais um manifesto de erro, e o tempo até consultável passa a ser a duração da queda."
    },
    {
      "letra":"B","titulo":"Lake e ack, carregador pelo manifesto","tatica":"ClickHouse derivado do bronze",
      "texto":"O consumidor grava raw, bronze e manifesto e dá o ack. Um carregador separado lê a cada 30 s os manifestos novos em raw/_manifestos/ingestao/, confere o SHA-256 de cada Parquet do bronze listado, insere no ClickHouse e guarda o nome do último manifesto carregado.",
      "ganho":"A queda do ClickHouse para só o carregador: raw, bronze e fila continuam andando, e o flush cai para cerca de 26 ms sem o INSERT. O carregador só lê lotes com manifesto, então um flush interrompido nunca chega ao ClickHouse, e o ClickHouse pode ser recriado a partir do bronze.",
      "custo":"O tempo até consultável sobe de cerca de 2 s para até 32 s. O manifesto deixa de dizer se o lote está no ClickHouse, e o estado do carregador é um ponto novo de falha: um manifesto carregado duas vezes duplica no ClickHouse, e o lote repetido por um kill antes do ack chega com dois manifestos válidos. Há mais um processo para operar."
    },
    {
      "letra":"C","titulo":"Uma fila por destino","tatica":"Dois consumidores independentes",
      "texto":"Uma exchange fanout copia cada mensagem para duas filas. O consumidor do lake grava raw, bronze e manifesto e dá o ack na fila dele; o do ClickHouse insere e dá o ack na outra, cada um com seu micro-lote. A Aula 06 aprofunda exchanges.",
      "ganho":"Cada destino segue no seu ritmo: a queda do ClickHouse acumula mensagens só na fila dele, e o lake continua gravando com o atraso de 2 s e um flush de cerca de 26 ms. O tempo até consultável não muda fora da queda.",
      "custo":"Os dois consumidores formam lotes diferentes, e o manifesto deixa de servir de recibo do ClickHouse. Durante a queda os destinos divergem, e a conferência de contagens por data_tag passa a ser obrigatória. Cada fila tem sua reentrega e suas duplicatas, e o grupo opera dois consumidores e duas filas."
    },
    {
      "letra":"D","titulo":"ClickHouse primeiro, lake diário","tatica":"Exportação diária do ClickHouse",
      "texto":"O flush insere no ClickHouse e dá o ack. Um job diário exporta o dia anterior de db_ingestion para o bronze, um Parquet por data_tag e dia, com um manifesto do dia.",
      "ganho":"O flush faz uma gravação em vez de quatro, 5,7 ms em vez de 31,6 ms medidos, e o lake recebe um arquivo por domínio e dia em vez de 189 objetos por dia de telemetria. Numa queda do ClickHouse, nenhuma tentativa grava objetos no lake.",
      "custo":"Até a exportação, o ClickHouse é a única cópia, e uma queda dele continua parando o consumidor. O raw deixa de existir: a tabela guarda uma linha por objeto, sem o envelope como chegou, e o boletim PTAX de 40 cotações não volta a ser uma mensagem. O lake passa a guardar o que a tabela guardou, e um erro na tabela vai junto para o backup."
    }
  ]'::jsonb,
  '{
    "titulo":"Um ensaio de queda do ClickHouse",
    "texto":"Numa sexta-feira à tarde, com o servidor da manhã no ar e a ordem atual, o contêiner do ClickHouse ficou parado por 20 minutos enquanto a telemetria chegava pela fila a 50 mensagens por segundo. O grupo cruzou o painel do RabbitMQ, o log do servidor, a listagem do RustFS, os manifestos e as contagens do ClickHouse. Os números são de um cenário construído para a discussão, coerente com as medições da preparação da aula.",
    "evidencias":[
      "A fila acumulou 60.000 mensagens em 20 minutos (50 por segundo durante 1.200 s), cerca de 11 MB a 190 bytes por envelope. O POST /ingest continuou respondendo 202, porque a API só depende da fila, e nenhum produtor percebeu a queda.",
      "O consumidor entrou num ciclo de cerca de 5 s: recebia as 500 mensagens da cabeça da fila, gravava o raw e o bronze, falhava no INSERT, gravava o manifesto com erro_clickhouse e esperava 5 s com as 500 sem ack, que o painel do RabbitMQ mostrava como Unacked. Ao fechar a conexão, o broker as devolvia à cabeça da fila.",
      "Foram cerca de 240 ciclos e 720 objetos novos no lake: 240 JSON Lines no raw e 240 Parquet no bronze, todos com as mesmas 500 mensagens (120.000 cópias em cada camada), e 240 manifestos com erro_clickhouse. Somam cerca de 31 MB, quase 4 vezes os 8,0 MB que um dia inteiro de telemetria ocupa nas três camadas.",
      "As outras 59.500 mensagens só chegaram ao lake depois que o ClickHouse voltou. Durante a queda, o raw e o bronze ficaram parados junto com o destino que deveriam cobrir, recebendo só cópias do mesmo lote.",
      "A telemetria é publicada direto na fila, sem o cabeçalho recebido_em_ms, e o consumidor marca o timestamp na hora em que consome. Cada reentrega recebeu timestamp novo e nome de lote novo, e a deduplicação pelo par timestamp e data_json não reconhece as cópias. O que separa as cópias é o status do manifesto de cada lote.",
      "Quando o ClickHouse voltou, o consumidor ainda estava na espera e levou até 5 s para tentar de novo; depois a fila drenou em cerca de 12 s (60.000 mensagens a cerca de 5.100 linhas/s, com as 50 por segundo que continuaram chegando), em cerca de 121 lotes com manifesto ok. O ClickHouse terminou sem perda e sem duplicata. O log registrou cerca de 240 exceções, e nenhum alerta foi disparado."
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
  'Até onde tipar a tabela de pouso',
  'Os analistas consultam livros, PTAX e telemetria em db_ingestion, com data_json no tipo JSON, e escrevem data_json.caminho::Tipo em toda consulta. Os tipos de cada caminho foram inferidos no INSERT, e um caminho pode guardar mais de um tipo. Na medição com 1 milhão de linhas, o preço médio por categoria levou 20,8 ms na coluna JSON, 15,5 ms com o tipo declarado no caminho e 146 ms com JSONExtract sobre uma coluna String. O Parquet tipado, lido pelo DuckDB, levou 7,5 ms. Que forma a tabela assume para quem consulta?',
  '[
    {
      "letra":"A","titulo":"Três colunas e uma view por domínio","tatica":"Conversão na leitura, escondida",
      "texto":"A tabela fica como está. Cada domínio ganha uma view, como ingestao.livros, que lê os caminhos do data_json com o tipo final, como data_json.preco_gbp::Decimal(10,2), e entrega colunas com nome e tipo ao analista.",
      "ganho":"Nada muda na escrita nem no servidor, o analista consulta colunas e não caminhos, e uma fonte nova ganha uma view sem tocar na tabela.",
      "custo":"A view não guarda nada: toda consulta continua convertendo as subcolunas, 20,8 ms por milhão de linhas contra 7,5 ms do Parquet tipado. Cada mudança de payload, como a da questão 1, exige editar a view, e um preço que chegue como texto só aparece na leitura, como erro de conversão."
    },
    {
      "letra":"B","titulo":"Tipos declarados nos caminhos do JSON","tatica":"JSON(preco_gbp Float64, ...)",
      "texto":"A coluna data_json continua do tipo JSON, mas declara o tipo dos caminhos conhecidos, como JSON(preco_gbp Float64, avaliacao UInt8, coletado_em String). Os outros caminhos seguem inferidos. A migração é um INSERT ... SELECT para uma tabela nova com o tipo declarado.",
      "ganho":"A consulta medida cai de 20,8 ms para 15,5 ms, o tipo do caminho deixa de depender do que chegou primeiro, e coletado_em declarado como String não depende mais das configurações de quem insere.",
      "custo":"A tabela genérica passa a conhecer campos de domínios, todos na mesma coluna. Um produtor que mande o preço como texto num caminho declarado Float64 faz o INSERT falhar, e o lote de todos os domínios entra no ciclo de reentrega da questão 2."
    },
    {
      "letra":"C","titulo":"Materialized view por domínio","tatica":"Colunas tipadas na inserção",
      "texto":"A tabela de três colunas continua sendo a entrada. Para cada domínio, uma materialized view lê os caminhos do data_json na hora do INSERT e grava numa tabela tipada, como ingestao.livros_tipado.",
      "ganho":"O analista consulta colunas nativas sem converter nada na leitura, como o Parquet tipado que o DuckDB leu em 7,5 ms (o equivalente no ClickHouse não foi medido). A landing segue genérica, e uma fonte nova entra sem DDL nela.",
      "custo":"Cada domínio e cada mudança de payload pedem DDL, e a view só vale para o que entrar depois dela, sem carga do histórico. Por padrão, um erro de conversão na view faz falhar o INSERT do lote inteiro, e o consumidor entra no ciclo de reentrega da questão 2, com raw, bronze e manifesto de erro gravados a cada tentativa."
    },
    {
      "letra":"D","titulo":"Uma tabela por domínio","tatica":"O servidor escreve tabelas tipadas",
      "texto":"O consumidor deixa a tabela de três colunas e insere cada data_tag numa tabela própria, com tipos declarados e ORDER BY do domínio, como upc para livros e caminhão e hora para telemetria.",
      "ganho":"Tipos declarados, ORDER BY pensado para as consultas de cada domínio e SQL direto para o analista, sem caminhos de JSON na leitura.",
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
