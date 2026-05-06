require('dotenv').config();

module.exports = {
  provider: process.env.SMS_PROVIDER || 'africastalking',
  apiKey: process.env.SMS_API_KEY || 'your_sms_api_key',
  username: process.env.SMS_USERNAME || 'your_sms_username',
  senderId: process.env.SMS_SENDER_ID || 'KodiPay',
  environment: process.env.SMS_ENV || 'sandbox' // 'sandbox' or 'production'
};

module.exports.isConfigured = function() {
  return process.env.SMS_API_KEY && process.env.SMS_USERNAME;
};
