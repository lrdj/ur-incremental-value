
Please follow these instructions exactly.


# 0) Scope (what this prototype will do)

* Use **SQLite** (file-based) inside the Prototype Kit.
* Model: **Organisations, Objectives, Key Results, Insights, Projects** + **weighted links** between them.
* Capture **decisions** and **experiments** that reference insights.
* Track **KR progress over time**.
* Show:

  * a **dashboard** (top OKRs, recent progress, insight links),
  * an **insight browser** (with reuse across projects/KRs),
  * a **project page** (decisions, experiments, KR contributions),
  * a simple **attribution score** per insight per KR.
* Ship with **dummy data** for **Defra**, **DBT**, **HMRC**.

---

# 1) Tech choices

* GOV.UK Prototype Kit (your current setup).
* Node 18+.
* **better-sqlite3** (fast, synchronous, minimal fuss).
* Nunjucks templates (already in kit).

Install:

```bash
npm i better-sqlite3 date-fns
```

---

# 2) Directory layout

```
/app
  /views
    okr/
      dashboard.njk
      kr.njk
    insights/
      list.njk
      detail.njk
    projects/
      list.njk
      detail.njk
  routes.js
/data
  app.db           # created by migration script
  /migrations
    001_init.sql
    002_seed.sql
/lib
  db.js
  attribution.js
```

Create missing folders as needed.

---

# 3) Database schema (minimal but powerful)

Create **/data/migrations/001\_init.sql**

```sql
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
```

---

# 4) Seed data (Defra, DBT, HMRC)

Create **/data/migrations/002\_seed.sql**

