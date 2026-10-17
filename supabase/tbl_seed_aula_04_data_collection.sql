-- =====================================================================
-- TBL — Data Collection and Storage 2026.2 · Aula 04 (31/10/2026)
-- Caso: O lakehouse que a demonstração colocou no ar
--
-- Três questões sobre a arquitetura que a demonstração da manhã montou
-- (job em Python com DuckDB in-process lendo os lotes TXT de telemetria
-- do raw e o bronze dos livros e da PTAX, bronze da telemetria em JSON
-- Lines com quarentena, silver em Parquet com um objeto de nome fixo por
-- data, gold recalculada a cada execução, dia local lido pelas partições
-- UTC escritas no caminho, imagem no Railway com cron 15 * * * *):
--   1. Formato da silver              — Parquet solto, formato de tabela,
--      arquivo de banco DuckDB ou Postgres. Retoma os blocos 2 e 3
--      (Parquet por dentro; lake, warehouse e lakehouse).
--   2. Lote inválido no raw           — um byte fora do UTF-8 derruba o dia.
--      Retoma os blocos 1 e 5 (schema on read no TXT, quarentena,
--      read_text e read_blob, deduplicação).
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
-- coerente com as medições da preparação da aula (sete dias de lotes do
-- gerar_lotes.py da Aula 02, 20 caminhões, DuckDB 1.5.6, MinIO local).
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
  'A demonstração desta manhã montou o lakehouse da disciplina sobre o MinIO do grupo. Um job em Python abre o DuckDB dentro do próprio processo, lê no bucket raw os lotes TXT de telemetria dos caminhões da transportadora e lê no bronze o JSON Lines dos livros e da PTAX. Grava três camadas: o bronze da telemetria, com uma linha do TXT por registro e uma quarentena para as linhas que nenhum dos cinco formatos explica; a silver, em Parquet tipado com arquivo_origem em toda linha; e a gold, com a jornada diária de cada caminhão (horas de direção, alertas acima de 5h30, velocidade média e quilometragem aproximada) e o preço de cada livro em reais por dia. No Codespace, o job roda contra a cópia local do MinIO; no Railway, roda como serviço com cron.

As decisões já tomadas são estas: cada data no bronze e na silver é um único objeto de nome fixo, como silver/posicoes/data_local=D/posicoes.parquet, substituído a cada reprocessamento; a gold é recalculada inteira a cada execução; o dia D no horário de Brasília é lido pelas partições do raw das 03h UTC de D às 02h59 UTC de D+1, escritas no caminho; a silver fica com uma posição por caminhão e minuto, a do lote mais recente; o cron é 15 * * * *, em UTC, com restartPolicyType NEVER, e o job processa as três fontes numa execução só.

A preparação mediu, sobre sete dias de lotes do gerador da Aula 02 (20 caminhões, 1.920 lotes por dia): 31.286 linhas num dia, das quais 31.285 casaram com um dos cinco formatos e uma, cortada no fim de um lote, foi para a quarentena sem erro; a semana de posições com 79,8 MB em JSON Lines e 2,1 MB em Parquet com ZSTD; cerca de 1.924 GET para ler um dia de lotes com as partições no caminho e 5 GET na silver. Um lote com um byte fora do UTF-8 fez o read_text recusar a leitura do dia inteiro. O cron do Railway pula a execução seguinte quando a anterior ainda roda.

