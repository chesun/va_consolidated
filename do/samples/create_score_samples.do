/*------------------------------------------------------------------------------
do/samples/create_score_samples.do — build all test-score VA estimation samples
================================================================================

PURPOSE
    Construct all 7 test-score VA estimation samples (b, l, a, s, la, ls, as,
    las — and the predecessor only loops over those 7, omitting `lasd' which
    is built downstream by VA estimation scripts) for both prior-score
    versions v1 and v2 (per ADR-0009).  The 7 samples differ by which
    additional controls are merged in:

      b   — base test-score sample (no extra controls)
      l   — leave-out prior-score sample (drops same-subject lagged score)
      a   — base + ACS census-tract demographic controls
      s   — base + sibling controls (older-sibling postsec outcomes)
      la  — leave-out + ACS
      ls  — leave-out + sibling
      as  — ACS + sibling
      las — leave-out + ACS + sibling (kitchen sink minus distance)

    For each (sample, version) cell, the script also computes
    n_g11_<subject>_<sample>_sp = per-school-year count of students
    contributing to that VA estimate (used as scatter-plot weighting).

INVOKED FROM
    `do/main.do' Phase 2 (run_samples block).

PRODUCTION STATUS
    GATED OFF in the predecessor `do_all.do:148-155' (`local do_create_samples = 0').
    Run-once-cached: outputs at $vaprojdir/data/va_samples_v[12]/score_*.dta
    persist on Scribe and are re-read by every subsequent VA-estimation step.
    In the consolidated repo, outputs land under CANONICAL `$datadir_clean/'
    (per ADR-0021 sandbox).  See `do/main.do' Phase 2 — invocation gated by
    the same `do_create_samples' local for behavior parity.

INPUTS
    LEGACY (read-only per ADR-0021 sandbox principle):
      $matt_files_dir/merge_k12_postsecondary.doh    — Matt's K12↔postsec merger
                                                       (called transitively via
                                                       create_va_sample.doh; ADR-0017)
      $vaprojdir/do_files/sbac/merge_loscore.doh     — leave-out-score merger
                                                       (not yet relocated)
      $vaprojdir/do_files/sbac/merge_sib.doh         — sibling-controls merger
                                                       (not yet relocated)
      $vaprojdir/do_files/sbac/merge_va_smp_acs.doh  — ACS-controls merger
                                                       (not yet relocated)
      $vaprojdir/do_files/sbac/merge_lag2_ela.doh    — lag-2 ELA-score merger
                                                       (not yet relocated)
      $vaprojdir/do_files/k12_postsec_distance/merge_k12_postsec_dist.doh
                                                     — k12-postsec distance merger
                                                       (not yet relocated; per Step 9)
      $vaprojdir/data/restricted_access/...          — K12 raw data (via locals
                                                       defined in macros_va.doh)
      do/va/helpers/macros_va.doh                    — VA-pipeline locals
      do/samples/create_va_sample.doh                — VA dataset constructor
      do/samples/create_va_g11_sample_v[12].doh      — 11th-grade subset + prior-score variant

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox principle):
      $datadir_clean/va_samples_v1/score_b.dta       — base test-score sample (v1)
      $datadir_clean/va_samples_v1/score_l.dta       — leave-out (v1)
      $datadir_clean/va_samples_v1/score_a.dta       — ACS (v1)
      $datadir_clean/va_samples_v1/score_s.dta       — sibling (v1)
      $datadir_clean/va_samples_v1/score_la.dta      — leave-out + ACS (v1)
      $datadir_clean/va_samples_v1/score_ls.dta      — leave-out + sibling (v1)
      $datadir_clean/va_samples_v1/score_as.dta      — ACS + sibling (v1)
      $datadir_clean/va_samples_v1/score_las.dta     — leave-out + ACS + sibling (v1)
      $datadir_clean/va_samples_v2/score_*.dta       — same 8 files for v2
      $logdir/create_score_samples.smcl + .log       — per-do-file log

ROLE IN ADR-0021 SANDBOX
    Reads LEGACY (Matt's merger transitively; sample-construction merge
    helpers not yet relocated; restricted-access K12 raw data) and writes
    ONLY to CANONICAL `$datadir_clean'.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 2 batch 2b, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/create_score_samples.do (predecessor)
    Destination: do/samples/create_score_samples.do (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - L10 usage comment: $vaprojdir/do_files/sbac/create_score_samples
                        -> $consolidated_dir/do/samples/create_score_samples.do
      - L37 `cd $vaprojdir' preserved (predecessor pattern; merge helpers
        rely on it); `cd "$consolidated_dir"' restored at end.
      - L42 log target: $vaprojdir/log_files/sbac/create_score_samples.smcl
                     -> CANONICAL `$logdir/create_score_samples.smcl'
      - L52 `include $vaprojdir/do_files/sbac/macros_va.doh'
         -> `include $consolidated_dir/do/va/helpers/macros_va.doh' (relocated 2026-04-30)
      - L63 `include $vaprojdir/do_files/sbac/create_va_sample.doh'
         -> `include $consolidated_dir/do/samples/create_va_sample.doh' (this batch)
      - L70 `include do_files/sbac/create_va_g11_sample_`version'.doh'
         -> `include do/samples/create_va_g11_sample_`version'.doh' (relocated 2026-04-30 batch 2a)
      - L73 `include $vaprojdir/do_files/k12_postsec_distance/merge_k12_postsec_dist.doh'
         — KEPT LEGACY (file not yet relocated per Step 9; requires $distance_dtadir,
            now defined in do/settings.do per this batch's prereq edit)
      - L76, L107, L149, L190, L209, L230 `include $vaprojdir/do_files/sbac/merge_*.doh'
         — KEPT LEGACY (sample-construction merge helpers not yet relocated)
      - L124, L166 `do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh ...'
         — KEPT LEGACY (called via `do' with args; not yet relocated)
      - L84, L104, L112, L126, L134, L146, L154, L168, L175, L187, L196, L206,
        L215, L227, L236, L242, L268: `$vaprojdir/data/va_samples_`version''
         -> CANONICAL `$datadir_clean/va_samples_`version''
      - L278-279 translate target: $vaprojdir/log_files/...
                                -> $logdir/...

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun August 15, 2022.
    2022-10-31: Changed naming convention for samples (b/l/a/s/la/ls/as/las).
    2022-12-29: Added loop for v1 and v2 versions of VA samples.
    2023-02-20: Added code to create variables for the number of students
                contributing to each VA estimate (n_g11_<outcome>_<sample>_sp).
    2023-04-11: Added code to merge on k12 postsecondary distances.
    2024-08-22: Added code to merge lag-2 ELA score (loscore) without
                dropping obs in base sample.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 2 batch 2b;
                paths repointed to CANONICAL per ADR-0021.

REFERENCES
    Plan:  quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 2
    ADRs:  0009 (prior-score v1 canonical), 0017 (Matt's files untouched),
           0021 (do/ relocation; sandbox; description convention)
    Predecessor caller: cde_va_project_fork/do_files/do_all.do:148-155 (gated 0)
------------------------------------------------------------------------------*/


