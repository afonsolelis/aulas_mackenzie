# Roteiro do professor · Aula 03 de Data Collection and Storage

APIs REST, Web Scraping e Ingestão no MinIO · sábado, 24/10/2026, 8h30 às 12h10.

Documento de uso do professor. Cada slide tem o horário-alvo, a duração, a fala, a ação na tela e, nas pausas, as respostas esperadas. A fala está escrita para ser dita em voz alta; os números e comandos são os mesmos do slide e do material.

## Mapa de tempo

| Horário | Slides | Bloco |
|---|---|---|
| 8h30 – 8h39 | 1 a 4 | Abertura, agenda, cenário e retomada |
| 8h39 – 9h03 | 5 a 14 | Bloco 1: APIs REST, retry e jitter |
| 9h03 – 9h15 | 15 a 19 | Bloco 2: PTAX, contrato e realidade |
| 9h15 – 9h32 | 20 a 27 | Bloco 3: scraping e coleta educada |
| 9h32 – 9h44 | 28 a 32 | Bloco 4: HTML bruto e escolha da fonte |
| 9h44 – 10h00 | 33 a 39 | Bloco 5: arquitetura e chaves no MinIO |
| 10h00 – 10h20 | 40 a 45 | Método, Etapa 00 e Etapas 01 a 03 |
| 10h20 – 10h30 | 46 a 48 | Etapas 04 e 05 |
| 10h30 – 10h50 | 49 a 57 | Etapas 06 a 09 |
| 10h50 – 11h00 | 58 a 60 | Etapas 10 e 11 |
| 11h00 – 11h26 | 61 a 65 | Etapas 12 a 15 |
| 11h26 – 11h30 | 66 a 68 | Etapas 16 a 18, apresentadas como tarefa da semana |
| 11h30 – 12h00 | 69 e 70 | Quiz |
| 12h00 – 12h10 | 71 e 72 | Fechamento e entrega |

## Antes de começar (8h00 a 8h30)

- Abrir o slide em tela cheia (tecla F) e conferir que as animações dos slides 10, 12, 25 e 37 rodam.
- Deixar um terminal pronto com o `curl` da PTAX do slide 15, para rodar ao vivo.
- Deixar a pasta `aula_03_api_scraping/` com a Etapa 00 já executada e, em outra pasta, os artefatos das Etapas 01 a 11 já gerados. Enquanto o agente roda ao vivo, o resultado pronto sustenta a explicação se a geração atrasar.
- Abrir o painel do quiz (`quiz/painel_aula_03.html`) numa aba separada.
- Os slides 43, 44 e 45 (Etapas 01, 02 e 03) estão com o quadro do prompt e a lista "Revise antes de seguir" vazios na versão atual. Use os prompts das seções 13.1, 13.2 e 13.3 do material, projetando o material nesses três momentos.

---

## Abertura

### Slide 1 · Capa (8h30, 2 min)

Fala:

> Bom dia, pessoal. Hoje é a Aula 03 de Data Collection and Storage: APIs REST, web scraping e ingestão no MinIO. A aula tem duas metades. Até as dez, a gente olha para o que falha numa coleta por API e numa coleta por scraping, sempre com números que eu medi na PTAX do Banco Central e no site books.toscrape.com. Depois das dez, a gente constrói um monitor de preços de livros em 19 etapas, da persona até o código, do mesmo jeito que vocês fizeram nas Aulas 01 e 02. No fim tem quiz.

Ação: avançar.

### Slide 2 · Agenda (8h32, 3 min)

Fala:

> A teoria vai até as dez horas e tem cinco blocos. Cada bloco segue o mesmo desenho: um problema concreto, o conceito, uma conta com números, uma animação quando ajuda, uma pausa para vocês pensarem e os pontos-chave.
>
> Bloco 1 trata de APIs REST, retry e jitter. Bloco 2, da PTAX: o que a documentação promete e o que a API faz de verdade. Bloco 3, de scraping e de coleta educada. Bloco 4, de por que guardar o HTML bruto e de como escolher a fonte. Bloco 5, da arquitetura do monitor e das chaves no MinIO.
>
> Das dez às onze e meia, a construção: contexto, requisitos, modelagem e ADRs, tarefas e testes, e código. Cada etapa tem um slide e um prompt. Às onze e meia, quiz de dez perguntas. Ao meio-dia, a gente fecha o que ficou pronto e o que fica para a semana: as Etapas 16 a 18, que são execução completa, ATAM e Railway.

Ação: avançar.

### Slide 3 · Cenário condutor (8h35, 2 min)

Fala:

> O problema que conduz a aula inteira: uma livraria importadora precisa saber, todo dia, quanto cada título custaria em reais. Para isso ela precisa de duas fontes.
>
> A primeira é o books.toscrape.com, um site de treino de scraping com 1.000 livros em 50 categorias, preço em libras. Ele não tem API, então a coleta é por scraping. A segunda é a PTAX do Banco Central, que dá a cotação da libra para o real e não pede chave.
>
> O resultado de hoje é o HTML e o JSON brutos no bucket raw e dois arquivos JSON Lines no bucket bronze: `livros.jsonl` e `cotacoes.jsonl`. A conversão para reais fica para a Aula 04, que vai ler esse bronze.

Ação: avançar.

### Slide 4 · Retomada das Aulas 01 e 02 (8h37, 2 min)

Fala:

> Duas coisas continuam das aulas anteriores. Da Aula 01, o método: persona, objetivos, spec, plano, tarefas, implementação e ATAM, com prompts no formato CREATE, e cada um usando o agente de código que preferir.
>
> Da Aula 02, o MinIO e a ideia de chave. No object storage, a pasta é só um prefixo da chave. A chave decide como o dado é achado, sobrescrito e relido. E o raw guarda os bytes em schema on read.
>
> A pasta de hoje se chama `aula_03_api_scraping/` e tem a mesma estrutura: AGENTS.md, docs, specs, src e tests.

Transição:

> Vamos começar por uma falha que aconteceu de verdade quando eu preparei esta aula.

---

## Bloco 1 · APIs REST, retry e jitter (8h39 a 9h03)

### Slide 5 · Uma página que não respondeu em 20 s (8h39, 2 min)

Fala:

> No dia 16/10, preparando esta aula, a minha coleta do books.toscrape.com parou numa página de detalhe. O servidor aceitou a conexão e não mandou resposta. O erro está aí: `ReadTimeout`, read timeout igual a 20.
>
> Eu só vi esse erro porque o código tinha `timeout=(5, 20)`: cinco segundos para conectar, vinte para ler. A exceção apareceu em 20 segundos e o coletor pôde decidir o que fazer.
>
> Sem timeout, o `requests` não tem limite padrão. A coleta fica esperando sem prazo, e ninguém fica sabendo. Primeira regra do dia: toda requisição tem timeout.

Ação: avançar.

### Slide 6 · Métodos HTTP e o que eles garantem (8h41, 3 min)

Fala:

> Para decidir se dá para repetir uma requisição, a gente precisa de duas propriedades da RFC 9110. Método seguro é o que não altera o servidor. Método idempotente é o que produz o mesmo efeito se for repetido.
>
> GET é seguro e idempotente: ler duas vezes não muda nada. POST não é nenhum dos dois: repetir pode criar dois pedidos. PUT não é seguro, porque altera, mas é idempotente: substituir o mesmo recurso duas vezes deixa o mesmo resultado. PATCH não tem garantia de idempotência. DELETE é idempotente: apagar de novo deixa o recurso apagado.
>
> O nosso coletor só usa GET na fonte. E no MinIO, um PutObject com a mesma chave e os mesmos bytes também é idempotente. Guardem isso, porque no bloco 5 é o que torna seguro repetir uma gravação que talvez já tenha acontecido.

Ação: avançar.

### Slide 7 · O status code decide a próxima ação (8h44, 3 min)

Fala:

