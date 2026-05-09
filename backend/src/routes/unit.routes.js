const express = require('express');
const router = express.Router();
const unitController = require('../controllers/unit.controller');
const checkRole = require('../middleware/role.middleware');

router.post('/', checkRole(['landlord', 'agent']), unitController.createUnit);
router.get('/property/:propertyId', unitController.getUnitsByProperty);
router.get('/:id', unitController.getUnit);
router.put('/:id', checkRole(['landlord', 'agent', 'caretaker']), unitController.updateUnit);
router.delete('/:id', checkRole(['landlord', 'agent']), unitController.deleteUnit);

module.exports = router;