********************************************************************************
/* create all test score VA samples used in subsequent analysis and store in memory*/
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun August 15, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/samples/create_score_samples.do
 */

/* CHANGE LOG:
10/31/2022: Changed naming convention for samples
b - base
l - loscore
a - acs
s - sibling
la - loscore and acs
ls - loscore and sibling
as - acs and sibling
las - loscore, acs and sibling

12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math

02/20/2022: added code to create variables for the number of students contributing
to each VA estimate for use in weighting in scatter plots
naming convention: n_g11_outcome_sample_sp

04/11/2023: added code to merge on k12 postsecondary distances

08/22/2024: add code to merge lag 2 ELA score (loscore) without dropping obs in base sample
 */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/va_samples_v1"
cap mkdir "$datadir_clean/va_samples_v2"
cap mkdir "$logdir"


 cd $vaprojdir

 log close _all


 log using "$logdir/create_score_samples.smcl", replace text

 di as text _n "{hline 80}"
 di as text "create_score_samples.do — RUN START: `c(current_date)' `c(current_time)'"
 di as text "{hline 80}"

 graph drop _all
 set more off
 set varabbrev off
 set graphics off
 set scheme s1color
 set seed 1984

// include the macros
 include $consolidated_dir/do/va/helpers/macros_va.doh

timer on 1


