const pool = require('../config/db');
const {
  listBillsForTenancy,
  createBill,
  updateBillStatus,
  deleteBill,
} = require('../services/bill.service');
const { getTenancyAccess, canReadTenancy, ownsProperty } = require('../utils/access-control');

exports.list = async (req, res) => {
  try {
    const tenancyAccess = await getTenancyAccess(pool, req.params.tenancyId);

    if (!tenancyAccess) return res.status(404).json({ error: 'Tenancy not found' });
    if (!canReadTenancy(req.user, tenancyAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await listBillsForTenancy(req.params.tenancyId);
    if (!result.success) return res.status(500).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch bills' });
  }
};

exports.create = async (req, res) => {
  try {
    const tenancyAccess = await getTenancyAccess(pool, req.body.tenancy_id);

    if (!tenancyAccess) return res.status(404).json({ error: 'Tenancy not found' });
    if (!ownsProperty(req.user, tenancyAccess)) return res.status(403).json({ error: 'Access denied' });

    const result = await createBill(req.body);
    if (!result.success) return res.status(400).json({ error: result.error });
    res.status(201).json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create bill' });
  }
};

exports.updateStatus = async (req, res) => {
  try {
    const billAccess = await pool.query(
      `SELECT b.id, p.landlord_id
       FROM bills b
       JOIN tenancies t ON b.tenancy_id = t.id
       JOIN units u ON t.unit_id = u.id
       JOIN properties p ON u.property_id = p.id
       WHERE b.id = $1`,
      [req.params.id]
    );

    if (billAccess.rows.length === 0) return res.status(404).json({ error: 'Bill not found' });
    if (!ownsProperty(req.user, billAccess.rows[0])) return res.status(403).json({ error: 'Access denied' });

    const result = await updateBillStatus(req.params.id, req.body.status);
    if (!result.success) return res.status(404).json({ error: result.error });
    res.json(result.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update bill status' });
  }
};

exports.remove = async (req, res) => {
  try {
    const billAccess = await pool.query(
      `SELECT b.id, p.landlord_id
       FROM bills b
       JOIN tenancies t ON b.tenancy_id = t.id
       JOIN units u ON t.unit_id = u.id
       JOIN properties p ON u.property_id = p.id
       WHERE b.id = $1`,
      [req.params.id]
    );

    if (billAccess.rows.length === 0) return res.status(404).json({ error: 'Bill not found' });
    if (!ownsProperty(req.user, billAccess.rows[0])) return res.status(403).json({ error: 'Access denied' });

    const result = await deleteBill(req.params.id);
    if (!result.success) return res.status(404).json({ error: result.error });
    res.json({ message: 'Bill deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete bill' });
  }
};
