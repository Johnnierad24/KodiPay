const pool = require('../config/db');

async function setupPhase3Tables() {
  try {
    // Add FCM token to users table
    await pool.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(255);
    `);
    console.log('✓ Added fcm_token column to users table');

    // Create notifications table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT,
        related_id INTEGER,
        related_type VARCHAR(50),
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✓ Created notifications table');

    // Create invoices table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS invoices (
        id SERIAL PRIMARY KEY,
        tenancy_id INTEGER NOT NULL REFERENCES tenancies(id) ON DELETE CASCADE,
        month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
        year INTEGER NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        due_date DATE NOT NULL,
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(tenancy_id, month, year)
      );
    `);
    console.log('✓ Created invoices table');

    console.log('\nPhase 3 database setup complete!');
  } catch (error) {
    console.error('Setup failed:', error.message);
  } finally {
    await pool.end();
  }
}

setupPhase3Tables();
