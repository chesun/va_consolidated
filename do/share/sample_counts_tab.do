/*------------------------------------------------------------------------------
do/share/sample_counts_tab.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    sample-size counts table across spec/sample/outcome combinations.  Paper producer (figures + tables) for the VA paper.

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
    $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_`sample'_g11_`subject'.ster  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_`sample'_g11_`subject'.ster  (CHAIN read)
    $tables_dir/share/va/pub/counts_k12.tex ///  (LEGACY)
    $vaprojdir/data/va_samples_v1/base_nodrop.dta  (LEGACY)
    $vaprojdir/data/va_samples_v1/score_a.dta  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/sample_counts_tab.smcl (via log using)
    $logdir/share/sample_counts_tab.smcl + $logdir/share/sample_counts_tab.log (translate)

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/sample_counts_tab.do
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
    Sister files (this batch): base_sum_stats_tab.do, kdensity.do, reg_out_va_tab.do, svyindex_tab.do, va_scatter.do, va_spec_fb_tab_all.do, va_var_explain.do, va_var_explain_tab.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* sample counts table with mean z scores */
********************************************************************************

*****************************************************
* First created by Christina Sun March 2, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/sample_counts_tab.do
 */

/* CHANGE LOG:

 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
cap log close sample_counts_tab

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

log using "$logdir/share/sample_counts_tab.smcl", replace text name(sample_counts_tab)

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

// start with the base sample without dropping observations
use $vaprojdir/data/va_samples_v1/base_nodrop.dta, clear

// merge leave out scores
merge 1:1 merge_id_k12_test_scores using ///
  `k12_test_scores'/k12_lag_test_scores_clean.dta, nogen keep(1 3) ///
  keepusing(L4_cst_ela_z_score L5_cst_ela_z_score) update
// create a leave out score variable
gen loscore =.
replace loscore = L4_cst_ela_z_score if year == 2015 | year == 2016
replace loscore = L5_cst_ela_z_score if year == 2017 | year == 2018
// dummy for missing prior leave out scores
gen byte mi_loscore = (mi(loscore))

// merge sibling controls
merge m:1 state_student_id using `sibling_out_xwalk', nogen keep(1 3)

// dummy for missing sibling controls
gen byte mi_sib = (mi(has_older_sibling_enr_2year) | mi(has_older_sibling_enr_4year))
replace mi_sib=1 if sibling_out_sample==0

tempfile va_sample
save `va_sample'

// merge ACS sample to use the census control sample indicator
// first, load ACS sample and keep only one observation per student
use $vaprojdir/data/va_samples_v1/score_a.dta, clear
duplicates drop state_student_id, force
tempfile va_acs
save `va_acs'

use `va_sample', clear
merge m:1 state_student_id using `va_acs', nogen keepusing(census_controls_sample)
// dummy for missing ACS controls
gen byte mi_acs = 0
replace mi_acs = 1 if census_controls_sample!=1



//------------------------------------------------------------------------------
// estimate the sample counts and save estimate files
//------------------------------------------------------------------------------

foreach subject in ela math {

  //--------------------------------------------------------
  // sample counts
  //--------------------------------------------------------

  // line 1: all students
  estpost tabstat count_var ///
    if grade==11 ///
    & all_students_sample==1 ///
    , stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_all_g11_`subject'.ster, replace

  tab year ///
  	if grade==11 ///
  	& all_students_sample==1

  // line 2: traditional 9-12 schools filtered by diff_school_prop
  estpost tabstat ///
  	count_var ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& all_students_sample==1 ///
  	, stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_if_school_level_g11_`subject'.ster, replace


  tab year ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& all_students_sample==1


  // line 3: first scores sample
  estpost tabstat ///
  	count_var ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	, stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_first_scores_g11_`subject'.ster, replace

  tab year ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1

  // line 4: conventional school
  estpost tabstat ///
  	count_var ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	, stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_conventional_school_g11_`subject'.ster, replace

  tab year ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1

  // line 5: 11th grader per school > 10
  estpost tabstat ///
  	count_var ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	, stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_cohort_size_g11_`subject'.ster, replace

  tab year ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size))

  // line 6: nonmissing subject test score
  estpost tabstat ///
  	count_var ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	, stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_cst_z_score_g11_`subject'.ster, replace

  tab year ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0

  // line 7: nonmissing demographic controls
  estpost tabstat ///
  	count_var ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	, stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_demographic_controls_g11_`subject'.ster, replace

  tab year ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0


  // line 8: nonmissing prior test scores
  estpost tabstat ///
  	count_var ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0 ///
  	, stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_prior_cst_z_score_g11_`subject'.ster, replace

  tab year ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0

  // line 9: school VA sample size >= 7
  /* note: after restricting samples further there will be schools size < 7 */
  estpost tabstat ///
  	count_var ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0 ///
  	& mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
  	& (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
  	, stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_valid_cohort_size_g11_`subject'.ster, replace

  tab year ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0 ///
  	& mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
  	& (n_g11_`subject'>=7 & !mi(n_g11_`subject'))

  // line 10: leave out score sample
  estpost tabstat ///
    count_var ///
    if grade==11 ///
    & (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
    & first_scores_sample==1 ///
    & mi_ssid_grade_year_school==0 ///
    & conventional_school==1 ///
    & (cohort_size>10 & !mi(cohort_size)) ///
    & mi_sbac_`subject'_z_score==0 ///
    & mi_demographic_controls==0 ///
    & mi_prior_ela_z_score==0 ///
    & mi_prior_math_z_score==0 ///
    & mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
    & (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
    & mi_loscore==0 ///
    , stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_loscore_g11_`subject'.ster, replace

  tab year ///
    if grade==11 ///
    & (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
    & first_scores_sample==1 ///
    & mi_ssid_grade_year_school==0 ///
    & conventional_school==1 ///
    & (cohort_size>10 & !mi(cohort_size)) ///
    & mi_sbac_`subject'_z_score==0 ///
    & mi_demographic_controls==0 ///
    & mi_prior_ela_z_score==0 ///
    & mi_prior_math_z_score==0 ///
    & mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
    & (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
    & mi_loscore==0

  // line 11: leave out score and sibling sample
  estpost tabstat ///
    count_var ///
    if grade==11 ///
    & (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
    & first_scores_sample==1 ///
    & mi_ssid_grade_year_school==0 ///
    & conventional_school==1 ///
    & (cohort_size>10 & !mi(cohort_size)) ///
    & mi_sbac_`subject'_z_score==0 ///
    & mi_demographic_controls==0 ///
    & mi_prior_ela_z_score==0 ///
    & mi_prior_math_z_score==0 ///
    & mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
    & (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
    & mi_loscore==0 ///
    & mi_sib==0 ///
    , stat(n) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_loscore_sib_g11_`subject'.ster, replace


  tab year ///
    if grade==11 ///
    & (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
    & first_scores_sample==1 ///
    & mi_ssid_grade_year_school==0 ///
    & conventional_school==1 ///
    & (cohort_size>10 & !mi(cohort_size)) ///
    & mi_sbac_`subject'_z_score==0 ///
    & mi_demographic_controls==0 ///
    & mi_prior_ela_z_score==0 ///
    & mi_prior_math_z_score==0 ///
    & mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
    & (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
    & mi_loscore==0 ///
    & mi_sib==0

    // line 12: leave out score and sibling and ACS sample
    estpost tabstat ///
      count_var ///
      if grade==11 ///
      & (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
      & first_scores_sample==1 ///
      & mi_ssid_grade_year_school==0 ///
      & conventional_school==1 ///
      & (cohort_size>10 & !mi(cohort_size)) ///
      & mi_sbac_`subject'_z_score==0 ///
      & mi_demographic_controls==0 ///
      & mi_prior_ela_z_score==0 ///
      & mi_prior_math_z_score==0 ///
      & mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
      & (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
      & mi_loscore==0 ///
      & mi_sib==0 ///
      & mi_acs==0 ///
      , stat(n) columns(statistics)
    estimates save $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_loscore_sib_acs_g11_`subject'.ster, replace


    tab year ///
      if grade==11 ///
      & (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
      & first_scores_sample==1 ///
      & mi_ssid_grade_year_school==0 ///
      & conventional_school==1 ///
      & (cohort_size>10 & !mi(cohort_size)) ///
      & mi_sbac_`subject'_z_score==0 ///
      & mi_demographic_controls==0 ///
      & mi_prior_ela_z_score==0 ///
      & mi_prior_math_z_score==0 ///
      & mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
      & (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
      & mi_loscore==0 ///
      & mi_sib==0 ///
      & mi_acs==0

  //--------------------------------------------------------
  // z scores
  //--------------------------------------------------------
  // line 1: all students
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& all_students_sample==1 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_all_g11_`subject'.ster, replace


  // line 2: traditional 9-12 schools filtered by diff_school_prop
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& all_students_sample==1 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_if_school_level_g11_`subject'.ster, replace

  // line 3: first scores sample
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_first_scores_g11_`subject'.ster, replace

  // line 4: conventional schools
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_conventional_school_g11_`subject'.ster, replace


  // line 5: 11th grader per school >10
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_cohort_size_g11_`subject'.ster, replace


  // line 6: nonmissing subject test score
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_cst_z_score_g11_`subject'.ster, replace

  // line 7: nonmissing demographic controls
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_demographic_controls_g11_`subject'.ster, replace

  // line 8: nonmissing prior test scores
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_prior_cst_z_score_g11_`subject'.ster, replace


  // line 9: school va sample size >= 7
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0 ///
  	& mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
  	& (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_valid_cohort_size_g11_`subject'.ster, replace


  // line 10: leave out scores sample
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0 ///
  	& mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
  	& (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
    & mi_loscore==0 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_loscore_g11_`subject'.ster, replace


  // line 11: leave out scores + sibling sample
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0 ///
  	& mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
  	& (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
    & mi_loscore==0 ///
    & mi_sib==0 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_loscore_sib_g11_`subject'.ster, replace

  // line 12: leave out scores + sibling + ACS sample
  estpost tabstat ///
  	sbac_`subject'_z_score ///
  	if grade==11 ///
  	& (diff_school_prop>=0.95 & !mi(diff_school_prop)) ///
  	& first_scores_sample==1 ///
  	& mi_ssid_grade_year_school==0 ///
  	& conventional_school==1 ///
  	& (cohort_size>10 & !mi(cohort_size)) ///
  	& mi_sbac_`subject'_z_score==0 ///
  	& mi_demographic_controls==0 ///
  	& mi_prior_ela_z_score==0 ///
  	& mi_prior_math_z_score==0 ///
  	& mi_peer_demographic_controls==0 & mi_peer_prior_ela_z_score==0 & mi_peer_prior_math_z_score==0 ///
  	& (n_g11_`subject'>=7 & !mi(n_g11_`subject')) ///
    & mi_loscore==0 ///
    & mi_sib==0 ///
    & mi_acs==0 ///
  	, stat(mean sd) columns(statistics)
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_loscore_sib_acs_g11_`subject'.ster, replace

}





//------------------------------------------------------------------------------
// create the sample counts table
//------------------------------------------------------------------------------

local save_option "replace"

foreach sample in all if_school_level first_scores ///
	conventional_school cohort_size ///
	cst_z_score demographic_controls prior_cst_z_score ///
	valid_cohort_size ///
  loscore loscore_sib loscore_sib_acs {
    di "Sample = `sample'"
    foreach subject in ela math {
      di "Subject = `subject'"

      estimates use $estimates_dir/va_cfr_all_v1/sum_stats/counts_k12_`sample'_g11_`subject'.ster
      eststo g11_`subject'_count
      matrix mat_count_`subject' = e(count)
      estadd matrix mat_stat = mat_count_`subject'

      estimates use $estimates_dir/va_cfr_all_v1/sum_stats/z_score_k12_`sample'_g11_`subject'.ster
      eststo g11_`subject'_z_score
  		matrix mat_z_score_`subject' = e(mean)
      estadd matrix mat_stat = mat_z_score_`subject'

    }


    local label_all "All Students"
    local label_if_school_level "+ 9-12 School"
    local label_all_scores "+ Nonmissing Test Score"
    local label_first_scores "+ First Test Score for Grade"
    local label_ssid_grade_year_school "+ Nonmissing Student ID, Grade, Year, and School"
    local label_conventional_school "+ Conventional School"
    local label_cohort_size "+ 11th Graders per School $ > $ 10"
    local label_cst_z_score "+ Nonmissing Subject Test Score"
    local label_demographic_controls "+ Nonmissing Demographic Controls"
    local label_prior_cst_z_score "+ Nonmissing Prior Test Scores"
    local label_peer "+ Nonmissing Peer Controls"
    local label_valid_cohort_size "+ School VA Sample Size $ \geq $ 7"
    local label_loscore "+ Leave Out Scores"
    local label_loscore_sib "+ Leave Out Scores and Sibling"
    local label_loscore_sib_acs "+ Leave Out Scores, Sibling, and ACS"


    esttab g11_ela_count g11_ela_z_score g11_math_count g11_math_z_score ///
      using $tables_dir/share/va/pub/counts_k12.tex ///
  		, `save_option' cells(mat_stat(fmt(%12.3gc))) ///
  		compress label interaction(\times) booktabs ///
  		nonotes ///
  		noobs ///
  		nomtitles nonumbers nonotes fragment collabels(none) ///
  		rename(count_var x sbac_ela_z_score x sbac_math_z_score x) ///
  		coeflabel(x "`label_`sample''")
  	eststo clear

    local save_option "append"

  }








local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close sample_counts_tab
translate $logdir/share/sample_counts_tab.smcl $logdir/share/sample_counts_tab.log, replace