> O código de status diz ao coletor o que fazer. 200 é sucesso: grava o corpo bruto e valida o conteúdo. 304 aparece quando a gente manda `If-None-Match` e a página não mudou: não precisa baixar de novo.
>
> A família 400 é erro do cliente: 400, 401, 403, 404. Repetir não resolve, então o coletor registra e segue. Duas exceções dentro da família: 408, que é timeout do lado do servidor, e 429, que é limite excedido. Nesses dois, o coletor espera e respeita o cabeçalho `Retry-After` se ele vier.
>
> A família 500 é problema do servidor, do proxy ou do gateway: 500, 502, 503, 504. Aqui o coletor repete com backoff e com limite.
>
> A família diz quem errou, mas tem exceção. A PTAX devolve 500 quando a data vem em formato inválido, como a gente vai ver no bloco 2. O erro é nosso, e repetir não resolve. Por isso o limite de tentativas é obrigatório.

Ação: avançar.

### Slide 8 · Paginação, chave de API e ETag (8h47, 3 min)

Fala:

> Quatro conceitos rápidos. Paginação por offset: na PTAX são os parâmetros `$skip` e `$top`. Ela permite saltar páginas, mas, se a coleção muda durante a leitura, você lê um item duas vezes ou pula um.
>
> Paginação por cursor: a resposta traz o link da próxima página, e isso é estável mesmo com inserções. O `li.next` do catálogo de livros funciona assim.
>
> Chave de API vai em cabeçalho e é lida do ambiente. Se ela for na URL, vaza para log e para o manifesto.
>
> ETag: eu medi em 16/10. A página inicial do catálogo tem 51.294 bytes. Com `If-None-Match`, a resposta foi 304 com zero bytes. A PTAX não oferece ETag, então lá esse truque não existe.

Ação: avançar.

### Slide 9 · Timeout, retry, backoff e jitter (8h50, 3 min)

Fala:

> Aqui está a regra em código. A primeira linha é o timeout: cinco segundos para conectar, vinte para ler.
>
> A segunda é a espera antes de repetir. Ela é sorteada entre zero e o menor valor entre um teto e a base vezes dois elevado à tentativa. Com base de um segundo, a espera cai entre 0 e 1 s, depois entre 0 e 2, entre 0 e 4, entre 0 e 8. Isso é backoff exponencial com full jitter. Se o servidor mandar `Retry-After`, vale o valor do servidor.
>
> Três regras acompanham a fórmula. Repetir só o transitório: timeout, erro de conexão, 408, 429 e 5xx. Ter limite de tentativas e registrar a falha no manifesto. E repetir só operação idempotente: mesma chave, mesmos bytes.

Ação: avançar.

### Slide 10 · Animação: uma requisição, quatro tentativas (8h53, 3 min)

Ação: a animação começa sozinha ao entrar no slide. Use "Pausar" para comentar cada evento e "Próximo evento" para avançar. "Reiniciar" recomeça.

Fala, acompanhando a tela:

> O coletor pede a página de detalhe do Sharp Objects. Olhem o relógio da requisição: tentativa 1 de 4, aguardando resposta, regra timeout de 5 e 20.
>
> Passaram 20 segundos sem resposta: read timeout. É transitório, então o coletor sorteia uma espera entre 0 e 1 segundo. Vejam que aparece uma linha no manifesto, com tentativa 1, status nulo, erro ReadTimeout e a espera.
>
> Tentativa 2: o servidor responde 503. Transitório de novo, espera sorteada entre 0 e 2 segundos, mais uma linha no manifesto.
>
> Tentativa 3: 429 com `Retry-After: 2`. Agora o sorteio não vale. O servidor pediu dois segundos e o coletor espera dois segundos.
>
> Tentativa 4: 200. O corpo chegou, e o coletor grava os bytes no raw.
>
> O relógio fica acelerado quatro vezes durante o timeout. As respostas rápidas levam 0,15 s, que foi a mediana que eu medi. A sequência de falhas é ilustrativa. O que importa é que cada tentativa deixou rastro no manifesto.

Ação: avançar.

### Slide 11 · Exemplo numérico 1: cem coletores ao mesmo tempo (8h56, 3 min)

Fala:

> Agora a conta que justifica o jitter. Cem clientes recebem 503 no mesmo instante e repetem quatro vezes, com base de um segundo. Eu simulei em Python com semente fixa.
>
> Com backoff sem jitter, todos esperam 1, depois 2, depois 4, depois 8 segundos. As repetições chegam juntas aos 1, 3, 7 e 15 segundos. O pico é de 100 clientes no mesmo instante, quatro vezes. Cada cliente espera 15 segundos no total.
>
> Com full jitter, as repetições se espalham entre 0 e 13,1 segundos. O pico cai para 23 chegadas em 100 milissegundos. A espera de cada cliente vai de 0 a 15 segundos, com média de 7,5.
>
> Sem jitter, o backoff só adia o pico que derrubou o servidor: os cem voltam juntos. Com o sorteio, o pico cai para menos de um quarto e a espera média fica na metade do teto. E o jitter não substitui o limite de tentativas.

Ação: avançar.

### Slide 12 · Animação: cem coletores depois de um 503 (8h59, 2 min)

Ação: a animação começa sozinha. "Sortear de novo" refaz o sorteio; "Mais rápido" acelera.

Fala:

> É a mesma situação, animada. Cada ponto é um cliente esperando a próxima tentativa. As barras contam chegadas ao servidor a cada 100 milissegundos.
>
> Olhem o lado sem jitter: os pontos andam juntos e as barras sobem em quatro picos de 100. Do lado do full jitter, as chegadas se espalham. Na tabela, comparem o pico em 100 ms e as chegadas acima da capacidade.
>
> A capacidade de 10 por 100 ms é uma hipótese, só para referência visual. A animação sorteia a cada reinício e fica perto da simulação do slide anterior.

Ação: clicar em "Sortear de novo" uma vez, mostrar que o resultado muda pouco, e avançar.

### Slide 13 · Pausa: repetir, esperar ou registrar e seguir? (9h01, 4 min, dos quais 2 min de silêncio)

Fala:

> Pausa. Vocês têm dois minutos. Para cada uma dessas quatro situações, decidam o que o coletor faz, se repete, espera ou registra e segue, e o que vai para o manifesto. Pode ser em dupla.

Ação: esperar 2 minutos. Depois, pedir uma resposta por situação antes de dar a sua.

Respostas esperadas:

- Read timeout na 3ª de 5 tentativas: transitório. O coletor espera um tempo sorteado entre 0 e o teto da tentativa e repete. O manifesto registra a URL, o número da tentativa, o erro `ReadTimeout` e a espera. Se a 5ª também falhar, o item termina como falhou.
- 404 de livro que saiu do catálogo: erro do cliente. Não repete. Registra URL e status 404 e segue para o próximo livro. A extração vai achar um livro a menos que o total declarado, e isso tem de aparecer como falha visível.
- 429 com `Retry-After: 30`: espera 30 segundos, porque o valor do servidor prevalece sobre o sorteio, e repete. O manifesto registra a espera de 30 s.
- 502 do proxy num `put_object`: repete a gravação com a mesma chave e os mesmos bytes. Se o objeto já tinha sido gravado, a repetição sobrescreve com o mesmo conteúdo. O manifesto conta as tentativas da gravação. Isso só é seguro se a chave for determinística, assunto do bloco 5.

Fala de fechamento da pausa:

> Reparem que a última resposta depende de um desenho de chave que a gente ainda não discutiu. Ela volta no bloco 5.

### Slide 14 · Pontos-chave do bloco 1 (9h05, 1 min)

Fala:

> Quatro pontos. Toda requisição tem timeout de conexão e de leitura; sem ele, a falha fica invisível. A família do status diz quem errou e se vale repetir, e o `Retry-After` prevalece. Backoff exponencial com jitter espalha as repetições, e o limite de tentativas encerra o laço. E repetir é seguro quando a operação é idempotente: GET na fonte e mesma chave no MinIO.
>
> Pergunta para o próximo bloco: a PTAX segue essas regras? Vamos ver onde ela foge do contrato.

