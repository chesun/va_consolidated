/*------------------------------------------------------------------------------
do/va/va_out_spec_test_tab.do — outcome-VA specification test summary table
================================================================================

PURPOSE
    Outcome-side mirror of `va_score_spec_test_tab.do' — builds paper-shipping
    summary table of outcome-VA specification-test results across the standard
    16-spec framework × v1/v2 prior-score versions × peer-on/off × predicted-
    prior-score variant.  Same schema as score-side (`pval`, `sd_va`, `sd_vam`,
    `va_control`, `va_sample`, `va_type`, `peer_controls`, `predicted_score`).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `va_out_all.do'.

INPUTS
    CANONICAL (read):
      $datadir_clean/va_samples_v[12]/out_<sample>.dta — outcome samples (batch 2b)
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<outcome>_<sample>_sp_<va_ctrl>_ct.dta
                                          — outcome-VA estimates (from va_out_all.do, batch 3a)
      $estimates_dir/va_cfr_all_v[12]/spec_test/spec_<outcome>_<sample>_sp_<va_ctrl>_ct.ster
      $estimates_dir/va_cfr_all_v[12]/spec_test/spec_p_<outcome>_<sample>_sp_<va_ctrl>_ct.ster

    LEGACY (read-only):
      `vam' ado v2.0.1+noseed (per ADR-0006).
      $vaprojdir/estimates/va_cfr_all_v[12]/.../predicted_prior_score/...  — exploratory; Step 11 deferred.

    Helpers (CONSOLIDATED):
      $consolidated_dir/do/va/helpers/{macros_va,macros_va_all_samples_controls,drift_limit}.doh

OUTPUTS
    CANONICAL:
      $tables_dir/va_cfr_all_v[12]/spec_test/spec_<outcome>_all.dta  — appended summary rows
      $logdir/va/va_out_spec_test_tab.smcl + .log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL + LEGACY (vam ado + explore predicted-score outputs).
    Writes ONLY to CANONICAL `$tables_dir/...` and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3b, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/va_out_spec_test_tab.do
    Destination: do/va/va_out_spec_test_tab.do
    Path repointing: same pattern as va_score_spec_test_tab.do.  Specifics:
      - L75 use sample dta -> $datadir_clean
      - L109, L122, L131 CFR estimate reads -> $estimates_dir
      - L140, L148, L157 predicted-prior-score reads -> KEPT LEGACY $vaprojdir
      - L127, L136, L153, L162 regsave + L168 use -> $tables_dir
      - 3 helper-include path repoints to absolute $consolidated_dir/do/va/helpers/
      - log + translate -> $logdir

PREDECESSOR LATENT BUG (preserved verbatim per ADR-0021)
    The predicted-prior-score with-peer row in this file (relocated L245)
    uses `sd_va, \`sd_va''` rather than the expected `\`sd_va_peer''`.  The
    score variant (`do/va/va_score_spec_test_tab.do` L165) computes BOTH
    `\`sd_va''` and `\`sd_va_peer''` for the predicted-prior-score branch
    and uses the peer variant for the with-peer row.  This file's
    predicted-prior-score branch only computes `\`sd_va''` (single `sum`
    on the non-peer estimate at L223) — and then uses that same value
    for both no-peer and with-peer rows.  Asymmetric to score variant.
    Real latent bug; the `sd_va` in the with-peer predicted-score row is
    effectively the no-peer SD.  Phase 1b naming/clarity will resolve by
    adding a `sum va_cfr_g11_<outcome>_peer` step + `\`sd_va_peer''`
    use in the addlabel call.

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina Sun)
    First created by Christina Sun September 19, 2022.
    2022-10-06: Added specifications with peer controls.
    2022-10-31: Naming conventions.
    2022-12-29: v1/v2 prior-score loop.
    2023-03-02: Renamed p value var to pval.
    2024-08-15: Added predicted-prior-score spec-test variant.
    2024-08-29: Added peer-controls variant for predicted-prior-score.
    2024-09-14: Added VAM SD calculation.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3b.

REFERENCES
    Plan: §3.3 step 3
    ADRs: 0004, 0006, 0009, 0012, 0021
    MEMORY: [LEARN:domain] _scrhat_ predicted-score is exploratory.
------------------------------------------------------------------------------*/


