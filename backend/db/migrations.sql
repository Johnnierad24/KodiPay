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

-- Create password reset tokens table if it doesn't exist
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ensure transaction_ref is unique to prevent duplicate payments
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_transaction_ref_key;
ALTER TABLE payments ADD CONSTRAINT payments_transaction_ref_key UNIQUE (transaction_ref);

-- Create missing indexes
CREATE INDEX IF NOT EXISTS idx_invoices_tenancy ON invoices(tenancy_id);
CREATE INDEX IF NOT EXISTS idx_chatbot_user ON chatbot_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_user ON password_reset_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_token ON password_reset_tokens(token_hash);

-- Documents table (leases, receipts, agreements, other uploads)
CREATE TABLE IF NOT EXISTS documents (
    id SERIAL PRIMARY KEY,
    property_id INTEGER REFERENCES properties(id) ON DELETE CASCADE,
    unit_id INTEGER REFERENCES units(id) ON DELETE SET NULL,
    tenant_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    tenancy_id INTEGER REFERENCES tenancies(id) ON DELETE SET NULL,
    payment_id INTEGER REFERENCES payments(id) ON DELETE SET NULL,
    uploaded_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('lease', 'receipt', 'agreement', 'other')),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    mime_type VARCHAR(100),
    size_bytes INTEGER,
    generated BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    starts_on DATE,
    expires_on DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_documents_property ON documents(property_id);
CREATE INDEX IF NOT EXISTS idx_documents_unit ON documents(unit_id);
CREATE INDEX IF NOT EXISTS idx_documents_tenant ON documents(tenant_id);
CREATE INDEX IF NOT EXISTS idx_documents_tenancy ON documents(tenancy_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(type);
CREATE INDEX IF NOT EXISTS idx_documents_expires_on ON documents(expires_on) WHERE expires_on IS NOT NULL;

-- Maintenance: add category column and expand priority to include 'emergency'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='maintenance_requests' AND column_name='category') THEN
        ALTER TABLE maintenance_requests ADD COLUMN category VARCHAR(30) DEFAULT 'other';
    END IF;
END $$;

ALTER TABLE maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_category_check;
ALTER TABLE maintenance_requests ADD CONSTRAINT maintenance_requests_category_check
    CHECK (category IN ('electrical', 'structural', 'plumbing', 'other'));

ALTER TABLE maintenance_requests DROP CONSTRAINT IF EXISTS maintenance_requests_priority_check;
ALTER TABLE maintenance_requests ADD CONSTRAINT maintenance_requests_priority_check
    CHECK (priority IN ('low', 'medium', 'high', 'urgent', 'emergency'));
