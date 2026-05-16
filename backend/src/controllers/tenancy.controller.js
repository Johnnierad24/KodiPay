const pool = require('../config/db');
const { getTenancyAccess, getUnitAccess, canReadTenancy, ownsProperty } = require('../utils/access-control');

exports.createTenancy = async (req, res) => {
  try {
    const { unit_id, tenant_id, start_date, end_date } = req.body;
    const unitAccess = await getUnitAccess(pool, unit_id);

    if (!unitAccess) return res.status(404).json({ error: 'Unit not found' });
    if (!ownsProperty(req.user, unitAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query(
      `INSERT INTO tenancies (unit_id, tenant_id, start_date, end_date) 
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [unit_id, tenant_id, start_date, end_date]
    );
    
    await pool.query('UPDATE units SET status = $1 WHERE id = $2', ['occupied', unit_id]);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create tenancy' });
  }
};

exports.getTenancies = async (req, res) => {
  try {
    const isTenant = req.user.role === 'tenant';
    const query = `
      SELECT t.*, u.unit_number, p.name as property_name, 
             us.first_name, us.last_name, us.email as tenant_email
      FROM tenancies t
      JOIN units u ON t.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      JOIN users us ON t.tenant_id = us.id
      WHERE ${isTenant ? 't.tenant_id = $1' : 'p.landlord_id = $1'}
    `;

    const result = await pool.query(query, [req.user.id]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch tenancies' });
  }
};

exports.getTenancy = async (req, res) => {
  try {
    const tenancyAccess = await getTenancyAccess(pool, req.params.id);

    if (!tenancyAccess) return res.status(404).json({ error: 'Tenancy not found' });
    if (!canReadTenancy(req.user, tenancyAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query('SELECT * FROM tenancies WHERE id = $1', [req.params.id]);
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch tenancy' });
  }
};

exports.updateTenancy = async (req, res) => {
  try {
    const { end_date, status } = req.body;
    const tenancyAccess = await getTenancyAccess(pool, req.params.id);

    if (!tenancyAccess) return res.status(404).json({ error: 'Tenancy not found' });
    if (!ownsProperty(req.user, tenancyAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query(
      'UPDATE tenancies SET end_date = $1, status = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3 RETURNING *',
      [end_date, status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Tenancy not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update tenancy' });
  }
};

exports.endTenancy = async (req, res) => {
  try {
    const tenancyAccess = await getTenancyAccess(pool, req.params.id);

    if (!tenancyAccess) return res.status(404).json({ error: 'Tenancy not found' });
    if (!ownsProperty(req.user, tenancyAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query('UPDATE tenancies SET status = $1, end_date = CURRENT_DATE, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *', ['ended', req.params.id]);
    if (result.rows.length > 0) {
      await pool.query('UPDATE units SET status = $1 WHERE id = (SELECT unit_id FROM tenancies WHERE id = $2)', ['vacant', req.params.id]);
    }
    if (result.rows.length === 0) return res.status(404).json({ error: 'Tenancy not found' });
    res.json({ message: 'Tenancy ended successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to end tenancy' });
  }
};