```sql
BEGIN;

INSERT INTO organization (id, name) VALUES
  (1, 'Defra'),
  (2, 'Department for Business & Trade (DBT)'),
  (3, 'HM Revenue & Customs (HMRC)');

-- Objectives & KRs
INSERT INTO objective (id, organization_id, title, owner, period_start, period_end) VALUES
  (101, 1, 'Smooth post-Brexit CHED certificate processing', 'Head of Border Sanitary Controls', '2025-01-01', '2025-12-31'),
  (201, 2, 'Understand small business needs & adapt DBT support', 'Dir. Small Business', '2025-01-01', '2025-12-31'),
  (301, 3, 'Reduce PAYE-related fraud through better user understanding', 'Head of Fraud Strategy', '2025-01-01', '2025-12-31');

INSERT INTO key_result (id, objective_id, title, target, unit, direction, owner) VALUES
  (1001, 101, 'Median CHED application processing time', 30, 'minutes', 'down', 'Ops Lead, CHED'),
  (1002, 101, 'First-time approval rate for CHEDs', 95, '%', 'up', 'Policy Lead, CHED'),
  (2001, 201, 'SMEs using the right DBT service on first try', 70, '%', 'up', 'Service Owner, SME'),
  (2002, 201, 'Average time from enquiry to matched support', 5, 'days', 'down', 'Service Owner, SME'),
  (3001, 301, 'Detected PAYE fraud cases caught pre-refund', 80, '%', 'up', 'Fraud Ops Lead'),
  (3002, 301, 'False-positive rate in PAYE fraud checks', 5, '%', 'down', 'Fraud Ops Lead');

-- KR progress timeseries (dummy monthly points)
INSERT INTO kr_progress (key_result_id, value, confidence, captured_on, note) VALUES
  (1001, 52, 0.9, '2025-03-01', 'Baseline after new form roll-out'),
  (1001, 44, 0.9, '2025-05-01', 'Queue mgmt pilot'),
  (1001, 36, 0.8, '2025-07-01', 'Vet docs checklist live'),
  (1002, 82, 0.9, '2025-03-01', 'Baseline'),
  (1002, 88, 0.9, '2025-05-01', 'Validation hints added'),
  (1002, 91, 0.8, '2025-07-01', 'Broker guidance page live'),

  (2001, 38, 0.8, '2025-02-01', 'Baseline'),
  (2001, 49, 0.8, '2025-04-01', 'Triaged landing'),
  (2001, 56, 0.8, '2025-06-01', 'Lifecycle nav'),
  (2002, 18, 0.8, '2025-02-01', 'Baseline'),
  (2002, 12, 0.8, '2025-04-01', 'Callback pledge'),
  (2002, 8,  0.8, '2025-06-01', 'Calendar booking'),

  (3001, 41, 0.8, '2025-02-01', 'Baseline'),
  (3001, 55, 0.8, '2025-05-01', 'Behavioural prompts'),
  (3001, 63, 0.8, '2025-07-01', 'Explainable flags'),
  (3002, 11, 0.8, '2025-02-01', 'Baseline'),
  (3002, 9,  0.8, '2025-05-01', 'Better comms'),
  (3002, 7,  0.8, '2025-07-01', 'Appeal UI update');

-- Insights (3 per org)
INSERT INTO insight (id, title, description, what_we_observed, why_it_matters, evidence, source, date_discovered) VALUES
  -- Defra
  (5001, 'Applicants confuse CHED-A vs CHED-D', 'Traders misclassify entry type', 'Frequent mis-selection on first screen', 'Misclassification triggers manual review and delays', 'Usability tests; call logs', 'Border control field study', '2025-02-10'),
  (5002, 'Broker-led submissions need role-specific guidance', 'Brokers skip doc checks', 'Broadsheet checklists unused', 'Drives rework and rejections', 'Broker interviews', 'Brokers association', '2025-03-05'),
  (5003, 'Veterinary doc terminology unclear', 'Users don’t recognise Latin terms', 'High abandonment at doc upload', 'Clear terms → higher first-pass success', 'Survey + analytics', 'CHED analytics', '2025-04-12'),

  -- DBT
  (5101, 'SMEs describe needs in outcomes, not services', 'They say “find buyers” not “use X tool”', 'Free-text intent mismatches IA', 'Map intents to right services', 'Diary studies', 'SME panel', '2025-01-20'),
  (5102, 'Trust increases with human callback option', 'Want named advisor', 'Self-serve only creates drop-offs', 'Hybrid model improves throughput', 'A/B test', 'DBT web analytics', '2025-03-18'),
  (5103, 'Lifecycle framing reduces cognitive load', 'Stages resonate', 'Better navigation comprehension', 'Increases correct routing', 'Tree tests', 'IA experiments', '2025-04-25'),

  -- HMRC
  (5201, 'PAYE users fear “fraud flag” stigma', 'Language causes anxiety', 'Users abandon appeals early', 'Tone impacts resolution speed', 'Content testing', 'Contact centre transcripts', '2025-02-11'),
  (5202, 'Explainable risk reasons boost compliance', 'If told why, they cooperate', 'Opaque checks → complaints', 'Explainability improves trust', 'Prototype tests', 'Risk ops', '2025-03-22'),
  (5203, 'Security mental models differ by device', 'Mobile vs desktop perceptions', 'Mismatched cues reduce trust', 'Device-aware prompts reduce errors', 'Lab tests', 'UX lab', '2025-04-30');

-- Projects
INSERT INTO project (id, organization_id, name, department, start_date, target_completion_date, current_progress) VALUES
  (9001, 1, 'CHED form redesign & broker pack', 'Border Sanitary Controls', '2025-02-01', '2025-08-31', 0.6),
  (9002, 2, 'SME intent routing & callback pilot', 'SME Services', '2025-02-15', '2025-07-31', 0.7),
  (9003, 3, 'PAYE fraud comms & explainability', 'Fraud Strategy', '2025-02-10', '2025-08-15', 0.65);

-- Project↔KR links
INSERT INTO project_kr (project_id, key_result_id, weight, note) VALUES
  (9001, 1001, 0.7, 'Reduce processing time'),
  (9001, 1002, 0.3, 'Improve first-time approval'),
  (9002, 2001, 0.6, 'Correct routing'),
  (9002, 2002, 0.4, 'Time to matched support'),
  (9003, 3001, 0.7, 'Catch fraud earlier'),
  (9003, 3002, 0.3, 'Reduce false positives');

-- Insight↔Objective (planning influence)
INSERT INTO insight_objective (insight_id, objective_id, link_type, linked_on, linked_by) VALUES
  (5001, 101, 'problem_definition', '2025-02-12', 'UX Lead'),
  (5101, 201, 'problem_definition', '2025-01-25', 'Service Owner'),
  (5201, 301, 'risk_definition',    '2025-02-14', 'Fraud PO');

-- Insight↔KR (weighted contribution)
INSERT INTO insight_kr (insight_id, key_result_id, contribution_weight, mechanism, confidence, linked_on, linked_by, note) VALUES
  (5001, 1001, 0.4, 'problem_reframed', 0.9, '2025-03-01', 'Research Lead', 'Entry type wizard'),
  (5002, 1002, 0.3, 'solution_validated', 0.8, '2025-04-10', 'Policy Lead', 'Broker pack'),
  (5003, 1002, 0.2, 'terminology_fix', 0.7, '2025-05-05', 'Content Lead', 'Glossary at upload'),

  (5101, 2001, 0.4, 'intent_mapping', 0.9, '2025-02-05', 'Service Owner', 'Outcome-based labels'),
  (5102, 2002, 0.3, 'human_support', 0.8, '2025-03-25', 'Ops Lead', 'Callback option'),
  (5103, 2001, 0.2, 'navigation_model', 0.8, '2025-04-28', 'IA Lead', 'Lifecycle nav'),

  (5201, 3002, 0.3, 'tone_of_voice', 0.8, '2025-03-05', 'Content Lead', 'Reduce threat language'),
  (5202, 3001, 0.4, 'explainable_flags', 0.9, '2025-04-02', 'Risk PO', 'Reasons panel'),
  (5203, 3001, 0.2, 'device_prompts', 0.8, '2025-05-03', 'UX Lead', 'Device-aware cues');

-- Decisions + links
INSERT INTO decision (id, project_id, objective_id, summary, rationale, decided_on, decided_by) VALUES
  (7001, 9001, 101, 'Introduce entry-type wizard', 'Reduce misclassification', '2025-03-01', 'Product Council'),
  (7002, 9002, 201, 'Add advisor callback', 'Improve trust & routing', '2025-03-20', 'Service Board'),
  (7003, 9003, 301, 'Show risk reasons', 'Increase cooperation', '2025-04-01', 'Fraud Governance');

INSERT INTO decision_insight (decision_id, insight_id, role, note) VALUES
  (7001, 5001, 'primary', 'Wizard addresses confusion'),
  (7001, 5003, 'supporting', 'Terminology inline'),
  (7002, 5102, 'primary', 'Callback drives trust'),
  (7002, 5101, 'supporting', 'Outcome phrasing'),
  (7003, 5202, 'primary', 'Explainability increase'),
  (7003, 5201, 'supporting', 'Tone tweaks');

-- Experiments + links
INSERT INTO experiment (id, project_id, hypothesis, metric_name, start_on, end_on, result, status) VALUES
  (8001, 9001, 'Wizard reduces median processing time by 20%', 'median_minutes', '2025-03-01', '2025-04-15', 'Observed -15%', 'succeeded'),
  (8002, 9002, 'Callback reduces time-to-match by 30%', 'days_to_match', '2025-03-25', '2025-05-20', 'Observed -25%', 'succeeded'),
  (8003, 9003, 'Explainable reasons increase early detection', '%pre_refund_detected', '2025-04-02', '2025-06-10', 'Observed +8pp', 'succeeded');

INSERT INTO experiment_insight (experiment_id, insight_id, role) VALUES
  (8001, 5001, 'primary'),
  (8002, 5102, 'primary'),
  (8003, 5202, 'primary');

COMMIT;
```

