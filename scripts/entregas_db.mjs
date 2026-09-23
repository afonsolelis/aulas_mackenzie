// Credencial lida apenas no processo local; nunca entra no HTML nem no log.
import fs from 'node:fs';
import pg from 'pg';

const envPath = process.env.QUIZ_ENV_FILE || '.env';
const env = fs.readFileSync(envPath, 'utf8');
const ler = (chave) => env.match(new RegExp(`^\\s*${chave}\\s*=\\s*(.+)\\s*$`, 'm'))?.[1]
  .trim().replace(/^(['"])(.*)\1$/, '$2');

const connectionString = ler('SUPABASE_DB_URL');
if (!connectionString) throw new Error('SUPABASE_DB_URL ausente no arquivo de ambiente.');

const client = new pg.Client({ connectionString, connectionTimeoutMillis: 15000 });
try {
  await client.connect();
  if (process.argv.includes('--apply')) {
    // O token é o mesmo do quiz e do TBL, salvo quando ENTREGA_HOST_TOKEN existir.
    // O SQL versionado traz só o marcador; o banco guarda o hash.
    const hostToken = ler('ENTREGA_HOST_TOKEN') || ler('QUIZ_HOST_TOKEN');
    if (!hostToken) throw new Error('ENTREGA_HOST_TOKEN (ou QUIZ_HOST_TOKEN) ausente no arquivo de ambiente.');
    if (!/^[A-Za-z0-9_-]{4,64}$/.test(hostToken)) {
      throw new Error('Token do professor fora do formato aceito.');
    }
    const sql = fs.readFileSync(new URL('../supabase/entregas_schema.sql', import.meta.url), 'utf8')
      .replaceAll('__ENTREGA_HOST_TOKEN__', hostToken);
    await client.query(sql);
  }
  const result = await client.query(`select f.slug, f.aberto,
      to_char(f.prazo at time zone 'America/Sao_Paulo', 'DD/MM/YYYY HH24:MI') as prazo,
      count(r.id)::int as envios, count(distinct lower(r.grupo))::int as grupos,
      count(r.corrigido_em)::int as corrigidos
    from entrega_formularios f left join entrega_respostas r on r.formulario_slug = f.slug
    group by f.slug, f.aberto, f.prazo order by f.prazo desc`);
  console.log(JSON.stringify(result.rows));
} catch (error) {
  console.error('Falha na conexão ou aplicação das entregas:', error.code || error.message);
  process.exitCode = 1;
} finally {
  await client.end();
}
