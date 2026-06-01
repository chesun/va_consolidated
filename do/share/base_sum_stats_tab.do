/*------------------------------------------------------------------------------
do/share/base_sum_stats_tab.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    base sample summary statistics table for paper.  Paper producer (figures + tables) for the VA paper.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Reads CHAIN VA outputs from $estimates_dir/va_cfr_all_<version>/<x>
    (Step 3 batches 3a-3d) + sample data from LEGACY $vaprojdir/data/
    va_samples_v1/<x> (sample data not yet relocated; out of Step 10 scope).
    Writes paper-shipping outputs to $tables_dir/share/<x> + $figures_dir/share/<x>
    (CANONICAL).

INPUTS (verified via grep on file body)
    $consolidated_dir/do/samples/create_diff_school_prop.doh  (helper include)
    $consolidated_dir/do/samples/create_prior_scores_v1.doh  (helper include)
    $consolidated_dir/do/samples/create_va_g11_out_sample_v1.doh  (helper include)
    $consolidated_dir/do/samples/merge_loscore.doh  (helper include)
    $consolidated_dir/do/samples/merge_sib.doh  (helper include)
    $consolidated_dir/do/va/helpers/drift_limit.doh  (helper include)
    $consolidated_dir/do/va/helpers/macros_va.doh  (helper include)
    $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela.ster  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_all.ster  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college.ster  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_all.ster  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_dropped.ster  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_las.ster  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_dropped.ster  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_las.ster  (CHAIN read)
    ... +8 more (see body grep)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/base_sum_stats_tab.smcl (via log using)
    $logdir/share/base_sum_stats_tab.smcl + $logdir/share/base_sum_stats_tab.log (translate)
    $tables_dir/share/va/pub/sum_stats_college.tex
    $tables_dir/share/va/pub/sum_stats_g11.tex
    $vaprojdir/data/va_samples_v1/base_nodrop.dta

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/base_sum_stats_tab.do
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
    Sister files (this batch): kdensity.do, reg_out_va_tab.do, sample_counts_tab.do, svyindex_tab.do, va_scatter.do, va_spec_fb_tab_all.do, va_var_explain.do, va_var_explain_tab.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* summary statistics table for base socre and enrollment samples */
********************************************************************************

*****************************************************
* First created by Christina Sun February 20, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/base_sum_stats_tab.do
 */

/* CHANGE LOG:
06/14/2023: added code to calculate sum stats for combined sample, and kitchen
sink sample; removed sd and excluded sample from table
0719/2023: keep only 2 year and 4 year in postsecondary sum stats
 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
cap log close base_sum_stats_tab

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
cap mkdir "$tables_dir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/share"
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
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/va_cfr_all_v1"
cap mkdir "$estimates_dir/va_cfr_all_v1/sum_stats"

log using "$logdir/share/base_sum_stats_tab.smcl", replace text name(base_sum_stats_tab)

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




  /* what sample to start from for sum stats?
  do all the merges without keeping/dropping specific observations so that
  we can calculate how many students we’re losing*/

