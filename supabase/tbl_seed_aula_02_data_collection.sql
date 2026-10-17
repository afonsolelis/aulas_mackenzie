-- =====================================================================
-- TBL — Data Collection and Storage 2026.2 · Aula 02 (17/10/2026)
-- Caso: O coletor que a demonstração colocou no ar
--
-- Três questões sobre a arquitetura que a demonstração da manhã montou
-- (coletor dos lotes TXT de telemetria de caminhões: pasta de pouso no
-- papel do SFTP do provedor por satélite, MinIO local em Docker e MinIO
-- de um nó no Railway, bucket raw com chave particionada pela janela em
-- UTC, HEAD antes do PUT, metadados de procedência com sha256, manifesto
-- em JSON Lines e remoção do pouso só depois da confirmação):
--   1. Durabilidade da camada bruta  — um nó, um volume, lotes que o
--      provedor não reenvia e que servem de prova de jornada. Retoma os
--      blocos 2 e 3 (tipos de storage, garantias do object storage,
--      versionamento).
--   2. Política de escrita           — 502 do proxy, disparo duplo e
--      retransmissão com conteúdo diferente. Retoma o bloco 5
--      (idempotência, imutabilidade e procedência).
--   3. Linhas sem formato            — cinco formatos, texto livre e o
--      TEMP_BAU do firmware novo: quando e onde interpretar o TXT.
--      Retoma o bloco 4 (storage contra data lake, schema on read e on
--      write, lake e lakehouse).
--
-- Cada questão traz quatro táticas com ganho e custo declarados, e
-- nenhuma é correta: o que se mede é o deslocamento entre a decisão
-- individual e a decisão posterior à discussão.
--
-- A questão 2 traz um dado novo, liberado só quando a discussão é aberta:
-- uma semana do coletor no Railway, em cenário construído para a
-- discussão e coerente com as medições da preparação da aula
-- (16/10/2026, MinIO RELEASE.2025-10-15T17-29-55Z).
--
-- Usa as tabelas e RPCs hubtbl_* já instaladas no Supabase compartilhado.
-- NÃO execute hubtbl-schema.sql nem hubtbl-funcoes.sql.
--
-- O token do professor não fica no SQL versionado: o marcador
-- __TBL_HOST_TOKEN__ é substituído por scripts/tbl_db.mjs a partir do
-- .env, que o Git ignora.
--
-- Idempotente e restrito à sala 'mack-dcs-a02-2026-2'. Recusa alterar a
-- sala depois que ela começou ou recebeu participantes.
-- =====================================================================

begin;

select pg_advisory_xact_lock(hashtext('mack-dcs-a02-2026-2'));

do $$
begin
  if exists (select 1 from hubtbl_sessions
              where slug = 'mack-dcs-a02-2026-2' and fase <> 'lobby')
     or exists (select 1 from hubtbl_participantes
                 where session_slug = 'mack-dcs-a02-2026-2') then
    raise exception 'Sala já iniciada ou com participantes: seed cancelado para preservar a rodada.';
  end if;
end $$;

insert into hubtbl_sessions (slug, titulo)
values ('mack-dcs-a02-2026-2', 'TBL — O coletor que a demonstração colocou no ar')
on conflict (slug) do update set titulo = excluded.titulo;

insert into hubtbl_host_tokens (session_slug, token)
values ('mack-dcs-a02-2026-2', '__TBL_HOST_TOKEN__')
on conflict (session_slug) do update set token = excluded.token;

