/*------------------------------------------------------------------------------
do/va/va_score_fb_all.do — test-score VA forecast-bias test, all combos
================================================================================

PURPOSE
    Forecast-bias (FB) test for test-score VA: for every (version, va_ctrl,
    fb_var, sample, subject) tuple — and for both no-peer and with-peer
    specifications — this script:
      1. Loads the score-VA sample dta.
      2. Estimates VA twice via `vam':
         (a) without the FB leave-out variable as a control, and
         (b) with the FB leave-out variable added to controls.
      3. Forms `r_d = r_no_fb - r_with_fb' (difference of residuals).
      4. Runs the FB test: regresses `r_d' on the no-fb VA estimate.
      5. Saves the FB test .ster to `$estimates_dir/va_cfr_all_<v>/fb_test/'.

    The FB test detects spec misspecification: if leaving out a variable
    matters for VA prediction quality, that's evidence the included controls
    are missing something.  Per ADR-0004 + macros_va_all_samples_controls.doh
    L66, `va_controls_for_fb' EXCLUDES `lasd' (kitchen-sink + distance) by
    design — when the spec already includes everything, there's nothing to
    leave out (paper Tables 2/3 column 6 FB rows blank by design).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `va_score_all.do'.

PRODUCTION STATUS
    GATED OFF in the predecessor `do_all.do:163-164` (`local do_va = 0`).
    Run-once-cached: outputs persist on Scribe and feed downstream FB test
    tables (`va_score_fb_test_tab.do`, etc., all in Step 3 batches 3b/3c).

INPUTS
    CANONICAL (read):
      $datadir_clean/va_samples_v[12]/score_<sample>.dta — score samples (batch 2b output)

    LEGACY (read-only per ADR-0021 sandbox):
      `vam' ado v2.0.1+noseed (project-pinned per ADR-0006)

    Helpers (CONSOLIDATED includes per absolute-path-after-cd convention):
      do/va/helpers/macros_va.doh
      do/va/helpers/drift_limit.doh
      do/va/helpers/macros_va_all_samples_controls.doh

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox):
      $estimates_dir/va_cfr_all_v[12]/vam/va_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — VAM estimates with FB leave-out var as control (no peer)
      $estimates_dir/va_cfr_all_v[12]/vam/va_p_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — same, with peer controls
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — FB test estimates (no peer)
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_p_<subject>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — FB test estimates (with peer)
      $logdir/va/va_score_fb_all.smcl + .log — per-do-file log

      Note: the no-FB estimation (lines 83-90, 132-140) is INTENTIONALLY NOT
      saved — its sole purpose is to produce `score_r' (residual) for the
      r_d-difference computation.  Per predecessor verbatim.

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL sample dtas + LEGACY `vam' ado.  Writes ONLY to CANONICAL
    `$estimates_dir/...` and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3a, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/va_score_fb_all.do
    Destination: do/va/va_score_fb_all.do
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      Same pattern as va_score_all.do — see that file's RELOCATION HISTORY
      block.  Specifics:
      - L28 `cd $vaprojdir' preserved + restored at end.
      - L32 log target: $vaprojdir/log_files/sbac/...      -> $logdir/...
      - L42 `include $vaprojdir/do_files/sbac/macros_va.doh'
         -> `include $consolidated_dir/do/va/helpers/macros_va.doh'
      - L47 `include $vaprojdir/do_files/sbac/drift_limit.doh'
         -> `include $consolidated_dir/do/va/helpers/drift_limit.doh'
      - L55 `include $vaprojdir/do_files/sbac/macros_va_all_samples_controls.doh'
         -> `include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh'
      - L74 `use $vaprojdir/data/va_samples_`version'/...'
         -> `use "$datadir_clean/va_samples_`version'/..."'
      - L110, L120, L163, L172 estimates targets:
            $vaprojdir/estimates/va_cfr_all_`version'/...
         -> $estimates_dir/va_cfr_all_`version'/...
      - L199-200 translate target: $vaprojdir/log_files/...  -> $logdir/...

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun September 7, 2022.
    2022-09-19: Added code to save VAM estimates to ster file for regression
                including fb leave out vars.
    2022-10-06: Added specifications with matching peer controls.
    2022-10-31: Changed naming conventions (sp/ct/lv).
    2022-12-29: Added v1/v2 prior-score loop.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3a.

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 3
    ADRs: 0004 (canonical pipeline), 0006 (vam), 0009 (v1 canonical), 0021 (sandbox)
    MEMORY: [LEARN:domain] FB-test structure + lasd-blank-by-design (Christina 2026-04-26)
------------------------------------------------------------------------------*/


********************************************************************************
/* test score VA forecast bias test for all samples and specification combos */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun Sptember 7, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_score_fb_all.do
 */

/* CHANGE LOG:
09/19/2022: added code to save VAM estimates to ster file for regression including
fb leave out vars

10/06/2022: added specifications with matching peer controls

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
cap mkdir "$estimates_dir/va_cfr_all_v1/fb_test"
cap mkdir "$estimates_dir/va_cfr_all_v2"
cap mkdir "$estimates_dir/va_cfr_all_v2/vam"
cap mkdir "$estimates_dir/va_cfr_all_v2/fb_test"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
 cd $vaprojdir

 cap log close va_score_fb_all

 log using "$logdir/va/va_score_fb_all.smcl", replace text name(va_score_fb_all)

 di as text _n "{hline 80}"
 di as text "va_score_fb_all.do — RUN START: `c(current_date)' `c(current_time)'"
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
/* All possible forecast bias tests for test score VA - all sample/specification/leaveout var combos*/
****************************************************

