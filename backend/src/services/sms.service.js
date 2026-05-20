const axios = require('axios');
const smsConfig = require('../config/sms');
const pool = require('../config/db');

async function sendSMS(phoneNumber, message) {
  try {
    if (!smsConfig.isConfigured()) {
      console.warn('SMS service not configured, logging message instead');
      console.log(`SMS to ${phoneNumber}: ${message}`);
      return { success: true, simulated: true };
    }

    if (smsConfig.provider === 'africastalking') {
      const response = await axios.post('https://api.africastalking.com/version1/messaging', {
        username: smsConfig.username,
        to: phoneNumber,
        message: message,
        from: smsConfig.senderId
      }, {
        headers: {
          'apiKey': smsConfig.apiKey,
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });
      return response.data;
    }

    throw new Error(`Unsupported SMS provider: ${smsConfig.provider}`);
  } catch (error) {
    console.error('SMS sending failed:', error.message);
    throw error;
  }
}

async function sendRentReminder(tenancyId) {
  try {
    const result = await pool.query(`
      SELECT t.id, t.tenant_id, u.phone, u.first_name, u.last_name, un.unit_number, p.name as property_name, un.rent_amount
      FROM tenancies t
      JOIN users u ON t.tenant_id = u.id
      JOIN units un ON t.unit_id = un.id
      JOIN properties p ON un.property_id = p.id
      WHERE t.id = $1 AND t.status = 'active'
    `, [tenancyId]);

    if (result.rows.length === 0) return { success: false, error: 'Tenancy not found' };

    const tenancy = result.rows[0];
    const message = `Hi ${tenancy.first_name}, your rent of KES ${tenancy.rent_amount} for ${tenancy.property_name} (Unit ${tenancy.unit_number}) is due. Pay via M-Pesa: Pay Bill ${process.env.MPESA_SHORTCODE || '174379'}. - KodiPay`;

    try {
      await sendSMS(tenancy.phone, message);
    } catch (smsErr) {
      console.warn('SMS dispatch failed, continuing with in-app notification:', smsErr.message);
    }

    await pool.query(
      'INSERT INTO notifications (user_id, type, title, message, related_id, related_type) VALUES ($1, $2, $3, $4, $5, $6)',
      [tenancy.tenant_id, 'rent_reminder', 'Rent Reminder', message, tenancyId, 'tenancy']
    );

    return { success: true, message: 'Reminder sent' };
  } catch (error) {
    console.error('Rent reminder failed:', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = { sendSMS, sendRentReminder };
