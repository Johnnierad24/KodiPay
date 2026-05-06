const pool = require('../config/db');

exports.createProperty = async (req, res) => {
  try {
    const { name, address, description } = req.body;
    const landlord_id = req.user?.id; // From JWT middleware (to be added)
    
    const result = await pool.query(
      'INSERT INTO properties (landlord_id, name, address, description) VALUES ($1, $2, $3, $4) RETURNING *',
      [landlord_id, name, address, description]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create property' });
  }
};

exports.getProperties = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM properties WHERE landlord_id = $1', [req.user?.id]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch properties' });
  }
};

exports.getProperty = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM properties WHERE id = $1 AND landlord_id = $2', [req.params.id, req.user?.id]);
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
