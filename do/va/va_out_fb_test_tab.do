/*------------------------------------------------------------------------------
do/va/va_out_fb_test_tab.do — outcome-VA forecast-bias test summary table
================================================================================

PURPOSE
    Outcome-side mirror of `va_score_fb_test_tab.do' — builds paper-shipping
    summary table of outcome-VA forecast-bias (FB) test results.  Same schema
    as score-side: appends rows for (no-peer × with-peer × CFR × predicted-
    score) per (outcome, va_ctrl, fb_var, sample) cell.

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `va_out_fb_all.do'.

INPUTS
    CANONICAL (read):
      $estimates_dir/va_cfr_all_v[12]/vam/va_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
      $estimates_dir/va_cfr_all_v[12]/vam/va_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
      $estimates_dir/va_cfr_all_v[12]/fb_test/fb_p_<outcome>_<sample>_sp_<va_ctrl>_ct_<fb_var>_lv.ster
                                          — produced by va_out_fb_all.do (batch 3a)

    LEGACY (read-only):
      $vaprojdir/estimates/va_cfr_all_v[12]/.../predicted_prior_score/...  — exploratory; Step 11 deferred.

    Helpers (CONSOLIDATED):
      $consolidated_dir/do/va/helpers/{macros_va,macros_va_all_samples_controls}.doh

OUTPUTS
    CANONICAL:
      $tables_dir/va_cfr_all_v[12]/fb_test/fb_<outcome>_all.dta — appended summary rows
      $logdir/va/va_out_fb_test_tab.smcl + .log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL FB ster + LEGACY predicted-score variants.
    Writes ONLY to CANONICAL `$tables_dir/...` and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3b, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/va_out_fb_test_tab.do
    Destination: do/va/va_out_fb_test_tab.do
    Path repointing: same pattern as va_score_fb_test_tab.do.  Specifics:
      - L31 cd $vaprojdir preserved + restored at end.
      - L35 log target -> $logdir
      - L45, L47 helper includes -> $consolidated_dir/do/va/helpers/...
      - L87, L94, L104, L113 CFR ster reads -> $estimates_dir
      - L122, L130, L137, L144 predicted-prior-score reads -> KEPT LEGACY $vaprojdir
      - L107, L116, L139, L146 regsave + L159 use -> $tables_dir

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun September 19, 2022.
    2022-10-06: Added specifications with peer controls.
    2022-10-31: Naming conventions.
    2022-12-29: v1/v2 prior-score loop.
    2024-08-15: Added predicted-prior-score FB variant.
    2024-08-29: Added peer-controls variant for predicted-prior-score.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3b.

REFERENCES
    Plan: §3.3 step 3
    ADRs: 0004, 0006, 0009, 0012, 0021
------------------------------------------------------------------------------*/


********************************************************************************
/* store all outcome VA forecast bias test results in a dta file */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun Sptember 19, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_out_fb_test_tab.do
 */

/* CHANGE LOG:
10/06/2022: add specifications with peer controls

10/31/2022: changed naming conventions
sp - sample
ct - control
lv - leave out variable


12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math

08/15/2024: add VA estimates using predicted ELA scores as controls

08/29/2024: add VA estimated using predicted ELA scores and including peer controls

 */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/va_cfr_all_v1"
cap mkdir "$tables_dir/va_cfr_all_v1/fb_test"
cap mkdir "$tables_dir/va_cfr_all_v2"
cap mkdir "$tables_dir/va_cfr_all_v2/fb_test"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cd $vaprojdir

cap log close va_out_fb_test_tab

log using "$logdir/va/va_out_fb_test_tab.smcl", replace text name(va_out_fb_test_tab)

di as text _n "{hline 80}"
di as text "va_out_fb_test_tab.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984

// include the macros
include $consolidated_dir/do/va/helpers/macros_va.doh

include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh


timer on 1


