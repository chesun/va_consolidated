# 0027: clamp OLS-imputed survey items to Likert range; re-point check_survey_indices to CANONICAL

- **Date:** 2026-06-09
- **Status:** Decided
- **Scope:** Methodology
- **Data quality:** Full context

## Context

The e968d13 acceptance run's Phase-7 check `check_survey_indices.do` reported a FAIL:
imputed `secqoi27mean_pooled` max = 2.6133, above the 5-point Likert ceiling [-2, 2]
(±0.01 tolerance).

Two root causes (both confirmed in code, not run — air-gapped):

1. **Unbounded imputation.** `do/survey_va/imputation.do` imputes missing CalSCHLS QOI
   items by OLS regression: `reg `i' ...` → `predict hat_`i'` → `replace `i' = hat_`i' if
   imputed`i'==1`. OLS prediction is unbounded, so an imputed climate item (secqoi27 is a
   `climateindex` component) can exceed the Likert range.

2. **Stale check source.** The FAIL is in SUB-CHECK 1, which read the LEGACY predecessor
   artifact `$caschls_projdir/dta/allsvyfactor/imputedallsvyqoimeans.dta` — a static file
   the consolidated pipeline never regenerates. The consolidated imputation writes the
   CANONICAL `$datadir_clean/survey_va/imputedallsvyqoimeans.dta` (`imputation.do:201`),
   which the downstream index builder consumes (`imputedcategoryindex.do:85`). The check
   predated the imputation relocation and never followed it to the CANONICAL output.

Surfaced via `quality_reports/reviews/2026-06-09_imputation-clamp_coder_review.md`
(coder-critic flagged the read/write file mismatch).

## Decision

- **Clamp/censor OLS-imputed predictions to the Likert range [-2, 2]** in
  `do/survey_va/imputation.do`, in all four regression-imputation loops (climate, quality,
  support, motivation). Out-of-range predictions are censored to the nearest bound:
  `replace `i' = -2 if imputed`i'==1 & `i' < -2` and
  `replace `i' = 2 if imputed`i'==1 & `i' > 2 & !missing(`i')` (the `!missing` guard is
  required because Stata orders missing as +∞). Only imputed cells are affected; observed
  values are untouched.
- **Re-point `check_survey_indices.do` SUB-CHECK 1** sources from the LEGACY
  `$caschls_projdir/dta/allsvyfactor/` files to the consolidated CANONICAL outputs
  (`$datadir_clean/survey_va/imputedallsvyqoimeans.dta` and `.../allsvyqoimeans.dta`), so
  the check validates what the pipeline actually produces and observes the clamped values.

Alternatives considered and rejected: relax the check to admit out-of-range imputed values
(would hide the unboundedness); switch to a bounded imputation method (PMM / truncated
regression) — a larger methodological change deferred; clamping is the minimal fix that
keeps the existing OLS imputation and bounds its output.

## Consequences

**Commits us to:**
- Imputed survey items bounded to [-2, 2]; a point mass at ±2 for predictions that would
  have overshot (benign for the standardized indices built downstream).
- `check_survey_indices.do` validating the consolidated CANONICAL survey-VA outputs, not the
  predecessor artifacts.

**Caveat (flagged for the next run):** SUB-CHECK 1's `assert _N == 5625` now reads the
CANONICAL files. If the consolidated `allsvyqoimeans` / `imputedallsvyqoimeans` row counts
differ from the predecessor's 5625, that assert will surface a separate (legitimate)
count mismatch — desired behavior (it validates the real pipeline).

**Note:** clamping changes survey-index inputs, so it is paper-affecting. coder-critic
reviewed the clamp (82/100 PASS, the −15 being exactly the read/write mismatch this ADR's
re-point resolves) and reviews the re-point separately.

## Sources

- Code: `do/survey_va/imputation.do:131-195` (clamp), `do/check/check_survey_indices.do:133,137` (re-point);
  data-flow trace `imputation.do:67,201` + `imputedcategoryindex.do:85`; roots `do/settings.do:102,136`.
- Reviews: `quality_reports/reviews/2026-06-08_server-run-e968d13_log-review.md`,
  `quality_reports/reviews/2026-06-09_imputation-clamp_coder_review.md`.
- Related: ADR-0010 (index item lists 9/15/4), ADR-0011 (sums→means), ADR-0021 (CANONICAL sandbox), ADR-0028 (sibling FAIL-1 decision, same triage).
