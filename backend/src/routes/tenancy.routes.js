const express = require('express');
const router = express.Router();
const tenancyController = require('../controllers/tenancy.controller');

router.post('/', tenancyController.createTenancy);
router.get('/', tenancyController.getTenancies);
router.get('/:id', tenancyController.getTenancy);
router.put('/:id', tenancyController.updateTenancy);
router.delete('/:id', tenancyController.endTenancy);

module.exports = router;
