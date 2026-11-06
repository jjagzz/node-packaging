const fs = require('fs');
const path = require('path');

const env = process.env.APP_ENV || 'development';
if (!['development', 'staging', 'production'].includes(env)) {
  throw new Error(`Invalid APP_ENV: ${env}`);
}

// Config lives OUTSIDE the package, in a folder you point to
const dir = process.env.APP_CONFIG_DIR || path.join(process.cwd(), 'config');
const file = path.join(dir, `${env}.json`);
const fromFile = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : {};

module.exports = {
  env,
  appName: process.env.APP_NAME || fromFile.appName || 'node-demo',
  port: Number(process.env.PORT || fromFile.port || 3000),
  debug: String(process.env.DEBUG || fromFile.debug || false) === 'true',
};
