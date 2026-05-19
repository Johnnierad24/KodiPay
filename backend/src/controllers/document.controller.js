const pool = require('../config/db');
const { uploadFile } = require('../services/storage.service');
const {
  generateLeaseForTenancy,
  generateReceiptForPayment,
} = require('../services/document.service');

const ALLOWED_TYPES = ['lease', 'receipt', 'agreement', 'other'];

function parseIntOrNull(value) {
  if (value === undefined || value === null || value === '') return null;
  const num = parseInt(value, 10);
  return Number.isNaN(num) ? null : num;
}

async function findDocumentWithScope(id) {
  const result = await pool.query(
    `SELECT d.*, p.landlord_id, p.name AS property_name, u.unit_number,
            us.first_name || ' ' || us.last_name AS tenant_name
       FROM documents d
       LEFT JOIN properties p ON d.property_id = p.id
       LEFT JOIN units u ON d.unit_id = u.id
       LEFT JOIN users us ON d.tenant_id = us.id
      WHERE d.id = $1`,
    [id]
  );
  return result.rows[0] || null;
}

function canAccessDocument(user, doc) {
  if (!doc) return false;
  if (['landlord', 'agent'].includes(user.role)) return doc.landlord_id === user.id;
  if (user.role === 'tenant') return doc.tenant_id === user.id;
  if (user.role === 'caretaker') return doc.landlord_id === user.id;
  return false;
}

async function propertyBelongsToUser(propertyId, user) {
  if (propertyId === null) return true;
  const result = await pool.query(
    'SELECT landlord_id FROM properties WHERE id = $1',
    [propertyId]
  );
  if (result.rows.length === 0) return false;
  return result.rows[0].landlord_id === user.id;
}

