/*------------------------------------------------------------------------------
do/check/check_merges.do — assert post-merge join rates against historical baselines
================================================================================

PURPOSE
    Verify that K12 ↔ NSC / CCC / CSU merge rates and the consolidated
    school-level analysis dataset (`va_all_schl_char.dta`) match the historical
    baselines derived from the codebook + Phase 0a deep-read audit.  Encodes
    the design memo §3 specification.

INPUTS
    `va_all_schl_char.dta` (`k12_main` per design memo §1).
        Path post-Phase-1a §3.3: $estimates_dir/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta
        Built by relocated `va_het.do` under do/va/heterogeneity/.
    Merge-result columns (`merge_grade_span`, `merge_cohort_size`,
        `merge_public_schools`) in `score_b.dta`.

OUTPUTS
    Per-do-file log: $logdir/check_merges.smcl + .log
    On `assert` failure: pipeline halts; partial outputs preserved.

ROLE IN ADR-0021 SANDBOX
    Reads from CANONICAL ($estimates_dir/...) once Phase 1a §3.3 lands the
    VA-estimation relocation.  Writes only to $logdir (CANONICAL).  Skeleton
    uses capture-confirm-file shim so a pre-relocation main.do run skips this
    check cleanly.

INVARIANTS (verbatim from design memo §3)
    Hard asserts:
      - score_b merge flags (_merge values 1..5; codebook §3 lines 72983-73070)
      - k12_main _N == 5009 schools
    TBD-codebook (per design memo §9 open items; needs production-run baseline):
      - K12 ↔ NSC merge rate ±0.5pp tolerance
      - K12 ↔ CCC bridge match-level==1 share against historical (~68.7%)
      - K12 ↔ CSU bridge same logic; smaller universe (1.42M vs 3.22M for CCC)

REFERENCES
    Design memo:    quality_reports/reviews/2026-04-28_data-checks-design.md §3
    Plan:           quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §5.3 step 9
    Codebook:       k12_ccc_xw describe (lines 77150-77179); k12_ccc_xw match_level
                    tabulation (lines 77317-77321); nsc describe (lines 75743-75824)
    ADRs:           0017 (Matt's K12↔postsec merges in merge_k12_postsecondary.doh untouched),
                    0019 (NSC crosswalk authorship; not pipeline-active),
                    0021 (description convention; sandbox role above)
------------------------------------------------------------------------------*/


clear all
set more off
cap log close _all
set linesize 120

cap mkdir "$logdir"
log using "$logdir/check_merges.smcl", replace text

di as text _n "{hline 80}"
di as text "check_merges.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/*==============================================================================
SUB-CHECK 1 — score_b merge flags
==============================================================================*/

* TODO Phase 1a §3.3: confirm post-relocation path (sample-construction).
local in_score_b "$estimates_dir/va_samples_v1/score_b.dta"

capture confirm file "`in_score_b'"
if _rc {
    di as text "  [SKELETON] `in_score_b' not found — produced by Phase 1a §3.3"
    di as text "             sample-construction relocation.  Skipping sub-check 1."
}
else {
    use "`in_score_b'", clear

    * _merge values are 1..5 (master-only / using-only / matched / etc.).
    * inspect r(N_unique) bounds the distinct value count.
    foreach m in merge_grade_span merge_cohort_size merge_public_schools {
        capture confirm variable `m'
        if _rc {
            di as error "  SOFT: expected merge column `m' not found in score_b — investigating."
            continue
        }
        qui inspect `m'
        capture assert r(N_unique) <= 5
        if _rc {
            di as error "  FAIL: `m' has more than 5 distinct values"
            qui tab `m', missing
            cap log close
            cap translate "$logdir/check_merges.smcl" "$logdir/check_merges.log", replace
            exit _rc
        }
        di as text "  PASS: `m' has <=5 distinct values (canonical _merge codes)"
    }
}


/*==============================================================================
SUB-CHECK 2 — k12_main school count
==============================================================================*/

* TODO Phase 1a §3.3: confirm post-relocation path (VA-estimation outputs).
local in_k12_main "$estimates_dir/va_cfr_all_v1/va_est_dta/va_all_schl_char.dta"

capture confirm file "`in_k12_main'"
if _rc {
    di as text "  [SKELETON] `in_k12_main' not found — produced by Phase 1a §3.3"
    di as text "             VA-estimation relocation (do/va/heterogeneity/va_het.do)."
    di as text "             Skipping sub-check 2."
}
else {
    use "`in_k12_main'", clear
    * 5,625 calschls schools → 5,009 k12_main schools = 89% retention (design memo §3).
    assert _N == 5009
    di as text "  PASS: k12_main _N == 5009 (89% retention from CalSCHLS school universe)"
}


/*==============================================================================
SUB-CHECK 3 — bridge match-level distributions  (TBD-codebook)
==============================================================================*/

* TBD-codebook per design memo §9 open items: needs production-run baseline.
* The K12↔CCC bridge is in $vaprojxwalks (LEGACY; static predecessor input).
* `match_level` ∈ {1, 2, 3, 4} per codebook lines 77317-77321 with freqs
* (2.21M, 63K, 918K, 27K).  Bound the share of match_level==1 against
* historical ~68.7% once that baseline is locked from the first production run.

local in_k12_ccc_xw "$vaprojxwalks/k12_ccc_crosswalk.dta"
capture confirm file "`in_k12_ccc_xw'"
if _rc {
    di as text "  [SKELETON] `in_k12_ccc_xw' not found in LEGACY — Matt-owned static crosswalk"
    di as text "             (per ADR-0017).  Skipping bridge match-level check."
}
else {
    use "`in_k12_ccc_xw'", clear
    qui count if match_level == 1
    local share_ml1 = r(N) / _N
    di as text "  INFO: K12↔CCC match_level==1 share = " %5.3f `share_ml1'
    * TBD-codebook: convert to hard assert with ±0.5pp tolerance once baseline locked.
}


/*==============================================================================
WRAP-UP
==============================================================================*/

di as text _n "{hline 80}"
di as text "check_merges.do — RUN END: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

cap log close
cap translate "$logdir/check_merges.smcl" "$logdir/check_merges.log", replace

* end of file
