# 0033: remove Phase-7 data-checks that have no hard basis in the data

- **Date:** 2026-06-21
- **Status:** Decided
- **Scope:** Methodology
- **Data quality:** Full context
- **Supersedes (in part):** ADR-0028 (the per-spec CFR cell-floor soft signal it created is removed)
- **Relates to:** ADR-0027, ADR-0032 (prior staffqoi-range check adjustments)

## Context

The 2026-06-20 Phase 5+7 re-run cleared the staffqoi98 fix (ADR-0032) and then
hard-halted on `check_survey_indices.do`: `FAIL: imputed z_climateindex min = -7.0888
(expected ∈ [-5, -1])`. That bound is an a-priori "typical z-score lower tail" heuristic
(design memo §5 line 224 comment) — the actual tail depends on the data distribution, and
−7.09 is a legitimate heavy tail (the z-mean≈0 / SD≈1 asserts passed, so standardization
is correct). It had simply never run before (every prior run halted earlier).

Christina's call: **a check should fire only when its bound has a hard basis — the data
coding scheme, an exact design-memo/codebook count, a valid-code set, or a
mathematical/estimator construction. Remove every check whose bound is an a-priori guess
about the data distribution ("typical", "expected ~", magnitude/correlation envelopes).**

Full audit: `quality_reports/reviews/2026-06-21_heuristic-check-audit.md`.

## Decision

### Removed (heuristic, no hard basis)

- `check_survey_indices.do`: z_<index> tail asserts `min ∈ [-5,-1]` and `max ∈ [1,5]`; the soft z_climate × z_quality correlation signal.
- `check_va_estimates.do`: VA centered-mean `|mean| < 0.05`; VA SD envelope `[0.05, 0.30]`; the per-spec CFR cell-floor `≥ 5` soft signal (was ADR-0028); the cross-spec and peer-control correlation soft signals. (All of this file's former checks were heuristic.)
- `check_samples.do`: the soft age-range `[5478,6940]` days and cohort_size-range `[11,1325]` signals.

### Loosened to the hard bound (dropped the heuristic centering half)

- `check_survey_indices.do` SUB-CHECK 1 (source items) and SUB-CHECK 2 (raw indices): the asserts were `min ∈ [-2.01, 0]` AND `max ∈ [0, 2.01]`. The `±2.01` (staffqoi98 `−3.01`) is the hard Likert-coding / mathematical bound and is kept; the `min ≤ 0` / `max ≥ 0` "straddles 0" centering half was a heuristic distributional assumption and is dropped. New form: `min ≥ floor` and `max ≤ 2.01`. The raw-index version still serves as the ADR-0011 sums→means regression test.

### Added (hard basis — replaces the emptied check_va_estimates)

- `check_va_estimates.do`: a single structural assert — the reference VA columns `va_ela_b_sp_b_ct` and `va_math_b_sp_b_ct` exist and are non-empty. This is existence/non-emptiness (binary structural fact), not a distributional guess. VA numerical correctness is verified by the M4 golden-master comparison (`do/check/m4_golden_master.do`), which diffs every estimate against the predecessor.

### Kept (hard basis — unchanged)

Exact counts (`_N == 1784445`, per-cohort Ns, `1389`, `5625`, `5009`, item counts 9/15/4);
`grade == 11`; `year ∈ [2015,2018]`; race-dummy orthogonality + binary coding; merge
`_merge`-code validity (`≤ 5`); Likert coding floor/ceiling `[-2.01,2.01]` (staffqoi98
`[-3.01,2.01]`); z-score `|mean| < 0.01` and `SD ∈ [0.95,1.05]` (forced by z-scoring); raw
index `[-2.01,2.01]`; item presence; the `check_logs` ran-but-no-log invariant.

## Consequences

- The pipeline's data-checks now halt only on hard-basis violations (real regressions),
  not on distributional surprises. This removes a class of false-halts (z-tail, the next
  one that would have hit the raw-index centering, and future ones).
- `check_va_estimates.do` shrinks from five heuristic checks to one structural check;
  detailed VA correctness moves entirely to the golden master, which is the right tool for
  it (exact diff vs predecessor).
- ADR-0028's soft cell-floor signal is gone; the thin-cell *acceptance* rationale in
  ADR-0028 still stands (restricted variants legitimately fall below CFR floors), it is
  simply no longer reported by a check.

## Sources

- Audit: `quality_reports/reviews/2026-06-21_heuristic-check-audit.md`.
- Run log: `log/main_20-Jun-2026_14-18-12.smcl`; `log/check/check_survey_indices.log` (z_climateindex min FAIL).
- Design memo: `quality_reports/reviews/2026-04-28_data-checks-design.md` §2/§4/§5 (the bounds being removed/kept).
- Prior: ADR-0011 (sums→means), ADR-0027/0032 (staffqoi range), ADR-0028 (thin-cell soft check, superseded in part).
