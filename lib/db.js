const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');

const dataDir = path.join(process.cwd(), 'data');
const migDir = path.join(dataDir, 'migrations');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });
if (!fs.existsSync(migDir)) fs.mkdirSync(migDir, { recursive: true });

const dbPath = path.join(dataDir, 'app.db');
const db = new Database(dbPath);

function tableExists(name) {
  const row = db
    .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name = ?")
    .get(name);
  return !!row;
}

// Run migrations incrementally based on filename tracking
function migrate() {
  // Create migrations ledger
  db.exec(`CREATE TABLE IF NOT EXISTS __migrations (
    name TEXT PRIMARY KEY,
    applied_at TEXT NOT NULL
  )`);

  // If this is an existing DB from earlier versions (tables exist but no ledger),
  // mark 001 and 002 as applied to avoid re-running schema/seed.
  const hasLedgerSeed = db
    .prepare("SELECT 1 FROM __migrations WHERE name IN ('001_init.sql','002_seed.sql') LIMIT 1")
    .get();
  if (!hasLedgerSeed && tableExists('organization')) {
    const now = new Date().toISOString();
    const ins = db.prepare('INSERT OR IGNORE INTO __migrations (name, applied_at) VALUES (?, ?)');
    ins.run('001_init.sql', now);
    ins.run('002_seed.sql', now);
  }

  const applied = new Set(
    db.prepare('SELECT name FROM __migrations').all().map((r) => r.name)
  );

  const files = fs
    .readdirSync(migDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  const insertMig = db.prepare('INSERT INTO __migrations (name, applied_at) VALUES (?, ?)');

  for (const file of files) {
    if (applied.has(file)) continue;
    const sql = fs.readFileSync(path.join(migDir, file), 'utf8');
    // Execute the migration script as-is (it may contain its own BEGIN/COMMIT)
    db.exec(sql);
    // Record as applied
    insertMig.run(file, new Date().toISOString());
  }
}

module.exports = { db, migrate };
