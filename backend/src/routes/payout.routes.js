const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const payoutController = require('../controllers/payout.controller');
const checkRole = require('../middleware/role.middleware');
const validate = require('../middleware/validate');

router.use(checkRole(['landlord', 'agent']));

router.get('/', payoutController.listPayouts);
router.get('/balance', payoutController.getBalance);
router.post('/',
  body('amount').isFloat({ min: 0 }),
  body('method').isString().notEmpty(),
  body('status').optional().isIn(['scheduled', 'pending', 'completed', 'failed']),
  body('scheduled_date').optional().isISO8601(),
  body('reference').optional().isString(),
  body('description').optional().isString(),
  validate,
  payoutController.createPayout
);
router.put('/:id/status',
  body('status').isIn(['scheduled', 'pending', 'completed', 'failed']),
  validate,
  payoutController.updatePayoutStatus
);

module.exports = router;