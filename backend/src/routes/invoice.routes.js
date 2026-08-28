const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const invoiceController = require('../controllers/invoice.controller');
const checkRole = require('../middleware/role.middleware');
const validate = require('../middleware/validate');

router.post('/',
  checkRole(['landlord', 'agent']),
  body('tenancy_id').isInt({ min: 1 }),
  body('amount').isFloat({ min: 0 }),
  body('due_date').isISO8601(),
  body('description').optional().trim().isLength({ max: 500 }),
  validate,
  invoiceController.createInvoice
);
router.get('/', checkRole(['landlord', 'agent', 'tenant']), invoiceController.getInvoices);
router.get('/:id', invoiceController.getInvoice);
router.put('/:id/status',
  checkRole(['landlord', 'agent']),
  body('status').isIn(['pending', 'paid', 'overdue', 'cancelled']),
  validate,
  invoiceController.updateInvoiceStatus
);
router.post('/generate-monthly', checkRole(['landlord', 'agent']), invoiceController.generateMonthly);

module.exports = router;
