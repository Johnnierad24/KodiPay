const firebase = require('../config/firebase');
const pool = require('../config/db');

async function sendPushNotification(userId, title, body, data = {}) {
  try {
    const result = await pool.query(
      'SELECT fcm_token FROM users WHERE id = $1 AND fcm_token IS NOT NULL',
      [userId]
    );

    if (result.rows.length === 0) return { success: false, error: 'No FCM token found' };

    const fcmToken = result.rows[0].fcm_token;

    if (!firebase.apps.length) {
      console.warn('Firebase not initialized, logging notification instead');
      console.log(`Push to ${userId}: ${title} - ${body}`);
      return { success: true, simulated: true };
    }

    const message = {
      notification: { title, body },
      data,
      token: fcmToken
    };

    const response = await firebase.messaging().send(message);

    await pool.query(
      'INSERT INTO notifications (user_id, type, title, message, related_id, related_type) VALUES ($1, $2, $3, $4, $5, $6)',
      [userId, 'push', title, body, data.relatedId || null, data.relatedType || null]
    );

    return { success: true, messageId: response };
  } catch (error) {
    console.error('Push notification failed:', error.message);
    return { success: false, error: error.message };
  }
}

async function sendBulkNotification(userIds, title, body, data = {}) {
  try {
    const result = await pool.query(
      'SELECT id, fcm_token FROM users WHERE id = ANY($1) AND fcm_token IS NOT NULL',
      [userIds]
    );

    if (result.rows.length === 0) return { success: false, error: 'No FCM tokens found' };

    if (!firebase.apps.length) {
      console.warn('Firebase not initialized, logging notifications instead');
      return { success: true, simulated: true };
    }

    const messages = result.rows.map(user => ({
      notification: { title, body },
      data,
      token: user.fcm_token
    }));

    const response = await firebase.messaging().sendEach(messages);

    for (const user of result.rows) {
      await pool.query(
        'INSERT INTO notifications (user_id, type, title, message, related_id, related_type) VALUES ($1, $2, $3, $4, $5, $6)',
        [user.id, 'push', title, body, data.relatedId || null, data.relatedType || null]
      );
    }

    return { success: true, successCount: response.successCount, failureCount: response.failureCount };
  } catch (error) {
    console.error('Bulk notification failed:', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = { sendPushNotification, sendBulkNotification };
