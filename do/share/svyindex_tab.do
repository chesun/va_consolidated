/*------------------------------------------------------------------------------
do/share/svyindex_tab.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    survey-VA index regression table (Table 8 panels).  Paper producer (figures + tables) for the VA paper.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Reads CHAIN VA outputs from $estimates_dir/va_cfr_all_<version>/<x>
    (Step 3 batches 3a-3d) + sample data from LEGACY $vaprojdir/data/
    va_samples_v1/<x> (sample data not yet relocated; out of Step 10 scope).
    Writes paper-shipping outputs to $tables_dir/share/<x> + $figures_dir/share/<x>
    (CANONICAL).

INPUTS (verified via grep on file body)
    $estimates_dir/survey_va/factor/index`reg'withdemo/`type'_index_`reg'_wdemo  (CHAIN read from Step 7 indexregwithdemo + indexhorseracewithdemo)
    $tables_dir/share/survey/check/`type'_index_combined_wdemo.tex  (LEGACY)
    $tables_dir/share/survey/pub/`type'_index_`reg'_wdemo.tex  (LEGACY)
    $tables_dir/share/survey/pub/`type'_index_combined_wdemo.tex  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/svyindex_tab.smcl (via log using)
    $tables_dir/share/survey/check/`type'_index_`reg'_wdemo.tex
    $tables_dir/share/survey/check/`type'_index_combined_wdemo.tex
    $tables_dir/share/survey/pub/`type'_index_`reg'_wdemo.tex
    $tables_dir/share/survey/pub/`type'_index_combined_wdemo.tex

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/svyindex_tab.do
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
    Sister files (this batch): base_sum_stats_tab.do, kdensity.do, reg_out_va_tab.do, sample_counts_tab.do, va_scatter.do, va_spec_fb_tab_all.do, va_var_explain.do, va_var_explain_tab.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* TABLE 4: create latex tables for caschls survey index regressions (separate bivariate
and horse race) */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun 02/06/2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/svyindex_tab.do
 */

/* CHANGE LOG:
09/12/2024: keep only fully restricted models
 */

cap log close _all

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

log using "$logdir/share/svyindex_tab.smcl", replace text

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


local date1 = c(current_date)
local time1 = c(current_time)

local datatype compcase imputed

local regtype bivar horse

local bivartitle "Value-added regressed on each index separately"
local horsetitle "Value-added regressed on all 3 indices simultaneously"

foreach type of local datatype {

  foreach reg of local regtype {  // load the dta dataset of the stacked regression estimates
    use $estimates_dir/survey_va/factor/index`reg'withdemo/`type'_index_`reg'_wdemo, replace

    // keep only ela, math, 2 year, 4 year
    drop va_dk* va_enr_l* va_enr_b*
    // drop base sample, keep only fully restricted specifications
    drop va_*b_sp_*

    // drop demographic controls and constants
    drop if strpos(var, "ln")==1
    drop if strpos(var, "avg")==1
    drop if strpos(var, "_")==1
    drop if var=="N" | var=="r2"

    foreach i in climate quality support {
      replace var="`i'_coef" if var=="z_`i'index_coef"
      replace var="`i'_stderr" if var=="z_`i'index_stderr"
    }

    gen rowgroup1=1 if strpos(var, "climate")==1
    replace rowgroup1=2 if strpos(var, "quality")==1
    replace rowgroup1=3 if strpos(var, "support")==1
    replace rowgroup1=4 if rowgroup1==.


      reshape long va_,  i(var) j(stub) string

      replace va_="Base" if va_=="b"
      replace va_="Base + LOS + Sibling + ACS" if va_=="las"
      replace va_="Yes" if va_=="Y"
      replace va_="No" if va_=="N"
      replace va_="ELA" if va_=="ela"
      replace va_="Math" if va_=="math"
      replace va_="2 Year Enrollment" if va_=="enr_2year"
      replace va_="4 Year Enrollment" if va_=="enr_4year"

      reshape wide va_, i(var) j(stub) string

    bysort rowgroup1: gen rowgroup2=(strpos(var, "coef")!=0)*1 + (strpos(var, "stderr")!=0)*2
    replace rowgroup2=1 if var=="va"
    replace rowgroup2=2 if var=="control"
    replace rowgroup2=3 if var=="peer"
    sort rowgroup1 rowgroup2

    foreach i in climate quality support {
      replace var="`i'" if var=="`i'_coef"
      replace var="" if var=="`i'_stderr"
    }



    replace var="School Climate" if var=="climate"
    replace var="Teacher and Staff Quality" if var=="quality"
    replace var="Counseling Support" if var=="support"

    replace var="VA" if var=="va"
    replace var="Peer" if var=="peer"
    replace var="Controls" if var=="control"

    drop if var=="sample"
    drop rowgroup*

    // rename the longest variale names to avoid character limit error with texsave
    foreach i in enr_2year enr_4year {
      rename va_`i'_las_sp_las_ct_p `i'_las_p
    }

    order var va_ela* va_math*

    tempfile `reg'_`type'
    save ``reg'_`type'', replace

    local texsave_options_single autonumber nonames replace size(footnotesize)  hlines(-3)
      /*title("``reg'title'") ///
       footnote("Standard errors in paranthesis. * \(p<0.05)\) ** \(p<0.01\) *** \(p<0.001\)") */

    // a folder for checking the tables
    texsave using "$tables_dir/share/survey/check/`type'_index_`reg'_wdemo.tex", `texsave_options_single'
    // folder for publication ready tables using the frag option for texsave
    texsave using "$tables_dir/share/survey/pub/`type'_index_`reg'_wdemo.tex", `texsave_options_single' frag

  }

  // combine the bivar table and horse race table 
  use `bivar_`type'', clear 
  // delete lines indicating va outcome, control, and peer 
  drop if var=="VA"
  drop if var=="Peer"
  drop if var=="Controls"

  insobs 1, before(1)
  replace var="Panel A: Separate Regressions for Each Index" if _n==1
  insobs 1, after(7)
  replace var="Panel B: Regressions Including All Indices" if _n==8

  // append the horse race table 
  append using `horse_`type''

  local texsave_options_combined autonumber nonames replace size(footnotesize)  hlines(1 7 7 8 -3)

  // a folder for checking the tables
  texsave using "$tables_dir/share/survey/check/`type'_index_combined_wdemo.tex", `texsave_options_combined'
  // folder for publication ready tables using the frag option for texsave
  texsave using "$tables_dir/share/survey/pub/`type'_index_combined_wdemo.tex", `texsave_options_combined' frag



}




























local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

log close
translate $logdir/share/svyindex_tab.smcl $logdir/share/svyindex_tab.log, replace
