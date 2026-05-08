/*------------------------------------------------------------------------------
do/va/va_score_all.do — test-score VA estimation, all samples × specifications
================================================================================

PURPOSE
    Estimate test-score (ELA + Math) value-added (VA) using the Chetty-
    Friedman-Rockoff (CFR) drift-limit shrinkage estimator, looping over the
    standard 16-spec framework defined in `macros_va_all_samples_controls.doh'
    (sample × control × subject × version × peer-controls-on/off).  This is
    the canonical score-VA entry point per ADR-0004 + ADR-0009.

    For every (version, va_ctrl, sample, subject) tuple — and for both
    no-peer and with-peer specifications — this script:
      1. Loads the corresponding score-VA sample dta (b/l/a/s/la/ls/as/las).
      2. Calls `vam' with the spec's controls + drift-limit shrinkage.
      3. Saves the .ster (raw VAM estimates) to `$estimates_dir/va_cfr_all_<v>/vam/'.
      4. Runs the specification test (regress prediction-residual on VA).
      5. Saves the .ster (spec-test estimates) to `$estimates_dir/va_cfr_all_<v>/spec_test/'.
      6. Collapses to school-year level and saves the `.dta' (school VA) to
         `$estimates_dir/va_cfr_all_<v>/va_est_dta/'.

    Uses the project-pinned `vam' v2.0.1+noseed per ADR-0006.

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block).

PRODUCTION STATUS
    GATED OFF in the predecessor `do_all.do:161-162' (`local do_va = 0').
    Run-once-cached: outputs at $vaprojdir/estimates/va_cfr_all_v[12]/...
    persist on Scribe and are re-read by the va_out_all.do (Deep Knowledge
    VA) and reg_out_va_*.do scripts.  In the consolidated repo, outputs land
    under CANONICAL `$estimates_dir/...` per ADR-0021 sandbox.  Invocation
    in main.do Phase 3 gated by the same `do_va' local for behavior parity.

INPUTS
    CANONICAL (read):
      $datadir_clean/va_samples_v1/score_<sample>.dta — base/l/a/s/la/ls/as/las (8 files)
      $datadir_clean/va_samples_v2/score_<sample>.dta — same 8 files for v2
      (output of do/samples/create_score_samples.do, batch 2b commit 5de34a7)

    LEGACY (read-only per ADR-0021 sandbox principle):
      `vam' ado v2.0.1+noseed (project-pinned per ADR-0006; located in /ado/)

    Helpers (CONSOLIDATED includes per the absolute-path-after-cd convention):
      do/va/helpers/macros_va.doh          — VA-pipeline locals
      do/va/helpers/drift_limit.doh        — score_drift_limit + out_drift_limit
      do/va/helpers/macros_va_all_samples_controls.doh — 16-spec framework

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox principle):
      $estimates_dir/va_cfr_all_v[12]/vam/va_<subject>_<sample>_sp_<va_ctrl>_ct.ster
                                            (32 ster per version × 2 versions = 64)
                                          — raw VAM estimates, no peer controls
      $estimates_dir/va_cfr_all_v[12]/vam/va_p_<subject>_<sample>_sp_<va_ctrl>_ct.ster
                                          — same, with peer controls
      $estimates_dir/va_cfr_all_v[12]/spec_test/spec_<...>.ster
                                          — specification test estimates (no peer)
      $estimates_dir/va_cfr_all_v[12]/spec_test/spec_p_<...>.ster
                                          — specification test estimates (with peer)
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<subject>_<sample>_sp_<va_ctrl>_ct.dta
                                          — collapsed school-year VA estimates
      $logdir/va_score_all.smcl + .log    — per-do-file log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL sample dtas (from batch 2b output) + LEGACY `vam' ado.
    Writes ONLY to CANONICAL `$estimates_dir/...` and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3a, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/va_score_all.do (predecessor)
    Destination: do/va/va_score_all.do (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - L10 usage comment: $vaprojdir/do_files/sbac/va_score_all
                        -> $consolidated_dir/do/va/va_score_all.do
      - L28 `cd $vaprojdir' preserved for behavior parity; restored at end.
        Per batch 2c convention: any consolidated `include' after `cd $vaprojdir'
        MUST use absolute `$consolidated_dir/do/...' prefix.
      - L32 log target: $vaprojdir/log_files/sbac/va_score_all.smcl
                     -> CANONICAL `$logdir/va_score_all.smcl'
      - L42 `include $vaprojdir/do_files/sbac/macros_va.doh'
         -> `include $consolidated_dir/do/va/helpers/macros_va.doh'
      - L47 `include $vaprojdir/do_files/sbac/drift_limit.doh'
         -> `include $consolidated_dir/do/va/helpers/drift_limit.doh'
      - L55 `include $vaprojdir/do_files/sbac/macros_va_all_samples_controls.doh'
         -> `include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh'
      - L65 `use $vaprojdir/data/va_samples_`version'/score_`sample''
         -> `use "$datadir_clean/va_samples_`version'/score_`sample'"'  (CANONICAL)
      - L80, L87, L105, L112, L123: estimates/save targets
            $vaprojdir/estimates/va_cfr_all_`version'/...
         -> $estimates_dir/va_cfr_all_`version'/...  (CANONICAL)
      - L141-142 translate target: $vaprojdir/log_files/...
                                -> $logdir/...

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun September 5, 2022.
    2022-10-13: Added specifications with matching peer controls.
    2022-10-31: Changed naming conventions (sp/ct/lv).
    2022-12-29: Added v1/v2 prior-score loop.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3a;
                paths repointed to CANONICAL per ADR-0021.

REFERENCES
    Plan:  quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 3
    ADRs:  0004 (sibling-VA canonical pipeline; va_score_all is the canonical entry),
           0006 (vam.ado pinned at v2.0.1 + noseed),
           0009 (prior-score v1 canonical),
           0021 (do/ relocation; sandbox; description convention)
    Predecessor caller: cde_va_project_fork/do_files/do_all.do:161-162 (gated 0)
------------------------------------------------------------------------------*/


