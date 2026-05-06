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