Observação de tempo: o bloco 1 termina por volta de 9h03 a 9h06. Se passar de 9h06, encurte o slide 16.

---

## Bloco 2 · PTAX, contrato e realidade (9h03 a 9h15)

### Slide 15 · A consulta PTAX que o monitor usa (9h06, 3 min)

Fala:

> Esta é a consulta que o monitor faz. A base é o serviço Olinda do Banco Central. O recurso é `CotacaoMoedaPeriodo`, com três parâmetros: a moeda, GBP, a data inicial e a data final.
>
> Prestem atenção no formato da data: mês, dia, ano, separados por hífen. A janela do exemplo vai de 17/10 a 24/10, que é hoje. A API aceita `$filter`, `$top` e `$skip`.
>
> Os campos que interessam são `cotacaoVenda`, `dataHoraCotacao` e `tipoBoletim`. Cada dia útil tem cinco boletins.

Ação sugerida: rodar o `curl` do slide no terminal e mostrar a resposta. Como hoje é sábado, a última cotação que aparece é de sexta, 23/10.

> Hoje é sábado. Reparem que a última cotação da resposta é de ontem, sexta-feira.

### Slide 16 · O que a documentação da PTAX omite (9h09, 3 min)

Fala:

> Isto eu observei chamando a API em 03/10 e 16/10. Nada disso está na documentação.
>
> Num sábado, a API responde 200 com `value` vazio. Correto, não tem cotação, mas o coletor precisa de uma janela de dias e precisa registrar a data da cotação que usou.
>
> Com a data em ISO, ano-mês-dia, a resposta também é 200 com lista vazia. É um erro silencioso: a API não reclama do formato. Então o código valida o formato antes de chamar.
>
> Com a data em dia-mês-ano, a resposta é 500, "Erro desconhecido". É um 500 causado pelo cliente, o que mostra por que o retry precisa de limite.
>
> E o rótulo do fechamento muda de recurso para recurso: "Fechamento PTAX" num, "Fechamento" no outro. Filtro com texto fixo precisa de teste.
>
> Um detalhe: o corpo do 500 vem entre barra-asterisco, que não é JSON válido. Guardar a resposta inteira antes de interpretar permite corrigir o filtro e reprocessar sem chamar a API de novo.

Ação: avançar.

### Slide 17 · Exemplo numérico 2: a janela que atravessa o feriado (9h12, 2 min)

Fala:

> Consultas de 16/10, libra. Aquela semana teve sábado, domingo e o feriado de 12/10.
>
> `CotacaoMoedaDia` no sábado, 10/10: 200, zero registros, 124 bytes. `CotacaoMoedaDia` na quinta, 15/10: cinco registros, 998 bytes. `CotacaoMoedaPeriodo` de 09/10 a 16/10: 25 registros de cinco dias, 4.475 bytes, 0,44 segundo.
>
> Oito dias renderam cinco dias úteis, porque 10, 11 e 12 não têm boletim. Uma requisição de 4,4 KB garante o último fechamento, que foi 6,7756 em 16/10. E hoje, sábado, 24/10, só a janela encontra o fechamento de sexta.

Ação: avançar.

### Slide 18 · Pausa: qual cotação vale na segunda, 02/11? (9h14, 3 min, dos quais 1 min e meio de silêncio)

Fala:

> Pausa. Finados cai numa segunda-feira em 2026. A coleta roda às 9h, antes do primeiro boletim do dia. Três perguntas no slide. Um minuto e meio.

Respostas esperadas:

- Quantos dias a janela precisa cobrir: o último fechamento é de sexta, 30/10. Sábado 31/10, domingo 01/11 e segunda 02/11 não têm boletim. A janela precisa ir de 30/10 a 02/11, ou seja, voltar três dias a partir de D. Uma margem maior, como os sete dias do slide 15, cobre feriados emendados com uma requisição só.
- Campo que mostra à Aula 04 que a cotação é de sexta: `dataHoraCotacao`, com a data de 30/10. A data da coleta e a data da cotação são coisas diferentes, e o registro precisa das duas.
- Critério de aceite que separa feriado de data em ISO: um critério valida o formato `MM-DD-AAAA` antes da chamada e falha a execução se a data vier em outro formato; outro critério diz que, com formato válido e janela sem nenhum Fechamento, o manifesto registra "janela sem Fechamento". No feriado, a janela traz o fechamento de sexta; com data em ISO, a validação barra antes de chamar.

### Slide 19 · Pontos-chave do bloco 2 (9h17, 1 min)

Fala:

> O contrato é o que a API declara; a realidade se descobre chamando com datas e formatos errados. 200 com lista vazia pode ser fim de semana, feriado ou erro de formato, e o status não distingue. A janela de dias custa uma requisição e garante o último fechamento, e a data efetiva vai para o registro. E o rótulo do boletim muda entre recursos.
>
> A PTAX pelo menos tem contrato. O catálogo de livros não tem API nenhuma. O bloco 3 trata de uma fonte sem contrato.

Observação de tempo: se estiver em 9h17, recupere 2 minutos no bloco 3 encurtando o slide 21.

---

## Bloco 3 · Scraping e coleta educada (9h15 a 9h32)

### Slide 20 · Uma fonte feita para pessoas (9h18, 2 min)

Fala:

> O catálogo foi feito para pessoas lerem. Tudo o que o coletor sabe vem da inspeção do HTML, e o HTML pode mudar sem aviso e sem versão.
>
> Comparem com a PTAX. Contrato: a PTAX documenta recursos e campos; no site, a página é a documentação. Formato: JSON com nomes estáveis contra uma árvore de tags e classes CSS. Paginação: `$skip` e `$top` contra o link next até ele sumir. Mudança: a PTAX tem versão no caminho, v1; o site muda e o seletor quebra. E requisições por dia: uma na PTAX, cerca de 1.081 no site.

Ação: avançar.

### Slide 21 · Seletores do books.toscrape.com (9h20, 3 min)

Ação sugerida: abrir books.toscrape.com numa aba e usar o inspecionar elemento num cartão de livro.

Fala:

> Estes são os seletores. Cada livro na listagem é um `article.product_pod`, vinte por página. O título está no atributo `title` do link `h3 > a`; o texto visível vem truncado, então não sirvam dele. O preço está em `p.price_color`, por exemplo £47.82. O estoque, em `p.instock.availability`. A avaliação é a segunda classe de `p.star-rating`, escrita por extenso, de One a Five. E a próxima página é `li.next > a`, com link relativo, page-2.html.
>
> Na página de detalhe ficam o UPC, na tabela `table.table-striped`, o estoque com quantidade, "In stock (20 available)", e a categoria no breadcrumb. Sigam o link next e não fixem o número de páginas no código.

Ação: avançar.

### Slide 22 · Por que o preço vira Â£47.82 (9h23, 2 min)

Fala:

> Uma armadilha que pega quase todo mundo. O servidor responde `Content-Type: text/html` sem charset. Nesse caso o `requests` assume ISO-8859-1. A libra em UTF-8 tem dois bytes, C2 e A3, e eles viram dois caracteres. O preço aparece como Â£47.82.
>
> Se você passa `r.text` para o BeautifulSoup, herda o erro. Se passa `r.content`, que são os bytes, o BeautifulSoup lê o meta charset UTF-8 da página e acerta.
>
> A regra fica assim: o parser recebe bytes e o MinIO recebe os bytes originais. Conferi em 16/10.

Ação: avançar.

### Slide 23 · Quatro verificações antes de raspar (9h25, 2 min)

Fala:

> Antes do primeiro script, quatro verificações. robots.txt, pela RFC 9309: neste site ele devolve 404, eu conferi em 03/10 e 16/10, mas a gente consulta e registra sempre. Termos de uso: uma proibição contratual vale mesmo sem robots.txt. LGPD: dado pessoal publicado continua sendo pessoal; este catálogo não tem dado pessoal. E cadência: User-Agent com contato, um segundo entre requisições, que é uma hipótese nossa, e sem paralelismo.

Ação: avançar.

