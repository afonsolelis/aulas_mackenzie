# Roteiro da Aula 03 · APIs REST, Web Scraping e Ingestão no MinIO

Data Collection and Storage · MBA em Engenharia de Dados · sábado, 24/10/2026, 8h30 às 12h10

Teleprompter da aula: para cada um dos 123 slides, o horário de chegada, a duração, o que fazer (linhas `[AÇÃO]`) e o texto da fala. Perguntas à turma vêm marcadas com `[ESPERE]` e a resposta esperada logo abaixo.

Arquivos da aula:

- Slides: `aulas/data_collection_and_storage/aula_03_apis_rest_web_scraping_e_ingestao_no_minio/slides/slide_aula_03_apis_rest_web_scraping_e_ingestao_no_minio.html`
- Material (prompts completos): `.../material/material_aula_03_apis_rest_web_scraping_e_ingestao_no_minio.html`
- Laboratório: `.../laboratorio/README.md` e `.../laboratorio/AGENTS.md`
- Quiz: `.../quiz/quiz_aula_03.html` e `.../quiz/painel_aula_03.html` (botões Quiz e Área do professor no rodapé do slide)

## Mapa do tempo

| Horário | Slides | Parte |
|---|---|---|
| 08:30 | 1 a 4 | Abertura, problema e retomada |
| 08:38 | 5 a 27 | Bloco 1 · APIs REST, HTTP, paginação, ETag, retry e jitter |
| 09:05 | 28 a 39 | Bloco 2 · PTAX, OData e a janela de dias |
| 09:20 | 40 a 55 | Bloco 3 · Scraping, HTML, seletores, charset e coleta educada |
| 09:40 | 56 a 64 | Bloco 4 · Bruto, camadas e escolha da fonte |
| 09:50 | 65 a 77 | Bloco 5 · Arquitetura, manifesto, chaves e o 502 |
| 10:05 | 78 a 84 | Construção · método, CREATE, rastreabilidade e Etapa 00 |
| 10:12 | 85 a 91 | Etapas 01 a 05 · personas, direcionadores, regras, RF e RNF |
| 10:30 | 92 a 104 | Etapas 06 a 09 · modelo de dados, modelagens e ADRs |
| 10:50 | 105 a 110 | Etapas 10 e 11 · tarefas e testes vermelhos |
| 11:00 | 111 a 115 | Etapas 12 a 15 · código |
| 11:25 | 116 a 119 | Etapas 16 a 18 · trabalho da semana |
| 11:30 | 120 e 121 | Quiz |
| 12:00 | 122 e 123 | Fechamento e entrega |

A agenda do slide 2 mostra a teoria até 10h00. Com os slides de conceito, o roteiro leva a teoria até 10h05; a diferença sai da construção.

## Antes da aula

- [ ] Deck aberto no navegador da projeção, em tela cheia (tecla `F`). Setas ou espaço avançam.
- [ ] As quatro animações testadas com Pausar e Reiniciar: slides 23, 25, 53 e 75.
- [ ] Codespace do repositório de demonstração aberto, com a pasta `aula_03_api_scraping/` criada e os arquivos de apoio do laboratório copiados.
- [ ] MinIO local de pé: `docker compose up -d --wait` e `docker compose ps` mostrando `(healthy)`.
- [ ] Agente de código autenticado no terminal e `AGENTS.md` na pasta (no Claude Code, `CLAUDE.md` com `@AGENTS.md`).
- [ ] Fontes respondendo: `curl -sI https://books.toscrape.com/ | head -5` e a consulta da PTAX do laboratório.
- [ ] Material aberto numa aba, na seção da construção em etapas, como plano B dos prompts.
- [ ] Painel do quiz aberto na Área do professor, sem projetar.

## Se o tempo apertar

- Na teoria, passe em 20 a 30 segundos pelos slides de conceito que a turma já domina (por exemplo, 10 Métodos HTTP, 12 Status code, 41 API contra página, 62 API, scraping ou nenhum dos dois). As pausas para reflexão não devem ser cortadas: são elas que mostram se a turma entendeu.
- Na construção, as Etapas 01 a 11 são a prioridade em sala. Se às 11h10 a Etapa 11 não tiver terminado, mostre só o slide 111 e deixe as Etapas 12 a 15 para a semana, com o material.
- O quiz começa às 11h30 em qualquer caso.

---

## Abertura · 08:30

### Slide 1 · APIs REST, Web Scraping e Ingestão no MinIO
`08:30 · 1 min`

Bom dia. Hoje é a Aula 03, e o assunto é coleta: como trazer dado de fora para dentro do nosso data lake.

Vamos ver o que falha numa coleta por API e numa coleta por scraping. Os números que vocês vão ver foram medidos de verdade, na PTAX do Banco Central e no site books.toscrape.com.

Depois da teoria, a gente constrói junto um monitor de preços de livros, em 19 etapas, da persona até o código gravando no MinIO. E no fim tem quiz.

### Slide 2 · Teoria até 10h00, construção até 11h30
`08:31 · 2 min`

A manhã tem três partes. Até as dez, teoria em cinco blocos. Cada bloco tem um exemplo com números, algumas animações, uma pausa para vocês pensarem e uma síntese.

Das dez às onze e meia, a construção. Cada slide é uma etapa, e cada etapa tem o prompt que vocês vão usar no agente de código.

Às onze e meia, quiz de dez perguntas. Ao meio-dia, o fechamento. As Etapas 16 a 18, que são execução completa, ATAM e Railway, ficam para a semana.

### Slide 3 · Converter preços em libras para reais
`08:33 · 2 min`

[AÇÃO] Apontar os dois cartões das fontes, depois o cartão do resultado.

O cenário da aula inteira é este. Uma livraria importadora quer saber, todo dia, quanto cada título custaria em reais.

O preço está num site, em libras. O site é o books.toscrape.com, um site de treino com 1.000 livros em 50 categorias. Ele não tem API, então vamos ler a página feita para pessoas e tirar os dados dela. Isso é scraping.

O câmbio vem de outra fonte: a API PTAX do Banco Central. Uma API entrega o dado pronto para programas, em JSON, num endereço documentado. E essa não pede chave.

No fim, o resultado fica no MinIO em dois lugares. No raw, o HTML e o JSON exatamente como a fonte entregou. No bronze, dois arquivos, livros.jsonl e cotacoes.jsonl, com um registro por linha, já separado em campos.

### Slide 4 · O mesmo método e o mesmo MinIO
`08:35 · 3 min`

Seis termos das aulas anteriores voltam hoje em quase todo slide. Vou passar rápido por cada um.

SDD, Spec-Driven Development: o código nasce de documentos revisados. Persona, requisitos, plano, tarefas. São as 19 etapas da construção.

CREATE é o formato dos nossos prompts, em seis partes: personagem, pedido, exemplos, ajustes, tipo de saída e extras. Um prompt por etapa.

MinIO é o object storage compatível com a API S3. Ele guarda arquivos, que chamamos de objetos, dentro de buckets. Hoje usamos os buckets raw e bronze.

A chave é o nome completo do objeto. A pasta que vocês veem é só um prefixo da chave.

Schema on read quer dizer guardar o dado sem impor estrutura e aplicar a estrutura na hora de ler. Por isso o raw guarda o HTML e o JSON intactos.

E o manifesto é o arquivo que cada execução grava com o que tentou: URLs, status, tentativas e hash. É ele que responde "o que aconteceu na coleta?".

Tudo isso vai morar na pasta aula_03_api_scraping do repositório do grupo.

## Bloco 1 · APIs REST, HTTP e falhas de rede · 08:38

### Slide 5 · API, REST e recurso
`08:38 · 1 min`

Começa o bloco 1. API é a porta que um sistema abre para outro programa pedir dados sem passar pela tela feita para pessoas.

REST é o estilo mais comum dessas portas na web. Cada coisa que se pode pedir tem um endereço próprio e é lida com os verbos do HTTP.

[AÇÃO] Apontar a coluna "Na PTAX" da tabela.

Na PTAX, o recurso são as cotações de uma moeda num período. O endpoint é a URL desse recurso. Os parâmetros, como a moeda GBP e a data inicial, vão escritos na própria URL. A resposta vem em JSON. E o contrato é o que a documentação do portal Olinda promete.

O catálogo de livros não tem nada disso. Os dados estão no HTML, e é por isso que ele exige scraping, assunto do bloco 3.

### Slide 6 · Anatomia de uma requisição e de uma resposta
`08:39 · 1 min 30 s`

Toda conversa HTTP tem duas mensagens, e cada uma tem três partes. Os valores aqui são reais: a página inicial do catálogo, conferida ontem.

[AÇÃO] Apontar o lado esquerdo do diagrama, de cima para baixo.

A requisição começa com a linha de pedido: método, caminho e versão. Aqui, GET barra. Depois vêm os cabeçalhos, pares de nome e valor, como o Host e o nosso User-Agent. O corpo está vazio, porque o GET só pede.

[AÇÃO] Apontar o lado direito.

A resposta começa com a linha de status: 200 OK, deu certo. Nos cabeçalhos, o tipo do conteúdo, o tamanho de 51.294 bytes e um tal de etag, que vamos usar daqui a pouco. E o corpo é o HTML da página.

Guardem a divisão: o bruto guarda o corpo; o manifesto guarda o status e os cabeçalhos úteis.

### Slide 7 · Uma página que não respondeu em 20 s
`08:40 · 1 min`

Agora um problema real. No dia 16, preparando esta aula, a coleta parou numa página de detalhe. O servidor aceitou a conexão e simplesmente não mandou a resposta.

[AÇÃO] Apontar a mensagem de erro ReadTimeout.

Como eu tinha passado timeout igual a 5 e 20, o requests esperou até 5 segundos para conectar e até 20 pela resposta. Passou do limite, ele levantou essa exceção, e o coletor pôde decidir: repetir, registrar ou desistir.

Sem timeout, o requests não tem limite padrão. A coleta fica parada, sem erro nenhum, e ninguém sabe que ela travou.

### Slide 8 · Timeout de conexão e timeout de leitura
`08:41 · 1 min`

Os dois números do timeout valem para fases diferentes da requisição.

[AÇÃO] Apontar as três linhas do diagrama, de cima para baixo.

Na primeira linha, uma página normal: a mediana que medimos foi 0,15 segundo. Na segunda, um servidor fora do ar: a conexão nunca abre, e o ConnectTimeout chega aos 5 segundos. Na terceira, o nosso caso do dia 16: conectou, nenhum byte chegou, e o ReadTimeout veio aos 20.

Um detalhe que engana muita gente: o timeout de leitura conta o silêncio entre dois pedaços da resposta, e não a duração total do download.

### Slide 9 · Seguro e idempotente: o que pode ser repetido
`08:42 · 1 min 30 s`

Depois de um timeout, o coletor tem uma dúvida: o servidor chegou a executar o pedido ou não? Repetir só é inofensivo em dois casos, definidos na RFC 9110, a norma do HTTP.

Seguro é o pedido que só lê. Pedir a página inicial cem vezes não muda o catálogo.

Idempotente é o pedido que, repetido, deixa o servidor no mesmo estado que se fosse feito uma vez só.

[AÇÃO] Apontar os três cartões de baixo, da esquerda para a direita.

Pensem num pagamento por POST. O pedido chega, o servidor cobra, a resposta se perde no caminho. O cliente repete, e o cartão é cobrado duas vezes. Não é seguro nem idempotente.

O GET de uma página é seguro e idempotente: repetir só traz a mesma página.

E o PUT no MinIO muda o servidor, mas gravar a mesma chave com os mesmos bytes duas vezes deixa um objeto só. É idempotente.

### Slide 10 · Métodos HTTP e o que eles garantem
`08:44 · 45 s`

O método é o verbo da requisição: diz ao servidor o que fazer com o recurso da URL.

[AÇÃO] Apontar a linha do GET e depois a do PUT.

Não precisa decorar a tabela. O que importa para nós: o coletor só usa GET nas fontes, que é seguro e idempotente. E, no MinIO, gravar com a mesma chave e os mesmos bytes também pode ser repetido. Por isso a gravação aceita retry.

### Slide 11 · Status code: quem errou, cliente ou servidor
`08:44 · 1 min 15 s`

O status code é o número de três dígitos na primeira linha da resposta. O primeiro dígito, a família, já diz o tipo de resultado.

Dois mil e pouco, deu certo. Trezentos, vá a outro lugar ou use a cópia que você já tem. Quatrocentos, o pedido do cliente tem problema. Quinhentos, o servidor ou algo no caminho falhou.

