const express = require('express');
const router = express.Router();
const invoiceController = require('../controllers/invoice.controller');
const checkRole = require('../middleware/role.middleware');

router.post('/', checkRole(['landlord', 'agent']), invoiceController.createInvoice);
router.get('/', checkRole(['landlord', 'agent', 'tenant']), invoiceController.getInvoices);
router.get('/:id', invoiceController.getInvoice);
router.put('/:id/status', checkRole(['landlord', 'agent']), invoiceController.updateInvoiceStatus);
router.post('/generate-monthly', checkRole(['landlord', 'agent']), invoiceController.generateMonthly);

module.exports = router;
