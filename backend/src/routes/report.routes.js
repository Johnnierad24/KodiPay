const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');
const checkRole = require('../middleware/role.middleware');

// Reports restricted to landlords and authorized agents
router.use(checkRole(['landlord', 'agent']));

router.get('/rent-collection', reportController.getRentCollectionReport);
router.get('/occupancy', reportController.getOccupancyReport);
router.get('/income', reportController.getIncomeReport);
router.get('/arrears', reportController.getArrearsReport);
router.get('/property-performance', reportController.getPropertyPerformanceReport);
router.get('/maintenance', reportController.getMaintenanceReport);
router.get('/payment-trends', reportController.getPaymentTrendsReport);
router.get('/transactions', reportController.getTransactionReport);
router.get('/rent-collection/pdf', reportController.downloadRentReportPDF);
router.get('/transactions/csv', reportController.downloadTransactionReportCSV);

module.exports = router;
