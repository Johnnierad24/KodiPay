const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const tenancyController = require('../controllers/tenancy.controller');
const checkRole = require('../middleware/role.middleware');
const validate = require('../middleware/validate');
const { createLimiter } = require('../middleware/rateLimiters');
const { validateName, validateEmail, validatePhone } = require('../utils/validators');

router.post('/',
  checkRole(['landlord', 'agent']),
  createLimiter,
  body('unit_id').isInt({ min: 1 }),
  body('tenant_id').isInt({ min: 1 }),
  body('start_date').isISO8601(),
  body('end_date').optional({ values: 'falsy' }).isISO8601(),
  body('rent_amount').isFloat({ min: 0 }),
  body('deposit_amount').optional().isFloat({ min: 0 }),
  validate,
  tenancyController.createTenancy
);
router.post('/with-new-tenant',
  checkRole(['landlord', 'agent']),
  body('unit_id').isInt({ min: 1 }),
  validateEmail('tenant_email'),
  validateName('tenant_first_name'),
  validateName('tenant_last_name'),
  validatePhone('tenant_phone'),
  body('start_date').isISO8601(),
  body('end_date').optional({ values: 'falsy' }).isISO8601(),
  body('rent_amount').isFloat({ min: 0 }),
  body('deposit_amount').optional().isFloat({ min: 0 }),
  validate,
  tenancyController.createTenancyWithNewTenant
);
router.get('/', checkRole(['landlord', 'agent', 'caretaker', 'tenant']), tenancyController.getTenancies);
router.get('/:id', tenancyController.getTenancy);
router.put('/:id',
  checkRole(['landlord', 'agent']),
  body('status').optional().isIn(['active', 'expired', 'terminated']),
  body('end_date').optional().isISO8601(),
  body('rent_amount').optional().isFloat({ min: 0 }),
  validate,
  tenancyController.updateTenancy
);
router.delete('/:id/end', checkRole(['landlord', 'agent']), tenancyController.endTenancy);

module.exports = router;