local create_sample = 0
if `create_sample'==1 {
  //------------------------------------------------------------------------------
  // create VA sample without dropping observations
  //------------------------------------------------------------------------------
    **************** Create VA Dataset
    use merge_id_k12_test_scores all_students_sample all_scores_sample first_scores_sample ///
    	dataset test cdscode school_id state_student_id year grade ///
    	cohort_size ///
    	sbac_ela_z_score sbac_math_z_score ///
    	`va_control_vars' eth_white ///
    	/*if substr(cdscode, 1, 7)=="3768338"*/ ///
    	using `k12_test_scores'/k12_test_scores_clean.dta, clear
    merge 1:1 merge_id_k12_test_scores using data/sbac/va_samples.dta ///
    	, nogen keepusing(touse_*)

    replace age = age / 365
    label var age "Age in Years"

    * Merge to lagged scores
    merge 1:1 merge_id_k12_test_scores using `k12_test_scores'/k12_lag_test_scores_clean.dta, nogen keep(1 3) ///
    	keepusing( ///
    		L3_cst_ela_z_score ///
    		L3_sbac_ela_z_score ///
    		L4_cst_ela_z_score ///
    		L3_sbac_math_z_score ///
    		L4_sbac_math_z_score ///
    		L5_cst_math_z_score ///
    		L6_cst_math_z_score ///
    	)

    * Merge to peer scores
    merge 1:1 merge_id_k12_test_scores using `k12_test_scores'/k12_peer_test_scores_clean.dta, nogen keep(1 3) ///
    	keepusing( ///
    		`peer_demographic_controls' ///
    		peer_L3_cst_ela_z_score ///
    		peer_L3_sbac_ela_z_score ///
    		peer_L4_cst_ela_z_score ///
    		peer_L3_sbac_math_z_score ///
    		peer_L4_sbac_math_z_score ///
    		peer_L5_cst_math_z_score ///
    		peer_L6_cst_math_z_score ///
    	)

    replace peer_age = peer_age / 365
    label var peer_age "Age in Years Peer Avg."

    count
    sum

    * Merge to school grade spans
    merge m:1 cdscode year using `k12_test_scores_public'/k12_diff_school_prop_schyr.dta ///
    	, gen(merge_grade_span) keepusing(gr11_*_diff_school_prop) keep(1 3)

    * Merge to median cohort sizes
    merge m:1 cdscode using `k12_test_scores_public'/k12_cohort_size_sch.dta ///
    	, gen(merge_cohort_size) keepusing(med_cohort_size_first_scores) keep(1 3)

    * Keep conventional schools
    merge m:1 cdscode using `k12_public_schools'/k12_public_schools_clean.dta ///
    	, gen(merge_public_schools) keepusing(conventional_school) keep(1 3)
    /*keep if conventional_school==1*/

    count
    tab year
    tab grade year if dataset=="CAASPP"
    sum




    ******** Postsecondary Outcomes
    do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only




    count
    tab year
    tab grade year if dataset=="CAASPP"
    sum


    * Save temporary dataset
    count
    tab year
    tab grade year if dataset=="CAASPP"
    sum
    compress
    tempfile va_dataset
    save `va_dataset'



    ******************************** 11th Grade (8th Grade ELA Controls, 6th Grade Math Controls)
    use if grade==11 & dataset=="CAASPP" & inrange(year, `test_score_min_year', `test_score_max_year') using `va_dataset', clear

    include $consolidated_dir/do/samples/create_diff_school_prop.doh
    /*keep if diff_school_prop>=0.95*/

    count
    tab year
    tab grade year
    sum

    include $consolidated_dir/do/samples/create_prior_scores_v1.doh

    **************** Sample
    gen byte count_var = 1
    gen mi_ssid_grade_year_school = (mi(state_student_id, grade, year, cdscode))
    gen byte mi_sbac_ela_z_score = (mi(sbac_ela_z_score))
    gen byte mi_sbac_math_z_score = (mi(sbac_math_z_score))
    gen byte mi_enr_ontime = (mi(enr_ontime))
    gen byte mi_enr_ontime_2year = (mi(enr_ontime_2year))
    gen byte mi_enr_ontime_4year = (mi(enr_ontime_4year))
    gen byte mi_demographic_controls = (mi(cohort_size, age, male, eth_hispanic, eth_asian, eth_black, eth_other, econ_disadvantage, limited_eng_prof, disabled))
    gen byte mi_prior_ela_z_score = (mi(prior_ela_z_score))
    gen byte mi_prior_math_z_score = (mi(prior_math_z_score))
    gen byte mi_peer_demographic_controls = (mi(peer_age, peer_male, peer_eth_hispanic, peer_eth_asian, peer_eth_black, peer_eth_other, peer_econ_disadvantage, peer_limited_eng_prof, peer_disabled))
    gen byte mi_peer_prior_ela_z_score = (mi(peer_prior_ela_z_score))
    gen byte mi_peer_prior_math_z_score = (mi(peer_prior_math_z_score))
    egen n_g11_ela = count(state_student_id) ///
    	if touse_g11_ela==1 ///
    	, by(cdscode year)
    egen n_g11_math = count(state_student_id) ///
    	if touse_g11_math==1 ///
    	, by(cdscode year)



  save $datadir_clean/share/base_nodrop.dta, replace  // CANONICAL local cache (was $vaprojdir/data/va_samples_v1/; repointed per ADR-0021 sandbox)

}

