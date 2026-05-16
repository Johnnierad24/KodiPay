const pool = require('../config/db');
const { getUnitAccess, ownsProperty } = require('../utils/access-control');

async function getMaintenanceAccess(requestId) {
  const result = await pool.query(
    `SELECT mr.id, mr.tenant_id, p.landlord_id
     FROM maintenance_requests mr
     JOIN units u ON mr.unit_id = u.id
     JOIN properties p ON u.property_id = p.id
     WHERE mr.id = $1`,
    [requestId]
  );

  return result.rows[0] || null;
}

async function tenantOccupiesUnit(userId, unitId) {
  const result = await pool.query(
    `SELECT id FROM tenancies
     WHERE tenant_id = $1 AND unit_id = $2 AND status = 'active'
     LIMIT 1`,
    [userId, unitId]
  );

  return result.rows.length > 0;
}

function canAccessMaintenance(user, access) {
  if (!access) return false;
  if (user.role === 'tenant') return access.tenant_id === user.id;
  if (['landlord', 'agent'].includes(user.role)) return access.landlord_id === user.id;
  return false;
}

exports.createRequest = async (req, res) => {
  try {
    const { unit_id, tenant_id, title, description, priority, image_urls } = req.body;
    const unitAccess = await getUnitAccess(pool, unit_id);
    const requestTenantId = req.user.role === 'tenant' ? req.user.id : tenant_id;

    if (!unitAccess) return res.status(404).json({ error: 'Unit not found' });
    if (req.user.role === 'tenant' && !(await tenantOccupiesUnit(req.user.id, unit_id))) {
      return res.status(403).json({ error: 'Access denied' });
    }
    if (['landlord', 'agent'].includes(req.user.role) && !ownsProperty(req.user, unitAccess)) {
      return res.status(403).json({ error: 'Access denied' });
    }
    if (!requestTenantId) return res.status(400).json({ error: 'Tenant is required' });

    const result = await pool.query(
      `INSERT INTO maintenance_requests (unit_id, tenant_id, title, description, priority, image_urls) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [unit_id, requestTenantId, title, description, priority || 'medium', image_urls || []]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create maintenance request' });
  }
};

exports.getRequestsByUnit = async (req, res) => {
  try {
    const unitAccess = await getUnitAccess(pool, req.params.unitId);

    if (!unitAccess) return res.status(404).json({ error: 'Unit not found' });
    if (req.user.role === 'tenant' && !(await tenantOccupiesUnit(req.user.id, req.params.unitId))) {
      return res.status(403).json({ error: 'Access denied' });
    }
    if (['landlord', 'agent'].includes(req.user.role) && !ownsProperty(req.user, unitAccess)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const result = await pool.query('SELECT * FROM maintenance_requests WHERE unit_id = $1 ORDER BY created_at DESC', [req.params.unitId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch maintenance requests' });
  }
};

exports.getRequest = async (req, res) => {
  try {
    const access = await getMaintenanceAccess(req.params.id);

    if (!access) return res.status(404).json({ error: 'Maintenance request not found' });
    if (!canAccessMaintenance(req.user, access)) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query('SELECT * FROM maintenance_requests WHERE id = $1', [req.params.id]);
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch request' });
  }
};

exports.updateRequest = async (req, res) => {
  try {
    const { title, description, priority } = req.body;
    const access = await getMaintenanceAccess(req.params.id);

    if (!access) return res.status(404).json({ error: 'Request not found' });
    if (!canAccessMaintenance(req.user, access)) return res.status(403).json({ error: 'Access denied' });

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
    const access = await getMaintenanceAccess(req.params.id);

    if (!access) return res.status(404).json({ error: 'Request not found' });
    if (!canAccessMaintenance(req.user, access)) return res.status(403).json({ error: 'Access denied' });

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
