PRAGMA foreign_keys = ON;

-- Core
CREATE TABLE organization (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE objective (
  id INTEGER PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organization(id),
  title TEXT NOT NULL,
  owner TEXT,
  period_start DATE,
  period_end DATE,
  status TEXT DEFAULT 'active',
  parent_objective_id INTEGER REFERENCES objective(id)
);

CREATE TABLE key_result (
  id INTEGER PRIMARY KEY,
  objective_id INTEGER NOT NULL REFERENCES objective(id),
  title TEXT NOT NULL,
  target REAL,
  unit TEXT,
  direction TEXT CHECK(direction IN ('up','down')) DEFAULT 'up',
  owner TEXT
);

CREATE TABLE kr_progress (
  id INTEGER PRIMARY KEY,
  key_result_id INTEGER NOT NULL REFERENCES key_result(id),
  value REAL NOT NULL,
  confidence REAL DEFAULT 1.0,
  captured_on DATE NOT NULL,
  note TEXT
);

-- Research
CREATE TABLE insight (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  what_we_observed TEXT,
  why_it_matters TEXT,
  evidence TEXT,
  source TEXT,
  date_discovered DATE NOT NULL,
  contains_pii INTEGER DEFAULT 0
);

-- Delivery
CREATE TABLE project (
  id INTEGER PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organization(id),
  name TEXT NOT NULL,
  department TEXT,
  start_date DATE,
  target_completion_date DATE,
  current_progress REAL DEFAULT 0.0
);

-- Governance / decisions / experiments
CREATE TABLE decision (
  id INTEGER PRIMARY KEY,
  project_id INTEGER REFERENCES project(id),
  objective_id INTEGER REFERENCES objective(id),
  summary TEXT NOT NULL,
  rationale TEXT,
  decided_on DATE NOT NULL,
  decided_by TEXT
);

CREATE TABLE experiment (
  id INTEGER PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES project(id),
  hypothesis TEXT NOT NULL,
  metric_name TEXT,
  start_on DATE,
  end_on DATE,
  result TEXT,
  status TEXT CHECK(status IN ('planned','running','succeeded','failed','inconclusive')) DEFAULT 'planned'
);

-- Weighted links (influence)
CREATE TABLE insight_objective (
  insight_id INTEGER NOT NULL REFERENCES insight(id),
  objective_id INTEGER NOT NULL REFERENCES objective(id),
  link_type TEXT,
  linked_on DATE NOT NULL,
  linked_by TEXT,
  PRIMARY KEY (insight_id, objective_id)
);

CREATE TABLE insight_kr (
  insight_id INTEGER NOT NULL REFERENCES insight(id),
  key_result_id INTEGER NOT NULL REFERENCES key_result(id),
  contribution_weight REAL NOT NULL CHECK(contribution_weight >= 0 AND contribution_weight <= 1),
  mechanism TEXT, -- e.g. problem_reframed / risk_avoided / solution_validated
  confidence REAL DEFAULT 1.0,
  linked_on DATE NOT NULL,
  linked_by TEXT,
  note TEXT,
  PRIMARY KEY (insight_id, key_result_id)
);

CREATE TABLE project_kr (
  project_id INTEGER NOT NULL REFERENCES project(id),
  key_result_id INTEGER NOT NULL REFERENCES key_result(id),
  weight REAL DEFAULT 1.0,
  note TEXT,
  PRIMARY KEY (project_id, key_result_id)
);

CREATE TABLE decision_insight (
  decision_id INTEGER NOT NULL REFERENCES decision(id),
  insight_id INTEGER NOT NULL REFERENCES insight(id),
  role TEXT, -- primary/supporting
  note TEXT,
  PRIMARY KEY (decision_id, insight_id)
);

CREATE TABLE experiment_insight (
  experiment_id INTEGER NOT NULL REFERENCES experiment(id),
  insight_id INTEGER NOT NULL REFERENCES insight(id),
  role TEXT,
  PRIMARY KEY (experiment_id, insight_id)
);

-- Convenience indexes
CREATE INDEX idx_progress_kr_date ON kr_progress(key_result_id, captured_on);
CREATE INDEX idx_insight_date ON insight(date_discovered);
CREATE INDEX idx_insight_kr ON insight_kr(key_result_id, insight_id);