exports.listDocuments = async (req, res) => {
  try {
    const propertyId = parseIntOrNull(req.query.propertyId);
    const unitId = parseIntOrNull(req.query.unitId);
    const tenantId = parseIntOrNull(req.query.tenantId);
    const tenancyId = parseIntOrNull(req.query.tenancyId);
    const type = req.query.type && ALLOWED_TYPES.includes(req.query.type) ? req.query.type : null;
    const search = (req.query.search || '').trim();

    const params = [];
    const where = [];

    if (['landlord', 'agent', 'caretaker'].includes(req.user.role)) {
      params.push(req.user.id);
      where.push(`p.landlord_id = $${params.length}`);
    } else if (req.user.role === 'tenant') {
      params.push(req.user.id);
      where.push(`d.tenant_id = $${params.length}`);
    } else {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (propertyId !== null) {
      params.push(propertyId);
      where.push(`d.property_id = $${params.length}`);
    }
    if (unitId !== null) {
      params.push(unitId);
      where.push(`d.unit_id = $${params.length}`);
    }
    if (tenantId !== null) {
      params.push(tenantId);
      where.push(`d.tenant_id = $${params.length}`);
    }
    if (tenancyId !== null) {
      params.push(tenancyId);
      where.push(`d.tenancy_id = $${params.length}`);
    }
    if (type) {
      params.push(type);
      where.push(`d.type = $${params.length}`);
    }
    if (search) {
      params.push(`%${search}%`);
      where.push(`(d.title ILIKE $${params.length} OR d.description ILIKE $${params.length})`);
    }

    const result = await pool.query(
      `SELECT d.*, p.name AS property_name, u.unit_number,
              us.first_name || ' ' || us.last_name AS tenant_name
         FROM documents d
         LEFT JOIN properties p ON d.property_id = p.id
         LEFT JOIN units u ON d.unit_id = u.id
         LEFT JOIN users us ON d.tenant_id = us.id
        WHERE ${where.join(' AND ')}
        ORDER BY d.created_at DESC
        LIMIT 200`,
      params
    );

    res.json(result.rows);
  } catch (error) {
    console.error('listDocuments failed:', error);
    res.status(500).json({ error: 'Failed to list documents' });
  }
};

exports.getDocument = async (req, res) => {
  try {
    const doc = await findDocumentWithScope(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Document not found' });
    if (!canAccessDocument(req.user, doc)) return res.status(403).json({ error: 'Access denied' });
    res.json(doc);
  } catch (error) {
    console.error('getDocument failed:', error);
    res.status(500).json({ error: 'Failed to fetch document' });
  }
};

exports.uploadDocument = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    if (!['landlord', 'agent'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Only landlords or agents can upload documents' });
    }

    const propertyId = parseIntOrNull(req.body.property_id);
    if (!propertyId) return res.status(400).json({ error: 'property_id is required' });
    const ownsProperty = await propertyBelongsToUser(propertyId, req.user);
    if (!ownsProperty) return res.status(403).json({ error: 'Access denied' });

    const type = ALLOWED_TYPES.includes(req.body.type) ? req.body.type : 'other';
    const title = (req.body.title || req.file.originalname || 'Untitled').toString().slice(0, 255);
    const description = req.body.description ? req.body.description.toString().slice(0, 2000) : null;
    const unitId = parseIntOrNull(req.body.unit_id);
    const tenantId = parseIntOrNull(req.body.tenant_id);
    const tenancyId = parseIntOrNull(req.body.tenancy_id);
    const startsOn = req.body.starts_on || null;
    const expiresOn = req.body.expires_on || null;

    const upload = await uploadFile(
      req.file.buffer,
      req.file.originalname,
      'documents/uploads',
      req.file.mimetype
    );
    if (!upload.success) return res.status(500).json({ error: upload.error });

    const insert = await pool.query(
      `INSERT INTO documents
        (property_id, unit_id, tenant_id, tenancy_id, uploaded_by,
         type, title, description, file_url, mime_type, size_bytes,
         generated, starts_on, expires_on, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, FALSE, $12, $13, 'active')
       RETURNING *`,
      [
        propertyId, unitId, tenantId, tenancyId, req.user.id,
        type, title, description, upload.url, req.file.mimetype, req.file.size,
        startsOn, expiresOn,
      ]
    );

    res.status(201).json({ ...insert.rows[0], simulated: upload.simulated || false });
  } catch (error) {
    console.error('uploadDocument failed:', error);
    res.status(500).json({ error: 'Failed to upload document' });
  }
};

exports.deleteDocument = async (req, res) => {
  try {
    const doc = await findDocumentWithScope(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Document not found' });
    if (!['landlord', 'agent'].includes(req.user.role) || doc.landlord_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await pool.query('DELETE FROM documents WHERE id = $1', [req.params.id]);
    res.json({ message: 'Document deleted' });
  } catch (error) {
    console.error('deleteDocument failed:', error);
    res.status(500).json({ error: 'Failed to delete document' });
  }
};

exports.generateLease = async (req, res) => {
  try {
    if (!['landlord', 'agent'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Only landlords or agents can generate leases' });
    }
    const tenancyId = parseIntOrNull(req.body.tenancy_id);
    if (!tenancyId) return res.status(400).json({ error: 'tenancy_id is required' });

    const tenancyOwner = await pool.query(
      `SELECT p.landlord_id
         FROM tenancies t
         JOIN units u ON t.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
        WHERE t.id = $1`,
      [tenancyId]
    );
    if (tenancyOwner.rows.length === 0) return res.status(404).json({ error: 'Tenancy not found' });
    if (tenancyOwner.rows[0].landlord_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const terms = req.body.terms || {};
    const result = await generateLeaseForTenancy({ tenancyId, terms, uploadedBy: req.user.id });
    if (!result.success) return res.status(500).json({ error: result.error });
    res.status(201).json(result.data);
  } catch (error) {
    console.error('generateLease failed:', error);
    res.status(500).json({ error: 'Failed to generate lease' });
  }
};

exports.generateReceipt = async (req, res) => {
  try {
    const paymentId = parseIntOrNull(req.body.payment_id);
    if (!paymentId) return res.status(400).json({ error: 'payment_id is required' });

    const paymentOwner = await pool.query(
      `SELECT t.tenant_id, p.landlord_id
         FROM payments pay
         JOIN tenancies t ON pay.tenancy_id = t.id
         JOIN units u ON t.unit_id = u.id
         JOIN properties p ON u.property_id = p.id
        WHERE pay.id = $1`,
      [paymentId]
    );
    if (paymentOwner.rows.length === 0) return res.status(404).json({ error: 'Payment not found' });

    const row = paymentOwner.rows[0];
    const canAccess =
      (['landlord', 'agent'].includes(req.user.role) && row.landlord_id === req.user.id) ||
      (req.user.role === 'tenant' && row.tenant_id === req.user.id);
    if (!canAccess) return res.status(403).json({ error: 'Access denied' });

    const result = await generateReceiptForPayment({ paymentId, uploadedBy: req.user.id });
    if (!result.success) return res.status(500).json({ error: result.error });
    res.status(201).json(result.data);
  } catch (error) {
    console.error('generateReceipt failed:', error);
    res.status(500).json({ error: 'Failed to generate receipt' });
  }
};
