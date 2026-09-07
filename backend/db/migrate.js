const fs = require('fs');
const path = require('path');
const pool = require('../src/config/db');

// Ordered list of migrations. Each runs exactly once per database, tracked by
// its own version token in schema_migrations. `file` is read relative to this
// directory; `sql` (inline) is used as-is. Inline SQL avoids any risk of the
// statement file being dropped from a serverless bundle.
const ESCROW_MIGRATION_SQL = `
CREATE TABLE IF NOT EXISTS escrow_ledger (
    id SERIAL PRIMARY KEY,
    landlord_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'debit')),
    amount DECIMAL(10,2) NOT NULL,
    reference VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_escrow_ledger_landlord ON escrow_ledger(landlord_id);
CREATE INDEX IF NOT EXISTS idx_escrow_ledger_type ON escrow_ledger(landlord_id, type);
`;

const MIGRATIONS = [
  { version: 'baseline-2026-09-02', file: 'migrations.sql' },
  { version: 'escrow-2026-09-04', sql: ESCROW_MIGRATION_SQL },
];

// Splits the SQL file into top-level statements, respecting DO $$ ... $$ blocks
// and ignoring '--' line comments (which would otherwise corrupt boundaries).
function splitStatements(sql) {
  const statements = [];
  let current = '';
  let inDollar = false;
  for (let i = 0; i < sql.length; i++) {
    if (!inDollar && sql[i] === '$' && sql[i + 1] === '$') { inDollar = true; current += '$$'; i++; continue; }
    if (inDollar && sql[i] === '$' && sql[i + 1] === '$') { inDollar = false; current += '$$'; i++; continue; }
    if (!inDollar && sql[i] === '-' && sql[i + 1] === '-') {
      while (i < sql.length && sql[i] !== '\n') i++;
      continue;
    }
    if (!inDollar && sql[i] === ';') { statements.push(current.trim()); current = ''; continue; }
    current += sql[i];
  }
  if (current.trim()) statements.push(current.trim());
  return statements.filter((s) => s.length > 0);
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Applies the idempotent schema migrations once per database, tracking each
// migration's completion independently in schema_migrations. Runs on a
// dedicated client and retries to ride out transient cold-start TLS hiccups.
// Failures are logged but never block the server from starting.
async function runMigrations(attempt = 1) {
  if (process.env.AUTO_MIGRATE === 'false') return { success: true, skipped: true };
  const client = await pool.connect();
  try {
    await client.query('CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(64) PRIMARY KEY, applied_at TIMESTAMPTZ DEFAULT now())');
    const missing = [];
    for (const m of MIGRATIONS) {
      const existing = await client.query('SELECT 1 FROM schema_migrations WHERE version = $1', [m.version]);
      if (existing.rowCount === 0) missing.push(m);
    }
    if (missing.length === 0) {
      console.log('KodiPay migrations already applied.');
      return { success: true, applied: false };
    }
    const baseDir = __dirname;
    for (const m of missing) {
      const sql = m.sql || fs.readFileSync(path.join(baseDir, m.file), 'utf8');
      for (const statement of splitStatements(sql)) {
        await client.query(statement);
      }
      await client.query('INSERT INTO schema_migrations (version) VALUES ($1)', [m.version]);
      console.log(`KodiPay migration applied: ${m.version}`);
    }
    return { success: true, applied: true };
  } catch (error) {
    const hint = error.message;
    if (attempt < 3) {
      console.error(`Migration bootstrap attempt ${attempt} failed (retrying): ${hint}`);
      await sleep(attempt * 2000);
      return runMigrations(attempt + 1);
    }
    console.error('Migration bootstrap failed (app will continue):', hint);
    return { success: false, error: hint };
  } finally {
    client.release();
  }
}

module.exports = { runMigrations };

let migrationPromise = null;
// Memoized entry used by server middleware so the first request awaits the
// bootstrap to completion (serverless runtimes freeze background work after the
// response is flushed; awaiting inside a request keeps the process alive).
function ensureMigrated() {
  if (!migrationPromise) migrationPromise = runMigrations();
  return migrationPromise;
}

module.exports = { runMigrations, ensureMigrated };