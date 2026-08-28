const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const maintenanceController = require('../controllers/maintenance.controller');
const validate = require('../middleware/validate');
const { createLimiter } = require('../middleware/rateLimiters');

const ALLOWED_CATEGORIES = ['electrical', 'structural', 'plumbing', 'other'];
const ALLOWED_PRIORITIES = ['low', 'medium', 'high', 'urgent', 'emergency'];
const ALLOWED_STATUSES = ['pending', 'in_progress', 'completed', 'cancelled'];

router.post('/',
  createLimiter,
  body('unit_id').isInt({ min: 1 }),
  body('category').isIn(ALLOWED_CATEGORIES),
  body('priority').isIn(ALLOWED_PRIORITIES),
  body('title').optional().trim().isLength({ max: 255 }),
  body('description').optional().trim().isLength({ max: 2000 }),
  validate,
  maintenanceController.createRequest
);
router.get('/mine', maintenanceController.getMyRequests);
router.get('/unit/:unitId', maintenanceController.getRequestsByUnit);
router.get('/:id', maintenanceController.getRequest);
router.put('/:id',
  body('title').optional().trim().isLength({ max: 255 }),
  body('description').optional().trim().isLength({ max: 2000 }),
  body('category').optional().isIn(ALLOWED_CATEGORIES),
  body('priority').optional().isIn(ALLOWED_PRIORITIES),
  validate,
  maintenanceController.updateRequest
);
router.put('/:id/status',
  body('status').isIn(ALLOWED_STATUSES),
  validate,
  maintenanceController.updateStatus
);
router.post('/:id/remind-caretaker', maintenanceController.remindCaretaker);

module.exports = router;
