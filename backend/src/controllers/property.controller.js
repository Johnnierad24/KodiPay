const pool = require('../config/db');

exports.createProperty = async (req, res) => {
  try {
    const { name, address, description } = req.body;
    const landlord_id = req.user.id;
    
    const result = await pool.query(
      'INSERT INTO properties (landlord_id, name, address, description) VALUES ($1, $2, $3, $4) RETURNING *',
      [landlord_id, name, address, description]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create property' });
  }
};

const PROPERTY_WITH_STATS_SQL = `
  SELECT
    p.id, p.landlord_id, p.name, p.address, p.description,
    p.created_at, p.updated_at,
    COALESCE(unit_stats.total_units, 0)::int AS total_units,
    COALESCE(unit_stats.occupied_units, 0)::int AS occupied_units,
    COALESCE(unit_stats.vacant_units, 0)::int AS vacant_units,
    COALESCE(unit_stats.monthly_rent, 0)::numeric AS expected_monthly_rent,
    COALESCE(income.this_month_income, 0)::numeric AS this_month_income,
    COALESCE(tenant_count.active_tenants, 0)::int AS active_tenants
  FROM properties p
  LEFT JOIN LATERAL (
    SELECT
      COUNT(*) AS total_units,
      COUNT(*) FILTER (WHERE status = 'occupied') AS occupied_units,
      COUNT(*) FILTER (WHERE status = 'vacant') AS vacant_units,
      SUM(CASE WHEN status = 'occupied' THEN rent_amount ELSE 0 END) AS monthly_rent
    FROM units WHERE property_id = p.id
  ) unit_stats ON TRUE
  LEFT JOIN LATERAL (
    SELECT COALESCE(SUM(pay.amount), 0) AS this_month_income
    FROM payments pay
    JOIN tenancies t ON pay.tenancy_id = t.id
    JOIN units u ON t.unit_id = u.id
    WHERE u.property_id = p.id
      AND pay.status = 'completed'
      AND pay.payment_date >= date_trunc('month', CURRENT_DATE)
  ) income ON TRUE
  LEFT JOIN LATERAL (
    SELECT COUNT(DISTINCT t.tenant_id) AS active_tenants
    FROM tenancies t
    JOIN units u ON t.unit_id = u.id
    WHERE u.property_id = p.id AND t.status = 'active'
  ) tenant_count ON TRUE
`;

exports.getProperties = async (req, res) => {
  try {
    const result = await pool.query(
      `${PROPERTY_WITH_STATS_SQL} WHERE p.landlord_id = $1 ORDER BY p.name`,
      [req.user?.id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch properties' });
  }
};

exports.getProperty = async (req, res) => {
  try {
    const result = await pool.query(
      `${PROPERTY_WITH_STATS_SQL} WHERE p.id = $1 AND p.landlord_id = $2`,
      [req.params.id, req.user?.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Property not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch property' });
  }
};

exports.updateProperty = async (req, res) => {
  try {
    const { name, address, description } = req.body;
    const result = await pool.query(
      'UPDATE properties SET name = $1, address = $2, description = $3, updated_at = CURRENT_TIMESTAMP WHERE id = $4 AND landlord_id = $5 RETURNING *',
      [name, address, description, req.params.id, req.user?.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Property not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update property' });
  }
};

exports.deleteProperty = async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM properties WHERE id = $1 AND landlord_id = $2 RETURNING id', [req.params.id, req.user?.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Property not found' });
    res.json({ message: 'Property deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete property' });
  }
};
