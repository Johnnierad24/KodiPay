const express = require('express');
const router = express.Router();
const invoiceController = require('../controllers/invoice.controller');

router.post('/', invoiceController.createInvoice);
router.get('/', invoiceController.getInvoices);
router.get('/:id', invoiceController.getInvoice);
router.put('/:id/status', invoiceController.updateInvoiceStatus);
router.post('/generate-monthly', invoiceController.generateMonthly);

module.exports = router;
