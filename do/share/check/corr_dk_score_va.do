/*------------------------------------------------------------------------------
do/share/check/corr_dk_score_va.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    diagnostic check: correlation between drift-knot (DK) score and VA estimates.  Paper producer (figures + tables) for the VA paper.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Reads CHAIN VA outputs from $estimates_dir/va_cfr_all_<version>/<x>
    (Step 3 batches 3a-3d) + sample data from LEGACY $vaprojdir/data/
    va_samples_v1/<x> (sample data not yet relocated; out of Step 10 scope).
    Writes paper-shipping outputs to $tables_dir/share/<x> + $figures_dir/share/<x>
    (CANONICAL).

INPUTS (verified via grep on file body)
    $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/check/corr_dk_score_va.smcl (via log using)

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/check/corr_dk_score_va.do
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
    Sister files (this batch): base_sum_stats_tab.do, kdensity.do, reg_out_va_tab.do, sample_counts_tab.do, svyindex_tab.do, va_scatter.do, va_spec_fb_tab_all.do, va_var_explain.do, va_var_explain_tab.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* check the covariance between test score VA and DK VA for the variance
decomposition table   */
********************************************************************************

*****************************************************
* First created by Christina Sun July 3, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/check/corr_dk_score_va.do
 */

/* CHANGE LOG
*/

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
cap log close _all

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
cap mkdir "$logdir/share/check"
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

log using "$logdir/share/check/corr_dk_score_va.smcl", replace text

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984
set linesize 250


local date1 = c(current_date)
local time1 = c(current_time)


// load macros 
/* include $consolidated_dir/do/va/helpers/macros_va.doh */
/* include $vaprojdir/do_files/sbac/macros_va_all_samples_controls.doh */

local samples b las 
local b_sample_controls b_ct 
local las_sample_controls b_ct b_ct_p a_ct_p las_ct_p lasd_ct_p 


// correlation matrices of DK and test score VAs for the 10 specifications in the tables
foreach version in v1 v2 {
    use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta, clear 

    foreach va_outcome in enr_2year enr_4year {
        di "Postsec outcome: `va_outcome'"

        foreach sample of local samples {
            di "sample: `sample'"

                foreach va_ctrl of local `sample'_sample_controls {

                    di "control: `va_ctrl'"

                    di "`va_outcome' DK VA covariance with ELA VA, `sample' sample, `va_ctrl' control, _p at the end means peer"
                    corr va_dk_`va_outcome'_`sample'_sp_`va_ctrl' va_ela_`sample'_sp_`va_ctrl', cov wrap

                    di "`va_outcome' DK VA covariance with math VA, `sample' sample, `va_ctrl' control, _p at the end means peer"
                    corr va_dk_`va_outcome'_`sample'_sp_`va_ctrl' va_math_`sample'_sp_`va_ctrl', cov wrap

                }

        }
    }
}




local date2 = c(current_date)
local time2 = c(current_time)


di "Start date time /reg_out_va_all.do: `date1' `time1'"
di "End date time: `date2' `time2'"

log close 
translate $logdir/share/check/corr_dk_score_va.smcl $logdir/share/check/corr_dk_score_va.log, replace  // predecessor used .txt extension; normalized to .log per consolidated convention 


