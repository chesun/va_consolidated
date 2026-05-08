/*------------------------------------------------------------------------------
do/va/va_out_fb_all.do — outcome VA forecast-bias test (incl. DK), all combos
================================================================================

PURPOSE
    Forecast-bias (FB) test for outcome VA: outcome-side mirror of
    `va_score_fb_all.do' with the Deep Knowledge (DK) extension from
    `va_out_all.do'.  For every (version, va_ctrl, fb_var, sample, outcome)
    tuple — and for both no-peer and with-peer specifications — this script:

      Standard outcome VA branch (lines 84-175 of predecessor):
        1. Loads the outcome-VA sample dta.
        2. Estimates VA twice (without and with FB leave-out var).
        3. Forms r_d = r_no_fb - r_with_fb.
        4. Runs the FB test; saves .ster.

      Deep Knowledge outcome VA branch (lines 177-289 of predecessor):
        1. Merges in score-VA estimates (ELA + Math) from va_score_all output.
        2. Estimates DK VA twice (without and with FB leave-out var).
        3. Forms DK r_d.
        4. Runs the DK FB test; saves .ster.

    Same `va_controls_for_fb' loop excludes `lasd' by design (paper Tables
    2/3 column 6 FB rows blank by design — see MEMORY.md FB-test-structure).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `va_out_all.do'
    because the DK FB branch reads the score-VA estimates merged in by
    va_out_all.do (or directly from va_score_all.do output for the
    `va_cfr_g11_<subject>' values).

PRODUCTION STATUS
    GATED OFF in the predecessor `do_all.do:167-168' (`local do_va = 0').

INPUTS
    CANONICAL (read):
      $datadir_clean/va_samples_v[12]/out_<sample>.dta — outcome samples (batch 2b)
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<subject>_<sample>_sp_<va_ctrl>_ct.dta
                                          — score-VA estimates (from va_score_all.do)

    LEGACY (read-only):
      `vam' ado v2.0.1+noseed (project-pinned per ADR-0006)

    Helpers (CONSOLIDATED):
      do/va/helpers/macros_va.doh, drift_limit.doh, macros_va_all_samples_controls.doh

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox):
      $estimates_dir/va_cfr_all_v[12]/vam/va_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — outcome VAM with FB leave-out (no peer)
      $estimates_dir/va_cfr_all_v[12]/vam/va_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — same, with peer controls
      $estimates_dir/va_cfr_all_v[12]/vam/dk_va_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — DK outcome VAM (no peer)
      $estimates_dir/va_cfr_all_v[12]/vam/dk_va_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — DK outcome VAM (with peer)
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — outcome FB test (no peer)
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — outcome FB test (with peer)
      $estimates_dir/va_cfr_all_v[12]/fb_test/dk_fb_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — DK FB test (no peer)
      $estimates_dir/va_cfr_all_v[12]/fb_test/dk_fb_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — DK FB test (with peer)
      $logdir/va_out_fb_all.smcl + .log   — per-do-file log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL sample dtas + score-VA estimates + LEGACY `vam' ado.
    Writes ONLY to CANONICAL `$estimates_dir/...` and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3a, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/va_out_fb_all.do
    Destination: do/va/va_out_fb_all.do
    Path repointing: same pattern as va_score_fb_all.do.  Specifics:
      - L75 `use $vaprojdir/data/va_samples_`version'/out_`sample''
         -> `use "$datadir_clean/va_samples_`version'/out_`sample'"'
      - L111, L120, L162, L171, L180, L225, L236, L279, L288: estimates targets
         -> $estimates_dir/va_cfr_all_`version'/...
      - L314-315 translate target -> $logdir/...
      - 3 helper-include path repoints to absolute `$consolidated_dir/do/va/helpers/...'

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun September 9, 2022.
    2022-09-19: Added code to save VAM estimates to ster file for regression
                including fb leave out vars.
    2022-10-06: Added specifications with peer controls.
    2022-10-31: Changed naming conventions (sp/ct/lv).
    2022-12-29: Added v1/v2 prior-score loop.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3a.

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 3
    ADRs: 0004, 0006, 0009, 0021
    MEMORY: [LEARN:domain] FB-test structure + lasd-blank-by-design
------------------------------------------------------------------------------*/


********************************************************************************
/* outcome VA forecast bias test for all samples and specification combos */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun Sptember 9, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_out_fb_all.do
 */

