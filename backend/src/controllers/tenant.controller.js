const pool = require('../config/db');

exports.getOverview = async (req, res) => {
  try {
    if (req.user.role !== 'tenant') {
      return res.status(403).json({ error: 'Access denied' });
    }

    const result = await pool.query(
      `SELECT us.first_name, us.last_name,
              p.name AS property_name, p.id AS property_id,
              u.unit_number, u.id AS unit_id, u.rent_amount,
              t.id AS tenancy_id, t.start_date, t.status AS tenancy_status,
              (SELECT COALESCE(SUM(i.amount), 0) FROM invoices i
                WHERE i.tenancy_id = t.id) AS invoiced,
              (SELECT COALESCE(SUM(py.amount), 0) FROM payments py
                WHERE py.tenancy_id = t.id AND py.status = 'completed') AS rent_paid,
              (SELECT MAX(py.payment_date) FROM payments py
                WHERE py.tenancy_id = t.id AND py.status = 'completed') AS last_payment_date
         FROM tenancies t
         JOIN units u ON t.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
         JOIN users us ON t.tenant_id = us.id
        WHERE t.tenant_id = $1 AND t.status = 'active'
        ORDER BY t.start_date DESC
        LIMIT 1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'No active tenancy found' });
    }

    const row = result.rows[0];
    const invoiced = Number(row.invoiced) || 0;
    const expected = invoiced > 0 ? invoiced : Number(row.rent_amount) || 0;
    const paid = Number(row.rent_paid) || 0;
    const outstanding = Math.max(expected - paid, 0);

    const start = row.start_date ? new Date(row.start_date) : null;
    const dueDay = start ? Math.min(Math.max(start.getDate(), 1), 28) : 25;

    res.json({
      tenant_id: req.user.id,
      tenant_name: [row.first_name, row.last_name].filter(Boolean).join(' ') || 'Tenant',
      property_id: row.property_id,
      property_name: row.property_name || '',
      unit_id: row.unit_id,
      unit_number: row.unit_number || '',
      tenancy_id: row.tenancy_id,
      tenancy_status: row.tenancy_status,
      rent_amount: Number(row.rent_amount) || 0,
      rent_expected: expected,
      rent_paid: paid,
      rent_outstanding: outstanding,
      due_day: dueDay,
      rent_status: outstanding > 0 ? 'pending' : 'paid',
      last_payment_date: row.last_payment_date || null,
    });
  } catch (error) {
    console.error('Tenant overview failed:', error.message);
    res.status(500).json({ error: 'Failed to load overview' });
  }
};