### Slide 24 · Exemplo numérico 3: quanto dura uma coleta educada (9h27, 2 min)

Fala:

> Eu rodei a coleta completa em 16/10, sequencial, com um segundo de pausa e retry com jitter. Foram 1.081 páginas: uma inicial, 80 de listagem e 1.000 detalhes. Nenhuma repetição foi necessária. A latência mediana foi 0,15 s, o p95 0,33 s e a máxima 9,9 s, perto da metade do timeout de leitura.
>
> A duração total foi 21 minutos e 57 segundos, e 18 minutos disso foram pausa. 82% do tempo é a pausa que o próprio coletor escolheu. E a primeira tentativa de medição, sem retry, parou num ReadTimeout.

Ação: avançar.

### Slide 25 · Animação: a coleta educada em tempo acelerado (9h29, 2 min)

Ação: começa com "Sequencial, 1 s". Deixe rodar uns 10 segundos e clique em "10 threads, sem pausa".

Fala:

> As mesmas 1.081 páginas com duas políticas. Cada quadrado escurece quando a página termina de baixar. No modo sequencial com um segundo de pausa, olhem o gráfico de carga: cerca de uma requisição por segundo.
>
> Agora dez threads contra o mesmo domínio, sem pausa. Termina em segundos, e a carga sobe para dezenas de requisições por segundo, fora da cadência combinada. Do ponto de vista do site, isso parece ataque.
>
> A latência é sorteada com a mediana e o p95 que eu medi. As hipóteses estão no rodapé: latência estável sob carga e ordem ilustrativa.

Ação: avançar.

### Slide 26 · Pausa: a gerente quer a coleta em cinco minutos (9h31, 3 min, dos quais 1 min e meio de silêncio)

Fala:

> Pausa. A gerente quer a coleta em cinco minutos. Com os números do exemplo 3, o que pode mudar sem violar a coleta educada, e o que precisa ficar como está? São quatro candidatas e três perguntas. Um minuto e meio.

Respostas esperadas:

- Qual o site percebe como ataque: dez threads contra o mesmo domínio. Baixar o intervalo para 0,1 s também multiplica a carga por dez e sai da cadência combinada.
- Qual depende de um dado que o servidor oferece: `If-None-Match` nas reexecuções, porque depende de o servidor mandar ETag. O site manda (304 com 0 B em 16/10); a PTAX não.
- Qual perde o UPC que a Aula 05 usa: pular os detalhes dos livros que não mudaram. UPC e quantidade em estoque só existem na página de detalhe.
- Conclusão para dizer: com 1.081 requisições e 1 s de pausa, só a pausa soma 18 minutos. Cinco minutos não cabem na coleta educada do catálogo inteiro. O caminho é negociar a meta, usar ETag para reduzir bytes ou restringir categorias, e manter cadência e detalhes.

### Slide 27 · Pontos-chave do bloco 3 (9h34, 1 min)

Fala:

> Sem API, a página é o contrato, e seletor ancorado em semântica, como `article.product_pod`, quebra menos. Paginação pelo link next, com `urljoin`, sem número fixo de páginas. O parser recebe bytes, e o MinIO, os bytes originais. robots.txt, termos, LGPD e cadência vêm antes do primeiro script; a cadência custa minutos e evita o bloqueio.
>
> E se o seletor errar por uma semana inteira? O que sobra? É o bloco 4.

Observação de tempo: o alvo era 9h32. Se estiver em 9h35, compense no slide 29.

---

## Bloco 4 · HTML bruto e escolha da fonte (9h32 a 9h44)

### Slide 28 · Guardar o HTML bruto antes de extrair (9h35, 2 min)

Fala:

> A decisão de arquitetura deste bloco é guardar o HTML bruto antes de extrair. Três situações mostram o ganho. Se o seletor ficou errado por uma semana, você corrige e reprocessa a semana a partir do bruto. Se aparece uma pergunta nova sobre um campo que você ignorou, você extrai do histórico. Se o site mudou, você compara a página antiga com a nova.
>
> E a extração falha de forma visível. Página que declara 20 livros e rende zero interrompe a extração com erro. É a mesma camada raw da Aula 02: bytes como chegaram, com procedência, em schema on read.

Ação: avançar.

### Slide 29 · Exemplo numérico 4: quanto custa guardar o bruto (9h37, 2 min)

Fala:

> Quanto isso custa? Tamanhos medidos na coleta de 16/10. Uma coleta gera 1.083 objetos brutos, com 21,5 MiB de HTML e JSON. O `livros.jsonl` da mesma coleta tem 268 KiB. Em 30 dias, 646 MiB de bruto. Em um ano, 395.295 objetos e 7,7 GiB.
>
> O bruto ocupa cerca de 80 vezes o JSON Lines, e mesmo assim cabe em 7,7 GiB por ano. Os mil detalhes somam 86% dos bytes; as listagens, 3 MiB. Pouco espaço compra reprocessamento, campo novo e diagnóstico.

Ação: avançar.

### Slide 30 · API, scraping ou nenhum dos dois (9h39, 2 min)

Fala:

> Como escolher a fonte. Se existe API documentada que entrega o dado, use a API. Se existe exportação oficial, CSV ou dados abertos, baixe o arquivo. Se não há API, o site permite e não há dado pessoal, scraping educado. Se os termos proíbem, ou há login, paywall ou CAPTCHA, nenhum dos dois: negocie ou compre. Dado pessoal sem base legal: nenhum. E se o dado já está no banco de quem está perguntando, leia a fonte interna.
>
> A ordem segue a estabilidade do contrato. No nosso monitor, a cotação tem API oficial e o catálogo não tem.

Ação: avançar.

### Slide 31 · Pausa: quatro fontes para uma rede de postos (9h41, 3 min, dos quais 1 min e meio de silêncio)

Fala:

> Pausa. Uma rede de postos quer comparar seus preços com o mercado. Para cada uma das quatro fontes, qual caminho da tabela anterior? Justifiquem pelo contrato que a fonte oferece.

Respostas esperadas:

- Preços da ANP em CSV nos dados abertos: download do arquivo. É exportação oficial, e scraping seria pior.
- Dólar do dia: API, a PTAX de USD no Olinda, a mesma do monitor.
- Aplicativo com login e termos que proíbem coleta: nenhum. Negociar acesso ou comprar o dado.
- Avaliações com nome e foto do autor: nenhum, porque é dado pessoal sem base legal para esse uso. Se a análise exigir, o caminho passa pela área jurídica e por agregados sem identificação.

### Slide 32 · Pontos-chave do bloco 4 (9h44, 1 min)

Fala:

> O coletor registra o que a fonte entregou e o extrator interpreta; guardar só o interpretado transforma erro de seletor em perda de dado. O bruto custa poucos GiB por ano. Extração que acha zero onde a página declara 20 falha com erro. E scraping vem depois da API e da exportação oficial; às vezes a resposta é nenhum dos dois.

Ação: avançar.

---

## Bloco 5 · Arquitetura e chaves no MinIO (9h44 a 10h00)

### Slide 33 · Coleta e extração em etapas separadas (9h45, 2 min)

Fala:

> A arquitetura do monitor tem cinco passos. Descobrir: lê o robots.txt e as categorias. Páginas: baixa as categorias e os mil detalhes para o raw. PTAX: grava o JSON bruto no raw. Manifesto: registra URLs, status, hash e tentativas. E extrair: lê do MinIO e grava o JSON Lines.
>
> Separar coleta e extração permite reprocessar sem chamar a fonte, isola falha de rede de falha de seletor e permite testar o extrator sem rede. Essa decisão vira o ADR-001 na construção.

Ação: avançar.

### Slide 34 · Chaves determinísticas no MinIO (9h47, 2 min)

Fala:

