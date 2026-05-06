const pool = require('../config/db');

async function generateInvoice(tenancyId, month, year) {
  try {
    const tenancyResult = await pool.query(`
      SELECT t.*, u.unit_number, u.rent_amount, p.name as property_name, 
             us.first_name, us.last_name, us.email, us.phone
      FROM tenancies t
      JOIN units u ON t.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      JOIN users us ON t.tenant_id = us.id
      WHERE t.id = $1 AND t.status = 'active'
    `, [tenancyId]);

    if (tenancyResult.rows.length === 0) return { success: false, error: 'Tenancy not found' };

    const tenancy = tenancyResult.rows[0];

    const existingInvoice = await pool.query(
      'SELECT id FROM invoices WHERE tenancy_id = $1 AND month = $2 AND year = $3',
      [tenancyId, month, year]
    );

    if (existingInvoice.rows.length > 0) {
      return { success: false, error: 'Invoice already exists for this period' };
    }

    const invoiceResult = await pool.query(`
      INSERT INTO invoices (tenancy_id, month, year, amount, due_date, status)
      VALUES ($1, $2, $3, $4, $5, 'pending')
      RETURNING *
    `, [
      tenancyId,
      month,
      year,
      tenancy.rent_amount,
      new Date(year, month, 5)
    ]);

    await pool.query(
      'INSERT INTO notifications (user_id, type, title, message, related_id, related_type) VALUES ($1, $2, $3, $4, $5, $6)',
      [
        tenancy.tenant_id,
        'invoice',
        'New Invoice Generated',
        `Invoice for ${month}/${year} - Amount: KES ${tenancy.rent_amount}`,
        invoiceResult.rows[0].id,
        'invoice'
      ]
    );

    return { success: true, invoice: invoiceResult.rows[0] };
  } catch (error) {
    console.error('Invoice generation failed:', error.message);
    return { success: false, error: error.message };
  }
}

async function generateMonthlyInvoices() {
  try {
    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();

    const activeTenancies = await pool.query(
      "SELECT id FROM tenancies WHERE status = 'active'"
    );

    const results = [];
    for (const tenancy of activeTenancies.rows) {
      const result = await generateInvoice(tenancy.id, month, year);
      results.push({ tenancyId: tenancy.id, ...result });
    }

    return { success: true, processed: results.length, results };
  } catch (error) {
    console.error('Monthly invoice generation failed:', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = { generateInvoice, generateMonthlyInvoices };