[AÇÃO] Apontar o diagrama coletor, proxy do Railway e MinIO.

Esse "algo no caminho" é o proxy: um intermediário que recebe a requisição e repassa para outro serviço. O gateway é o proxy na porta de entrada. O 502 diz que o serviço de trás respondeu mal; o 504, que ele não respondeu a tempo; o 503, que está indisponível agora.

No nosso monitor, o 502 aparece ao gravar no MinIO do Railway. Quem responde é o proxy, e o objeto pode ter sido gravado mesmo assim. Voltamos a isso no bloco 5.

### Slide 12 · O status code decide a próxima ação
`08:46 · 1 min`

Para cada resposta, o coletor escolhe: gravar, repetir ou registrar a falha e seguir.

[AÇÃO] Percorrer a tabela linha a linha, só pela coluna "Coletor".

200, grava o corpo bruto e valida. 304, a página não mudou, não baixa de novo. 400, 401, 403 e 404, o pedido tem problema, então não repete: registra. 408 e 429, espera, respeitando o Retry-After. E a família 500, repete com backoff e com limite.

Retry-After é o cabeçalho em que o servidor diz quantos segundos esperar. Backoff é esperar cada vez mais entre tentativas, e vem nos próximos slides.

Uma exceção que vamos ver no bloco 2: a PTAX devolve 500 para data em formato inválido, e repetir não resolve. Por isso o limite de tentativas é obrigatório.

### Slide 13 · Paginação: a coleção chega em pedaços
`08:47 · 1 min 30 s`

Uma coleção grande não cabe numa resposta só. A fonte divide em páginas de tamanho fixo, e o cliente pede uma de cada vez. O catálogo mostra 20 livros por página.

Existem dois jeitos de pedir a próxima página.

[AÇÃO] Apontar o lado esquerdo, passo 1, 2 e 3.

Offset é "pule tantos, traga tantos". Na PTAX, top diz quantos trazer e skip quantos pular. Na página 1, pulo zero e trago três: A, B e C. Aí entra um item X no começo da lista. Na página 2, pulo três e trago três, e olhem: o C aparece de novo. Se em vez de entrar um item tivesse saído, um item seria pulado.

[AÇÃO] Apontar o lado direito.

Cursor é "continue depois de C". O servidor devolve um marcador, e a página 2 começa no D, mesmo com o X inserido no começo. Nada se repete, e o cliente nem precisa saber o total.

### Slide 14 · Como as duas fontes paginam
`08:48 · 1 min`

No monitor, cada fonte pagina de um jeito.

A PTAX aceita offset, com top e skip. Mas o monitor pede uma janela de poucos dias, que cabe numa página só, então não precisa paginar.

O catálogo traz, no fim de cada página de categoria, um link "next". O coletor segue esse link até ele sumir, sem fixar quantas páginas existem.

[AÇÃO] Apontar o href page-2.html.

Um cuidado: esse link carrega o número da página. Então, por dentro, ele se comporta como offset. Se o catálogo mudasse durante a coleta, itens poderiam se deslocar. Num catálogo parado, o risco não aparece. O ganho é não depender do total de páginas.

### Slide 15 · Chave de API: no cabeçalho, nunca na URL
`08:49 · 45 s`

Chave de API é uma senha de programa. Ela identifica quem chama, para a fonte cobrar, limitar ou bloquear. As nossas duas fontes não pedem chave, mas muitas APIs comerciais pedem.

[AÇÃO] Apontar o exemplo da esquerda, depois o da direita.

Se a chave vai na URL, ela vaza: fica no log do servidor, no proxy, no histórico do terminal e no nosso manifesto. Quem lê qualquer um deles copia a chave.

O certo é mandar num cabeçalho, lendo o valor do .env, que não entra no Git. E o manifesto registra a URL sem a chave.

### Slide 16 · ETag: baixar só se a página mudou
`08:50 · 1 min 15 s`

Lembram do etag na resposta do slide 6? Ele é um carimbo da versão da página. Se o conteúdo muda, o carimbo muda.

[AÇÃO] Seguir o diagrama de cima para baixo.

Na primeira visita, o coletor faz o GET e recebe 200, o carimbo e o corpo de 51.294 bytes. Ele guarda o carimbo no manifesto e nos metadados.

Na segunda visita, ele manda o mesmo GET com o cabeçalho If-None-Match e o carimbo. Se nada mudou, o servidor responde 304 Not Modified, com zero bytes de corpo.

Se a página tivesse mudado, o carimbo seria outro e voltaria um 200 com o corpo novo. Medimos isso no dia 16 e conferimos ontem. A PTAX não tem ETag, então toda consulta a ela baixa a resposta inteira.

### Slide 17 · Falha que passa sozinha e falha que não passa
`08:51 · 1 min`

Retry é repetir a mesma requisição depois de uma falha. Só faz sentido quando a causa é temporária.

[AÇÃO] Apontar a coluna da esquerda, depois a da direita.

Transitória: o problema está no momento. Timeout, conexão recusada, 408, 429 e a família 500. A mesma pergunta, alguns segundos depois, pode dar certo.

Permanente: o problema está no pedido. 400, 401, 403, 404. E a PTAX com data no formato dia, mês, ano, que devolve 500 toda vez.

Esse último mostra o limite da regra: um erro da família 500 causado pelo cliente. Por isso, além de escolher o que repetir, o coletor precisa de um número máximo de tentativas.

### Slide 18 · Esperar antes de repetir, e cada vez mais
`08:52 · 1 min 15 s`

Imaginem um servidor sobrecarregado respondendo 503 a cem coletores. Se os cem repetirem na hora, a carga volta inteira e o servidor cai de novo. Isso é o efeito manada.

Backoff é a espera entre uma tentativa e a seguinte. No backoff exponencial, a espera dobra a cada tentativa: base vezes dois elevado a k.

[AÇÃO] Apontar a tabela.

Com base de 1 segundo: espera 1, volta em 1. Espera 2, volta em 3. Espera 4, volta em 7. Espera 8, volta em 15.

Sem limite, a décima espera seria de 512 segundos. Por isso existe o teto, por exemplo 30 segundos no cliente HTTP da Etapa 12.

Mas falta uma coisa. Se os cem usam a mesma conta, todos voltam juntos em 1, 3, 7 e 15 segundos. O backoff espaça as tentativas de cada coletor, mas não separa um coletor do outro.

### Slide 19 · Três jeitos de voltar depois de um 503
`08:53 · 1 min`

Cada ponto aqui é um coletor chegando ao servidor.

[AÇÃO] Apontar as três linhas, de cima para baixo.

Na primeira, repetir na hora: os cem voltam no mesmo instante, várias vezes seguidas. Na segunda, backoff exponencial: as chegadas ficam espaçadas, mas continuam empilhadas em 1, 3, 7 e 15 segundos.

Na terceira, backoff com jitter. Jitter é sortear a espera. Cada coletor tira um número diferente, e as chegadas deixam de coincidir. As posições dessa linha são ilustrativas; o exemplo numérico 1 mede o efeito de verdade.

### Slide 20 · A fórmula da espera, parte por parte
`08:54 · 1 min`

Vou ler a fórmula em voz alta. A espera é um número sorteado entre zero e o menor valor entre o teto e a base vezes dois elevado à tentativa.

[AÇÃO] Apontar a tabela, linha a linha.

Com base 1, teto 30 e tentativa 2: base vezes dois ao quadrado dá 4 segundos. O mínimo entre 30 e 4 é 4. E o sorteio dá qualquer valor de zero a 4, por exemplo 2,7.

Full jitter quer dizer que o sorteio cobre a faixa inteira, desde zero.

E não esqueçam o prazo de cada tentativa, o timeout de 5 e 20. Sem ele, a tentativa não termina, e o retry nunca começa.

### Slide 21 · Quando o servidor diz quanto esperar
`08:55 · 45 s`

Rate limit é a cota de requisições que o servidor aceita de cada cliente por intervalo, por exemplo 60 por minuto. Quem passa da cota recebe 429, Too Many Requests.

Junto com o 429 ou o 503, o servidor pode mandar Retry-After: 2, que quer dizer "volte daqui a 2 segundos". Esse valor substitui o sorteio, porque o servidor conhece a própria cota e o coletor não.

E o limite de tentativas: no .env da aula, HTTP_MAX_TENTATIVAS vale 4. Depois disso, o coletor desiste e grava a falha no manifesto. Assim o 500 da PTAX não vira laço infinito.

### Slide 22 · As três regras do retry no coletor
`08:56 · 45 s`

Juntando tudo, três regras, que na construção viram requisito.

Primeira: repetir só o transitório. Timeout, erro de conexão, 408, 429 e família 500. O resto vai direto para o manifesto.

Segunda: esperar com backoff exponencial e full jitter. Com Retry-After, esperar o que o servidor pediu. E parar no limite.

Terceira: repetir só operação idempotente. GET na fonte; no MinIO, mesma chave e mesmos bytes.

### Slide 23 · Uma requisição, quatro tentativas
`08:57 · 1 min 45 s`

Agora vamos ver as regras funcionando numa página só, o detalhe do Sharp Objects.

[AÇÃO] Se a animação estiver rodando, apertar Reiniciar. Depois usar Próximo evento para avançar no ritmo da fala.

Olhem a barra: ela mostra o tempo de cada tentativa e de cada espera. À esquerda, a linha que o coletor grava no manifesto a cada tentativa. À direita, o estado do coletor e a regra aplicada.

[AÇÃO] Próximo evento até o fim da tentativa 1.

Na tentativa 1, a página não responde, e o read timeout chega aos 20 segundos. O relógio acelera nesse trecho para não ficarmos parados. Aparece a primeira linha no manifesto.

[AÇÃO] Próximo evento até a tentativa 2.

Espera sorteada entre zero e 1 segundo, e a tentativa 2 recebe 503. Nova linha no manifesto, nova espera sorteada, agora entre zero e 2.

[AÇÃO] Próximo evento até a tentativa 3.

Na tentativa 3, vem 429 com Retry-After de 2. Reparem que aqui não tem sorteio: o coletor espera exatamente os 2 segundos que o servidor pediu.

[AÇÃO] Próximo evento até o fim.

A tentativa 4 recebe 200 em 0,15 segundo, a mediana que medimos. O manifesto termina com quatro linhas, e a sequência de falhas é ilustrativa, mas cada regra é a que vamos programar.

### Slide 24 · Cem coletores repetindo ao mesmo tempo
`08:59 · 1 min`

Agora a conta com cem coletores. Os cem recebem 503 no mesmo instante e repetem quatro vezes, com base de 1 segundo. Os números vêm de uma simulação em Python com semente fixa: o sorteio parte sempre do mesmo ponto, então quem rodar o script obtém os mesmos valores.

[AÇÃO] Apontar a coluna "Pico".

Pico é o maior número de chegadas ao servidor numa mesma janela de 100 milissegundos. Sem jitter, o pico é 100, quatro vezes: em 1, 3, 7 e 15 segundos. Com full jitter, as chegadas se espalham entre zero e 13,1 segundos, e o pico cai para 23.

Na espera total: sem jitter, 15 segundos para todos. Com jitter, de zero a 15, com média de 7,5.

Ou seja, o pico cai para menos de um quarto, e a espera média fica na metade do teto. Mas o jitter não substitui o limite de tentativas.

### Slide 25 · Cem coletores depois de um 503
`09:00 · 1 min 30 s`

Agora em movimento. São os mesmos cem clientes do exemplo.

[AÇÃO] Apertar Sortear de novo para começar do zero.

Em cima, sem jitter; embaixo, com full jitter. Cada ponto é um cliente esperando a próxima tentativa. Cada barra conta quantos chegaram ao servidor numa janela de 100 milissegundos. A linha tracejada é a capacidade, uma hipótese de 10 chegadas por janela, só como referência visual.

[AÇÃO] Deixar rodar e apontar a faixa de cima quando a barra subir em 1 s.

Olhem a faixa de cima: em 1 segundo, os cem chegam juntos, e a barra fura a capacidade. Vai acontecer de novo em 3, 7 e 15.

[AÇÃO] Apontar a faixa de baixo e os contadores.

Na faixa de baixo, as chegadas se espalham e as barras ficam baixas. Acompanhem nos contadores o pico em 100 milissegundos e as chegadas acima da capacidade de cada política.

[AÇÃO] Se sobrar tempo, apertar Mais rápido até o fim.

