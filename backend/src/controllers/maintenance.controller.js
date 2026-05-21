const pool = require('../config/db');
const { getUnitAccess, ownsProperty } = require('../utils/access-control');

const ALLOWED_CATEGORIES = ['electrical', 'structural', 'plumbing', 'other'];
const ALLOWED_PRIORITIES = ['low', 'medium', 'high', 'urgent', 'emergency'];

async function getMaintenanceAccess(requestId) {
  const result = await pool.query(
    `SELECT mr.id, mr.tenant_id, p.id AS property_id, p.landlord_id
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

async function caretakerCoversProperty(caretakerId, propertyId) {
  const result = await pool.query(
    'SELECT id FROM caretaker_assignments WHERE caretaker_id = $1 AND property_id = $2 LIMIT 1',
    [caretakerId, propertyId]
  );
  return result.rows.length > 0;
}

async function canAccessMaintenance(user, access) {
  if (!access) return false;
  if (user.role === 'tenant') return access.tenant_id === user.id;
  if (['landlord', 'agent'].includes(user.role)) return access.landlord_id === user.id;
  if (user.role === 'caretaker') {
    return caretakerCoversProperty(user.id, access.property_id);
  }
  return false;
}

function normalizeCategory(value) {
  if (!value) return 'other';
  const v = String(value).toLowerCase();
  return ALLOWED_CATEGORIES.includes(v) ? v : 'other';
}

function normalizePriority(value) {
  if (!value) return 'medium';
  const v = String(value).toLowerCase();
  return ALLOWED_PRIORITIES.includes(v) ? v : 'medium';
}

exports.createRequest = async (req, res) => {
  try {
    const { unit_id, tenant_id, title, description, priority, category, image_urls } = req.body;
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
      `INSERT INTO maintenance_requests (unit_id, tenant_id, title, description, category, priority, image_urls)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [
        unit_id,
        requestTenantId,
        title,
        description,
        normalizeCategory(category),
        normalizePriority(priority),
        image_urls || [],
      ]
    );

    if (req.user.role === 'tenant') {
      try {
        const isEmergency = normalizePriority(priority) === 'emergency';
        const notifType = isEmergency ? 'alert' : 'maintenance';
        const notifTitle = isEmergency
          ? 'Emergency reported'
          : 'New maintenance request';
        const tenantInfo = await pool.query(
          `SELECT us.first_name, us.last_name, un.unit_number, p.name AS property_name
             FROM users us, units un, properties p
            WHERE us.id = $1 AND un.id = $2 AND un.property_id = p.id`,
          [req.user.id, unit_id]
        );
        const t = tenantInfo.rows[0] || {};
        const tenantName = `${t.first_name || ''} ${t.last_name || ''}`.trim() || 'A tenant';
        const where = t.unit_number
          ? `${t.property_name || ''} • Unit ${t.unit_number}`.trim()
          : t.property_name || '';
        const message = `${tenantName} reported "${title}"${where ? ' at ' + where : ''}.`;
        await pool.query(
          `INSERT INTO notifications (user_id, type, title, message, related_id, related_type)
           VALUES ($1, $2, $3, $4, $5, 'maintenance_request')`,
          [unitAccess.landlord_id, notifType, notifTitle, message, result.rows[0].id]
        );
      } catch (notifyErr) {
        console.error('Maintenance create notification failed:', notifyErr.message);
      }
    }

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('createRequest failed:', error.message);
    res.status(500).json({ error: 'Failed to create maintenance request' });
  }
};

