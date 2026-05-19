const pool = require('../config/db');

async function setupDocumentsTable() {
  try {
    await pool.query(`
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
    `);
    console.log('✓ Created documents table');

    await pool.query('CREATE INDEX IF NOT EXISTS idx_documents_property ON documents(property_id);');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_documents_unit ON documents(unit_id);');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_documents_tenant ON documents(tenant_id);');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_documents_tenancy ON documents(tenancy_id);');
    await pool.query('CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(type);');
    await pool.query("CREATE INDEX IF NOT EXISTS idx_documents_expires_on ON documents(expires_on) WHERE expires_on IS NOT NULL;");
    console.log('✓ Created documents indexes');

    console.log('\nDocuments table setup complete!');
  } catch (error) {
    console.error('Setup failed:', error.message);
  } finally {
    await pool.end();
  }
}

setupDocumentsTable();
