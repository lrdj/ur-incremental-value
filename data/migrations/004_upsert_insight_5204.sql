BEGIN;

-- Add or update sample insight 5204 (leaders lacking a sounding board)
INSERT INTO insight (
  id, title, description, what_we_observed, why_it_matters,
  evidence, source, date_discovered, contains_pii
) VALUES (
  5204,
  'Leaders need a trusted sounding board',
  'Senior leaders told us they often have no one to talk to about the practical challenges of running the business. This creates isolation, decision fatigue and slower action on important issues.',
  'Owners and senior managers hesitated to engage with services and instead asked for “someone to talk to”. Complex enquiries became long email threads. In several cases, advisors were informally used as coaches to help think through trade‑offs.',
  'Without a trusted sounding board, leaders delay or avoid decisions, which increases time to the right support and the risk of missteps. Providing a named advisor or structured peer support can speed up routing and improve outcomes.',
  'Qualitative interviews with SME owners; contact centre transcripts; diary study entries on isolation and decision fatigue',
  'SME panel and contact centre',
  '2025-05-15',
  0
)
ON CONFLICT(id) DO UPDATE SET
  title = excluded.title,
  description = excluded.description,
  what_we_observed = excluded.what_we_observed,
  why_it_matters = excluded.why_it_matters,
  evidence = excluded.evidence,
  source = excluded.source,
  date_discovered = excluded.date_discovered,
  contains_pii = excluded.contains_pii;

COMMIT;

