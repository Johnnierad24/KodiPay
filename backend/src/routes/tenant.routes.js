const express = require('express');
const router = express.Router();
const tenantController = require('../controllers/tenant.controller');

router.get('/overview', tenantController.getOverview);

module.exports = router;
