require('dotenv').config();

module.exports = {
  consumerKey: process.env.MPESA_CONSUMER_KEY || 'your_consumer_key',
  consumerSecret: process.env.MPESA_CONSUMER_SECRET || 'your_consumer_secret',
  businessShortCode: process.env.MPESA_SHORTCODE || '174379',
  passkey: process.env.MPESA_PASSKEY || 'your_passkey',
  callbackUrl: process.env.MPESA_CALLBACK_URL || 'https://yourdomain.com/api/payments/mpesa/callback',
  authUrl: 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
  stkPushUrl: 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
  environment: process.env.MPESA_ENV || 'sandbox' // 'sandbox' or 'production'
};

// Helper function to check if M-Pesa is configured
module.exports.isConfigured = function() {
  return process.env.MPESA_CONSUMER_KEY && process.env.MPESA_CONSUMER_SECRET;
};
