import express from 'express';
import { z } from 'zod';
import { config } from './config.js';
import { agentRequestSchema, critique, localCritique } from './agent.js';
import { evolutionQuery, distributionQuery, magnitudeQuery, relationQuery } from './catalog.js';
import { databaseEnabled, databaseHealth, query } from './database.js';
import { aggregateFallbackEvolution, fallback } from './fallback_data.js';

const boundedInteger = (minimum, maximum, fallbackValue) => z.coerce.number().int()
  .min(minimum).max(maximum).default(fallbackValue);

export function histogram(values, bins) {
  if (!values.length) return [];
  const min = Math.min(...values);
  const max = Math.max(...values);
  const width = Math.max((max - min) / bins, 1);
  const result = Array.from({ length: bins }, (_, index) => ({
    x0: min + index * width,
    x1: min + (index + 1) * width,
    count: 0
  }));
  values.forEach((value) => {
    const index = Math.min(Math.floor((value - min) / width), bins - 1);
    result[index].count += 1;
  });
  return result;
}

async function withFallback(databaseWork, fallbackWork) {
  if (databaseEnabled()) {
    try {
      return { source: 'railway', data: await databaseWork() };
    } catch (error) {
      if (!config.fallbackData) throw error;
    }
  }
  return { source: 'fallback', data: fallbackWork() };
}

export function createApp() {
  const app = express();
  const agentRequests = new Map();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '16kb' }));
  app.use(express.static(config.publicDir));

  app.get('/api/health', async (_request, response) => {
    response.json({
      app: 'available',
      database: await databaseHealth(),
      ai: config.agent.enabled && config.agent.apiKey ? 'configured' : 'local_fallback'
    });
  });

  app.get('/api/datasets/evolution', async (request, response, next) => {
    try {
      const { grain } = z.object({ grain: z.enum(['day', 'week', 'month']).default('month') })
        .parse(request.query);
      const result = await withFallback(
        () => query(evolutionQuery(grain, config.api.maxRows)),
        () => aggregateFallbackEvolution(grain).slice(0, config.api.maxRows)
      );
      response.json({ ...result, meta: { grain, unit: 'pedidos', aggregation: 'contagem' } });
    } catch (error) { next(error); }
  });

  app.get('/api/datasets/distribution', async (request, response, next) => {
    try {
      const { bins } = z.object({ bins: boundedInteger(5, 40, 12) }).parse(request.query);
      const result = await withFallback(
        async () => (await query(distributionQuery(config.api.maxRows))).map((row) => Number(row.price)),
        () => fallback.prices
      );
      response.json({ source: result.source, data: histogram(result.data, bins), meta: {
        bins, sampleSize: result.data.length, unit: 'R$', aggregation: 'frequência'
      } });
    } catch (error) { next(error); }
  });

  app.get('/api/datasets/magnitude', async (request, response, next) => {
    try {
      const { top } = z.object({ top: boundedInteger(5, 20, 10) }).parse(request.query);
      const result = await withFallback(
        () => query(magnitudeQuery(top)),
        () => fallback.magnitude.slice(0, top)
      );
      response.json({ ...result, meta: { top, unit: 'R$', aggregation: 'soma de price' } });
    } catch (error) { next(error); }
  });

  app.get('/api/datasets/relation', async (request, response, next) => {
    try {
      const params = z.object({
        limit: boundedInteger(50, config.api.maxRows, 200),
        trimOutliers: z.enum(['true', 'false']).default('false')
      }).parse(request.query);
      const result = await withFallback(
        () => query(relationQuery(params.limit)),
        () => fallback.relation.slice(0, params.limit)
      );
      let data = result.data.map((row) => ({ price: Number(row.price), freight: Number(row.freight) }));
      if (params.trimOutliers === 'true' && data.length) {
        const prices = data.map((row) => row.price).sort((a, b) => a - b);
        const cutoff = prices[Math.floor(prices.length * 0.95)];
        data = data.filter((row) => row.price <= cutoff);
      }
      response.json({ source: result.source, data, meta: {
        sampleSize: data.length, trimmed: params.trimOutliers === 'true', unit: 'R$', aggregation: 'item de pedido'
      } });
    } catch (error) { next(error); }
  });

  app.post('/api/agent', async (request, response) => {
    const now = Date.now();
    const key = request.ip;
    const recent = (agentRequests.get(key) || []).filter((timestamp) => now - timestamp < 60000);
    if (recent.length >= 20) return response.status(429).json({ error: 'rate_limit_exceeded' });
    recent.push(now);
    agentRequests.set(key, recent);
    const parsed = agentRequestSchema.safeParse(request.body);
    if (!parsed.success) return response.status(400).json({ error: 'invalid_agent_request' });
    try {
      return response.json(await critique(parsed.data));
    } catch {
      return response.json({ mode: 'local_after_provider_error', ...localCritique(parsed.data) });
    }
  });

  app.use('/api', (_request, response) => response.status(404).json({ error: 'not_found' }));
  app.use((error, _request, response, _next) => {
    const invalid = error instanceof z.ZodError;
    response.status(invalid ? 400 : 503).json({ error: invalid ? 'invalid_parameters' : 'service_unavailable' });
  });
  return app;
}
