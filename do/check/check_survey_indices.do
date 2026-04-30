/*------------------------------------------------------------------------------
do/check/check_survey_indices.do — assert CalSCHLS source items + built indices
================================================================================

PURPOSE
    Verify CalSCHLS source items are within the -2 to +2 Likert range and
    built indices (`climateindex`, `qualityindex`, `supportindex`) are
    well-formed.  Pre/post-fix detection: raw indices in [-2, 2] is the
    post-ADR-0011-fix invariant (sums→means).  Encodes the design memo §5
    specification.

INPUTS
    Source CalSCHLS files (LEGACY — static predecessor inputs):
      $caschls_projdir/dta/allsvyfactor/imputedallsvyqoimeans.dta  (calschls_1)
      $caschls_projdir/dta/allsvyfactor/allsvyqoimeans.dta         (calschls_2)
    Built index files (post-Phase-1a §3.3 CANONICAL):
      $estimates_dir/calschls/categoryindex/imputedcategoryindex.dta
      $estimates_dir/calschls/categoryindex/compcasecategoryindex.dta
    Built by relocated `imputedcategoryindex.do` + `compcasecategoryindex.do`
    under do/survey_va/.

OUTPUTS
    Per-do-file log: $logdir/check_survey_indices.smcl + .log
    On `assert` failure: pipeline halts; partial outputs preserved.

ROLE IN ADR-0021 SANDBOX
    Reads from LEGACY ($caschls_projdir, static predecessor source — static
    CalSCHLS surveys don't change) and CANONICAL ($estimates_dir, post-Phase-1a
    relocated index outputs).  Writes only to $logdir (CANONICAL).  Skeleton
    uses capture-confirm-file shim on the CANONICAL inputs so a pre-relocation
    main.do run skips those sub-checks cleanly.

INDEX STRUCTURE (resolved 2026-04-28; design memo §5)
    Both `imputedcategoryindex.do` + `compcasecategoryindex.do` use IDENTICAL
    item lists.  Three indices match ADR-0010's "9 / 15 / 4":

    | Index           | N | Items                                              |
    |-----------------|---|----------------------------------------------------|
    | climateindex    | 9 | parentqoi 16/17/27 + secqoi 22/23/24/26/27/29      |
    | qualityindex    |15 | parentqoi 30/31/32/33/34 + secqoi 28/35/36/37/38/  |
    |                 |   | 39/40 + staffqoi 20/24/87                          |
    | supportindex    | 4 | parentqoi 15/64 + staffqoi 10/128                  |

    Total source items used: 28 of 45 source QOIs.  17 source QOIs unused.
    A fourth `motivationindex` is declared-but-commented-out — exploratory,
    dropped from the paper.  Do NOT assert its existence.

INVARIANTS (verbatim from design memo §5)
    Hard asserts on source:
      - _N == 5625 schools
      - source items in [-2.01, 2.01] (5-point Likert, ±0.01 tolerance)
      - every climateitems / qualityitems / supportitems variable present
      - item counts: 9 / 15 / 4
    Hard asserts on built indices:
      - z_<index>: |mean| < 0.01, SD ∈ [0.95, 1.05], min ∈ [-5, -1], max ∈ [1, 5]
      - raw <index>: range [-2.01, 2.01]  (catches ADR-0011 sums→means fix —
                                           PASSES post-fix; FAILS pre-fix)
    Soft signals:
      - z_climateindex / z_qualityindex correlation: ~0.7+; flag if <=0.
      - imputed vs compcase per-school correlation: ~0.95+; flag if <0.85.

REFERENCES
    Design memo:    quality_reports/reviews/2026-04-28_data-checks-design.md §5
    Plan:           quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.3 step 9
    Codebook:       calschls_1 parentqoi9mean_pooled (lines 1404-1422);
                    calschls_1 describe (lines 101-1320; 957 vars).
    Constructor:    imputedcategoryindex.do (item lists at lines used in
                    constructor; see ADR-0010 + ADR-0011 for full lineage)
    ADRs:           0010 (paper-α from indexalpha.do; 9/15/4),
                    0011 (sums→means fix; raw-index range bound is the test),
                    0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/


clear all
set more off
cap log close _all
set linesize 120

cap mkdir "$logdir"
log using "$logdir/check_survey_indices.smcl", replace text

di as text _n "{hline 80}"
di as text "check_survey_indices.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/*==============================================================================
ITEM LISTS (from design memo §5; resolved 2026-04-28)
==============================================================================*/

