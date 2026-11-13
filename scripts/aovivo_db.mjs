// Credencial lida apenas no processo local; nunca entra no HTML nem no log.
// Aplica supabase/aovivo_schema.sql (respostas ao vivo) e mostra o estado das salas.
import fs from 'node:fs';
import pg from 'pg';

const envPath = process.env.QUIZ_ENV_FILE || '.env';
const env = fs.readFileSync(envPath, 'utf8');
const ler = (chave) => env.match(new RegExp(`^\\s*${chave}\\s*=\\s*(.+)\\s*$`, 'm'))?.[1]
  .trim().replace(/^(['"])(.*)\1$/, '$2');

const connectionString = ler('AULAS_DB_URL');
if (!connectionString) throw new Error('AULAS_DB_URL ausente no arquivo de ambiente. Abra o túnel (ver supabase/README.md) e aponte para postgresql://postgres:<senha>@127.0.0.1:55432/aulas.');

const client = new pg.Client({ connectionString, connectionTimeoutMillis: 15000 });
try {
  await client.connect();
  if (process.argv.includes('--apply')) {
    // Token do professor de Data Collection; o SQL versionado traz só o marcador.
    const hostToken = ler('AOVIVO_HOST_TOKEN') || ler('DCS_HOST_TOKEN');
    if (!hostToken) throw new Error('AOVIVO_HOST_TOKEN (ou DCS_HOST_TOKEN) ausente no arquivo de ambiente.');
    if (!/^[A-Za-z0-9_-]{4,64}$/.test(hostToken)) {
      throw new Error('Token do professor fora do formato aceito.');
    }
    const sql = fs.readFileSync(new URL('../supabase/aovivo_schema.sql', import.meta.url), 'utf8')
      .replaceAll('__AOVIVO_HOST_TOKEN__', hostToken);
    await client.query(sql);
  }
  const result = await client.query(`select s.slug, s.aberta, s.perguntas,
      count(r.*)::int as respostas, count(distinct r.cliente)::int as grupos
    from aovivo_salas s left join aovivo_respostas r on r.sala_slug = s.slug
    group by s.slug, s.aberta, s.perguntas order by s.slug`);
  console.log(JSON.stringify(result.rows));
} catch (error) {
  console.error('Falha na conexão ou aplicação das respostas ao vivo:', error.code || error.message);
  process.exitCode = 1;
} finally {
  await client.end();
}
