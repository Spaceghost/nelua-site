CREATE TABLE IF NOT EXISTS app_config (id INTEGER PRIMARY KEY CHECK (id = 1), value TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY, login TEXT NOT NULL, name TEXT NOT NULL,
  installation_id INTEGER, selection TEXT, consent INTEGER NOT NULL DEFAULT 0,
  version INTEGER NOT NULL DEFAULT 0, totals TEXT, counted_at INTEGER
);
CREATE TABLE IF NOT EXISTS sessions (
  hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  csrf TEXT NOT NULL, expires INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS states (
  hash TEXT PRIMARY KEY, purpose TEXT NOT NULL, payload TEXT NOT NULL, expires INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS scan_tasks (
  hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  version INTEGER NOT NULL, repository_count INTEGER NOT NULL,
  run_id TEXT NOT NULL, expires INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_expiry ON sessions(expires);
CREATE INDEX IF NOT EXISTS states_expiry ON states(expires);
CREATE INDEX IF NOT EXISTS users_installation ON users(installation_id);
