const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics.controller');
const checkRole = require('../middleware/role.middleware');

// Analytics restricted to landlords and authorized agents
router.use(checkRole(['landlord', 'agent']));

router.get('/revenue-trend', analyticsController.getRevenueTrend);
router.get('/occupancy', analyticsController.getOccupancyRate);
router.get('/payment-methods', analyticsController.getPaymentMethods);
router.get('/maintenance-stats', analyticsController.getMaintenanceStats);
router.get('/collection-rate', analyticsController.getCollectionRate);

module.exports = router;