> Estas são as chaves. No raw: fonte, data, categoria e página para a listagem; fonte, data e livro para o detalhe; fonte, moeda e data para a PTAX. O manifesto é o único que leva o identificador da execução, com data e hora.
>
> No bronze: `livros.jsonl` e `cotacoes.jsonl`, por fonte e data.
>
> Se eu rodar de novo no mesmo dia, as mesmas chaves são sobrescritas. Só o manifesto é novo. Por isso o retry do 502 fica seguro. E os campos do livro são estes nove: upc, url, titulo, categoria, avaliacao, preco_gbp, em_estoque, qtd_estoque e coletado_em.

Ação: avançar.

### Slide 35 · Metadados do objeto e o 502 do Railway (9h49, 2 min)

Fala:

> Cada objeto bruto leva metadados `x-amz-meta`: URL de origem, horário da coleta em UTC, status HTTP, SHA-256 do corpo, id da execução e ETag da fonte. O ContentType é `text/html; charset=utf-8` ou `application/json`.
>
> Metadado só aceita ASCII. Se vocês escreverem "preço" com cedilha, o boto3 recusa com `ParamValidationError`.
>
> Do lado direito, o 502. O Railway põe um proxy na frente do MinIO, e o 502 pode chegar depois de o objeto ter sido gravado. Com mesma chave e mesmos bytes, repetir o `put_object` é seguro, e o manifesto conta as tentativas.
>
> Uma observação prática: o `mc stat` da imagem que a gente usa não mostrou os metadados de usuário. A verificação usa `head_object` do boto3.

Ação: avançar.

### Slide 36 · Exemplo numérico 5: duas execuções por dia durante um mês (9h51, 2 min)

Fala:

> A hipótese: 1.083 objetos por execução, duas execuções por dia, a agendada e uma repetição, durante 30 dias, e 1% dos PUT recebendo 502 depois de gravar.
>
> Uma execução com 502: com chave determinística, 1.083 objetos, e 11 deles foram regravados iguais. Com horário na chave, 1.094 objetos, 11 cópias.
>
> Um dia, duas execuções: 1.083 objetos mais dois manifestos contra 2.188. Trinta dias: 32.490 contra 65.640.
>
> E o pior está no bronze: com horário na chave, o `livros.jsonl` do dia pode chegar a 2.020 linhas se o extrator ler o prefixo inteiro. Com chave determinística, ele bate com as 1.000 do site, e as tentativas ficam no manifesto.

Ação: avançar.

### Slide 37 · Animação: retry no 502, chave fixa contra chave com horário (9h53, 2 min)

Ação: a animação começa sozinha; "Acelerar" se estiver lenta.

Fala:

> Os dois buckets lado a lado. O proxy grava o objeto e às vezes devolve 502, e o coletor repete. Do lado da chave determinística, a repetição cai sobre o mesmo objeto: o contador de regravações sobe, o de objetos a mais fica em zero. Do lado da chave com horário, cada repetição cria um objeto novo.
>
> Agora começa a execução 2. Do lado determinístico, nada cresce. Do lado do horário, o bucket dobra.

Ação: avançar quando a execução 2 terminar.

### Slide 38 · Pausa: o livros.jsonl saiu com 980 linhas (9h55, 3 min, dos quais 1 min de silêncio)

Fala:

> Última pausa. O site declara 1.000 livros e o `livros.jsonl` saiu com 980. Em que ordem vocês investigam, e qual artefato responde cada pergunta?

Respostas esperadas, na ordem:

1. A coleta baixou os 1.000 detalhes? O manifesto responde: URLs, status e tentativas. Se houver 20 itens em falhou, por exemplo 404 ou timeout esgotado, a causa está na coleta.
2. Os objetos estão no bucket? `mc ls` no prefixo `livro=` da data. Se o manifesto diz gravado e o objeto não existe, o problema está na gravação.
3. O extrator descartou páginas? Reprocessar a partir do raw, sem chamar o site. Se há 1.000 detalhes no raw e saem 980 linhas, o seletor ou o parser descartou.

Fala de fechamento:

> A ordem vai da fonte para o bronze, e nenhum passo exige chamar o site de novo.

### Slide 39 · Pontos-chave do bloco 5 e passagem para a prática (9h58, 2 min)

Fala:

> Fechando a teoria. Coleta e extração separadas: a extração lê do MinIO, roda sozinha e é testada sem rede. Chave derivada de fonte, data e página: reexecução e retry não duplicam, e o manifesto é a exceção deliberada. Metadados ASCII com origem, horário, status e hash, conferidos com `head_object`. E a contagem do bronze contra o total declarado é o teste que denuncia cópia ou perda.
>
> Na construção, cada uma dessas decisões vira regra, requisito, ADR, tarefa, teste e cenário ATAM. Abram o Codespace.

---

## Construção em etapas (10h00 a 11h30)

Ritmo geral: em cada etapa, leia o objetivo, mostre o prompt, rode no seu agente e, enquanto ele gera, comente a lista "Revise antes de seguir". Se a geração demorar, mostre o artefato pronto que você preparou antes da aula.

### Slide 40 · Do problema ao código em 19 etapas (10h00, 2 min)

Fala:

> O método vem do repositório cinesenac, que levou um sistema de reservas de cinema da persona até o merge. Aqui ele serve a um sistema de dados. A diferença é que o usuário principal é um pipeline, e a modelagem descreve chaves, contratos de arquivo e manifesto.
>
> São sete grupos. Etapa 00, preparação. 01 a 03, contexto: personas, direcionadores e regras. 04 e 05, requisitos. 06 a 09, modelagem e ADRs. 10 e 11, plano e testes. 12 a 15, código. E 16 a 18, validação, que fica para a semana.
>
> Toda etapa termina com o prompt registrado, literal, em `docs/prompts.md`. É isso que eu uso para corrigir.

Ação: avançar.

### Slide 41 · Da persona ao teste, um fio só (10h02, 3 min)

Fala:

> Antes de começar, o fio que liga tudo. Cada artefato cita o anterior pelo ID. Vamos seguir um exemplo da esquerda para a direita.
>
> P1, o analista de compras que reprecifica em reais. DN-01, o direcionador: margem perdida por câmbio sem data. OBJ-02: cotação de fechamento disponível todo dia. RN-02, a regra: vale o último Fechamento até a data D. RF-05: gravar a resposta PTAX bruta no raw. RNF-04: retry com backoff, jitter e Retry-After. ADR-003: full jitter, com as alternativas descartadas. T-02, a tarefa: o cliente HTTP repete 429 respeitando o servidor. O teste `test_respeita_retry_after_em_429`. E a evidência: as tentativas no manifesto.
>
> Se um teste falha, o fio mostra qual decisão de negócio está em risco. Se o negócio muda, o fio mostra quais testes revisar.
>
> E três definições que vocês vão usar o tempo todo. Regra de negócio vale no mundo, com ou sem software. Requisito funcional é o que o sistema faz para respeitar a regra, com critério Dado, Quando, Então. Requisito não funcional é quão bem o sistema faz, com número e forma de medir.

Ação: avançar.

### Slide 42 · Etapa 00: pasta, MinIO local e registro de prompts (10h05, 5 min)

Ação: copiar o bloco do terminal (botão "Copiar") e rodar no Codespace enquanto fala.

Fala:

> Antes do primeiro prompt, o ambiente precisa responder. A gente cria a estrutura de pastas, copia os quatro arquivos do laboratório da aula, protege o `.env` no `.gitignore`, sobe o MinIO e cria três buckets: raw e bronze para a coleta, e teste para os testes de gravação. Depois cria o ambiente Python e o `docs/prompts.md`. Quem usa Claude Code cria também o `CLAUDE.md` apontando para o `AGENTS.md`.
>
> O gate tem três checagens. `docker compose ps` mostra healthy. `mc ls local` lista raw, bronze e teste. E `git check-ignore .env` imprime `.env`, o que prova que o segredo não vai para o Git.
>
> E a regra do registro: o `AGENTS.md` do laboratório manda o agente acrescentar, ao fim de cada etapa, o prompt literal, a data e os arquivos gerados em `docs/prompts.md`. No cinesenac, essa regra virou a skill update-tutorial.

Ação: mostrar as três checagens do gate passando e avançar.

### Slide 43 · Etapa 01: personas (10h10, 4 min)

