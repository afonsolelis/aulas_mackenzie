import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import { distributionQuery, evolutionQuery, magnitudeQuery, relationQuery } from '../server/catalog.js';
import { histogram } from '../server/app.js';

describe('catálogo SQL', () => {
  test('mantém todos os valores variáveis em parâmetros', () => {
    const queries = [evolutionQuery('month', 500), distributionQuery(500), magnitudeQuery(10), relationQuery(200)];
    queries.forEach((query) => {
      assert.ok(Array.isArray(query.values));
      assert.ok(query.values.length > 0);
      assert.doesNotMatch(query.text, /INSERT|UPDATE|DELETE|DROP|ALTER|CREATE/i);
      assert.match(query.text, /LIMIT \$/);
    });
  });
});

describe('transformações vazias', () => {
  test('histograma vazio não produz Infinity ou NaN', () => {
    assert.deepEqual(histogram([], 12), []);
  });
});