A partir da Aula 05, a silver dos livros e da PTAX alimenta o modelo relacional e o esquema estrela, e o contrato dessas tabelas não pode mudar sem aviso. As três questões revisam o job antes que o cron acumule meses de execução. Nenhuma alternativa é a correta: cada uma é uma tática com ganho e custo declarados.',
  '[
    {"rotulo":"Raw da telemetria","valor":"1.920 lotes por dia","nota":"20 caminhões × 96 janelas de 15 min · cerca de 1 KB cada"},
    {"rotulo":"Linhas por dia","valor":"31.286 em 5 formatos","nota":"1 em quarentena · 28.799 posições na silver"},
    {"rotulo":"Formato","valor":"2,1 MB contra 79,8 MB","nota":"Parquet ZSTD contra JSON Lines · posições da semana"},
    {"rotulo":"Leitura de um dia","valor":"1.924 GET contra 5","nota":"lotes TXT com partições no caminho contra silver em Parquet"},
    {"rotulo":"Byte fora do UTF-8","valor":"derruba o dia","nota":"read_text recusa o lote · read_blob identifica sem parar"},
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
-- Questão 2 — Lote inválido no raw
-- O dado novo é uma semana do job no Railway, liberada na discussão.
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas, dado_novo)
values (
  'mack-dcs-a04-2026-2', 2,
  'Lote inválido no raw',
  'Um byte fora do UTF-8 derruba o dia',
  'Um lote do raw chega com um byte fora do UTF-8, e o read_text interrompe a leitura do dia inteiro. Outro lote chegou cortado no meio da última linha, e essa linha foi para a quarentena sem nenhum erro. O job não pode alterar o raw. Que política o job adota para lote inválido?',
  '[
    {
      "letra":"A","titulo":"Falhar o dia e avisar","tatica":"Parar na primeira falha",
      "texto":"O job interrompe o processamento do dia, termina com código diferente de 0 e registra no log o caminho do lote e o erro. Nada é gravado no bronze, na silver nem na gold daquele dia até alguém resolver o lote.",
      "ganho":"A gold nunca mostra jornada calculada sem parte dos lotes, e a falha fica visível no histórico do Railway. Testar é simples: basta um lote com byte inválido na fixture.",
      "custo":"Um lote entre 1.920 trava o dia inteiro, e o cron repete a falha a cada hora até alguém agir. Como o raw é somente leitura para o job, resolver exige intervenção manual no bucket."
    },
    {
      "letra":"B","titulo":"Validar, pular e seguir","tatica":"Lista de lotes válidos",
      "texto":"Antes da extração, o job lê os lotes do dia com read_blob, separa com try(decode(content)) os que não são UTF-8, passa ao read_text só a lista dos válidos e registra os inválidos no resumo da execução.",
      "ganho":"O bronze e a silver continuam atualizados, e um lote perdido custa 15 minutos de um caminhão. O lote ruim fica nomeado no log.",
      "custo":"Os lotes são lidos duas vezes, uma para validar e outra para extrair. O resumo só ajuda se alguém o ler, e a gold mostra menos horas de direção para aquele caminhão sem indicar que faltou dado."
    },
    {
      "letra":"C","titulo":"Quarentena com marca na gold","tatica":"Registro de inválidos e completude",
      "texto":"O job pula o lote inválido, grava caminho e erro na quarentena da telemetria e acrescenta à gold de jornada uma coluna com os minutos sem posição de cada caminhão e dia, somando lotes pulados e linhas em quarentena.",
      "ganho":"Quem consome a gold sabe quando uma jornada foi calculada com menos de 1.440 minutos, e a engenharia ganha uma fila de lotes e linhas para investigar sem tocar no raw.",
      "custo":"Mais um contrato para manter e testar. O consumidor precisa olhar a coluna, e a quarentena cresce se ninguém a esvaziar."
    },
    {
      "letra":"D","titulo":"Ler com substituição e marcar","tatica":"decode com replace",
      "texto":"O job lê os lotes com read_blob e decode(content, ''replace''), que troca o byte inválido por ? e segue, e marca no bronze as linhas que vieram de um lote com substituição.",
      "ganho":"Nenhum lote é perdido por um byte. Se o byte estiver numa mensagem de rádio, que nenhuma gold usa, a jornada não muda.",
      "custo":"Se o byte cair numa linha de posição, ela deixa de casar e vai para a quarentena. O texto do rádio fica alterado no bronze, e a origem do problema, como um firmware que grava em Latin-1, só aparece se alguém olhar a marca."
    }
  ]'::jsonb,
  '{
    "titulo":"Uma semana do job no Railway",
    "texto":"O grupo deixou o job agendado por sete dias com a política de falhar o dia e cruzou o railway logs, a listagem da silver e a gold. Os números são de um cenário construído para a discussão, coerente com as medições da preparação da aula.",
    "evidencias":[
      "O objeto raw/telemetria/data=2026-10-27/hora=14/caminhao=CAM-1060/lote_1415.txt chegou com trânsito gravado em Latin-1 numa mensagem de rádio. Todas as execuções que processavam o dia 27 falharam dali em diante: 13 seguidas, de 14h15 a 2h15 UTC.",
      "Na virada do dia em Brasília, o job passou a processar o dia 28 e voltou a terminar com código 0. O bronze e a silver de 27/10 ficaram com a versão das 13h15 UTC, e nenhum alerta foi disparado.",
      "Relido com decode(content, ''replace''), o lote teve as 15 posições reconhecidas: o byte estava só na linha de rádio. A jornada do CAM-1060 em 27/10 não mudou.",
      "A gold de preços dos livros, que não depende da telemetria, também deixou de ser atualizada nessas 13 execuções, porque o job processa as três fontes numa execução só.",
      "Na mesma semana, 9 linhas cortadas no fim de lotes foram para a quarentena sem nenhum registro no log, e ninguém abriu a quarentena. Três caminhões ficaram com menos de 1.440 minutos em algum dia."
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
  'O job roda a cada hora e reprocessa o dia local corrente inteiro, lendo os lotes do dia com as partições escritas no caminho: até 1.920 objetos por execução e até 46.080 por dia, para 1.920 gravados pela coleta. A gold de jornada muda a cada lote que chega, e a de preços muda uma vez por coleta. Que agendamento e que janela de leitura o grupo adota?',
  '[
    {
      "letra":"A","titulo":"Cron horário reprocessando a data","tatica":"Manter 15 * * * *",
      "texto":"O job continua a cada hora, relendo os lotes do dia local com as partições fixas no caminho e regravando o bronze e a silver do dia e a gold inteira.",
      "ganho":"A gold fica no máximo uma hora atrás da coleta, e cada execução é idempotente: uma execução pulada se corrige na seguinte.",
      "custo":"24 execuções por dia e até 46.080 lotes lidos, com consumo de crédito proporcional. Se uma execução passar de uma hora, a seguinte é pulada."
    },
    {
      "letra":"B","titulo":"Cron diário da data fechada","tatica":"Uma execução por dia",
      "texto":"O job roda uma vez por dia, por exemplo às 6h15 UTC (3h15 em Brasília), e processa o dia anterior já completo, com todas as partições do dia local fechadas.",
      "ganho":"Uma execução e 1.920 lotes lidos por dia, e a silver de cada data é gravada uma vez, com todos os lotes.",
      "custo":"A gold do dia corrente não existe, e a de ontem só aparece de madrugada. Uma falha só é percebida no dia seguinte."
    },
    {
      "letra":"C","titulo":"Incremental com estado","tatica":"Ler só o que chegou",
      "texto":"O job guarda num objeto de controle a lista das chaves do raw já processadas e, a cada hora, lê só os lotes novos, combinando-os com o bronze e a silver anteriores do dia.",
      "ganho":"Cada execução lê cerca de 80 lotes novos em vez de até 1.920, e o custo fica pequeno mesmo com a frota crescendo.",
      "custo":"O estado vira parte do sistema: se ele se perder ou divergir, o job pula ou repete objetos. A deduplicação passa a misturar silver anterior e objetos novos, e o teste de reprocessamento fica mais difícil."
    },
    {
      "letra":"D","titulo":"Disparo pelo coletor","tatica":"Execução por evento",
      "texto":"O coletor da Aula 02, ao terminar de gravar os lotes da hora, chama o job, ou o MinIO notifica a chegada de objetos novos. O cron sai.",
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
