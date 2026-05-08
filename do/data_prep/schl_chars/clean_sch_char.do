/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_sch_char.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    MASTER assembly: merges 6 sister-cleaner tempfiles + 4 chain dtas; produces $datadir_clean/sch_char.dta.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $consolidated_dir/do/va/helpers/macros_va.doh  (consolidated helper)
    $datadir_clean/cde/charter_status.dta  (CHAIN read; from this batch)
    $datadir_clean/cde/ecn_disadv.dta  (CHAIN read; from this batch)
    $datadir_clean/cde/elsch/elsch_`spring_year'_clean.dta  (CHAIN read; from this batch)
    $datadir_clean/cde/enr/enr_`spring_year'_clean.dta  (CHAIN read; from this batch)
    $datadir_clean/cde/frpm/frpm_`spring_year'_clean.dta  (CHAIN read; from this batch)
    $datadir_clean/cde/staffcred/staffcred_`spring_year'_clean.dta  (CHAIN read; from this batch)
    $datadir_clean/cde/staffdemo/staffdemo_`spring_year'_clean.dta  (CHAIN read; from this batch)
    $datadir_clean/cde/staffschoolfte/staffschoolfte_`spring_year'_clean.dta  (CHAIN read; from this batch)
    $datadir_clean/nces/pubschls_locale.dta  (CHAIN read; from this batch)
    `elsch'  (tempfile from sister cleaner)
    `enr_race'  (tempfile from sister cleaner)
    `enr_sex'  (tempfile from sister cleaner)
    `enr_total'  (tempfile from sister cleaner)
    `frpm'  (tempfile from sister cleaner)
    `staffcred'  (tempfile from sister cleaner)
    `staffdemo'  (tempfile from sister cleaner)
    `staffschoolfte'  (tempfile from sister cleaner)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/sch_char.dta
    $logdir/clean_sch_char.smcl (via log using)
    $logdir/clean_sch_char.smcl + $logdir/clean_sch_char.log
    `elsch'  (tempfile)
    `enr_race'  (tempfile)
    `enr_sex'  (tempfile)
    `enr_total'  (tempfile)
    `frpm'  (tempfile)
    `staffcred'  (tempfile)
    `staffdemo'  (tempfile)
    `staffschoolfte'  (tempfile)

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_sch_char.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                    -> removed (absolute paths)
      log_files/schl_chars/* (relative or absolute)    -> $logdir/*  (CANONICAL)
      include do_files/sbac/macros_va.doh              -> include $consolidated_dir/do/va/helpers/macros_va.doh
      $vaprojdir/data/public_access/clean/cde/*        -> $datadir_clean/cde/*  (CANONICAL chain; absolute form)
      $vaprojdir/data/public_access/clean/nces/*       -> $datadir_clean/nces/*  (CANONICAL chain; absolute form)
      data/public_access/clean/cde/*                   -> $datadir_clean/cde/*  (CANONICAL chain; relative form post-cd)
      data/public_access/clean/nces/*                  -> $datadir_clean/nces/*  (CANONICAL chain; relative form post-cd)
      data/sch_char.dta (relative; clean_sch_char only) -> $datadir_clean/sch_char.dta  (CANONICAL master)
      translate log_files/schl_chars/* (rel or abs)    -> translate $logdir/*  (CANONICAL)
      $vaprojdir/data/public_access/raw/*              -> kept LEGACY (raw inputs)
      $vaprojdir/data/restricted_access/clean/*        -> kept LEGACY (restricted; out of scope)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag (per Step 7 indexalpha precedent).

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9b
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_elsch.do, clean_enr.do, clean_frpm.do, clean_staffcred.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_charter.do, clean_ecn_disadv.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


version 16.1
cap log close _all
clear all
********************************************************************************
* Description *

/*
This file cleans the publicly available CDE data to create variables on school
characteristics.

The final dataset combines data from the elsch, enr, frpm, staffcred, staffdemo, and staffschoolfte datasets.
*/
********************************************************************************

*****************************************************
* First created by Matthew Naven on Month Day, Year *
* updated by Che Sun Febraury 3, 2022
*** Notes: 
*****************************************************


/* CHANGE LOG:
Dec 18, 2023: added all enrollment variables to the cleaned dataset
Jan 4, 2024: created var for percent black or hispanic
Jan 17, 2024: added data from all test score years 
 */

/* do file was run Dec 18, 2023 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"

log using "$logdir/clean_sch_char.smcl", replace text


graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
/* Color Order
color p       gs6
color p1      navy
color p2      maroon
color p3      forest_green
color p4      dkorange
color p5      teal
color p6      cranberry
color p7      lavender
color p8      khaki
color p9      sienna
color p10     emidblue
color p11     emerald
color p12     brown
color p13     erose
color p14     gold
color p15     bluishgray
*/
/* Marker Symbol Order
circle             O
diamond            D
triangle           T
square             S
plus               +
X                  X
arrowf             A
arrow              a
pipe               |
V                  V
*/
/* Line Pattern Order
solid
dash
dot
dash_dot
shortdash
shortdash_dot
longdash
longdash_dot
*/
set seed 1984




