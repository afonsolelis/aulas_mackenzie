import assert from 'node:assert/strict';
import { after, before, describe, test } from 'node:test';
import { createApp } from '../server/app.js';

let server;
let baseUrl;

before(async () => {
  server = createApp().listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  server.closeAllConnections();
  await new Promise((resolve) => server.close(resolve));
});

async function json(path, options) {
  const response = await fetch(`${baseUrl}${path}`, options);
  return { response, body: await response.json() };
}

describe('health e fallbacks', () => {
  test('health não expõe configuração sensível', async () => {
    const { response, body } = await json('/api/health');
    assert.equal(response.status, 200);
    assert.equal(body.app, 'available');
    assert.match(body.ai, /configured|local_fallback/);
    assert.doesNotMatch(JSON.stringify(body), /DATABASE_URL|OPENAI_API_KEY|postgresql:\/\//);
  });

  test('serve o frontend do laboratório', async () => {
    const response = await fetch(baseUrl);
    assert.equal(response.status, 200);
    assert.match(await response.text(), /Dashboard analítico Olist/);
  });
});

describe('datasets delimitados', () => {
  test('retorna evolução com granularidade permitida', async () => {
    const { response, body } = await json('/api/datasets/evolution?grain=week');
    assert.equal(response.status, 200);
    assert.equal(body.meta.grain, 'week');
    assert.ok(body.data.length > 10);
  });

  test('rejeita tentativa de injeção na granularidade', async () => {
    const { response, body } = await json('/api/datasets/evolution?grain=month%3BDROP%20TABLE%20x');
    assert.equal(response.status, 400);
    assert.equal(body.error, 'invalid_parameters');
  });

  test('limita bins do histograma', async () => {
    const invalid = await json('/api/datasets/distribution?bins=99');
    assert.equal(invalid.response.status, 400);
    const valid = await json('/api/datasets/distribution?bins=8');
    assert.equal(valid.body.data.length, 8);
  });

  test('respeita Top N', async () => {
    const { response, body } = await json('/api/datasets/magnitude?top=5');
    assert.equal(response.status, 200);
    assert.equal(body.data.length, 5);
  });

  test('trata outliers somente por booleano permitido', async () => {
    const { response, body } = await json('/api/datasets/relation?limit=50&trimOutliers=true');
    assert.equal(response.status, 200);
    assert.equal(body.meta.trimmed, true);
    assert.ok(body.data.length <= 50);
    const invalid = await json('/api/datasets/relation?trimOutliers=DROP');
    assert.equal(invalid.response.status, 400);
  });
});

describe('agente seguro', () => {
  test('devolve crítica estruturada sem depender do provedor', async () => {
    const { response, body } = await json('/api/agent', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chartId: 'relation',
        decision: 'Descrevi associação sem afirmar causa.',
        summary: { sampleSize: 100, min: 10, max: 500, mean: 90, median: 55 }
      })
    });
    assert.equal(response.status, 200);
    assert.ok(body.observation && body.caution && body.suggestion);
    assert.match(body.caution, /causalidade/i);
  });

  test('rejeita campos extras e pedidos fora do contrato', async () => {
    const { response, body } = await json('/api/agent', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ chartId: 'sql', decision: 'DROP TABLE', summary: { sampleSize: 1 }, databaseUrl: 'secret' })
    });
    assert.equal(response.status, 400);
    assert.deepEqual(body, { error: 'invalid_agent_request' });
  });

  test('limita chamadas repetidas ao agente', async () => {
    const request = {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ chartId: 'evolution', decision: 'Comparar granularidades antes de publicar.', summary: { sampleSize: 10 } })
    };
    const statuses = [];
    for (let index = 0; index < 25; index += 1) {
      statuses.push((await fetch(`${baseUrl}/api/agent`, request)).status);
    }
    assert.ok(statuses.includes(429));
  });
});