Ação: o quadro do prompt está vazio neste slide. Projete a seção 13.1 do material e copie o prompt de lá.

Fala:

> Etapa 01, personas. Em pipeline, a persona tem três lados. P1 decide com o dado. P2 é acionada quando a coleta falha. P3 consome o bronze na aula seguinte.
>
> O prompt pede `docs/00_persona.md` com papel, decisão, pergunta típica, frequência, dor, consequência de dado errado e nível técnico de cada uma. Reparem em dois ajustes: o arquivo declara no topo que o domínio é didático, porque o site avisa que preços e avaliações são aleatórios, e todo valor sem origem recebe "hipótese, validação pendente".
>
> Na revisão, quatro perguntas: cada persona decide algo concreto? A P2 existe e sabe o que a acorda de madrugada? Algum horário ou volume aparece sem marcação de hipótese? O aviso do domínio didático está no topo?

Ação: rodar o prompt, mostrar o plano que o agente apresenta, aprovar e avançar.

### Slide 44 · Etapa 02: direcionadores de negócio e objetivos (10h14, 3 min)

Ação: prompt na seção 13.2 do material.

Fala:

> Direcionador de negócio é a força que justifica o sistema: dinheiro, prazo, risco, regulação. Objetivo é a resposta a essa força, com métrica e um comando que mede.
>
> Para a P1, o direcionador é a margem perdida quando a reprecificação usa câmbio sem data. O objetivo é o snapshot diário completo do catálogo, medido pela contagem do `livros.jsonl` contra o total que o site declara.
>
> O prompt também pede restrições e fora de escopo. Fora de escopo segura a Aula 04 fora daqui: Parquet, DuckDB, silver, gold e conversão para reais. Esses direcionadores voltam na Etapa 17, na utility tree do ATAM.
>
> Revisão: cada OBJ tem um comando que mede? Cada DN tem ao menos um OBJ? O fora de escopo está explícito?

Ação: rodar e avançar.

### Slide 45 · Etapa 03: regras de negócio (10h17, 3 min)

Ação: prompt na seção 13.3 do material.

Fala:

> No cinesenac, a frase do cliente sobre assentos virou três regras numeradas, RN01 a RN03. Aqui, "usar o câmbio certo" vira a RN-02: vale o último boletim Fechamento da PTAX com data menor ou igual a D. O exemplo é a coleta de hoje, sábado, que usa o fechamento de ontem. O contraexemplo é usar o boletim de Abertura de D porque ele saiu antes. O contraexemplo ajuda mais na revisão, porque mostra a interpretação errada que o agente poderia escolher.
>
> A regra vale no mundo; o requisito, na Etapa 04, é o que o sistema faz para respeitá-la. Por isso o prompt proíbe nome de biblioteca, bucket ou função.
>
> Revisão: alguma regra fala de tecnologia? O contraexemplo da cotação é plausível? A regra da execução incompleta tem critério numérico, declarado contra extraído?

Ação: rodar e avançar.

### Slide 46 · Etapa 04: requisitos funcionais (10h20, 5 min)

Fala:

> Requisitos funcionais com Dado, Quando, Então. Cada critério precisa virar teste sem reinterpretação.
>
> Olhem o prompt. Ele cobre descoberta das categorias, paginação, detalhe de cada livro, o filtro `SCRAPER_CATEGORIAS`, gravação do bruto, robots.txt, PTAX com janela, janela sem fechamento, manifesto, extração e reexecução. E ele traz os fatos que eu verifiquei em 03/10 e 16/10: os seletores, o formato de data da PTAX, as respostas vazias. Sem esses fatos, o critério não fica verificável.
>
> O exemplo é o RF-05: dado que a API respondeu 200 com ao menos um Fechamento, quando a coleta da data D termina, então existe o JSON bruto na chave certa, com SHA-256 igual ao do corpo e os metadados.
>
> Um ajuste importante: o total esperado vem da página, e não de uma constante. Mil livros é um fato de 03/10, não uma regra.
>
> Revisão: todo critério vira teste? Existe RF para janela PTAX vazia e para data em formato errado? A matriz RN para RF não tem regra órfã?

Ação: rodar, mostrar o índice dos RFs que o agente apresenta antes de escrever e avançar.

### Slide 47 · Etapa 05: requisitos não funcionais (10h25, 3 min)

Fala:

> Requisitos não funcionais com número e medida, organizados pelos oito eixos da ISO/IEC 25010. As medidas de 16/10 entram como linha de base, e não como meta inventada: 1.081 requisições, mediana de 0,15 s, p95 de 0,33 s, 18 minutos de espera, 1.083 objetos e 21,5 MiB por execução.
>
> O exemplo é o RNF-04, a repetição com backoff e jitter: o critério descreve o que repete, a fórmula da espera e o Retry-After, e a medida é um teste com servidor simulado que conta tentativas e esperas.
>
> O ajuste que mais pega: nada de "rápido" ou "robusto" sem número. Número sem origem recebe "hipótese, validação pendente".
>
> Revisão: os oito eixos aparecem? Cada RNF tem medida que um teste, um comando ou o manifesto prova? A linha de base foi tratada como medida?

Ação: rodar e avançar.

### Slide 48 · ISO/IEC 25010 aplicada ao monitor (10h28, 2 min)

Fala:

> Esta tabela ajuda a revisar o que o agente gerou. No cinesenac, o cenário era um frontend com 10.000 usuários. Num coletor diário, confiabilidade e respeito à fonte pesam mais que tempo de resposta.
>
> Adequação funcional: linhas extraídas iguais ao total declarado. Desempenho: uma requisição por vez e duração no manifesto. Compatibilidade: a Aula 04 lê o bronze sem adaptar. Usabilidade: a P2 entende a falha às 7h pelo manifesto. Confiabilidade: retry com limite e zero duplicados. Segurança: `git grep` sem segredo. Manutenibilidade: extração testada com fixtures e reprocesso a partir do raw. Portabilidade: mesmo código local e no Railway, só o `.env` muda.

Ação: avançar.

### Slide 49 · Etapa 06: modelo de dados (10h30, 4 min)

Fala:

> Num data lake, o modelo de dados tem três partes: onde cada objeto mora, o contrato de cada arquivo do bronze e o registro da execução. O DBML documenta as relações lógicas mesmo sem banco.
>
> O prompt pede o layout de chaves, o dicionário do bronze com os nove campos de `livros.jsonl` e os cinco de `cotacoes.jsonl`, o manifesto com cabeçalho e itens, os metadados ASCII e o DBML com cinco entidades.
>
> O ajuste principal: os nomes dos campos do bronze são contrato com as próximas aulas. Não renomeiem nem traduzam. E a única chave com id de execução é a do manifesto.
>
> Revisão: os nove e os cinco campos estão com os nomes exatos? Cada campo tem origem rastreável? Alguma chave usa horário? O DBML abre no dbdiagram.io?

Ação: rodar e, se der tempo, colar o DBML no dbdiagram.io.

### Slide 50 · Modelo lógico do monitor (10h34, 2 min)

Fala:

> É assim que o modelo deve ficar. Uma execução tem muitos itens de manifesto. Cada item aponta para um objeto do raw pela chave. Um `detalhe.html` gera um livro. Um JSON da PTAX gera várias cotações. Cinco entidades em três prefixos.
>
> Comparem com o que o agente de vocês gerou. Os campos do bronze são contrato com as Aulas 04, 05 e 07.

Ação: avançar.

### Slide 51 · Etapa 07: componentes e classes (10h36, 3 min)

Fala:

> Modelagem estática, antes do código. Os nomes do diagrama são os nomes que vão para `src/`. Dois limites valem para a aula inteira: o coletor não conhece o MinIO, porque recebe um gravador; e o extrator não conhece a rede, porque não importa `requests`.
>
> O prompt pede o diagrama de componentes em Mermaid, com responsabilidade, interface, RF e RNF de cada componente, e o diagrama de classes com Config, ClienteHttp, os coletores, GravadorS3, Manifesto, Extrator, Livro e Cotacao.
>
> Um ajuste prático: Mermaid sem ponto e vírgula dentro de rótulo, porque quebra a renderização.
>
> Revisão: há seta do extrator para a rede? Não pode haver. Todo RF aparece em algum componente? O diagrama renderiza no preview do GitHub?

