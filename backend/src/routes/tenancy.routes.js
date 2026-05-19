const express = require('express');
const router = express.Router();
const tenancyController = require('../controllers/tenancy.controller');
const checkRole = require('../middleware/role.middleware');

router.post('/', checkRole(['landlord', 'agent']), tenancyController.createTenancy);
router.post('/with-new-tenant', checkRole(['landlord', 'agent']), tenancyController.createTenancyWithNewTenant);
router.get('/', checkRole(['landlord', 'agent', 'caretaker']), tenancyController.getTenancies);
router.get('/:id', tenancyController.getTenancy);
router.put('/:id', checkRole(['landlord', 'agent']), tenancyController.updateTenancy);
router.delete('/:id/end', checkRole(['landlord', 'agent']), tenancyController.endTenancy);

module.exports = router;
