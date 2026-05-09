const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const paymentController = require('../controllers/payment.controller');
const { processCallback } = require('../services/mpesa.service');
const checkRole = require('../middleware/role.middleware');

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

router.post('/',
  body('tenancy_id').isInt(),
  body('amount').isFloat({ min: 1 }),
  body('payment_method').isIn(['mpesa', 'cash', 'bank_transfer']),
  paymentController.recordPayment
);
router.get('/tenancy/:tenancyId', paymentController.getPaymentsByTenancy);
router.get('/:id', paymentController.getPayment);
router.put('/:id/status', checkRole(['landlord', 'agent']), paymentController.updatePaymentStatus);

module.exports = router;