/* CHANGE LOG:
09/19/2022: added code to save VAM estimates to ster file for regression including
fb leave out vars

10/06/2022: added specifications with peer controls

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


cd $vaprojdir

log close _all

log using "$logdir/va_out_fb_all.smcl", replace text

di as text _n "{hline 80}"
di as text "va_out_fb_all.do — RUN START: `c(current_date)' `c(current_time)'"
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
        foreach outcome in enr enr_2year enr_4year {
          di "outcome: `outcome'"

          use "$datadir_clean/va_samples_`version'/out_`sample'" if touse_g11_`outcome'==1, clear

          ************ No peer controls
          ******* Regular outcome VA
          // VA estimation without leave out vars
          di "`outcome' VA without leave out var `fb_var'. Sample: `sample'"

          di "control variables: ``va_ctrl'_spec_controls'"

          vam `outcome' ///
        		, teacher(school_id) year(year) class(school_id) ///
        		controls( ///
        			i.year ///
        			``va_ctrl'_spec_controls' ///
            ) ///
        		data(merge tv score_r) ///
        		driftlimit(`out_drift_limit')

          rename tv va_cfr_g11_`outcome'
          rename score_r g11_`outcome'_r

          // display specification test estimates
          di "specification test for VA without leave out var"
          reg g11_`outcome'_r va_cfr_g11_`outcome', cluster(school_id)

          // VA with added forecast bias leave out vars as controls
          di "VA estimation including leave out var `fb_var'"
          vam `outcome' ///
            , teacher(school_id) year(year) class(school_id) ///
            controls( ///
              i.year ///
              ``va_ctrl'_spec_controls' ///
              ``fb_var'_controls' ///
            ) ///
            data(merge tv score_r) ///
            driftlimit(`out_drift_limit') ///
            estimates($estimates_dir/va_cfr_all_`version'/vam/va_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace)

          rename tv va_fb_g11_`outcome'
        	rename score_r g11_`outcome'_r_p

          ******** Forecast bias test: Regress predicted scores on value added
          di " Forecast bias test leave out var: `fb_var'; sample: `sample'; `outcome' VA specification: `va_ctrl'. No peer controls"
          gen g11_`outcome'_r_d = g11_`outcome'_r - g11_`outcome'_r_p
          reg g11_`outcome'_r_d va_cfr_g11_`outcome', cluster(school_id)
          estimates save $estimates_dir/va_cfr_all_`version'/fb_test/fb_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace




          ************ With peer controls
          // VA estimation without leave out vars
          di "`outcome' VA without leave out var `fb_var'. Sample: `sample'. No peer controls"

          di "control variables: ``va_ctrl'_spec_controls' `peer_`va_ctrl'_controls'"

          vam `outcome' ///
        		, teacher(school_id) year(year) class(school_id) ///
        		controls( ///
        			i.year ///
        			``va_ctrl'_spec_controls' ///
              `peer_`va_ctrl'_controls' ///
            ) ///
        		data(merge tv score_r) ///
        		driftlimit(`out_drift_limit')

          rename tv va_cfr_g11_`outcome'_peer
          rename score_r g11_`outcome'_r_peer


          // display specification test estimates
          di "specification test for VA without leave out var, with peer controls"
          reg g11_`outcome'_r_peer va_cfr_g11_`outcome'_peer, cluster(school_id)


          // VA with added forecast bias leave out vars as controls
          di "VA estimation including leave out var `fb_var'. With peer controls"
          vam `outcome' ///
            , teacher(school_id) year(year) class(school_id) ///
            controls( ///
              i.year ///
              ``va_ctrl'_spec_controls' ///
              ``fb_var'_controls' ///
              `peer_`va_ctrl'_controls' ///
            ) ///
            data(merge tv score_r) ///
            driftlimit(`out_drift_limit') ///
            estimates($estimates_dir/va_cfr_all_`version'/vam/va_p_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace)

          rename tv va_fb_g11_`outcome'_peer
          rename score_r g11_`outcome'_r_p_peer

          ******** Forecast bias test: Regress predicted scores on value added
          di " Forecast bias test leave out var: `fb_var'; sample: `sample'; `outcome' VA specification: `va_ctrl'. With peer controls"
          gen g11_`outcome'_r_d_peer = g11_`outcome'_r_peer - g11_`outcome'_r_p_peer
          reg g11_`outcome'_r_d_peer va_cfr_g11_`outcome'_peer, cluster(school_id)
          estimates save $estimates_dir/va_cfr_all_`version'/fb_test/fb_p_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace




          ************************************************************************
          ****** Deep Knowledge outcome VA
          //merge on the test score VA estimates
          foreach subject in ela math {
            merge m:1 cdscode year using "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`subject'_`sample'_sp_`va_ctrl'_ct.dta", ///
              nogen keep(1 3) keepusing(va_cfr_g11_`subject')
            gen touse_g11_`outcome'_`subject' = touse_g11_`outcome'
            replace touse_g11_`outcome'_`subject' = 0 if mi(va_cfr_g11_`subject')
          }

          gen touse_g11_`outcome'_dk = touse_g11_`outcome'
          replace touse_g11_`outcome'_dk = 0 if mi(va_cfr_g11_ela)
          replace touse_g11_`outcome'_dk = 0 if mi(va_cfr_g11_math)

          // DK VA controlling for both ELA and Math test score VA without forecast bias leave out var
          di "Deep Knowledge VA estimation without FB leaveout var for `sample' sample with `va_ctrl' controls. Subject: `subject'. No peer controls"

          vam `outcome' ///
            , teacher(school_id) year(year) class(school_id) ///
            controls( ///
              i.year ///
              ``va_ctrl'_spec_controls' ///
              va_cfr_g11_ela ///
              va_cfr_g11_math ///
            ) ///
            data(merge tv score_r) ///
            driftlimit(`out_drift_limit')

            rename tv va_cfr_g11_`outcome'_dk
            rename score_r g11_`outcome'_dk_r

            // display specification test estimates
            di "specification test for DK VA without leave out var, no peer controls"
            reg g11_`outcome'_dk_r va_cfr_g11_`outcome'_dk, cluster(school_id)

            // DK VA controlling for both ELA and Math test score VA including forecast bias leave out var
            // VA with added forecast bias leave out vars as controls
            di "Deep Knowledge VA estimation including leave out var `fb_var'"
            vam `outcome' ///
              , teacher(school_id) year(year) class(school_id) ///
              controls( ///
                i.year ///
                ``va_ctrl'_spec_controls' ///
                va_cfr_g11_ela ///
                va_cfr_g11_math ///
                ``fb_var'_controls' ///
              ) ///
              data(merge tv score_r) ///
              driftlimit(`out_drift_limit') ///
              estimates($estimates_dir/va_cfr_all_`version'/vam/dk_va_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace)


            rename tv va_fb_g11_`outcome'_dk
            rename score_r g11_`outcome'_dk_r_p


            ******** Forecast bias test: Regress predicted scores on value added. No peer controls
            di " DK Forecast bias test leave out var: `fb_var'; sample: `sample'; `subject' VA specification: `va_ctrl'"
            gen g11_`outcome'_dk_r_d = g11_`outcome'_dk_r - g11_`outcome'_dk_r_p
          	reg g11_`outcome'_dk_r_d va_cfr_g11_`outcome'_dk, cluster(school_id)
            estimates save $estimates_dir/va_cfr_all_`version'/fb_test/dk_fb_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace



            ************ With peer controls
            // DK VA controlling for both ELA and Math test score VA without forecast bias leave out var
            di "Deep Knowledge VA estimation without FB leaveout var for `sample' sample with `va_ctrl' controls. Subject: `subject'. With peer controls"

            vam `outcome' ///
              , teacher(school_id) year(year) class(school_id) ///
              controls( ///
                i.year ///
                ``va_ctrl'_spec_controls' ///
                va_cfr_g11_ela ///
                va_cfr_g11_math ///
                `peer_`va_ctrl'_controls' ///
              ) ///
              data(merge tv score_r) ///
              driftlimit(`out_drift_limit')

            rename tv va_cfr_g11_`outcome'_dk_peer
            rename score_r g11_`outcome'_dk_r_peer

            // display specification test estimates
            di "specification test for DK VA without leave out var, with peer controls"
            reg g11_`outcome'_dk_r_peer va_cfr_g11_`outcome'_dk_peer, cluster(school_id)


            // DK VA controlling for both ELA and Math test score VA including forecast bias leave out var
            // VA with added forecast bias leave out vars as controls. With peer controls
            di "Deep Knowledge VA estimation including leave out var `fb_var'. With peer controls"
            vam `outcome' ///
              , teacher(school_id) year(year) class(school_id) ///
              controls( ///
                i.year ///
                ``va_ctrl'_spec_controls' ///
                va_cfr_g11_ela ///
                va_cfr_g11_math ///
                ``fb_var'_controls' ///
                `peer_`va_ctrl'_controls' ///
              ) ///
              data(merge tv score_r) ///
              driftlimit(`out_drift_limit') ///
              estimates($estimates_dir/va_cfr_all_`version'/vam/dk_va_p_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace)

            rename tv va_fb_g11_`outcome'_dk_peer
            rename score_r g11_`outcome'_dk_r_p_peer

            ******** Forecast bias test: Regress predicted scores on value added. With peer controls
            di " DK Forecast bias test leave out var: `fb_var'; sample: `sample'; `subject' VA specification: `va_ctrl'. With peer controls"
            gen g11_`outcome'_dk_r_d_peer = g11_`outcome'_dk_r_peer - g11_`outcome'_dk_r_p_peer
          	reg g11_`outcome'_dk_r_d_peer va_cfr_g11_`outcome'_dk_peer, cluster(school_id)
            estimates save $estimates_dir/va_cfr_all_`version'/fb_test/dk_fb_p_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster, replace



        }

      }
    }
  }


}








timer off 1
timer list
timer clear 1

cap log close

cap translate "$logdir/va_out_fb_all.smcl" ///
  "$logdir/va_out_fb_all.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