-- ---------------------------------------------------------------------
-- O contexto comum das três questões
-- ---------------------------------------------------------------------
insert into hubtbl_casos (session_slug, caso_titulo, caso_texto, contexto)
values (
  'mack-dcs-a02-2026-2',
  'O coletor que a demonstração colocou no ar',
  'A demonstração desta manhã montou a camada bruta da transportadora. O provedor de rastreamento por satélite entrega, para cada caminhão, um lote TXT a cada 15 minutos, com linhas do tacógrafo, do GPS e do rádio em cinco formatos misturados, e não guarda histórico. Um coletor em Python lê os lotes da pasta de pouso, que faz o papel do SFTP do provedor, e grava cada um, sem alterar um byte, no bucket raw do MinIO. No Codespace, o MinIO roda em Docker para desenvolver; na coleta contínua, roda no Railway, como um único serviço com um volume montado em /data.

As decisões já tomadas são estas: chave telemetria/data=AAAA-MM-DD/hora=HH/caminhao=CAM-XXXX/lote_HHMM.txt, com o início da janela em UTC; HEAD antes do PUT, de modo que a primeira gravação da janela vale; sete metadados de procedência por objeto, entre eles o sha256 do lote; um manifesto em JSON Lines por execução; versionamento ligado no bucket; e o arquivo só sai do pouso depois de a gravação ser confirmada. A API compatível com S3 permite levar o mesmo código para outro provedor trocando o endpoint e as credenciais.

A preparação da aula mediu 1.018 bytes por lote, cerca de 7,0 KB em disco por objeto no MinIO local, e medianas de 4,56 ms por PUT e 2,95 ms por GET, sem rede. O proxy do Railway devolve 502 de forma esporádica, e um 502 não prova que o PUT falhou. O sistema de arquivos do volume do Railway não foi verificado, e a garantia de consistência do MinIO depende dele.

O lote é prova de jornada: a linha de alerta do tacógrafo acima de 5h30 de direção contínua pode ser cobrada numa fiscalização ou num processo trabalhista meses depois. Na Aula 04, a raw vira a origem do lakehouse. As três questões revisam a arquitetura antes que ela acumule meses de lotes. Nenhuma alternativa é a correta: cada uma é uma tática com ganho e custo declarados.',
  '[
    {"rotulo":"Frota em sala","valor":"80 lotes por hora","nota":"20 caminhões × 4 janelas · 1.920 por dia"},
    {"rotulo":"Em disco","valor":"7,0 KB por objeto","nota":"1,0 KB de conteúdo · medido no MinIO local"},
    {"rotulo":"PUT mediano","valor":"4,56 ms","nota":"MinIO local, sem rede"},
    {"rotulo":"MinIO no Railway","valor":"1 nó, 1 volume","nota":"sem redundância · sistema de arquivos não verificado"},
    {"rotulo":"Proxy do Railway","valor":"502 esporádico","nota":"o PUT pode ter chegado mesmo assim"},
    {"rotulo":"Valor do lote","valor":"prova de jornada","nota":"alerta acima de 5h30 · Lei 13.103/2015"}
  ]'::jsonb
)
on conflict (session_slug) do update set
  caso_titulo = excluded.caso_titulo,
  caso_texto  = excluded.caso_texto,
  contexto    = excluded.contexto;

-- ---------------------------------------------------------------------
-- Questão 1 — Durabilidade da camada bruta
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a02-2026-2', 1,
  'Durabilidade da camada bruta',
  'Um nó, um volume, a prova da jornada',
  'A raw guarda o que o provedor não entrega de novo: o lote original de cada janela, que pode ser a única prova de uma jornada numa fiscalização ou num processo trabalhista. Hoje ela vive em um MinIO de um nó, num único volume do Railway, e a perda desse volume apaga essa prova. Que decisão o grupo toma sobre onde a camada bruta mora daqui para a frente?',
  '[
    {
      "letra":"A","titulo":"Manter o nó e espelhar todo dia","tatica":"Cópia para um segundo destino",
      "texto":"O MinIO de um nó continua como está, e um job diário copia o bucket raw com mc mirror para um segundo destino, em outro provedor, com a data da última cópia registrada no manifesto.",
      "ganho":"Elimina a perda total do histórico com pouco código e sem mudar o coletor. O espelho usa a mesma API S3, e restaurar é copiar de volta.",
      "custo":"Dobra o armazenamento e cria um segundo serviço para operar. Os lotes do dia ainda não espelhados ficam expostos por até 24 horas, e uma gravação errada é copiada do mesmo jeito que uma correta."
    },
    {
      "letra":"B","titulo":"Levar a raw para o Amazon S3","tatica":"Armazenamento gerenciado",
      "texto":"A coleta contínua passa a gravar num bucket do Amazon S3, com versionamento e ciclo de vida iguais aos de hoje. O MinIO fica só no Codespace, para desenvolver e testar.",
      "ganho":"Durabilidade e redundância passam a ser do provedor, e o código muda só no endpoint e nas credenciais. A decisão aproveita exatamente a portabilidade que justificou o MinIO.",
      "custo":"Exige conta própria e cartão, fora do crédito da disciplina, com cobrança por requisição e por saída de dados. Credenciais de nuvem passam a circular no projeto do grupo."
    },
    {
      "letra":"C","titulo":"MinIO distribuído no Railway","tatica":"Redundância no próprio serviço",
      "texto":"O MinIO passa a rodar em modo distribuído, com vários nós e discos e codificação de apagamento, de modo que a perda de um volume não apague objetos.",
      "ganho":"Tolera a falha de um disco ou nó sem mudar a API nem o coletor, e mantém tudo dentro do mesmo ambiente que o grupo já opera.",
      "custo":"Multiplica o consumo de crédito e a complexidade de operação por causa do mínimo de discos exigido. Todos os nós continuam no mesmo provedor: um problema de conta ou de região leva tudo junto."
    },
    {
      "letra":"D","titulo":"Aceitar o risco e declarar","tatica":"Risco registrado com gatilho",
      "texto":"A arquitetura fica como está. O ATAM registra o cenário de perda do volume, os lotes que ele apagaria e o gatilho de revisão: quando a coleta sair do piloto de 20 caminhões para a frota inteira, a durabilidade muda.",
      "ganho":"Custo zero agora, e a decisão fica escrita, com condição de revisão. A API S3 mantém a mudança barata quando o gatilho disparar.",
      "custo":"Se o volume se perder antes do gatilho, perde-se justamente o que o provedor não reenvia: os lotes originais. Declarar o risco não o reduz, e um processo sobre uma jornada do piloto fica sem prova."
    }
  ]'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 2 — Política de escrita
