const pool = require('../config/db');
const { getPropertyAccess, getUnitAccess, ownsProperty } = require('../utils/access-control');

exports.createUnit = async (req, res) => {
  try {
    const { property_id, unit_number, rent_amount, deposit_amount } = req.body;
    const propertyAccess = await getPropertyAccess(pool, property_id);

    if (!propertyAccess) return res.status(404).json({ error: 'Property not found' });
    if (!ownsProperty(req.user, propertyAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query(
      'INSERT INTO units (property_id, unit_number, rent_amount, deposit_amount) VALUES ($1, $2, $3, $4) RETURNING *',
      [property_id, unit_number, rent_amount, deposit_amount]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    if (error.code === '23505') return res.status(400).json({ error: 'Unit number already exists for this property' });
    res.status(500).json({ error: 'Failed to create unit' });
  }
};

exports.getUnitsByProperty = async (req, res) => {
  try {
    const propertyAccess = await getPropertyAccess(pool, req.params.propertyId);

    if (!propertyAccess) return res.status(404).json({ error: 'Property not found' });
    if (!ownsProperty(req.user, propertyAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query(
      `SELECT
         u.id, u.property_id, u.unit_number, u.rent_amount, u.deposit_amount, u.status,
         u.created_at, u.updated_at,
         active.tenancy_id, active.tenant_id, active.tenant_name, active.tenant_phone,
         active.start_date,
         COALESCE(arrears.unpaid_count, 0)::int AS unpaid_invoices,
         COALESCE(arrears.arrears_amount, 0)::numeric AS arrears_amount,
         COALESCE(arrears.overdue_count, 0)::int AS overdue_invoices,
         latest_payment.last_payment_date
       FROM units u
       LEFT JOIN LATERAL (
         SELECT
           t.id AS tenancy_id,
           t.tenant_id,
           t.start_date,
           us.first_name || ' ' || us.last_name AS tenant_name,
           us.phone AS tenant_phone
         FROM tenancies t
         JOIN users us ON us.id = t.tenant_id
         WHERE t.unit_id = u.id AND t.status = 'active'
         ORDER BY t.start_date DESC
         LIMIT 1
       ) active ON TRUE
       LEFT JOIN LATERAL (
         SELECT
           COUNT(*) FILTER (WHERE i.status IN ('pending', 'overdue')) AS unpaid_count,
           COUNT(*) FILTER (WHERE i.status IN ('pending', 'overdue') AND i.due_date < CURRENT_DATE) AS overdue_count,
           SUM(i.amount) FILTER (WHERE i.status IN ('pending', 'overdue')) AS arrears_amount
         FROM invoices i
         WHERE i.tenancy_id = active.tenancy_id
       ) arrears ON TRUE
       LEFT JOIN LATERAL (
         SELECT MAX(pay.payment_date) AS last_payment_date
         FROM payments pay
         WHERE pay.tenancy_id = active.tenancy_id AND pay.status = 'completed'
       ) latest_payment ON TRUE
       WHERE u.property_id = $1
       ORDER BY u.unit_number`,
      [req.params.propertyId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch units' });
  }
};

exports.getUnit = async (req, res) => {
  try {
    const unitAccess = await getUnitAccess(pool, req.params.id);

    if (!unitAccess) return res.status(404).json({ error: 'Unit not found' });
    if (!ownsProperty(req.user, unitAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query('SELECT * FROM units WHERE id = $1', [req.params.id]);
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch unit' });
  }
};

exports.updateUnit = async (req, res) => {
  try {
    const { unit_number, rent_amount, deposit_amount, status } = req.body;
    const unitAccess = await getUnitAccess(pool, req.params.id);

    if (!unitAccess) return res.status(404).json({ error: 'Unit not found' });
    if (!ownsProperty(req.user, unitAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query(
      'UPDATE units SET unit_number = $1, rent_amount = $2, deposit_amount = $3, status = $4, updated_at = CURRENT_TIMESTAMP WHERE id = $5 RETURNING *',
      [unit_number, rent_amount, deposit_amount, status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Unit not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update unit' });
  }
};

exports.deleteUnit = async (req, res) => {
  try {
    const unitAccess = await getUnitAccess(pool, req.params.id);

    if (!unitAccess) return res.status(404).json({ error: 'Unit not found' });
    if (!ownsProperty(req.user, unitAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query('DELETE FROM units WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Unit not found' });
    res.json({ message: 'Unit deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete unit' });
  }
};