********************************************************************************
/* store all outcome VA specification test results in a dta file */
********************************************************************************

*****************************************************
* First created by Christina Sun Sptember 19, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_out_spec_test_tab.do
 */

/* CHANGE LOG:
10/06/2022: added specifications with peer controls

10/31/2022: changed naming conventions
sp - sample
ct - control
lv - leave out variable


12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math

03/02/2023: changed p value variable name to pval to be consistent with fb tables

08/15/2024: add spec test from VA estimates using predicted ELA scores as controls

08/29/2024: add VA estimated using predicted ELA scores and including peer controls

09/14/2024: add code to calculate SD of VA from variances output by the VAM command

 */


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/va_cfr_all_v1"
cap mkdir "$tables_dir/va_cfr_all_v1/spec_test"
cap mkdir "$tables_dir/va_cfr_all_v2"
cap mkdir "$tables_dir/va_cfr_all_v2/spec_test"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cd $vaprojdir

cap log close va_out_spec_test_tab

log using "$logdir/va/va_out_spec_test_tab.smcl", replace text name(va_out_spec_test_tab)

di as text _n "{hline 80}"
di as text "va_out_spec_test_tab.do — RUN START: `c(current_date)' `c(current_time)'"
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
include $consolidated_dir/do/va/helpers/drift_limit.doh


timer on 1



