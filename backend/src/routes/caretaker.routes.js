const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const caretakerController = require('../controllers/caretaker.controller');
const checkRole = require('../middleware/role.middleware');
const validate = require('../middleware/validate');
const { createLimiter } = require('../middleware/rateLimiters');
const { validateName, validateEmail, validatePhone } = require('../utils/validators');

router.get('/', checkRole(['landlord', 'agent']), caretakerController.listMyCaretakers);
router.post('/',
  checkRole(['landlord', 'agent']),
  createLimiter,
  validateEmail('email'),
  body('property_id').isInt({ min: 1 }).toInt(),
  validateName('first_name', { optional: true }),
  validateName('last_name', { optional: true }),
  validatePhone('phone'),
  validate,
  caretakerController.assignCaretaker
);
router.put('/:caretakerId',
  checkRole(['landlord', 'agent']),
  validateName('first_name', { optional: true }),
  validateName('last_name', { optional: true }),
  validatePhone('phone'),
  validate,
  caretakerController.updateCaretaker
);
router.delete('/:id', checkRole(['landlord', 'agent']), caretakerController.removeCaretaker);

router.get('/my-properties', caretakerController.getMyProperties);
router.get('/my-units', caretakerController.getMyUnits);
router.put('/units/:unitId/vacancy', caretakerController.reportVacancy);

module.exports = router;
