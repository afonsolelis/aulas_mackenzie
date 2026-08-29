import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './aulas/data_visualization/aula_03_visualizacao_de_dados_numericos/laboratorio/tests',
  testMatch: '**/*.spec.js',
  fullyParallel: false,
  reporter: 'list',
  use: { baseURL: 'http://127.0.0.1:3000', trace: 'on-first-retry' },
  webServer: {
    command: 'npm run lab:aula03',
    url: 'http://127.0.0.1:3000/api/health',
    reuseExistingServer: false,
    timeout: 15000
  },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile', use: { ...devices['Pixel 5'] } }
  ]
});