---

# 5) DB helpers

Create **/lib/db.js**

```js
const path = require('path');
const Database = require('better-sqlite3');

const dbPath = path.join(process.cwd(), 'data', 'app.db');
const db = new Database(dbPath);

// Run migrations if tables missing (simple check)
function migrate() {
  const pragma = db.prepare("PRAGMA user_version").get();
  // Run SQL files in order
  const fs = require('fs');
  const migDir = path.join(process.cwd(), 'data', 'migrations');
  const files = fs.readdirSync(migDir).sort();
  for (const file of files) {
    const sql = fs.readFileSync(path.join(migDir, file), 'utf8');
    db.exec(sql);
  }
}

module.exports = { db, migrate };
```

> First run will execute both migration files and create/seed the DB.

---

# 6) Simple attribution utility

Create **/lib/attribution.js**

```js
const { differenceInCalendarDays, parseISO } = require('date-fns');

// Basic normalisation for KR based on direction and latest target
function normaliseKRDelta(direction, beforeVal, afterVal) {
  if (beforeVal == null || afterVal == null) return 0;
  const delta = afterVal - beforeVal;
  return direction === 'down' ? -delta : delta; // for 'down', lower is better
}

// Time-decay weight: more recent effects count slightly more (gentle decay)
function timeDecay(capturedOn, pivotDateStr) {
  const d = parseISO(capturedOn);
  const pivot = parseISO(pivotDateStr);
  const days = Math.max(0, differenceInCalendarDays(pivot, d));
  // Half-life ~ 120 days
  return Math.pow(0.5, days / 120);
}

/**
 * Compute contribution score for an insight on a given KR
 * Score = Σ (contribution_weight × confidence × time_decay × kr_delta_normalised)
 */
function scoreInsightForKR({ progress, direction, contributionWeight, confidence, pivotDate }) {
  if (!progress || progress.length < 2) return 0;

  // Compare last two points (very simple)
  const before = progress[progress.length - 2];
  const after = progress[progress.length - 1];

  const krDelta = normaliseKRDelta(direction, before.value, after.value);
  const decay = timeDecay(after.captured_on, pivotDate);

  return (contributionWeight * (confidence ?? 1) * decay * krDelta);
}

module.exports = { scoreInsightForKR };
```