exports.getMyRequests = async (req, res) => {
  try {
    const priorityFilter = req.query.priority
      ? String(req.query.priority).toLowerCase()
      : null;
    if (priorityFilter && !ALLOWED_PRIORITIES.includes(priorityFilter)) {
      return res.status(400).json({ error: 'Invalid priority filter' });
    }

    if (req.user.role === 'tenant') {
      const params = [req.user.id];
      let priorityClause = '';
      if (priorityFilter) {
        params.push(priorityFilter);
        priorityClause = ` AND mr.priority = $${params.length}`;
      }
      const result = await pool.query(
        `SELECT mr.*, u.unit_number, p.name AS property_name
         FROM maintenance_requests mr
         JOIN units u ON mr.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
         WHERE mr.tenant_id = $1${priorityClause}
         ORDER BY mr.created_at DESC`,
        params
      );
      return res.json(result.rows);
    }

    if (['landlord', 'agent'].includes(req.user.role)) {
      const params = [req.user.id];
      let priorityClause = '';
      if (priorityFilter) {
        params.push(priorityFilter);
        priorityClause = ` AND mr.priority = $${params.length}`;
      }
      const result = await pool.query(
        `SELECT mr.*, u.unit_number, p.name AS property_name,
                us.first_name AS tenant_first_name, us.last_name AS tenant_last_name,
                us.phone AS tenant_phone, us.email AS tenant_email
         FROM maintenance_requests mr
         JOIN units u ON mr.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
         JOIN users us ON mr.tenant_id = us.id
         WHERE p.landlord_id = $1${priorityClause}
         ORDER BY mr.created_at DESC`,
        params
      );
      return res.json(result.rows);
    }

    if (req.user.role === 'caretaker') {
      const params = [req.user.id];
      let priorityClause = '';
      if (priorityFilter) {
        params.push(priorityFilter);
        priorityClause = ` AND mr.priority = $${params.length}`;
      }
      const result = await pool.query(
        `SELECT mr.*, u.unit_number, p.name AS property_name,
                us.first_name AS tenant_first_name, us.last_name AS tenant_last_name,
                us.phone AS tenant_phone, us.email AS tenant_email
         FROM maintenance_requests mr
         JOIN units u ON mr.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
         JOIN users us ON mr.tenant_id = us.id
         JOIN caretaker_assignments ca ON ca.property_id = p.id
         WHERE ca.caretaker_id = $1${priorityClause}
         ORDER BY mr.created_at DESC`,
        params
      );
      return res.json(result.rows);
    }

    res.json([]);
  } catch (error) {
    console.error('getMyRequests failed:', error.message);
    res.status(500).json({ error: 'Failed to fetch maintenance requests' });
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
    if (!(await canAccessMaintenance(req.user, access))) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query(
      `SELECT mr.*, u.unit_number, p.name AS property_name,
              us.first_name AS tenant_first_name, us.last_name AS tenant_last_name,
              us.phone AS tenant_phone, us.email AS tenant_email
       FROM maintenance_requests mr
       JOIN units u ON mr.unit_id = u.id
       JOIN properties p ON u.property_id = p.id
       JOIN users us ON mr.tenant_id = us.id
       WHERE mr.id = $1`,
      [req.params.id]
    );
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch request' });
  }
};

exports.updateRequest = async (req, res) => {
  try {
    const { title, description, priority, category } = req.body;
    const access = await getMaintenanceAccess(req.params.id);

    if (!access) return res.status(404).json({ error: 'Request not found' });
    if (!(await canAccessMaintenance(req.user, access))) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query(
      `UPDATE maintenance_requests
         SET title = COALESCE($1, title),
             description = COALESCE($2, description),
             priority = $3,
             category = $4,
             updated_at = CURRENT_TIMESTAMP
       WHERE id = $5 RETURNING *`,
      [
        title ?? null,
        description ?? null,
        normalizePriority(priority),
        normalizeCategory(category),
        req.params.id,
      ]
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
    if (!(await canAccessMaintenance(req.user, access))) return res.status(403).json({ error: 'Access denied' });

    const previous = await pool.query(
      'SELECT status, title, tenant_id FROM maintenance_requests WHERE id = $1',
      [req.params.id]
    );
    if (previous.rows.length === 0) return res.status(404).json({ error: 'Request not found' });
    const prevStatus = previous.rows[0].status;

    const result = await pool.query(
      'UPDATE maintenance_requests SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Request not found' });

    if (status === 'completed' && prevStatus !== 'completed') {
      try {
        await pool.query(
          `INSERT INTO notifications (user_id, type, title, message, related_id, related_type)
           VALUES ($1, 'maintenance', $2, $3, $4, 'maintenance_request')`,
          [
            previous.rows[0].tenant_id,
            'Maintenance Completed',
            `Your request "${previous.rows[0].title}" has been marked completed.`,
            req.params.id,
          ]
        );
      } catch (notifyErr) {
        console.error('Maintenance completion notification failed:', notifyErr.message);
      }
    }

    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update status' });
  }
};
