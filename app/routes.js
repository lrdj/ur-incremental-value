//
// For guidance on how to create routes see:
// https://prototype-kit.service.gov.uk/docs/create-routes
//

const govukPrototypeKit = require('govuk-prototype-kit')
const router = govukPrototypeKit.requests.setupRouter()

// App routes
const { db, migrate } = require('../lib/db');
const { scoreInsightForKR } = require('../lib/attribution');
const { format } = require('date-fns');

// Ensure DB ready on first load
migrate();

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

// Home → dashboard
router.get('/', (req, res) => res.redirect('/okr/dashboard'))

router.get('/okr/dashboard', (req, res) => {
  const krs = db.prepare(`
    SELECT kr.id, kr.title, kr.unit, kr.direction,
           o.title AS objective_title, org.name AS org_name
    FROM key_result kr
    JOIN objective o ON o.id = kr.objective_id
    JOIN organization org ON org.id = o.organization_id
    ORDER BY org.name, o.title`).all();

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

// KR detail
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

  const projects = db.prepare(`
    SELECT p.id, p.name, p.department, p.current_progress, pk.weight
    FROM project_kr pk
    JOIN project p ON p.id = pk.project_id
    WHERE pk.key_result_id = ?
    ORDER BY pk.weight DESC, p.name
  `).all(krId);

  res.render('okr/kr.njk', { kr, insights: scored, projects });
});

// Insights list
router.get('/insights', (req, res) => {
  const list = db.prepare(`
    SELECT i.id, i.title, i.date_discovered, i.source, i.why_it_matters
    FROM insight i
    ORDER BY i.date_discovered DESC`).all();
  res.render('insights/list.njk', { insights: list });
});

// New insight form
router.get('/insights/new', (req, res) => {
  const krs = db.prepare(`
    SELECT kr.id, kr.title, o.title AS objective_title, org.name AS org_name
    FROM key_result kr
    JOIN objective o ON o.id = kr.objective_id
    JOIN organization org ON org.id = o.organization_id
    ORDER BY org.name, o.title, kr.title`).all();
  res.render('insights/new.njk', { krs });
});

// Create insight + link
router.post('/insights/new', (req, res) => {
  const body = req.body || {};
  const {
    title,
    description,
    what_we_observed,
    why_it_matters,
    evidence,
    source,
    date_discovered,
    kr_id,
    weight,
    confidence,
    mechanism
  } = body;

  if (!title || !date_discovered || !kr_id || !weight) {
    req.session.data.error = 'Please fill in the required fields.'
    return res.redirect('/insights/new');
  }

  // Insert insight
  const insertInsight = db.prepare(`
    INSERT INTO insight (title, description, what_we_observed, why_it_matters, evidence, source, date_discovered)
    VALUES (?, ?, ?, ?, ?, ?, ?)`);
  const info = insertInsight.run(
    title,
    description || null,
    what_we_observed || null,
    why_it_matters || null,
    evidence || null,
    source || null,
    date_discovered
  );
  const newId = info.lastInsertRowid;

  // Link to KR
  db.prepare(`
    INSERT INTO insight_kr (insight_id, key_result_id, contribution_weight, mechanism, confidence, linked_on, linked_by)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(
    newId,
    Number(kr_id),
    Number(weight),
    mechanism || null,
    confidence ? Number(confidence) : 0.8,
    format(new Date(), 'yyyy-MM-dd'),
    'Prototype user'
  );

  res.redirect(`/insights/${newId}`);
});

// Insight detail
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

// Projects
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

module.exports = router
