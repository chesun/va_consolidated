/*------------------------------------------------------------------------------
do/va/va_out_all.do — outcome VA estimation (incl. Deep Knowledge), all combos
================================================================================

PURPOSE
    Estimate outcome VA (postsecondary enrollment: enr / enr_2year / enr_4year)
    via the CFR drift-limit shrinkage estimator across the standard 16-spec
    framework.  Outcome-side mirror of `va_score_all.do' with one major
    addition: **Deep Knowledge (DK) VA** — outcome VA controlling for both
    ELA and Math test-score VA estimates (per Naven 2023; the
    "deep knowledge" in question is the disambiguation between teaching
    quality vs general school-quality factors).

    For every (version, va_ctrl, sample, outcome) tuple — and for both
    no-peer and with-peer specifications — this script produces:
      1. Outcome VA without DK (basic CFR + spec-test).
      2. Outcome VA with DK (controls augmented by va_cfr_g11_ela and
         va_cfr_g11_math, merged in from va_score_all.do output).
      3. Spec-tests for both.
      4. Collapsed school-year .dta with the full set of va_cfr_g11_<outcome>{_dk,_peer}
         estimates and per-school-year n's (`n_g11_<outcome>_<sample>_sp` and
         `n_g11_<outcome>_dk_<sample>_sp`).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after `va_score_all.do'
    because DK VA reads the score-VA estimates produced there.

PRODUCTION STATUS
    GATED OFF in the predecessor `do_all.do:165-166' (`local do_va = 0').
    Run-once-cached: outputs persist on Scribe and feed downstream paper
    Tables 4-7 (pass-through regressions; Phase 1a §3.3 step 4 + step 10).

INPUTS
    CANONICAL (read):
      $datadir_clean/va_samples_v[12]/out_<sample>.dta — outcome samples (batch 2b)
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<subject>_<sample>_sp_<va_ctrl>_ct.dta
                                          — score-VA estimates produced by
                                            do/va/va_score_all.do (this batch).

    LEGACY (read-only):
      `vam' ado v2.0.1+noseed (project-pinned per ADR-0006)

    Helpers (CONSOLIDATED):
      do/va/helpers/macros_va.doh
      do/va/helpers/drift_limit.doh
      do/va/helpers/macros_va_all_samples_controls.doh

OUTPUTS
    CANONICAL (write per ADR-0021 sandbox):
      $estimates_dir/va_cfr_all_v[12]/vam/va_<outcome>_<sample>_sp_<va_ctrl>_ct.ster
                                          — outcome VAM (no peer)
      $estimates_dir/va_cfr_all_v[12]/vam/va_p_<outcome>_<sample>_sp_<va_ctrl>_ct.ster
                                          — outcome VAM (with peer)
      $estimates_dir/va_cfr_all_v[12]/vam/dk_va_<outcome>_<sample>_sp_<va_ctrl>_ct.ster
                                          — DK outcome VAM (no peer)
      $estimates_dir/va_cfr_all_v[12]/vam/dk_va_p_<outcome>_<sample>_sp_<va_ctrl>_ct.ster
                                          — DK outcome VAM (with peer)
      $estimates_dir/va_cfr_all_v[12]/spec_test/spec_<...>.ster — 4 spec-test ster
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<outcome>_<sample>_sp_<va_ctrl>_ct.dta
                                          — collapsed school-year VA estimates
      $logdir/va/va_out_all.smcl + .log      — per-do-file log

ROLE IN ADR-0021 SANDBOX
    Reads CANONICAL sample dtas + CANONICAL score-VA estimates (produced by
    va_score_all.do) + LEGACY `vam' ado.  Writes ONLY to CANONICAL
    `$estimates_dir/...` and `$logdir/`.  Sandbox-clean.

RELOCATION HISTORY (per plan v3 §3.3 step 3 batch 3a, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/va_out_all.do
    Destination: do/va/va_out_all.do
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      Same pattern as va_score_all.do.  Specifics:
      - L62 `use $vaprojdir/data/va_samples_`version'/out_`sample''
         -> `use "$datadir_clean/va_samples_`version'/out_`sample'"' (CANONICAL)
      - L78, L85, L102, L109, L118, L143, L150, L168, L176, L191:
            $vaprojdir/estimates/va_cfr_all_`version'/...
         -> $estimates_dir/va_cfr_all_`version'/...  (CANONICAL)
      - L210-211 translate target: $vaprojdir/log_files/...  -> $logdir/...
      - 3 helper-include path repoints (macros_va, drift_limit, macros_va_all_samples_controls)
        all use absolute `$consolidated_dir/do/va/helpers/...' per
        absolute-path-after-cd convention (batch 2c).

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First created by Christina (Che) Sun September 9, 2022.
    2022-10-06: Added specifications with peer controls.
    2022-10-31: Changed naming conventions (sp/ct/lv).
    2022-12-29: Added v1/v2 prior-score loop.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 3 batch 3a.

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 3
    ADRs: 0004 (canonical pipeline), 0006 (vam), 0009 (v1 canonical), 0021 (sandbox)
    Predecessor caller: cde_va_project_fork/do_files/do_all.do:165-166 (gated 0)
------------------------------------------------------------------------------*/


********************************************************************************
/* outcome VA estimation for all samples and specifications */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun Sptember 9, 2022
*****************************************************

/* To run this do file, type:
do $consolidated_dir/do/va/va_out_all.do
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


cap mkdir "$logdir/va"
 cd $vaprojdir

 log close _all

 log using "$logdir/va/va_out_all.smcl", replace text

 di as text _n "{hline 80}"
 di as text "va_out_all.do — RUN START: `c(current_date)' `c(current_time)'"
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

/* do helper file with macros for different controls, samples, forecast bias leave out vars,
and their combinations for running loops */
include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh

