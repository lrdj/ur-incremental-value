BEGIN;

-- Link insight 5204 to DBT objective and KR (time to matched support)
INSERT OR IGNORE INTO insight_objective (insight_id, objective_id, link_type, linked_on, linked_by)
VALUES (5204, 201, 'support_model', '2025-05-20', 'Service Owner');

INSERT OR IGNORE INTO insight_kr (
  insight_id, key_result_id, contribution_weight, mechanism, confidence, linked_on, linked_by, note
) VALUES (
  5204, 2002, 0.3, 'human_support', 0.8, '2025-05-22', 'Service Owner', 'Named advisor / peer support'
);

COMMIT;