---

# 7) Routes (Express) — add to **/app/routes.js**

> Keep your existing routes; add these blocks.

```js
const express = require('express');
const router = express.Router();
const { db, migrate } = require('../lib/db');
const { scoreInsightForKR } = require('../lib/attribution');
const { format } = require('date-fns');

// Ensure DB ready
migrate();

/** Helpers */
function getKRWithProgress(krId) {
  const kr = db.prepare(`
    SELECT kr.id, kr.title, kr.unit, kr.direction, kr.owner,
           o.title AS objective_title, o.id AS objective_id, org.name AS org_name
    FROM key_result kr
    JOIN objective o ON o.id = kr.objective_id
    JOIN organization org ON org.id = o.organization_id
    WHERE kr.id = ?`).get(krId);

  const progress = db.prepare(`
    SELECT value, confidence, captured_on, note
    FROM kr_progress WHERE key_result_id = ?
    ORDER BY captured_on ASC`).all(krId);

  return { ...kr, progress };
}

/** Home → dashboard */
router.get('/', (req, res) => res.redirect('/okr/dashboard'));

router.get('/okr/dashboard', (req, res) => {
  const krs = db.prepare(`
    SELECT kr.id, kr.title, kr.unit, kr.direction,
           o.title AS objective_title, org.name AS org_name
    FROM key_result kr
    JOIN objective o ON o.id = kr.objective_id
    JOIN organization org ON org.id = o.organization_id
    ORDER BY org.name, o.title`).all();

  // attach latest progress value
  const latestStmt = db.prepare(`
    SELECT value, captured_on FROM kr_progress
    WHERE key_result_id = ?
    ORDER BY captured_on DESC LIMIT 1
  `);

  const withLatest = krs.map(kr => {
    const latest = latestStmt.get(kr.id);
    return { ...kr, latest_value: latest?.value, latest_date: latest?.captured_on };
  });

  res.render('okr/dashboard.njk', { krs: withLatest });
});

/** KR detail with linked insights and basic attribution */
router.get('/okr/kr/:id', (req, res) => {
  const krId = Number(req.params.id);
  const kr = getKRWithProgress(krId);

  const links = db.prepare(`
    SELECT i.id AS insight_id, i.title, i.why_it_matters,
           ik.contribution_weight, ik.confidence, ik.mechanism, ik.linked_on, ik.linked_by
    FROM insight_kr ik
    JOIN insight i ON i.id = ik.insight_id
    WHERE ik.key_result_id = ?
    ORDER BY ik.contribution_weight DESC, i.date_discovered ASC
  `).all(krId);

  // Compute simple score vs last progress delta
  const pivot = format(new Date(), 'yyyy-MM-dd');
  const scored = links.map(l => {
    const s = scoreInsightForKR({
      progress: kr.progress,
      direction: kr.direction,
      contributionWeight: l.contribution_weight,
      confidence: l.confidence,
      pivotDate: pivot
    });
    return { ...l, score: Number(s.toFixed(3)) };
  });

  // Projects linked to this KR
  const projects = db.prepare(`
    SELECT p.id, p.name, p.department, p.current_progress, pk.weight
    FROM project_kr pk
    JOIN project p ON p.id = pk.project_id
    WHERE pk.key_result_id = ?
    ORDER BY pk.weight DESC, p.name
  `).all(krId);

  res.render('okr/kr.njk', { kr, insights: scored, projects });
});

/** Insights browsing */
router.get('/insights', (req, res) => {
  const list = db.prepare(`
    SELECT i.id, i.title, i.date_discovered, i.source, i.why_it_matters
    FROM insight i
    ORDER BY i.date_discovered DESC`).all();
  res.render('insights/list.njk', { insights: list });
});

router.get('/insights/:id', (req, res) => {
  const id = Number(req.params.id);
  const i = db.prepare(`SELECT * FROM insight WHERE id = ?`).get(id);

  const krs = db.prepare(`
    SELECT kr.id, kr.title, ik.contribution_weight, ik.confidence, ik.mechanism
    FROM insight_kr ik
    JOIN key_result kr ON kr.id = ik.key_result_id
    WHERE ik.insight_id = ?
    ORDER BY ik.contribution_weight DESC`).all(id);

  const objs = db.prepare(`
    SELECT o.id, o.title, io.link_type
    FROM insight_objective io
    JOIN objective o ON o.id = io.objective_id
    WHERE io.insight_id = ?`).all(id);

  const decisions = db.prepare(`
    SELECT d.id, d.summary, d.decided_on, d.decided_by, p.name AS project_name
    FROM decision_insight di
    JOIN decision d ON d.id = di.decision_id
    LEFT JOIN project p ON p.id = d.project_id
    WHERE di.insight_id = ?
    ORDER BY d.decided_on DESC`).all(id);

  const experiments = db.prepare(`
    SELECT e.id, e.hypothesis, e.status, e.result, p.name AS project_name
    FROM experiment_insight ei
    JOIN experiment e ON e.id = ei.experiment_id
    JOIN project p ON p.id = e.project_id
    WHERE ei.insight_id = ?
    ORDER BY e.start_on DESC`).all(id);

  res.render('insights/detail.njk', { insight: i, krs, objs, decisions, experiments });
});

/** Projects */
router.get('/projects', (req, res) => {
  const rows = db.prepare(`
    SELECT p.id, p.name, p.department, p.current_progress, org.name AS org_name
    FROM project p JOIN organization org ON org.id = p.organization_id
    ORDER BY org.name, p.name`).all();
  res.render('projects/list.njk', { projects: rows });
});

router.get('/projects/:id', (req, res) => {
  const id = Number(req.params.id);
  const p = db.prepare(`
    SELECT p.*, org.name AS org_name
    FROM project p JOIN organization org ON org.id = p.organization_id
    WHERE p.id = ?`).get(id);

  const krs = db.prepare(`
    SELECT kr.id, kr.title, pk.weight, o.title AS objective_title
    FROM project_kr pk
    JOIN key_result kr ON kr.id = pk.key_result_id
    JOIN objective o ON o.id = kr.objective_id
    WHERE pk.project_id = ?
    ORDER BY pk.weight DESC`).all(id);

  const decisions = db.prepare(`
    SELECT d.id, d.summary, d.decided_on, d.decided_by
    FROM decision d WHERE d.project_id = ?
    ORDER BY d.decided_on DESC`).all(id);

  const experiments = db.prepare(`
    SELECT e.id, e.hypothesis, e.status, e.result
    FROM experiment e WHERE e.project_id = ?
    ORDER BY e.start_on DESC`).all(id);

  res.render('projects/detail.njk', { project: p, krs, decisions, experiments });
});

module.exports = router;
```