A animação sorteia de novo a cada reinício, então os números ficam perto da tabela anterior, sem ser iguais.

### Slide 26 · Repetir, esperar ou registrar e seguir?
`09:01 · 2 min 30 s`

Pausa para vocês. São quatro situações. Para cada uma, decidam a ação do coletor e o que vai para o manifesto. A parte de baixo de cada cartão explica o termo.

[AÇÃO] Ler os quatro cartões em voz alta e perguntar à turma.

Primeira: read timeout num detalhe, na terceira de cinco tentativas. Segunda: 404, um livro que saiu do catálogo entre a listagem e o detalhe. Terceira: 429 com Retry-After de 30 numa API de preços. Quarta: 502 do proxy no put_object, a gravação no MinIO, e o objeto talvez exista.

[ESPERE]

Resposta esperada: read timeout é transitório, repete com backoff e jitter, ainda restam tentativas, e cada tentativa vai para o manifesto. 404 é permanente, não repete, registra URL e status e segue para o próximo livro. 429 espera os 30 segundos do Retry-After em vez de sortear, e registra a espera. 502 no put_object repete a gravação com a mesma chave e os mesmos bytes, porque é idempotente; se o objeto já existia, fica um só, e o manifesto conta as tentativas.

### Slide 27 · Pontos-chave do bloco 1
`09:04 · 1 min`

Fechando o bloco 1.

Toda requisição tem timeout de conexão e de leitura. Sem ele, a falha fica invisível.

A família do status diz quem errou e se vale repetir: transitório se repete, permanente se registra.

O backoff exponencial espaça as tentativas de cada coletor; o jitter separa um coletor do outro; e o Retry-After vale mais que o sorteio. O limite de tentativas encerra o laço e deixa a falha no manifesto.

E repetir é seguro quando a operação é idempotente: GET na fonte, mesma chave no MinIO.

Agora a pergunta: a PTAX segue essas regras todas? No bloco 2, vamos ver onde ela foge do próprio contrato.

## Bloco 2 · PTAX e OData · 09:05

### Slide 28 · PTAX, a taxa de câmbio de referência do Banco Central
`09:05 · 1 min`

[AÇÃO] Apontar a linha do tempo dos cinco boletins, da esquerda para a direita.

Agora vamos à segunda fonte do monitor, a cotação. PTAX é a taxa de câmbio que o Banco Central publica a partir de consultas aos dealers, os bancos credenciados que negociam moeda com ele.

Ao longo do dia útil saem cinco boletins: um de abertura, três intermediários e o fechamento. Na sexta, 16/10, a abertura da libra saiu às 10h08 e o fechamento às 13h04, com venda a 6,7756.

O fechamento é a PTAX do dia, a que contratos e preços de importação usam. Guardem um detalhe: antes das 13h esse fechamento ainda não existe. A nossa coleta roda às 9h, então ela só encontra o fechamento do dia útil anterior.

### Slide 29 · GBP/BRL: compra, venda e a conta da livraria
`09:06 · 1 min`

[AÇÃO] Apontar a conta do Sharp Objects no quadro de baixo.

GBP/BRL diz quantos reais custa uma libra. Cada boletim traz dois preços: a compra, que a instituição paga quando alguém lhe vende libras, e a venda, que ela cobra de quem compra.

A livraria importa. Ela compra libras para pagar o fornecedor, então paga a venda. O Sharp Objects custa £47,82; com o fechamento de 16/10, são R$ 324,01. Pela compra, daria R$ 323,90.

Num livro a diferença é pequena. Num catálogo de mil títulos repetido todo dia, deixa de ser. Hoje o monitor só grava e extrai a cotação; a conversão para reais fica para a Aula 04.

### Slide 30 · Olinda e OData: consultar dados escrevendo a URL
`09:07 · 1 min`

Olinda é o portal de APIs de dados abertos do Banco Central. Não pede cadastro nem chave. Os serviços dele seguem o OData, um protocolo em que a própria URL descreve a consulta.

[AÇÃO] Percorrer a tabela de cima para baixo, só pela coluna "Exemplo na PTAX".

O recurso é o conjunto de dados, como uma tabela: CotacaoMoedaDia ou CotacaoMoedaPeriodo. O parâmetro com arroba é o valor que a função recebe, como a moeda GBP. As opções com cifrão ajustam a resposta: $format escolhe JSON, $select escolhe campos, $filter filtra, e $top e $skip paginam, como vimos no bloco 1.

Um exemplo: com $filter pedindo só o fechamento, a semana de 09 a 16/10 caiu para cinco registros, em 987 B. Mesmo assim o monitor não filtra na coleta. Ele grava tudo e escolhe depois.

### Slide 31 · A consulta do monitor, peça por peça
`09:08 · 1 min 30 s`

[AÇÃO] Ler a URL com a turma, uma linha da tabela por vez, apontando o trecho correspondente no comando.

Esta é a consulta exata que o coletor vai fazer. Primeiro vem a base do serviço PTAX no Olinda; o v1 é a versão do contrato.

Depois, o recurso CotacaoMoedaPeriodo, que traz as cotações de uma moeda num intervalo. Entre parênteses, a assinatura da função: cada parâmetro ganha um apelido com arroba.

Depois do ponto de interrogação vêm os valores. Moeda GBP, a libra. Início da janela em 10-17-2026, que é 17 de outubro escrito mês, dia e ano. Fim da janela em 10-24-2026, o sábado da coleta. Por último, $format=json.

Um detalhe de terminal: a barra antes do cifrão impede o shell de achar que $format é uma variável. No Python esse cuidado não existe.

### Slide 32 · Um dia ou um período, a mesma lista value
`09:09 · 1 min`

[AÇÃO] Apontar a lista value no JSON e, depois, o campo tipoBoletim.

Os dois recursos respondem com o mesmo formato: um objeto JSON com uma lista chamada value, um item por boletim. Sem boletim, a lista vem vazia, e o status continua 200.

Agora olhem o tipoBoletim. No recurso de um dia, o fechamento se chama "Fechamento PTAX". No recurso de período, o mesmo boletim se chama só "Fechamento".

A consequência é prática: um filtro escrito para um recurso não acha nada no outro. Por isso o teste do extrator usa a resposta do recurso que o coletor realmente chama.

### Slide 33 · Três formatos de data, três respostas diferentes
`09:10 · 1 min 30 s`

A PTAX espera a data em MM-DD-AAAA, o padrão americano. O problema é que os dois formatos que a gente usa no dia a dia também "funcionam", cada um de um jeito.

[AÇÃO] Apontar as três linhas da tabela, nesta ordem.

Com '10-15-2026', vêm os cinco boletins de 15/10. Com a data em ISO, '2026-10-15', vem 200 com lista vazia, a mesma resposta de um feriado. Com '15-10-2026', vem um 500 em 0,23 s.

O segundo caso é um erro silencioso: não há exceção nem status de erro. O coletor grava uma lista vazia e ninguém percebe até faltar cotação na Aula 04. A defesa é validar o formato antes de chamar e tratar lista vazia em dia útil como alerta.

O terceiro é um erro nosso que chega com código de erro do servidor. Repetir não resolve, e por isso o retry precisa de limite. E o corpo desse 500 vem entre /* e */, que JSON não aceita: o json.loads falha. Guardar a resposta bruta mantém a prova.

### Slide 34 · O que a documentação da PTAX omite
`09:12 · 1 min`

O contrato de uma API é o que ela promete na documentação. O comportamento real só aparece quando a gente chama com datas sem cotação e formatos errados, e anota o que volta.

[AÇÃO] Apontar a coluna "Consequência para o coletor".

A tabela resume o que observamos em 03/10 e 16/10. Sábado e data em ISO dão 200 com lista vazia. Data em DD-MM-AAAA dá 500. E o nome do fechamento muda entre os recursos.

Nenhuma dessas situações aparece como erro de rede. É por isso que guardamos a resposta inteira antes de interpretar: dá para corrigir o filtro e reprocessar sem chamar a API de novo. E a PTAX não manda ETag, então não há como perguntar se a resposta mudou.

### Slide 35 · Dia útil, feriado e a janela de dias
`09:13 · 1 min 30 s`

[AÇÃO] Percorrer o calendário da esquerda para a direita e parar em 16/10.

Só existe boletim em dia útil: de segunda a sexta, fora dos feriados nacionais. Vejam a semana de 09 a 16/10. Sexta tem fechamento. Sábado e domingo, nada. Segunda, 12/10, é feriado de Nossa Senhora Aparecida, também nada. De terça a sexta, cinco boletins por dia.

A janela de dias é consultar um intervalo que termina na data da coleta. O último fechamento até aquela data fica sempre dentro dela. Uma única requisição de 09 a 16/10 trouxe 25 registros de 5 dias úteis, e o último fechamento, 6,7756, está ali.

Se eu consultasse só o dia 12, receberia 200 com lista vazia. Igual à resposta de uma data em formato errado.

### Slide 36 · A janela que atravessa o feriado
`09:14 · 1 min`

Aqui estão as três consultas que fiz em 16/10, com o tamanho e o tempo de cada resposta.

[AÇÃO] Apontar a terceira linha da tabela.

O sábado devolveu zero registros em 124 B. A quinta, cinco registros em 998 B. A janela de 09 a 16/10 trouxe 25 registros em 4.475 B, em 0,44 s.

Oito dias renderam cinco dias úteis. Uma requisição de 4,4 KB garante o último fechamento, então alargar a janela quase não custa. No sábado, dia 24, só a janela encontra o fechamento de sexta.

### Slide 37 · Do JSON da PTAX ao cotacoes.jsonl
`09:15 · 1 min`

JSON Lines é um arquivo de texto com um objeto JSON completo por linha. A extração pega cada item da lista value e escreve uma linha com cinco campos, combinados com a Aula 04.

[AÇÃO] Apontar as duas linhas de exemplo e, na tabela, o campo dataHoraCotacao.

A moeda vem do parâmetro da consulta, porque a resposta não a traz. dataHoraCotacao, tipoBoletim, compra e venda vêm da resposta.

O campo que mais importa para a próxima aula é o dataHoraCotacao. É ele que mostra que a cotação usada num sábado é a de sexta. E o tipoBoletim permite escolher o fechamento entre os cinco boletins do dia.

### Slide 38 · Qual cotação vale na segunda, 02/11?
`09:16 · 2 min 30 s`

Pausa para pensar. Em 2026, Finados cai numa segunda-feira, então 02/11 não é dia útil. A coleta roda às 9h, antes do primeiro boletim de qualquer dia.

[AÇÃO] Ler a primeira pergunta e esperar.

Quantos dias a janela precisa cobrir para achar um fechamento?

[ESPERE]

Resposta esperada: precisa voltar até sexta, 30/10, ou seja, cobrir pelo menos quatro dias (30/10, 31/10, 01/11 e 02/11); a janela de sete dias do .env cobre com folga.

[AÇÃO] Ler a segunda pergunta e esperar.

Que campo do cotacoes.jsonl mostra à Aula 04 que a cotação é de sexta, 30/10?

[ESPERE]

Resposta esperada: dataHoraCotacao.

[AÇÃO] Ler a terceira pergunta e esperar.

Que critério de aceite separa lista vazia em feriado de lista vazia por data em ISO?

[ESPERE]

Resposta esperada: um critério que valida o formato MM-DD-AAAA antes da chamada e outro que trata janela sem nenhum Fechamento como falha registrada no manifesto.

### Slide 39 · Pontos-chave do bloco 2
`09:19 · 1 min`

Fechando o bloco. A PTAX de um dia é o fechamento, publicado depois das 13h, e a livraria usa a cotação de venda.

O contrato é o que a API declara. A realidade a gente descobre chamando com datas e formatos errados. Um 200 com lista vazia pode ser fim de semana, feriado ou erro de formato, e o status não distingue.

A janela de dias custa uma requisição e garante o último fechamento, com a data efetiva no registro. E o nome do boletim muda entre recursos, então filtro com texto fixo precisa de teste.

[AÇÃO] Avançar.

A PTAX pelo menos tem contrato. O catálogo de livros não tem API nenhuma, e é dele que trata o bloco 3.

## Bloco 3 · Web scraping e coleta educada · 09:20

### Slide 40 · Ler com um programa uma página feita para pessoas
`09:20 · 1 min`

[AÇÃO] Percorrer o fluxo de cinco passos da esquerda para a direita.

Web scraping é baixar uma página web e extrair dela, por programa, os dados que uma pessoa leria na tela. O catálogo não tem um endereço que devolva os preços em JSON. O único caminho é baixar o HTML e procurar os valores dentro dele.