**********
* Macros *
**********
include $consolidated_dir/do/va/helpers/macros_va.doh

#delimit ;
#delimit cr
macro list


timer on 1
*****************
* Begin Do File *
*****************
**************** Total Enrollment
clear
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	append using $datadir_clean/cde/enr/enr_`spring_year'_clean.dta
}

collapse (sum) enr_total, by(cdscode year)

label var enr_total "Total Enrollment"

compress
tempfile enr_total
save `enr_total'




**************** Enrollment by Race
clear
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	append using $datadir_clean/cde/enr/enr_`spring_year'_clean.dta
}

collapse (sum) enr_total, by(cdscode year race)

drop if mi(race)
reshape wide enr_total, i(cdscode year) j(race)

rename enr_total1 enr_indian
label var enr_indian "American Indian Enrollment"

rename enr_total2 enr_asian
label var enr_asian "Asian Enrollment"

rename enr_total5 enr_hispanic
label var enr_hispanic "Hispanic Enrollment"

rename enr_total6 enr_black
label var enr_black "Black Enrollment"

rename enr_total7 enr_white
label var enr_white "White Enrollment"

rename enr_total8 enr_biracial
label var enr_biracial "Two or More Races Enrollment"

egen enr_black_hisp = rowtotal(enr_black enr_hispanic), missing
label var enr_black_hisp "Black and Hispanic enrollment"

egen enr_other = rowtotal(enr_indian enr_biracial), missing
label var enr_other "Other Race Enrollment"

egen enr_minority = rowtotal(enr_indian enr_hispanic enr_black enr_biracial), missing
label var enr_minority "Minority Enrollment"

egen enr_majority = rowtotal(enr_asian enr_white), missing
label var enr_majority "Majority Enrollment"


merge 1:1 cdscode year using `enr_total', keep(1 3) nogen

gen enr_indian_prop = enr_indian / enr_total
label var enr_indian_prop "Enrollment Proportion American Indian"

gen enr_asian_prop = enr_asian / enr_total
label var enr_asian_prop "Enrollment Proportion Asian"

gen enr_hispanic_prop = enr_hispanic / enr_total
label var enr_hispanic_prop "Enrollment Proportion Hispanic"

gen enr_black_prop = enr_black / enr_total
label var enr_black_prop "Enrollment Proportion Black"

gen enr_white_prop = enr_white / enr_total
label var enr_white_prop "Enrollment Proportion White"

gen enr_biracial_prop = enr_biracial / enr_total
label var enr_biracial_prop "Enrollment Proportion Two or More Races"

gen enr_other_prop = enr_other / enr_total
label var enr_other_prop "Enrollment Proportion Other Race"

gen enr_minority_prop = enr_minority / enr_total
label var enr_minority_prop "Enrollment Proportion Minority"

gen enr_majority_prop = enr_majority / enr_total
label var enr_majority_prop "Enrollment Proportion Majority"

gen enr_black_hisp_prop = enr_black_hisp / enr_total
label var enr_black_hisp_prop "Enrollment Proportion Black/Hispanic"

drop enr_total


compress
tempfile enr_race
save `enr_race'




**************** Enrollment by Sex
clear
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	append using $datadir_clean/cde/enr/enr_`spring_year'_clean.dta
}

collapse (sum) enr_total, by(cdscode year male)

drop if mi(male)
reshape wide enr_total, i(cdscode year) j(male)

rename enr_total0 enr_female
label var enr_female "Female Enrollment"

rename enr_total1 enr_male
label var enr_male "Male Enrollment"


merge 1:1 cdscode year using `enr_total', keep(1 3) nogen

gen enr_female_prop = enr_female / enr_total
label var enr_female_prop "Enrollment Proportion Female"

gen enr_male_prop = enr_male / enr_total
label var enr_male_prop "Enrollment Proportion Male"

drop enr_total


compress
tempfile enr_sex
save `enr_sex'
















**************** Free and Reduced Price Lunch
clear
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	append using $datadir_clean/cde/frpm/frpm_`spring_year'_clean.dta
}

drop if mi(cdscode, year)

duplicates tag cdscode year, gen(dup_tag)
drop if dup_tag!=0
drop dup_tag

compress
tempfile frpm
save `frpm'
















**************** English Language Learners
clear
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	append using $datadir_clean/cde/elsch/elsch_`spring_year'_clean.dta
}

collapse (sum) total_el, by(cdscode year)

merge 1:1 cdscode year using `enr_total', keep(1 3) nogen

gen el_prop = total_el / enr_total

compress
tempfile elsch
save `elsch'
















**************** Staff Demo
clear
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	append using $datadir_clean/cde/staffdemo/staffdemo_`spring_year'_clean.dta
}

**** Ethnicity
gen eth_minority = (inlist(race, 1, 5, 6, 8))
replace eth_minority = . if mi(race)
label var eth_minority "Minority"