foreach version in v1 v2 {
  di "VA version: `version'"

  foreach outcome in enr enr_2year enr_4year {
    di "outcome: `outcome'"
    local append_macro replace

    foreach va_ctrl of local va_controls_for_fb {
      di "VA regression controls: `va_ctrl'"

      foreach fb_var of local `va_ctrl'_ctrl_leave_out_vars {
        di "Forecast bias leave out var: `fb_var'"

        foreach sample of local `fb_var'_fb_`va_ctrl'_samples {
          di "sample: `sample'"

          ****** calculating F stats for leave out vars

          // replace macro if fb leave out var is sibling college dummy, can only test 1.var
          if "`fb_var'" == "s" {
            local s_controls 	1.has_older_sibling_enr_2year	1.has_older_sibling_enr_4year
          }
          if "`fb_var'" == "ls" {
            local ls_controls `l_controls' 1.has_older_sibling_enr_2year	1.has_older_sibling_enr_4year
          }
          if "`fb_var'" == "as" {
            local as_controls `a_controls' 1.has_older_sibling_enr_2year	1.has_older_sibling_enr_4year
          }
          if "`fb_var'" == "las" {
            local las_controls `l_controls' `a_controls' 1.has_older_sibling_enr_2year	1.has_older_sibling_enr_4year
          }


          // load va estimates for the VAm regression including fb var without peer controls
          estimates use $estimates_dir/va_cfr_all_`version'/vam/va_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster
          // F test for leave out vars
          test ``fb_var'_controls'
          local f_stat: di %4.3f = r(F)
          local prob_f: di %4.3f = r(p)

          // load va estimates for the VAm regression including fb var with peer controls
          estimates use $estimates_dir/va_cfr_all_`version'/vam/va_p_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster
          // F test for leave out vars
          test ``fb_var'_controls'
          local f_stat_peer: di %4.3f = r(F)
          local prob_f_peer: di %4.3f = r(p)




          // regression estimates without peer controls
          estimates use $estimates_dir/va_cfr_all_`version'/fb_test/fb_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster

          // output estimates to dta dataset
          regsave using "$tables_dir/va_cfr_all_`version'/fb_test/fb_`outcome'_all.dta", ///
            pval ci addlabel(f_stat_lovar, `f_stat', prob_f, `prob_f', ///
            va_control, `va_ctrl', fb_var, `fb_var', va_sample, `sample', va_type, `outcome', peer_controls, 0, predicted_score, 0) `append_macro'


          // regression estimates with peer controls
          estimates use $estimates_dir/va_cfr_all_`version'/fb_test/fb_p_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster

          // output estimates to dta dataset
          regsave using "$tables_dir/va_cfr_all_`version'/fb_test/fb_`outcome'_all.dta", ///
            pval ci addlabel(f_stat_lovar, `f_stat_peer', prob_f, `prob_f_peer', ///
            va_control, `va_ctrl', fb_var, `fb_var', va_sample, `sample', va_type, `outcome', peer_controls, 1, predicted_score, 0) append


            // load VA estimates for VAM regression including fb var and predicted score as controls without peer controls
            * NOTE: predicted-prior-score reads are LEGACY ($vaprojdir/...); Step 11 deferred (exploratory).
            estimates use $vaprojdir/estimates/va_cfr_all_`version'/vam/predicted_prior_score/va_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster
            // F test for leave out vars
            test ``fb_var'_controls'
            local f_stat_hatscore: di %4.3f = r(F)
            local prob_f_hatscore: di %4.3f = r(p)


            // load VA estimates for VAM regression including fb var and predicted score as controls with peer controls
            estimates use $vaprojdir/estimates/va_cfr_all_`version'/vam/predicted_prior_score/va_p_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster
            // F test for leave out vars
            test ``fb_var'_controls'
            local f_stat_hatscore_peer: di %4.3f = r(F)
            local prob_f_hatscore_peer: di %4.3f = r(p)

            // regressione estimates without peer controls, using predicted scores as controls
            estimates use $vaprojdir/estimates/va_cfr_all_`version'/fb_test/predicted_prior_score/fb_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster
            // output estimates to dta dataset
            regsave using "$tables_dir/va_cfr_all_`version'/fb_test/fb_`outcome'_all.dta", ///
              pval ci addlabel(f_stat_lovar, `f_stat_hatscore', prob_f, `prob_f_hatscore', ///
              va_control, `va_ctrl', fb_var, `fb_var', va_sample, `sample', va_type, `outcome', peer_controls, 0, predicted_score, 1) append

            // regressione estimates with peer controls, using predicted scores as controls
            estimates use $vaprojdir/estimates/va_cfr_all_`version'/fb_test/predicted_prior_score/fb_p_`outcome'_`sample'_sp_`va_ctrl'_ct_`fb_var'_lv.ster
            // output estimates to dta dataset
            regsave using "$tables_dir/va_cfr_all_`version'/fb_test/fb_`outcome'_all.dta", ///
              pval ci addlabel(f_stat_lovar, `f_stat_hatscore_peer', prob_f, `prob_f_hatscore_peer', ///
              va_control, `va_ctrl', fb_var, `fb_var', va_sample, `sample', va_type, `outcome', peer_controls, 1, predicted_score, 1) append



          local append_macro append


        }
      }
    }

    use "$tables_dir/va_cfr_all_`version'/fb_test/fb_`outcome'_all.dta", clear
    label var f_stat_lovar "F statistic for leave out variables"
    label var prob_f "P value from F test for leave out vars"
    label var fb_var "Leave out vars for forecast bias test"
    label var va_type "VA outcome var"
    label var va_control "Controls in VA estimation"
    label var va_sample "Sample used in VA estimation"
    label var peer_controls "Corresponding Peer Controls"
    label var predicted_score "Using predicted ELA score as controls"
    drop if var == "_cons"
    order va_sample va_control fb_var peer_controls coef ci_lower ci_upper
    sort va_sample fb_var va_control peer_controls
    save, replace
  }

}


timer off 1
timer list
timer clear 1


cap log close va_out_fb_test_tab
cap translate "$logdir/va/va_out_fb_test_tab.smcl" ///
  "$logdir/va/va_out_fb_test_tab.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
