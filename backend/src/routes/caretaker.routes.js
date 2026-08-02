const express = require('express');
const router = express.Router();
const caretakerController = require('../controllers/caretaker.controller');

router.get('/', caretakerController.listMyCaretakers);
router.post('/', caretakerController.assignCaretaker);
router.delete('/:id', caretakerController.removeCaretaker);

router.get('/my-properties', caretakerController.getMyProperties);
router.get('/my-units', caretakerController.getMyUnits);
router.put('/units/:unitId/vacancy', caretakerController.reportVacancy);

module.exports = router;
