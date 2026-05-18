/*------------------------------------------------------------------------------
do/share/kdensity.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    kdensity plots of VA estimates by version.  Paper producer (figures + tables) for the VA paper.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Reads CHAIN VA outputs from $estimates_dir/va_cfr_all_<version>/<x>
    (Step 3 batches 3a-3d) + sample data from LEGACY $vaprojdir/data/
    va_samples_v1/<x> (sample data not yet relocated; out of Step 10 scope).
    Writes paper-shipping outputs to $tables_dir/share/<x> + $figures_dir/share/<x>
    (CANONICAL).

INPUTS (verified via grep on file body)
    $consolidated_dir/do/va/helpers/drift_limit.doh  (helper include)
    $consolidated_dir/do/va/helpers/macros_va.doh  (helper include)
    $estimates_dir/va_cfr_all_`version'/va_est_dta/va_`va_outcome'_all.dta  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $figures_dir/share/va/`version'/va_`va1'_`va2'_kdensity_b_b_las_las_`version'.pdf
    $logdir/share/kdensity.smcl (via log using)
    $logdir/share/kdensity.smcl + $logdir/share/kdensity.log (translate)

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/kdensity.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                      -> removed (absolute paths)
      log_files/share/<x>.smcl (rel + abs forms)         -> $logdir/<x>.smcl  (CANONICAL)
      include $vaprojdir/do_files/sbac/<x>.doh           -> include $consolidated_dir/do/{va/helpers,samples}/<x>.doh
        (per Step 1/2 helper relocation; covers macros_va, drift_limit, create_diff_school_prop, create_prior_scores_v1/v2, merge_loscore, merge_sib, merge_lag2_ela, merge_va_smp_acs, create_va_g11_sample_v1/v2, create_va_g11_out_sample_v1/v2)
      $estimates_dir/va_cfr_all_<v>/<x> -> $estimates_dir/va_cfr_all_<v>/<x> (CHAIN read from Step 3)
      $estimates_dir/va_cfr_all_<v>/<x> -> $estimates_dir/va_cfr_all_<v>/<x> (CHAIN read; predecessor stored intermediate regsave dtas under tables/, consolidated relocates under $estimates_dir/)
      $vaprojdir/figures/share/<x> -> $figures_dir/share/<x> (CANONICAL paper-shipping)
      $vaprojdir/tables/share/<x> -> $tables_dir/share/<x> (CANONICAL paper-shipping)
      $vaprojdir/data/va_samples_v1/<x> -> kept LEGACY (sample data; out of Step 10 scope)
      translate (multi-line ABS form) -> $logdir/<x> (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10a
    Sister files (this batch): base_sum_stats_tab.do, reg_out_va_tab.do, sample_counts_tab.do, svyindex_tab.do, va_scatter.do, va_spec_fb_tab_all.do, va_var_explain.do, va_var_explain_tab.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* create kernel density plots for
1. ELA and Math VA, base/base and kitchen sink/kitchen sink, 4 graphs combined panel
2. 2 year and 4 year enrollment, base/base and kitchen sink/kitchen sink, 4 graphs combined panel  */
********************************************************************************

*****************************************************
* First created by Christina Sun February 16, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/kdensity.do
 */

/* CHANGE LOG:

 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
cap log close kdensity

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/share"
cap mkdir "$tables_dir/share/va"
cap mkdir "$tables_dir/share/va/check"
cap mkdir "$tables_dir/share/va/pub"
cap mkdir "$tables_dir/share/survey"
cap mkdir "$tables_dir/share/survey/check"
cap mkdir "$tables_dir/share/survey/pub"
cap mkdir "$figures_dir"
cap mkdir "$figures_dir/share"
cap mkdir "$figures_dir/share/va"

log using "$logdir/share/kdensity.smcl", replace text name(kdensity)

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

local sp_ct_p_combos b_sp_b_ct las_sp_las_ct

//----------------------------------------------------------------------------
//  standardize VA estimates
//----------------------------------------------------------------------------
foreach version in v1 v2 {
  foreach va_outcome in ela math enr_2year enr_4year {
    use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_`va_outcome'_all.dta, clear

    sort school_id year
    xtset school_id year

    keep cdscode school_id year *b_sp_b_ct *las_sp_las_ct
    // drop dk va to get around character limit for macros for mean and sd
    if inlist("`va_outcome'", "enr_2year", "enr_4year") {
      drop va_dk*
    }

    foreach v of varlist va_* {
      sum `v'
      local m_`v' = 0
      local sd_`v' : di %4.3f = r(sd)
      replace `v' = `v' - r(mean)

    }

    tempfile va_`va_outcome'
    save `va_`va_outcome''
  }


use `va_ela'
merge 1:1 cdscode year using `va_math', nogen
merge 1:1 cdscode year using `va_enr_2year', nogen
merge 1:1 cdscode year using `va_enr_4year', nogen


//----------------------------------------------------------------------------
// kernel density graphs
//----------------------------------------------------------------------------
foreach va_type in score enr {
  if "`va_type'"=="score" {
    local va1 ela
    local va2 math
    local type_str "Test Score"
  }
  if "`va_type'"=="enr" {
    local va1 enr_2year
    local va2 enr_4year
    local type_str "Enrollment"

  }

  twoway ///
    (kdensity va_`va1'_b_sp_b_ct) ///
    (kdensity va_`va2'_b_sp_b_ct) ///
    (kdensity va_`va1'_las_sp_las_ct) ///
    (kdensity va_`va2'_las_sp_las_ct) ///
    , ytitle("Density") xtitle("Value Added") ///
    title("`type_str' VA") ///
  	legend(label(1 "``va1'_str', Base/Base") label(2 "``va2'_str', Base/Base") ///
      label(3 "``va1'_str', Kitchen Sink/Kitchen Sink") label(4 "``va2'_str', Kitchen Sink/Kitchen Sink") size(vsmall)) ///
  	note("``va1'_str' VA Base/Base Mean (Standard Deviation) = `m_va_`va1'_b_sp_b_ct' (`sd_va_`va1'_b_sp_b_ct')" ///
  	"``va2'_str' VA Base/Base Mean (Standard Deviation) = `m_va_`va2'_b_sp_b_ct' (`sd_va_`va2'_b_sp_b_ct')" ///
  	"``va1'_str' VA Kitchen/Kitchen Mean (Standard Deviation) = `m_va_`va1'_las_sp_las_ct' (`sd_va_`va1'_las_sp_las_ct')" ///
    "``va2'_str' VA Kitchen/Kitchen Mean (Standard Deviation) = `m_va_`va2'_las_sp_las_ct' (`sd_va_`va2'_las_sp_las_ct')")

  graph export $figures_dir/share/va/`version'/va_`va1'_`va2'_kdensity_b_b_las_las_`version'.pdf, replace
}


}








local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close kdensity
translate $logdir/share/kdensity.smcl $logdir/share/kdensity.log, replace
