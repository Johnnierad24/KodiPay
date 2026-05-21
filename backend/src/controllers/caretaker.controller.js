const bcrypt = require('bcrypt');
const crypto = require('crypto');
const pool = require('../config/db');

function generateTempPassword() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  const bytes = crypto.randomBytes(10);
  let pwd = '';
  for (let i = 0; i < bytes.length; i++) pwd += alphabet[bytes[i] % alphabet.length];
  return pwd;
}

async function landlordOwnsProperty(landlordId, propertyId) {
  const result = await pool.query(
    'SELECT id FROM properties WHERE id = $1 AND landlord_id = $2',
    [propertyId, landlordId]
  );
  return result.rows.length > 0;
}

exports.listMyCaretakers = async (req, res) => {
  try {
    if (!['landlord', 'agent'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Only landlords or agents can manage caretakers' });
    }
    const result = await pool.query(
      `SELECT ca.id AS assignment_id, ca.created_at,
              u.id AS caretaker_id, u.email, u.first_name, u.last_name, u.phone,
              p.id AS property_id, p.name AS property_name, p.address AS property_address
         FROM caretaker_assignments ca
         JOIN users u ON ca.caretaker_id = u.id
         JOIN properties p ON ca.property_id = p.id
        WHERE p.landlord_id = $1
        ORDER BY p.name, u.first_name, u.last_name`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('listMyCaretakers failed:', error.message);
    res.status(500).json({ error: 'Failed to fetch caretakers' });
  }
};

exports.assignCaretaker = async (req, res) => {
  if (!['landlord', 'agent'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Only landlords or agents can add caretakers' });
  }

  const { property_id, email, first_name, last_name, phone } = req.body || {};
  if (!property_id) return res.status(400).json({ error: 'property_id is required' });
  if (!email) return res.status(400).json({ error: 'email is required' });

  const propertyId = parseInt(property_id, 10);
  if (Number.isNaN(propertyId)) {
    return res.status(400).json({ error: 'property_id must be an integer' });
  }

  if (!(await landlordOwnsProperty(req.user.id, propertyId))) {
    return res.status(403).json({ error: 'You do not own this property' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    let caretakerId;
    let tempPassword = null;
    let created = false;

    const existing = await client.query(
      'SELECT id, role FROM users WHERE LOWER(email) = LOWER($1)',
      [email]
    );

    if (existing.rows.length > 0) {
      const u = existing.rows[0];
      if (u.role !== 'caretaker') {
        await client.query('ROLLBACK');
        return res.status(400).json({
          error: `A user with this email exists but their role is "${u.role}", not "caretaker"`,
        });
      }
      caretakerId = u.id;
    } else {
      if (!first_name || !last_name) {
        await client.query('ROLLBACK');
        return res.status(400).json({
          error: 'first_name and last_name are required to create a new caretaker',
        });
      }
      tempPassword = generateTempPassword();
      const passwordHash = await bcrypt.hash(tempPassword, 10);
      const inserted = await client.query(
        `INSERT INTO users (email, password_hash, first_name, last_name, phone, role)
         VALUES ($1, $2, $3, $4, $5, 'caretaker') RETURNING id`,
        [email.trim(), passwordHash, first_name.trim(), last_name.trim(), phone?.trim() || null]
      );
      caretakerId = inserted.rows[0].id;
      created = true;
    }

    const dup = await client.query(
      'SELECT id FROM caretaker_assignments WHERE property_id = $1 AND caretaker_id = $2',
      [propertyId, caretakerId]
    );
    if (dup.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'This caretaker is already assigned to this property',
      });
    }

    const assignment = await client.query(
      `INSERT INTO caretaker_assignments (property_id, caretaker_id)
       VALUES ($1, $2) RETURNING id, created_at`,
      [propertyId, caretakerId]
    );

    const profile = await client.query(
      'SELECT id, email, first_name, last_name, phone FROM users WHERE id = $1',
      [caretakerId]
    );

    const property = await client.query(
      'SELECT id, name, address FROM properties WHERE id = $1',
      [propertyId]
    );

    await client.query('COMMIT');

    res.status(201).json({
      assignment: assignment.rows[0],
      caretaker: profile.rows[0],
      property: property.rows[0],
      caretaker_created: created,
      temp_password: tempPassword,
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Email already in use' });
    }
    console.error('assignCaretaker failed:', error);
    res.status(500).json({ error: 'Failed to add caretaker' });
  } finally {
    client.release();
  }
};

exports.removeCaretaker = async (req, res) => {
  if (!['landlord', 'agent'].includes(req.user.role)) {
    return res.status(403).json({ error: 'Only landlords or agents can remove caretakers' });
  }
  try {
    const result = await pool.query(
      `DELETE FROM caretaker_assignments ca
         USING properties p
        WHERE ca.id = $1
          AND ca.property_id = p.id
          AND p.landlord_id = $2
        RETURNING ca.id`,
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Caretaker assignment not found' });
    }
    res.json({ message: 'Caretaker removed from this property' });
  } catch (error) {
    console.error('removeCaretaker failed:', error.message);
    res.status(500).json({ error: 'Failed to remove caretaker' });
  }
};
