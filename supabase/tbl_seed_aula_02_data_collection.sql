-- =====================================================================
-- TBL — Data Collection and Storage 2026.2 · Aula 02 (17/10/2026)
-- Caso: O coletor que a demonstração colocou no ar
--
-- Três questões sobre a arquitetura que a demonstração da manhã montou
-- (coletor da Open-Meteo, MinIO local em Docker e MinIO de um nó no
-- Railway, bucket raw com chave particionada, HEAD antes do PUT,
-- metadados de procedência e manifesto em JSON Lines):
--   1. Durabilidade da camada bruta  — um nó, um volume, um histórico que
--      a API não devolve. Retoma os blocos 2 e 3 (tipos de storage,
--      garantias do object storage, versionamento).
--   2. Política de escrita           — retry, 502 do proxy e disparo
--      duplo. Retoma o bloco 5 (idempotência e procedência).
--   3. Arquivo não estruturado       — os lotes TXT da telemetria dos
--      caminhões. Retoma o bloco 4 (file contra object storage, storage
--      contra data lake, schema on read e on write).
--
-- Cada questão traz quatro táticas com ganho e custo declarados, e
-- nenhuma é correta: o que se mede é o deslocamento entre a decisão
-- individual e a decisão posterior à discussão.
--
-- A questão 2 traz um dado novo, liberado só quando a discussão é aberta:
-- uma semana do coletor no Railway, em cenário construído para a
-- discussão e coerente com as medições da preparação da aula.
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
  'A demonstração desta manhã montou a camada bruta da distribuidora de bebidas. Um coletor em Python chama a Open-Meteo a cada hora para seis capitais e grava cada resposta como JSON no bucket raw do MinIO. No Codespace, o MinIO roda em Docker para desenvolver; na coleta contínua, roda no Railway, como um único serviço com um volume montado em /data.

As decisões já tomadas são estas: chave open_meteo/data=AAAA-MM-DD/hora=HH/cidade.json, em UTC; HEAD antes do PUT, de modo que a primeira gravação da hora vale; sete metadados de procedência por objeto; um manifesto em JSON Lines por execução; versionamento ligado no bucket. A API compatível com S3 permite levar o mesmo código para outro provedor trocando o endpoint e as credenciais.

A preparação da aula mediu 992 bytes por resposta, cerca de 6,6 KB em disco por objeto no MinIO local, e medianas de 3,97 ms por PUT e 1,90 ms por GET, sem rede. O proxy do Railway devolve 502 de forma esporádica, e um 502 não prova que o PUT falhou. O sistema de arquivos do volume do Railway não foi verificado, e a garantia de consistência do MinIO depende dele.

