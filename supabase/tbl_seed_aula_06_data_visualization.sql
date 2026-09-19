-- =====================================================================
-- TBL — Data Visualization 2026.2 · Aula 06 (19/09/2026)
-- Caso: O painel que o orientador lê em quatro minutos
--
-- Duas questões sobre o mesmo painel, encaixadas no fechamento do bloco
-- teórico da Aula 06 (heurísticas de avaliação, heurísticas cognitivas e
-- os vieses que o artefato fabrica):
--   1. Curadoria da tela de abertura  — denominador, ancoragem, ranking
--      de pessoas, cor semântica. Retoma a Aula 03 (magnitude, base em
--      zero, mesma unidade) e a Aula 05 (divergência e suporte exigido).
--   2. A lacuna que o dado já tem     — viés de sobrevivência, taxa-base
--      e erro fundamental de atribuição. Retoma a Aula 01 (perfil, nulos),
--      a Aula 02 (grão) e a Aula 04 (reconciliação e rastreabilidade).
--
-- Cada questão traz quatro táticas com ganho e custo declarados, e
-- nenhuma é correta: o que se mede é o deslocamento entre a decisão
-- individual e a decisão posterior à discussão.
--
-- A segunda questão traz um dado novo, liberado só quando a discussão é
-- aberta: o reteste de interpretação com três leitores mostra o que a
-- tela atual produz em quem não a construiu. Ele desloca o critério sem
-- mudar as alternativas — e é o mesmo reteste que a prática das 10h20
-- vai exigir do protótipo.
--
-- Usa as tabelas e RPCs hubtbl_* já instaladas no Supabase compartilhado
-- (as mesmas do TBL de aulas_senac). NÃO execute hubtbl-schema.sql nem
-- hubtbl-funcoes.sql: a infraestrutura já existe e é compartilhada.
--
-- O token do professor não fica no SQL versionado: o marcador
-- __TBL_HOST_TOKEN__ é substituído por scripts/tbl_db.mjs a partir do
-- .env, que o Git ignora.
--
-- Idempotente e restrito à sala 'mack-dv-a06-2026-2'. Recusa alterar a
-- sala depois que ela começou ou recebeu participantes.
-- =====================================================================

begin;

select pg_advisory_xact_lock(hashtext('mack-dv-a06-2026-2'));

do $$
begin
  if exists (select 1 from hubtbl_sessions
              where slug = 'mack-dv-a06-2026-2' and fase <> 'lobby')
     or exists (select 1 from hubtbl_participantes
                 where session_slug = 'mack-dv-a06-2026-2') then
    raise exception 'Sala já iniciada ou com participantes: seed cancelado para preservar a rodada.';
  end if;
end $$;

insert into hubtbl_sessions (slug, titulo)
values ('mack-dv-a06-2026-2', 'TBL — O painel que o orientador lê em quatro minutos')
on conflict (slug) do update set titulo = excluded.titulo;

insert into hubtbl_host_tokens (session_slug, token)
values ('mack-dv-a06-2026-2', '__TBL_HOST_TOKEN__')
on conflict (session_slug) do update set token = excluded.token;

