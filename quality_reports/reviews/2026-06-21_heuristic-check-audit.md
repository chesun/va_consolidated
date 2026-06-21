# Heuristic-check audit — remove checks without a hard basis

**Date:** 2026-06-21
**Trigger:** Christina — "get rid of the z-score tail check… remove all heuristic checks without hard basis." The z-tail `min ∈ [-5,-1]` halted the 2026-06-20 rerun despite being an a-priori "typical tail" heuristic (design memo line 224 comment).
**Principle:** keep checks whose bound is fixed by the **data coding, an exact design-memo/codebook count, a valid-code set, or a mathematical/estimator construction**. Remove checks whose bound is an a-priori guess about the data distribution ("typical", "expected ~", "envelope").

## Classification

### REMOVE — heuristic, no hard basis

| File | Lines | Check | Why heuristic |
|---|---|---|---|
| check_survey_indices.do | 248–255 | `z_<index>` min ∈ [-5,-1] | "typical z-score lower tail" (memo l.224) — depends on distribution |
| check_survey_indices.do | 256–263 | `z_<index>` max ∈ [1,5] | "typical z-score upper tail" |
| check_survey_indices.do | ~289–304 | SOFT z_climate×z_quality corr ≥0.50 (exp ~0.7+) | a-priori correlation guess |
| check_va_estimates.do | 116–127 | `va_ela_b_sp_b_ct` SD ∈ [0.05,0.30] | "paper-reported envelope ~0.10-0.15 σ" — magnitude guess |
| check_va_estimates.do | ~150–165 | SOFT cross-spec corr ≥0.70 (exp ~0.85+) | a-priori ("per chunk-3 audit") |
| check_va_estimates.do | ~166–180 | SOFT peer-control corr ≥0.90 (exp ~0.97) | a-priori |
| check_samples.do | ~155–162 | SOFT age ∈ [5478,6940] days (~15-19 yr) | plausible-age guess |
| check_samples.do | ~165–171 | SOFT cohort_size ∈ [11,1325] | "expected" range guess |

### KEEP — hard basis

- **Exact counts** (design memo / codebook): `_N==1784445`, per-cohort `r(N)==402416/406084/450201/525744`, `n_schools==1389`, `_N==5625`, item counts `9/15/4`, paper `_N==1784445`/`==5009`, k12 `_N==5009`. Exact, no tolerance.
- **Definitional:** `grade==11`, `inrange(year,2015,2018)` (ADR-0029).
- **Coding/logic:** race dummies orthogonal `inlist(eth_sum,0,1)`; binary `inlist(v,0,1,.)`; merge `r(N_unique)<=5` (canonical Stata `_merge` codes 1–5).
- **Coding-scheme range:** source items within `[-2.01, 2.01]`, staffqoi98 `[-3.01, 2.01]` (the items ARE coded on that scale; ADR-0032).
- **Mathematical / by construction:** `z_<index>` mean `|.|<0.01` and SD `[0.95,1.05]` (z-scoring forces these); raw `<index>` within `[-2.01, 2.01]` (mean of items each in [-2,2] → bounded; also the ADR-0011 sums→means regression test).
- **Item presence**, **check_logs** ran-but-no-log invariant.

### MODIFY — hard core, heuristic sub-assumption (centering)

The source-item (SUB-CHECK 1) and raw-index (SUB-CHECK 2) range asserts are written as
`min ∈ [-2.01, 0]` + `max ∈ [0, 2.01]`. The `±2.01` (and staffqoi98 `−3.01`) bound is the
**hard** coding/math limit; the `min ≤ 0` / `max ≥ 0` half is a **heuristic centering
assumption** (it requires every item/index to straddle 0). SUB-CHECK 1 passed empirically,
but the raw-index version (never reached before) would be the **next halt** after the z-tail
is removed if any index is one-signed.

Proposal: loosen both to the pure coding/math bound — assert each value (or min and max)
lies within `[-2.01, 2.01]` (staffqoi98 `[-3.01, 2.01]`), dropping the `≤0`/`≥0` centering.
Keeps the Likert-range + ADR-0011 guard; removes the distributional guess.

### BORDERLINE — need Christina's call

1. **VA centered-mean** `|mean| < 0.05` (check_va_estimates.do:105). VA is centered ≈0 *by BLUP construction* (structural basis), but 0.05 is a loose tolerance. Recommend **KEEP** (structural).
2. **CFR per-spec count `≥ 5`** SOFT (check_va_estimates.do:141). Set by **ADR-0028** (Christina, 2026-06-09) as an informational flag; CFR cell-floor has a methodological basis but restricted variants legitimately fall below. Recommend **KEEP** (recent explicit decision; already soft).

## Plan once confirmed

1. Apply removals + the centering loosen.
2. ADR-0033 (records the "no-heuristic-check" principle; amends the design-memo §5 invariants; supersedes the z-tail/correlation parts of ADR-0028's check posture as needed).
3. Update each check file's header INVARIANTS block to match.
4. coder-critic gate (hard 80) → commit → push → Scribe rerun.

---

## Resolution (2026-06-21)

Christina's calls on the three borderline items: **remove** VA centered-mean; **remove**
CFR per-spec count soft (ADR-0028); **loosen** the source-item + raw-index centering to the
hard `[-2.01,2.01]` bound. Implemented + ADR-0033 written. coder-critic **94/100 PASS**
(`2026-06-21_heuristic-check-removal_coder_review.md`) — verified no hard-basis check lost,
no heuristic survived, M4 golden master strictly stronger than the removed VA envelopes.
Also fixed coder-critic M1: the pre-existing rc-clobber in check_samples.do's two wrapped
fail-branches (`exit _rc` after cap → exit 0) → `local rc=_rc` + `exit \`rc'`.
