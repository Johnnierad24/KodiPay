const pool = require('../config/db');
const { sendPushNotification } = require('../services/notification.service');
const { sendRentReminder } = require('../services/sms.service');

exports.getNotifications = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const result = await pool.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2 RETURNING *',
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Notification not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update notification' });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    await pool.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
      [req.user.id]
    );
    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update notifications' });
  }
};

exports.sendTestNotification = async (req, res) => {
  try {
    const { title, body } = req.body;
    const result = await sendPushNotification(req.user.id, title || 'Test', body || 'This is a test notification');
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: 'Failed to send notification' });
  }
};

exports.sendRentReminder = async (req, res) => {
  try {
    const { tenancy_id } = req.body;
    const result = await sendRentReminder(tenancy_id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: 'Failed to send reminder' });
  }
};

exports.sendAnnouncement = async (req, res) => {
  try {
    if (!['landlord', 'agent'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Only landlords or agents can post announcements' });
    }
    const { title, message, property_id } = req.body || {};
    if (!title || !message) {
      return res.status(400).json({ error: 'Title and message are required' });
    }

    const params = [req.user.id];
    let propertyClause = '';
    if (property_id) {
      const parsed = parseInt(property_id, 10);
      if (Number.isNaN(parsed)) {
        return res.status(400).json({ error: 'property_id must be an integer' });
      }
      params.push(parsed);
      propertyClause = ' AND p.id = $2';
    }

    const tenantQuery = `
      SELECT DISTINCT t.tenant_id
      FROM tenancies t
      JOIN units u ON t.unit_id = u.id
      JOIN properties p ON u.property_id = p.id
      WHERE p.landlord_id = $1 AND t.status = 'active'${propertyClause}
    `;
    const tenants = await pool.query(tenantQuery, params);

    if (tenants.rows.length === 0) {
      return res.json({ success: true, recipients: 0, message: 'No active tenants found' });
    }

    const insertText = `
      INSERT INTO notifications (user_id, type, title, message, related_id, related_type)
      VALUES ${tenants.rows.map((_, idx) => `($${idx * 4 + 1}, 'announcement', $${idx * 4 + 2}, $${idx * 4 + 3}, $${idx * 4 + 4}, 'announcement')`).join(', ')}
    `;
    const insertValues = tenants.rows.flatMap((row) => [
      row.tenant_id,
      title,
      message,
      property_id || null,
    ]);

    await pool.query(insertText, insertValues);

    res.status(201).json({
      success: true,
      recipients: tenants.rows.length,
      message: 'Announcement delivered',
    });
  } catch (error) {
    console.error('sendAnnouncement failed:', error.message);
    res.status(500).json({ error: 'Failed to send announcement' });
  }
};