foreach version in v1 v2 {
  di "VA version: `version'"

  foreach outcome in enr enr_2year enr_4year {
    di "outcome: `outcome'"
    local append_macro replace

    foreach va_ctrl of local va_controls {
      di "VA regression controls: `va_ctrl'"

      foreach sample of local `va_ctrl'_ctrl_samples {
        di "sample: `sample'"

        // ****************************
        // get SD of VA from VAM variance output
        // ****************************
        use "$datadir_clean/va_samples_`version'/out_`sample'" if touse_g11_`outcome'==1, clear
        preserve

        di "VA estimation without peer controls, to get SD from VAM command"
        vam `outcome' ///
      		, teacher(school_id) year(year) class(school_id) ///
      		controls( ///
      			i.year ///
      			``va_ctrl'_spec_controls' ///
          ) ///
      		data(variance) ///
      		driftlimit(`out_drift_limit')

        local sd_vam: di %4.3f = sqrt(var_class[_N])
        di "macro sd_vam is `sd_vam'"


        restore
        di "VA estimation with peer controls, to get SD from VAM command"
        vam `outcome' ///
          , teacher(school_id) year(year) class(school_id) ///
          controls( ///
            i.year ///
            ``va_ctrl'_spec_controls' ///
            `peer_`va_ctrl'_controls' ///
          ) ///
          data(variance) ///
          driftlimit(`out_drift_limit')

        local sd_vam_peer: di %4.3f = sqrt(var_class[_N])
        di "macro sd_vam_peer is `sd_vam_peer'"



        use "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`outcome'_`sample'_sp_`va_ctrl'_ct.dta", clear

        sort school_id year
        xtset school_id year
        //calculate sd of va estimates without peer controls
        sum va_cfr_g11_`outcome'
        local sd_va: di %4.3f = r(sd)

        // sd of va estimates with peer controls
        sum va_cfr_g11_`outcome'_peer
        local sd_va_peer: di %4.3f = r(sd)

        // spec test estimates without peer controls
        estimates use $estimates_dir/va_cfr_all_`version'/spec_test/spec_`outcome'_`sample'_sp_`va_ctrl'_ct.ster
        test _b[va_cfr_g11_`outcome'] = 1
        local p_spec: di %4.3f = r(p)

        // output estimates to dta dataset
        regsave using "$tables_dir/va_cfr_all_`version'/spec_test/spec_`outcome'_all.dta", ///
          ci addlabel(pval, `p_spec', sd_va, `sd_va', sd_vam, `sd_vam', va_control, `va_ctrl', va_sample, `sample', va_type, `outcome', peer_controls, 0, predicted_score, 0) `append_macro'

        // spec test estimates with peer controls
        estimates use $estimates_dir/va_cfr_all_`version'/spec_test/spec_p_`outcome'_`sample'_sp_`va_ctrl'_ct.ster
        test _b[va_cfr_g11_`outcome'_peer] = 1
        local p_spec_peer: di %4.3f = r(p)

        // output estimates with peer controls to dta dataset
        regsave using "$tables_dir/va_cfr_all_`version'/spec_test/spec_`outcome'_all.dta", ///
          ci addlabel(pval, `p_spec_peer', sd_va, `sd_va_peer', sd_vam, `sd_vam_peer', va_control, `va_ctrl', va_sample, `sample', va_type, `outcome', peer_controls, 1, predicted_score, 0) append

        // VA using predicted score as controls — LEGACY (Step 11 deferred; exploratory)
          use $vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/predicted_prior_score/va_`outcome'_`sample'_sp_`va_ctrl'_ct.dta, clear
          sort school_id year
          xtset school_id year
          //calculate sd of va estimates without peer controls
          sum va_cfr_g11_`outcome'
          local sd_va: di %4.3f = r(sd)

          // spec test estimates without peer controls
          estimates use $vaprojdir/estimates/va_cfr_all_`version'/spec_test/predicted_prior_score/spec_`outcome'_`sample'_sp_`va_ctrl'_ct.ster
          test _b[va_cfr_g11_`outcome'] = 1
          local p_spec: di %4.3f = r(p)

          // output estimates to dta dataset
          regsave using "$tables_dir/va_cfr_all_`version'/spec_test/spec_`outcome'_all.dta", ///
            ci addlabel(pval, `p_spec', sd_va, `sd_va', sd_vam, -999, va_control, `va_ctrl', va_sample, `sample', va_type, `outcome', peer_controls, 0, predicted_score, 1) append

          // spec test estimates with peer controls
          estimates use $vaprojdir/estimates/va_cfr_all_`version'/spec_test/predicted_prior_score/spec_p_`outcome'_`sample'_sp_`va_ctrl'_ct.ster
          test _b[va_cfr_g11_`outcome'_peer] = 1
          local p_spec_peer: di %4.3f = r(p)

          // output estimates to dta dataset
          regsave using "$tables_dir/va_cfr_all_`version'/spec_test/spec_`outcome'_all.dta", ///
            ci addlabel(pval, `p_spec_peer', sd_va, `sd_va', sd_vam, -999, va_control, `va_ctrl', va_sample, `sample', va_type, `outcome', peer_controls, 1, predicted_score, 1) append

        local append_macro append
      }
    }
    use "$tables_dir/va_cfr_all_`version'/spec_test/spec_`outcome'_all.dta", clear
    label var pval "P value from test against b=1"
    label var va_type "VA outcome var"
    label var sd_va "standard deviation of VA estimates"
    label var sd_vam "SD from VAM command"
    label var va_control "Controls in VA estimation"
    label var va_sample "Sample used in VA estimation"
    label var peer_controls "Corresponding Peer Controls"
    label var predicted_score "Using predicted ELA score as controls"
    drop if var == "_cons"
    order va_sample va_control peer_controls coef ci_lower ci_upper
    sort va_sample va_control peer_controls
    save, replace
  }
}

















timer off 1
timer list
timer clear 1

cap log close va_out_spec_test_tab
cap translate "$logdir/va/va_out_spec_test_tab.smcl" ///
  "$logdir/va/va_out_spec_test_tab.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
