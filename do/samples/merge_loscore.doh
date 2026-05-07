/*------------------------------------------------------------------------------
do/samples/merge_loscore.doh — leave-out prior-score merger (in-memory fragment)
================================================================================

PURPOSE
    Pure parent-context fragment.  Merges leave-out prior ELA scores onto the
    in-memory VA dataset and constructs the `loscore' variable per the
    cohort-specific lag rule:
      Spring 2015 cohort: 7th grade ELA (spring 2011)  -> L4_cst_ela_z_score
      Spring 2016 cohort: 7th grade ELA (spring 2012)  -> L4_cst_ela_z_score
      Spring 2017 cohort: 6th grade ELA (spring 2012)  -> L5_cst_ela_z_score
      Spring 2018 cohort: 6th grade ELA (spring 2013)  -> L5_cst_ela_z_score
    Also computes peer leave-out scores via rangestat (mean within school-year,
    excluding self).  Drops observations with missing loscore.

INCLUDED FROM
    `do/samples/create_score_samples.do' and `do/samples/create_out_samples.do'
    (the `_l' control combination block in each).
    Pure fragment — runs only inside parent's log scope; no own log.

INPUTS
    Parent-scope locals (from macros_va.doh):
      `k12_test_scores' -> $vaprojdir/data/restricted_access/clean/k12_test_scores

    LEGACY (read-only per ADR-0021 sandbox principle):
      `k12_test_scores'/k12_lag_test_scores_clean.dta — restricted-access lagged scores

OUTPUTS
    None on disk.  Modifies in-memory dataset:
      + loscore (numeric; cohort-specific leave-out prior ELA score)
      + peer_loscore (numeric; school-year peer mean excluding self)

ROLE IN ADR-0021 SANDBOX
    Pure fragment; no save / export / log.  Only reads LEGACY restricted-access
    K12 data via parent-scope `k12_test_scores' local.  Sandbox-trivially clean.

RELOCATION HISTORY (per plan v3 §3.3 step 2 batch 2c, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/merge_loscore.doh (predecessor)
    Destination: do/samples/merge_loscore.doh (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - No internal path globals or top-level $<global> references.
      - Body verbatim from predecessor.

ORIGINAL CHANGE LOG (preserved from predecessor; no header attribution in source)
    Predecessor file lacked an authorship header.  Per file role and adjacent
    create_score_samples.do (Christina-authored, 2022-08-15), attributed to
    Christina (Che) Sun.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 2 batch 2c;
                no path repointing needed (file uses parent-scope locals only).

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 2
    ADRs: 0009 (prior-score v1 canonical — leave-out scores are the v1 mechanism),
          0021 (sandbox; description convention)
------------------------------------------------------------------------------*/

********************************************************************************
/* do helper file to merge prior test scores and create leave out prior scores*/
********************************************************************************

/* Leave out scores:
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
drop if mi(L4_cst_ela_z_score) & mi(L5_cst_ela_z_score)

// create a leave out score variable
gen loscore =.
replace loscore = L4_cst_ela_z_score if year == 2015 | year == 2016
replace loscore = L5_cst_ela_z_score if year == 2017 | year == 2018
drop if mi(loscore)
label var loscore "leave out scores"

// peer leave out score variables
/* average of peer scores excluding self in each year and school */
rangestat (mean) loscore, interval(year, 0, 0) by(cdscode) excludeself
rename loscore_mean peer_loscore
label var peer_loscore "peer leave out scores"
