# 0032: staffqoi98 extended -3 scale — relax imputation clamp floor + widen check bound

- **Date:** 2026-06-20
- **Status:** Decided
- **Scope:** Methodology
- **Data quality:** Full context
- **Amends:** ADR-0027 (clamp floor for staffqoi98 only)
- **Extends:** ADR-0028 (check-acceptance adjustment pattern)

## Context

The 2026-06-13 full acceptance run (master log `log/main_13-Jun-2026_17-23-53.smcl`)
completed all phases with no Stata errors; Phase 7 had 5/6 checks PASS. The sixth check,
`check_survey_indices.do`, **hard-halted** (the ADR-0027/`7ee1548` rc-clobber fix working
as designed) on:

```
FAIL: imputed staffqoi98mean_pooled min = -3.0000 (expected ∈ [-2.01, 0])
```

This is **not a pipeline regression.** `staffqoi98` is deliberately coded on an extended
scale where `-3 = "severe problem"`:

- `do/data_prep/qoiclean/staff/staffqoiclean1415.do:250,258,276` — `replace qoi98temp = -3 if qoi98 == 4`
- identical in `staffqoiclean1617_1516.do:266,274,292` and `staffqoiclean1819_1718.do:138,146,165`

So a school-level pooled mean of `-3.0` is legitimate. `qoi98` is the **only** item with
`-3` coding (`grep 'qoi[0-9]+temp = -3'` across all `do/data_prep/qoiclean/` returns
`qoi98` only), so no other source item trips the bound.

Two things assumed the standard 5-point Likert range `[-2, 2]` and were therefore wrong
for `staffqoi98`:

1. **The check.** `check_survey_indices.do:167` asserted every source item's
   `min ∈ [-2.01, 0]`. The observed `staffqoi98` min of `-3` is legitimate, so the
   assertion produced a false FAIL.
2. **The ADR-0027 clamp.** `imputation.do` (climatevars loop) censored imputed
   predictions to `[-2, 2]`. For `staffqoi98`, clamping the floor at `-2` artificially
   discards the legitimate "severe problem" category for imputed observations. (The
   observed `-3` came from non-imputed rows — the clamp only fires on `imputed`i'==1` —
   which is why the source file already carried `-3` regardless of the clamp.)

Blast radius is small: `staffqoi98` appears in `imputation.do`'s `climatevars`
*imputation universe* (line 73) but is **not** a component of any built index
(`climateindex`/`qualityindex`/`supportindex` use the 28 curated items listed in
`check_survey_indices.do:41-44`, which exclude `staffqoi98`). So relaxing its clamp affects
only the `staffqoi98mean_pooled` column of `imputedallsvyqoimeans.dta`; the built indices,
SUB-CHECK 2 (raw-index range), and the survey-VA regressions (which use the indices) are
unaffected.

## Decision (Christina, 2026-06-20)

1. **Relax the clamp floor for `staffqoi98` to `-3`** (ceiling stays `+2`). Implemented in
   `do/survey_va/imputation.do` climatevars loop: `local lo = cond("`i'" ==
   "staffqoi98mean_pooled", -3, -2)`; `replace `i' = `lo' if imputed`i'==1 & `i' < `lo'`.
   The other three category loops keep the uniform `-2` floor (they contain no `-3`-coded
   items).
2. **Widen the check's min bound for `staffqoi98` to `[-3.01, 0]`** (all other items keep
   `[-2.01, 0]`). Implemented in `do/check/check_survey_indices.do` SUB-CHECK 1:
   `local lo_bound = -2.01`; `if "`v'" == "staffqoi98mean_pooled" local lo_bound = -3.01`.
   Applies to both the `imputed` and `compcase` sources (special-cased by variable name,
   not source).

Rationale: a check must accept the data's legitimate range, and the clamp should not
censor a legitimately-coded category. This is the ADR-0028 class of fix (adjust the
acceptance criterion to the real, intended data), not a data change.

## Consequences

- The next clean Phase 5–7 re-run should pass `check_survey_indices` SUB-CHECK 1 for
  `staffqoi98` and proceed to SUB-CHECK 2 (built-index ranges) — which was never reached
  on the 2026-06-13 run because of the halt, and which `staffqoi98` does not feed.
- No change to any paper table/figure is expected (`staffqoi98` is not an index component).
- The ADR-0027 clamp remains in force unchanged for every other imputed item.

## Sources

- Session log: `quality_reports/session_logs/2026-06-20_doc-repo-links-and-june13-run-triage.md` (Part 2 + Diagnosis).
- Verification ledger: `.claude/state/verification-ledger.md` row `do/check/check_survey_indices.do | diagnosis:staffqoi98-min-neg3-false-fail`.
- Run log: `log/main_13-Jun-2026_17-23-53.smcl`; `log/check/check_survey_indices.log` (FAIL line).
- Code: `do/data_prep/qoiclean/staff/staffqoiclean*.do` (the -3 coding); `do/survey_va/imputation.do` climatevars loop; `do/check/check_survey_indices.do` SUB-CHECK 1.
- Prior: ADR-0027 (clamp + re-point), ADR-0028 (thin-cell soft-check precedent).
