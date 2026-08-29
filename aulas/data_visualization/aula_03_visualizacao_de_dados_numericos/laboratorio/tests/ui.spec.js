import { expect, test } from '@playwright/test';

test('renderiza quatro gráficos, metadados e crítica sem erros', async ({ page }) => {
  const errors = [];
  page.on('console', (message) => { if (message.type() === 'error') errors.push(message.text()); });
  page.on('pageerror', (error) => errors.push(error.message));

  await page.goto('/');
  await expect(page.locator('.chart svg')).toHaveCount(4);
  await expect(page.locator('#dashboard-kpis article')).toHaveCount(4);
  await expect(page.locator('#kpi-magnitude')).not.toHaveText('Carregando');
  await expect(page.locator('.metadata')).toHaveCount(4);
  await expect(page.locator('#evolution-description')).not.toBeEmpty();
  await expect(page.locator('#magnitude-description')).not.toBeEmpty();

  await page.locator('[data-agent="relation"]').click();
  await expect(page.locator('#relation-agent')).toContainText('Observação:');
  expect(errors).toEqual([]);
  expect(await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth)).toBe(false);
});

test('controles alteram decisões analíticas', async ({ page }) => {
  await page.goto('/');
  await page.locator('#evolution-grain').selectOption('week');
  await expect(page.locator('#evolution-description')).toContainText('períodos');
  await page.locator('#distribution-bins').fill('20');
  await expect(page.locator('#distribution-bins-value')).toHaveText('20');
  await expect(page.locator('#distribution-description')).toContainText('20 intervalos');
  await page.locator('#magnitude-top').selectOption('5');
  await expect(page.locator('#magnitude-description')).toContainText('5 categorias');
  await page.locator('#relation-trim').check();
  await expect(page.locator('#relation-meta')).toContainText('P95');
});
