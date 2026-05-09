const pool = require('../config/db');
const { generateInvoice, generateMonthlyInvoices } = require('../services/invoice.service');

exports.createInvoice = async (req, res) => {
  try {
    const { tenancy_id, month, year } = req.body;
    const result = await generateInvoice(tenancy_id, month, year);
    if (!result.success) return res.status(400).json({ error: result.error });
    res.status(201).json(result.invoice);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create invoice' });
  }
};

exports.getInvoices = async (req, res) => {
  try {
    const isTenant = req.user.role === 'tenant';
    const result = await pool.query(`
      SELECT i.*, t.tenant_id, u.first_name, u.last_name, u.email, un.unit_number, p.name as property_name
      FROM invoices i
      JOIN tenancies t ON i.tenancy_id = t.id
      JOIN units un ON t.unit_id = un.id
      JOIN properties p ON un.property_id = p.id
      JOIN users u ON t.tenant_id = u.id
      WHERE ${isTenant ? 't.tenant_id = $1' : 'p.landlord_id = $1'}
      ORDER BY i.year DESC, i.month DESC
    `, [req.user.id]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch invoices' });
  }
};

exports.getInvoice = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT i.*, t.tenant_id, u.first_name, u.last_name, u.email, un.unit_number, p.name as property_name
      FROM invoices i
      JOIN tenancies t ON i.tenancy_id = t.id
      JOIN units un ON t.unit_id = un.id
      JOIN properties p ON un.property_id = p.id
      JOIN users u ON t.tenant_id = u.id
      WHERE i.id = $1
    `, [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Invoice not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch invoice' });
  }
};

exports.updateInvoiceStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const result = await pool.query(
      'UPDATE invoices SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Invoice not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update invoice' });
  }
};

exports.generateMonthly = async (req, res) => {
  try {
    const result = await generateMonthlyInvoices();
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: 'Failed to generate monthly invoices' });
  }
};
