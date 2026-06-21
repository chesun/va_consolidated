/*------------------------------------------------------------------------------
do/check/check_va_estimates.do — assert VA estimates structurally present

================================================================================

PURPOSE
    Verify VA estimation (`va_all_schl_char.dta` / `k12_main`) produced its
    reference output columns and that they are non-empty.  Encodes the design
    memo §4 specification (structural part only).

    NOTE (ADR-0033, 2026-06-21): the former distributional checks in this file —
    centered-mean tolerance (|mean|<0.05), SD envelope ([0.05,0.30]), per-spec
    CFR cell-floor (>=5, soft), and the cross-spec / peer-control correlation
    soft signals — were a-priori magnitude/correlation HEURISTICS with no hard
    basis in the data and have been REMOVED.  VA numerical correctness is
    verified by the M4 golden-master comparison (do/check/m4_golden_master.do),
    which diffs every estimate against the predecessor pipeline.

INPUTS
    `va_all_schl_char.dta` (`k12_main` per design memo §1 + §4).
        Path post-Phase-1a §3.3: $estimates_dir/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta
        Built by relocated `va_het.do` under do/va/heterogeneity/.

OUTPUTS
    Per-do-file log: $logdir/check/check_va_estimates.smcl + .log
    On a HARD `assert` failure (reference column missing or all-missing):
    pipeline halts, partial outputs preserved.

ROLE IN ADR-0021 SANDBOX
    Reads from CANONICAL ($estimates_dir/...).  Writes only to $logdir
    (CANONICAL).  Skeleton uses capture-confirm-file shim so a pre-relocation
    main.do run skips this check cleanly.

VARIABLE INVENTORY (codebook lines 47369-47442)
    VA columns follow `va_<subj>_<sample>_sp_<ctrl>_ct[_p]`:
      - <subj>   ∈ {ela, math}
      - <sample> ∈ {b, l, a, s, la, ls, as, las}        (8 samples; chunk-3)
      - <ctrl>   ∈ {b, l, a, s}                         (kitchen-sink controls)
      - _ct      = "controls" suffix
      - _p       = "with peer controls" suffix
    Companion `n_g11_<subj>_<sample>_sp` = student-year count per spec.

INVARIANTS (verbatim from design memo §4; structural part only — see ADR-0033)
    Hard asserts:
      - Reference VA columns va_ela_b_sp_b_ct and va_math_b_sp_b_ct exist and
        are non-empty (the VA estimation produced output).
    (Distributional invariants removed per ADR-0033 — see PURPOSE note.)

REFERENCES
    Design memo:    quality_reports/reviews/2026-04-28_data-checks-design.md §4
    Audit:          quality_reports/reviews/2026-06-21_heuristic-check-audit.md
    Plan:           quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.3 step 9
    Codebook:       k12_main describe (lines 47325-48951); VA columns (lines 47373-47442)
    ADRs:           0004 (sibling-VA canonical pipeline), 0009 (v1 prior-score),
                    0021 (description convention; sandbox role above),
                    0033 (remove heuristic checks without hard basis)
------------------------------------------------------------------------------*/


clear all
set more off
cap log close check_va_estimates
set linesize 120

cap mkdir "$logdir"

cap mkdir "$logdir/check"
log using "$logdir/check/check_va_estimates.smcl", replace text name(check_va_estimates)

di as text _n "{hline 80}"
di as text "check_va_estimates.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/*==============================================================================
INPUT
==============================================================================*/

* TODO Phase 1a §3.3: confirm post-relocation path (VA-estimation outputs).
local in_dta "$estimates_dir/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta"

capture confirm file "`in_dta'"
if _rc {
    di as text "  [SKELETON] `in_dta' not found — produced by Phase 1a §3.3"
    di as text "             VA-estimation relocation (do/va/heterogeneity/va_het.do)."
    di as text "             Skipping check_va_estimates.do."
    cap log close check_va_estimates
    cap translate "$logdir/check/check_va_estimates.smcl" "$logdir/check/check_va_estimates.log", replace
    exit 0
}

use "`in_dta'", clear


/*==============================================================================
HARD ASSERT (structural — VA estimation produced its reference outputs)
==============================================================================*/

* The only non-heuristic VA check: the reference VA columns exist and are
* non-empty.  Distributional checks (centered-mean tolerance, SD envelope,
* per-spec CFR cell floor, cross-spec / peer-control correlations) were REMOVED
* 2026-06-21 per ADR-0033 — a-priori magnitude/correlation heuristics with no
* hard basis in the data.  VA numerical correctness is covered by the M4
* golden-master comparison (do/check/m4_golden_master.do).
foreach v in va_ela_b_sp_b_ct va_math_b_sp_b_ct {
    capture confirm variable `v'
    local rc = _rc
    if _rc {
        di as error "  FAIL: reference VA column `v' missing — VA estimation did not produce it"
        cap log close check_va_estimates
        cap translate "$logdir/check/check_va_estimates.smcl" "$logdir/check/check_va_estimates.log", replace
        exit `rc'
    }
    qui count if !missing(`v')
    if r(N) == 0 {
        di as error "  FAIL: reference VA column `v' is all missing (N = 0)"
        cap log close check_va_estimates
        cap translate "$logdir/check/check_va_estimates.smcl" "$logdir/check/check_va_estimates.log", replace
        exit 9
    }
}
di as text "  PASS: reference VA columns (va_ela_b_sp_b_ct, va_math_b_sp_b_ct) exist and are non-empty"


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n "{hline 80}"
di as text "check_va_estimates.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close check_va_estimates
cap translate "$logdir/check/check_va_estimates.smcl" "$logdir/check/check_va_estimates.log", replace

* end of file
