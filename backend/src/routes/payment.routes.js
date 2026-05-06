const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');
const { processCallback } = require('../services/mpesa.service');

// M-Pesa callback/webhook endpoint (no auth required)
router.post('/mpesa/callback', async (req, res) => {
  try {
    const result = await processCallback(req.body);
    res.json({ ResultCode: 0, ResultDesc: 'Success' });
  } catch (error) {
    console.error('M-Pesa callback error:', error);
    res.json({ ResultCode: 1, ResultDesc: 'Failed' });
  }
});

router.post('/', paymentController.recordPayment);
router.get('/tenancy/:tenancyId', paymentController.getPaymentsByTenancy);
router.get('/:id', paymentController.getPayment);
router.put('/:id', paymentController.updatePaymentStatus);

module.exports = router;