O fluxo tem cinco passos. Um GET da página, com o mesmo requests do bloco 1. Chegam os bytes do HTML, uns 50 KB. Um parser monta a árvore. Um seletor aponta o elemento. E sai o valor, £47.82.

O books.toscrape.com é um site de treino, feito para ser raspado, e avisa que preços e avaliações são inventados. Num site real, as verificações do fim deste bloco vêm antes do primeiro script.

### Slide 41 · O que se perde quando a fonte não tem API
`09:21 · 1 min`

[AÇÃO] Apontar a coluna "Consequência para o coletor".

A PTAX promete campos fixos e tem versão no endereço. A página não promete nada: o layout pode mudar amanhã, e o coletor só descobre quando a extração falhar.

Os seletores saem da inspeção da página. Precisamos de um parser de HTML. A paginação segue o link next até ele sumir. E a mudança chega sem aviso: o seletor quebra em silêncio, e quem acusa é o teste de contagem.

Outra diferença está no volume. A PTAX pede uma requisição por dia; o catálogo, cerca de 1.081. A cadência deixa de ser detalhe e vira assunto de ética e de tempo.

### Slide 42 · Tags, atributos e classes num cartão de livro
`09:22 · 1 min`

HTML é o texto que o navegador recebe e desenha. Ele é feito de elementos marcados por tags.

[AÇÃO] Apontar no código, nesta ordem: a tag article, o atributo href, a classe "star-rating Four".

A tag é o nome entre os sinais de menor e maior: article, p, h3, a. Ela abre e fecha, e o que fica entre as duas é o conteúdo. O atributo é um par nome e valor dentro da tag: o href guarda o endereço do link, e o title, o título completo do livro.

A classe é o valor do atributo class. Um elemento pode ter várias, separadas por espaço. Em "star-rating Four" são duas classes, e a segunda é a nota. Para ver isso no navegador: botão direito sobre o livro, Inspecionar.

### Slide 43 · O mesmo cartão como árvore de elementos
`09:23 · 1 min`

[AÇÃO] Descer pela árvore com o dedo, da raiz article.product_pod até a folha p.price_color.

Elementos dentro de elementos formam uma árvore, o DOM. O de fora é o pai, os de dentro são os filhos. A raiz aqui é o cartão, article.product_pod, que se repete 20 vezes por página.

O coletor desce até a folha que guarda o valor. O preço está em p.price_color, o estoque em p.instock.availability. O título está no atributo title do link dentro do h3.

Reparem na nota: ela não está no texto, está na classe do parágrafo star-rating. As folhas em cinza-claro são as que o coletor lê.

### Slide 44 · Como ler um seletor CSS
`09:24 · 1 min 30 s`

Seletor CSS é uma expressão que aponta elementos da árvore. Nasceu para o navegador aplicar estilo, e o coletor usa a mesma linguagem para achar o dado.

[AÇÃO] Ler a coluna "Como se lê" em voz alta, uma linha por vez.

Uma palavra solta é a tag: article pega todo article. O ponto indica classe: .product_pod. Tag e classes juntas, p.instock.availability, pedem um p com as duas classes. O sinal de maior, em h3 > a, pede o link logo abaixo do h3, sem nada no meio. O espaço, em div.product_main p.availability, aceita qualquer nível de profundidade. E os colchetes, em a[title], pedem a tag que tem aquele atributo.

[AÇÃO] Se houver tempo, abrir o Inspecionar no navegador e rodar no console a linha do rodapé.

No console do navegador, querySelectorAll("article.product_pod") devolve 20.

### Slide 45 · Seletores do books.toscrape.com, lidos em português
`09:25 · 1 min`

Estes são os seletores do monitor, conferidos em 03/10 e de novo em 23/10.

[AÇÃO] Apontar as linhas do título e da avaliação.

Dois cuidados. O título vem do atributo title, porque o texto visível vem cortado. E a avaliação está na segunda classe de p.star-rating, de One a Five.

A regra geral está no rodapé: classe com significado, como price_color, quebra menos que posição, como "terceiro div". Basta um banner novo para a posição mudar.

### Slide 46 · BeautifulSoup transforma bytes em árvore
`09:26 · 1 min 30 s`

Parser é o programa que lê um texto com regras de formato e devolve uma estrutura navegável. O BeautifulSoup recebe a página, monta a árvore DOM e aceita seletores CSS.

[AÇÃO] Percorrer o código linha a linha e depois os quatro quadros da direita.

O select devolve a lista de todos que casam com o seletor, aqui os 20 cartões. O select_one devolve o primeiro, ou None. Um None inesperado é o sinal de que o site mudou. Com colchetes eu leio um atributo, como o title, e com get_text leio o texto entre as tags.

Reparem que o código entrega r.content ao parser, e não r.text. O motivo vem daqui a dois slides.

### Slide 47 · Listagem, página de detalhe e links relativos
`09:28 · 1 min`

A listagem mostra 20 livros por página, com título, preço e nota. Mas o UPC, o código único do produto, e a quantidade em estoque só aparecem na página de detalhe. Por isso o coletor visita as duas.

[AÇÃO] Apontar os dois exemplos de urljoin no código.

O site usa links relativos: só o caminho a partir da página atual, e ../ sobe uma pasta. O urljoin faz a conta que o navegador faria e devolve o endereço completo antes do GET.

A paginação segue o mesmo raciocínio. A categoria Mystery tem 32 livros em duas páginas. A primeira traz o link next para page-2.html; a última não traz. O coletor segue o link até ele sumir.

### Slide 48 · Bytes, charset e o símbolo da libra
`09:29 · 1 min`

[AÇÃO] Apontar os bytes C2 A3 no centro e depois os dois lados do diagrama.

A rede só transporta bytes, números de 0 a 255. Charset é a tabela que diz qual caractere cada byte representa.

No UTF-8, a libra ocupa dois bytes, C2 e A3. No ISO-8859-1, cada byte é sempre um caractere. Os mesmos dois bytes, lidos pela tabela errada, viram "Â£". O servidor mandou a mesma coisa nos dois casos; o que mudou foi a leitura.

### Slide 49 · Por que o preço vira Â£47.82 no requests
`09:30 · 1 min 30 s`

O cabeçalho Content-Type deveria dizer o tipo e o charset. Este servidor manda só text/html. Sem charset no cabeçalho, o requests adota ISO-8859-1 para montar o r.text, e a libra estraga.

[AÇÃO] Apontar a tag meta no código e depois as duas linhas do BeautifulSoup.

O charset certo está dentro do próprio HTML, numa tag meta. Se eu entrego r.text, o texto já chega estragado. Se entrego r.content, os bytes como chegaram da rede, o BeautifulSoup lê a meta e decodifica em UTF-8.

Daí a regra do monitor: o parser recebe bytes, e o MinIO recebe os bytes originais, sem decodificar e recodificar.

### Slide 50 · robots.txt: o que o dono do site pede aos robôs
`09:31 · 1 min`

Página pública não autoriza qualquer coleta. São quatro verificações antes do primeiro script, e a primeira é um arquivo.

O robots.txt é um texto em que o dono do site diz quais caminhos os robôs não devem visitar. O formato é da RFC 9309, e o arquivo fica sempre na raiz do domínio.

[AÇÃO] Apontar o exemplo ilustrativo no rodapé.

Ele não bloqueia o acesso nem tem força de autorização jurídica. Registra a vontade do dono, e ignorá-la é má prática. Neste site ele devolve 404, sem restrição declarada. Mesmo assim o coletor consulta a cada execução e registra no manifesto, porque a ausência de hoje não garante a de amanhã.

### Slide 51 · Termos de uso, LGPD, User-Agent e cadência
`09:32 · 1 min 30 s`

[AÇÃO] Passar pelos quatro cartões, da esquerda para a direita.

Termos de uso são o contrato que a gente aceita ao usar o site. Sites comerciais costumam proibir coleta automatizada, e essa proibição vale mesmo sem robots.txt.

A LGPD, Lei 13.709 de 2018, protege informação ligada a uma pessoa identificável. Dado pessoal publicado continua pessoal. O catálogo não tem; avaliações com o nome do autor teriam.

User-Agent é o cabeçalho em que o cliente diz quem é. O monitor manda o nome do projeto e um contato, para o dono poder avisar antes de bloquear.

Cadência é o intervalo entre requisições, aqui 1 s, que é hipótese. Dez threads fazem dez pedidos ao mesmo tempo, e isso parece ataque. O servidor responde 429, 403 ou recusa o IP. Isso é o bloqueio.

### Slide 52 · Quanto dura uma coleta educada, medida
`09:34 · 1 min`

Esta é a coleta completa que rodei em 16/10: uma requisição por vez e 1 s de pausa depois de cada resposta.

[AÇÃO] Apontar a linha da duração e depois o quadro "O que a conta mostra".

Foram 1.081 páginas: a inicial, 80 de categoria e 1.000 de detalhe. A latência mediana foi 0,15 s, ou seja, metade das páginas respondeu em até esse tempo. O p95 foi 0,33 s: 95% responderam em até isso. A mais lenta levou 9,9 s.

A coleta durou 21 min 57 s, e 18 min foram pausa: 82% do tempo. Paralelizar cortaria pouco da parte de rede e multiplicaria a carga na fonte.

### Slide 53 · A coleta educada em tempo acelerado
`09:35 · 2 min`

[AÇÃO] Com "Sequencial, 1 s" selecionado, deixar a animação rodar.

Aqui estão as mesmas 1.081 páginas em tempo acelerado: cada segundo na tela vale 52 s simulados. Cada quadrado escurece quando a página termina de baixar. Olhem a barra de carga na fonte: fica abaixo de uma requisição por segundo.

[AÇÃO] Apontar o contador "Desse tempo, em pausa" enquanto ele sobe.

Notem quanto do tempo simulado é pausa. É a mesma proporção do slide anterior.

[AÇÃO] Clicar em "10 threads, sem pausa".

Agora, dez conexões ao mesmo tempo e sem pausa. A coleta termina em segundos, mas a barra mostra dezenas de requisições por segundo no servidor. Isso está fora da cadência combinada, e é exatamente o padrão que leva ao bloqueio.

[AÇÃO] Clicar em "Sequencial, 1 s" e "Reiniciar" para deixar o slide pronto para a pausa.

### Slide 54 · A gerente quer a coleta em cinco minutos
`09:37 · 2 min`

Com os números do exemplo 3, a gerente pede a coleta em cinco minutos. São quatro propostas na mesa.

[AÇÃO] Ler as três perguntas, uma por vez, e esperar cada resposta.

Qual delas o site percebe como ataque?

[ESPERE]

Resposta esperada: as dez threads contra o mesmo domínio e o intervalo de 0,1 s.

Qual depende de algo que o servidor oferece?

[ESPERE]

Resposta esperada: o If-None-Match, que só funciona porque o servidor manda ETag e responde 304 quando a página não mudou.

Qual perde o UPC que a Aula 05 usa como identificador do livro?

[ESPERE]

Resposta esperada: pular a página de detalhe, porque o UPC só aparece nela.

Resposta esperada para a pergunta da gerente: com 1 s de pausa e 1.081 páginas, só a pausa passa de 18 min. Cinco minutos não cabem na cadência combinada; o If-None-Match reduz bytes, e não o número de pedidos.

### Slide 55 · Pontos-chave do bloco 3
`09:39 · 1 min`

Fechando o bloco. Sem API, a página é o contrato. O parser monta a árvore, e seletores presos a classes com significado, como article.product_pod, quebram menos que posições.

A paginação segue o link next até ele sumir, e os links relativos passam pelo urljoin. O número de páginas nunca fica fixo no código. O parser recebe bytes e lê o charset da meta, e o MinIO recebe os bytes originais.

robots.txt, termos de uso, LGPD e cadência vêm antes do primeiro script. A cadência custa minutos e evita o bloqueio.

[AÇÃO] Avançar.

Fica uma pergunta para o próximo bloco: se o seletor errar durante uma semana, o que sobra? O bloco 4 responde.

## Bloco 4 · Bruto, camadas e escolha da fonte · 09:40

### Slide 56 · O bruto e o extraído de uma mesma página
`09:40 · 1 min`

[AÇÃO] Apontar primeiro a caixa da esquerda (bruto) e depois a da direita (extraído).

Agora entramos no bloco 4. Até aqui falamos de como buscar o dado. A pergunta deste bloco é outra: o que eu guardo do que chegou.