********************************************************************************
/* test score VA estimation for all samples and specifications */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun Sptember 5, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_score_all.do
 */

/* CHANGE LOG:
10/13/2022: added specification with matching peer controls (i.e. sibling controls
with peer sibling controls, etc.)

10/31/2022: changed naming conventions
sp - sample
ct - control
lv - leave out variable


12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math
 */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/va_cfr_all_v1"
cap mkdir "$estimates_dir/va_cfr_all_v1/vam"
cap mkdir "$estimates_dir/va_cfr_all_v1/spec_test"
cap mkdir "$estimates_dir/va_cfr_all_v1/va_est_dta"
cap mkdir "$estimates_dir/va_cfr_all_v2"
cap mkdir "$estimates_dir/va_cfr_all_v2/vam"
cap mkdir "$estimates_dir/va_cfr_all_v2/spec_test"
cap mkdir "$estimates_dir/va_cfr_all_v2/va_est_dta"
cap mkdir "$logdir"


 cd $vaprojdir

 log close _all

 log using "$logdir/va_score_all.smcl", replace text

 di as text _n "{hline 80}"
 di as text "va_score_all.do — RUN START: `c(current_date)' `c(current_time)'"
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


include $consolidated_dir/do/va/helpers/drift_limit.doh

****************************************************
/*  Test score VA estimation and specification test, all possible control - sample combinations */
****************************************************

/* do helper file with macros for different controls, samples, forecast bias leave out vars,
and their combinations for running loops */
include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh


foreach version in v1 v2 {
  di "VA version: `version'"

  foreach va_ctrl of local va_controls {
    foreach sample of local `va_ctrl'_ctrl_samples {
      foreach subject in ela math {
        ************ without peer controls
        use "$datadir_clean/va_samples_`version'/score_`sample'" if touse_g11_`subject'==1, clear

        // CFR VA estimation
        di "VA estimation for `sample' sample with `va_ctrl' controls. Subject: `subject'"

        di "control variables: ``va_ctrl'_spec_controls'"

        vam sbac_`subject'_z_score ///
      		, teacher(school_id) year(year) class(school_id) ///
      		controls( ///
      			i.year ///
      			``va_ctrl'_spec_controls' ///
          ) ///
      		data(merge tv score_r) ///
      		driftlimit(`score_drift_limit') ///
          estimates($estimates_dir/va_cfr_all_`version'/vam/va_`subject'_`sample'_sp_`va_ctrl'_ct.ster, replace)

        rename tv va_cfr_g11_`subject'
        rename score_r sbac_g11_`subject'_r

        // specification test
        reg sbac_g11_`subject'_r va_cfr_g11_`subject', cluster(school_id)
        estimates save $estimates_dir/va_cfr_all_`version'/spec_test/spec_`subject'_`sample'_sp_`va_ctrl'_ct.ster, replace


        ************* with peer controls
        di "VA estimation for `sample' sample with `va_ctrl' controls. Subject: `subject'. With peer controls"

        di "control variables: ``va_ctrl'_spec_controls' `peer_`va_ctrl'_controls'"


        vam sbac_`subject'_z_score ///
          , teacher(school_id) year(year) class(school_id) ///
          controls( ///
            i.year ///
            ``va_ctrl'_spec_controls' ///
            `peer_`va_ctrl'_controls' ///
          ) ///
          data(merge tv score_r) ///
          driftlimit(`score_drift_limit') ///
          estimates($estimates_dir/va_cfr_all_`version'/vam/va_p_`subject'_`sample'_sp_`va_ctrl'_ct.ster, replace)

        rename tv va_cfr_g11_`subject'_peer
        rename score_r sbac_g11_`subject'_r_peer

        // specification test
        reg sbac_g11_`subject'_r_peer va_cfr_g11_`subject'_peer, cluster(school_id)
        estimates save $estimates_dir/va_cfr_all_`version'/spec_test/spec_p_`subject'_`sample'_sp_`va_ctrl'_ct.ster, replace


        // store VA estimates
        collapse (firstnm) va_* ///
          (mean) sbac_*_r* ///
          (sum) n_g11_`subject'_`sample'_sp = touse_g11_`subject' ///
          , by(school_id cdscode grade year)

        label data "`subject' test score VA estimates for `sample' sample with `va_ctrl' controls"
        compress
        save "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`subject'_`sample'_sp_`va_ctrl'_ct.dta", replace



      }
    }
  }
}




timer off 1
timer list
timer clear 1

cap log close

cap translate "$logdir/va_score_all.smcl" ///
  "$logdir/va_score_all.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
