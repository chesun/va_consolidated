/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_staffdemo.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean CDE staff demographic data per year; produces $datadir_clean/cde/staffdemo/staffdemo_<year>_clean.dta (consumed by clean_sch_char via append).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/cde/staffdemo/StaffDemo`fall_year_stub'.txt  (LEGACY raw)
    $consolidated_dir/do/va/helpers/macros_va.doh  (consolidated helper)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/staffdemo/staffdemo_`=`fall_year' + 1'_clean.dta
    $logdir/clean_staffdemo.smcl (via log using)
    $logdir/clean_staffdemo.smcl + $logdir/clean_staffdemo.log

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_staffdemo.do
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
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_elsch.do, clean_enr.do, clean_frpm.do, clean_staffcred.do, clean_staffschoolfte.do, clean_charter.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


version 16.1
cap log close _all
clear all


********************************************************************************
* Description *
/*
This file cleans the CDE staff demographics files. The combined dataset is
unique on districtcode, year, and recid.

Data Location: https://www.cde.ca.gov/ds/ad/staffdemo.asp
*/
********************************************************************************

*****************************************************
* First created by Matthew Naven on Month Day, Year *
* updated by Che Sun Febraury 3, 2022
*****************************************************

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/cde"
cap mkdir "$datadir_clean/cde/staffdemo"

log using "$logdir/clean_staffdemo.smcl", replace text

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
forvalues fall_year = 2014 (1) 2014 {
	di "Fall Year = `fall_year'"

	local fall_year_stub = substr("`fall_year'", 3, 2)

	import delimited $vaprojdir/data/public_access/raw/cde/staffdemo/StaffDemo`fall_year_stub'.txt, delimiter(tab) varnames(1) case(lower) stringcols(1 2 3) encoding("utf-8") clear
	desc, full
	codebook

	label var academicyear "Academic Year"

	label var recid "Record ID"

	label var districtcode "District Code"

	label var countyname "County name"

	label var districtname "District name"

	label var gendercode "Gender"

	label def male 1 "Male" 0 "Female"
	gen male:male = 1 if gendercode=="M"
	replace male = 0 if gendercode=="F"
	replace male = . if mi(gendercode)
	label var male "Male"
	drop gendercode

	label var educationlevel "Staff member's highest educational level (honorary degrees not included)"

	label def education 1 "Doctorate"
	label def education 2 "Master's degree plus 30 or more semester hours", add
	label def education 3 "Master's degree", add
	label def education 4 "Bachelor's degree plus 30 or more semester hours", add
	label def education 5 "Bachelor's degree", add
	label def education 6 "Less than bachelor's degree", add
	label def education 7 "Not reported", add
	label def education 8 "Special", add
	label def education 9 "Fifth year within bachelor's degree", add
	label def education 10 "Fifth year induction", add
	label def education 11 "Fifth year", add
	gen education:education = 1 if educationlevel=="D"
	replace education = 8 if educationlevel=="S"
	replace education = 2 if educationlevel=="V"
	replace education = 3 if educationlevel=="M"
	replace education = 9 if educationlevel=="U"
	replace education = 10 if educationlevel=="Y"
	replace education = 11 if educationlevel=="F"
	replace education = 4 if educationlevel=="C"
	replace education = 5 if educationlevel=="B"
	replace education = 6 if educationlevel=="A"
	replace education = 7 if educationlevel=="N"
	replace education = . if mi(educationlevel)

	label def ethnicity 0 "Not Reported"
	label def ethnicity 1 "American Indian or Alaska Native, not Hispanic", add
	label def ethnicity 2 "Asian, not Hispanic", add
	label def ethnicity 3 "Pacific Islander, not Hispanic", add
	label def ethnicity 4 "Filipino, not Hispanic", add
	label def ethnicity 5 "Hispanic or Latino", add
	label def ethnicity 6 "African American, not Hispanic", add
	label def ethnicity 7 "White, not Hispanic", add
	label def ethnicity 9 "Two or More Races, not Hispanic", add
	rename ethnicgroup ethnicity
	label val ethnicity ethnicity
	label var ethnicity "Staff member's racial/ethnic designation"

	label def race 1 "American Indian or Alaska Native"
	label def race 2 "Asian", add
	label def race 5 "Hispanic or Latino", add
	label def race 6 "Black or African American", add
	label def race 7 "White", add
	label def race 8 "Two or More Races", add
	gen race:race = 1 if ethnicity==1
	replace race = 2 if inlist(ethnicity, 2, 3, 4)
	replace race = 5 if ethnicity==5
	replace race = 6 if ethnicity==6
	replace race = 7 if ethnicity==7
	replace race = 8 if ethnicity==9
	label var race "Race"

	/*gen eth_american_indian = (race==1)
	replace eth_american_indian = . if mi(race)
	label var eth_american_indian "American Indian or Alaska Native"

	gen eth_asian = (race==2)
	replace eth_asian = . if mi(race)
	label var eth_asian "Asian"

	gen eth_hispanic = (race==5)
	replace eth_hispanic = . if mi(race)
	label var eth_hispanic "Hispanic or Latino"

	gen eth_black = (race==6)
	replace eth_black = . if mi(race)
	label var eth_black "Black or African American"

	gen eth_white = (race==7)
	replace eth_white = . if mi(race)
	label var eth_white "White"

	gen eth_biracial = (race==8)
	replace eth_biracial = . if mi(race)
	label var eth_biracial "Two or More Races"

	gen eth_other = inlist(race, 1, 8, .)
	label var eth_other "Other Race"*/

	rename yearsteaching years_teaching
	label var years_teaching "Total years of public and/or private educational service. Includes services in this district, other districts, other states, and countries. Does not include substitute teaching or classified staff service. The first year of service is counted as 1 year."

	rename yearsindistrict years_district
	label var years_district "Total years of service in a certificated position in the district. The first year of service is counted as 1 year."

	label var employmentstatuscode "Indicates whether the teacher's position is tenured, probationary, or long-term substitute or temporary employee"

	label def employment_status 1 "Long term substitute or temporary employee"
	label def employment_status 2 "Probationary", add
	label def employment_status 3 "Tenured", add
	label def employment_status 4 "Other", add
	gen employment_status:employment_status = 1 if employmentstatuscode=="L"
	replace employment_status = 2 if employmentstatuscode=="P"
	replace employment_status = 3 if employmentstatuscode=="T"
	replace employment_status = 4 if employmentstatuscode=="O"
	replace employment_status = . if mi(employmentstatuscode)
	label var employment_status "Employment Status"

	rename fteteaching fte_teach
	label var fte_teach "Full-time equivalent (FTE) teaching duties"

	rename fteadministrative fte_admin
	label var fte_admin "FTE administrative duties"

	rename ftepupilservices fte_pupil
	label var fte_pupil "FTE pupil services duties"

	egen fte = rowtotal(fte_teach fte_admin fte_pupil), missing
	label var fte "Full-Time Equivalent"

	label var filecreated "Date that the file was created"

	gen date_created = date(filecreated, "MDY")
	format date_created %td
	label var date_created "Date that the file was created"
	drop filecreated

	gen year = `fall_year' + 1
	label var year "Year of Spring Semester"

	order districtcode year recid
	sort districtcode year recid
	compress
	label data "California Department of Education Spring `=`fall_year' + 1' Staff Demographics Records"
	save $datadir_clean/cde/staffdemo/staffdemo_`=`fall_year' + 1'_clean.dta, replace
}




