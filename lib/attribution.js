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

  return contributionWeight * (confidence ?? 1) * decay * krDelta;
}

module.exports = { scoreInsightForKR };

