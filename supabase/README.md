# Seeds das atividades interativas

A pasta guarda os seeds dos TBLs, quizzes e entregas. O nome `supabase/`
ficou por histórico: desde novembro de 2026 as atividades do Mackenzie rodam
no Postgres + PostgREST do projeto `aulas_mackenzie` na VPS (Coolify), e não
mais no Supabase cloud, que segue só com o `aulas_senac`.

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
