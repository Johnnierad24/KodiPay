const pool = require('../config/db');
const { initiateSTKPush } = require('../services/mpesa.service');

exports.recordPayment = async (req, res) => {
  try {
    const { tenancy_id, amount, payment_method, transaction_ref } = req.body;
    
    if (payment_method === 'mpesa') {
      // M-Pesa STK Push
      const { phone_number } = req.body;
      if (!phone_number) return res.status(400).json({ error: 'Phone number required for M-Pesa' });
      
      const stkResponse = await initiateSTKPush(
        phone_number,
        amount,
        `Tenancy-${tenancy_id}`,
        'Rent Payment'
      );
      
      // Save pending payment
      const paymentResult = await pool.query(
        `INSERT INTO payments (tenancy_id, amount, payment_method, transaction_ref, status) 
         VALUES ($1, $2, $3, $4, 'pending') RETURNING *`,
        [tenancy_id, amount, payment_method, stkResponse.CheckoutRequestID]
      );
      
      res.status(201).json({ 
        payment: paymentResult.rows[0], 
        stk: stkResponse,
        message: 'STK Push initiated. Complete payment on your phone.' 
      });
    } else {
      // Manual payment
      const paymentResult = await pool.query(
        `INSERT INTO payments (tenancy_id, amount, payment_method, transaction_ref, status) 
         VALUES ($1, $2, $3, $4, 'completed') RETURNING *`,
        [tenancy_id, amount, payment_method, transaction_ref]
      );
      
      const ledgerResult = await pool.query(
        `INSERT INTO ledger_entries (tenancy_id, entry_type, amount, description) 
         VALUES ($1, 'rent', $2, 'Manual payment recorded') RETURNING *`,
        [tenancy_id, amount]
      );
      
      res.status(201).json({ payment: paymentResult.rows[0], ledger: ledgerResult.rows[0] });
    }
  } catch (error) {
    res.status(500).json({ error: error.message || 'Failed to record payment' });
  }
};

exports.getPaymentsByTenancy = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM payments WHERE tenancy_id = $1 ORDER BY payment_date DESC', [req.params.tenancyId]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch payments' });
  }
};

exports.getPayment = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM payments WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Payment not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch payment' });
  }
};

exports.updatePaymentStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const result = await pool.query(
      'UPDATE payments SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      [status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Payment not found' });
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update payment' });
  }
};
