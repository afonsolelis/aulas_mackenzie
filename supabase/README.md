# Seeds das atividades interativas

A pasta guarda os seeds dos TBLs, quizzes e entregas. O nome `supabase/`
ficou por histórico: desde novembro de 2026 as atividades do Mackenzie rodam
no Postgres + PostgREST do projeto `aulas_mackenzie` na VPS (Coolify), e não
mais no Supabase cloud. O `aulas_senac` saiu de lá em 07/11/2026 para um
PostgREST próprio na mesma VPS (`https://aulas-senac-api.afonsolelis.tech`).

- API usada pelas páginas: `https://aulas-mackenzie-api.afonsolelis.tech`,
  pelo cliente `assets/api_aulas.js`. Só as RPCs ficam expostas; o token do
  professor e o gabarito permanecem no banco e são validados pelas RPCs.
- O Postgres não tem porta pública. Ele escuta só em `127.0.0.1:55432` da VPS,
  e os scripts chegam a ele por túnel SSH.

## Aplicar um seed

1. Abra o túnel em outro terminal e deixe aberto:

   ```bash
   ssh -N -L 55432:127.0.0.1:55432 root@<ip-da-vps>
   ```

2. Confira que o `.env` local tem `AULAS_DB_URL` apontando para
   `postgresql://postgres:<senha>@127.0.0.1:55432/aulas`. O arquivo é ignorado
   pelo Git.

3. Rode o `check` e depois o `apply` da atividade, por exemplo:

   ```bash
   npm run quiz:aula05:check
   npm run quiz:aula05:apply
   ```

`check` confirma o estado, a quantidade de perguntas e o peso da última.
`apply` executa o seed. Os seeds são transacionais e recusam alterações depois
que a sala começou ou recebeu participantes.

Não execute `quiz-schema.sql` do repositório `aulas_senac`: ele foi escrito
para o Supabase e recria as tabelas. A estrutura e as RPCs já estão instaladas
no banco da VPS.

## Respostas ao vivo (`aovivo_*`)

`aovivo_schema.sql` cria as tabelas e as RPCs do painel ao vivo: os grupos
escrevem as respostas das missões no simulador da Aula 06 de Data Collection
(`aovivo_enviar`), e o slide 51 do deck mostra as respostas por missão
(`aovivo_painel`, com o token do professor). O token vem de
`AOVIVO_HOST_TOKEN` ou, na falta dele, de `DCS_HOST_TOKEN`, ambos no `.env`.

```bash
npm run aovivo:apply
npm run aovivo:check
```

O script é idempotente e não apaga respostas. Para limpar a sala depois de um
ensaio, chame `aovivo_limpar(token, 'mack-dcs-a06-2026-2')`; para bloquear
novos envios, `aovivo_abrir(token, 'mack-dcs-a06-2026-2', false)`.
