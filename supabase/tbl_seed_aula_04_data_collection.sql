-- =====================================================================
-- TBL — Data Collection and Storage 2026.2 · Aula 04 (31/10/2026)
-- Caso: O lakehouse que a demonstração colocou no ar
--
-- Três questões sobre a arquitetura que a demonstração da manhã montou
-- (job em Python com DuckDB in-process lendo o raw e o bronze do MinIO,
-- silver em Parquet com um objeto de nome fixo por data, gold recalculada
-- a cada execução, janela D e D+1 por causa da partição em UTC, imagem
-- publicada no Railway como serviço com cron 15 * * * *):
--   1. Formato da silver              — Parquet solto, formato de tabela,
--      arquivo de banco DuckDB ou Postgres. Retoma os blocos 2 e 3
--      (Parquet por dentro; lake, warehouse e lakehouse).
--   2. Arquivo inválido no raw        — um JSON truncado derruba a data.
--      Retoma os blocos 1 e 5 (schema on read, Malformed JSON,
--      ignore_errors, deduplicação).
--   3. Agendamento e janela de leitura — cron horário, diário, incremental
--      ou por evento. Retoma os blocos 4 e 5 (requisições por leitura,
--      regras do cron do Railway, idempotência).
--
-- Cada questão traz quatro táticas com ganho e custo declarados, e
-- nenhuma é correta: o que se mede é o deslocamento entre a decisão
-- individual e a decisão posterior à discussão.
--
-- A questão 2 traz um dado novo, liberado só quando a discussão é aberta:
-- uma semana do job no Railway, em cenário construído para a discussão e
-- coerente com as medições da preparação da aula (réplica de uma semana
-- do raw, DuckDB 1.5.6, MinIO local).
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
values ('mack-dcs-a04-2026-2', 'TBL — O lakehouse que a demonstração colocou no ar')
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
  'O lakehouse que a demonstração colocou no ar',
  'A demonstração desta manhã montou o lakehouse da disciplina sobre o MinIO do grupo. Um job em Python abre o DuckDB dentro do próprio processo, lê o JSON da Open-Meteo no bucket raw e o JSON Lines dos livros e da PTAX no bronze, e grava duas camadas: a silver, em Parquet tipado com arquivo_origem em toda linha, e a gold, com a temperatura média diária por capital e o preço de cada livro em reais por dia. No Codespace, o job roda contra a cópia local do MinIO; no Railway, roda como serviço com cron.

As decisões já tomadas são estas: a silver de cada data é um único objeto de nome fixo, como silver/clima/data=D/clima.parquet, substituído a cada reprocessamento; a gold é recalculada inteira a cada execução; a silver do dia D lê as partições D e D+1 do raw, porque a partição está em UTC e a previsão no horário de Brasília, e fica com a coleta mais recente de cada hora prevista; o cron é 15 * * * *, em UTC, com restartPolicyType NEVER, e o job processa as três fontes numa execução só.

A preparação mediu, sobre uma réplica de uma semana do raw (1.008 respostas com a forma real e valores sorteados): 3.456 linhas lidas por dia para 144 úteis; a mesma tabela com 5.241.207 bytes em JSON Lines e 54.020 bytes em Parquet com ZSTD; 1.010 GET para ler um dia com union_by_name sobre a semana e 3 GET na silver. Um JSON truncado derrubou a leitura da data inteira com Malformed JSON, e ignore_errors não vale para JSON comum. O cron do Railway pula a execução seguinte quando a anterior ainda roda.

