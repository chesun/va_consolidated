/*------------------------------------------------------------------------------
do/va/va_out_sib_lag.do — Phase 1a §3.3 step 3 batch 3d relocation
================================================================================

PURPOSE
    Sibling-lag forecast-bias diagnostic for outcome VA (mirror of va_score_sib_lag.do). Estimate outcome VA with lag-1 older-sibling controls + lag-2 older-sibling FB leave-out. Diagnostic-only (not paper-reported).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); diagnostic-only, sibling-lag
    branch.  Per do_all.do comment: "kept active for diagnostic; not reported
    in the paper but kept available in case coauthors revisit."

OUTPUTS (CANONICAL per ADR-0021 sandbox)
    $estimates_dir/va_cfr_all_v[12]/{vam,spec_test,fb_test,va_est_dta}/<outcome>_s_sp_sib1_ct[_sib2_lv].{ster,dta}
    $logdir/va/va_out_sib_lag.smcl + .log

RELOCATION (per plan v3 §3.3 step 3 batch 3d, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/sbac/va_out_sib_lag.do
    Path repointing applied via script-based sed pass (same as batch 3c2):
      $vaprojdir/log_files/sbac/<x> -> $logdir/<x>
      $vaprojdir/data/va_samples_* -> $datadir_clean/va_samples_*
      $vaprojdir/estimates/<x> -> $estimates_dir/<x>
      $vaprojdir/tables/<x> -> $tables_dir/<x>
      $vaprojdir/do_files/sbac/{macros_va,macros_va_all_samples_controls,drift_limit}.doh
        -> $consolidated_dir/do/va/helpers/<x> (absolute per batch 2c convention)

ADRs: 0004 (canonical pipeline), 0009 (v1 canonical), 0021 (sandbox; description convention)
ORIGINAL CHANGE LOG preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* run outcome VA estimation with lag 1 older sibling as controls and lag 2 older sibling
as leave out. Forecast bias test with lag 2 older sibling as leaveout  */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun November 20, 2022
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/sbac/va_out_sib_lag.do
 */

/* CHANGE LOG:

 */

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/va_cfr_all_v1"
cap mkdir "$estimates_dir/va_cfr_all_v1/vam"
cap mkdir "$estimates_dir/va_cfr_all_v1/spec_test"
cap mkdir "$estimates_dir/va_cfr_all_v1/fb_test"
cap mkdir "$estimates_dir/va_cfr_all_v1/va_est_dta"
cap mkdir "$estimates_dir/va_cfr_all_v2"
cap mkdir "$estimates_dir/va_cfr_all_v2/vam"
cap mkdir "$estimates_dir/va_cfr_all_v2/spec_test"
cap mkdir "$estimates_dir/va_cfr_all_v2/fb_test"
cap mkdir "$estimates_dir/va_cfr_all_v2/va_est_dta"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cd $vaprojdir

cap log close va_out_sib_lag

log using "$logdir/va/va_out_sib_lag.smcl", replace text name(va_out_sib_lag)

di as text _n "{hline 80}"
di as text "va_out_sib_lag.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


local date1 = c(current_date)
local time1 = c(current_time)


include $consolidated_dir/do/va/helpers/macros_va.doh
include $consolidated_dir/do/va/helpers/drift_limit.doh

//------------------------------------------------------------------------------
// VA estimation
//------------------------------------------------------------------------------
foreach version in v1 v2 {
  di "VA version: `version'"

  foreach outcome in enr enr_2year enr_4year {
    use $datadir_clean/va_samples_`version'/out_s if touse_g11_`outcome'==1 & touse_sib_lag==1, clear

    vam `outcome' ///
      , teacher(school_id) year(year) class(school_id) ///
      controls( ///
        i.year ///
        `b_controls' ///
        `sib_lag1_controls' ///
      ) ///
      data(merge tv score_r) ///
      driftlimit(`score_drift_limit') ///
      estimates($estimates_dir/va_cfr_all_`version'/vam/va_`outcome'_s_sp_sib1_ct.ster, replace)

    rename tv va_cfr_g11_`outcome'
    rename score_r sbac_g11_`outcome'_r

    // specification test
    reg sbac_g11_`outcome'_r va_cfr_g11_`outcome', cluster(school_id)
    estimates save $estimates_dir/va_cfr_all_`version'/spec_test/spec_`outcome'_s_sp_sib1_ct.ster, replace

    // store VA estimates
    collapse (firstnm) va_* ///
      (mean) sbac_*_r* ///
      (sum) n_g11_`outcome' = touse_g11_`outcome' ///
      , by(school_id cdscode grade year)

    label data "`outcome' test score VA estimates for sibling sample with lag 1 older sibling controls"
    compress
    save $estimates_dir/va_cfr_all_`version'/va_est_dta/va_`outcome'_s_sp_sib1_ct.dta, replace
  }


}

//------------------------------------------------------------------------------
// forecast bias test
//------------------------------------------------------------------------------
foreach version in v1 v2 {
  di "VA version: `version'"

  foreach outcome in enr enr_2year enr_4year {
    use $datadir_clean/va_samples_`version'/out_s if touse_g11_`outcome'==1 & touse_sib_lag==1, clear

    vam `outcome' ///
      , teacher(school_id) year(year) class(school_id) ///
      controls( ///
        i.year ///
        `b_controls' ///
        `sib_lag1_controls' ///
      ) ///
      data(merge tv score_r) ///
      driftlimit(`score_drift_limit') ///

    rename tv va_cfr_g11_`outcome'
    rename score_r sbac_g11_`outcome'_r

    // display specification test estimates
    di "specification test for VA without leave out var, no peer controls "
    reg sbac_g11_`outcome'_r va_cfr_g11_`outcome', cluster(school_id)


    // VA with added forecast bias leaveout var as controls
    di "VA estimation including leave out var lag 2 older sibling"

    vam `outcome' ///
      , teacher(school_id) year(year) class(school_id) ///
      controls( ///
        i.year ///
        `b_controls' ///
        `sib_lag1_controls' ///
        `sib_lag2_controls' ///
      ) ///
      data(merge tv score_r) ///
      driftlimit(`score_drift_limit') ///
      estimates($estimates_dir/va_cfr_all_`version'/vam/va_`outcome'_s_sp_sib1_ct_sib2_lv.ster, replace)

    rename tv va_fb_g11_`outcome'
    rename score_r sbac_g11_`outcome'_r_p

    ******** Forecast bias test: Regress predicted scores on value added
    di " Forecast bias test leave out var: lag 2 older sibling outcome; sample: sibling; `outcome' VA specification: lag 1 older sibling as control"
    gen sbac_g11_`outcome'_r_d = sbac_g11_`outcome'_r - sbac_g11_`outcome'_r_p
    reg sbac_g11_`outcome'_r_d va_cfr_g11_`outcome', cluster(school_id)
    estimates save $estimates_dir/va_cfr_all_`version'/fb_test/fb_`outcome'_s_sp_sib1_ct_sib2_lv.ster, replace



  }


}










local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close va_out_sib_lag
cap translate "$logdir/va/va_out_sib_lag.smcl" ///
  "$logdir/va/va_out_sib_lag.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
