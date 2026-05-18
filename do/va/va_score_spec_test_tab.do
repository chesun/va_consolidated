/*------------------------------------------------------------------------------
do/va/va_score_spec_test_tab.do — score-VA specification test summary table
================================================================================

PURPOSE
    Build paper-shipping summary table of test-score VA specification-test
    results.  For every (version, subject, va_ctrl, sample) tuple — and for
    both no-peer and with-peer specifications — this script:
      1. Re-runs `vam` with `data(variance)` to extract VAM-internal SD.
      2. Loads the saved spec-test .ster from va_score_all.do output.
      3. Tests `_b[va_cfr_g11_<subject>] = 1' (the specification test).
      4. Appends row to `$tables_dir/va_cfr_all_<v>/spec_test/spec_<subject>_all.dta`.
      5. Repeats the spec-test branch for predicted-prior-score variant
         (LEGACY-read; produced by exploratory va_predicted_score.do that
         won't relocate until Step 11).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `va_score_all.do'.

PRODUCTION STATUS
    GATED OFF in the predecessor `do_all.do:172' (`local do_va = 0').
    Run-once-cached: outputs at $tables_dir/va_cfr_all_v[12]/spec_test/
    persist and feed paper Tables 2/3 spec-test rows.

INPUTS
    CANONICAL (read):
      $datadir_clean/va_samples_v[12]/score_<sample>.dta — score samples (batch 2b)
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<subject>_<sample>_sp_<va_ctrl>_ct.dta
                                          — score-VA estimates (from va_score_all.do, batch 3a)
      $estimates_dir/va_cfr_all_v[12]/spec_test/spec_<subject>_<sample>_sp_<va_ctrl>_ct.ster
      $estimates_dir/va_cfr_all_v[12]/spec_test/spec_p_<subject>_<sample>_sp_<va_ctrl>_ct.ster

    LEGACY (read-only):
      `vam' ado v2.0.1+noseed (per ADR-0006).
      $vaprojdir/estimates/va_cfr_all_v[12]/va_est_dta/predicted_prior_score/...
      $vaprojdir/estimates/va_cfr_all_v[12]/spec_test/predicted_prior_score/...
                                          — predicted-prior-score variants;
                                            EXPLORATORY (per [LEARN:domain] _scrhat_).
                                            Produced by do_files/explore/va_predicted_score.do
                                            (Step 11 deferred); read from LEGACY until then.

    Helpers (CONSOLIDATED):
      $consolidated_dir/do/va/helpers/{macros_va,macros_va_all_samples_controls,drift_limit}.doh

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox):
      $tables_dir/va_cfr_all_v[12]/spec_test/spec_<subject>_all.dta
                                          — appended spec-test summary; 4 rows
                                            per (subject, va_ctrl, sample) cell
                                            (no-peer × with-peer × CFR × predicted-score)
      $logdir/va/va_score_spec_test_tab.smcl + .log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL (samples + CFR estimates) + LEGACY (vam ado + predicted-score
    explore outputs).  Writes ONLY to CANONICAL `$tables_dir/...` and `$logdir/`.
    Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3b, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/va_score_spec_test_tab.do
    Destination: do/va/va_score_spec_test_tab.do
    Path repointing under ADR-0021:
      - L35 `cd $vaprojdir' preserved + restored at end.
      - L39 log target: $vaprojdir/log_files/...     -> $logdir/...
      - L49, L51, L52 helper includes -> $consolidated_dir/do/va/helpers/... (per batch 2c convention)
      - L74 `use $vaprojdir/data/va_samples_...'     -> `use "$datadir_clean/va_samples_..."'
      - L107, L120, L129 CFR estimate reads          -> `$estimates_dir/...`
      - L138, L150, L159 predicted-prior-score reads -> KEPT LEGACY $vaprojdir/.../predicted_prior_score/...
        (exploratory subdir; relocates with va_predicted_score.do at Step 11)
      - L125, L133, L155, L164 regsave + L173 `use'  -> `$tables_dir/...` (CANONICAL; new $tables_dir global added to settings.do this batch)
      - L205-206 translate target                    -> $logdir/...

    Prereq settings.do edit: added `$tables_dir = "$consolidated_dir/tables"' and
    `$figures_dir = "$consolidated_dir/figures"' globals to the CANONICAL block.

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun September 15, 2022.
    2022-10-06: Added specifications with peer controls.
    2022-10-31: Naming conventions (sp/ct/lv).
    2022-12-29: v1/v2 prior-score loop.
    2023-03-02: Renamed p value var to pval (consistent with FB tables).
    2024-08-15: Added predicted-prior-score spec-test variant.
    2024-08-29: Added peer-controls variant for predicted-prior-score.
    2024-09-13: Added VAM SD calculation from variance output.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3b.

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 3
    ADRs: 0004 (canonical pipeline), 0006 (vam.ado), 0009 (v1 canonical),
          0012 (paper producers — tables under $tables_dir),
          0021 (do/ relocation; sandbox; description convention)
    MEMORY: [LEARN:domain] _scrhat_ predicted-score is exploratory, not v2.
------------------------------------------------------------------------------*/


********************************************************************************
/* store all test score VA specification test results in a dta file */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun Sptember 15, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_score_spec_test_tab.do
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

09/13/2024: add code to calculate SD of VA from variances output by the VAM command

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

log close _all

log using "$logdir/va/va_score_spec_test_tab.smcl", replace text

