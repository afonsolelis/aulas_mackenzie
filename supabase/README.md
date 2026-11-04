# Quiz da Aula 05 — Data Visualization

A sala usa o mesmo projeto Supabase dos quizzes de `aulas_senac`, com o slug
isolado `mack-dv-a05-2026-2`. O navegador recebe somente a URL e a chave
publicável. O token do professor e o gabarito permanecem no banco e são
validados pelas RPCs existentes.

O arquivo `.env` local deve conter `SUPABASE_DB_URL`. Ele é ignorado pelo Git.

```bash
npm run quiz:aula05:check
npm run quiz:aula05:apply
```

`check` confirma o estado, a quantidade de perguntas e o peso da última.
`apply` executa `quiz_seed_aula_05_data_visualization.sql`. O seed é transacional
e recusa alterações depois que a sala começou ou recebeu participantes.

Não execute `quiz-schema.sql` do repositório `aulas_senac`: ele recria as
tabelas compartilhadas. A infraestrutura e as RPCs já estão instaladas.
