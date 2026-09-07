const assert = require('node:assert');
const pool = require('../src/config/db');
const paymentController = require('../src/controllers/payment.controller');
const payoutService = require('../src/services/payout.service');
const payoutController = require('../src/controllers/payout.controller');
const escrowService = require('../src/services/escrow.service');

let landlordId, tenantId, propertyId, unitId, tenancyId, paymentId;

async function cleanup() {
  const ids = [tenancyId, unitId, propertyId, tenantId, landlordId].filter(Boolean);
  if (tenancyId) await pool.query('DELETE FROM payments WHERE tenancy_id = $1', [tenancyId]);
  if (tenancyId) await pool.query('DELETE FROM ledger_entries WHERE tenancy_id = $1', [tenancyId]);
  if (tenantId) await pool.query('DELETE FROM tenancies WHERE tenant_id = $1', [tenantId]);
  if (landlordId) await pool.query('DELETE FROM escrow_ledger WHERE landlord_id = $1', [landlordId]);
  if (landlordId) await pool.query('DELETE FROM payouts WHERE landlord_id = $1', [landlordId]);
  if (landlordId) await pool.query('DELETE FROM properties WHERE landlord_id = $1', [landlordId]);
  if (tenantId) await pool.query('DELETE FROM users WHERE id = $1', [tenantId]);
  if (landlordId) await pool.query('DELETE FROM users WHERE id = $1', [landlordId]);
}

async function seed() {
  const u = await pool.query(
    `INSERT INTO users (email, password_hash, first_name, last_name, role, phone)
     VALUES ($1, 'x', 'Escrow', 'Test', 'landlord', '0700000000') RETURNING id`,
    [`escrow_test_${Date.now()}@example.com`]
  );
  landlordId = u.rows[0].id;

  const t = await pool.query(
    `INSERT INTO users (email, password_hash, first_name, last_name, role, phone)
     VALUES ($1, 'x', 'Escrow', 'Tenant', 'tenant', '0711111111') RETURNING id`,
    [`escrow_tenant_${Date.now()}@example.com`]
  );
  tenantId = t.rows[0].id;

  const p = await pool.query(
    `INSERT INTO properties (landlord_id, name, address) VALUES ($1, 'Escrow Test Prop', '123 Test') RETURNING id`,
    [landlordId]
  );
  propertyId = p.rows[0].id;

  const un = await pool.query(
    `INSERT INTO units (property_id, unit_number, rent_amount, status)
     VALUES ($1, 'A1', 15000, 'occupied') RETURNING id`,
    [propertyId]
  );
  unitId = un.rows[0].id;

  const tw = await pool.query(
    `INSERT INTO tenancies (unit_id, tenant_id, start_date, status)
     VALUES ($1, $2, CURRENT_DATE, 'active') RETURNING id`,
    [unitId, tenantId]
  );
  tenancyId = tw.rows[0].id;
}

function stubRes() {
  let statusCode = 200;
  return {
    status(c) { statusCode = c; return this; },
    json(d) { this.body = d; },
    getStatusCode: () => statusCode,
  };
}

async function main() {
  await seed();
  console.log('seeded landlord=%d tenant=%d tenancy=%d', landlordId, tenantId, tenancyId);

  // 1. Record a manual cash payment (completed) -> escrow credit
  const res = stubRes();
  const user = { id: tenantId, role: 'tenant' };
  await paymentController.recordPayment({ body: { tenancy_id: tenancyId, amount: 15000, payment_method: 'cash', transaction_ref: `REF${Date.now()}` }, user }, res);
  assert.strictEqual(res.getStatusCode(), 201, 'recordPayment should return 201, got ' + res.getStatusCode() + ' ' + JSON.stringify(res.body));
  paymentId = res.body.payment.id;
  console.log('payment recorded id=%d status=%s', paymentId, res.body.payment.status);

  // 2. Escrow balance should be 15000
  let escrow = await escrowService.getEscrowBalance(landlordId);
  console.log('escrow after payment:', JSON.stringify(escrow));
  assert.strictEqual(escrow.balance, 15000, 'escrow balance should be 15000');

  // 3. Payout balance endpoint reflects escrow
  const bal = await payoutService.getBalance(landlordId);
  assert.strictEqual(bal.success, true);
  assert.strictEqual(bal.data.balance, 15000);
  assert.strictEqual(bal.data.escrow.balance, 15000);
  console.log('payout balance:', JSON.stringify(bal.data));

  // 4. Create a successful payout (M-Pesa) for full amount
  const payRes = stubRes();
  await payoutController.createPayout({ user: { id: landlordId, role: 'landlord' }, body: { amount: 10000, method: 'mpesa', description: 'Withdraw via M-Pesa' } }, payRes);
  assert.strictEqual(payRes.getStatusCode(), 201, 'payout creation should be 201, got ' + payRes.getStatusCode() + ' ' + JSON.stringify(payRes.body));
  console.log('payout created id=%d status=%s', payRes.body.id, payRes.body.status);

  // 5. Balance should now be 5000
  escrow = await escrowService.getEscrowBalance(landlordId);
  console.log('escrow after payout:', JSON.stringify(escrow));
  assert.strictEqual(escrow.balance, 5000, 'escrow should drop to 5000');

  // 6. Overdraw should be rejected
  const bigRes = stubRes();
  await payoutController.createPayout({ user: { id: landlordId, role: 'landlord' }, body: { amount: 99999, method: 'bank_transfer' } }, bigRes);
  console.log('overdraw payout status:', bigRes.getStatusCode(), JSON.stringify(bigRes.body));
  assert.strictEqual(bigRes.getStatusCode(), 400, 'overdraw should be 400');

  // 7. Simulate failed disbursement -> funds reversed into escrow
  const failRes = stubRes();
  await payoutController.updatePayoutStatus({ user: { id: landlordId, role: 'landlord' }, params: { id: payRes.body.id }, body: { status: 'failed' } }, failRes);
  assert.strictEqual(failRes.getStatusCode(), 200, 'fail update should be 200, got ' + failRes.getStatusCode() + ' ' + JSON.stringify(failRes.body));
  escrow = await escrowService.getEscrowBalance(landlordId);
  console.log('escrow after failed payout:', JSON.stringify(escrow));
  assert.strictEqual(escrow.balance, 15000, 'escrow should be restored to 15000 after failure reversal');

  // 8. Ledger history is populated (payment credit + payout debit + reversal credit)
  const ledger = await escrowService.listEscrowLedger(landlordId);
  console.log('ledger entries:', ledger.length, '->', ledger.map(e => `${e.type}:${e.amount}:${e.reference}`).join(' | '));
  assert.strictEqual(ledger.length, 3, 'expected 3 ledger entries (payment credit, payout debit, reversal credit)');

  // 9. Double-failing the same payout must not double-reverse (idempotency)
  const failAgain = stubRes();
  await payoutController.updatePayoutStatus({ user: { id: landlordId, role: 'landlord' }, params: { id: payRes.body.id }, body: { status: 'failed' } }, failAgain);
  escrow = await escrowService.getEscrowBalance(landlordId);
  assert.strictEqual(escrow.balance, 15000, 'double-fail must not double reverse');
  console.log('idempotency check ok: balance still', escrow.balance);

  console.log('\nALL ESCROW INTEGRATION CHECKS PASSED');
  await cleanup();
  await pool.end();
  process.exit(0);
}

main().catch(async (e) => {
  console.error('FAILED:', e);
  try { await cleanup(); } catch (_) {}
  await pool.end();
  process.exit(1);
});
