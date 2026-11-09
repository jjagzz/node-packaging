const test = require('node:test');
const assert = require('node:assert');
const createApp = require('../src/server');

test('health endpoint returns healthy', async () => {
  const server = createApp().listen(0);
  const { port } = server.address();
  const res = await fetch(`http://localhost:${port}/health`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: 'healthy' });
  server.close();
});
