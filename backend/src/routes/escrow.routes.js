const express = require('express');
const router = express.Router();
const escrowController = require('../controllers/escrow.controller');
const checkRole = require('../middleware/role.middleware');

router.use(checkRole(['landlord', 'agent']));

router.get('/balance', escrowController.getBalance);
router.get('/ledger', escrowController.getLedger);

module.exports = router;