-- ---------------------------------------------------------------------
-- O contexto comum das duas questões
-- ---------------------------------------------------------------------
insert into hubtbl_casos (session_slug, caso_titulo, caso_texto, contexto)
values (
  'mack-dv-a06-2026-2',
  'O painel que o orientador lê em quatro minutos',
  'O painel de acompanhamento dos grupos responde a uma pergunta de orientação: **com qual grupo o professor precisa conversar nesta semana, e sobre o quê**. Ele é aberto no celular, entre uma aula e outra, nos **quatro minutos** que antecedem a reunião. O grupo que o constrói dispõe do semestre inteiro; a leitura que decide a conversa ocorre nesses quatro minutos, sem consulta a nenhuma outra fonte.

A base do período reúne **2.688 commits de 34 estudantes, distribuídos em 6 grupos ao longo de 5 sprints**. A autoria resolve para um integrante em **2.136** desses commits. Os **552 restantes** chegam com e-mail de cliente git fora da conta institucional e são exibidos como **[externo]** ou **[bot]**. A plataforma não registra o trabalho descartado antes do commit, a revisão feita por chamada de vídeo nem a programação em par no mesmo teclado, de modo que o rastro disponível descreve o que virou objeto no repositório, e não o esforço empregado.

A tela de abertura é hoje um **ranking dos seis grupos por volume de commits**, ordenado do maior para o menor, com **cor semântica** nos dois últimos. O **filtro padrão traz as duas últimas sprints**; o período completo exige um clique que nenhum dos acessos registrados no semestre executou. Abaixo do ranking, uma segunda tela mostra a **participação interna do grupo, com uma barra por integrante**.

Na Aula 05 o grupo registrou as divergências **D1 a D6** entre o modelo do usuário e o do projetista, cada uma com decisão e suporte exigido. Em **D3** a divergência foi observada em voz alta: o orientador lê **"12 commits" como "trabalhou pouco"** e decide, a partir dessa leitura, quem chamar para conversar. O fluxo anotado identifica onde a inferência nasce. **Nenhum elemento da interface a impede no ponto em que ela acontece.**

A entrega das 12h10 é o protótipo auditado, com os achados de severidade **3 e 4** corrigidos e retestados. As decisões abaixo antecedem essa construção, e cada uma cobra um custo do orientador, do estudante que aparece na tela ou do grupo que precisa implementá-la em uma manhã. **Nenhuma das alternativas é a correta.**',
  '[
    {"rotulo":"Base do período","valor":"2.688 commits","nota":"5 sprints · 6 grupos · 34 estudantes"},
    {"rotulo":"Autoria resolvida","valor":"2.136 de 2.688","nota":"79,5% · os outros 552 são [externo] ou [bot]"},
    {"rotulo":"Tela de abertura","valor":"ranking por volume","nota":"ordenado, com cor semântica nos dois últimos"},
    {"rotulo":"Filtro padrão","valor":"últimas 2 sprints","nota":"o período completo exige um clique nunca executado"},
    {"rotulo":"Tempo de leitura","valor":"4 minutos","nota":"no celular, antes da reunião de orientação"},
    {"rotulo":"Divergência mais cara","valor":"D3","nota":"\"12 commits\" lido como \"trabalhou pouco\""}
  ]'::jsonb
)
on conflict (session_slug) do update set
  caso_titulo = excluded.caso_titulo,
  caso_texto  = excluded.caso_texto,
  contexto    = excluded.contexto;

