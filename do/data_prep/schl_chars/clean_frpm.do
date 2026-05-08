/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_frpm.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean CDE Free/Reduced Price Meals school-level data per year; produces $datadir_clean/cde/frpm/frpm_<year>_clean.dta (consumed by clean_sch_char via append).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/cde/frpm/frpm`fall_year_stub'`spring_year_stub'.xls  (LEGACY raw)
    $vaprojdir/data/public_access/raw/cde/frpm/frpm`fall_year_stub'`spring_year_stub'.xlsx  (LEGACY raw)
    $consolidated_dir/do/va/helpers/macros_va.doh  (consolidated helper)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/frpm/frpm_`=`fall_year' + 1'_clean.dta
    $logdir/clean_frpm.smcl (via log using)
    $logdir/clean_frpm.smcl + $logdir/clean_frpm.log

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_frpm.do
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
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_elsch.do, clean_enr.do, clean_staffcred.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_charter.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


version 16.1
cap log close _all
clear all

********************************************************************************
* Description *
/*
This data cleans the Free or Reduced-Price Meal (Student Poverty) Data.

Data Location: https://www.cde.ca.gov/ds/ad/filessp.asp
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
cap mkdir "$datadir_clean/cde/frpm"

log using "$logdir/clean_frpm.smcl", replace text


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

//debug
/* set trace on */


forvalues fall_year = `= `test_score_min_year' - 1' (1) `= `test_score_max_year' - 1' {
	di "Fall Year = `fall_year'"

	local spring_year = `fall_year' + 1
	local fall_year_stub = substr(string(`fall_year'), 3, 2)
	local spring_year_stub = substr(string(`spring_year'), 3, 2)

	//the end of the cell range is optional. Stata will detect automatically if not specified. Different years of these datasets have different end rows.
	// 1718 and 1819 data are .xlsx formats
	if ( `fall_year'==2017 | `fall_year'==2018 ) {
		import excel $vaprojdir/data/public_access/raw/cde/frpm/frpm`fall_year_stub'`spring_year_stub'.xlsx, sheet("FRPM School-Level Data ") cellrange(A2) firstrow case(lower) allstring clear
	}
	else {
		import excel $vaprojdir/data/public_access/raw/cde/frpm/frpm`fall_year_stub'`spring_year_stub'.xls, sheet("FRPM School-Level Data ") cellrange(A2) firstrow case(lower) allstring clear
	}

	gen cdscode = countycode + districtcode + schoolcode

	destring enrollmentk12, gen(enrollment_k12)
	drop enrollmentk12
	destring freemealcountk12, gen(freemeals_k12)
	drop freemealcountk12
	destring percenteligiblefreek1, gen(freemeals_k12_prop)
	drop percenteligiblefreek1
	destring frpmcountk12, gen(totalfrpm_k12)
	drop frpmcountk12
	destring percenteligiblefrpmk1, gen(frpm_k12_prop)
	drop percenteligiblefrpmk1

	destring enrollmentages517, gen(enrollment)
	drop enrollmentages517
	destring freemealcountages517, gen(freemeals)
	drop freemealcountages517
	destring percenteligiblefreeage, gen(freemeals_prop)
	drop percenteligiblefreeage
	destring frpmcountages517, gen(totalfrpm)
	drop frpmcountages517
	destring percenteligiblefrpmage, gen(frpm_prop)
	drop percenteligiblefrpmage

	rename ab calpads_certification

	gen year = `fall_year' + 1
	label var year "Year of Spring Semester"

	order cdscode year
	sort cdscode year
	compress
	label data "California Department of Education Spring `=`fall_year' + 1' Free and Reduced Price Meals"
	save $datadir_clean/cde/frpm/frpm_`=`fall_year' + 1'_clean.dta, replace
}


/* set trace off */


timer off 1
timer list
log close
translate $logdir/clean_frpm.smcl $logdir/clean_frpm.log, replace
