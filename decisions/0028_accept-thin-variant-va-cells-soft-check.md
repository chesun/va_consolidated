# 0028: accept thin per-spec VA cells in restricted-variant samples; soften the count check

- **Date:** 2026-06-09
- **Status:** Superseded in part by #0033 — the soft per-spec count check is removed (heuristic, no hard basis). The thin-cell *acceptance* rationale below still stands.
- **Scope:** Specification
- **Data quality:** Full context

## Context

The e968d13 acceptance run's Phase-7 check `check_va_estimates.do` reported a FAIL:
`n_g11_ela_l_sp` min student-year count = 4, below the design-memo §4 CFR-style minimum
cell size of 5.

Why a restricted variant falls below the base floor (confirmed in code — air-gapped):

1. The base sample tags eligibility with a >=7 floor: `touse_va.do:295-298` builds
   `n_g11_ela = count(...) by(cdscode year)` and sets `touse_g11_ela = 0 if n_g11_ela < 7`.
   The floor binds the **base** cell count and fixes the `touse` flag once.
2. The restricted variants are subsamples built by merging extra controls onto the base.
   The `l` (leave-out) variant runs `merge_loscore.doh`, which **drops** students lacking a
   leave-out prior score (`:76` `drop if mi(L4...) & mi(L5...)`, `:82` `drop if mi(loscore)`).
3. The checked count `n_g11_ela_l_sp` is computed **after** those drops, downstream in the
   VA estimation: `collapse (sum) n_g11_ela_l_sp = touse_g11_ela, by(cdscode year)`
   (`va_score_all.do:247`). It tallies the base-flagged students who survived the merge.

So the base flag is carried forward unchanged and the variant cell shrinks; a base cell of
7 with 3 students missing a leave-out score becomes 4 in the `l` sample. The >=7 floor is
never re-applied per variant. Being a subsample is exactly why the per-cell count drops.

(Vestigial: the `create_score_samples.do:376-384` egen loop that appears to build these
counts has no `save` and omits the `as` variant; it is dead. The live counts come from the
collapse above. Cleanup deferred.)

## Decision

- **Accept the condition.** Restricted-variant per-spec student-year counts may legitimately
  fall below 5. Rationale: the CFR-style drift-limit shrinkage estimator (`vam.ado`) shrinks
  thin cells toward the mean, and `n_g11_<subj>_<sample>_sp` is used only as a scatter-plot
  weight (`va_scatter.do`), not as the estimation sample or a paper-reported quantity.
- **Downgrade the per-spec count check to SOFT (non-halting).** In `check_va_estimates.do`,
  the `n_g11_*_sp >= 5` block now reports cells below the floor (`di as error "  SOFT: ..."`)
  but does not `exit` / halt the pipeline. The two genuinely-hard asserts in the same file
  (main-spec VA centered `|mean| < 0.05`; reference-spec SD ∈ [0.05, 0.30]) stay HARD.

Alternatives considered and rejected: re-apply a >=5/>=7 floor per variant before estimation
(would change the estimation sample and move published results — not warranted for a weight
variable); lower the hard floor to an arbitrary value (masks the signal). Soft-report keeps
visibility into thin cells without blocking an accepted condition.

## Consequences

**Commits us to:**
- `check_va_estimates.do` no longer halts the pipeline on thin restricted-variant cells; it
  logs `SOFT:` lines so the condition stays visible in the per-file log.
- The design-memo §4 "min N >= 5 (hard)" invariant is amended: hard for centered-mean and SD,
  soft for per-spec counts.

**Rules out (for now):** treating a sub-5 variant cell as a pipeline-halting error.

**Note:** this is a check-semantics change to a `do/check/` file; coder-critic reviews it.
The underlying VA estimates and outputs are unchanged — only the check's halt behavior.

## Sources

- Code: `do/samples/touse_va.do:295-298` (base floor), `do/samples/merge_loscore.doh:76,82`
  (variant drop), `do/va/va_score_all.do:247` (post-drop count), `do/check/check_va_estimates.do:123-140` (soft block),
  vestigial `do/samples/create_score_samples.do:376-384`.
- Reviews: `quality_reports/reviews/2026-06-08_server-run-e968d13_log-review.md`.
- Related: ADR-0009 (prior-score v1), ADR-0021 (CANONICAL sandbox), ADR-0027 (survey FAIL-2 decision, same triage).