À esquerda está o bruto: a página de detalhe do Sharp Objects, 14.847 bytes, exatamente como o site mandou. À direita está o extraído: upc, título, preço, estoque, avaliação e categoria, já como campos.

Reparem nas setas pequenas. O texto "£47.82" virou o número 47.82. A classe "Four" virou a avaliação 4. Cada uma dessas linhas é uma decisão do extrator, e toda decisão pode errar. O bruto guarda tudo, inclusive o que hoje ninguém usa. O extraído só tem o que o seletor conhecia.

### Slide 57 · Raw, bronze e as camadas que vêm depois
`09:41 · 1 min`

[AÇÃO] Percorrer o diagrama da esquerda para a direita: fonte, raw, extrator, bronze, silver e gold.

Camada é um estágio do dado no lake, guardado num bucket ou prefixo próprio. O monitor de hoje grava as duas primeiras.

No raw ficam o HTML e o JSON como chegaram, com os metadados de procedência. O raw é imutável: ninguém edita, só regrava igual. O extrator lê o raw e grava o bronze, um registro por livro ou por boletim. O bronze pode ser apagado e refeito a partir do raw. Silver e gold, com Parquet, tipos e preço em reais, ficam para a Aula 04.

Embaixo está a retomada da Aula 02. No schema on write, o formato é imposto na gravação, e o que não cabe se perde. No schema on read, que é o nosso raw, guardo o original e decido o formato na leitura.

### Slide 58 · JSON Lines: um registro por linha
`09:42 · 1 min`

[AÇÃO] Apontar a linha do Sharp Objects no bloco de código.

O bronze usa JSON Lines, extensão ".jsonl". Cada linha do arquivo é um objeto JSON completo. Não tem colchete em volta nem vírgula entre os registros.

Esta é uma linha do livros.jsonl. São os nove campos do contrato e 274 bytes, contando a quebra de linha. O horário de coletado_em é ilustrativo.

Três vantagens práticas. Com "wc -l" eu conto registros: mil linhas no dia são mil livros. O leitor processa linha a linha, sem carregar o arquivo inteiro. E uma linha corrompida estraga um registro, enquanto num JSON único ela quebraria o arquivo todo.

### Slide 59 · Três situações em que o bruto salva o dado
`09:43 · 1 min`

[AÇÃO] Ler os três cartões em ordem e terminar na caixa "Falhar de forma visível".

Reprocessar é rodar a extração de novo sobre bytes que já estão guardados, sem chamar a fonte. Isso só existe se eu guardei o bruto. E a página de ontem não volta: o site mostra só o preço de hoje.

Três casos. Primeiro, o preço saiu vazio durante uma semana: corrijo o seletor e reprocesso a semana a partir do raw. Segundo, alguém quer a avaliação em estrelas, que eu ignorava: extraio o campo novo para todo o histórico. Terceiro, o site mudou e o seletor quebrou: comparo o HTML antigo com o novo e acho a tag que mudou. Sem bruto, nos três casos, eu perco dado ou fico adivinhando.

E uma regra junto: se a listagem declara 20 livros e o extrator acha zero, a extração para com erro. Ela não grava um JSON Lines vazio como se fosse resultado válido.

### Slide 60 · Quanto custa guardar o bruto
`09:44 · 1 min`

[AÇÃO] Apontar a linha "1 ano" da tabela e depois a caixa "O que a conta mostra".

Guardar tudo custa quanto? Estes números são da coleta de 16/10/2026. À esquerda, as unidades: KiB são 1.024 bytes, MiB são 1.024 KiB, GiB são 1.024 MiB.

Uma coleta gera 1.083 objetos e 21,5 MiB de bruto. Em um ano, 7,7 GiB. O livros.jsonl do ano inteiro fica em 95 MiB.

O bruto ocupa cerca de 80 vezes o JSON Lines e ainda cabe em 7,7 GiB por ano. Os mil detalhes são 86% dos bytes. Para um monitor diário, é um custo pequeno pelo que ele compra.

### Slide 61 · Os caminhos até o dado e o que os bloqueia
`09:45 · 1 min`

[AÇÃO] Apontar a coluna "Caminhos" e depois a coluna "Bloqueios".

Antes de escrever qualquer coletor, decido por onde o dado entra. À esquerda, os caminhos. API, como a PTAX, feita para programas e com contrato. Exportação oficial, um arquivo que o dono do dado publica. Dados abertos, os portais públicos dessas exportações. E scraping, que é o nosso catálogo.

À direita, o que bloqueia. Login, paywall e CAPTCHA são bloqueios técnicos. Termos de uso são contrato: podem proibir a coleta mesmo sem bloqueio técnico. E base legal é o motivo previsto na LGPD que autoriza tratar dado pessoal, como consentimento ou obrigação legal.

### Slide 62 · API, scraping ou nenhum dos dois
`09:46 · 1 min`

[AÇÃO] Apontar as três últimas linhas da tabela, as que terminam em "nenhum".

A ordem da tabela segue a estabilidade do contrato. Quanto mais documentado o caminho, menos o coletor quebra. Por isso scraping fica por último: o HTML muda sem aviso.

Quero chamar atenção para as linhas de baixo. Às vezes a resposta é nenhum dos dois. Se os termos proíbem, se tem login ou CAPTCHA, o caminho é negociar, comprar o dado ou mudar a pergunta. Se é dado pessoal sem base legal, o risco jurídico supera o valor do dado. E se o dado já está no banco de quem pergunta, eu leio a fonte interna.

No monitor, a cotação tem API oficial e o catálogo não tem. As duas escolhas da aula seguem esta tabela.

### Slide 63 · Quatro fontes para uma rede de postos
`09:47 · 2 min`

[AÇÃO] Ler o cenário, perguntar à turma e esperar. Passar pelos quatro cartões em ordem.

Pausa para pensar. Uma rede de postos quer comparar seus preços com o mercado. A ANP é a agência que regula combustíveis e pesquisa preços nos postos. Para cada uma destas quatro fontes, qual caminho vocês escolhem, e por quê?

[ESPERE]

Resposta esperada: preços da ANP por download do CSV nos dados abertos; dólar do dia pela API da PTAX, a mesma da aula; aplicativo de preços, nenhum, porque exige login e os termos proíbem coleta; avaliações dos postos, nenhum sem base legal, porque nome e foto do autor são dado pessoal.

### Slide 64 · Pontos-chave do bloco 4
`09:49 · 1 min`

[AÇÃO] Ler os quatro pontos e terminar na nota de passagem.

Resumindo o bloco 4. O coletor guarda o que a fonte entregou no raw, e o extrator interpreta e grava o bronze. Guardar só o interpretado transforma erro de seletor em perda de dado.

O bruto custa poucos GiB por ano e compra reprocessamento, campos novos e diagnóstico de mudança. Extração que acha zero onde a página declara 20 falha com erro. E, na escolha da fonte, scraping vem depois da API e da exportação oficial.

Agora o bloco 5 junta tudo numa arquitetura e decide onde e com que nome cada objeto é gravado.

## Bloco 5 · Arquitetura, manifesto e chaves · 09:50

### Slide 65 · Coletor e extrator em etapas separadas
`09:50 · 1 min`

[AÇÃO] Seguir os números de 1 a 5 no diagrama e apontar a linha da fronteira da rede.

Este é o desenho do monitor. Dois programas. O coletor é o único que fala com a rede: baixa e grava no raw, sem interpretar. O extrator é outro programa, que lê o raw e grava o bronze, e nunca chama o site.

Sigam os números. Um: o coletor descobre o robots.txt e a lista de categorias. Dois: baixa as páginas de categoria e os detalhes, com 1 segundo de pausa. Três: busca a PTAX numa janela de dias. Quatro: escreve o manifesto, o diário da execução, que também vai para o raw. Cinco: o extrator, sem rede, gera o .jsonl.

A linha que importa é a fronteira da rede. Só o coletor a atravessa.

### Slide 66 · Por que separar coleta e extração
`09:51 · 1 min`

[AÇÃO] Passar pelos quatro cartões e terminar na caixa sobre ADR.

A alternativa seria extrair na mesma execução, com os bytes que acabaram de chegar. Separar custa ler de volta cerca de 21,5 MiB por dia do MinIO. Em troca, ganho quatro coisas.

Reprocesso qualquer data sem chamar a fonte. Isolo as falhas: a coleta falha por rede, a extração falha por mudança no HTML, e cada uma é reexecutada sozinha. Provo que o raw contém tudo o que preciso. E testo o extrator com páginas gravadas em arquivo, sem depender do site no ar.

Essa decisão fica registrada num ADR, um arquivo curto com contexto, opção escolhida, alternativas e custo. Ela vira o ADR-001 na Etapa 09 da construção.

### Slide 67 · O manifesto: o diário de uma execução
`09:52 · 1 min`

[AÇÃO] Apontar os campos do item no bloco JSON: status_http, tentativas e sha256.

O manifesto é um arquivo JSON que o coletor escreve a cada execução. Tem um cabeçalho sobre a execução e um item por URL pedida. Ele responde o que foi baixado, com que resultado e quantas tentativas custou, sem eu abrir nenhuma página.

No cabeçalho estão o id da execução, início e fim, a data de referência, o resultado do robots.txt e o total de livros que o site declara. Em cada item, como este do Sharp Objects: URL, chave gravada, status 200, duas tentativas, 14.847 bytes, o SHA-256 e o erro, que aqui é nulo. As duas tentativas são ilustrativas.

Cada execução grava o seu manifesto, sem sobrescrever o anterior.

### Slide 68 · Anatomia de uma chave no MinIO
`09:53 · 1 min`

[AÇÃO] Ler a chave do diagrama trecho por trecho, da esquerda para a direita.

Lembrando a Aula 02: no MinIO não há pastas. A chave é o nome completo do objeto, e as barras só separam trechos. Cada trecho inicial forma um prefixo que eu consigo listar.

Lendo esta chave: raw é a camada, books_toscrape é a fonte, data=2026-10-24 é a partição, livro=sharp-objects_997 é o item e detalhe.html é o arquivo.

A partição no formato nome=valor agrupa os objetos de um dia. Listo o prefixo do dia e vem só aquele dia, sem varrer o ano. Na Aula 04, o DuckDB lê esse nome=valor como coluna. E a data é a da coleta no fuso de São Paulo. Em UTC, uma execução depois das 21h de Brasília cairia no dia seguinte.

### Slide 69 · Chave determinística contra chave com horário
`09:54 · 1 min`

[AÇÃO] Comparar os dois cartões do topo e depois apontar a linha do manifesto na lista de chaves.

Chave determinística é a calculada só a partir da fonte, da data e da página. A mesma página no mesmo dia gera sempre a mesma chave. Se eu gravo de novo, sobrescrevo o objeto em vez de criar outro.

Com horário no nome, cada tentativa ganha um nome novo, e o bucket acumula cópias da mesma página.

Na lista de chaves do monitor, todas são determinísticas, com uma exceção deliberada: o manifesto, que tem uma por execução. O custo da decisão é perder a versão intermediária de uma página que mudou entre duas execuções do mesmo dia. Para um monitor diário, esse é o grão que eu quero.

### Slide 70 · Metadados: a etiqueta de cada objeto
`09:55 · 1 min`

[AÇÃO] Apontar o bloco de metadados e depois os três termos à direita.

Metadados são pares de nome e valor gravados junto com o objeto, fora dos bytes. Os que eu defino recebem o prefixo x-amz-meta-, que vem da API S3 da Amazon, que o MinIO imita. Com eles eu sei de onde o objeto veio sem abri-lo.

No detalhe do Sharp Objects: o ContentType, a URL de origem, o horário da coleta, o status, o SHA-256 e a execução. Horário e execução aqui são ilustrativos.

Três termos. ContentType diz que tipo de bytes o objeto guarda e em qual codificação. UTC é o horário universal: 09h30 em Brasília são 12h30 UTC. E ASCII são os 128 caracteres básicos, sem acento nem libra. Metadado só aceita ASCII: se eu escrever "preço" com cedilha, o boto3 recusa com ParamValidationError.

### Slide 71 · SHA-256: a impressão digital dos bytes
`09:56 · 1 min`

[AÇÃO] Apontar os dois hashes de 47.82 e 47.83.

Hash é uma função que transforma qualquer sequência de bytes num código de tamanho fixo. O SHA-256 gera 64 caracteres. Os mesmos bytes dão sempre o mesmo código, e não dá para voltar do código para os bytes.

