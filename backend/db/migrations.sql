-- KodiPay Migration Script
-- Run this to update an existing database to the latest schema

-- Add fcm_token to users if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='fcm_token') THEN
        ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255);
    END IF;
END $$;

-- Update role constraint in users
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('landlord', 'tenant', 'caretaker', 'agent'));

-- Add related_id and related_type to notifications
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='related_id') THEN
        ALTER TABLE notifications ADD COLUMN related_id INTEGER;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='related_type') THEN
        ALTER TABLE notifications ADD COLUMN related_type VARCHAR(50);
    END IF;
END $$;

-- Create invoices table if it doesn't exist
CREATE TABLE IF NOT EXISTS invoices (
    id SERIAL PRIMARY KEY,
    tenancy_id INTEGER REFERENCES tenancies(id) ON DELETE CASCADE,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create chatbot_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS chatbot_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    response TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ensure transaction_ref is unique to prevent duplicate payments
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_transaction_ref_key;
ALTER TABLE payments ADD CONSTRAINT payments_transaction_ref_key UNIQUE (transaction_ref);

-- Create missing indexes
CREATE INDEX IF NOT EXISTS idx_invoices_tenancy ON invoices(tenancy_id);
CREATE INDEX IF NOT EXISTS idx_chatbot_user ON chatbot_logs(user_id);