---

# 8) Nunjucks views

## /app/views/okr/dashboard.njk

```njk
{% extends "layouts/main.html" %}
{% block pageTitle %}OKR dashboard{% endblock %}
{% block content %}
<h1 class="govuk-heading-l">OKR dashboard</h1>
<table class="govuk-table">
  <thead class="govuk-table__head">
    <tr class="govuk-table__row">
      <th class="govuk-table__header">Organisation</th>
      <th class="govuk-table__header">Objective</th>
      <th class="govuk-table__header">Key result</th>
      <th class="govuk-table__header">Latest</th>
    </tr>
  </thead>
  <tbody class="govuk-table__body">
    {% for kr in krs %}
      <tr class="govuk-table__row">
        <td class="govuk-table__cell">{{ kr.org_name }}</td>
        <td class="govuk-table__cell">{{ kr.objective_title }}</td>
        <td class="govuk-table__cell"><a href="/okr/kr/{{ kr.id }}">{{ kr.title }}</a></td>
        <td class="govuk-table__cell">
          {% if kr.latest_value %}{{ kr.latest_value }} {{ kr.unit }} ({{ kr.latest_date }}){% else %}-{% endif %}
        </td>
      </tr>
    {% endfor %}
  </tbody>
</table>
<p class="govuk-body"><a class="govuk-link" href="/projects">View projects</a> · <a class="govuk-link" href="/insights">Browse insights</a></p>
{% endblock %}
```

