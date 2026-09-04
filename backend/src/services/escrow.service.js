const pool = require('../config/db');

// For a given payment, derive the owning landlord id so the escrow credit can
// be applied to the correct account.
async function getLandlordIdForPayment(paymentId) {
  const result = await pool.query(
    `SELECT p.landlord_id
     FROM payments pay
     JOIN tenancies t ON pay.tenancy_id = t.id
     JOIN units u ON t.unit_id = u.id
     JOIN properties p ON u.property_id = p.id
     WHERE pay.id = $1`,
    [paymentId]
  );
  if (result.rows.length === 0) return null;
  return result.rows[0].landlord_id;
}

// Returns the landlord's current escrow balance (sum of credits minus debits).
async function getEscrowBalance(landlordId) {
  const result = await pool.query(
    `SELECT
       COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END), 0) AS credits,
       COALESCE(SUM(CASE WHEN type = 'debit' THEN amount ELSE 0 END), 0) AS debits
     FROM escrow_ledger
     WHERE landlord_id = $1`,
    [landlordId]
  );
  const credits = Number(result.rows[0].credits) || 0;
  const debits = Number(result.rows[0].debits) || 0;
  const balance = Math.round((credits - debits) * 100) / 100;
  return { balance, credits, debits };
}

// Completing a tenant payment credits the landlord's escrow balance.
async function creditEscrow(landlordId, amount, reference, description) {
  await pool.query(
    `INSERT INTO escrow_ledger (landlord_id, type, amount, reference, description)
     VALUES ($1, 'credit', $2, $3, $4)`,
    [landlordId, amount, reference, description]
  );
  return getEscrowBalance(landlordId);
}

// Creating a payout debits (holds) the money from escrow. Validates the
// landlord has sufficient balance; returns an error object otherwise.
async function createEscrowDebit(landlordId, amount, reference, description) {
  const { balance } = await getEscrowBalance(landlordId);
  if (Number(amount) > balance) {
    return { success: false, error: 'Insufficient escrow balance' };
  }
  await pool.query(
    `INSERT INTO escrow_ledger (landlord_id, type, amount, reference, description)
     VALUES ($1, 'debit', $2, $3, $4)`,
    [landlordId, amount, reference, description]
  );
  return { success: true, data: await getEscrowBalance(landlordId) };
}

// If a payout fails, return the held funds to the landlord's escrow balance.
async function reverseEscrowDebit(landlordId, amount, reference, description) {
  await pool.query(
    `INSERT INTO escrow_ledger (landlord_id, type, amount, reference, description)
     VALUES ($1, 'credit', $2, $3, $4)`,
    [landlordId, amount, reference, description || 'Payout reversed / returned to escrow']
  );
  return getEscrowBalance(landlordId);
}

// Full escrow ledger history for a landlord, most recent first.
async function listEscrowLedger(landlordId, limit = 50) {
  const result = await pool.query(
    `SELECT id, type, amount, reference, description, created_at
     FROM escrow_ledger
     WHERE landlord_id = $1
     ORDER BY created_at DESC, id DESC
     LIMIT $2`,
    [landlordId, limit]
  );
  return result.rows;
}

module.exports = {
  getLandlordIdForPayment,
  getEscrowBalance,
  creditEscrow,
  createEscrowDebit,
  reverseEscrowDebit,
  listEscrowLedger,
};