foreach version in v1 v2 {
  di "VA version: `version'"

  ****************************************************
  /*  outcome VA estimation and specification test, all possible control - sample combinations */
  ****************************************************

  foreach va_ctrl of local va_controls {
    foreach sample of local `va_ctrl'_ctrl_samples {
      foreach outcome in enr enr_2year enr_4year {
        use "$datadir_clean/va_samples_`version'/out_`sample'" if touse_g11_`outcome'==1, clear


        ****** CFR VA estimation without peer controls
        di "VA estimation for `sample' sample with `va_ctrl' controls. Subject: `subject'. No peer controls"

        di "control variables: ``va_ctrl'_spec_controls'"

        vam `outcome' ///
      		, teacher(school_id) year(year) class(school_id) ///
      		controls( ///
      			i.year ///
      			``va_ctrl'_spec_controls' ///
          ) ///
      		data(merge tv score_r) ///
      		driftlimit(`out_drift_limit') ///
          estimates($estimates_dir/va_cfr_all_`version'/vam/va_`outcome'_`sample'_sp_`va_ctrl'_ct.ster, replace)

        rename tv va_cfr_g11_`outcome'
        rename score_r g11_`outcome'_r

        // specification test
        reg g11_`outcome'_r va_cfr_g11_`outcome', cluster(school_id)
        estimates save $estimates_dir/va_cfr_all_`version'/spec_test/spec_`outcome'_`sample'_sp_`va_ctrl'_ct.ster, replace


        ****** CFR VA estimation with peer controls
        di "VA estimation for `sample' sample with `va_ctrl' controls. Subject: `subject'. With peer controls"

        di "control variables: ``va_ctrl'_spec_controls' `peer_`va_ctrl'_controls'"

        vam `outcome' ///
          , teacher(school_id) year(year) class(school_id) ///
          controls( ///
            i.year ///
            ``va_ctrl'_spec_controls' ///
            `peer_`va_ctrl'_controls' ///
          ) ///
          data(merge tv score_r) ///
          driftlimit(`out_drift_limit') ///
          estimates($estimates_dir/va_cfr_all_`version'/vam/va_p_`outcome'_`sample'_sp_`va_ctrl'_ct.ster, replace)

        rename tv va_cfr_g11_`outcome'_peer
        rename score_r g11_`outcome'_r_peer

        // specification test
        reg g11_`outcome'_r_peer va_cfr_g11_`outcome'_peer, cluster(school_id)
        estimates save $estimates_dir/va_cfr_all_`version'/spec_test/spec_p_`outcome'_`sample'_sp_`va_ctrl'_ct.ster, replace




        **************************************************************************
        // Deep Knowledge VA
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


        ****** Deep Knowledge VA estimation without peer controls
        // DK VA controlling for both ELA and Math test score VA
        di "Deep Knowledge VA estimation for `sample' sample with `va_ctrl' controls. Outcome: `outcome'. No peer controls"

        vam `outcome' ///
          , teacher(school_id) year(year) class(school_id) ///
          controls( ///
            i.year ///
            ``va_ctrl'_spec_controls' ///
            va_cfr_g11_ela ///
            va_cfr_g11_math ///
          ) ///
          data(merge tv score_r) ///
          driftlimit(`out_drift_limit') ///
          estimates($estimates_dir/va_cfr_all_`version'/vam/dk_va_`outcome'_`sample'_sp_`va_ctrl'_ct.ster, replace)

          rename tv va_cfr_g11_`outcome'_dk
          rename score_r g11_`outcome'_dk_r

          // specification test
          reg g11_`outcome'_dk_r va_cfr_g11_`outcome'_dk, cluster(school_id)
          estimates save $estimates_dir/va_cfr_all_`version'/spec_test/dk_spec_`outcome'_`sample'_sp_`va_ctrl'_ct.ster, replace


          ****** Deep Knowledge VA estimation with peer controls
          // DK VA controlling for both ELA and Math test score VA
          di "Deep Knowledge VA estimation for `sample' sample with `va_ctrl' controls. Outcome: `outcome'. With peer controls"

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
            driftlimit(`out_drift_limit') ///
            estimates($estimates_dir/va_cfr_all_`version'/vam/dk_va_p_`outcome'_`sample'_sp_`va_ctrl'_ct.ster, replace)


          rename tv va_cfr_g11_`outcome'_dk_peer
          rename score_r g11_`outcome'_dk_r_peer

          // specification test
          reg g11_`outcome'_dk_r_peer va_cfr_g11_`outcome'_dk_peer, cluster(school_id)
          estimates save $estimates_dir/va_cfr_all_`version'/spec_test/dk_spec_p_`outcome'_`sample'_sp_`va_ctrl'_cts.ster, replace





          // store VA estimates
          collapse (firstnm) va_* ///
            (mean) g11_`outcome'* ///
            (sum) n_g11_`outcome'_`sample'_sp = touse_g11_`outcome' ///
            n_g11_`outcome'_dk_`sample'_sp = touse_g11_`outcome'_dk ///
            , by(school_id cdscode grade year)

          label data "`outcome' VA estimates including DK VA (controlling for both ELA and Math VA) for `sample' sample with `va_ctrl'' controls"
          compress
          save "$estimates_dir/va_cfr_all_`version'/va_est_dta/va_`outcome'_`sample'_sp_`va_ctrl'_ct.dta", replace


      }
    }
  }

}




timer off 1
timer list
timer clear 1

cap log close

cap translate "$logdir/va/va_out_all.smcl" ///
  "$logdir/va/va_out_all.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
