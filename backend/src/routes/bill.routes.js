const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const billController = require('../controllers/bill.controller');
const checkRole = require('../middleware/role.middleware');
const validate = require('../middleware/validate');

router.get('/:tenancyId', billController.list);
router.post('/',
  checkRole(['landlord', 'agent']),
  body('tenancy_id').isInt({ min: 1 }),
  body('bill_type').isIn(['service_charge', 'water', 'electricity', 'other']),
  body('title').isString().notEmpty(),
  body('amount').isFloat({ min: 0 }),
  body('due_date').optional().isISO8601(),
  body('status').optional().isIn(['pending', 'paid', 'overdue']),
  body('description').optional().isString(),
  validate,
  billController.create
);
router.put('/:id/status',
  checkRole(['landlord', 'agent']),
  body('status').isIn(['pending', 'paid', 'overdue']),
  validate,
  billController.updateStatus
);
router.delete('/:id', checkRole(['landlord', 'agent']), billController.remove);

module.exports = router;
