const { test } = require('node:test');
const assert = require('node:assert');
const path = require('node:path');

// Load the config fresh with a given MPESA_ENV. require() caches modules, so we
// clear the cache between cases to re-evaluate the env-dependent URLs.
function loadConfig(mpesaEnv) {
  const configPath = path.join(__dirname, 'mpesa.js');
  delete require.cache[require.resolve(configPath)];
  process.env.MPESA_ENV = mpesaEnv;
  return require(configPath);
}

test('sandbox env points all Daraja URLs at the sandbox host', () => {
  const cfg = loadConfig('sandbox');
  assert.ok(cfg.authUrl.startsWith('https://sandbox.safaricom.co.ke'));
  assert.ok(cfg.stkPushUrl.startsWith('https://sandbox.safaricom.co.ke'));
  assert.ok(cfg.stkQueryUrl.startsWith('https://sandbox.safaricom.co.ke'));
  assert.strictEqual(cfg.environment, 'sandbox');
});

test('production env points all Daraja URLs at the live host', () => {
  const cfg = loadConfig('production');
  assert.ok(cfg.authUrl.startsWith('https://api.safaricom.co.ke'));
  assert.ok(cfg.stkPushUrl.startsWith('https://api.safaricom.co.ke'));
  assert.ok(cfg.stkQueryUrl.startsWith('https://api.safaricom.co.ke'));
  assert.strictEqual(cfg.environment, 'production');
});

test('unknown env falls back to sandbox (never accidentally live)', () => {
  const cfg = loadConfig('staging');
  assert.strictEqual(cfg.environment, 'sandbox');
  assert.ok(cfg.stkPushUrl.startsWith('https://sandbox.safaricom.co.ke'));
});

// Reload the config with a given MPESA_SHORTCODE_TYPE.
function loadConfigWithShortCodeType(type) {
  const configPath = path.join(__dirname, 'mpesa.js');
  delete require.cache[require.resolve(configPath)];
  process.env.MPESA_SHORTCODE_TYPE = type;
  return require(configPath);
}

test('paybill shortcode maps to CustomerPayBillOnline', () => {
  const cfg = loadConfigWithShortCodeType('paybill');
  assert.strictEqual(cfg.shortCodeType, 'paybill');
  assert.strictEqual(cfg.transactionType, 'CustomerPayBillOnline');
});

test('till shortcode maps to CustomerBuyGoodsOnline', () => {
  const cfg = loadConfigWithShortCodeType('till');
  assert.strictEqual(cfg.shortCodeType, 'till');
  assert.strictEqual(cfg.transactionType, 'CustomerBuyGoodsOnline');
});

test('unset/invalid shortcode type defaults to paybill', () => {
  const cfg = loadConfigWithShortCodeType('something-else');
  assert.strictEqual(cfg.shortCodeType, 'paybill');
  assert.strictEqual(cfg.transactionType, 'CustomerPayBillOnline');
});