-- ---------------------------------------------------------------------
-- Questão 1 — Curadoria da tela de abertura
-- Heurísticas 1, 5, 7, 8 e 10 · ancoragem, denominador ausente,
-- ranking de pessoas e cor semântica. Retoma a Aula 03.
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas)
values (
  'mack-dv-a06-2026-2', 1,
  'Curadoria da tela de abertura',
  'Os quatro minutos antes da reunião',
  'A tela de abertura é um ranking dos seis grupos por volume de commits, e é ela que fixa a régua com que todo o resto do painel será lido. O grupo tem esta manhã para mudá-la. Que decisão de projeto ele toma para essa tela?',
  '[
    {
      "letra":"A","titulo":"Proporção ao lado do absoluto","tatica":"Dar denominador à magnitude",
      "texto":"O ranking permanece, mas cada barra passa a exibir o valor absoluto e a proporção sobre a base do próprio grupo — commits por integrante ativo na sprint —, com a base declarada no eixo e o período fixado nas cinco sprints.",
      "ganho":"Ataca o denominador ausente no ponto em que ele nasce e preserva a leitura de magnitude que a Aula 03 exige: base comum em zero, mesma unidade, mesmo recorte para todos os grupos.",
      "custo":"Duas medidas na mesma barra disputam a atenção, e a primeira que o leitor fixa vira a âncora. O formato continua sendo uma lista ordenada: encarece a leitura errada, não a impede."
    },
    {
      "letra":"B","titulo":"Distribuição no lugar do ranking","tatica":"Trocar a pergunta que a tela faz",
      "texto":"A abertura deixa de ordenar grupos e passa a mostrar a distribuição do indicador entre os seis, com a mediana marcada e a faixa de variação do período; o nome do grupo aparece só quando o leitor aponta para o ponto.",
      "ganho":"Remove a lista do melhor ao pior, que é exatamente o formato que o erro fundamental de atribuição pede, e mostra se a diferença observada é grande diante da variação normal entre grupos.",
      "custo":"Ler distribuição é uma competência que o orientador não pediu e não tem em quatro minutos. Se ele não localizar o próprio grupo de imediato, volta para a planilha, onde não há suporte nenhum."
    },
    {
      "letra":"C","titulo":"Pergunta em vez de placar","tatica":"Acionabilidade antes de magnitude",
      "texto":"A abertura deixa de exibir indicador agregado e passa a listar as três situações que pedem conversa nesta semana, cada uma com a evidência que a caracteriza, o grupo envolvido e o caminho para o detalhe que a sustenta.",
      "ganho":"Serve diretamente à decisão real — com quem falar e sobre o quê — em vez de entregar um número que o leitor precisa interpretar sozinho em quatro minutos. Heurísticas 1 e 10 no centro da tela.",
      "custo":"A regra que define \"situação que pede conversa\" é uma decisão do grupo, não do dado, e concentra nela todo o viés de curadoria. Mal calibrada e não declarada, ela esconde o que ficou de fora sem que ninguém perceba."
    },
    {
      "letra":"D","titulo":"Manter o ranking e anotar","tatica":"Contramedida sobre a tela existente",
      "texto":"O ranking continua como está, e recebe uma anotação fixa de que volume de commits não mede esforço, mais a faixa de variação normal entre grupos no período e a remoção da cor semântica dos dois últimos.",
      "ganho":"Custo de implementação baixo numa manhã curta, preserva a tela que o orientador já sabe ler e coloca a declaração de limite no lugar exato onde a inferência indevida acontece.",
      "custo":"Anotação não desfaz codificação: a barra continua ordenando pessoas do melhor ao pior, e o leitor apressado lê o comprimento, não o texto. Trata o sintoma na tela e mantém o formato que o produz."
    }
  ]'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- ---------------------------------------------------------------------