-- O dado novo é uma semana do coletor no Railway, liberada na discussão.
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas, dado_novo)
values (
  'mack-dcs-a02-2026-2', 2,
  'Política de escrita',
  'Quando o 502 não quer dizer falha',
  'O coletor usa chave determinística pela janela e HEAD antes do PUT: a primeira gravação da janela vale, e o lote só sai do pouso depois da confirmação. Com retries atravessando o proxy do Railway, um agendador que pode disparar duas vezes e um provedor que às vezes retransmite um lote, que política de escrita o grupo adota para a raw?',
  '[
    {
      "letra":"A","titulo":"A primeira gravação da janela vale","tatica":"Manter HEAD antes do PUT",
      "texto":"A política continua: se a chave existe com o mesmo sha256, o coletor não grava e registra ja_existia; com sha256 diferente, registra conflito_hash e deixa o arquivo no pouso para uma pessoa decidir.",
      "ganho":"Simples, idempotente e testável com um armazenamento falso. A contagem de objetos e de versões antes e depois de reexecutar é a evidência do cenário C-02, e nada que serve de prova é sobrescrito.",
      "custo":"Uma retransmissão corrigida fica parada no pouso até alguém agir. Duas execuções simultâneas passam juntas pelo HEAD e gravam duas versões, e a política não percebe."
    },
    {
      "letra":"B","titulo":"A última gravação da janela vale","tatica":"PUT sempre, versões guardam o resto",
      "texto":"O coletor grava sempre na mesma chave, sem HEAD. O versionamento guarda as gravações anteriores, e quem lê usa a versão mais recente.",
      "ganho":"A raw fica com a retransmissão mais nova de cada janela, nenhuma gravação se perde e o coletor fica mais curto, sem a requisição extra.",
      "custo":"A contagem de versões deixa de detectar repetição indevida, porque toda execução cria uma. Quem lê precisa escolher versão, e a prova passa a depender de qual versão foi lida."
    },
    {
      "letra":"C","titulo":"Gravar tudo e deduplicar depois","tatica":"Chave com o instante da recepção",
      "texto":"A chave ganha o instante da recepção em segundos, e cada execução grava um objeto novo. A regra de qual lote vale para a janela passa para a Aula 04, na leitura da raw.",
      "ganho":"Nada se perde e nenhuma decisão fica escondida no coletor: todas as transmissões, inclusive as repetidas e as corrigidas, ficam disponíveis para auditoria.",
      "custo":"Duplicata vira regra, e o bucket cresce a cada reexecução e a cada retransmissão. A camada seguinte carrega uma lógica que nenhum teste unitário do coletor cobre."
    },
    {
      "letra":"D","titulo":"Gravação condicional no servidor","tatica":"PUT com If-None-Match",
      "texto":"O HEAD sai, e o PUT passa a ser condicional: o servidor só grava se a chave não existir, numa única operação; se recusar, o coletor compara o hash. O S3 aceita esse cabeçalho; no MinIO da versão usada, o suporte precisa ser testado antes.",
      "ganho":"Fecha a janela entre o HEAD e o PUT, inclusive com execuções simultâneas, e economiza uma requisição por lote gravado.",
      "custo":"Depende de suporte do servidor que ainda não foi verificado no Railway. Se o MinIO local e o remoto se comportarem diferente, o teste passa num ambiente e falha no outro."
    }
  ]'::jsonb,
  '{
    "titulo":"Uma semana do coletor no Railway",
    "texto":"O grupo deixou o coletor rodando de 15 em 15 minutos por sete dias, com o gerador da aula no papel do provedor, e cruzou o manifesto, o log do coletor e a listagem de versões do bucket. Os números são de um cenário construído para a discussão, coerente com as medições da preparação da aula.",
    "evidencias":[
      "As 672 execuções agendadas receberam 13.440 lotes (20 caminhões × 4 por hora × 168 horas), e a listagem mostra 13.440 chaves em telemetria/.",
      "O proxy devolveu 502 em 37 PUT. Em 9 deles o objeto já estava gravado, e o retry criou uma segunda versão idêntica, com o mesmo ETag.",
      "Depois de um redeploy, o agendador disparou duas execuções no mesmo minuto. Em 6 lotes, as duas passaram pelo HEAD antes de qualquer PUT e gravaram duas versões com os mesmos bytes; só o metadado recebido-em difere.",
      "O provedor retransmitiu 4 lotes com uma linha a mais, que o satélite tinha atrasado. Os 4 ficaram no pouso como conflito_hash, e ninguém olhou a pasta durante a semana.",
      "Um desses 4 lotes traz um alerta de direção contínua acima de 5h30 que não está na versão gravada na raw.",
      "A Aula 04 vai ler a raw por período e espera exatamente um lote por caminhão e janela."
    ],
    "pergunta":"Diante do que a semana registrou, qual política permanece? Declare se a sua escolha anterior sobrevive a este dado e por quê."
  }'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 3 — Linhas sem formato e o firmware novo
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a02-2026-2', 3,
  'Arquivo não estruturado',
  'Linhas sem formato e o firmware novo',
  'Cada lote mistura cinco formatos de linha, texto livre do rádio e erros do enlace, cerca de 16 linhas por lote. Em março, parte da frota recebe um firmware que acrescenta TEMP_BAU, a temperatura do baú, ao fim das linhas do formato 3. Hoje a raw guarda o lote intacto e ninguém interpreta as linhas. Quando e onde o grupo passa a interpretar esse texto?',
  '[
    {
      "letra":"A","titulo":"Parser na coleta, só registros","tatica":"Schema on write no coletor",
      "texto":"O coletor interpreta cada linha antes de gravar e envia ao bucket um JSON Lines com os campos tipados dos formatos conhecidos. O TXT original é descartado depois da gravação.",
      "ganho":"Uma única etapa, campos tipados desde o primeiro dia e leitura imediata pelo DuckDB, sem uma camada de arquivos brutos para manter.",
      "custo":"Linha fora dos cinco formatos se perde, e o TEMP_BAU some até alguém mudar o parser. Sem o original, um defeito do parser não se corrige, e a prova numa fiscalização depende do que o parser entendeu."
    },
    {
      "letra":"B","titulo":"Raw bruta e bronze depois","tatica":"Schema on read com extrator separado",
      "texto":"A raw continua com o TXT intacto. Um extrator versionado lê a raw e grava a bronze em JSON Lines, uma linha por registro, com o formato reconhecido, o lote de origem e as linhas que não reconheceu.",
      "ganho":"O original fica como prova, o TEMP_BAU entra no histórico inteiro quando o extrator aprender a lê-lo, e um defeito se corrige reprocessando a raw.",
      "custo":"Dois componentes para operar, o dado guardado em duas camadas e um atraso entre a chegada e a leitura. Alguém precisa acompanhar as linhas não reconhecidas, ou elas viram um depósito sem dono."
    },
    {
      "letra":"C","titulo":"Raw bruta e parser em cada leitura","tatica":"Schema on read sem camada intermediária",
      "texto":"Nada além da raw. Cada consulta da Aula 04 aplica um parser, em SQL ou em Python, direto sobre os TXT do bucket.",
      "ganho":"Nenhum componente novo, e mudar o parser é mudar a consulta: o TEMP_BAU aparece no histórico inteiro na próxima leitura.",
      "custo":"Cada leitor escreve e mantém o seu parser, e duas consultas podem discordar sobre o mesmo lote. Interpretar 1.920 arquivos por dia de dado a cada consulta custa mais que ler registros prontos."
    },
    {
      "letra":"D","titulo":"Parser na coleta e TXT preservado","tatica":"Raw e bronze na mesma execução",
      "texto":"O coletor grava o TXT na raw, como hoje, e na mesma execução grava a bronze em JSON Lines. Se o parser falhar, o lote vai para a raw mesmo assim e o erro entra no manifesto.",
      "ganho":"Leitura imediata sem perder o original, e reprocessar a bronze a partir da raw continua possível.",
      "custo":"O coletor fica maior e passa a depender de código que muda a cada firmware. Um defeito no parser atrasa a execução que só precisava mover arquivos, e o pouso pode acumular lotes."
    }
  ]'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- Remove questões excedentes de uma execução anterior desta mesma sala.
delete from hubtbl_questoes where session_slug = 'mack-dcs-a02-2026-2' and ordem > 3;

do $$
begin
  if (select count(*) from hubtbl_questoes where session_slug = 'mack-dcs-a02-2026-2') <> 3 then
    raise exception 'A sala deve conter exatamente 3 questões.';
  end if;
end $$;

commit;