Olhem aqui. 47.82 e 47.83 diferem num único caractere, e os dois códigos não têm nada em comum. A página inteira do Sharp Objects, com 14.847 bytes, também tem o seu.

Uso o hash para três coisas. Integridade: comparo o hash do que baixei com o do objeto no MinIO. Mudança: se o hash é igual ao de ontem, a página não mudou. E rastro: o manifesto e os metadados guardam o mesmo hash e ligam o registro ao objeto.

### Slide 72 · Por que o 502 pode chegar depois de gravar
`09:57 · 1 min`

[AÇÃO] Seguir as setas do diagrama de cima para baixo e parar na mensagem "200, mas a conexão cai".

Proxy é um servidor intermediário: recebe a requisição, repassa ao serviço de verdade e devolve a resposta. O Railway põe um proxy na frente do MinIO.

Sigam o diagrama. O coletor manda o PUT. O proxy repassa. O MinIO grava o objeto e responde 200. Só que a conexão cai na volta, e o coletor recebe 502 Bad Gateway. O objeto já existe, mas o coletor não sabe disso, então repete.

Com chave determinística, a repetição cai na mesma chave com os mesmos bytes, e o objeto é sobrescrito igual. Não cria cópia. O manifesto conta as tentativas, e se elas crescem, é sinal de que o proxy piorou.

### Slide 73 · Gravar e conferir o bucket
`09:58 · 1 min`

[AÇÃO] Apontar as linhas de put_object, head_object e mc stat.

O código grava com o boto3, a biblioteca Python oficial da AWS para a API S3. Como o MinIO fala a mesma API, basta trocar o endereço. Para conferir, uso o mc, o cliente de linha de comando do MinIO.

Os que mais vamos usar: put_object grava bytes numa chave com metadados. head_object lê só os metadados, sem baixar os bytes. get_object baixa os bytes, e é o que o extrator usa. No terminal, mc ls lista as chaves de um prefixo e mc cat imprime um objeto.

Um aviso da preparação desta aula: na imagem que usamos, o mc stat não mostrou os metadados de usuário. Por isso a conferência dos metadados é feita com head_object em Python.

### Slide 74 · Duas execuções por dia durante um mês
`09:59 · 1 min`

[AÇÃO] Apontar a linha "30 dias" e a linha "livros.jsonl do dia".

Este exemplo é hipótese, não medição. Mil e oitenta e três objetos por execução, duas execuções por dia, 30 dias, e 1% dos PUT com 502 depois de gravar, ou seja, 11 repetições por execução.

Com chave determinística, ao fim de 30 dias tenho 32.490 objetos e 60 manifestos. Com horário na chave, 65.640 objetos: o volume dobra.

E a linha de baixo é a que dói. Com chave determinística, o livros.jsonl do dia tem 1.000 linhas e bate com o site. Com horário, chega a 2.020 linhas se o extrator ler o prefixo inteiro, e a Aula 04 teria de remover repetições sem saber qual versão vale.

### Slide 75 · Retry no 502: chave fixa contra chave com horário
`10:00 · 2 min`

[AÇÃO] A animação começa sozinha ao entrar no slide. Deixar correr a execução 1, usar "Acelerar" para chegar à execução 2 e, no fim, "Reiniciar" se quiserem ver de novo.

Cada quadrado é um objeto no bucket. À esquerda, chave determinística. À direita, chave com horário.

Olhem primeiro os quadrados marcados como repetição depois do 502. À esquerda, a repetição cai sobre o mesmo quadrado. À direita, aparece um quadrado novo a cada repetição.

[AÇÃO] Clicar em "Acelerar" e apontar o rótulo "Execução 2 de 2".

Agora a segunda execução do mesmo dia. À esquerda, nada cresce: as mesmas chaves são regravadas. À direita, o bucket ganha um conjunto inteiro de novo.

[AÇÃO] Apontar a tabela de contadores.

Nos contadores, a linha "Objetos a mais que o necessário" fica em zero à esquerda e cresce à direita. As posições dos 502 são sorteadas a cada reinício, mas a conclusão é sempre a mesma do exemplo 5.

### Slide 76 · O livros.jsonl saiu com 980 linhas
`10:02 · 2 min`

[AÇÃO] Ler o cenário, perguntar à turma e esperar antes de mostrar a ordem dos cartões.

Último exercício da teoria. O site declara mil livros e o bronze saiu com 980 linhas. Faltam 20. Em que ordem vocês investigam, e qual artefato responde cada pergunta?

[ESPERE]

Resposta esperada: primeiro o manifesto, para ver se a coleta baixou os mil detalhes, procurando itens com erro ou status diferente de 200; depois o bucket, com mc ls --recursive no prefixo da data, contando os detalhe.html; por fim, reprocessar a partir do raw, sem chamar o site, para ver onde a contagem cai no extrator.

Cada pergunta elimina uma camada: rede, armazenamento ou interpretação. É para isso que serviram o manifesto, a chave determinística e a separação entre coletor e extrator.

### Slide 77 · Pontos-chave do bloco 5
`10:04 · 1 min`

[AÇÃO] Ler os quatro pontos e terminar na nota de passagem para a construção.

Fechando a teoria. Coleta e extração separadas: a extração lê do MinIO, roda sozinha e é testada sem rede. Chave derivada de fonte, data e página: reexecução e retry não duplicam, e o manifesto é a exceção deliberada.

Metadados em ASCII guardam origem, horário UTC, status e SHA-256, e eu confiro com head_object. E a contagem do bronze contra o total que o site declara é o teste que denuncia cópia ou perda.

A partir de agora a gente constrói. Cada uma dessas decisões vai virar regra, requisito, ADR, tarefa, teste e cenário ATAM no repositório de vocês.

## Construção em etapas · 10:05

### Slide 78 · Do problema ao código em 19 etapas
`10:05 · 1 min`

[AÇÃO] Deixe o Codespace do repositório de demonstração aberto numa segunda aba, com o terminal visível.

Agora a gente para de falar sobre o monitor e passa a construí-lo. São 19 etapas, numeradas de 00 a 18, e cada slide daqui em diante é uma delas.

O método vem de um repositório público meu, o cinesenac, que levou um sistema de reservas de cinema da persona até o merge na main. Aqui eu aplico o mesmo caminho a um sistema de dados. A diferença é que o usuário principal é um pipeline, e a modelagem fala de chaves, contratos de arquivo e manifesto.

Em sala vamos até a Etapa 15. As Etapas 16, 17 e 18 ficam para a semana.

### Slide 79 · Especificar antes de programar
`10:06 · 1 min`

Na Aula 01 vocês viram o Spec-Driven Development. A especificação vem antes do código e manda nele.

O agente de código escreve, e vocês revisam cada artefato antes de pedir o próximo. Cada um usa o agente que preferir: Claude Code, Codex, Gemini, Cursor ou Copilot. O AGENTS.md da pasta diz ao agente o escopo, os comandos permitidos e o que ele nunca pode fazer.

Cada etapa termina com o quadro "Revise antes de seguir". Se alguma resposta for não, o prompt é refeito antes da etapa seguinte. E todo prompt fica registrado, literal, em docs/prompts.md.

### Slide 80 · Os seis campos do prompt CREATE
`10:07 · 1 min`

Todo prompt desta aula segue o formato CREATE da Aula 01. São seis campos, e cada um responde a uma pergunta que o agente faria se pudesse.

Personagem é o papel do agente e o que ele não faz na etapa. Pedido é o que fazer e em qual arquivo. Exemplos mostram o formato exato, e o agente copia a forma, então o exemplo precisa estar certo. Ajustes trazem as proibições, como não inventar número. Tipo de saída define formato e tamanho. Extras dizem o que ler antes, quando mostrar o plano e quando parar.

Campo vazio vira suposição do agente. Por isso nenhum fica em branco.

### Slide 81 · Da persona ao teste, um fio só
`10:08 · 1 min`

Este slide é o motivo de tantas etapas. Cada artefato cita o anterior pelo identificador.

Leiam o fio: a persona P1 reprecifica em reais. O direcionador DN-01 é a margem perdida por câmbio sem data. O objetivo OBJ-02 pede cotação de fechamento todo dia. A regra RN-02 diz que vale o último Fechamento até a data D. O requisito RF-05 grava a PTAX bruta. O RNF-04 exige retry com jitter. A ADR-003 registra a escolha. A tarefa T-02 e o teste do 429 provam, e a evidência fica no manifesto.

Se um teste falha, o fio mostra qual decisão de negócio está em risco. Se o negócio muda, o fio mostra quais testes revisar.

### Slide 82 · Os IDs que ligam um artefato ao outro
`10:09 · 1 min`

Esta tabela é a legenda dos identificadores. Cada item recebe o ID na etapa em que nasce, e as etapas seguintes o citam.

P é persona, na Etapa 01. DN e OBJ são direcionador e objetivo, na Etapa 02. RN é regra, na 03. RF e RNF são requisitos, nas Etapas 04 e 05. ADR é decisão de arquitetura, na 09. T é tarefa, na 10.

A matriz de rastreabilidade é a tabela que mostra essas citações lado a lado. Ela aparece na Etapa 17.

### Slide 83 · O que a Etapa 00 deixa de pé
`10:10 · 1 min`

Antes do primeiro prompt, o ambiente precisa responder. Cada peça já apareceu nas Aulas 01 e 02.

O Codespace é a máquina Linux na nuvem, com Docker. O Docker Compose sobe o MinIO e só devolve o terminal quando ele está saudável. São três buckets: raw para os bytes da fonte, bronze para o JSON Lines, e teste só para os testes, para não sujar os outros dois.

O .env guarda endereço e senha do MinIO. Senha é segredo, então o arquivo fica no .gitignore.

### Slide 84 · Pasta, MinIO local e registro de prompts
`10:11 · 1 min`

[AÇÃO] No Codespace, rode os comandos do slide em sequência (ou mostre o terminal onde já rodou antes da aula). Em seguida rode `docker compose ps`, `docker compose exec minio mc ls local` e `git check-ignore .env`.

Estes comandos criam a pasta aula_03_api_scraping com docs, specs, features, src e tests. Depois copiam os arquivos do laboratório, sobem o MinIO e criam os três buckets.

O gate tem três provas. O docker compose ps mostra healthy. O mc ls lista raw, bronze e teste. E o git check-ignore imprime .env, o que confirma que a senha não vai para o Git.

Quem ainda não tem o ambiente de pé, siga o README do laboratório e acompanhe as próximas etapas pela tela. Plano B: se o Docker demorar no Codespace, eu sigo com o meu ambiente e vocês alcançam na semana.

### Slide 85 · Quem usa o dado e que decisão toma
`10:12 · 4 min`

[AÇÃO] Clique em Copiar. Cole o prompt no agente, aberto na pasta aula_03_api_scraping. Aguarde o plano, leia em voz alta e dê o ok.

Persona é o retrato de quem usa o sistema: que decisão toma, que dor tem, com que frequência. Num pipeline há três lados.

O prompt pede três personas. P1 decide com o dado, a analista de compras que reprecifica em reais. P2 é quem é acionado quando a coleta falha. P3 é quem consome o bronze na Aula 04. Ele também pede que todo valor sem origem receba a marcação "hipótese, validação pendente".

[AÇÃO] Quando o agente terminar, abra docs/00_persona.md e leia a revisão com a turma.

Vamos conferir. Cada persona decide algo concreto? A P2 sabe o que a acorda de madrugada?

[ESPERE]

Resposta esperada: P2 é acionada quando a coleta falha ou a contagem não bate, e o manifesto é o que ela lê.

Algum horário ou volume apareceu sem a marcação de hipótese? E o aviso de que o domínio é didático está no topo? O site avisa que preços e avaliações são aleatórios.

Plano B: se o agente demorar, mostre o exemplo de persona que está no material, na Etapa 01.

### Slide 86 · Direcionadores de negócio e objetivos medíveis
`10:16 · 3 min`

[AÇÃO] Copiar, colar no agente, aguardar o plano, dar o ok.

Direcionador é a força que justifica o sistema existir: dinheiro, prazo, risco, regulação. Objetivo é a resposta a essa força, com métrica e com um comando que mede.

O prompt pede os DN, os OBJ, as restrições da disciplina e o fora de escopo. O exemplo é o OBJ-01: snapshot diário completo, medido comparando as linhas do livros.jsonl com o total que a página inicial declara.

[AÇÃO] Abra docs/01_objetivos_negocio.md e leia a revisão.

Cada objetivo tem um comando que mede? Cada direcionador tem ao menos um objetivo? E o fora de escopo segura a Aula 04 fora daqui?