if `create_sample'==0 {
  use $datadir_clean/share/base_nodrop.dta, clear  // CANONICAL chain — paired with cached save above
}


//------------------------------------------------------------------------------
// base sample summary statistics z scores: mean and sd
/* Panel A contains the sample used to estimate ELA test score value added with
 the exception of \math z-score", which comes from the math test score value
added sample. Panel B contains the subset of panel A students who could be linked to the NSC data */
//------------------------------------------------------------------------------


// ELA summary stats
// VA sample
estpost sum ///
  cohort_size ///
  `va_control_vars' eth_white ///
  sbac_ela_z_score ///
  prior_ela_z_score prior_math_z_score ///
  `peer_demographic_controls' ///
  peer_prior_ela_z_score peer_prior_math_z_score ///
  if touse_g11_ela==1
  estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela.ster, replace


tab year ///
	if touse_g11_ela==1

**** Dropped from VA Sample
estpost sum ///
	cohort_size ///
	`va_control_vars' eth_white ///
	sbac_ela_z_score ///
	prior_ela_z_score prior_math_z_score ///
	`peer_demographic_controls' ///
	peer_prior_ela_z_score peer_prior_math_z_score ///
	if touse_g11_ela==0 & grade==11 & all_students_sample==1
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_dropped.ster, replace

tab year ///
	if touse_g11_ela==0 & grade==11 & all_students_sample==1

***** Overall sample: combined VA and excluded
estpost sum ///
  cohort_size ///
  `va_control_vars' eth_white ///
  sbac_ela_z_score ///
  prior_ela_z_score prior_math_z_score ///
  `peer_demographic_controls' ///
  peer_prior_ela_z_score peer_prior_math_z_score ///
  if touse_g11_ela==1 | (touse_g11_ela==0 & grade==11 & all_students_sample==1)
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_all.ster, replace

// Math sum stats
**** VA Sample
estpost sum ///
	cohort_size ///
	`va_control_vars' eth_white ///
	sbac_math_z_score ///
	prior_ela_z_score prior_math_z_score ///
	`peer_demographic_controls' ///
	peer_prior_ela_z_score peer_prior_math_z_score ///
	if touse_g11_math==1
estimates save  $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_math.ster, replace

tab year ///
	if touse_g11_math==1


**** Dropped from VA Sample
estpost sum ///
	cohort_size ///
	`va_control_vars' eth_white ///
	sbac_math_z_score ///
	prior_ela_z_score prior_math_z_score ///
	`peer_demographic_controls' ///
	peer_prior_ela_z_score peer_prior_math_z_score ///
	if touse_g11_math==0 & grade==11 & all_students_sample==1
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_math_dropped.ster, replace

tab year ///
	if touse_g11_math==0 & grade==11 & all_students_sample==1


***** combined sample: VA and excluded
estpost sum ///
	cohort_size ///
	`va_control_vars' eth_white ///
	sbac_math_z_score ///
	prior_ela_z_score prior_math_z_score ///
	`peer_demographic_controls' ///
	peer_prior_ela_z_score peer_prior_math_z_score ///
	if touse_g11_math==1 | (touse_g11_math==0 & grade==11 & all_students_sample==1)
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_math_all.ster, replace





//------------------
// Enrollment sum stats for observations in ELA sample that could be linked to NSC
estpost sum ///
	enr_ontime_2year enr_ontime_4year ///
	if touse_g11_ela==1
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college.ster, replace

**** Dropped from VA Sample
estpost sum ///
	enr_ontime_2year enr_ontime_4year ///
	if touse_g11_ela==0 & grade==11 & all_students_sample==1
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_dropped.ster, replace

// overall sample: combined VA and excluded
estpost sum ///
	enr_ontime_2year enr_ontime_4year ///
	if  touse_g11_ela==1 | (touse_g11_ela==0 & grade==11 & all_students_sample==1)
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_all.ster, replace



//---------------------------------------------------------------------------
// Summary statistics for ktichen sink sample with leave out score, sibling, and
// ACS controls
//---------------------------------------------------------------------------
****** first merge on the controls
use $vaprojdir/data/va_samples_v1/score_las.dta, clear

/* // do helper file to merge leave out scores
include $consolidated_dir/do/samples/merge_loscore.doh

// call do helper file to merge onto ACS controls. Be sure to specify correct arguments. 5 args in total
do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh ///
  test_score ///
  $vaprojdir/data/va_samples_v1/score_b.dta ///
  score_b.dta ///
  create_sample ///
  none

//subroutine that merges on sibling college going controls
include $consolidated_dir/do/samples/merge_sib.doh */

// merge to Postsecondary Outcomes
do do_files/merge_k12_postsecondary.doh enr_only

replace age=age/365

/*
* Save temporary dataset
compress
tempfile va_dataset
save `va_dataset'