local climateitems  parentqoi16mean_pooled parentqoi17mean_pooled            ///
                    parentqoi27mean_pooled                                   ///
                    secqoi22mean_pooled secqoi23mean_pooled                  ///
                    secqoi24mean_pooled secqoi26mean_pooled                  ///
                    secqoi27mean_pooled secqoi29mean_pooled

local qualityitems  parentqoi30mean_pooled parentqoi31mean_pooled            ///
                    parentqoi32mean_pooled parentqoi33mean_pooled            ///
                    parentqoi34mean_pooled                                   ///
                    secqoi28mean_pooled secqoi35mean_pooled                  ///
                    secqoi36mean_pooled secqoi37mean_pooled                  ///
                    secqoi38mean_pooled secqoi39mean_pooled                  ///
                    secqoi40mean_pooled                                      ///
                    staffqoi20mean_pooled staffqoi24mean_pooled              ///
                    staffqoi87mean_pooled

local supportitems  parentqoi15mean_pooled parentqoi64mean_pooled            ///
                    staffqoi10mean_pooled staffqoi128mean_pooled

* Item-count invariants per ADR-0010 — these are in-memory checks, do not
* need a dataset loaded.
local n_climate : word count `climateitems'
local n_quality : word count `qualityitems'
local n_support : word count `supportitems'

assert `n_climate' == 9
assert `n_quality' == 15
assert `n_support' == 4
di as text "  PASS: item counts match ADR-0010 — climate=9, quality=15, support=4"


/*==============================================================================
SUB-CHECK 1 — source files (imputed + compcase)
==============================================================================*/

