const OpenAI = require('openai');
const openaiConfig = require('../config/openai');
const pool = require('../config/db');

const openai = openaiConfig.isConfigured() 
  ? new OpenAI({ apiKey: openaiConfig.apiKey, timeout: 15000 }) // 15s timeout
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

async function getUserContext(userId) {
  try {
    const userResult = await pool.query(
      `SELECT u.role, u.first_name,
              p.name as property_name, un.unit_number, un.rent_amount,
              (SELECT SUM(amount) FROM invoices WHERE tenancy_id = t.id AND status = 'pending') as pending_balance
       FROM users u
       LEFT JOIN tenancies t ON u.id = t.tenant_id AND t.status = 'active'
       LEFT JOIN units un ON t.unit_id = un.id
       LEFT JOIN properties p ON un.property_id = p.id
       WHERE u.id = $1`,
      [userId]
    );
    return userResult.rows[0] || {};
  } catch (error) {
    console.error('Error fetching user context:', error);
    return {};
  }
}

async function getChatHistory(userId, limit = 5) {
  try {
    const result = await pool.query(
      'SELECT message, response FROM chatbot_logs WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2',
      [userId, limit]
    );
    return result.rows.reverse();
  } catch (error) {
    console.error('Error fetching chat history:', error);
    return [];
  }
}

async function processQuery(userId, message) {
  try {
    if (!openai) {
      return { 
        success: true, 
        simulated: true,
        response: "Chatbot is in demo mode. Configure OPENAI_API_KEY for full functionality. How can I help you with KodiPay today?"
      };
    }

    // 1. Get User Data Context
    const userContext = await getUserContext(userId);

    // 2. Get Recent Conversation History
    const history = await getChatHistory(userId);

    // 3. Construct AI Messages
    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'system', content: `Current User Context:
        Name: ${userContext.first_name || 'User'}
        Role: ${userContext.role || 'User'}
        Property: ${userContext.property_name || 'N/A'}
        Unit: ${userContext.unit_number || 'N/A'}
        Rent Amount: ${userContext.rent_amount || 'N/A'}
        Outstanding Balance: ${userContext.pending_balance || 0}`
      }
    ];

    // Add history to context
    history.forEach(chat => {
      messages.push({ role: 'user', content: chat.message });
      messages.push({ role: 'assistant', content: chat.response });
    });

    // Add current message
    messages.push({ role: 'user', content: message });

    const completion = await openai.chat.completions.create({
      model: openaiConfig.model,
      max_tokens: openaiConfig.maxTokens,
      messages: messages
    });

    const response = completion.choices[0].message.content;

    // Async log to DB (don't block response)
    pool.query(
      'INSERT INTO chatbot_logs (user_id, message, response) VALUES ($1, $2, $3)',
      [userId, message, response]
    ).catch(err => console.error('Failed to log chat:', err));

    return { success: true, response };
  } catch (error) {
    console.error('Chatbot service error:', error);

    if (error.name === 'OpenAIError') {
      return { success: false, error: 'The AI assistant is temporarily unavailable. Please try again in a moment.' };
    }

    return { success: false, error: 'Failed to process query' };
  }
}

module.exports = { processQuery };
