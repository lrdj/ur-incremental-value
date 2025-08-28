BEGIN;

-- Enrich Defra insights
UPDATE insight SET
  description = 'Users regularly conflate CHED-A (animal by-products) with CHED-D (certain food/feed of non-animal origin). Internal jargon and similar acronyms increase cognitive load at the very first decision point.',
  what_we_observed = 'Traders and brokers hesitate at the first screen; error-rate spikes on entry-type; repeated back-and-forth between help and form; call-centre logs show classification queries rising on Mondays.',
  why_it_matters = 'Picking the wrong entry type routes cases for manual review and adds days to processing. Every misclassification ties up scarce vet time and creates friction for compliant traders.',
  evidence = 'Moderated usability sessions (n=12); analytics funnel showing 18% bounce at entry-type; 47 call transcripts coded for misclassification; field shadowing at border posts.'
WHERE id = 5001;

UPDATE insight SET
  description = 'Broker organisations operate with varied role boundaries. Junior staff often submit with incomplete documentation while seniors assume checks are elsewhere. Current guidance is generic and not embedded in the workflow.',
  what_we_observed = 'Skipped document checks before submission; reliance on memory for rare document types; printed checklists go out of date and are ignored; repeated rework due to missing vet attestations.',
  why_it_matters = 'Rework drives longer cycle time and frustrates both sides. Role-specific guidance, embedded where the work happens, reduces first-time errors and increases approvals.',
  evidence = 'Broker interviews (n=9 across 4 firms); diary study; defect analysis of rejected CHEDs; pilot of inline guidance prototype.'
WHERE id = 5002;

UPDATE insight SET
  description = 'Specialist veterinary terminology and Latin species names are unfamiliar to many submitters. The upload step contains dense language that becomes a barrier.',
  what_we_observed = 'Participants pause and Google species terms; uncertainty about equivalence between common and Latin names; abandonment at the point of selecting document type.',
  why_it_matters = 'Unclear terminology increases abandonment and errors, reducing first-time approval and delaying shipments. Plain English with tooltips improves comprehension.',
  evidence = 'Survey (n=142) on terminology comprehension; lab tests with content variants; heatmaps showing hover on unclear terms.'
WHERE id = 5003;

-- Enrich DBT insights
UPDATE insight SET
  description = 'Small businesses describe needs in terms of outcomes (e.g. “find buyers”) rather than internal service names. The current IA mirrors organisational silos and mismatches mental models.',
  what_we_observed = 'Free-text enquiries talk about goals not services; users skim brand names and look for verbs; confusion between similar-sounding schemes with different eligibility.',
  why_it_matters = 'Mismatched language leads to wrong routing and increased drop-off. Mapping intents to outcomes helps users self-select and reach the right support first time.',
  evidence = 'Diary studies over 4 weeks; search log analysis; tree testing of revised IA with 23 SMEs.'
WHERE id = 5101;

UPDATE insight SET
  description = 'Trust increases when users can request a named advisor callback. Purely self-serve flows feel risky for complex, high-stakes decisions.',
  what_we_observed = 'Higher completion when a human option is visible; users postpone decisions without a “talk to a person” route; increased NPS for those offered callbacks.',
  why_it_matters = 'A hybrid support model reduces abandonment and improves time-to-match by resolving uncertainty quickly.',
  evidence = 'A/B test (control n=2,184, variant n=2,176) with +25% conversion to suitable service; qualitative follow-ups; contact-centre notes.'
WHERE id = 5102;

UPDATE insight SET
  description = 'Framing journeys around a simple lifecycle (start, grow, export, etc.) reduces cognitive load compared to a flat list of services.',
  what_we_observed = 'Users navigate by stage; fewer pogo-sticks between pages; clearer understanding of “what to do next”.',
  why_it_matters = 'Lifecycle framing helps users build a path, improving correct routing and reducing support queries.',
  evidence = 'Tree tests with 31 participants; first-click success up 18pp; analytics on navigation depth.'
WHERE id = 5103;

-- Enrich HMRC insights
UPDATE insight SET
  description = 'Language that hints at “fraud flags” produces anxiety. People fear long-term account impact and stigma, even when the process is routine.',
  what_we_observed = 'Early abandonment of appeals when strong warning language used; calls asking whether an employer will see the flag; misinterpretation of “risk” wording as accusation.',
  why_it_matters = 'Anxiety drives non-compliance and delays. Calmer, explanatory language improves cooperation and resolution speed.',
  evidence = 'Content tests with 18 claimants; contact-centre transcript coding; readability and tone audit.'
WHERE id = 5201;

UPDATE insight SET
  description = 'When users are told the factors behind a risk decision, perceived fairness increases and cooperation improves.',
  what_we_observed = 'People accept additional checks when given a reason; fewer complaints; better quality of supporting evidence submitted.',
  why_it_matters = 'Explainability builds trust and improves early detection without harming legitimate users.',
  evidence = 'Prototype testing with “reasons” patterns; ops feedback; reduction in repeat contacts after deployment.'
WHERE id = 5202;

UPDATE insight SET
  description = 'Security cues are read differently on mobile vs desktop. Patterns that feel safe on one device can feel suspicious on another.',
  what_we_observed = 'SMS links seen as risky on desktop; small-screen modals dismissed as pop-ups; device posture changes tolerance for friction.',
  why_it_matters = 'Device-aware prompts and cues reduce false positives and increase completion for legitimate users.',
  evidence = 'Lab tests across devices; heuristic review; remote usability with 12 participants.'
WHERE id = 5203;

COMMIT;

