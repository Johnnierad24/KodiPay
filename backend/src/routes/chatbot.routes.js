const express = require('express');
const router = express.Router();
const { rateLimit } = require('express-rate-limit');
const chatbotController = require('../controllers/chatbot.controller');

// Rate limiting to prevent abuse and manage API costs
const chatbotLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // limit each IP to 20 requests per window
  message: { error: 'Too many requests from this IP, please try again after 15 minutes' },
  standardHeaders: true,
  legacyHeaders: false,
});

router.post('/chat', chatbotLimiter, chatbotController.chat);
router.get('/history', chatbotController.getChatHistory);

module.exports = router;
