const pool = require('../config/db');

async function listPayouts(landlordId) {
  try {
    const result = await pool.query(
      `SELECT id, amount, method, status, reference, scheduled_date, completed_date, description, created_at
       FROM payouts
       WHERE landlord_id = $1
       ORDER BY created_at DESC`,
      [landlordId]
    );
    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function createPayout(landlordId, { amount, method, status, scheduled_date, reference, description }) {
  try {
    const result = await pool.query(
      `INSERT INTO payouts (landlord_id, amount, method, status, scheduled_date, reference, description)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [landlordId, amount, method, status || 'scheduled', scheduled_date || null, reference || null, description || null]
    );
    return { success: true, data: result.rows[0] };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function getBalance(landlordId) {
  try {
    const paidResult = await pool.query(
      `SELECT COALESCE(SUM(pay.amount), 0) AS total
       FROM payments pay
       JOIN tenancies t ON pay.tenancy_id = t.id
       JOIN units u ON t.unit_id = u.id
       JOIN properties p ON u.property_id = p.id
       WHERE p.landlord_id = $1
         AND pay.status = 'completed'`,
      [landlordId]
    );

    const payoutResult = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) AS total
       FROM payouts
       WHERE landlord_id = $1
         AND status != 'failed'`,
      [landlordId]
    );

    const paidIncoming = Number(paidResult.rows[0].total) || 0;
    const payoutsOut = Number(payoutResult.rows[0].total) || 0;
    const balance = Math.round((paidIncoming - payoutsOut) * 100) / 100;

    return { success: true, data: { balance, held: 0 } };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

module.exports = { listPayouts, createPayout, getBalance };
