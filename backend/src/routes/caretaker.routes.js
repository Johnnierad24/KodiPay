const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const caretakerController = require('../controllers/caretaker.controller');
const checkRole = require('../middleware/role.middleware');
const validate = require('../middleware/validate');
const { createLimiter } = require('../middleware/rateLimiters');

router.get('/', checkRole(['landlord', 'agent']), caretakerController.listMyCaretakers);
router.post('/',
  checkRole(['landlord', 'agent']),
  createLimiter,
  body('email').isEmail().normalizeEmail(),
  body('property_id').isInt({ min: 1 }),
  body('first_name').optional().trim().isLength({ max: 100 }),
  body('last_name').optional().trim().isLength({ max: 100 }),
  body('phone').optional().trim().isLength({ max: 20 }),
  validate,
  caretakerController.assignCaretaker
);
router.put('/:caretakerId',
  checkRole(['landlord', 'agent']),
  body('first_name').optional().trim().notEmpty().isLength({ max: 100 }),
  body('last_name').optional().trim().notEmpty().isLength({ max: 100 }),
  body('phone').optional().trim().isLength({ max: 20 }),
  validate,
  caretakerController.updateCaretaker
);
router.delete('/:id', checkRole(['landlord', 'agent']), caretakerController.removeCaretaker);

router.get('/my-properties', caretakerController.getMyProperties);
router.get('/my-units', caretakerController.getMyUnits);
router.put('/units/:unitId/vacancy', caretakerController.reportVacancy);

module.exports = router;
