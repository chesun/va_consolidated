/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_staffschoolfte.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean CDE staff-school FTE assignments per year; produces $datadir_clean/cde/staffschoolfte/staffschoolfte_<year>_clean.dta (consumed by clean_sch_char via append).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/cde/staffschoolfte/StaffSchoolFTE`fall_year_stub'.txt  (LEGACY raw)
    $consolidated_dir/do/va/helpers/macros_va.doh  (consolidated helper)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/staffschoolfte/staffschoolfte_`=`fall_year' + 1'_clean.dta
    $logdir/data_prep/schl_chars/clean_staffschoolfte.smcl (via log using)
    $logdir/data_prep/schl_chars/clean_staffschoolfte.smcl + $logdir/data_prep/schl_chars/clean_staffschoolfte.log

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_staffschoolfte.do
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
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_elsch.do, clean_enr.do, clean_frpm.do, clean_staffcred.do, clean_staffdemo.do, clean_charter.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


version 16.1
cap log close clean_staffschoolfte
clear all

********************************************************************************
* Description *

/*
This file cleans the CDE staff school FTE files. The resulting dataset is
unique on cdscode, year, recid, job_classification, and fte.

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
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/schl_chars"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/cde"
cap mkdir "$datadir_clean/cde/staffschoolfte"

log using "$logdir/data_prep/schl_chars/clean_staffschoolfte.smcl", replace text name(clean_staffschoolfte)

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

	import delimited $vaprojdir/data/public_access/raw/cde/staffschoolfte/StaffSchoolFTE`fall_year_stub'.txt, delimiter(tab) varnames(1) case(lower) stringcols(1 2 3 4) encoding("utf-8") clear
	desc, full
	codebook

	label var academicyear "Academic Year"

	label var recid "Record ID"

	label var districtcode "District Code"

	label var schoolcode "School Code"

	gen cdscode = districtcode + schoolcode
	label var cdscode "CDS Code"

	label var countyname "County Name"

	label var districtname "District Name"

	label var schoolname "School Name"

	label def job_classification 10 "Administrator"
	label def job_classification 11 "Pupil services", add
	label def job_classification 12 "Teacher", add
	label def job_classification 25 "Non-certificated Administrator", add
	label def job_classification 26 "Charter School Non-certificated Teacher", add
	label def job_classification 27 "Itinerant or Pull-Out/Push-In Teacher", add
	rename jobclassification job_classification
	label val job_classification job_classification
	label var job_classification "Educational Service Job Classification"

	label var stafftype "Type of staff assignment"

	label def staff_type 1 "Administrator"
	label def staff_type 2 "Pupil services", add
	label def staff_type 3 "Teacher", add
	gen staff_type:staff_type = 1 if stafftype=="A"
	replace staff_type = 2 if stafftype=="P"
	replace staff_type = 3 if stafftype=="T"

	label var fte "Full-time equivalent (FTE) teaching duties"

	label var filecreated "Date that the file was created"

	gen date_created = date(filecreated, "MDY")
	format date_created %td
	label var date_created "Date that the file was created"
	drop filecreated

	gen year = `fall_year' + 1
	label var year "Year of Spring Semester"

	order cdscode year recid job_classification fte
	sort cdscode year recid job_classification fte
	compress
	label data "California Department of Education Spring `=`fall_year' + 1' Staff School FTE"
	save $datadir_clean/cde/staffschoolfte/staffschoolfte_`=`fall_year' + 1'_clean.dta, replace
}


timer off 1
timer list
cap log close clean_staffschoolfte
translate $logdir/data_prep/schl_chars/clean_staffschoolfte.smcl $logdir/data_prep/schl_chars/clean_staffschoolfte.log, replace
