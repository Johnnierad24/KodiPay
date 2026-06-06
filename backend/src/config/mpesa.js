require('dotenv').config();

// Daraja has two completely separate hosts. Production calls MUST NOT hit the
// sandbox host (and vice versa) or every transaction fails. Select the base
// host from MPESA_ENV so the same code works in both environments.
const environment = process.env.MPESA_ENV === 'production' ? 'production' : 'sandbox';
const baseUrl = environment === 'production'
  ? 'https://api.safaricom.co.ke'
  : 'https://sandbox.safaricom.co.ke';

// STK Push transaction type depends on the shortcode kind:
//   Paybill  -> CustomerPayBillOnline
//   Till     -> CustomerBuyGoodsOnline (Buy Goods)
// Set MPESA_SHORTCODE_TYPE=till if Safaricom issued a Till number; defaults to paybill.
const shortCodeType = process.env.MPESA_SHORTCODE_TYPE === 'till' ? 'till' : 'paybill';
const transactionType = shortCodeType === 'till'
  ? 'CustomerBuyGoodsOnline'
  : 'CustomerPayBillOnline';

module.exports = {
  consumerKey: process.env.MPESA_CONSUMER_KEY || 'your_consumer_key',
  consumerSecret: process.env.MPESA_CONSUMER_SECRET || 'your_consumer_secret',
  businessShortCode: process.env.MPESA_SHORTCODE || '174379',
  passkey: process.env.MPESA_PASSKEY || 'your_passkey',
  callbackUrl: process.env.MPESA_CALLBACK_URL || 'https://yourdomain.com/api/payments/mpesa/callback',
  baseUrl,
  authUrl: `${baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
  stkPushUrl: `${baseUrl}/mpesa/stkpush/v1/processrequest`,
  stkQueryUrl: `${baseUrl}/mpesa/stkpushquery/v1/query`,
  shortCodeType, // 'paybill' or 'till'
  transactionType, // STK Push TransactionType derived from shortCodeType
  environment // 'sandbox' or 'production'
};

// Helper function to check if M-Pesa is configured
module.exports.isConfigured = function() {
  return process.env.MPESA_CONSUMER_KEY && process.env.MPESA_CONSUMER_SECRET;
};