include $consolidated_dir/do/samples/create_va_g11_out_sample_v1.doh */

// ELA sum stats
estpost sum ///
  cohort_size ///
  `va_control_vars' eth_white ///
  sbac_ela_z_score ///
  prior_ela_z_score prior_math_z_score ///
  `peer_demographic_controls' ///
  peer_prior_ela_z_score peer_prior_math_z_score ///
  if touse_g11_ela==1
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_las.ster, replace

// Math sum stats
estpost sum ///
	cohort_size ///
	`va_control_vars' eth_white ///
	sbac_math_z_score ///
	prior_ela_z_score prior_math_z_score ///
	`peer_demographic_controls' ///
	peer_prior_ela_z_score peer_prior_math_z_score ///
	if touse_g11_math==1
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_math_las.ster, replace

// Enrollment sum stats for ELA sample that could be linked to postsec outcomes
estpost sum  enr_ontime_2year enr_ontime_4year if touse_g11_ela==1 

	/* enr_ontime /// */
	/* enr_ontime_pub enr_ontime_priv /// */
	/* enr_ontime_instate enr_ontime_outstate /// */
estimates save $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_las.ster, replace


//-----------------------------------------------------------------------
// latex tables for summary statistics
//------------------------------------------------------------------------
//------------------------------------------------------------------------------
// esttab macros
//------------------------------------------------------------------------------


#delimit ;
local esttab_reg
	b(%12.3gc) se(%12.3gc)
	star(* 0.1 ** 0.05 *** 0.01)
	;
local esttab_sum_stats
	/*main(mean %5.3f) aux(sd %4.3f)*/
	brackets
	/*nomtitles nonumbers nonotes*/
	;
local esttab_tab_stat
	cells(mean(fmt(%12.3gc)) count(fmt(%12.3gc) par(\{ \})))
	nomtitles nonumbers nonotes collabels(none)
	;
local esttab_scalars
	scalars(
	"N Observations"
	/*"r2 $ R^2 $"*/
	)
	sfmt(
	%12.3gc
	/*%12.3g*/
	)
	noobs
	;
local esttab_layout
	compress
	label interaction(\times)
	booktabs
	/*replace*/
	;
local esttab_manual
	nolines
	nomtitles nonumbers nonotes
	fragment
	;
