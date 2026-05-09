const axios = require('axios');
const mpesaConfig = require('../config/mpesa');
const pool = require('../config/db');

// Get M-Pesa access token
async function getAccessToken() {
  try {
    const auth = Buffer.from(`${mpesaConfig.consumerKey}:${mpesaConfig.consumerSecret}`).toString('base64');
    const response = await axios.get(mpesaConfig.authUrl, {
      headers: { Authorization: `Basic ${auth}` }
    });
    return response.data.access_token;
  } catch (error) {
    throw new Error(`Failed to get M-Pesa access token: ${error.message}`);
  }
}

// Generate STK Push password
function generatePassword() {
  const timestamp = new Date().toISOString().replace(/[-:TZ.]/g, '').slice(0, 14);
  const password = Buffer.from(`${mpesaConfig.businessShortCode}${mpesaConfig.passkey}${timestamp}`).toString('base64');
  return { password, timestamp };
}

// Initiate STK Push
async function initiateSTKPush(phoneNumber, amount, accountReference, description) {
  try {
    const accessToken = await getAccessToken();
    const { password, timestamp } = generatePassword();
    
    const stkPushData = {
      BusinessShortCode: mpesaConfig.businessShortCode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phoneNumber,
      PartyB: mpesaConfig.businessShortCode,
      PhoneNumber: phoneNumber,
      CallBackURL: mpesaConfig.callbackUrl,
      AccountReference: accountReference,
      TransactionDesc: description
    };
    
    const response = await axios.post(mpesaConfig.stkPushUrl, stkPushData, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });
    
    return response.data;
  } catch (error) {
    throw new Error(`STK Push failed: ${error.message}`);
  }
}

// Process M-Pesa callback
async function processCallback(callbackData) {
  try {
    const { Body } = callbackData;
    const { stkCallback } = Body;
    
    const { CheckoutRequestID, ResultCode, ResultDesc } = stkCallback;
    
    if (ResultCode === 0) {
      // Payment successful
      const { CallbackMetadata } = stkCallback;
      const metadata = {};
      CallbackMetadata.Item.forEach(item => {
        metadata[item.Name] = item.Value;
      });
      
      const { Amount, MpesaReceiptNumber, TransactionDate, PhoneNumber } = metadata;
      
      // Update payment status in database
      await pool.query(
        `UPDATE payments SET status = 'completed', transaction_ref = $1, updated_at = CURRENT_TIMESTAMP 
         WHERE transaction_ref = $2`,
        [MpesaReceiptNumber, CheckoutRequestID]
      );
      
      // Add to ledger
      const paymentResult = await pool.query('SELECT tenancy_id FROM payments WHERE transaction_ref = $1', [MpesaReceiptNumber]);
      if (paymentResult.rows.length > 0) {
        await pool.query(
          `INSERT INTO ledger_entries (tenancy_id, entry_type, amount, description) 
           VALUES ($1, 'rent', $2, 'M-Pesa payment via STK Push')`,
          [paymentResult.rows[0].tenancy_id, Amount]
        );
      }
      
      return { success: true, receipt: MpesaReceiptNumber };
    } else {
      // Payment failed
      await pool.query(
        `UPDATE payments SET status = 'failed', updated_at = CURRENT_TIMESTAMP 
         WHERE transaction_ref = $1`,
        [CheckoutRequestID]
      );
      return { success: false, error: ResultDesc };
    }
  } catch (error) {
    throw new Error(`Callback processing failed: ${error.message}`);
  }
}

// Query Transaction Status
async function queryTransactionStatus(checkoutRequestID) {
  try {
    const accessToken = await getAccessToken();
    const { password, timestamp } = generatePassword();

    const queryData = {
      BusinessShortCode: mpesaConfig.businessShortCode,
      Password: password,
      Timestamp: timestamp,
      CheckoutRequestID: checkoutRequestID
    };

    const queryUrl = 'https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query';
    const response = await axios.post(queryUrl, queryData, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });

    return response.data;
  } catch (error) {
    throw new Error(`Transaction query failed: ${error.message}`);
  }
}

module.exports = { initiateSTKPush, processCallback, getAccessToken, queryTransactionStatus };
