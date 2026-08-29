import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../../..');
const fileConfig = YAML.parse(
  fs.readFileSync(path.join(root, 'config/aula_03_codespaces_d3_ia.yaml'), 'utf8')
);

const integer = (value, fallback) => {
  const parsed = Number.parseInt(value ?? '', 10);
  return Number.isFinite(parsed) ? parsed : fallback;
};

export const config = Object.freeze({
  port: integer(process.env.PORT, fileConfig.server.port),
  databaseUrl: process.env.DATABASE_URL || process.env.POSTGRES_URL || '',
  database: {
    poolMax: integer(process.env.DB_POOL_MAX, fileConfig.database.pool_max),
    statementTimeoutMs: integer(
      process.env.DB_STATEMENT_TIMEOUT_MS,
      fileConfig.database.statement_timeout_ms
    ),
    ssl: process.env.DB_SSL !== 'false' && fileConfig.database.ssl
  },
  api: {
    maxRows: integer(process.env.API_MAX_ROWS, fileConfig.api.max_rows),
    requestTimeoutMs: integer(
      process.env.API_REQUEST_TIMEOUT_MS,
      fileConfig.api.request_timeout_ms
    )
  },
  agent: {
    enabled: process.env.AGENT_ENABLED !== 'false' && fileConfig.agent.enabled,
    apiKey: process.env.OPENAI_API_KEY || '',
    model: process.env.OPENAI_MODEL || fileConfig.agent.model,
    maxOutputTokens: integer(
      process.env.OPENAI_MAX_OUTPUT_TOKENS,
      fileConfig.agent.max_output_tokens
    )
  },
  fallbackData: process.env.FALLBACK_DATA !== 'false' && fileConfig.lab.fallback_data,
  publicDir: path.join(root, 'aulas/data_visualization/aula_03_visualizacao_de_dados_numericos/laboratorio/public')
});