[ESPERE]

Resposta esperada: Parquet, DuckDB, silver, gold e conversão para reais ficam fora.

Esses direcionadores voltam na Etapa 17, quando a gente procura riscos na arquitetura.

### Slide 87 · Regras de negócio antes de requisitos
`10:19 · 3 min`

[AÇÃO] Copiar, colar, aguardar o plano, dar o ok.

No cinesenac, uma frase do cliente sobre assentos virou as regras RN01 a RN03. Aqui fazemos o mesmo com o monitor.

A regra vale no mundo, com ou sem software. O requisito, na próxima etapa, é o que o sistema faz para respeitá-la. O prompt pede cada regra com enunciado, origem, exemplo e contraexemplo, e proíbe nome de biblioteca, bucket ou função.

[AÇÃO] Abra docs/02_regras_de_negocio.md e leia a revisão.

Alguma regra fala de tecnologia? O contraexemplo da regra de cotação faz sentido?

[ESPERE]

Resposta esperada: usar o boletim de Abertura do dia porque saiu antes, em vez do último Fechamento.

E a regra da execução incompleta tem critério numérico? Ela precisa comparar o total declarado com o total extraído.

### Slide 88 · Critério de aceite em três partes
`10:22 · 1 min`

Requisito sem critério de aceite vira discussão. Com critério, vira teste.

O formato Dado, Quando, Então separa três coisas. Dado é o contexto antes: a PTAX respondeu 200 com ao menos um Fechamento. Quando é um evento só: a coleta da data D termina. Então é o resultado que se confere: existe o objeto na chave raw/ptax, com o SHA-256 igual ao do corpo recebido.

Bom critério compara com o total que a página declara, e não com 1.000 escrito à mão. Na Etapa 11, cada critério vira um cenário Gherkin e um teste com o mesmo nome.

### Slide 89 · Requisitos funcionais com Dado, Quando, Então
`10:23 · 4 min`

[AÇÃO] Copiar, colar, aguardar o índice dos RFs que o agente mostra antes de escrever, dar o ok.

O prompt pede os RF do monitor, cada um com origem e critério. Ele lista o que precisa estar coberto: categorias, paginação, detalhe de cada livro, gravação do bruto, robots.txt, a janela da PTAX, o manifesto, a extração e a reexecução sem duplicar.

Reparem que o prompt traz os fatos verificados das fontes. São os seletores e os comportamentos da PTAX que vimos de manhã. O agente é instruído a confirmar antes de usar.

[AÇÃO] Abra specs/01_requisitos_funcionais.md e leia a revisão.

Todo critério vira teste sem reinterpretação? Existe RF para janela PTAX vazia e para data em formato errado?

[ESPERE]

Resposta esperada: precisa existir, porque os dois devolvem 200 com lista vazia, e o critério tem de separar os casos.

Por último, a matriz RN para RF no fim do arquivo não pode ter regra órfã.

Plano B: se o agente demorar, mostre o exemplo do RF-05 no material.

### Slide 90 · Requisitos não funcionais com número e medida
`10:27 · 2 min`

[AÇÃO] Copiar, colar, aguardar o plano, dar o ok.

A ISO/IEC 25010 divide a qualidade de software em oito características. Cada uma vira um grupo de RNF.

O prompt dá ao agente as medidas de 16/10 como linha de base: 1.081 requisições, latência mediana de 0,15 s, cerca de 18 minutos de espera, 21,5 MiB de bruto por execução. São medidas, e não metas. O exemplo é o RNF-04, retry com backoff e jitter.

[AÇÃO] Abra specs/02_requisitos_nao_funcionais.md e leia a revisão.

Os oito eixos aparecem? Cada RNF tem uma medida que um teste, um comando ou o manifesto prova? A linha de base foi tratada como medida?

### Slide 91 · ISO/IEC 25010 aplicada ao monitor
`10:29 · 1 min`

Esta tabela traduz cada eixo numa pergunta sobre o monitor.

No cinesenac, com 10.000 usuários num frontend, pesava o tempo de resposta. Num coletor diário, pesam a confiabilidade e o respeito à fonte. Confiabilidade pergunta se o monitor sobrevive a timeout, 429, 5xx e 502. Compatibilidade pergunta se a Aula 04 lê o bronze sem adaptar.

Usem esta tabela para conferir o arquivo que o agente gerou.

### Slide 92 · Modelo lógico, DBML e contrato de dados
`10:30 · 1 min`

A Etapa 06 descreve os dados antes de qualquer código. Num data lake não há tabela de banco, mas há registros com campos e relações.

O modelo lógico tem cinco entidades: execução, item do manifesto, objeto bruto, livro e cotação. Cardinalidade diz quantos se ligam a quantos: uma execução tem muitos itens; um detalhe.html gera uma linha de livro.

DBML é uma linguagem de texto para tabelas e relações, e o dbdiagram.io desenha o diagrama a partir dela. Contrato de dados é o acordo entre quem produz e quem consome. Os campos do bronze são o contrato com as Aulas 04, 05 e 07.

### Slide 93 · Modelo de dados: chaves, contratos e manifesto
`10:31 · 3 min`

[AÇÃO] Copiar, colar, aguardar o plano, dar o ok.

O prompt pede três partes. Primeiro, o layout das chaves em raw e bronze, com um exemplo real de cada. Depois, o dicionário do bronze, campo a campo, com tipo, origem e regra. Por fim, o manifesto e os metadados de cada objeto, além do DBML.

[AÇÃO] Abra specs/03_modelo_de_dados.md. Copie o bloco DBML e cole em dbdiagram.io para mostrar o desenho.

Os nove campos do livros.jsonl e os cinco do cotacoes.jsonl estão com os nomes exatos? Alguma chave usa horário?

[ESPERE]

Resposta esperada: só o manifesto leva o id da execução. As outras chaves derivam de fonte, data e página, e por isso a reexecução não duplica.

### Slide 94 · Modelo lógico do monitor
`10:34 · 1 min`

Este é o modelo que o agente deve chegar perto. São cinco entidades em três prefixos.

A execução tem muitos itens no manifesto. Cada item aponta para um objeto bruto pela chave. Um detalhe.html vira uma linha de livro, e um JSON da PTAX vira um registro por boletim da janela.

Os campos do bronze não se renomeiam nem se traduzem. A Aula 04 depende deles.

### Slide 95 · Mermaid, componentes e classes
`10:35 · 1 min`

Modelagem estática mostra as partes do sistema e quem depende de quem, sem a passagem do tempo.

Mermaid é uma linguagem de texto que o GitHub desenha dentro do Markdown. Um ponto e vírgula dentro de um rótulo quebra o diagrama inteiro, e o cinesenac perdeu um assim. Componente é um bloco com uma responsabilidade, como o ClienteHttp. Diagrama de classes mostra atributos e assinaturas, como get que recebe uma url e devolve uma Resposta.

Desenhar antes custa minutos. Mudar um módulo pronto custa testes refeitos.

### Slide 96 · Componentes e classes antes do código
`10:36 · 3 min`

[AÇÃO] Copiar, colar, aguardar o plano, dar o ok.

O prompt pede dois arquivos. Um com o diagrama de componentes, com responsabilidade, interface e requisitos de cada um. Outro com o diagrama de classes, de Config até Livro e Cotacao.

Ele traz duas regras: coletor não conhece o MinIO, recebe um gravador. E o extrator não importa requests.

[AÇÃO] Abra componentes.md no preview do GitHub ou do editor para ver o diagrama renderizado. Leia a revisão.

Há alguma seta do extrator para a rede?

[ESPERE]

Resposta esperada: não pode haver. O extrator lê e grava só no MinIO.

Todo RF aparece em algum componente? E o diagrama renderiza?

### Slide 97 · Componentes e o limite da rede
`10:39 · 1 min`

Este é o desenho de referência. A caixa tracejada à esquerda é a rede, e só os coletores chegam até ela, sempre pelo ClienteHttp.

O extrator fica embaixo do raw: lê o raw e grava o bronze, sem internet. Por isso ele roda e é testado na sala mesmo se o site sair do ar.

Comparem com o componentes.md que o agente gerou.

### Slide 98 · Sequências com falha e estados do item
`10:40 · 3 min`

[AÇÃO] Copiar, colar, aguardar o plano, dar o ok.

Agora o sistema no tempo. O prompt pede um diagrama de sequência por fluxo: PTAX com janela, uma categoria com 429 e read timeout, gravação com 502 do Railway, extração e reexecução. Cada diagrama precisa trazer o caminho de erro. Ele também pede um diagrama de estados do item do manifesto.

[AÇÃO] Enquanto o agente trabalha, avance para os dois próximos slides. Volte aqui para a revisão quando os arquivos estiverem prontos.

O 502 aparece com a mesma chave no retry? O diagrama de extração toca alguma fonte externa? O estado "falhou" é final e fica registrado no manifesto?

### Slide 99 · Como ler sequência e estados
`10:43 · 1 min`

Antes de ver os diagramas, as convenções.

No diagrama de sequência, os participantes ficam no topo, e o tempo corre de cima para baixo pela linha de vida. Seta cheia é chamada, e seta tracejada é resposta. Caixa cinza é uma nota, aqui usada para espera.

No diagrama de estados, cada caixa é um estado e cada seta é uma transição com o evento ao lado. O círculo cheio é o início e o círculo com anel é o fim. Todo laço precisa de saída, e aqui a saída é o limite de tentativas.

### Slide 100 · Um detalhe de livro com 429 e 502
`10:44 · 1 min`

Leiam de cima para baixo. O ColetorBooks pede o detalhe ao ClienteHttp. A fonte responde 429 com Retry-After 2, e o cliente espera exatamente 2 segundos, porque o servidor manda.

Na segunda tentativa vem o 200. Depois o gravador faz o PUT no MinIO do Railway, e o proxy devolve 502, mesmo com o objeto já gravado. O gravador espera um tempo sorteado e repete na mesma chave.

No fim, duas tentativas no GET, duas no PUT e um objeto só no bucket.

### Slide 101 · Estados de um item do manifesto
`10:45 · 1 min`

Cada URL da coleta percorre estes estados. Pendente, baixando, e daí três caminhos.

Com 200 ou 304, vai para baixado e, com o PUT, para gravado. Com timeout, 408, 429 ou 5xx, vai para aguardando e volta a baixar. Com 4xx sem retry ou com o limite atingido, vai para falhou.

O item que falha não para a execução. Ele entra no manifesto, e a contagem final denuncia a lacuna. É assim que se responde por que o livros.jsonl saiu com 980 linhas.

### Slide 102 · O que é uma ADR
`10:46 · 1 min`

ADR é Architecture Decision Record, proposta por Michael Nygard em 2011. É um arquivo curto por decisão de arquitetura, guardado no repositório.

Tem contexto, decisão, alternativas e consequências. Sem as alternativas, a ADR vira anúncio da escolha. As consequências trazem o que melhora e o que custa: o full jitter reduz o pico e faz a duração da coleta variar.

Toda ADR nasce como Proposta. Vira Aceita quando o grupo aprova.

### Slide 103 · Uma ADR por tática de qualidade
`10:47 · 2 min`

[AÇÃO] Copiar, colar, aguardar o plano, dar o ok.

O prompt pede o arquitetura.md com drivers, estilo, implantação e o mapa de tática para RNF. Pede também sete ADRs, todas em status Proposta.

[AÇÃO] Abra docs/adr/ e mostre a ADR-003. Leia a revisão.

Cada ADR tem pelo menos duas alternativas reais? As consequências trazem o custo, e não só o benefício?

[ESPERE]

Resposta esperada: a ADR-004 tem de admitir os cerca de 18 minutos de espera como custo da coleta sequencial.

### Slide 104 · As táticas da teoria viram ADRs
`10:49 · 1 min`

Esta tabela junta as sete decisões. Todas apareceram de manhã.

Coleta e extração separadas, no bloco 5. Chave por fonte, data e página, também no bloco 5. Backoff com full jitter, no bloco 1. Coleta sequencial, no bloco 3. Bytes originais no raw, também no bloco 3. Manifesto por execução e janela de dias na PTAX, nos blocos 5 e 2.

Reparem na última coluna: cada decisão tem um custo aceito.

### Slide 105 · Plano, tarefa e gate
`10:50 · 1 min`

Até aqui os documentos dizem o que construir e por quê. O plano diz com o quê, e as tarefas dividem o trabalho.