**** Experience
gen new_teacher = (inrange(years_teaching, 0, 3))
replace new_teacher = . if mi(years_teaching)


compress
tempfile staffdemo
save `staffdemo'








**************** Staff Credentials
clear
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	append using $datadir_clean/cde/staffcred/staffcred_`spring_year'_clean.dta
}

**** Credential
gen credential_full = 1 if credential==10
replace credential_full = 0 if inlist(credential, 20, 30, 40, 50, 60, 70, 80, 85, 90, 95)

**** Collapse Data
collapse (max) ///
	credential_full = credential_full ///
	, by(year recid)

**** Credential
label var credential_full "Full Credential"


compress
tempfile staffcred
save `staffcred'









**************** Staff School FTE
clear
forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	append using $datadir_clean/cde/staffschoolfte/staffschoolfte_`spring_year'_clean.dta
}


**** Classification
gen classification_teach = (inlist(job_classification, 12, 26, 27))
replace classification_teach = . if mi(classification_teach)

gen fte_teach = fte if classification_teach==1

gen classification_admin = (inlist(job_classification, 10, 25))
replace classification_admin = . if mi(job_classification)

gen fte_admin = fte if classification_admin==1

gen classification_pupil = (job_classification==11)
replace classification_pupil = . if mi(job_classification)

gen fte_pupil = fte if classification_pupil==1


compress
tempfile staffschoolfte
save `staffschoolfte'









**************** Combine and collapse teacher data
use `staffschoolfte'
merge m:1 districtcode year recid using `staffdemo', nogen
merge m:1 year recid using `staffcred', nogen
preserve

******** Staff FTE
restore, preserve

replace fte_teach = fte_teach / 100
replace fte_admin = fte_admin / 100
replace fte_pupil = fte_pupil / 100

**** Collapse Data
collapse (rawsum) ///
	fte_teach = fte_teach ///
	fte_admin = fte_admin ///
	fte_pupil = fte_pupil ///
	, by(cdscode year)

merge 1:1 cdscode year using `enr_total' ///
	, gen(merge_enr_total) keep(1 3)

gen fte_teach_pc = fte_teach / enr_total
label var fte_teach_pc "FTE Teachers per Student"

gen fte_admin_pc = fte_admin / enr_total
label var fte_admin_pc "FTE Admin per Student"

gen fte_pupil_pc = fte_pupil / enr_total
label var fte_pupil_pc "FTE Pupil Services per Student"

drop enr_* merge_*


compress
sort cdscode year
tempfile staffschoolfte
save `staffschoolfte'




******** Teacher Demographics
restore, preserve

* Keep teachers
keep if classification_teach==1

**** Collapse Data
collapse (mean) ///
	male_prop = male ///
	eth_minority_prop = eth_minority ///
	new_teacher_prop = new_teacher ///
	[aw = fte_teach] ///
	, by(cdscode year)

label var male_prop "Proportion Male Teachers"
label var eth_minority_prop "Staff Proportion Minority"
label var new_teacher_prop "Proportion $ \leq $ 3 Years Experience Teachers"


compress
sort cdscode year
tempfile staffdemo
save `staffdemo'




******** Teacher Credentials
restore, preserve

* Keep teachers
keep if classification_teach==1

**** Collapse Data
collapse (mean) ///
	credential_full_prop = credential_full ///
	[aw = fte_teach] ///
	, by(cdscode year)


compress
sort cdscode year
tempfile staffcred
save `staffcred'
















**************** Combine All School Characteristics
use `enr_total', clear
merge 1:1 cdscode year using `enr_race' ///
	, nogen keepusing(*prop)
merge 1:1 cdscode year using `enr_sex' ///
	, nogen keepusing(enr_male_prop)
merge 1:1 cdscode year using `frpm' ///
	, nogen keepusing(frpm_prop)
merge 1:1 cdscode year using `elsch' ///
	, nogen keepusing(el_prop)
merge 1:1 cdscode year using `staffdemo' ///
	, nogen keepusing(*)
merge 1:1 cdscode year using `staffcred' ///
	, nogen keepusing(*)
merge 1:1 cdscode year using `staffschoolfte' ///
	, nogen keepusing(*)
/* merge with charter status */
merge m:1 cdscode using $datadir_clean/cde/charter_status.dta, nogen 
/* merge with proportion of econ disadvantage data */
merge 1:1 cdscode year using $datadir_clean/cde/ecn_disadv.dta, nogen 
/* merge with NCES urban/rural classification data from 2015-16 */
merge m:1 cdscode using $datadir_clean/nces/pubschls_locale.dta, nogen

compress
save $datadir_clean/sch_char.dta, replace
/* create a dataset for school characteristics for each year */
snapshot save

forvalues spring_year = `test_score_min_year' (1) `test_score_max_year' {
	keep if year == `spring_year'
	save data/sch_char_`spring_year'.dta, replace 
	snapshot restore 1
}


timer off 1
timer list
log close
translate $logdir/clean_sch_char.smcl $logdir/clean_sch_char.log, replace