local esttab_mgroups
	nomtitles
	mgroups(""
	, pattern()
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	;
local esttab_keep
	keep(

	)
	order(

	)
	;
#delimit cr




//--------------------------------------------------------
// ELA and Math
//--------------------------------------------------------

*** VA sample
estimates use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela.ster
eststo g11_ela

estimates use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_math.ster
eststo g11_math

*** dropped sample
estimates use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_dropped.ster
eststo g11_ela_dropped

estimates use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_math_dropped.ster
eststo g11_math_dropped

***** combined sample of VA and dropped
estimates use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_all.ster
eststo g11_ela_all

estimates use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_math_all.ster
eststo g11_math_all

***** kitchen sink sample with leave out score, ACS, and sibling
estimates use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_las.ster
eststo g11_ela_las

estimates use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_math_las.ster
eststo g11_math_las


esttab g11_ela_all g11_ela g11_ela_las using $tables_dir/share/va/pub/sum_stats_g11.tex ///
  , replace `esttab_sum_stats' main(mean %12.3gc) /*aux(sd %12.3gc)*/ wide noobs `esttab_layout' `esttab_manual' ///
	keep( ///
		cohort_size ///
	) ///
	coeflabel( ///
		cohort_size "11th Graders per School" ///
	) ///


esttab g11_ela_all g11_ela g11_ela_las using $tables_dir/share/va/pub/sum_stats_g11.tex ///
	, append `esttab_sum_stats' main(mean %5.1f) /*aux(sd %4.3f)*/ wide noobs `esttab_layout' `esttab_manual' ///
	keep( ///
		age ///
	) ///
	coeflabel( ///
		age "Age in Years" ///
	)

esttab g11_ela_all g11_ela g11_ela_las using $tables_dir/share/va/pub/sum_stats_g11.tex ///
	, append `esttab_sum_stats' main(mean %5.3f) wide noobs `esttab_layout' `esttab_manual' ///
	keep( ///
		male ///
		eth_hispanic ///
		eth_white ///
		eth_asian ///
		eth_black ///
		eth_other ///
		econ_disadvantage ///
		limited_eng_prof ///
		disabled ///
		 ///
	) ///
	order( ///
		male ///
		eth_hispanic ///
		eth_white ///
		eth_asian ///
		eth_black ///
		eth_other ///
		econ_disadvantage ///
		limited_eng_prof ///
		disabled ///
		 ///
	) ///
	coeflabel( ///
		male "Male" ///
		eth_hispanic "Hispanic or Latino" ///
		eth_white "White" ///
		eth_asian "Asian" ///
		eth_black "Black or African American" ///
		eth_other "Other Race" ///
		econ_disadvantage "Economic Disadvantage" ///
		limited_eng_prof "Limited English Proficiency Status" ///
		disabled "Disabled" ///
	)


esttab g11_ela_all g11_ela g11_ela_las using $tables_dir/share/va/pub/sum_stats_g11.tex ///
	, append `esttab_sum_stats' main(mean %5.3f) /*aux(sd %4.3f)*/ wide noobs `esttab_layout' `esttab_manual' ///
	keep( ///
		sbac_ela_z_score ///
	) ///
	coeflabel( ///
		sbac_ela_z_score "ELA Z-Score" ///
	)

esttab g11_math_all g11_math g11_math_las using $tables_dir/share/va/pub/sum_stats_g11.tex ///
	, append `esttab_sum_stats' main(mean %5.3f) /*aux(sd %4.3f)*/ wide noobs `esttab_layout' `esttab_manual' ///
	keep( ///
		sbac_math_z_score ///
	) ///
	coeflabel( ///
		sbac_math_z_score "Math Z-Score" ///
	)

esttab g11_ela_all g11_ela g11_ela_las using $tables_dir/share/va/pub/sum_stats_g11.tex ///
	, append `esttab_sum_stats' main(mean %5.3f) /*aux(sd %4.3f)*/ wide `esttab_scalars' `esttab_layout' `esttab_manual' prefoot(\midrule) ///
	keep( ///
		prior_ela_z_score ///
		prior_math_z_score ///
	) ///
	coeflabel( ///
		prior_ela_z_score "Prior ELA Z-Score" ///
		prior_math_z_score "Prior Math Z-Score" ///
	)


//--------------------------------------------------------
// postsecondary enrollment
//--------------------------------------------------------
// subset of ELA VA sample
est use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college.ster
eststo g11_ela_college
// dropped sample
est use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_dropped.ster
eststo g11_ela_college_dropped

// overall sample: combined VA and Excluded
est use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_all.ster
eststo g11_ela_college_all

// kitchen sink sample with leave out score, acs, and sibling
est use $estimates_dir/va_cfr_all_v1/sum_stats/sum_stats_g11_ela_college_las.ster
eststo g11_ela_college_las

esttab g11_ela_college_all g11_ela_college g11_ela_college_las using $tables_dir/share/va/pub/sum_stats_college.tex ///
	, replace `esttab_sum_stats' main(mean %5.3f) wide `esttab_scalars' `esttab_layout' `esttab_manual' prefoot(\midrule) ///
	coeflabel( ///
		enr_ontime "Enrolled at a Postsecondary Institution" ///
		enr_ontime_2year "Enrolled at a 2-Year College" ///
		enr_ontime_4year "Enrolled at a 4-Year University" ///
	)
		/* enr_ontime_pub "Enrolled at a Public Institution" ///
		enr_ontime_priv "Enrolled at a Private Institution" ///
		enr_ontime_instate "Enrolled at a CA Institution" ///
		enr_ontime_outstate "Enrolled at an Out-of-State Institution" /// */


local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close base_sum_stats_tab
translate $logdir/share/base_sum_stats_tab.smcl $logdir/share/base_sum_stats_tab.log, replace