No plano, cada biblioteca cita o RNF que a justifica. O cinesenac chamou isso de No Invention. Tarefa é trabalho de até 30 minutos, com o teste que prova a conclusão. Gate é a verificação que precisa passar para seguir.

Tarefa curta gera diff curto, que o grupo consegue revisar.

### Slide 106 · Plano e tarefas de até 30 minutos
`10:51 · 3 min`

[AÇÃO] Copiar, colar, aguardar o plano, dar o ok.

O prompt pede o plan.md e o tasks.md. As tarefas já nascem agrupadas nas Etapas 12 a 15, cada uma com arquivos, requisitos, ADR, teste e comando.

[AÇÃO] Abra specs/tasks.md e role até a tabela requisito por tarefa. Leia a revisão.

Alguma tarefa mexe em mais de três arquivos? Existe tarefa para cada falha tratada?

[ESPERE]

Resposta esperada: timeout, 429, 5xx, PTAX vazia, 502 e reexecução, cada uma com sua tarefa.

E algum RF ficou sem tarefa? Linha vazia na tabela é requisito que ninguém vai construir.

### Slide 107 · Teste primeiro: vermelho, depois verde
`10:54 · 1 min`

No TDD, o teste vem antes do código. Ele falha porque a função ainda não existe, e só então o código é escrito.

Vermelho é falhar pelo motivo certo: ImportError ou NotImplementedError, nunca erro de digitação no teste. Verde é o código mínimo que faz passar.

Teste unitário roda sem rede e sem MinIO. Teste de integração conversa com o MinIO local, no bucket teste. O teste escrito depois tende a confirmar o que o código já faz. Escrito antes, ele confere o critério de aceite.

### Slide 108 · Fixture, servidor simulado e Gherkin
`10:55 · 1 min`

Três recursos para testar sem depender do site.

Fixture é um arquivo fixo em tests/fixtures, como a página real do Sharp Objects. Servidor simulado é uma função falsa no lugar do get, que devolve 429 com Retry-After 2 e depois 200. E o sleep simulado só anota o valor pedido, então o teste confere a espera de 2 segundos sem esperar.

Gherkin escreve o cenário em Dado, Quando, Então, legível por quem não programa. A tag, como @RF-08, liga o teste ao requisito.

### Slide 109 · Três páginas reais, baixadas uma vez
`10:56 · 1 min`

[AÇÃO] Copiar os comandos do slide e rodar no terminal do Codespace. Depois `ls -l tests/fixtures`.

Estes três curl baixam a página inicial, a primeira página de Mystery e o detalhe do Sharp Objects, com o mesmo User-Agent e a mesma pausa da coleta.

Uso página real porque uma fixture escrita à mão testa o que o agente imagina do site. A real traz o Content-Type sem charset, a libra em UTF-8 e o UPC e00eb4fd7b871a48. Conferi ontem: 1000 resultados na página inicial e 20 em estoque no detalhe.

### Slide 110 · Testes vermelhos a partir dos critérios
`10:57 · 3 min`

[AÇÃO] Copiar, colar, aguardar o plano, dar o ok. Quando terminar, rode `pytest -q` e mostre a saída vermelha.

O prompt pede um arquivo Gherkin por módulo, copiando os critérios dos requisitos com a tag do ID. Pede também um teste pytest por cenário e a prova de que todos falham pelo motivo certo.

Há um cenário para cada critério de aceite? Os testes falham por ImportError ou NotImplementedError?

[ESPERE]

Resposta esperada: sim. Se algum falhar por erro dentro do próprio teste, o teste está errado e volta para o agente.

Algum teste depende da ordem de execução? Não pode.

### Slide 111 · Um prompt, quatro rodadas de tarefas
`11:00 · 2 min`

As quatro etapas de código usam o mesmo prompt. Muda só o intervalo de tarefas.

Para cada tarefa, o agente mostra o plano, roda o teste vermelho, implementa o mínimo, roda o pytest verde e marca a tarefa no tasks.md. Os testes da Etapa 11 são o contrato: o agente não pode alterá-los para passar.

Na revisão de cada rodada, quatro perguntas: o teste estava vermelho antes? O diff mexe só nos arquivos da tarefa? Existe requests.get sem timeout? Algum segredo ou URL do Railway no código?

### Slide 112 · O cliente que toda coleta usa
`11:02 · 7 min`

[AÇÃO] Copie o prompt do slide 111, troque o intervalo pelas tarefas da Etapa 12 no seu tasks.md, cole no agente e dê o ok.

Começo pelo cliente HTTP porque todo coletor depende dele. É a teoria do bloco 1 em vinte linhas: timeout em toda chamada, repetição só do transitório, full jitter e Retry-After.

O trecho do slide é o núcleo que o teste espera. A função deve_repetir trata None como timeout ou erro de conexão. A função espera devolve o Retry-After quando ele existe e, senão, sorteia entre zero e o mínimo entre o teto e base vezes dois elevado à tentativa.

[AÇÃO] Quando o agente terminar, rode `pytest tests/test_http.py tests/test_config.py -q`. Abra o diff e procure o timeout no get.

O teste do 429 passou? O sleep simulado recebeu 2?

Plano B: se o tempo apertar, mostre o código do slide e siga para a Etapa 13.

### Slide 113 · Gravador no MinIO e manifesto
`11:09 · 6 min`

[AÇÃO] Mesmo prompt, intervalo das tarefas da Etapa 13. Cole e dê o ok.

O gravador aplica o bloco 5. A chave deriva de fonte, data e página. O corpo vai como bytes originais, nunca response.text. E os metadados levam fonte-url, coletado-em, sha256 e execução, só em ASCII. O boto3 recusa acento em metadado com ParamValidationError.

O teste do 502 confere que o retry do put_object cai na mesma chave.

[AÇÃO] Rode `pytest -m minio -q` e depois `docker compose exec minio mc ls local/teste` para mostrar os objetos de teste.

### Slide 114 · Coletores da PTAX e do catálogo
`11:15 · 5 min`

[AÇÃO] Mesmo prompt, intervalo das tarefas da Etapa 14. Cole e dê o ok.

Os dois coletores gravam o bruto antes de qualquer interpretação.

O da PTAX monta a janela de dias com datas em MM-DD-AAAA. Se nenhum Fechamento aparecer, registra falha no manifesto. O do catálogo consulta e registra o robots.txt, que hoje devolve 404. Depois percorre categorias, segue o li.next com urljoin e visita cada detalhe. SCRAPER_CATEGORIAS restringe a coleta durante o desenvolvimento.

[AÇÃO] Rode `pytest tests/test_coletores.py -q`.

Plano B: se faltar tempo, a Etapa 14 segue na semana. Mostre o código do slide e passe para a 15.

### Slide 115 · Extrator e linha de comando
`11:20 · 5 min`

[AÇÃO] Mesmo prompt, intervalo das tarefas da Etapa 15. Cole e dê o ok.

O extrator lê só do MinIO. Ele pega o total declarado na página inicial, no form.form-horizontal strong, e compara com as linhas extraídas. Se não bater, falha com erro visível.

Grava o livros.jsonl com os nove campos e o cotacoes.jsonl com os cinco. E ganha dois comandos, coletar e extrair, cada um com --data.

[AÇÃO] Rode `pytest -q` e mostre tudo verde, ou mostre até onde chegou.

Em sala, o mínimo é o primeiro teste verde. O resto das rodadas fica para a semana.

### Slide 116 · Execução local e reexecução
`11:25 · 2 min`

Daqui em diante é trabalho da semana. Explico o que cada etapa pede.

A Etapa 16 roda primeiro com duas categorias, mystery_3 e poetry_23. Depois, com autorização, roda a coleta completa, de cerca de 18 minutos. O checklist é a prova: as linhas do livros.jsonl batem com o total declarado e com o número de detalhe.html. E a reexecução no mesmo dia mantém a contagem e cria só um manifesto a mais.

Essa reexecução é o teste da chave determinística.

### Slide 117 · ATAM: procurar riscos na arquitetura
`11:27 · 1 min`

ATAM é o método da Carnegie Mellon que vocês viram na Aula 01. Ele parte dos direcionadores de negócio e testa a arquitetura contra cenários concretos.

A utility tree vai do atributo de qualidade até o cenário, com prioridade de importância e de dificuldade. O cenário tem seis partes: fonte, estímulo, artefato, ambiente, resposta e medida. Trade-off é melhorar uma qualidade e piorar outra, como cadência educada contra tempo de coleta.

A cobertura vem do pytest --cov, e anota-se o número medido.

### Slide 118 · ATAM, rastreabilidade e cobertura
`11:28 · 1 min`

O prompt da Etapa 17 pede o atam.md com sete cenários obrigatórios e o rastreabilidade.md, com a matriz da persona até a evidência.

Na revisão: os sete cenários têm as seis partes? A matriz tem linha vazia? A cobertura veio do comando ou foi digitada?

Para quem quiser ir além, o cinesenac montou um workflow no GitHub Actions com o banco num contêiner. Aqui o equivalente é o MinIO como service container rodando pytest a cada push.

### Slide 119 · Mesmo código, outro endpoint
`11:29 · 1 min`

A Etapa 18 aponta o mesmo código para o MinIO da turma no Railway. Só muda o .env.railway, com o endereço público e as chaves do serviço.

O proxy do Railway pode devolver 502. Se acontecer, o manifesto mostra gravações com mais de uma tentativa, e o bucket continua sem duplicata.

O entregável final aparece no último slide da aula. Agora, o quiz.

## Quiz · 11:30

### Slide 120 · Dez perguntas sobre a teoria da manhã
`11:30 · 3 min`

[AÇÃO] Clique em Área do professor no rodapé, entre no painel e abra a sala do quiz. Projete o QR. Abra o botão Quiz numa aba separada para testar o acesso.

Agora são dez perguntas sobre a teoria da manhã, no estilo Kahoot, no celular.

Três perguntas retomam a Aula 02: tipos de storage, chave particionada no raw e schema on read. As outras sete cobrem os cinco blocos de hoje: status e retry, jitter, PTAX, codificação, escolha da fonte e chaves.

Apontem a câmera para o QR e escolham o nome que vai aparecer no placar.

[ESPERE] até o painel mostrar a turma conectada.

### Slide 121 · 90 segundos por pergunta, a última vale o dobro
`11:33 · 27 min`

[AÇÃO] Leia as regras e inicie o quiz pelo painel. Depois de cada revelação, comente a explicação em uma ou duas frases antes de abrir a próxima.

Cada pergunta abre para todos ao mesmo tempo e tem 90 segundos. Uma escolha só; depois do toque, a resposta não muda.

Acerto rende mais pontos quanto antes chegar, e erro vale zero. A pergunta 10 vale o dobro. Sair da aba com a pergunta aberta zera os pontos dela.

No fim, cada um vê os temas que errou, com a seção do material para retomar antes da Aula 04.

[AÇÃO] Ao terminar, mostre o placar final e o relatório por tema no painel.

## Fechamento · 12:00

### Slide 122 · O que existe às 12h10 e o que fica para a semana
`12:00 · 6 min`

[AÇÃO] Volte ao deck.

Vamos fechar com o que cada um precisa ter hoje e o que fica para a semana.

Em sala, o esperado é a Etapa 00 de pé, as Etapas 01 a 10 revisadas e a Etapa 11 com o primeiro teste verde. Também conta o quiz respondido, com os temas a retomar anotados.

Na semana, até a Aula 04, no dia 31/10: Etapas 12 a 15 com pytest verde. Depois a 16, com a coleta completa e a reexecução, a 17, com ATAM e rastreabilidade, e a 18, com uma data gravada no MinIO do Railway.

Quem travou em alguma etapa hoje, o material tem cada prompt completo, e o README do laboratório tem os comandos.

### Slide 123 · Pasta aula_03_api_scraping/
`12:06 · 4 min`

A entrega é a pasta aula_03_api_scraping no repositório do grupo.

Eu corrijo por dois caminhos. O primeiro é o docs/prompts.md, que mostra o que vocês pediram ao agente. O segundo é a matriz de rastreabilidade: cada teste precisa levar a um requisito, e cada requisito a uma persona.

Dentro da pasta: em docs, prompts, persona, objetivos, regras, modelagem, arquitetura, as sete ADRs, ATAM e rastreabilidade. Em specs, RF, RNF, modelo de dados, plano e tarefas. Depois features, src e tests verdes, e os objetos de pelo menos uma data no MinIO do Railway.

Dúvidas sobre a entrega?

[ESPERE]

Até a Aula 04, no dia 31/10.