## /app/views/okr/kr.njk

```njk
{% extends "layouts/main.html" %}
{% block pageTitle %}Key result{% endblock %}
{% block content %}
<h1 class="govuk-heading-l">{{ kr.title }}</h1>
<p class="govuk-body">Objective: <a href="#">{{ kr.objective_title }}</a> &middot; Organisation: {{ kr.org_name }}</p>

<h2 class="govuk-heading-m">Progress</h2>
<ul class="govuk-list govuk-list--bullet">
  {% for pt in kr.progress %}
    <li>{{ pt.captured_on }}: {{ pt.value }} {{ kr.unit }} (confidence {{ pt.confidence }}) – {{ pt.note }}</li>
  {% endfor %}
</ul>

<h2 class="govuk-heading-m">Linked insights (with simple contribution score)</h2>
<table class="govuk-table">
  <thead><tr class="govuk-table__row">
    <th class="govuk-table__header">Insight</th>
    <th class="govuk-table__header">Weight</th>
    <th class="govuk-table__header">Confidence</th>
    <th class="govuk-table__header">Mechanism</th>
    <th class="govuk-table__header">Score</th>
  </tr></thead>
  <tbody>
  {% for i in insights %}
    <tr class="govuk-table__row">
      <td class="govuk-table__cell"><a href="/insights/{{ i.insight_id }}">{{ i.title }}</a></td>
      <td class="govuk-table__cell">{{ i.contribution_weight }}</td>
      <td class="govuk-table__cell">{{ i.confidence }}</td>
      <td class="govuk-table__cell">{{ i.mechanism }}</td>
      <td class="govuk-table__cell">{{ i.score }}</td>
    </tr>
  {% endfor %}
  </tbody>
</table>

<h2 class="govuk-heading-m">Projects contributing</h2>
<ul class="govuk-list govuk-list--bullet">
  {% for p in projects %}
    <li><a href="/projects/{{ p.id }}">{{ p.name }}</a> – weight {{ p.weight }} ({{ p.department }})</li>
  {% endfor %}
</ul>

<p class="govuk-body"><a class="govuk-link" href="/okr/dashboard">Back to dashboard</a></p>
{% endblock %}
```

## /app/views/insights/list.njk

```njk
{% extends "layouts/main.html" %}
{% block pageTitle %}Insights{% endblock %}
{% block content %}
<h1 class="govuk-heading-l">Insights</h1>
<ul class="govuk-list">
  {% for i in insights %}
    <li><a href="/insights/{{ i.id }}">{{ i.title }}</a> – {{ i.date_discovered }} – {{ i.source }}</li>
  {% endfor %}
</ul>
{% endblock %}
```

## /app/views/insights/detail.njk

```njk
{% extends "layouts/main.html" %}
{% block pageTitle %}Insight{% endblock %}
{% block content %}
<h1 class="govuk-heading-l">{{ insight.title }}</h1>
<p class="govuk-body">{{ insight.description }}</p>
<p class="govuk-body"><strong>What we observed:</strong> {{ insight.what_we_observed }}</p>
<p class="govuk-body"><strong>Why it matters:</strong> {{ insight.why_it_matters }}</p>
<p class="govuk-body"><strong>Evidence:</strong> {{ insight.evidence }} · <strong>Source:</strong> {{ insight.source }} · <strong>Discovered:</strong> {{ insight.date_discovered }}</p>

<h2 class="govuk-heading-m">Influences objectives</h2>
<ul class="govuk-list govuk-list--bullet">
  {% for o in objs %}
    <li>{{ o.title }} <span class="govuk-hint">({{ o.link_type }})</span></li>
  {% endfor %}
</ul>

<h2 class="govuk-heading-m">Contributes to key results</h2>
<table class="govuk-table">
  <thead><tr class="govuk-table__row">
    <th class="govuk-table__header">Key result</th>
    <th class="govuk-table__header">Weight</th>
    <th class="govuk-table__header">Confidence</th>
    <th class="govuk-table__header">Mechanism</th>
  </tr></thead>
  <tbody>
  {% for kr in krs %}
    <tr class="govuk-table__row">
      <td class="govuk-table__cell"><a href="/okr/kr/{{ kr.id }}">{{ kr.title }}</a></td>
      <td class="govuk-table__cell">{{ kr.contribution_weight }}</td>
      <td class="govuk-table__cell">{{ kr.confidence }}</td>
      <td class="govuk-table__cell">{{ kr.mechanism }}</td>
    </tr>
  {% endfor %}
  </tbody>
</table>

<h2 class="govuk-heading-m">Decisions informed</h2>
<ul class="govuk-list govuk-list--bullet">
  {% for d in decisions %}
    <li>{{ d.decided_on }} – {{ d.summary }} <span class="govuk-hint">({{ d.project_name }})</span></li>
  {% endfor %}
</ul>

<h2 class="govuk-heading-m">Experiments linked</h2>
<ul class="govuk-list govuk-list--bullet">
  {% for e in experiments %}
    <li>{{ e.project_name }}: {{ e.hypothesis }} – <strong>{{ e.status }}</strong> {% if e.result %} ({{ e.result }}){% endif %}</li>
  {% endfor %}
</ul>

<p class="govuk-body"><a class="govuk-link" href="/insights">Back to insights</a></p>
{% endblock %}
```