forvalues fall_year = 2015 (1) `= `test_score_max_year' - 1' {
	di "Fall Year = `fall_year'"

	local fall_year_stub = substr("`fall_year'", 3, 2)

	import delimited $vaprojdir/data/public_access/raw/cde/staffdemo/StaffDemo`fall_year_stub'.txt, delimiter(tab) varnames(1) case(lower) stringcols(1 2 3) encoding("utf-8") clear
	desc, full
	codebook

	label var academicyear "Academic Year"

	label var recid "Record ID"

	label var districtcode "District Code"

	label var countyname "County name"

	label var districtname "District name"

	label var gendercode "Gender"

	label def male 1 "Male" 0 "Female"
	gen male:male = 1 if gendercode=="M"
	replace male = 0 if gendercode=="F"
	replace male = . if mi(gendercode)
	label var male "Male"
	drop gendercode

	label var age "The age of the staff member on Census Day"

	label var educationlevel "Staff member's highest educational level (honorary degrees not included)"

	label def education 1 "Doctorate"
	label def education 2 "Master's degree plus 30 or more semester hours", add
	label def education 3 "Master's degree", add
	label def education 4 "Bachelor's degree plus 30 or more semester hours", add
	label def education 5 "Bachelor's degree", add
	label def education 6 "Less than bachelor's degree", add
	label def education 7 "Not reported", add
	label def education 8 "Special", add
	label def education 9 "Fifth year within bachelor's degree", add
	label def education 10 "Fifth year induction", add
	label def education 11 "Fifth year", add
	gen education:education = 1 if educationlevel=="D"
	replace education = 8 if educationlevel=="S"
	replace education = 2 if educationlevel=="V"
	replace education = 3 if educationlevel=="M"
	replace education = 9 if educationlevel=="U"
	replace education = 10 if educationlevel=="Y"
	replace education = 11 if educationlevel=="F"
	replace education = 4 if educationlevel=="C"
	replace education = 5 if educationlevel=="B"
	replace education = 6 if educationlevel=="A"
	replace education = 7 if educationlevel=="N"
	replace education = . if mi(educationlevel)

	label def ethnicity 0 "Not Reported"
	label def ethnicity 1 "American Indian or Alaska Native, not Hispanic", add
	label def ethnicity 2 "Asian, not Hispanic", add
	label def ethnicity 3 "Pacific Islander, not Hispanic", add
	label def ethnicity 4 "Filipino, not Hispanic", add
	label def ethnicity 5 "Hispanic or Latino", add
	label def ethnicity 6 "African American, not Hispanic", add
	label def ethnicity 7 "White, not Hispanic", add
	label def ethnicity 9 "Two or More Races, not Hispanic", add
	rename ethnicgroup ethnicity
	label val ethnicity ethnicity
	label var ethnicity "Staff member's racial/ethnic designation"

	label def race 1 "American Indian or Alaska Native"
	label def race 2 "Asian", add
	label def race 5 "Hispanic or Latino", add
	label def race 6 "Black or African American", add
	label def race 7 "White", add
	label def race 8 "Two or More Races", add
	gen race:race = 1 if ethnicity==1
	replace race = 2 if inlist(ethnicity, 2, 3, 4)
	replace race = 5 if ethnicity==5
	replace race = 6 if ethnicity==6
	replace race = 7 if ethnicity==7
	replace race = 8 if ethnicity==9
	label var race "Race"

	gen eth_american_indian = (race==1)
	replace eth_american_indian = . if mi(race)
	label var eth_american_indian "American Indian or Alaska Native"

	gen eth_asian = (race==2)
	replace eth_asian = . if mi(race)
	label var eth_asian "Asian"

	gen eth_hispanic = (race==5)
	replace eth_hispanic = . if mi(race)
	label var eth_hispanic "Hispanic or Latino"

	gen eth_black = (race==6)
	replace eth_black = . if mi(race)
	label var eth_black "Black or African American"

	gen eth_white = (race==7)
	replace eth_white = . if mi(race)
	label var eth_white "White"

	gen eth_biracial = (race==8)
	replace eth_biracial = . if mi(race)
	label var eth_biracial "Two or More Races"

	gen eth_other = inlist(race, 1, 8, .)
	label var eth_other "Other Race"

	rename yearsteaching years_teaching
	label var years_teaching "Total years of public and/or private educational service. Includes services in this district, other districts, other states, and countries. Does not include substitute teaching or classified staff service. The first year of service is counted as 1 year."

	rename yearsindistrict years_district
	label var years_district "Total years of service in a certificated position in the district. The first year of service is counted as 1 year."

	label var employmentstatuscode "Indicates whether the teacher's position is tenured, probationary, or long-term substitute or temporary employee"

	label def employment_status 1 "Long term substitute or temporary employee"
	label def employment_status 2 "Probationary", add
	label def employment_status 3 "Tenured", add
	label def employment_status 4 "Other", add
	gen employment_status:employment_status = 1 if employmentstatuscode=="L"
	replace employment_status = 2 if employmentstatuscode=="P"
	replace employment_status = 3 if employmentstatuscode=="T"
	replace employment_status = 4 if employmentstatuscode=="O"
	replace employment_status = . if mi(employmentstatuscode)
	label var employment_status "Employment Status"

	rename fteteaching fte_teach
	label var fte_teach "Full-time equivalent (FTE) teaching duties"

	rename fteadministrative fte_admin
	label var fte_admin "FTE administrative duties"

	rename ftepupilservices fte_pupil
	label var fte_pupil "FTE pupil services duties"

	label var filecreated "Date that the file was created"

	gen date_created = date(filecreated, "MDY")
	format date_created %td
	label var date_created "Date that the file was created"
	drop filecreated

	gen year = `fall_year' + 1
	label var year "Year of Spring Semester"

	order districtcode year recid
	sort districtcode year recid
	compress
	label data "California Department of Education Spring `=`fall_year' + 1' Staff Demographics Records"
	save $datadir_clean/cde/staffdemo/staffdemo_`=`fall_year' + 1'_clean.dta, replace
}


timer off 1
timer list
log close
translate $logdir/clean_staffdemo.smcl $logdir/clean_staffdemo.log, replace