-- Questão 2 — A lacuna que o dado já tem
-- Heurísticas 3, 7, 9 e 1 · sobrevivência, taxa-base e atribuição.
-- O dado novo é o reteste de interpretação com três leitores, liberado
-- quando a discussão é aberta: ele mostra o que a tela atual produziu em
-- quem não a construiu, e é o mesmo protocolo que a prática exigirá.
-- ---------------------------------------------------------------------
insert into hubtbl_questoes (session_slug, ordem, categoria, titulo, pergunta, alternativas, dado_novo)
values (
  'mack-dv-a06-2026-2', 2,
  'A lacuna que o dado já tem',
  'Os 552 commits sem dono',
  'A tela de participação interna precisa existir: o grupo quer responder sobre equilíbrio de participação. Mas 552 dos 2.688 commits não resolvem para nenhum integrante. Como o grupo trata esse resíduo na tela que vai ao orientador?',
  '[
    {
      "letra":"A","titulo":"Faixa explícita no mesmo gráfico","tatica":"A ausência como categoria",
      "texto":"\"Não atribuído\" vira uma faixa do próprio gráfico, com contagem e percentual, na mesma escala das pessoas, de modo que a soma das partes feche com o total declarado no título.",
      "ganho":"O leitor não consegue somar as partes e obter um total menor sem perceber. A lacuna sai do rodapé e entra na conversa como dado, que é o que a heurística 7 cobra.",
      "custo":"Uma faixa grande ao lado de nomes próprios convida à leitura de que alguém não trabalhou. Sem rótulo que explique a origem técnica da lacuna, ela produz suspeita distribuída em vez de informação."
    },
    {
      "letra":"B","titulo":"Corrigir a origem antes de publicar","tatica":"Reconciliação no pipeline",
      "texto":"Antes de qualquer gráfico, o grupo mapeia os e-mails divergentes para os integrantes, registra a regra de mapeamento no dossiê e reconcilia a soma das partes com o total bruto da base.",
      "ganho":"Resolve a divergência onde ela nasce, no pipeline da Aula 04: o número publicado passa a ter rastro até a linha de origem e a lacuna cai para o que de fato é robô.",
      "custo":"O mapeamento é uma afirmação do grupo sobre quem é quem, e pode estar errado sem deixar marca. Consome a manhã, e basta uma máquina nova para a lacuna voltar na próxima sprint."
    },
    {
      "letra":"C","titulo":"Tirar a pessoa do eixo","tatica":"Mudar a unidade de saída",
      "texto":"A tela deixa de ter nomes no eixo e passa a responder sobre concentração: qual proporção do trabalho está nas mãos de quantos integrantes, com a definição da medida declarada na tela.",
      "ganho":"Responde à pergunta de equilíbrio sem entregar o formato que o atalho de atribuição pede, e torna a lacuna menos danosa, porque nenhum nome é comparado com nenhum outro.",
      "custo":"O grupo perde a capacidade de ver quem está fora da distribuição, que é justamente o caso sobre o qual a orientação quer conversar. A medida de concentração precisa ser explicada, e ninguém a pediu."
    },
    {
      "letra":"D","titulo":"Declarar o limite e não publicar a tela","tatica":"Recusa fundamentada",
      "texto":"Enquanto a autoria não resolver acima de um limiar declarado, a tela de participação interna não entra no painel: o dossiê registra a pergunta, a lacuna, a condição para a tela existir e a data do reteste.",
      "ganho":"Nenhuma leitura falsa é induzida, porque nenhuma tela é oferecida. A limitação fica escrita exatamente onde a Aula 05 pede: com decisão, custo declarado e forma de reteste.",
      "custo":"A pergunta do orientador não desaparece junto com a tela: ele a responderá por impressão, com a lembrança mais recente que tiver. Deixar de mostrar também é uma decisão que recai sobre quem depende do dado."
    }
  ]'::jsonb,
  '{
    "titulo":"O reteste de interpretação com três leitores",
    "texto":"A equipe levou a versão atual da tela a três pessoas que não participaram da construção — o orientador, uma professora de outra turma e um estudante de outro grupo — e pediu a mesma tarefa, sem explicar a interface. As observações abaixo foram registradas durante o uso, com as frases literais de quem leu.",
    "evidencias":[
      "Os três concluíram a tarefa em menos de dois minutos e nenhum deles abriu o detalhe por trás de qualquer número.",
      "Dois dos três leram a faixa [externo] como \"gente que não fez nada\" e, em seguida, nomearam o integrante de menor barra.",
      "O terceiro perguntou de onde vinha o total e não encontrou, na tela, nenhum caminho até a origem.",
      "Nenhum dos três percebeu que o período exibido eram as duas últimas sprints, e não as cinco do projeto.",
      "Os 552 commits não atribuídos concentram-se em dois grupos; em um deles, 214 vêm de uma única máquina mal configurada.",
      "Com o período corrigido para as cinco sprints, a ordem dos três primeiros grupos do ranking muda."
    ],
    "pergunta":"Diante do que os três leitores efetivamente fizeram com a tela, qual tática permanece como resposta primária? Declare se a sua escolha anterior sobrevive a este dado e por quê."
  }'::jsonb
)
on conflict (session_slug, ordem) do update set
  categoria = excluded.categoria, titulo = excluded.titulo,
  pergunta = excluded.pergunta, alternativas = excluded.alternativas,
  dado_novo = excluded.dado_novo;

-- Remove questões excedentes de uma execução anterior desta mesma sala.
delete from hubtbl_questoes where session_slug = 'mack-dv-a06-2026-2' and ordem > 2;

do $$
begin
  if (select count(*) from hubtbl_questoes where session_slug = 'mack-dv-a06-2026-2') <> 2 then
    raise exception 'A sala deve conter exatamente 2 questões.';
  end if;
end $$;

commit;
