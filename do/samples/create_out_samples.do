/*------------------------------------------------------------------------------
do/samples/create_out_samples.do — build all postsecondary-outcome VA samples
================================================================================

PURPOSE
    Construct all 7 postsecondary-outcome VA estimation samples (b, l, a, s,
    la, ls, as, las — and the predecessor only loops over those 7) for both
    prior-score versions v1 and v2 (per ADR-0009).  Outcome side mirror of
    `create_score_samples.do' — same 7 control combinations, same v1/v2 split,
    different label string ("Outcome" vs "Test Score") and outcome variable
    handling (enr / enr_2year / enr_4year vs sbac_ela_z / sbac_math_z).

    Postsecondary outcomes are merged in via Matt's
    `merge_k12_postsecondary.doh' (untouched per ADR-0017) inside the base
    sample block; the 3 outcome variables are then renamed from `_ontime'
    suffixes to base names for downstream consistency.

INVOKED FROM
    `do/main.do' Phase 2 (run_samples block).

PRODUCTION STATUS
    GATED OFF in the predecessor `do_all.do:148-155' (`local do_create_samples = 0').
    Run-once-cached: outputs at $vaprojdir/data/va_samples_v[12]/out_*.dta
    persist on Scribe and are re-read by every subsequent VA-estimation step.
    In the consolidated repo, outputs land under CANONICAL `$datadir_clean/'
    (per ADR-0021 sandbox).  Invocation gated by the same `do_create_samples'
    local for behavior parity.

INPUTS
    LEGACY (read-only per ADR-0021 sandbox principle):
      $matt_files_dir/merge_k12_postsecondary.doh    — Matt's K12↔postsec merger (ADR-0017)
      $vaprojdir/do_files/sbac/merge_loscore.doh     — leave-out-score merger
      $vaprojdir/do_files/sbac/merge_sib.doh         — sibling-controls merger
      $vaprojdir/do_files/sbac/merge_va_smp_acs.doh  — ACS-controls merger
      $vaprojdir/do_files/sbac/merge_lag2_ela.doh    — lag-2 ELA-score merger
      $vaprojdir/do_files/k12_postsec_distance/merge_k12_postsec_dist.doh
                                                     — k12-postsec distance merger
      $vaprojdir/data/restricted_access/...          — K12 raw data (via macros_va.doh locals)
      do/va/helpers/macros_va.doh                    — VA-pipeline locals
      do/samples/create_va_sample.doh                — VA dataset constructor
      do/samples/create_va_g11_out_sample_v[12].doh  — 11th-grade subset + prior-score variant

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox principle):
      $datadir_clean/va_samples_v1/out_b.dta         — base outcome sample (v1)
      $datadir_clean/va_samples_v1/out_l.dta         — leave-out (v1)
      $datadir_clean/va_samples_v1/out_a.dta         — ACS (v1)
      $datadir_clean/va_samples_v1/out_s.dta         — sibling (v1)
      $datadir_clean/va_samples_v1/out_la.dta        — leave-out + ACS (v1)
      $datadir_clean/va_samples_v1/out_ls.dta        — leave-out + sibling (v1)
      $datadir_clean/va_samples_v1/out_as.dta        — ACS + sibling (v1)
      $datadir_clean/va_samples_v1/out_las.dta       — leave-out + ACS + sibling (v1)
      $datadir_clean/va_samples_v2/out_*.dta         — same 8 files for v2
      $logdir/samples/create_out_samples.smcl + .log         — per-do-file log

ROLE IN ADR-0021 SANDBOX
    Reads LEGACY (Matt's merger; sample-construction merge helpers; restricted-access
    K12) and writes ONLY to CANONICAL `$datadir_clean'.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 2 batch 2b, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/create_out_samples.do (predecessor)
    Destination: do/samples/create_out_samples.do (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - L10 usage comment: $vaprojdir/do_files/sbac/create_out_samples
                        -> $consolidated_dir/do/samples/create_out_samples.do
      - L39 `cd $vaprojdir' preserved (predecessor pattern); restored at end.
      - L44 log target: $vaprojdir/log_files/sbac/create_out_samples.smcl
                     -> CANONICAL `$logdir/samples/create_out_samples.smcl'
      - L54 `include do_files/sbac/macros_va.doh'
         -> `include $consolidated_dir/do/va/helpers/macros_va.doh' (relocated 2026-04-30)
      - L66 `include do_files/sbac/create_va_sample.doh'
         -> `include do/samples/create_va_sample.doh' (this batch)
      - L69 `do do_files/merge_k12_postsecondary.doh enr_only'
         -> `do "$matt_files_dir/merge_k12_postsecondary.doh" enr_only'
      - L80 `include do_files/sbac/create_va_g11_out_sample_`version'.doh'
         -> `include do/samples/create_va_g11_out_sample_`version'.doh' (relocated 2026-04-30 batch 2a)
      - L83, L86 `include $vaprojdir/do_files/...' — KEPT LEGACY (not yet relocated)
      - L120, L155 `do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh ...' — KEPT LEGACY
      - L141, L177, L195, L215 `include $vaprojdir/do_files/sbac/merge_sib.doh' — KEPT LEGACY
      - L105 `include $vaprojdir/do_files/sbac/merge_loscore.doh' — KEPT LEGACY
      - L93, L102, L110, L122, L130, L138, L146, L157, L165, L174, L183, L192,
        L201, L212, L221, L227: `$vaprojdir/data/va_samples_`version''
         -> CANONICAL `$datadir_clean/va_samples_`version''
      - L242-243 translate target: $vaprojdir/log_files/...
                                -> $logdir/...

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun August 15, 2022.
    2022-10-31: Changed naming convention for samples (b/l/a/s/la/ls/as/las).
    2022-12-29: Added loop for v1 and v2 versions of VA samples.
    2023-02-20: Added code to create variables for the number of students
                contributing to each VA estimate (n_g11_<outcome>_<sample>_sp).
    2023-04-30: Added code to merge on k12 postsecondary distances.
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
/* create all outcomes VA samples used in subsequent analysis and store in memory*/
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun August 15, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/samples/create_out_samples.do
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