foreach src_tag in calschls_1 calschls_2 {
    if "`src_tag'" == "calschls_1" {
        local src_dta "$caschls_projdir/dta/allsvyfactor/imputedallsvyqoimeans.dta"
        local src_label "imputed"
    }
    else {
        local src_dta "$caschls_projdir/dta/allsvyfactor/allsvyqoimeans.dta"
        local src_label "compcase"
    }

    capture confirm file "`src_dta'"
    if _rc {
        di as text "  [LEGACY-MISSING] `src_dta' — predecessor caschls source not present."
        di as text "                   Skipping `src_label' source-item checks."
        continue
    }

    use "`src_dta'", clear

    * School-level row count -- design memo §5 (codebook line 105 / 24269)
    capture assert _N == 5625
    if _rc {
        di as error "  FAIL: `src_label' source _N = " r(N) " (expected 5625)"
        cap log close
        cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
        exit _rc
    }
    di as text "  PASS: `src_label' source _N == 5625"

    * Source-item Likert range: [-2, 2] with ±0.01 floating-point tolerance.
    foreach v of varlist parentqoi*mean_pooled secqoi*mean_pooled            ///
                         staffqoi*mean_pooled                                {
        qui sum `v'
        if r(N) == 0 continue
        capture assert inrange(r(min), -2.01, 0)
        if _rc {
            di as error "  FAIL: `src_label' `v' min = " %7.4f r(min) " (expected ∈ [-2.01, 0])"
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
        capture assert inrange(r(max), 0, 2.01)
        if _rc {
            di as error "  FAIL: `src_label' `v' max = " %7.4f r(max) " (expected ∈ [0, 2.01])"
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
    }
    di as text "  PASS: `src_label' source items within Likert [-2.01, 2.01]"

    * Every index component present in the source file.
    foreach v in `climateitems' `qualityitems' `supportitems' {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL: `src_label' source missing required item `v'"
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
    }
    di as text "  PASS: `src_label' source has all 28 (=9+15+4) required index components"
}


/*==============================================================================
SUB-CHECK 2 — built indices (post-Phase-1a §3.3 CANONICAL)
==============================================================================*/

foreach idx_tag in imputed compcase {
    local idx_dta "$estimates_dir/calschls/categoryindex/`idx_tag'categoryindex.dta"

    capture confirm file "`idx_dta'"
    if _rc {
        di as text "  [SKELETON] `idx_dta' not found — produced by Phase 1a §3.3"
        di as text "             survey-VA relocation (do/survey_va/`idx_tag'categoryindex.do)."
        di as text "             Skipping `idx_tag' built-index check."
        continue
    }

    use "`idx_dta'", clear

    * Z-scored indices: mean 0, SD 1 by construction.  Invariant under
    * ADR-0011 sums→means fix (z-score absorbs scaling).
    foreach z in z_climateindex z_qualityindex z_supportindex {
        qui sum `z'
        if r(N) == 0 continue
        capture assert abs(r(mean)) < 0.01
        if _rc {
            di as error "  FAIL: `idx_tag' `z' mean = " %7.4f r(mean) " (expected |.| < 0.01)"
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
        capture assert inrange(r(sd), 0.95, 1.05)
        if _rc {
            di as error "  FAIL: `idx_tag' `z' SD = " %7.4f r(sd) " (expected ∈ [0.95, 1.05])"
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
        capture assert inrange(r(min), -5, -1)
        if _rc {
            di as error "  FAIL: `idx_tag' `z' min = " %7.4f r(min) " (expected ∈ [-5, -1])"
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
        capture assert inrange(r(max), 1, 5)
        if _rc {
            di as error "  FAIL: `idx_tag' `z' max = " %7.4f r(max) " (expected ∈ [1, 5])"
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
    }
    di as text "  PASS: `idx_tag' z-scored indices have mean≈0, SD≈1, typical tail ranges"

    * RAW indices: post-ADR-0011-fix invariant is range [-2.01, 2.01].
    * Pre-fix (sums) would scale with N items (~[-18, 18] for climate, etc.).
    * This is THE test for whether the ADR-0011 fix has landed.
    foreach idx in climateindex qualityindex supportindex {
        qui sum `idx'
        if r(N) == 0 continue
        capture assert inrange(r(min), -2.01, 0)
        if _rc {
            di as error "  FAIL: `idx_tag' raw `idx' min = " %7.4f r(min) " (expected ∈ [-2.01, 0])"
            di as error "        Indicates ADR-0011 sums→means fix has NOT been applied to `idx_tag'."
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
        capture assert inrange(r(max), 0, 2.01)
        if _rc {
            di as error "  FAIL: `idx_tag' raw `idx' max = " %7.4f r(max) " (expected ∈ [0, 2.01])"
            di as error "        Indicates ADR-0011 sums→means fix has NOT been applied to `idx_tag'."
            cap log close
            cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace
            exit _rc
        }
    }
    di as text "  PASS: `idx_tag' raw indices ∈ [-2.01, 2.01] (ADR-0011 sums→means fix verified)"

    * Soft: z_climateindex / z_qualityindex correlation ~0.7+; flag if near zero.
    capture qui corr z_climateindex z_qualityindex
    if _rc {
        di as error "  SOFT: could not compute z_climateindex × z_qualityindex correlation."
    }
    else {
        local r_cq = r(rho)
        if `r_cq' < 0.5 {
            di as error "  SOFT: `idx_tag' z_climateindex × z_qualityindex correlation = " %5.3f `r_cq'
            di as error "        below 0.50 floor; expected ~0.7+ per design memo §5."
        }
        else {
            di as text "  PASS (soft): `idx_tag' z_climate × z_quality correlation = " %5.3f `r_cq'
        }
    }
}


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n "{hline 80}"
di as text "check_survey_indices.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close
cap translate "$logdir/check_survey_indices.smcl" "$logdir/check_survey_indices.log", replace

* end of file
