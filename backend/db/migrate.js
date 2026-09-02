const fs = require('fs');
const path = require('path');
const pool = require('../src/config/db');

const MIGRATION_VERSION = 'baseline-2026-09-02';

// Splits the SQL file into top-level statements, respecting DO $$ ... $$ blocks.
function splitStatements(sql) {
  const statements = [];
  let current = '';
  let inDollar = false;
  for (let i = 0; i < sql.length; i++) {
    if (!inDollar && sql[i] === '$' && sql[i + 1] === '$') { inDollar = true; current += '$$'; i++; continue; }
    if (inDollar && sql[i] === '$' && sql[i + 1] === '$') { inDollar = false; current += '$$'; i++; continue; }
    if (!inDollar && sql[i] === ';') { statements.push(current.trim()); current = ''; continue; }
    current += sql[i];
  }
  if (current.trim()) statements.push(current.trim());
  return statements.filter((s) => s.length > 0);
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Applies the idempotent schema migrations (db/migrations.sql) once per
// database, tracking completion in schema_migrations. Runs on a dedicated
// client and retries to ride out transient cold-start TLS hiccups. Failures are
// logged but never block the server from starting.
async function runMigrations(attempt = 1) {
  if (process.env.AUTO_MIGRATE === 'false') return { success: true, skipped: true };
  const client = await pool.connect();
  try {
    await client.query('CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(64) PRIMARY KEY, applied_at TIMESTAMPTZ DEFAULT now())');
    const existing = await client.query('SELECT 1 FROM schema_migrations WHERE version = $1', [MIGRATION_VERSION]);
    if (existing.rowCount > 0) {
      console.log('KodiPay migrations already applied.');
      return { success: true, applied: false };
    }
    const sql = fs.readFileSync(path.join(__dirname, 'migrations.sql'), 'utf8');
    for (const statement of splitStatements(sql)) {
      await client.query(statement);
    }
    await client.query('INSERT INTO schema_migrations (version) VALUES ($1)', [MIGRATION_VERSION]);
    console.log('KodiPay migrations applied successfully.');
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