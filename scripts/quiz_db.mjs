// Credencial lida apenas no processo local; nunca entra no HTML nem no log.
import fs from 'node:fs';
import pg from 'pg';
const envPath = process.env.QUIZ_ENV_FILE || '.env';
const env = fs.readFileSync(envPath, 'utf8');
const match = env.match(/^\s*SUPABASE_DB_URL\s*=\s*(.+)\s*$/m);
if (!match) throw new Error('SUPABASE_DB_URL ausente no arquivo de ambiente.');
const connectionString = match[1].trim().replace(/^(['"])(.*)\1$/, '$2');
// Parâmetros opcionais: --sala <slug> --seed <arquivo em supabase/> --token-env <VAR>.
// Sem eles, o script opera o quiz da Aula 05 de Data Visualization.
const arg = (nome, padrao) => { const i = process.argv.indexOf(nome); return i > -1 ? process.argv[i + 1] : padrao; };
const SLUG = arg('--sala', 'mack-dv-a05-2026-2');
const SEED = arg('--seed', 'quiz_seed_aula_05_data_visualization.sql');
const TOKEN_ENV = arg('--token-env', 'QUIZ_HOST_TOKEN');
const client = new pg.Client({ connectionString, connectionTimeoutMillis: 15000 });
try {
  await client.connect();
  if (process.argv.includes('--apply')) {
    // O token do professor não fica no SQL versionado: o seed traz um marcador
    // e o valor real vem do .env, que o Git ignora.
    const tokenMatch = env.match(new RegExp('^\\s*' + TOKEN_ENV + '\\s*=\\s*(.+)\\s*$', 'm'));
    if (!tokenMatch) throw new Error(TOKEN_ENV + ' ausente no arquivo de ambiente.');
    const hostToken = tokenMatch[1].trim().replace(/^(['"])(.*)\1$/, '$2');
    if (!/^[A-Za-z0-9_-]{4,64}$/.test(hostToken)) {
      throw new Error('QUIZ_HOST_TOKEN fora do formato aceito.');
    }
    const seed = fs.readFileSync(new URL('../supabase/' + SEED, import.meta.url), 'utf8')
      .replaceAll('__QUIZ_HOST_TOKEN__', hostToken);
    await client.query(seed);
  }
  const result = await client.query(`select s.slug, s.estado, count(q.id)::int as perguntas,
    count(*) filter(where q.peso=2)::int as perguntas_dobro,
    (select count(*)::int from quiz_players p where p.session_slug=s.slug) as jogadores
    from quiz_sessions s left join quiz_questions q on q.session_slug=s.slug
    where s.slug=$1 group by s.slug,s.estado`, [SLUG]);
  console.log(JSON.stringify(result.rows));
} catch (error) {
  console.error('Falha na conexão ou aplicação do quiz:', error.code || 'erro sem código');
  process.exitCode = 1;
} finally {
  await client.end();
}