02/20/2023: added code to create variables for number of students contributing to
VA estimates
naming onvention: n_g11_outcome_sample_sp

04/30/2023: added code to merge on k12 postsecondary distances

08/22/2024: add code to merge lag 2 ELA score (loscore) without dropping obs in base sample

 */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/va_samples_v1"
cap mkdir "$datadir_clean/va_samples_v2"
cap mkdir "$logdir"


cap mkdir "$logdir/samples"
 cd $vaprojdir

 cap log close create_out_samples


 log using "$logdir/samples/create_out_samples.smcl", replace text name(create_out_samples)

 di as text _n "{hline 80}"
 di as text "create_out_samples.do — RUN START: `c(current_date)' `c(current_time)'"
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
  * Base outcome sample
  *******************************************
  local create_b = 1
  if `create_b' == 1 {
    // va sample
    include $consolidated_dir/do/samples/create_va_sample.doh

    // Postsecondary Outcomes
    do "$matt_files_dir/merge_k12_postsecondary.doh" enr_only
    drop enr enr_2year enr_4year
    rename enr_ontime enr
    rename enr_ontime_2year enr_2year
    rename enr_ontime_4year enr_4year

    * Save temporary dataset
    compress
    tempfile va_dataset
    save `va_dataset'

    include $consolidated_dir/do/samples/create_va_g11_out_sample_`version'.doh

    // merge on k12 postsecondary distances (helper relocated 2026-05-08 batch 9c)
    include $consolidated_dir/do/data_prep/k12_postsec_distance/merge_k12_postsec_dist.doh

    // merge on lag 2 ELA scores without dropping obs, to predict lag 1 ELA score
    include $consolidated_dir/do/samples/merge_lag2_ela.doh



    label data "Base Outcome VA Sample"

    compress
    save "$datadir_clean/va_samples_`version'/out_b.dta", replace

  }

  *******************************************
  * outcome sample with leave out prior scores
  *******************************************
  local create_l = 1
  if `create_l' == 1 {
    use "$datadir_clean/va_samples_`version'/out_b.dta", clear

    // do helper file to merge leave out scores
    include $consolidated_dir/do/samples/merge_loscore.doh

    label data "Outcome VA Sample with Leave Out Scores"

    compress
    save "$datadir_clean/va_samples_`version'/out_l.dta", replace
  }

  *******************************************
  * outcome sample with ACS controls
  *******************************************
  local create_a = 1
  if `create_a' == 1 {

    // call do helper file to merge onto ACS controls. Be sure to specify correct arguments. 5 args in total
    do $consolidated_dir/do/samples/merge_va_smp_acs.doh ///
      outcome ///
      "$datadir_clean/va_samples_`version'/out_b.dta" ///
      out_b.dta ///
      create_sample ///
      none

    label data "Outcome VA Sample with ACS Controls"


    save "$datadir_clean/va_samples_`version'/out_a.dta", replace
  }

  *******************************************
  * outcome sample with sibling controls
  *******************************************
  local create_s = 1
  if `create_s' == 1 {
    use "$datadir_clean/va_samples_`version'/out_b.dta", clear

    //subroutine that merges on sibling college going controls
    include $consolidated_dir/do/samples/merge_sib.doh

    label data "Outcome VA Sample with Sibling Controls"

    compress
    save "$datadir_clean/va_samples_`version'/out_s.dta", replace
  }

  *******************************************
  * outcome sample with leave out score and ACS controls
  *******************************************
  local create_la = 1
  if `create_la' == 1 {
    // call do helper file to merge onto ACS controls. Be sure to specify correct arguments. 5 args in total
    do $consolidated_dir/do/samples/merge_va_smp_acs.doh ///
      outcome ///
      "$datadir_clean/va_samples_`version'/out_l.dta" ///
      out_l.dta ///
      create_sample ///
      none

    label data "Outcome VA Sample with Leave Out Scores and ACS Controls"


    save "$datadir_clean/va_samples_`version'/out_la.dta", replace

  }

  *******************************************
  * outcome sample with leave out score and sibling controls
  *******************************************
  local create_ls = 1
  if `create_ls' == 1 {
    use "$datadir_clean/va_samples_`version'/out_l.dta", clear

    //subroutine that merges on sibling college going controls
    include $consolidated_dir/do/samples/merge_sib.doh

    label data "Outcome VA Sample with Leave Out Scores and Sibling Controls"


    compress
    save "$datadir_clean/va_samples_`version'/out_ls.dta", replace
  }


  *******************************************
  * outcome sample with ACS and sibling controls
  *******************************************
  local create_as = 1
  if `create_as' == 1 {
    use "$datadir_clean/va_samples_`version'/out_a.dta", clear

    //subroutine that merges on sibling college going controls
    include $consolidated_dir/do/samples/merge_sib.doh

    label data "Outcome VA Sample with ACS and Sibling Controls"


    compress
    save "$datadir_clean/va_samples_`version'/out_as.dta", replace


  }


  *******************************************
  * outcome sample with leave out score, ACS, and sibling controls
  *******************************************
  local create_las = 1
  if `create_las'==1 {
    use "$datadir_clean/va_samples_`version'/out_la.dta", clear

    //subroutine that merges on sibling college going controls
    include $consolidated_dir/do/samples/merge_sib.doh

    label data "Outcome VA Sample with Leave Out Scores, ACS, and Sibling Controls"


    compress
    save "$datadir_clean/va_samples_`version'/out_las.dta", replace
  }

  // create vars for number of students contributing to VA estimates
  foreach sample in b l a s la ls las {
    foreach outcome in enr enr_2year enr_4year {
      use "$datadir_clean/va_samples_`version'/out_`sample'.dta", clear
      egen n_g11_`outcome'_`sample'_sp = count(state_student_id) ///
        if touse_g11_`outcome'==1 ///
        , by(cdscode year)
    }
  }

}




timer off 1
timer list

cap log close create_out_samples
cap translate "$logdir/samples/create_out_samples.smcl" ///
  "$logdir/samples/create_out_samples.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