Ação: rodar e avançar.

### Slide 52 · Componentes e o limite da rede (10h39, 2 min)

Fala:

> O resultado esperado. À esquerda, as fontes externas. No centro, o ClienteHttp, os coletores, o GravadorS3 e o Manifesto. À direita, o bucket raw, o Extrator, que lê do raw, e o bronze, onde ele grava.
>
> Só os coletores falam com a rede, sempre pelo ClienteHttp. O extrator lê e grava no MinIO e roda sem internet.

Ação: avançar.

### Slide 53 · Etapa 08: sequências com falha e estados do item (10h41, 2 min)

Fala:

> Modelagem dinâmica. Um diagrama de sequência por fluxo, sempre com o caminho de erro: PTAX com janela, categoria com paginação, 429 e timeout, gravação com 502 do Railway, extração e reexecução. E um diagrama de estados do item do manifesto: pendente, baixando, aguardando, baixado, gravado e falhou.
>
> Revisão: o 502 aparece com a mesma chave no retry? O diagrama de extração não toca nenhuma fonte externa? O estado falhou é final e fica registrado no manifesto?

Ação: rodar e avançar.

### Slide 54 · Um detalhe de livro com 429 e 502 (10h43, 2 min)

Fala:

> Um diagrama de sequência pronto. O ColetorBooks pede ao ClienteHttp, que recebe 429 com Retry-After 2. Ele espera dois segundos e recebe 200. Depois o GravadorS3 manda o PUT, o MinIO do Railway devolve 502, o gravador espera e repete o PUT na mesma chave.
>
> A fonte pede calma, o proxy falha depois de gravar, e o bucket termina com um objeto só. É a pausa do bloco 1 desenhada.

Ação: avançar.

### Slide 55 · Estados de um item do manifesto (10h45, 1 min)

Fala:

> Cada URL percorre estes estados, e o manifesto grava o estado final e o caminho. É por aqui que se responde por que o `livros.jsonl` saiu com 980 linhas: os 20 que faltam estão em falhou, ou chegaram a gravado e o extrator descartou.

Ação: avançar.

### Slide 56 · Etapa 09: uma ADR por tática de qualidade (10h46, 2 min)

Fala:

> Sete decisões já apareceram na teoria. Cada uma vira um ADR com contexto, alternativas e custo. O status é Proposta, porque aceitar é decisão do grupo.
>
> O exemplo é o ADR-003: o contexto é o RNF-04 e os cem clientes que voltam juntos; a decisão é a fórmula com full jitter; as alternativas são intervalo fixo, backoff sem jitter e sem retry; e as consequências trazem o custo: a duração da coleta passa a variar.
>
> Revisão: cada ADR tem pelo menos duas alternativas reais? As consequências trazem o custo, e não só o benefício? O mapa tática para RNF cobre os de confiabilidade?

Ação: rodar e avançar.

### Slide 57 · As táticas da teoria viram ADRs (10h48, 2 min)

Fala:

> A tabela-resumo. 001, coleta e extração separadas, ao custo de uma etapa a mais para operar. 002, chave por fonte, data e página, que perde a versão intermediária do dia. 003, full jitter, com duração variável. 004, coleta sequencial, com cerca de 18 minutos de espera. 005, bytes originais no raw, o que obriga a decodificar em todo parser. 006, manifesto por execução, um objeto a mais. 007, janela de dias na PTAX, com resposta maior e data a declarar.
>
> Reparem que toda linha tem uma coluna de custo preenchida. No ADR de vocês, as consequências precisam trazer esse custo.

Ação: avançar.

### Slide 58 · Etapa 10: plano e tarefas de até 30 minutos (10h50, 4 min)

Fala:

> O plano justifica cada biblioteca com um RNF. As bibliotecas são requests, beautifulsoup4, boto3, python-dotenv e pytest. Outra biblioteca só entra com RNF que a justifique.
>
> As tarefas já nascem agrupadas nas Etapas 12 a 15, cada uma com o teste que prova a conclusão. O exemplo é a T-02: arquivos, requisitos, ADR, o teste com servidor simulado que responde 429 com Retry-After 2 e depois 200, o comando e a dependência.
>
> Revisão: alguma tarefa mexe em mais de três arquivos? Existe tarefa para cada falha tratada, timeout, 429, 5xx, PTAX vazia, 502 e reexecução? Algum RF ficou sem tarefa?

Ação: rodar e avançar.

### Slide 59 · Etapa 11: três páginas reais como fixtures (10h54, 3 min)

Ação: copiar o bloco do terminal e rodar. Trocar `<org>/<repo>` pelo repositório do grupo.

Fala:

> Os testes de parser leem arquivos locais. Essas fixtures são baixadas uma única vez, com o mesmo User-Agent e a mesma pausa da coleta.
>
> Por que páginas reais? Uma fixture escrita à mão testa o que o agente imagina do site. A página real traz o Content-Type sem charset, a libra em UTF-8 e o UPC do Sharp Objects, e00eb4fd7b871a48.
>
> Eu conferi ontem, 23/10: a página inicial declara 1000 resultados, e o detalhe traz "In stock (20 available)", avaliação Four e preço £47.82.

Ação: rodar os três `curl` e avançar.

### Slide 60 · Etapa 11: testes vermelhos a partir dos critérios (10h57, 3 min)

Fala:

> Os critérios Dado, Quando, Então viram cenários Gherkin, com a tag do requisito, e cada cenário vira um teste pytest com o mesmo nome. Todos têm de falhar pelo motivo certo antes de existir código: ImportError ou NotImplementedError, e não erro no próprio teste.
>
> O exemplo extrai UPC, preço e estoque da página do Sharp Objects. Nenhum teste acessa a rede. Os testes de gravação levam a marca `minio` e usam o bucket teste.
>
> Revisão: há um cenário para cada critério? Os testes falham pelo motivo certo? Algum teste depende da ordem de execução?

Ação: rodar e mostrar a saída do `pytest -q` toda vermelha.

> Vermelho é o estado esperado agora.

### Slide 61 · Etapas 12 a 15: um prompt, quatro rodadas (11h00, 3 min)

Fala:

> As quatro etapas de código usam o mesmo prompt. Muda só o intervalo de tarefas. Rodada 12: configuração e cliente HTTP. 13: gravador no MinIO e manifesto. 14: coletores da PTAX e do catálogo. 15: extrator e linha de comando.
>
> Os testes da Etapa 11 são o contrato. O agente não pode alterar teste para fazer passar; se o teste estiver errado, ele para e explica. Para cada tarefa: plano, teste vermelho, implementação mínima, `pytest -q` verde, tarefa marcada e só então a próxima.
>
> Revisão em toda rodada: o teste estava vermelho antes? O diff mexe só nos arquivos da tarefa? Existe `requests.get` sem timeout? Algum segredo ou URL do Railway no código?

Ação: preencher o prompt com as tarefas da Etapa 12 e rodar.

### Slide 62 · Etapa 12: o cliente que toda coleta usa (11h03, 6 min)

Fala:

> Aqui está a teoria do bloco 1 em vinte linhas. `deve_repetir`: nulo, que é timeout ou erro de conexão, 408, 429 ou qualquer 5xx. `espera`: se veio Retry-After, o servidor manda; senão, sorteio entre zero e o menor entre teto e base vezes dois à tentativa. E a chamada com timeout de conexão e de leitura, User-Agent, e o `sleep` do intervalo depois, sem threads.
>
> As tarefas: a Config lê o `.env` e recusa intervalo abaixo do mínimo; o `ClienteHttp.get` devolve bytes e a lista de tentativas; e o servidor simulado responde 429 com Retry-After 2 e depois 200.
>
> O gate é `pytest tests/test_http.py tests/test_config.py -q`. Requisito RNF-04, ADRs 003 e 004.

