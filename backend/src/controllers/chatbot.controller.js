const { processQuery } = require('../services/chatbot.service');

exports.chat = async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) return res.status(400).json({ error: 'Message required' });
    
    const result = await processQuery(req.user.id, message);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: 'Chatbot error' });
  }
};

exports.getChatHistory = async (req, res) => {
  try {
    const pool = require('../config/db');
    const result = await pool.query(
      'SELECT * FROM chatbot_logs WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch chat history' });
  }
};
