const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const propertyController = require('../controllers/property.controller');
const checkRole = require('../middleware/role.middleware');
const validate = require('../middleware/validate');
const { createLimiter } = require('../middleware/rateLimiters');

router.post('/',
  checkRole(['landlord', 'agent']),
  createLimiter,
  body('name').trim().notEmpty().isLength({ max: 255 }),
  body('address').trim().notEmpty().isLength({ max: 500 }),
  body('description').optional().trim().isLength({ max: 2000 }),
  validate,
  propertyController.createProperty
);
router.get('/', checkRole(['landlord', 'agent']), propertyController.getProperties);
router.get('/:id', checkRole(['landlord', 'agent', 'caretaker']), propertyController.getProperty);
router.put('/:id',
  checkRole(['landlord', 'agent']),
  body('name').optional().trim().notEmpty().isLength({ max: 255 }),
  body('address').optional().trim().notEmpty().isLength({ max: 500 }),
  body('description').optional().trim().isLength({ max: 2000 }),
  validate,
  propertyController.updateProperty
);
router.delete('/:id', checkRole(['landlord']), propertyController.deleteProperty);

module.exports = router;
