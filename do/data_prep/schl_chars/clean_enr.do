/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_enr.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean CDE enrollment by race/sex/total per year; produces $datadir_clean/cde/enr/enr_<year>_clean.dta (consumed by clean_sch_char via append).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/cde/enr/filesenr`fall_year_stub'.asp.txt  (LEGACY raw)
    $consolidated_dir/do/va/helpers/macros_va.doh  (consolidated helper)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/enr/enr_`=`fall_year' + 1'_clean.dta
    $logdir/data_prep/schl_chars/clean_enr.smcl (via log using)
    $logdir/data_prep/schl_chars/clean_enr.smcl + $logdir/data_prep/schl_chars/clean_enr.log

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_enr.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                    -> removed (absolute paths)
      log_files/schl_chars/<x> (relative or absolute)    -> $logdir/<x>  (CANONICAL)
      include do_files/sbac/macros_va.doh              -> include $consolidated_dir/do/va/helpers/macros_va.doh
      $vaprojdir/data/public_access/clean/cde/<x>        -> $datadir_clean/cde/<x>  (CANONICAL chain; absolute form)
      $vaprojdir/data/public_access/clean/nces/<x>       -> $datadir_clean/nces/<x>  (CANONICAL chain; absolute form)
      data/public_access/clean/cde/<x>                   -> $datadir_clean/cde/<x>  (CANONICAL chain; relative form post-cd)
      data/public_access/clean/nces/<x>                  -> $datadir_clean/nces/<x>  (CANONICAL chain; relative form post-cd)
      data/sch_char.dta (relative; clean_sch_char only) -> $datadir_clean/sch_char.dta  (CANONICAL master)
      translate log_files/schl_chars/<x> (rel or abs)    -> translate $logdir/<x>  (CANONICAL)
      $vaprojdir/data/public_access/raw/<x>              -> kept LEGACY (raw inputs)
      $vaprojdir/data/restricted_access/clean/<x>        -> kept LEGACY (restricted; out of scope)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag (per Step 7 indexalpha precedent).

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9b
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_elsch.do, clean_frpm.do, clean_staffcred.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_charter.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


version 16.1
cap log close clean_enr
clear all

********************************************************************************
* Description *
/*
This do file cleans the Census Day Enrollment by School.

Data Location: https://www.cde.ca.gov/ds/ad/filesenr.asp
*/
********************************************************************************


*****************************************************
* First created by Matthew Naven on Month Day, Year *
* updated by Che Sun Febraury 3, 2022
*****************************************************

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/schl_chars"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/cde"
cap mkdir "$datadir_clean/cde/enr"

log using "$logdir/data_prep/schl_chars/clean_enr.smcl", replace text name(clean_enr)

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
forvalues fall_year = `= `test_score_min_year' - 1' (1) `= `test_score_max_year' - 1' {
	di "Fall Year = `fall_year'"

	local fall_year_stub = substr("`fall_year'", 3, 2)

	import delimited $vaprojdir/data/public_access/raw/cde/enr/filesenr`fall_year_stub'.asp.txt, delimiter(tab) varnames(1) stringcols(1) encoding(ISO-8859-1) clear
	desc, full
	codebook

	rename cds_code cdscode
	label var cdscode "CDS Code"
	label var county "County"
	label var district "District"
	label var school "School"

	rename ethnic ethnicity
	label def ethnicity 0 "Not reported"
	label def ethnicity 1 "American Indian or Alaska Native, Not Hispanic", add
	label def ethnicity 2 "Asian, Not Hispanic", add
	label def ethnicity 3 "Pacific Islander, Not Hispanic", add
	label def ethnicity 4 "Filipino, Not Hispanic", add
	label def ethnicity 5 "Hispanic or Latino", add
	label def ethnicity 6 "African American, not Hispanic", add
	label def ethnicity 7 "White, not Hispanic", add
	label def ethnicity 9 "Two or More Races, Not Hispanic", add
	label val ethnicity ethnicity
	label var ethnicity "Racial/ethnic designation"

	label def race 1 "American Indian or Alaska Native"
	label def race 2 "Asian", add
	label def race 5 "Hispanic or Latino", add
	label def race 6 "Black or African American", add
	label def race 7 "White", add
	label def race 8 "Two or More Races", add
	//gen varname:lblname = []
	gen race:race = 1 if ethnicity==1
	replace race = 2 if inlist(ethnicity, 2, 3, 4)
	replace race = 5 if ethnicity==5
	replace race = 6 if ethnicity==6
	replace race = 7 if ethnicity==7
	replace race = 8 if ethnicity==9
	label var race "Race"

	label def male 1 "Male" 0 "Female"
	gen male:male = 1 if gender=="M"
	replace male = 0 if gender=="F"
	replace male = . if mi(gender)
	label var male "Male"
	drop gender

	label var kdgn "Students enrolled in kindergarten"

	label var gr_1 "Students enrolled in grade one"

	label var gr_2 "Students enrolled in grade two"

	label var gr_3 "Students enrolled in grade three"

	label var gr_4 "Students enrolled in grade four"

	label var gr_5 "Students enrolled in grade five"

	label var gr_6 "Students enrolled in grade six"

	label var gr_7 "Students enrolled in grade seven"

	label var gr_8 "Students enrolled in grade eight"

	label var ungr_elm "Students enrolled in ungraded elementary classes in grades kindergarten through eight"

	label var gr_9 "Students enrolled in grade nine"

	label var gr_10 "Students enrolled in grade ten"

	label var gr_11 "Students enrolled in grade eleven"

	label var gr_12 "Students enrolled in grade twelve"

	label var ungr_sec "Students enrolled in ungraded secondary classes in grades nine through twelve"

	label var enr_total "Total school enrollment for fields Kindergarten (KDGN) through grade twelve (GR_12) plus ungraded elementary (UNGR_ELM) and ungraded secondary classes (UNGR_SEC). Adults in kindergarten through grade twelve programs are not included."

	label var adult "Adults enrolled in kindergarten through grade twelve programs. This data does not include adult education students."

	gen year = `fall_year' + 1
	label var year "Year of Spring Semester"

	order cdscode year county district school ethnicity race male
	sort cdscode year county district school ethnicity race male
	compress
	label data "California Department of Education Spring `=`fall_year' + 1' School Enrollment"
	save $datadir_clean/cde/enr/enr_`=`fall_year' + 1'_clean.dta, replace
}


timer off 1
timer list
cap log close clean_enr
translate $logdir/data_prep/schl_chars/clean_enr.smcl $logdir/data_prep/schl_chars/clean_enr.log, replace
