import pg from 'pg';
import { config } from './config.js';

let pool;

export function databaseEnabled() {
  return Boolean(config.databaseUrl);
}

function getPool() {
  if (!databaseEnabled()) return null;
  if (!pool) {
    pool = new pg.Pool({
      connectionString: config.databaseUrl,
      max: config.database.poolMax,
      statement_timeout: config.database.statementTimeoutMs,
      query_timeout: config.api.requestTimeoutMs,
      ssl: config.database.ssl ? { rejectUnauthorized: false } : false
    });
  }
  return pool;
}

export async function query(queryConfig) {
  const activePool = getPool();
  if (!activePool) throw new Error('database_unavailable');
  const result = await activePool.query(queryConfig);
  return result.rows.slice(0, config.api.maxRows);
}

export async function databaseHealth() {
  if (!databaseEnabled()) return 'not_configured';
  try {
    await getPool().query({ text: 'SELECT 1 AS ok', statement_timeout: 1500 });
    return 'available';
  } catch {
    return 'unavailable';
  }
}

export async function closeDatabase() {
  if (pool) await pool.end();
  pool = undefined;
}
