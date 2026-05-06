const OpenAI = require('openai');
const openaiConfig = require('../config/openai');
const pool = require('../config/db');

const openai = openaiConfig.isConfigured() 
  ? new OpenAI({ apiKey: openaiConfig.apiKey })
  : null;

const SYSTEM_PROMPT = `You are KodiBot, an AI assistant for KodiPay - a rental management platform for landlords, tenants, and caretakers.

Your role is to:
1. Help users navigate the app (properties, tenants, payments, maintenance)
2. Answer questions about rental management features
3. Assist with accessibility needs (screen reader friendly responses)
4. Provide quick answers to FAQs about rent, payments, and maintenance
5. Guide users through common tasks

Keep responses concise, clear, and helpful. Use simple language for accessibility.
If you don't know something, say so and suggest contacting support.`;

async function processQuery(userId, message) {
  try {
    if (!openai) {
      return { 
        success: true, 
        simulated: true,
        response: "Chatbot is in demo mode. Configure OPENAI_API_KEY for full functionality. How can I help you with KodiPay today?"
      };
    }

    const userResult = await pool.query(
      'SELECT role, first_name FROM users WHERE id = $1',
      [userId]
    );
    const user = userResult.rows[0] || {};

    const completion = await openai.chat.completions.create({
      model: openaiConfig.model,
      max_tokens: openaiConfig.maxTokens,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: `User (${user.role || 'user'} ${user.first_name || ''}): ${message}` }
      ]
    });

    const response = completion.choices[0].message.content;

    await pool.query(
      'INSERT INTO chatbot_logs (user_id, message, response) VALUES ($1, $2, $3)',
      [userId, message, response]
    ).catch(() => {});

    return { success: true, response };
  } catch (error) {
    console.error('Chatbot error:', error.message);
    return { success: false, error: 'Failed to process query' };
  }
}

module.exports = { processQuery };
