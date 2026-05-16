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

    const result = await pool.query('SELECT * FROM units WHERE property_id = $1', [req.params.propertyId]);
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
