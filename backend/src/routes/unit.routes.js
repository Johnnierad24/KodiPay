const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const unitController = require('../controllers/unit.controller');
const checkRole = require('../middleware/role.middleware');
const validate = require('../middleware/validate');

router.post('/',
  checkRole(['landlord', 'agent']),
  body('property_id').isInt({ min: 1 }),
  body('unit_number').trim().notEmpty().isLength({ max: 50 }),
  body('rent_amount').isFloat({ min: 0 }),
  body('deposit_amount').optional().isFloat({ min: 0 }),
  validate,
  unitController.createUnit
);
router.get('/property/:propertyId', unitController.getUnitsByProperty);
router.get('/:id', unitController.getUnit);
router.put('/:id',
  checkRole(['landlord', 'agent', 'caretaker']),
  body('rent_amount').optional().isFloat({ min: 0 }),
  body('deposit_amount').optional().isFloat({ min: 0 }),
  body('status').optional().isIn(['vacant', 'occupied', 'maintenance']),
  validate,
  unitController.updateUnit
);
router.delete('/:id', checkRole(['landlord', 'agent']), unitController.deleteUnit);

module.exports = router;
