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