/* do helper file with macros for different controls, samples, forecast bias leave out vars,
and their combinations for running loops */
include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh



foreach version in v1 v2 {
  di "VA version: `version'"

  // VA controls specifications used in forecast bias tests
  foreach va_ctrl of local va_controls_for_fb {
    di "VA control: `va_ctrl'"
    // forecast biase leave out vars for the given VA control specification
    foreach fb_var of local `va_ctrl'_ctrl_leave_out_vars {
      di "Forecast bias leave out var: `fb_var'"
      // samples used for the given VA control - FB leave out var combination
      foreach sample of local `fb_var'_fb_`va_ctrl'_samples {
        di "sample: `sample'"
        foreach subject in ela math {
          di "subject: `subject'"

          use "$datadir_clean/va_samples_`version'/score_`sample'" if touse_g11_`subject'==1, clear

          ************************************************************************
          ****** No peer controls
          // VA estimation without leave out vars
          di "`subject' VA without leave out var `fb_var'. Sample: `sample'. No peer controls"

          di "control variables: ``va_ctrl'_spec_controls'"

          vam sbac_`subject'_z_score ///
            , teacher(school_id) year(year) class(school_id) ///
            controls( ///
              i.year ///
              ``va_ctrl'_spec_controls' ///
            ) ///
            data(merge tv score_r) ///
            driftlimit(`score_drift_limit')

          rename tv va_cfr_g11_`subject'
          rename score_r sbac_g11_`subject'_r

          // display specification test estimates
          di "specification test for VA without leave out var, no peer controls "
          reg sbac_g11_`subject'_r va_cfr_g11_`subject', cluster(school_id)

          // VA with added forecast bias leave out vars as controls
          di "VA estimation including leave out var `fb_var'"
          vam sbac_`subject'_z_score ///
            , teacher(school_id) year(year) class(school_id) ///
            controls( ///
              i.year ///
              ``va_ctrl'_spec_controls' ///
              ``fb_var'_controls' ///
            ) ///
            data(merge tv score_r) ///
            driftlimit(`score_drift_limit') ///
            estimates($estimates_dir/va_cfr_all_`version'/vam/va_`subject'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace)


          rename tv va_fb_g11_`subject'
        	rename score_r sbac_g11_`subject'_r_p

          ******** Forecast bias test: Regress predicted scores on value added
          di " Forecast bias test leave out var: `fb_var'; sample: `sample'; `subject' VA specification: `va_ctrl'"
          gen sbac_g11_`subject'_r_d = sbac_g11_`subject'_r - sbac_g11_`subject'_r_p
          reg sbac_g11_`subject'_r_d va_cfr_g11_`subject', cluster(school_id)
          estimates save $estimates_dir/va_cfr_all_`version'/fb_test/fb_`subject'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace




          ************************************************************************
          ****** with peer controls
          di "`subject' VA without leave out var `fb_var'. Sample: `sample'. With peer controls"

          di "control variables: ``va_ctrl'_spec_controls' `peer_`va_ctrl'_controls'"

          vam sbac_`subject'_z_score ///
            , teacher(school_id) year(year) class(school_id) ///
            controls( ///
              i.year ///
              ``va_ctrl'_spec_controls' ///
              `peer_`va_ctrl'_controls' ///
            ) ///
            data(merge tv score_r) ///
            driftlimit(`score_drift_limit')


            rename tv va_cfr_g11_`subject'_peer
  	        rename score_r sbac_g11_`subject'_r_peer

            // display specification test estimates
            di "specification test for VA without leave out var, with peer controls "
            reg sbac_g11_`subject'_r_peer va_cfr_g11_`subject'_peer, cluster(school_id)


            // VA with added forecast bias leave out vars as controls
            di "VA estimation including leave out var `fb_var'"
            vam sbac_`subject'_z_score ///
              , teacher(school_id) year(year) class(school_id) ///
              controls( ///
                i.year ///
                ``va_ctrl'_spec_controls' ///
                ``fb_var'_controls' ///
                `peer_`va_ctrl'_controls' ///
              ) ///
              data(merge tv score_r) ///
              driftlimit(`score_drift_limit') ///
              estimates($estimates_dir/va_cfr_all_`version'/vam/va_p_`subject'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace)

            rename tv va_fb_g11_`subject'_peer
            rename score_r sbac_g11_`subject'_r_p_peer

            ******** Forecast bias test: Regress predicted scores on value added
            di " Forecast bias test leave out var: `fb_var'; sample: `sample'; `subject' VA specification: `va_ctrl'. WIth peer controls"
            gen sbac_g11_`subject'_r_d_peer = sbac_g11_`subject'_r_peer - sbac_g11_`subject'_r_p_peer
            reg sbac_g11_`subject'_r_d_peer va_cfr_g11_`subject'_peer, cluster(school_id)
            estimates save $estimates_dir/va_cfr_all_`version'/fb_test/fb_p_`subject'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace
        }

      }
    }
  }

}




timer off 1
timer list
timer clear 1

cap log close va_score_fb_all
cap translate "$logdir/va/va_score_fb_all.smcl" ///
  "$logdir/va/va_score_fb_all.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
