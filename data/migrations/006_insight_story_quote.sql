BEGIN;

-- Add optional narrative and quote fields to insights
ALTER TABLE insight ADD COLUMN persona_story_title TEXT;
ALTER TABLE insight ADD COLUMN persona_story_body TEXT;
ALTER TABLE insight ADD COLUMN vox_pop_quote TEXT;
ALTER TABLE insight ADD COLUMN vox_pop_attribution TEXT;

-- Defra
UPDATE insight SET
  persona_story_title = 'Marco’s submission hiccup',
  persona_story_body = 'Marco, a trader, is filing late on Thursday. On the first screen he pauses — CHED‑A or CHED‑D? He guesses, thinking it''s just a different page, and the case is routed for manual review. The weekend rolls by before anyone can fix it.',
  vox_pop_quote = 'I thought A and D were just different pages of the same thing.',
  vox_pop_attribution = 'Import broker, usability session'
WHERE id = 5001;

UPDATE insight SET
  persona_story_title = 'Jai’s rushed handover',
  persona_story_body = 'Jai, a junior broker, submits a CHED close to a deadline. He assumes another colleague will double‑check the veterinary paperwork. The submission is rejected and has to be resubmitted on Monday — frustration on both sides.',
  vox_pop_quote = 'I usually just send it through — someone else will catch it if it’s wrong.',
  vox_pop_attribution = 'Junior broker, interview'
WHERE id = 5002;

UPDATE insight SET
  persona_story_title = 'Lina vs Latin',
  persona_story_body = 'Lina reaches the document upload step and stalls on unfamiliar Latin terms. She searches for the common name, then abandons the flow after two attempts.',
  vox_pop_quote = 'I don’t know the Latin name, and I’m scared of picking the wrong thing.',
  vox_pop_attribution = 'Trader, survey follow‑up'
WHERE id = 5003;

-- DBT
UPDATE insight SET
  persona_story_title = 'Sara wants buyers, not brands',
  persona_story_body = 'Sara is looking to expand sales overseas. The site lists product names and branded services; she just wants to “find buyers” and ends up submitting a vague enquiry.',
  vox_pop_quote = 'Don’t tell me the tool, help me find buyers for my product.',
  vox_pop_attribution = 'SME owner, diary study'
WHERE id = 5101;

UPDATE insight SET
  persona_story_title = 'Owen hesitates without a human option',
  persona_story_body = 'Owen completes the form but stops before submitting. He wants to talk it through with an advisor in case he’s missing something important.',
  vox_pop_quote = 'Can I talk to someone before I send this?',
  vox_pop_attribution = 'SME, A/B test post‑survey'
WHERE id = 5102;

UPDATE insight SET
  persona_story_title = 'Amina follows the lifecycle',
  persona_story_body = 'Amina is starting up. A lifecycle view (“Start, grow, export”) helps her orient quickly and pick the next step without reading long pages.',
  vox_pop_quote = 'Stages make sense. I know where I am and what’s next.',
  vox_pop_attribution = 'Prospective founder, tree test'
WHERE id = 5103;

-- HMRC
UPDATE insight SET
  persona_story_title = 'Tom fears the “fraud flag”',
  persona_story_body = 'Tom opens an appeal but the strong warning language makes him anxious about long‑term consequences. He drops out and phones instead, worried it will be “on his record”.',
  vox_pop_quote = 'Will this go on my record? I don’t want to be labelled.',
  vox_pop_attribution = 'Claimant, contact centre transcript'
WHERE id = 5201;

UPDATE insight SET
  persona_story_title = 'Priya cooperates when told why',
  persona_story_body = 'Priya receives a check with a short explanation of the risk reasons. She understands what evidence to provide and resolves it quickly.',
  vox_pop_quote = 'If you tell me why, I can sort it faster.',
  vox_pop_attribution = 'Taxpayer, prototype test'
WHERE id = 5202;

UPDATE insight SET
  persona_story_title = 'Ben reads security cues differently',
  persona_story_body = 'On mobile, an SMS link feels fine; on desktop, the same link looks suspicious. Ben trusts different patterns on different devices.',
  vox_pop_quote = 'On my phone it feels normal — on my laptop it looks dodgy.',
  vox_pop_attribution = 'Participant, lab test'
WHERE id = 5203;

-- Additional (5204)
UPDATE insight SET
  persona_story_title = 'Naz needs a sounding board',
  persona_story_body = 'Naz runs a small firm and feels isolated when making important decisions. She wants a trusted person to think through trade‑offs before choosing a service.',
  vox_pop_quote = 'I need someone to bounce ideas off — not just a list of services.',
  vox_pop_attribution = 'SME owner, interview'
WHERE id = 5204;

COMMIT;