A partir da Aula 05, a silver dos livros e da PTAX alimenta o modelo relacional e o esquema estrela, e o contrato dessas tabelas não pode mudar sem aviso. As três questões revisam o job antes que o cron acumule meses de execução. Nenhuma alternativa é a correta: cada uma é uma tática com ganho e custo declarados.',
  '[
    {"rotulo":"Raw do clima","valor":"144 respostas por dia","nota":"6 capitais × 24 coletas · cerca de 990 B cada"},
    {"rotulo":"Linhas por dia","valor":"3.456 lidas, 144 úteis","nota":"cada hora prevista aparece em 24 coletas"},
    {"rotulo":"Formato","valor":"54 KB contra 5,2 MB","nota":"Parquet ZSTD contra JSON Lines · mesma semana da réplica"},
    {"rotulo":"Leitura de um dia","valor":"1.010 GET contra 3","nota":"JSON com union_by_name contra silver em Parquet"},
    {"rotulo":"JSON truncado","valor":"derruba a data","nota":"Malformed JSON · ignore_errors só vale para JSON Lines"},
    {"rotulo":"Cron do Railway","valor":"15 * * * *","nota":"UTC · a execução seguinte é pulada se a anterior roda"}
  ]'::jsonb
)
on conflict (session_slug) do update set
  caso_titulo = excluded.caso_titulo,
  caso_texto  = excluded.caso_texto,
  contexto    = excluded.contexto;

-- ---------------------------------------------------------------------
-- Questão 1 — Formato da silver
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a04-2026-2', 1,
  'Formato da silver',
  'O que faz arquivos virarem tabela',
  'A silver é um conjunto de arquivos Parquet, um por data, que a Aula 05 vai ler como se fosse tabela. Não há transação envolvendo vários arquivos, nem histórico de versões, nem registro do esquema vigente em cada momento. Que forma a silver assume daqui para a frente?',
  '[
    {
      "letra":"A","titulo":"Parquet com nome fixo por data","tatica":"Manter o ADR-001",
      "texto":"A silver continua como está: um objeto Parquet por data, substituído no reprocessamento, com o contrato de colunas escrito na spec e conferido por teste.",
      "ganho":"Qualquer motor que leia Parquet lê a silver, e a gravação de um objeto é atômica: quem lê vê a data antiga ou a nova. Nada novo para operar.",
      "custo":"Sem histórico, um reprocessamento errado sobrescreve a data sem volta. Uma mudança de esquema convive com arquivos antigos sem registro de quando mudou, e uma atualização de várias datas não é atômica."
    },
    {
      "letra":"B","titulo":"Formato de tabela aberto","tatica":"Iceberg ou Delta sobre o MinIO",
      "texto":"A silver passa a ser uma tabela Apache Iceberg ou Delta Lake no mesmo bucket, com um log de metadados sobre os Parquet. O DuckDB tem extensões para os dois; a escrita pela versão usada precisa ser testada antes de entrar na spec.",
      "ganho":"Transação envolvendo vários arquivos, leitura de uma versão anterior e evolução de esquema registrada, sem sair do object storage nem dos formatos abertos.",
      "custo":"Mais um componente com versão própria, e o suporte de escrita do DuckDB não foi verificado na preparação. A Aula 05 e o ClickHouse da Aula 06 precisam ler o mesmo formato, e versões antigas exigem limpeza periódica."
    },
    {
      "letra":"C","titulo":"Arquivo de banco do DuckDB","tatica":"Um .duckdb no bucket",
      "texto":"O job grava silver e gold como tabelas de um único arquivo de banco do DuckDB, que sobe para o bucket ao fim de cada execução e é baixado no início da próxima.",
      "ganho":"Tabelas de verdade, com tipos, restrições e transação dentro do arquivo, e consultas da Aula 05 sem glob nem partição.",
      "custo":"O arquivo inteiro é reescrito a cada hora e cresce sem poda. Só o DuckDB lê o formato, duas execuções simultâneas sobrescrevem uma à outra, e uma falha no upload deixa a cópia anterior valendo sem aviso."
    },
    {
      "letra":"D","titulo":"Silver no Postgres da Aula 05","tatica":"Warehouse a partir da silver",
      "texto":"O job lê o raw e o bronze com o DuckDB e grava silver e gold direto em tabelas do Postgres que a Aula 05 vai usar, com esquema declarado e chave primária.",
      "ganho":"Transação, chave primária contra duplicata, permissões por tabela e SQL imediato para a Aula 05, sem arquivo intermediário.",
      "custo":"O lakehouse fica reduzido a raw e bronze: o ClickHouse da Aula 06 e outros motores deixam de ler a silver pela API S3. Mais um serviço para pagar e operar no Railway."
    }
  ]'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 2 — Arquivo inválido no raw
