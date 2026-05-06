const express = require('express');
const router = express.Router();
const unitController = require('../controllers/unit.controller');

router.post('/', unitController.createUnit);
router.get('/property/:propertyId', unitController.getUnitsByProperty);
router.get('/:id', unitController.getUnit);
router.put('/:id', unitController.updateUnit);
router.delete('/:id', unitController.deleteUnit);

module.exports = router;
