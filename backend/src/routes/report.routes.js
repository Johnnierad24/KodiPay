const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');
const checkRole = require('../middleware/role.middleware');

// Reports restricted to landlords and authorized agents
router.use(checkRole(['landlord', 'agent']));

router.get('/rent-collection', reportController.getRentCollectionReport);
router.get('/occupancy', reportController.getOccupancyReport);
router.get('/rent-collection/pdf', reportController.downloadRentReportPDF);

module.exports = router;
