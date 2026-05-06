require('dotenv').config();

module.exports = {
  apiKey: process.env.OPENAI_API_KEY || '',
  model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
  maxTokens: parseInt(process.env.OPENAI_MAX_TOKENS) || 500
};

module.exports.isConfigured = function() {
  return !!process.env.OPENAI_API_KEY;
};
