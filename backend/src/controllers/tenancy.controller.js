const bcrypt = require('bcrypt');
const crypto = require('crypto');
const pool = require('../config/db');
const { getTenancyAccess, getUnitAccess, canReadTenancy, ownsProperty } = require('../utils/access-control');

function generateTempPassword() {
  // 10-char readable temp password (no ambiguous chars)
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  const bytes = crypto.randomBytes(10);
  let pwd = '';
  for (let i = 0; i < bytes.length; i++) pwd += alphabet[bytes[i] % alphabet.length];
  return pwd;
}

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
    const params = [req.user.id];
    let propertyClause = '';
    if (req.query.propertyId) {
      const propertyId = parseInt(req.query.propertyId, 10);
      if (!Number.isNaN(propertyId)) {
        params.push(propertyId);
        propertyClause = ` AND p.id = $${params.length}`;
      }
    }

    const query = `
      SELECT t.*, u.unit_number, u.rent_amount, p.id AS property_id, p.name AS property_name,
             us.first_name, us.last_name, us.email AS tenant_email, us.phone AS tenant_phone
      FROM tenancies t
      JOIN units u ON t.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      JOIN users us ON t.tenant_id = us.id
      WHERE ${isTenant ? 't.tenant_id = $1' : 'p.landlord_id = $1'}${propertyClause}
      ORDER BY p.name, u.unit_number
    `;

    const result = await pool.query(query, params);
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

exports.createTenancyWithNewTenant = async (req, res) => {
  if (!['landlord', 'agent'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Only landlords or agents can add tenants' });
  }

  const { unit_id, start_date, end_date, first_name, last_name, email, phone } = req.body;
  if (!unit_id || !start_date || !first_name || !last_name || !email) {
    return res.status(400).json({ error: 'unit_id, start_date, first_name, last_name and email are required' });
  }

  const client = await pool.connect();
  try {
    const unitAccess = await client.query(
      `SELECT u.id, u.status, u.property_id, p.landlord_id
         FROM units u JOIN properties p ON u.property_id = p.id
        WHERE u.id = $1`,
      [unit_id]
    );
    if (unitAccess.rows.length === 0) {
      return res.status(404).json({ error: 'Unit not found' });
    }
    const unit = unitAccess.rows[0];
    if (unit.landlord_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }
    if (unit.status === 'occupied') {
      return res.status(400).json({ error: 'Unit is already occupied' });
    }

    await client.query('BEGIN');

    let tempPassword = null;
    let tenantId;
    let tenantCreated = false;

    const existing = await client.query(
      'SELECT id, role FROM users WHERE LOWER(email) = LOWER($1)',
      [email]
    );

    if (existing.rows.length > 0) {
      const existingUser = existing.rows[0];
      if (existingUser.role !== 'tenant') {
        await client.query('ROLLBACK');
        return res.status(400).json({
          error: 'A user with this email exists but is not a tenant',
        });
      }
      tenantId = existingUser.id;
    } else {
      tempPassword = generateTempPassword();
      const passwordHash = await bcrypt.hash(tempPassword, 10);
      const inserted = await client.query(
        `INSERT INTO users (email, password_hash, first_name, last_name, phone, role)
         VALUES ($1, $2, $3, $4, $5, 'tenant') RETURNING id`,
        [email.trim(), passwordHash, first_name.trim(), last_name.trim(), phone?.trim() || null]
      );
      tenantId = inserted.rows[0].id;
      tenantCreated = true;
    }

    const tenancyResult = await client.query(
      `INSERT INTO tenancies (unit_id, tenant_id, start_date, end_date)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [unit_id, tenantId, start_date, end_date || null]
    );

    await client.query(
      'UPDATE units SET status = $1 WHERE id = $2',
      ['occupied', unit_id]
    );

    await client.query('COMMIT');

    const tenantResult = await pool.query(
      'SELECT id, email, first_name, last_name, phone FROM users WHERE id = $1',
      [tenantId]
    );

    res.status(201).json({
      tenancy: tenancyResult.rows[0],
      tenant: tenantResult.rows[0],
      tenant_created: tenantCreated,
      temp_password: tempPassword,
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Email already in use' });
    }
    console.error('createTenancyWithNewTenant failed:', error);
    res.status(500).json({ error: 'Failed to add tenant' });
  } finally {
    client.release();
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
