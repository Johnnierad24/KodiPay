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
      TransactionType: mpesaConfig.transactionType,
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

// Decide whether to independently re-confirm callbacks with Safaricom.
// Verifying costs an extra API round-trip, so default to ON only in production
// (where real money is at stake) and OFF in sandbox for frictionless testing.
// MPESA_VERIFY_CALLBACK=true|false overrides the default either way.
function shouldVerifyCallback() {
  if (process.env.MPESA_VERIFY_CALLBACK === 'true') return true;
  if (process.env.MPESA_VERIFY_CALLBACK === 'false') return false;
  return mpesaConfig.environment === 'production';
}

// The inbound callback body is untrusted (the endpoint is a public webhook). Before
// moving money we ask Safaricom directly what happened to this CheckoutRequestID.
// Returns 'success' | 'failed' | 'unverified' — 'unverified' (query errored) means
// we must NOT guess, so the payment is left pending for manual reconciliation.
async function confirmStkSuccess(checkoutRequestID) {
  try {
    const status = await queryTransactionStatus(checkoutRequestID);
    if (status.ResultCode === undefined || status.ResultCode === null) return 'unverified';
    // Daraja returns ResultCode as a string; '0' = the STK push truly succeeded.
    return String(status.ResultCode) === '0' ? 'success' : 'failed';
  } catch (error) {
    console.error(`M-Pesa callback verification failed for ${checkoutRequestID}: ${error.message}`);
    return 'unverified';
  }
}

// Process M-Pesa callback
async function processCallback(callbackData) {
  try {
    const { Body } = callbackData || {};
    const { stkCallback } = Body || {};
    if (!stkCallback) throw new Error('Invalid callback payload: missing Body.stkCallback');

    const { CheckoutRequestID, ResultCode, ResultDesc } = stkCallback;
    if (!CheckoutRequestID) throw new Error('Invalid callback payload: missing CheckoutRequestID');

    // Treat the callback as a trigger, not the source of truth. A claimed success
    // is re-confirmed with Safaricom; a claimed failure needs no verification
    // (forging a failure moves no money). 'unverified' leaves the payment pending.
    let verdict;
    if (String(ResultCode) !== '0') {
      verdict = 'failed';
    } else if (shouldVerifyCallback()) {
      verdict = await confirmStkSuccess(CheckoutRequestID);
    } else {
      verdict = 'success';
    }

    if (verdict === 'unverified') {
      console.warn(`M-Pesa callback for ${CheckoutRequestID} could not be verified; leaving payment pending.`);
      return { success: false, pending: true };
    }

    if (verdict === 'success') {
      // Payment successful
      const { CallbackMetadata } = stkCallback;
      const metadata = {};
      CallbackMetadata.Item.forEach(item => {
        metadata[item.Name] = item.Value;
      });
      
      const { Amount, MpesaReceiptNumber, TransactionDate, PhoneNumber } = metadata;

      // Idempotency guard: Safaricom retries callbacks when an ack is slow, so this
      // can fire more than once for the same payment. Gate completion on the row
      // still being un-completed (and matching the CheckoutRequestID) in ONE atomic
      // statement — Postgres locks the row, so a concurrent duplicate sees 'completed'
      // and matches nothing. RETURNING drives the ledger insert, so a repeat callback
      // can never double-credit. This also covers forged callbacks for unknown IDs.
      const completed = await pool.query(
        `UPDATE payments SET status = 'completed', transaction_ref = $1, updated_at = CURRENT_TIMESTAMP
         WHERE transaction_ref = $2 AND status <> 'completed'
         RETURNING id, tenancy_id`,
        [MpesaReceiptNumber, CheckoutRequestID]
      );

      if (completed.rows.length === 0) {
        console.warn(`M-Pesa callback for ${CheckoutRequestID} ignored: already completed or unknown payment.`);
        return { success: true, duplicate: true, receipt: MpesaReceiptNumber };
      }

      const { id: paymentId, tenancy_id } = completed.rows[0];
      await pool.query(
        `INSERT INTO ledger_entries (tenancy_id, entry_type, amount, description)
         VALUES ($1, 'rent', $2, 'M-Pesa payment via STK Push')`,
        [tenancy_id, Amount]
      );

      const { generateReceiptForPayment } = require('./document.service');
      generateReceiptForPayment({ paymentId })
        .catch((err) => console.error('M-Pesa auto-receipt failed:', err.message));

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

    const response = await axios.post(mpesaConfig.stkQueryUrl, queryData, {
      headers: { Authorization: `Bearer ${accessToken}` }
    });

    return response.data;
  } catch (error) {
    throw new Error(`Transaction query failed: ${error.message}`);
  }
}

module.exports = { initiateSTKPush, processCallback, getAccessToken, queryTransactionStatus };
