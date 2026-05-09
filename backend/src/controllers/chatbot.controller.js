const { processQuery } = require('../services/chatbot.service');

exports.chat = async (req, res) => {
  try {
    const { message } = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: 'A valid message string is required' });
    }

    if (message.length > 1000) {
      return res.status(400).json({ error: 'Message is too long (max 1000 characters)' });
    }
    
    const result = await processQuery(req.user.id, message);

    if (!result.success) {
      // Differentiate between user-facing errors and server errors
      const statusCode = result.error.includes('unavailable') ? 503 : 500;
      return res.status(statusCode).json({ error: result.error });
    }

    res.json(result);
  } catch (error) {
    console.error('Chat controller error:', error);
    res.status(500).json({ error: 'An unexpected error occurred in the chatbot' });
  }
};

exports.getChatHistory = async (req, res) => {
  try {
    const pool = require('../config/db');
    const result = await pool.query(
      'SELECT message, response, created_at FROM chatbot_logs WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Failed to fetch chat history:', error);
    res.status(500).json({ error: 'Failed to fetch chat history' });
  }
};
