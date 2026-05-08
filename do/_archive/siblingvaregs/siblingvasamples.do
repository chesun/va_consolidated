********************************************************************************
/* create the VA samples markers with sibling outcomes merged on to make it easier
to create sample sum stats.
Using doh helpher files each time to recreate the data takes too much time
 */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on Sep 22, 2021 ***************************

/* to run this do file:
do $projdir/do/share/siblingvaregs/siblingvasamples.do
*/

clear all
set more off
set varabbrev off

cap log close _all



cd $vaprojdir

//starting log file
log using $projdir/log/share/siblingvaregs/siblingvasamples.smcl, replace

/* file path macros  */
include $projdir/do/share/siblingvaregs/vafilemacros.doh

//set a timer for this do file to see how long it runs
timer on 1


********************************************************************************
/* This first block of code is directly taken from Matt's touse_Va.do */

**********
* Macros *
**********
//run the do helper file to set the local macros
include `vaprojdofiles'/sbac/macros_va.doh

#delimit ;

#delimit cr
macro list


timer on 1
*****************
* Begin Do File *
*****************
**************** Create VA Dataset
use merge_id_k12_test_scores all_students_sample first_scores_sample ///
	dataset test cdscode school_id state_student_id year grade ///
	cohort_size ///
	sbac_ela_z_score sbac_math_z_score ///
	`va_control_vars' ///
	using `k12_test_scores'/k12_test_scores_clean.dta, clear
mark touse

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

* Merge to school grade spans
merge m:1 cdscode year using `k12_test_scores_public'/k12_diff_school_prop_schyr.dta ///
	, gen(merge_grade_span) keepusing(gr11_*_diff_school_prop) keep(1 3)

* Merge to median cohort sizes
merge m:1 cdscode using `k12_test_scores_public'/k12_cohort_size_sch.dta ///
	, gen(merge_cohort_size) keepusing(med_cohort_size_first_scores) keep(1 3)

* Keep conventional schools
merge m:1 cdscode using `k12_public_schools'/k12_public_schools_clean.dta ///
	, gen(merge_public_schools) keepusing(conventional_school) keep(1 3)
replace touse = 0 if conventional_school!=1

* Exclude schools where more than 25 percent of students are receiving special education services

* Drop if a student is receiving instruction at home, in a hospital, or in a school serving disabled students solely

* Drop if 10 or fewer students per school
replace touse = 0 if cohort_size<=10




******** Postsecondary Outcomes
do $vaprojdir/do_files/merge_k12_postsecondary.doh enr_only
drop enr enr_2year enr_4year
rename enr_ontime enr
rename enr_ontime_2year enr_2year
rename enr_ontime_4year enr_4year











******************************** 11th Grade (8th Grade ELA Controls, 6th Grade Math Controls)
gen diff_school_prop = gr11_L3_diff_school_prop if year!=2017
replace diff_school_prop = gr11_L4_diff_school_prop if year==2017

**************** Prior Scores
******** ELA
gen prior_ela_z_score = L3_cst_ela_z_score if inrange(year, `star_min_year' + 3, `star_max_year' + 3) & year!=2017
replace prior_ela_z_score = L3_sbac_ela_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3) & year!=2017
replace prior_ela_z_score = L4_cst_ela_z_score if year==2017
label var prior_ela_z_score "Prior ELA Z-Score"
gen peer_prior_ela_z_score = peer_L3_cst_ela_z_score if inrange(year, `star_min_year' + 3, `star_max_year' + 3) & year!=2017
replace peer_prior_ela_z_score = peer_L3_sbac_ela_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3) & year!=2017
replace peer_prior_ela_z_score = peer_L4_cst_ela_z_score if year==2017
label var peer_prior_ela_z_score "Peer Avg. Prior ELA Z-Score"

******** Math
gen prior_math_z_score = L5_cst_math_z_score if inrange(year, `star_min_year' + 5, `star_max_year' + 5) & !inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
replace prior_math_z_score = L3_sbac_math_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
label var prior_math_z_score "Prior Math Z-Score"
gen peer_prior_math_z_score = peer_L5_cst_math_z_score if inrange(year, `star_min_year' + 5, `star_max_year' + 5) & !inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
replace peer_prior_math_z_score = peer_L3_sbac_math_z_score if inrange(year, `caaspp_min_year' + 3, `caaspp_max_year' + 3)
label var peer_prior_math_z_score "Peer Avg. Prior Math Z-Score"

**** Test Score Sample
foreach subject in ela math {
	mark touse_g11_`subject' ///
		if grade==11 & dataset=="CAASPP" & inrange(year, `test_score_min_year', `test_score_max_year') ///
		& diff_school_prop>=0.95
	markout touse_g11_`subject' ///
		sbac_`subject'_z_score ///
		school_id i.year ///
		`school_controls' ///
		`demographic_controls' ///
		`ela_score_controls' ///
		`math_score_controls' ///
		`peer_demographic_controls' ///
		`peer_ela_score_controls' ///
		`peer_math_score_controls'

	replace touse_g11_`subject' = 0 if touse==0

	egen n_g11_`subject' = count(state_student_id) ///
		if touse_g11_`subject'==1 ///
		, by(cdscode year)
	replace touse_g11_`subject' = 0 if n_g11_`subject'<7
}

**** Postsecondary Outcomes Sample
foreach outcome in enr enr_2year enr_4year {
	mark touse_g11_`outcome' ///
		if grade==11 & dataset=="CAASPP" & inrange(year, `outcome_min_year', `outcome_max_year') ///
		& diff_school_prop>=0.95
	markout touse_g11_`outcome' ///
		`outcome' ///
		school_id i.year ///
		`school_controls' ///
		`demographic_controls' ///
		`ela_score_controls' ///
		`math_score_controls' ///
		`peer_demographic_controls' ///
		`peer_ela_score_controls' ///
		`peer_math_score_controls'

	replace touse_g11_`outcome' = 0 if touse==0

	egen n_g11_`outcome' = count(state_student_id) ///
		if touse_g11_`outcome'==1 ///
		, by(cdscode year)
	replace touse_g11_`outcome' = 0 if n_g11_`outcome'<7
}


********************************************************************************
/* Merge onto sibling outcomes xwalk  */

merge m:1 state_student_id using `sibling_out_xwalk'

keep state_student_id merge_id_k12_test_scores touse* sibling_out_sample sibling_full_sample

compress
save $projdir/dta/common_core_va/va_sibling_samples, replace

cd $projdir

timer off 1
timer list
log close

//translate the log file to a text log file
translate $projdir/log/share/siblingvaregs/siblingvasamples.smcl $projdir/log/share/siblingvaregs/siblingvasamples.log, replace
