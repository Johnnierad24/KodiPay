const express = require('express');
const router = express.Router();
const caretakerController = require('../controllers/caretaker.controller');

router.get('/', caretakerController.listMyCaretakers);
router.post('/', caretakerController.assignCaretaker);
router.delete('/:id', caretakerController.removeCaretaker);

module.exports = router;
