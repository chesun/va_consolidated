/*------------------------------------------------------------------------------
do/samples/merge_lag2_ela.doh — lag-2 ELA-score merger (in-memory fragment)
================================================================================

PURPOSE
    Pure parent-context fragment.  Sister of `merge_loscore.doh' that merges
    the same lag-2 ELA prior-scores but DOES NOT drop missing observations,
    so the base sample size is preserved.  Used to predict lag-1 ELA score
    in downstream regressions where loscore is needed for the prior-score
    control but the sample restriction it would impose is unwanted.

INCLUDED FROM
    `do/samples/create_score_samples.do:212' (Base test-score sample) and
    `do/samples/create_out_samples.do:204' (Base outcome sample).  Both are
    in the `_b' (base) control block — runs once per (sample, version) cell.
    Pure fragment — runs only inside parent's log scope; no own log.

INPUTS
    Parent-scope locals (from macros_va.doh):
      `k12_test_scores' -> $vaprojdir/data/restricted_access/clean/k12_test_scores

    LEGACY (read-only per ADR-0021 sandbox principle):
      `k12_test_scores'/k12_lag_test_scores_clean.dta — restricted-access lagged scores

OUTPUTS
    None on disk.  Modifies in-memory dataset:
      + lag2ela (numeric; cohort-specific lag-2 ELA prior score, no row drops)
      - L4_cst_ela_z_score, L5_cst_ela_z_score (dropped after lag2ela built)

ROLE IN ADR-0021 SANDBOX
    Pure fragment; no save / export / log.  Same LEGACY restricted-access K12
    read as merge_loscore.doh.  Sandbox-trivially clean.

RELOCATION HISTORY (per plan v3 §3.3 step 2 batch 2c, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/merge_lag2_ela.doh (predecessor)
    Destination: do/samples/merge_lag2_ela.doh (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - No internal path globals or top-level $<global> references.
      - Body verbatim from predecessor.

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    Predecessor file added 2024-08-22 per the change log in
    create_score_samples.do (parent caller).
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 2 batch 2c.

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 2
    Sister: do/samples/merge_loscore.doh (drops-missing variant)
    ADRs: 0021 (sandbox; description convention)
------------------------------------------------------------------------------*/

********************************************************************************
/* do helper file to merge lag 2 ELA scores to VA samples to predict lag 1 ELA
This is the same as merge_loscore.doh but does not drop missing obs to preserve
sample */
********************************************************************************

/* lag 2 ELA scores is same as leave out scores:
1.    Spring 2015 cohort use 7th grade ELA (spring 2011)

2.    Spring 2016 cohort use 7th grade ELA (spring 2012)

3.    Spring 2017 cohort use 6th grade ELA (spring 2012)

4.    Spring 2018 cohort use 6th grade ELA (spring 2013)
*/

/* only including 4 grade prior ELA scores but no math scores because
not everyone took math tests */
merge 1:1 merge_id_k12_test_scores using ///
  `k12_test_scores'/k12_lag_test_scores_clean.dta, nogen keep(1 3) ///
  keepusing(L4_cst_ela_z_score L5_cst_ela_z_score) update

// create a leave out score variable
gen lag2ela =.
replace lag2ela = L4_cst_ela_z_score if year == 2015 | year == 2016
replace lag2ela = L5_cst_ela_z_score if year == 2017 | year == 2018
label var lag2ela "leave out scores"

drop L4_cst_ela_z_score L5_cst_ela_z_score