-- O dado novo é uma semana do job no Railway, liberada na discussão.
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas, dado_novo)
values (
  'mack-dcs-a04-2026-2', 2,
  'Arquivo inválido no raw',
  'Um JSON truncado derruba a data',
  'Um objeto do raw do clima chega truncado, e o read_json_auto interrompe a leitura da data inteira com Malformed JSON. O DuckDB não aceita ignore_errors para JSON comum, e o job não pode alterar o raw. Que política o job adota para arquivo inválido?',
  '[
    {
      "letra":"A","titulo":"Falhar a data e avisar","tatica":"Parar na primeira falha",
      "texto":"O job interrompe o processamento da data, termina com código diferente de 0 e registra no log o caminho do arquivo e o erro. Nada é gravado na silver nem na gold daquela data até alguém resolver o arquivo.",
      "ganho":"A gold nunca mostra média calculada sem parte das coletas, e a falha fica visível no histórico do Railway. Testar é simples: basta um JSON truncado na fixture.",
      "custo":"Um arquivo entre até 288 trava a data inteira, e o cron repete a falha a cada hora até alguém agir. Como o raw é somente leitura para o job, resolver exige intervenção manual no bucket."
    },
    {
      "letra":"B","titulo":"Validar, pular e seguir","tatica":"Lista de arquivos válidos",
      "texto":"Antes da consulta, o job valida cada objeto com json.loads, passa ao DuckDB só a lista dos válidos e registra os inválidos no resumo da execução. A deduplicação usa a coleta válida mais recente de cada hora prevista.",
      "ganho":"A silver continua atualizada, e uma coleta perdida custa pouco: a mesma hora prevista aparece em outras 23 coletas do dia.",
      "custo":"Cada objeto é baixado duas vezes, uma para validar e outra para ler. O resumo só ajuda se alguém o ler, e a silver pode usar uma previsão mais antiga sem que a gold indique isso."
    },
    {
      "letra":"C","titulo":"Quarentena com marca na gold","tatica":"Registro de inválidos e completude",
      "texto":"O job pula o inválido, grava caminho e erro em silver/_quarentena/data=D/invalidos.jsonl e acrescenta à gold de clima uma coluna com o número de coletas inválidas de cada dia.",
      "ganho":"Quem consome a gold sabe quando uma média usou menos coletas, e a engenharia ganha uma fila de arquivos para investigar sem tocar no raw.",
      "custo":"Mais um contrato para manter e testar, inclusive na Aula 05. O consumidor precisa olhar a coluna, e a quarentena cresce se ninguém a esvaziar."
    },
    {
      "letra":"D","titulo":"Isolar por fonte e falhar no fim","tatica":"Etapas independentes",
      "texto":"Clima, livros e PTAX viram etapas separadas. A que encontra arquivo inválido mantém a silver anterior daquela fonte, as outras seguem, e o job termina com código diferente de 0 se alguma etapa falhou.",
      "ganho":"Um JSON ruim do clima não impede a gold de preços que a Aula 05 consome, e o código de saída ainda mostra a falha no Railway.",
      "custo":"A gold de clima fica parada sem aviso para quem a consome, e o código 1 a cada hora vira ruído no log. O job passa a ter estado parcial entre etapas, mais difícil de testar."
    }
  ]'::jsonb,
  '{
    "titulo":"Uma semana do job no Railway",
    "texto":"O grupo deixou o job agendado por sete dias com a política de falhar a data e cruzou o railway logs, a listagem da silver e a gold. Os números são de um cenário construído para a discussão, coerente com as medições da preparação da aula.",
    "evidencias":[
      "O objeto raw/open_meteo/data=2026-10-27/hora=14/sao_paulo.json chegou truncado. Todas as execuções que processavam o dia 27 falharam dali em diante: 13 seguidas, de 14h15 a 2h15 UTC.",
      "Na virada do dia em Brasília, o job passou a processar o dia 28 e voltou a terminar com código 0. A silver de 27/10 ficou com a versão das 13h15 UTC, e nenhum alerta foi disparado.",
      "A hora prevista afetada aparecia em outras 23 coletas válidas do mesmo dia. Recalculada sem o arquivo truncado, a média de São Paulo em 27/10 mudou menos de 0,1 °C.",
      "A gold de preços dos livros, que não depende do clima, também deixou de ser atualizada nessas 13 execuções, porque o job processa as três fontes numa execução só.",
      "No bronze dos livros, um teste com ignore_errors pulou 2 linhas malformadas sem registro: a contagem de livros da silver caiu 2 e nenhum log disse por quê."
    ],
    "pergunta":"Diante do que a semana registrou, qual política permanece? Declare se a sua escolha anterior sobrevive a este dado e por quê."
  }'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 3 — Agendamento e janela de leitura
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dcs-a04-2026-2', 3,
  'Agendamento e janela de leitura',
  'Quando o job roda e quanto ele lê',
  'O job roda a cada hora e reprocessa a data corrente inteira, lendo as partições D e D+1 do raw: até 288 objetos por execução e 6.912 por dia, para 144 gravados pela coleta. A gold de clima muda pouco ao longo do dia, e a de preços muda uma vez por coleta. Que agendamento e que janela de leitura o grupo adota?',
  '[
    {
      "letra":"A","titulo":"Cron horário reprocessando a data","tatica":"Manter 15 * * * *",
      "texto":"O job continua a cada hora, relendo as partições D e D+1 com o caminho fixo no glob e regravando a silver da data e a gold inteira.",
      "ganho":"A gold fica no máximo uma hora atrás da coleta, e cada execução é idempotente: uma execução pulada se corrige na seguinte.",
      "custo":"24 execuções por dia e até 6.912 objetos lidos, com consumo de crédito proporcional. Se uma execução passar de uma hora, a seguinte é pulada."
    },
    {
      "letra":"B","titulo":"Cron diário da data fechada","tatica":"Uma execução por dia",
      "texto":"O job roda uma vez por dia, por exemplo às 6h15 UTC (3h15 em Brasília), e processa o dia anterior já completo, com as partições D e D+1 fechadas.",
      "ganho":"Uma execução e cerca de 288 objetos lidos por dia, e a silver de cada data é gravada uma vez, com todas as coletas.",
      "custo":"A gold do dia corrente não existe, e a de ontem só aparece de madrugada. Uma falha só é percebida no dia seguinte."
    },
    {
      "letra":"C","titulo":"Incremental com estado","tatica":"Ler só o que chegou",
      "texto":"O job guarda num objeto de controle a lista das chaves do raw já processadas e, a cada hora, lê só os objetos novos, combinando-os com a silver anterior da data.",
      "ganho":"Cada execução lê cerca de 6 objetos novos do clima em vez de até 288, e o custo fica pequeno mesmo com o bucket crescendo.",
      "custo":"O estado vira parte do sistema: se ele se perder ou divergir, o job pula ou repete objetos. A deduplicação passa a misturar silver anterior e objetos novos, e o teste de reprocessamento fica mais difícil."
    },
    {
      "letra":"D","titulo":"Disparo pelo coletor","tatica":"Execução por evento",
      "texto":"O coletor da Aula 02, ao terminar de gravar as seis respostas da hora, chama o job, ou o MinIO notifica a chegada de objetos novos. O cron sai.",
      "ganho":"A gold fica pronta logo depois da coleta, sem o atraso fixo do minuto 15, e o job não roda quando não há coleta nova.",
      "custo":"Coletor e job ficam acoplados: se o coletor falhar, o job não roda, e um disparo duplo roda o job duas vezes ao mesmo tempo. A regra do cron que pula a execução sobreposta deixa de proteger."
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
