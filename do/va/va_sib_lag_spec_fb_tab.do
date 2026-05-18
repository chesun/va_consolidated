/*------------------------------------------------------------------------------
do/va/va_sib_lag_spec_fb_tab.do — Phase 1a §3.3 step 3 batch 3d relocation
================================================================================

PURPOSE
    Combined spec-test + FB-test summary tables for sibling-lag diagnostic specs.
    Reads the .ster outputs from va_score_sib_lag and va_out_sib_lag; appends
    rows to two .dta summary tables (spec-test + FB-test).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); diagnostic-only, sibling-lag
    branch.  Per do_all.do comment: "kept active for diagnostic; not reported
    in the paper but kept available in case coauthors revisit."

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified by grep at L114, L155, L125, L168)
    $tables_dir/va_cfr_all_v[12]/spec_test/spec_sib_lag.dta — regsave-appended spec-test summary
    $tables_dir/va_cfr_all_v[12]/fb_test/fb_sib_lag.dta — regsave-appended FB-test summary
    $logdir/va/va_sib_lag_spec_fb_tab.smcl + .log

    Note: writes ONLY to spec_test/ and fb_test/ subdirs (also written by
    batch 3b's va_*_spec_test_tab.do + va_*_fb_test_tab.do).  The mkdir prep
    for `combined/' below is dead per the predecessor — preserved verbatim
    per ADR-0021 (predecessor mkdir'd combined/ but never wrote to it).

RELOCATION (per plan v3 §3.3 step 3 batch 3d, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/sbac/va_sib_lag_spec_fb_tab.do
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
/* create tables for score and enrollment VA specification and forecast bias tests
 with lag 1 older sibling as controls and lag 2 older sibling
as leave out. Forecast bias test with lag 2 older sibling as leaveout  */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun November 20, 2022
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/sbac/va_sib_lag_spec_fb_tab.do
 */

/* CHANGE LOG:

 */

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/va_cfr_all_v1"
cap mkdir "$tables_dir/va_cfr_all_v1/combined"
cap mkdir "$tables_dir/va_cfr_all_v2"
cap mkdir "$tables_dir/va_cfr_all_v2/combined"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cd $vaprojdir

cap log close _all

log using "$logdir/va/va_sib_lag_spec_fb_tab.smcl", replace text

di as text _n "{hline 80}"
di as text "va_sib_lag_spec_fb_tab.do — RUN START: `c(current_date)' `c(current_time)'"
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
// tables for spec test
//------------------------------------------------------------------------------

foreach version in v1 v2 {
  di "VA version: `version'"

  local append_macro replace

  foreach va_outcome in ela math enr enr_2year enr_4year {
    di " VA va_outcome: `va_outcome'"

    use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_`va_outcome'_s_sp_sib1_ct.dta, clear

    sort school_id year
    xtset school_id year
    //calculate sd of va estimates
    sum va_cfr_g11_`va_outcome'
    local sd_va: di %4.3f = r(sd)

    // specification test without peer controls
    estimates use $estimates_dir/va_cfr_all_`version'/spec_test/spec_`va_outcome'_s_sp_sib1_ct.ster
    test _b[va_cfr_g11_`va_outcome'] = 1
    local p_spec: di %4.3f = r(p)

    regsave using $tables_dir/va_cfr_all_`version'/spec_test/spec_sib_lag.dta, ///
      ci addlabel(p_value, `p_spec', sd_va, `sd_va', va_control, sib_lag1, va_sample, sib_lag, va_type, `va_outcome', peer_controls, 0) `append_macro'

    local append_macro append

  }

  use $tables_dir/va_cfr_all_`version'/spec_test/spec_sib_lag.dta, clear
  drop if var == "_cons"
  order va_sample va_control peer_controls coef ci_lower ci_upper
  sort va_sample va_control peer_controls
  save, replace
}



//------------------------------------------------------------------------------
// tables for fb test
//------------------------------------------------------------------------------

foreach version in v1 v2 {
  di "VA version: `version'"

  local append_macro replace

  foreach va_outcome in ela math enr enr_2year enr_4year {
    di " VA va_outcome: `va_outcome'"


    // load va estimates for the VAm regression including fb var
    estimates use $estimates_dir/va_cfr_all_`version'/vam/va_`va_outcome'_s_sp_sib1_ct_sib2_lv.ster

    // F test for leave out vars
    test `sib_lag2_controls'
    local f_stat: di %4.3f = r(F)
    local prob_f: di %4.3f = r(p)


    // forecast bias estimates
    estimates use $estimates_dir/va_cfr_all_`version'/fb_test/fb_`va_outcome'_s_sp_sib1_ct_sib2_lv.ster

    regsave using $tables_dir/va_cfr_all_`version'/fb_test/fb_sib_lag.dta, ///
      pval ci addlabel(f_stat_lovar, `f_stat', prob_f, `prob_f', ///
      va_control, sib_lag1, fb_var, sib_lag2, va_sample, sib_lag, va_type, `va_outcome', peer_controls, 0) `append_macro'


    local append_macro append

  }

  use $tables_dir/va_cfr_all_`version'/fb_test/fb_sib_lag.dta, clear
  drop if var == "_cons"
  order va_sample va_control peer_controls coef ci_lower ci_upper
  sort va_sample va_control peer_controls
  save, replace
}






local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close
cap translate "$logdir/va/va_sib_lag_spec_fb_tab.smcl" ///
  "$logdir/va/va_sib_lag_spec_fb_tab.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
