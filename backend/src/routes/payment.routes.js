const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const paymentController = require('../controllers/payment.controller');
const { processCallback } = require('../services/mpesa.service');
const checkRole = require('../middleware/role.middleware');
const authMiddleware = require('../middleware/auth.middleware');
const verifyCallbackSource = require('../middleware/mpesa-callback.middleware');

// M-Pesa callback/webhook endpoint. No JWT — Safaricom calls it machine-to-machine.
// verifyCallbackSource gates it via secret path + optional IP allowlist instead.
// Two routes share one handler: '/mpesa/callback/:token' (when a secret is set) and
// the secret-less '/mpesa/callback' (legacy / no secret). Express 5 dropped the old
// optional ':token?' syntax, so we register both explicitly.
async function handleCallback(req, res) {
  try {
    await processCallback(req.body);
    res.json({ ResultCode: 0, ResultDesc: 'Success' });
  } catch (error) {
    console.error('M-Pesa callback error:', error);
    res.json({ ResultCode: 1, ResultDesc: 'Failed' });
  }
}
router.post('/mpesa/callback', verifyCallbackSource, handleCallback);
router.post('/mpesa/callback/:token', verifyCallbackSource, handleCallback);

router.use(authMiddleware);

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