## /app/views/projects/list.njk

```njk
{% extends "layouts/main.html" %}
{% block pageTitle %}Projects{% endblock %}
{% block content %}
<h1 class="govuk-heading-l">Projects</h1>
<ul class="govuk-list">
  {% for p in projects %}
    <li><a href="/projects/{{ p.id }}">{{ p.name }}</a> – {{ p.org_name }} ({{ p.department }})</li>
  {% endfor %}
</ul>
{% endblock %}
```

## /app/views/projects/detail.njk

```njk
{% extends "layouts/main.html" %}
{% block pageTitle %}Project{% endblock %}
{% block content %}
<h1 class="govuk-heading-l">{{ project.name }}</h1>
<p class="govuk-body">{{ project.org_name }} – {{ project.department }}</p>
<p class="govuk-body">Progress: {{ project.current_progress }}</p>

<h2 class="govuk-heading-m">Key results contributed to</h2>
<ul class="govuk-list govuk-list--bullet">
  {% for k in krs %}
    <li><a href="/okr/kr/{{ k.id }}">{{ k.title }}</a> – weight {{ k.weight }} <span class="govuk-hint">(Objective: {{ k.objective_title }})</span></li>
  {% endfor %}
</ul>

<h2 class="govuk-heading-m">Decisions</h2>
<ul class="govuk-list govuk-list--bullet">
  {% for d in decisions %}
    <li>{{ d.decided_on }} – {{ d.summary }} <span class="govuk-hint">({{ d.decided_by }})</span></li>
  {% endfor %}
</ul>

<h2 class="govuk-heading-m">Experiments</h2>
<ul class="govuk-list govuk-list--bullet">
  {% for e in experiments %}
    <li>{{ e.hypothesis }} – <strong>{{ e.status }}</strong> {% if e.result %} ({{ e.result }}){% endif %}</li>
  {% endfor %}
</ul>

<p class="govuk-body"><a class="govuk-link" href="/projects">Back to projects</a></p>
{% endblock %}
```

---

# 9) How to run

1. Ensure folders exist (`/data`, `/data/migrations`, `/lib`, `/app/views/...`).
2. Paste the SQL files, JS helpers, routes, and views as above.
3. Install deps:

```bash
npm i better-sqlite3 date-fns
```

4. Start the prototype:

```bash
npm start
```

The first run executes the migrations, creates `/data/app.db`, seeds it, and serves:

* **/okr/dashboard**
* **/okr/kr/\:id**
* **/projects**
* **/projects/\:id**
* **/insights**
* **/insights/\:id**

---

# 10) Notes for Codex (what “good” looks like)

* Keep to **UK English** in UI copy.
* Use GOV.UK Design System classes (`govuk-*`) as shown.
* Don’t add write forms yet; read-only is fine for demo.
* Use **weighted links** (`insight_kr.contribution_weight`, `confidence`, `mechanism`).
* The attribution is intentionally simple; it’s enough to **show the idea**:

  * We look at the last two KR progress points and compute a tiny score per insight factoring **weight × confidence × time-decay × KR delta**.
* Keep everything in SQLite to avoid infra faff.

---

Please also extend this with quick **POST routes + forms** to add a new insight and link it to a KR with a weight (0.1/0.3/0.6 presets).