A partir da Aula 03, o mesmo bucket recebe novas fontes; na Aula 04, ele vira a origem do lakehouse. Em janeiro, a distribuidora quer incorporar a telemetria dos caminhões de entrega, que chega por satélite em lotes TXT sem formato fixo. As três questões revisam a arquitetura antes que ela acumule meses de dado. Nenhuma alternativa é a correta: cada uma é uma tática com ganho e custo declarados.',
  '[
    {"rotulo":"Coleta","valor":"144 objetos por dia","nota":"6 capitais × 24 horas"},
    {"rotulo":"Em disco","valor":"6,6 KB por objeto","nota":"992 B de conteúdo · medido no MinIO local"},
    {"rotulo":"PUT mediano","valor":"3,97 ms","nota":"MinIO local, sem rede"},
    {"rotulo":"MinIO no Railway","valor":"1 nó, 1 volume","nota":"sem redundância · sistema de arquivos não verificado"},
    {"rotulo":"Proxy do Railway","valor":"502 esporádico","nota":"o PUT pode ter chegado mesmo assim"},
    {"rotulo":"Quem lê depois","valor":"Aulas 03, 04 e 05","nota":"a raw é o original de todas as camadas"}
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
  'Um nó, um volume, um histórico',
  'A raw guarda o que a Open-Meteo não devolve mais: a previsão de uma hora que já passou. Hoje ela vive em um MinIO de um nó, num único volume do Railway, e a perda desse volume apaga o histórico. Que decisão o grupo toma sobre onde a camada bruta mora daqui para a frente?',
  '[
    {
      "letra":"A","titulo":"Manter o nó e espelhar todo dia","tatica":"Cópia para um segundo destino",
      "texto":"O MinIO de um nó continua como está, e um job diário copia o bucket raw com mc mirror para um segundo destino, em outro provedor, com a data da última cópia registrada no manifesto.",
      "ganho":"Elimina a perda total do histórico com pouco código e sem mudar o coletor. O espelho usa a mesma API S3, e restaurar é copiar de volta.",
      "custo":"Dobra o armazenamento e cria um segundo serviço para operar. O espelho fica até 24 horas atrasado, e uma gravação errada é copiada para lá do mesmo jeito que uma correta."
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
      "texto":"A arquitetura fica como está. O ATAM registra o cenário de perda do volume, o histórico que ele apagaria e o gatilho de revisão: quando a raw passar a sustentar uma decisão de negócio, a durabilidade muda.",
      "ganho":"Custo zero agora, e a decisão fica escrita, com condição de revisão. A API S3 mantém a mudança barata quando o gatilho disparar.",
      "custo":"Se o volume se perder antes do gatilho, o que se perde é justamente o que nenhuma API devolve: as previsões passadas. Declarar o risco não o reduz."
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
  'O coletor usa chave determinística e HEAD antes do PUT: a primeira gravação da hora vale. Com retries atravessando o proxy do Railway e um agendador que pode disparar duas vezes, que política de escrita o grupo adota para a raw?',
  '[
    {
      "letra":"A","titulo":"A primeira gravação da hora vale","tatica":"Manter HEAD antes do PUT",
      "texto":"A política continua: se a chave existe, o coletor não grava e registra ja_existia no manifesto. Retry e reexecução ficam seguros enquanto houver uma execução por vez.",
      "ganho":"Simples, idempotente e testável com um armazenamento falso. A contagem de objetos e de versões antes e depois de reexecutar é a evidência do cenário C-02.",
      "custo":"Uma primeira resposta ruim fica valendo para sempre. Duas execuções simultâneas passam juntas pelo HEAD e gravam duas versões, e a política não percebe."
    },
    {
      "letra":"B","titulo":"A última gravação da hora vale","tatica":"PUT sempre, versões guardam o resto",
      "texto":"O coletor grava sempre na mesma chave, sem HEAD. O versionamento guarda as gravações anteriores, e quem lê usa a versão mais recente.",
      "ganho":"A raw fica sempre com a resposta mais nova da hora, nenhuma gravação se perde e o coletor fica mais curto, sem a requisição extra.",
      "custo":"A contagem de versões deixa de detectar repetição indevida, porque toda execução cria uma. O bucket cresce a cada retry, e a leitura precisa escolher versão."
    },
    {
      "letra":"C","titulo":"Gravar tudo e deduplicar depois","tatica":"Chave com o instante da coleta",
      "texto":"A chave ganha o instante da coleta em segundos, e cada execução grava um objeto novo. A regra de qual resposta vale para a hora passa para a Aula 04, na leitura da raw.",
      "ganho":"Nada se perde e nenhuma decisão fica escondida no coletor: todas as respostas, inclusive as repetidas, ficam disponíveis para auditoria.",
      "custo":"Duplicata vira regra, e o bucket dobra a cada reexecução. A camada seguinte carrega uma lógica que nenhum teste unitário do coletor cobre."
    },
    {
      "letra":"D","titulo":"Gravação condicional no servidor","tatica":"PUT com If-None-Match",
      "texto":"O HEAD sai, e o PUT passa a ser condicional: o servidor só grava se a chave não existir, numa única operação. O S3 aceita esse cabeçalho; no MinIO da versão usada, o suporte precisa ser testado antes.",
      "ganho":"Fecha a janela entre o HEAD e o PUT, inclusive com execuções simultâneas, e economiza uma requisição por objeto.",
      "custo":"Depende de suporte do servidor que ainda não foi verificado no Railway. Se o MinIO local e o remoto se comportarem diferente, o teste passa num ambiente e falha no outro."
    }
  ]'::jsonb,
  '{
    "titulo":"Uma semana do coletor no Railway",
    "texto":"O grupo deixou o coletor rodando de hora em hora por sete dias e cruzou o manifesto, o log do coletor e a listagem de versões do bucket. Os números são de um cenário construído para a discussão, coerente com as medições da preparação da aula.",
    "evidencias":[
      "As 168 execuções agendadas deveriam gerar 1.008 objetos, e a listagem mostra 1.008 chaves.",
      "O proxy devolveu 502 em 11 PUT. Em 3 deles o objeto já estava gravado, e o retry criou uma segunda versão idêntica, com o mesmo ETag.",
      "Depois de um redeploy, o agendador disparou duas execuções no mesmo minuto. Em 2 cidades, as duas passaram pelo HEAD antes de qualquer PUT e gravaram duas versões que diferem só no campo generationtime_ms, o que muda o hash.",
      "Em uma hora, a resposta para Manaus veio com HTTP 200 e todos os valores de temperatura nulos. Pela política atual, é ela que vale para aquela hora.",
      "A Aula 04 vai ler a raw por período e espera exatamente uma resposta por cidade e hora."
    ],
    "pergunta":"Diante do que a semana registrou, qual política permanece? Declare se a sua escolha anterior sobrevive a este dado e por quê."
  }'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 3 — Arquivo não estruturado
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a02-2026-2', 3,
  'Arquivo não estruturado',
  'Os lotes TXT dos caminhões',
  'Em janeiro, os lotes TXT da telemetria passam a chegar pelo SFTP do provedor, cerca de 48 mil por dia na hipótese do bloco 4, com datas em formatos diferentes, texto livre e linhas de erro. Como esse dado entra na arquitetura que a demonstração montou?',
  '[
    {
      "letra":"A","titulo":"A pasta do SFTP como repositório","tatica":"File storage definitivo",
      "texto":"Os lotes ficam no volume do servidor SFTP, organizados em pastas por data. Quem precisa do dado lê por montagem do volume ou copia os arquivos.",
      "ganho":"Nenhum serviço novo, latência de arquivo local e o formato que o provedor já entrega. Acrescentar linhas a um lote aberto funciona sem adaptação.",
      "custo":"Sem metadados de procedência nem versões, num volume de um servidor só. DuckDB e ClickHouse não leem por API S3, e a retenção legal fica num script. É storage, sem as regras de um lake."
    },
    {
      "letra":"B","titulo":"SFTP como pouso, bucket como destino","tatica":"Pouso temporário e raw no MinIO",
      "texto":"Um processo move cada lote para telemetria/data=/hora=/caminhao= no bucket raw, com metadados de origem e hash, e só apaga o arquivo da pasta depois de confirmar a gravação.",
      "ganho":"A telemetria ganha a mesma governança da Open-Meteo: original preservado, schema on read e reprocessamento quando o parser mudar.",
      "custo":"Mais um processo para operar e monitorar, com uma janela em que o lote existe nos dois lugares. 48 mil objetos por dia pesam na listagem e na sobrecarga de cerca de 5,6 KB por objeto."
    },
    {
      "letra":"C","titulo":"Parsear na chegada e guardar só registros","tatica":"Schema on write num Postgres",
      "texto":"Um parser lê cada lote assim que ele chega e grava apenas os registros tipados numa tabela do Postgres. O TXT é descartado depois da carga.",
      "ganho":"SQL imediato, tipos garantidos e um painel rápido desde o primeiro dia, sem uma camada de arquivos para manter.",
      "custo":"Linha fora do formato é rejeitada, e um campo novo do firmware se perde até alguém migrar a tabela. Sem o original, um defeito do parser não se corrige, e a prova numa fiscalização depende dele."
    },
    {
      "letra":"D","titulo":"Lote por hora na raw e bronze imediato","tatica":"Agregar na chegada e extrair cedo",
      "texto":"Os lotes de cada caminhão são concatenados por hora antes de ir à raw, com a lista dos arquivos originais no manifesto, e um extrator grava em seguida o bronze em JSON Lines.",
      "ganho":"Divide o número de objetos e a sobrecarga por quatro, e o bronze dá leitura imediata sem descartar o texto original.",
      "custo":"Agregar exige esperar a hora fechar e cria mais um passo que pode falhar no meio. O lote do provedor deixa de existir como objeto próprio, e dois componentes passam a exigir manutenção desde o primeiro mês."
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
