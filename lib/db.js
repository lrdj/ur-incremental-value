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

// Run migrations if core tables missing
function migrate() {
  if (tableExists('organization')) return; // assume already migrated/seeded

  const files = fs
    .readdirSync(migDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();
  for (const file of files) {
    const sql = fs.readFileSync(path.join(migDir, file), 'utf8');
    db.exec(sql);
  }
}

module.exports = { db, migrate };

