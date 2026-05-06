const express = require('express');
const router = express.Router();
const chatbotController = require('../controllers/chatbot.controller');

router.post('/chat', chatbotController.chat);
router.get('/history', chatbotController.getChatHistory);

module.exports = router;
