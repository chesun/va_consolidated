/*------------------------------------------------------------------------------
do/check/check_va_estimates.do — assert VA estimates structurally well-formed
================================================================================

PURPOSE
    Verify VA estimates from `va_all_schl_char.dta` (`k12_main`) are
    structurally well-formed (centered, expected magnitudes, sufficient cell
    sizes).  Encodes the design memo §4 specification.

INPUTS
    `va_all_schl_char.dta` (`k12_main` per design memo §1 + §4).
        Path post-Phase-1a §3.3: $estimates_dir/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta
        Built by relocated `va_het.do` under do/va/heterogeneity/.

OUTPUTS
    Per-do-file log: $logdir/check_va_estimates.smcl + .log
    On `assert` failure: pipeline halts; partial outputs preserved.

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

INVARIANTS (verbatim from design memo §4)
    Hard asserts:
      - Main-spec VA centered: |mean| < 0.05 for all va_<subj>_*_ct columns
        (school-level VA ≈ 0 by construction after BLUP shrinkage).
      - Paper-reported SD: VA SD ∈ [0.05, 0.30] for va_ela_b_sp_b_ct
        (paper Tables 2-3 report ~0.10-0.15 σ; wide tolerance halts only on
        absurd values).
      - Per-spec student-year counts: min N >= 5 (CFR-style estimator
        minimum cell size).
    Soft signals (display as error, non-halting):
      - Cross-spec correlation va_ela_b_sp_b_ct vs va_ela_l_sp_l_ct: ~0.85+
        per chunk-3 audit; flag if <0.7.
      - _p (peer controls) vs no-_p correlation: ~0.97; flag if <0.9.

REFERENCES
    Design memo:    quality_reports/reviews/2026-04-28_data-checks-design.md §4
    Plan:           quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.3 step 9
    Codebook:       k12_main describe (lines 47325-48951); VA columns (lines 47373-47442)
    Audit:          quality_reports/audits/2026-04-26_deep-read-audit-FINAL.md (chunk-3 cross-spec correlations)
    ADRs:           0004 (sibling-VA canonical pipeline), 0009 (v1 prior-score),
                    0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/


clear all
set more off
cap log close _all
set linesize 120

cap mkdir "$logdir"
log using "$logdir/check_va_estimates.smcl", replace text

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
    cap log close
    cap translate "$logdir/check_va_estimates.smcl" "$logdir/check_va_estimates.log", replace
    exit 0
}

use "`in_dta'", clear


/*==============================================================================
HARD ASSERTS (from design memo §4)
==============================================================================*/

* Main-spec VA centered.  School-level VA ≈ 0 by construction after BLUP
* shrinkage; tight tolerance because paper reports school VA centered.
foreach v of varlist va_ela_*_ct va_math_*_ct va_*_ct_p {
    qui sum `v'
    if r(N) == 0 continue
    capture assert abs(r(mean)) < 0.05
    if _rc {
        di as error "  FAIL: `v' mean = " %7.4f r(mean) " — outside |.| < 0.05 tolerance"
        cap log close
        cap translate "$logdir/check_va_estimates.smcl" "$logdir/check_va_estimates.log", replace
        exit _rc
    }
}
di as text "  PASS: all va_<subj>_*_ct and va_*_ct_p columns have |mean| < 0.05"

* Paper-reported SD bound on the b-sample b-control reference spec.
qui sum va_ela_b_sp_b_ct
capture assert inrange(r(sd), 0.05, 0.30)
if _rc {
    di as error "  FAIL: va_ela_b_sp_b_ct SD = " %7.4f r(sd) " — outside [0.05, 0.30]"
    di as error "        paper Tables 2-3 report ~0.10-0.15 σ"
    cap log close
    cap translate "$logdir/check_va_estimates.smcl" "$logdir/check_va_estimates.log", replace
    exit _rc
}
di as text "  PASS: va_ela_b_sp_b_ct SD ∈ [0.05, 0.30] (paper-reported envelope)"

* Per-spec student-year counts non-zero — CFR estimator minimum cell size.
foreach v of varlist n_g11_ela_*_sp n_g11_math_*_sp {
    qui sum `v'
    if r(N) == 0 continue
    capture assert r(min) >= 5
    if _rc {
        di as error "  FAIL: `v' has min student-year count = " %5.0f r(min) " — below CFR minimum 5"
        cap log close
        cap translate "$logdir/check_va_estimates.smcl" "$logdir/check_va_estimates.log", replace
        exit _rc
    }
}
di as text "  PASS: all n_g11_<subj>_*_sp counts >= 5 (CFR minimum cell size)"


/*==============================================================================
SOFT SIGNALS (display as error; non-halting)
==============================================================================*/

* Cross-spec correlation reference (b-sample b-control vs l-sample l-control).
* Per chunk-3 audit, expected ~0.85+; soft-flag if <0.7.
capture qui corr va_ela_b_sp_b_ct va_ela_l_sp_l_ct
if _rc {
    di as error "  SOFT: could not compute cross-spec correlation — variables may not exist."
}
else {
    local r_cross = r(rho)
    if `r_cross' < 0.7 {
        di as error "  SOFT: va_ela_b_sp_b_ct vs va_ela_l_sp_l_ct correlation = " %5.3f `r_cross'
        di as error "        below 0.70 floor; expected ~0.85+ per chunk-3 audit."
    }
    else {
        di as text "  PASS (soft): cross-spec ela correlation = " %5.3f `r_cross'
    }
}

* _p (peer controls) vs no-_p correlation: expected ~0.97; soft-flag if <0.9.
capture qui corr va_ela_b_sp_b_ct va_ela_b_sp_b_ct_p
if _rc {
    di as error "  SOFT: could not compute peer-control correlation — variables may not exist."
}
else {
    local r_peer = r(rho)
    if `r_peer' < 0.9 {
        di as error "  SOFT: va_ela_b_sp_b_ct vs va_ela_b_sp_b_ct_p correlation = " %5.3f `r_peer'
        di as error "        below 0.90 floor; expected ~0.97 per design memo §4."
    }
    else {
        di as text "  PASS (soft): peer-control correlation = " %5.3f `r_peer'
    }
}


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n "{hline 80}"
di as text "check_va_estimates.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close
cap translate "$logdir/check_va_estimates.smcl" "$logdir/check_va_estimates.log", replace

* end of file
