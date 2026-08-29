import { createApp } from './app.js';
import { config } from './config.js';
import { closeDatabase } from './database.js';

const server = createApp().listen(config.port, '0.0.0.0', () => {
  console.log(JSON.stringify({ level: 'info', event: 'lab_started', port: config.port }));
});

async function shutdown() {
  server.close(async () => {
    await closeDatabase();
    process.exit(0);
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
