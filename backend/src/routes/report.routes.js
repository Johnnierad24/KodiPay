const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');

router.get('/rent-collection', reportController.getRentCollectionReport);
router.get('/occupancy', reportController.getOccupancyReport);
router.get('/rent-collection/pdf', reportController.downloadRentReportPDF);

module.exports = router;
