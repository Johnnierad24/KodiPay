const pool = require('../config/db');

exports.createRequest = async (req, res) => {
  try {
    const { unit_id, tenant_id, title, description, priority, image_urls } = req.body;
    const result = await pool.query(
      `INSERT INTO maintenance_requests (unit_id, tenant_id, title, description, priority, image_urls) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [unit_id, tenant_id, title, description, priority || 'medium', image_urls || []]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create maintenance request' });
  }
};

exports.getRequestsByUnit = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM maintenance_requests WHERE unit_id = $1 ORDER BY created_at DESC', [req.params.unitId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch maintenance requests' });
  }
};

exports.getRequest = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM maintenance_requests WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Maintenance request not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch request' });
  }
};

exports.updateRequest = async (req, res) => {
  try {
    const { title, description, priority } = req.body;
    const result = await pool.query(
      'UPDATE maintenance_requests SET title = $1, description = $2, priority = $3, updated_at = CURRENT_TIMESTAMP WHERE id = $4 RETURNING *',
      [title, description, priority, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Request not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update request' });
  }
};

exports.updateStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const result = await pool.query(
      'UPDATE maintenance_requests SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Request not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update status' });
  }
};
