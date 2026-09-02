const pool = require('../config/db');

async function listBillsForTenancy(tenancyId) {
  try {
    const result = await pool.query(
      `SELECT id, bill_type, title, amount, due_date, status, description, created_at
       FROM bills
       WHERE tenancy_id = $1
       ORDER BY created_at DESC`,
      [tenancyId]
    );
    return { success: true, data: result.rows };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function createBill({ tenancy_id, bill_type, title, amount, due_date, status, description }) {
  try {
    const result = await pool.query(
      `INSERT INTO bills (tenancy_id, bill_type, title, amount, due_date, status, description)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [tenancy_id, bill_type, title, amount, due_date || null, status || 'pending', description || null]
    );
    return { success: true, data: result.rows[0] };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function updateBillStatus(billId, status) {
  try {
    const result = await pool.query(
      'UPDATE bills SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, billId]
    );
    if (result.rows.length === 0) return { success: false, error: 'Bill not found' };
    return { success: true, data: result.rows[0] };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function deleteBill(billId) {
  try {
    const result = await pool.query(
      'DELETE FROM bills WHERE id = $1 RETURNING id',
      [billId]
    );
    if (result.rows.length === 0) return { success: false, error: 'Bill not found' };
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

module.exports = { listBillsForTenancy, createBill, updateBillStatus, deleteBill };
