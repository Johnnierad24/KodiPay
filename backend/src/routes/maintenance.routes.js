const express = require('express');
const router = express.Router();
const maintenanceController = require('../controllers/maintenance.controller');

router.post('/', maintenanceController.createRequest);
router.get('/mine', maintenanceController.getMyRequests);
router.get('/unit/:unitId', maintenanceController.getRequestsByUnit);
router.get('/:id', maintenanceController.getRequest);
router.put('/:id', maintenanceController.updateRequest);
router.put('/:id/status', maintenanceController.updateStatus);
router.post('/:id/remind-caretaker', maintenanceController.remindCaretaker);

module.exports = router;
