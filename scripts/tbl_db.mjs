// Credencial lida apenas no processo local; nunca entra no HTML nem no log.
import fs from 'node:fs';
import pg from 'pg';
const envPath = process.env.QUIZ_ENV_FILE || '.env';
const env = fs.readFileSync(envPath, 'utf8');
const match = env.match(/^\s*SUPABASE_DB_URL\s*=\s*(.+)\s*$/m);
if (!match) throw new Error('SUPABASE_DB_URL ausente no arquivo de ambiente.');
const connectionString = match[1].trim().replace(/^(['"])(.*)\1$/, '$2');
const SLUG = 'mack-dv-a06-2026-2';
const client = new pg.Client({ connectionString, connectionTimeoutMillis: 15000 });
try {
  await client.connect();
  if (process.argv.includes('--apply')) {
    // O token do professor não fica no SQL versionado: o seed traz um marcador
    // e o valor real vem do .env, que o Git ignora. TBL e quiz são do mesmo
    // professor na mesma aula, então TBL_HOST_TOKEN é opcional.
    const tokenMatch = env.match(/^\s*TBL_HOST_TOKEN\s*=\s*(.+)\s*$/m)
      || env.match(/^\s*QUIZ_HOST_TOKEN\s*=\s*(.+)\s*$/m);
    if (!tokenMatch) throw new Error('TBL_HOST_TOKEN (ou QUIZ_HOST_TOKEN) ausente no arquivo de ambiente.');
    const hostToken = tokenMatch[1].trim().replace(/^(['"])(.*)\1$/, '$2');
    if (!/^[A-Za-z0-9_-]{4,64}$/.test(hostToken)) {
      throw new Error('Token do professor fora do formato aceito.');
    }
    const seed = fs.readFileSync(new URL('../supabase/tbl_seed_aula_06_data_visualization.sql', import.meta.url), 'utf8')
      .replaceAll('__TBL_HOST_TOKEN__', hostToken);
    await client.query(seed);
  }
  const result = await client.query(`select s.slug, s.fase, s.questao,
    count(q.ordem)::int as questoes,
    count(*) filter (where q.dado_novo is not null)::int as com_dado_novo,
    (select count(*)::int from hubtbl_participantes p where p.session_slug = s.slug) as participantes,
    (select count(*)::int from hubtbl_votos v where v.session_slug = s.slug) as votos
    from hubtbl_sessions s left join hubtbl_questoes q on q.session_slug = s.slug
    where s.slug = $1 group by s.slug, s.fase, s.questao`, [SLUG]);
  console.log(JSON.stringify(result.rows));
} catch (error) {
  console.error('Falha na conexão ou aplicação do TBL:', error.code || 'erro sem código');
  process.exitCode = 1;
} finally {
  await client.end();
}
