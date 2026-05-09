const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const propertyController = require('../controllers/property.controller');
const checkRole = require('../middleware/role.middleware');

router.post('/',
  checkRole(['landlord', 'agent']),
  body('name').trim().notEmpty(),
  body('address').trim().notEmpty(),
  propertyController.createProperty
);
router.get('/', checkRole(['landlord', 'agent']), propertyController.getProperties);
router.get('/:id', checkRole(['landlord', 'agent', 'caretaker']), propertyController.getProperty);
router.put('/:id', checkRole(['landlord', 'agent']), propertyController.updateProperty);
router.delete('/:id', checkRole(['landlord']), propertyController.deleteProperty);

module.exports = router;
