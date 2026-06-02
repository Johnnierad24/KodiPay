const OpenAI = require('openai');
const openaiConfig = require('../config/openai');
const pool = require('../config/db');
const { buildSystemPrompt } = require('./chatbot.prompts');
const { getToolsForRole } = require('./chatbot.tools');

const openai = openaiConfig.isConfigured()
  ? new OpenAI({ apiKey: openaiConfig.apiKey, timeout: 30000 }) // 30s timeout (tool round-trips)
  : null;

// Max tool-calling round-trips before we force a final answer (cost/abuse guard).
const MAX_TOOL_ROUNDS = 4;

async function getUserProfile(userId) {
  try {
    const result = await pool.query(
      'SELECT first_name, role FROM users WHERE id = $1',
      [userId]
    );
    return result.rows[0] || {};
  } catch (error) {
    console.error('Error fetching user profile:', error);
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

/**
 * Run the chatbot for a logged-in user.
 * @param {{ id: number, role: string }} user - authenticated user from the JWT
 * @param {string} message
 */
async function processQuery(user, message) {
  try {
    if (!openai) {
      return {
        success: true,
        simulated: true,
        response:
          'KodiBot is in demo mode. Configure OPENAI_API_KEY on the server for full ' +
          'functionality. How can I help you with KodiPay today?',
      };
    }

    const profile = await getUserProfile(user.id);
    const role = user.role || profile.role || 'tenant';
    const history = await getChatHistory(user.id);
    const { definitions, executors } = getToolsForRole(role);

    const messages = [
      { role: 'system', content: buildSystemPrompt(role, profile) },
    ];

    history.forEach((chat) => {
      messages.push({ role: 'user', content: chat.message });
      messages.push({ role: 'assistant', content: chat.response });
    });

    messages.push({ role: 'user', content: message });

    // Tool-calling loop: let the model fetch data it needs, then answer.
    let response = '';
    for (let round = 0; round <= MAX_TOOL_ROUNDS; round++) {
      // On the final allowed round, drop tools so the model must produce text.
      const allowTools = round < MAX_TOOL_ROUNDS && definitions.length > 0;

      const completion = await openai.chat.completions.create({
        model: openaiConfig.model,
        max_tokens: openaiConfig.maxTokens,
        messages,
        ...(allowTools ? { tools: definitions } : {}),
      });

      const choice = completion.choices[0].message;

      if (allowTools && choice.tool_calls && choice.tool_calls.length > 0) {
        // Echo the assistant's tool-call message, then resolve each call.
        messages.push(choice);
        for (const call of choice.tool_calls) {
          const executor = executors[call.function.name];
          let toolResult;
          if (!executor) {
            toolResult = { error: `Unknown tool: ${call.function.name}` };
          } else {
            try {
              const args = call.function.arguments ? JSON.parse(call.function.arguments) : {};
              toolResult = await executor(args, user);
            } catch (err) {
              console.error(`Tool ${call.function.name} failed:`, err);
              toolResult = { error: 'That information could not be retrieved right now.' };
            }
          }
          messages.push({
            role: 'tool',
            tool_call_id: call.id,
            content: JSON.stringify(toolResult),
          });
        }
        continue; // ask the model again with tool results in context
      }

      response = choice.content || '';
      break;
    }

    if (!response) {
      response = "I'm sorry, I couldn't put together an answer just now. Please try rephrasing.";
    }

    // Async log to DB (don't block the response).
    pool
      .query(
        'INSERT INTO chatbot_logs (user_id, message, response) VALUES ($1, $2, $3)',
        [user.id, message, response]
      )
      .catch((err) => console.error('Failed to log chat:', err));

    return { success: true, response };
  } catch (error) {
    console.error('Chatbot service error:', error);

    if (error instanceof OpenAI.APIError) {
      return {
        success: false,
        error: 'The AI assistant is temporarily unavailable. Please try again in a moment.',
      };
    }

    return { success: false, error: 'Failed to process query' };
  }
}

module.exports = { processQuery };