foreach version in v1 v2 {
  *******************************************
  * Base test score sample
  *******************************************
  local create_b = 1
  if `create_b' == 1 {
    include $consolidated_dir/do/samples/create_va_sample.doh

    compress
    tempfile va_dataset
    save `va_dataset'

    // 11th grade sample
    include $consolidated_dir/do/samples/create_va_g11_sample_`version'.doh

    // merge on k12 postsecondary distances
    include $vaprojdir/do_files/k12_postsec_distance/merge_k12_postsec_dist.doh

    // merge on lag 2 ELA scores without dropping obs, to predict lag 1 ELA score
    include $consolidated_dir/do/samples/merge_lag2_ela.doh



    * Save temporary dataset
    compress
    label data "Base Test Score VA Sample"

    save "$datadir_clean/va_samples_`version'/score_b.dta", replace
  }


  *******************************************
  * Test score sample with leave out prior scores
  *******************************************

  /* Leave out scores:
  1.    Spring 2015 cohort use 7th grade ELA (spring 2011)

  2.    Spring 2016 cohort use 7th grade ELA (spring 2012)

  3.    Spring 2017 cohort use 6th grade ELA (spring 2012)

  4.    Spring 2018 cohort use 6th grade ELA (spring 2013)
  */
  //loscore stands for leave out score
  local create_l = 1
  if `create_l' == 1 {
    use "$datadir_clean/va_samples_`version'/score_b.dta", clear

    // do helper file to merge leave out scores
    include $consolidated_dir/do/samples/merge_loscore.doh

    label data "Test Score VA Sample with Leave Out Scores"

    compress
    save "$datadir_clean/va_samples_`version'/score_l.dta", replace

  }


  *******************************************
  * Test score sample with ACS controls
  *******************************************
  local create_a = 1
  if `create_a' == 1 {

    // call do helper file to merge onto ACS controls. Be sure to specify correct arguments. 5 args in total
    do $consolidated_dir/do/samples/merge_va_smp_acs.doh ///
      test_score ///
      "$datadir_clean/va_samples_`version'/score_b.dta" ///
      score_b.dta ///
      create_sample ///
      none

      label data "Test Score VA Sample with ACS Controls"
      compress

      save "$datadir_clean/va_samples_`version'/score_a.dta", replace


  }



  *******************************************
  * Test score sample with sibling controls
  *******************************************
  local create_s = 1
  if `create_s' == 1 {
    use "$datadir_clean/va_samples_`version'/score_b.dta", clear

    //subroutine that merges on sibling college going controls
    include $consolidated_dir/do/samples/merge_sib.doh

    label data "Test Score VA Sample with Sibling Controls"

    compress
    save "$datadir_clean/va_samples_`version'/score_s.dta", replace
  }



  *******************************************
  * Test score sample with leave out score and ACS controls
  *******************************************
  local create_la = 1
  if `create_la' == 1 {

    // call do helper file to merge onto ACS controls. Be sure to specify correct arguments. 5 args in total
    do $consolidated_dir/do/samples/merge_va_smp_acs.doh ///
      test_score ///
      "$datadir_clean/va_samples_`version'/score_l.dta" ///
      score_l.dta ///
      create_sample ///
      none

    label data "Test Score VA Sample with Leave Out Scores and ACS Controls"

    save "$datadir_clean/va_samples_`version'/score_la.dta", replace

  }




  *******************************************
  * Test score sample with leave out score and sibling controls
  *******************************************
  local create_ls = 1
  if `create_ls' == 1 {
    use "$datadir_clean/va_samples_`version'/score_l.dta", clear

    //subroutine that merges on sibling college going controls
    include $consolidated_dir/do/samples/merge_sib.doh

    label data "Test Score VA Sample with Leave Out Scores and Sibling Controls"


    compress
    save "$datadir_clean/va_samples_`version'/score_ls.dta", replace
  }



  *******************************************
  * Test score sample with ACS and sibling controls
  *******************************************
  local create_as = 1
  if `create_as' == 1 {
    use "$datadir_clean/va_samples_`version'/score_a.dta", clear

    //subroutine that merges on sibling college going controls
    include $consolidated_dir/do/samples/merge_sib.doh

    label data "Test Score VA Sample with ACS and Sibling Controls"


    compress
    save "$datadir_clean/va_samples_`version'/score_as.dta", replace


  }



  *******************************************
  * Test score sample with leave out score, ACS, and sibling controls
  *******************************************
  local create_las = 1
  if `create_las'==1 {
    use "$datadir_clean/va_samples_`version'/score_la.dta", clear

    //subroutine that merges on sibling college going controls
    include $consolidated_dir/do/samples/merge_sib.doh

    label data "Test Score VA Sample with Leave Out Scores, ACS, and Siblig Controls"


    compress
    save "$datadir_clean/va_samples_`version'/score_las.dta", replace
  }

  // create vars for number of students contributing to VA estimates
  foreach sample in b l a s la ls las {
      foreach subject in ela math {
      use "$datadir_clean/va_samples_`version'/score_`sample'.dta", clear
      egen n_g11_`subject'_`sample'_sp = count(state_student_id) ///
        if touse_g11_`subject'==1 ///
        , by(cdscode year)
    }
  }

}

timer off 1
timer list

cap log close

cap translate "$logdir/create_score_samples.smcl" ///
  "$logdir/create_score_samples.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
