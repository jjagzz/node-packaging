const express = require('express');
const cfg = require('./config');
const { version } = require('../package.json');

function createApp() {
  const app = express();
  app.get('/', (req, res) =>
    res.json({ app: cfg.appName, version, environment: cfg.env, debug: cfg.debug })
  );
  app.get('/health', (req, res) => res.json({ status: 'healthy' }));
  return app;
}

if (require.main === module) {
  createApp().listen(cfg.port, () =>
    console.log(`${cfg.appName} v${version} [${cfg.env}] on port ${cfg.port}`)
  );
}

module.exports = createApp;