Ação: mostrar o gate verde e avançar.

### Slide 63 · Etapa 13: gravador no MinIO e manifesto (11h09, 6 min)

Fala:

> O gravador. A chave é derivada de fonte, data e página, e o número da página tem três dígitos. O corpo é `resp.content`, bytes, nunca `resp.text`. O `put_object` leva o ContentType e os metadados: fonte-url, coletado-em, sha256 e execução, todos em ASCII.
>
> As tarefas: chave determinística, SHA-256 nos metadados e no manifesto, e retry do `put_object` na mesma chave depois de 502.
>
> O gate é `pytest -m minio -q` e um `mc ls local/teste` para ver os objetos. ADRs 002 e 006.

Ação: mostrar o gate e avançar.

### Slide 64 · Etapa 14: coletores da PTAX e do catálogo (11h15, 6 min)

Fala:

> Os dois coletores gravam o bruto antes de qualquer interpretação.
>
> Na PTAX, a janela volta `ptax_janela_dias` a partir da data de referência, e as datas vão em mês-dia-ano. Depois filtra os boletins Fechamento; se não houver nenhum, o manifesto registra "janela sem Fechamento".
>
> No catálogo, o BeautifulSoup recebe `resp.content`, busca `li.next > a` e resolve o link com `urljoin`. Quando não há próxima, a paginação termina. Nada de número fixo de páginas.
>
> As tarefas: robots.txt consultado e registrado, que hoje dá 404; categorias, paginação e detalhes; e `SCRAPER_CATEGORIAS` para restringir a coleta no desenvolvimento. Gate: `pytest tests/test_coletores.py -q`. ADRs 005 e 007.

Ação: mostrar o gate e avançar.

### Slide 65 · Etapa 15: extrator e linha de comando (11h21, 5 min)

Fala:

> O extrator lê só do MinIO. Ele abre a página inicial guardada no raw e lê o total declarado em `form.form-horizontal strong`. Extrai cada detalhe. Se o número de linhas for diferente do declarado, levanta `ExtracaoIncompleta`, com "980 de 1000", por exemplo. Só depois grava o `livros.jsonl` no bronze.
>
> As tarefas: `livros.jsonl` com os nove campos, `cotacoes.jsonl` com os cinco, e dois comandos, coletar e extrair, cada um com `--data`. O gate é o `pytest -q` inteiro verde.

Ação: rodar `pytest -q` e avançar.

### Slide 66 · Etapa 16: execução local e reexecução (11h26, 2 min, tarefa da semana)

Fala:

> Daqui em diante é tarefa da semana. Etapa 16: primeiro duas categorias, mystery e poetry, depois, com autorização, a coleta completa de cerca de 18 minutos. A reexecução é o teste da chave determinística.
>
> O checklist: linhas do `livros.jsonl` iguais ao total declarado e ao número de `detalhe.html`; todo registro com upc e qtd_estoque inteiro; PTAX com ao menos um Fechamento na janela; reexecução com a mesma contagem e um manifesto a mais; e `git status` sem `.env`.

Ação: avançar.

### Slide 67 · Etapa 17: ATAM, rastreabilidade e cobertura (11h28, 1 min, tarefa da semana)

Fala:

> Etapa 17: o ATAM começa nos direcionadores da Etapa 02, com sete cenários obrigatórios, cada um com as seis partes. A matriz de rastreabilidade é derivada dos arquivos, e a cobertura vem do comando `pytest --cov=src`, sem arredondar. Quem quiser ir além monta o workflow no GitHub Actions com o MinIO como service container.

Ação: avançar.

### Slide 68 · Etapa 18: Railway (11h29, 1 min, tarefa da semana)

Fala:

> Etapa 18: mesmo código, outro endpoint. Só o `.env.railway` muda. O proxy do Railway pode devolver 502, então procurem no manifesto gravações com mais de uma tentativa. A entrega é a pasta completa e, no MinIO do Railway, os cinco prefixos de pelo menos uma data.

Transição:

> Celulares na mão. Vamos para o quiz.

---

## Quiz (11h30 a 12h00)

### Slide 69 · Dez perguntas sobre a teoria da manhã (11h30, 2 min)

Ação: projetar o QR do painel do quiz.

Fala:

> Quiz ao vivo, no estilo Kahoot, respondido no celular. São dez perguntas. Três retomam a Aula 02: tipos de storage, chave particionada na camada raw e schema on read. Sete são sobre os blocos de hoje: status e retry, jitter, PTAX, codificação, escolha da fonte e chaves.
>
> Apontem a câmera para o QR e escolham o nome que vai aparecer no placar. O relatório por tema mostra a mim e a cada um de vocês o que retomar antes da Aula 04.

### Slide 70 · Pontuação e tempo (11h32, 1 min)

Fala:

> As regras. 90 segundos por pergunta, e a pergunta abre para todos ao mesmo tempo. Quatro alternativas, e depois do toque a resposta não muda. Acerto vale mais quanto mais rápido; erro vale zero. A pergunta 10 vale o dobro e pode virar o placar.
>
> Atenção ao strike: se vocês saírem da aba com a pergunta aberta, os pontos dela zeram.
>
> Depois de cada pergunta eu mostro a alternativa correta, a explicação e o placar. No fim, cada um vê os temas que errou, com a seção do material.

Ação: abrir a primeira pergunta no painel. Conduzir as dez perguntas até 11h58, comentando cada explicação em até 30 segundos. Ao fim, mostrar o relatório por tema e anotar os dois temas com mais erro.

---

## Fechamento (12h00 a 12h10)

### Slide 71 · O que existe às 12h10 e o que fica para a semana (12h00, 6 min)

Fala:

> Fechando. O que tem de existir até agora, na pasta de vocês: a Etapa 00, com a pasta e o MinIO local com três buckets; as Etapas 01 a 10 revisadas, da persona até o `tasks.md`; a Etapa 11 com o primeiro teste verde; e o quiz respondido, com os temas a retomar anotados.
>
> Na semana, até a Aula 04, dia 31/10: Etapas 12 a 15 com `pytest -q` verde; Etapa 16, coleta completa e reexecução; Etapa 17, ATAM, rastreabilidade e cobertura; e Etapa 18, uma data no MinIO do Railway.
>
> O material tem o tutorial completo, com todos os prompts, e o README do laboratório tem o roteiro passo a passo.

Ação: citar os dois temas com mais erro no quiz e a seção do material correspondente. Avançar.

### Slide 72 · Entrega no repositório do grupo (12h06, 4 min)

Fala:

> A entrega é a pasta `aula_03_api_scraping/` no repositório do grupo. Eu corrijo seguindo o `docs/prompts.md` e a matriz de rastreabilidade: cada teste precisa levar a um requisito, e cada requisito a uma persona.
>
> São quatro grupos de artefatos. Contexto e requisitos: prompts, persona, objetivos, regras, RF, RNF, modelo de dados e DBML. Modelagem e decisões: componentes, classes, sequências, estados, `arquitetura.md` e as sete ADRs em Proposta. Código: plan, tasks, features, src e tests com `pytest -q` verde. Validação e Railway: ATAM, rastreabilidade e os objetos em raw e bronze no MinIO do Railway.
>
> Dúvidas agora ou pelo canal da turma. Bom fim de semana, e até sábado que vem.

---

## Plano B de tempo

- Atraso de até 5 minutos na teoria: encurtar os slides 16, 21 e 29 para a leitura do quadro "O que a conta mostra".
- Atraso de mais de 5 minutos na teoria: reduzir as pausas dos slides 26 e 31 para 1 minuto e responder em voz alta sem recolher respostas.
- Atraso na construção: nas Etapas 06 a 09, mostrar os artefatos já prontos em vez de rodar o agente, e rodar ao vivo só as Etapas 11 e 12.
- O quiz começa às 11h30 em qualquer cenário; as Etapas 13 a 15 podem ficar para a semana, junto das 16 a 18.