di as text _n "{hline 80}"
di as text "va_score_spec_test_tab.do — RUN START: `c(current_date)' `c(current_time)'"
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

  foreach subject in ela math {
    di "subject: `subject'"
    local append_macro replace

    foreach va_ctrl of local va_controls {
      di "VA regression controls: `va_ctrl'"

      foreach sample of local `va_ctrl'_ctrl_samples {
        di "sample: `sample'"

        // ****************************
        // get SD of VA from VAM variance output
        // ****************************
        use "$datadir_clean/va_samples_`version'/score_`sample'" if touse_g11_`subject'==1, clear
        preserve

        di "VA estimation without peer controls, to get SD from VAM command"
        vam sbac_`subject'_z_score  ///
      		, teacher(school_id) year(year) class(school_id) ///
      		controls( ///
      			i.year ///
      			``va_ctrl'_spec_controls' ///
          ) ///
      		data(variance) ///
      		driftlimit(`score_drift_limit')

        local sd_vam: di %4.3f = sqrt(var_class[_N])
        di "macro sd_vam is `sd_vam'"


        restore
        di "VA estimation with peer controls, to get SD from VAM command"

        vam sbac_`subject'_z_score ///
          , teacher(school_id) year(year) class(school_id) ///
          controls( ///
            i.year ///
            ``va_ctrl'_spec_controls' ///
            `peer_`va_ctrl'_controls' ///
          ) ///
          data(variance) ///
          driftlimit(`score_drift_limit')

        local sd_vam_peer: di %4.3f = sqrt(var_class[_N])
        di "macro sd_vam_peer is `sd_vam_peer'"

        use "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`subject'_`sample'_sp_`va_ctrl'_ct.dta", clear

        sort school_id year
        xtset school_id year
        //calculate sd of va estimates
        sum va_cfr_g11_`subject'
        local sd_va: di %4.3f = r(sd)

        // sd of va estimates with peer controls
        sum va_cfr_g11_`subject'_peer
        local sd_va_peer: di %4.3f = r(sd)

        // specification test without peer controls
        estimates use $estimates_dir/va_cfr_all_`version'/spec_test/spec_`subject'_`sample'_sp_`va_ctrl'_ct.ster
        test _b[va_cfr_g11_`subject'] = 1
        local p_spec: di %4.3f = r(p)

        // output estimates to dta dataset
        regsave using "$tables_dir/va_cfr_all_`version'/spec_test/spec_`subject'_all.dta", ///
          ci addlabel(pval, `p_spec', sd_va, `sd_va', sd_vam, `sd_vam', va_control, `va_ctrl', va_sample, `sample', va_type, `subject', peer_controls, 0, predicted_score, 0) `append_macro'

        // specification test with peer controls
        estimates use $estimates_dir/va_cfr_all_`version'/spec_test/spec_p_`subject'_`sample'_sp_`va_ctrl'_ct.ster
        test _b[va_cfr_g11_`subject'_peer] = 1
        local p_spec_peer: di %4.3f = r(p)

        regsave using "$tables_dir/va_cfr_all_`version'/spec_test/spec_`subject'_all.dta", ///
          ci addlabel(pval, `p_spec_peer', sd_va, `sd_va_peer', sd_vam, `sd_vam_peer', va_control, `va_ctrl', va_sample, `sample', va_type, `subject', peer_controls, 1, predicted_score, 0) append

        *************** VA using predicted score as controls
        * NOTE: predicted-prior-score reads are LEGACY ($vaprojdir/...)
        * because va_predicted_score.do (do_files/explore/) is Step 11 deferred.
        * EXPLORATORY per [LEARN:domain] _scrhat_; not paper-canonical (paper uses v1).

          use $vaprojdir/estimates/va_cfr_all_`version'/va_est_dta/predicted_prior_score/va_`subject'_`sample'_sp_`va_ctrl'_ct.dta, clear
          sort school_id year
          xtset school_id year
          //calculate sd of va estimates without peer controls
          sum va_cfr_g11_`subject'
          local sd_va: di %4.3f = r(sd)

          // sd of va estimates with peer controls
          sum va_cfr_g11_`subject'_peer
          local sd_va_peer: di %4.3f = r(sd)

          // spec test estimates without peer controls
          estimates use $vaprojdir/estimates/va_cfr_all_`version'/spec_test/predicted_prior_score/spec_`subject'_`sample'_sp_`va_ctrl'_ct.ster
          test _b[va_cfr_g11_`subject'] = 1
          local p_spec: di %4.3f = r(p)

          // output estimates to dta dataset
          regsave using "$tables_dir/va_cfr_all_`version'/spec_test/spec_`subject'_all.dta", ///
            ci addlabel(pval, `p_spec', sd_va, `sd_va', sd_vam, -999, va_control, `va_ctrl', va_sample, `sample', va_type, `subject', peer_controls, 0, predicted_score, 1) append

          // spec test estimates with peer controls
          estimates use $vaprojdir/estimates/va_cfr_all_`version'/spec_test/predicted_prior_score/spec_p_`subject'_`sample'_sp_`va_ctrl'_ct.ster
          test _b[va_cfr_g11_`subject'_peer] = 1
          local p_spec_peer: di %4.3f = r(p)

          // output estimates to dta dataset
          regsave using "$tables_dir/va_cfr_all_`version'/spec_test/spec_`subject'_all.dta", ///
            ci addlabel(pval, `p_spec_peer', sd_va, `sd_va_peer', sd_vam, -999,  va_control, `va_ctrl', va_sample, `sample', va_type, `subject', peer_controls, 1, predicted_score, 1) append




        local append_macro append
      }
    }
    use "$tables_dir/va_cfr_all_`version'/spec_test/spec_`subject'_all.dta", clear
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

cap log close
cap translate "$logdir/va/va_score_spec_test_tab.smcl" ///
  "$logdir/va/va_score_spec_test_tab.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
