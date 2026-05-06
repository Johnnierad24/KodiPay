const pool = require('../config/db');

async function setupPhase4Tables() {
  try {
    // Create chatbot_logs table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS chatbot_logs (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        message TEXT NOT NULL,
        response TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✓ Created chatbot_logs table');

    console.log('\nPhase 4 database setup complete!');
  } catch (error) {
    console.error('Setup failed:', error.message);
  } finally {
    await pool.end();
  }
}

setupPhase4Tables();
