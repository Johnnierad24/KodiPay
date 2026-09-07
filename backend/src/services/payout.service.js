const pool = require('../config/db');
const escrowService = require('./escrow.service');

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
    const amountNum = Number(amount);

    // Reserve the funds in escrow (debit) before recording the payout.
    const debit = await escrowService.createEscrowDebit(
      landlordId,
      amountNum,
      `Payout-${reference || 'pending'}`,
      description || 'Withdrawal to ' + (method || 'payout method')
    );
    if (!debit.success) {
      return { success: false, error: debit.error };
    }

    const result = await pool.query(
      `INSERT INTO payouts (landlord_id, amount, method, status, scheduled_date, reference, description)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [landlordId, amountNum, method, status || 'scheduled', scheduled_date || null, reference || null, description || null]
    );
    return { success: true, data: result.rows[0] };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function getBalance(landlordId) {
  try {
    const escrow = await escrowService.getEscrowBalance(landlordId);
    return {
      success: true,
      data: {
        balance: escrow.balance,
        held: 0,
        escrow: escrow,
      },
    };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

module.exports = { listPayouts, createPayout, getBalance };
