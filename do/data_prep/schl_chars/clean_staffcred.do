/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_staffcred.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean CDE staff credential data per year; produces $datadir_clean/cde/staffcred/staffcred_<year>_clean.dta (consumed by clean_sch_char via append).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/cde/staffcred/StaffCred`fall_year_stub'.txt  (LEGACY raw)
    $consolidated_dir/do/va/helpers/macros_va.doh  (consolidated helper)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/staffcred/staffcred_`=`fall_year' + 1'_clean.dta
    $logdir/data_prep/schl_chars/clean_staffcred.smcl (via log using)
    $logdir/data_prep/schl_chars/clean_staffcred.smcl + $logdir/data_prep/schl_chars/clean_staffcred.log

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_staffcred.do
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
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_elsch.do, clean_enr.do, clean_frpm.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_charter.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


version 16.1
cap log close clean_staffcred
clear all
********************************************************************************
* Description *
/*
This file cleans the CDE staff credentials file. It is unique on year, recid,
credential, and authorization.

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
cap mkdir "$datadir_clean/cde/staffcred"

log using "$logdir/data_prep/schl_chars/clean_staffcred.smcl", replace text name(clean_staffcred)


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

	import delimited $vaprojdir/data/public_access/raw/cde/staffcred/StaffCred`fall_year_stub'.txt, delimiter(tab) varnames(1) case(lower) stringcols(1 2) numericcols(3 4) encoding("utf-8") clear
	desc, full
	codebook

	label var academicyear "Academic Year"

	label var recid "Record ID"

	label def credential 10 "Full Credential"
	label def credential 20 "University Intern", add
	label def credential 30 "District Intern", add
	label def credential 40 "Waiver-Requested", add
	label def credential 50 "Provisional Internship Permit-Available", add
	label def credential 60 "Short-term Staff Permit -Requested", add
	label def credential 70 "Child Development or Children’s Center Permit", add
	label def credential 80 "Emergency or Long-Term Emergency Permits", add
	label def credential 85 "Limited Assignment Teaching Permit", add
	label def credential 90 "Certificate of Clearance", add
	label def credential 95 "Activity Supervisor Clearance Certificate", add
	rename credentialtype credential
	label val credential credential
	label var credential "The type of credential issued to the staff member by CCTC"

	label def authorization 100 "Elementary/Self-Contained Classroom/Multiple Subject"
	label def authorization 107 "Secondary – any single subject", add
	label def authorization 110 "Agriculture", add
	label def authorization 120 "Art", add
	label def authorization 130 "Biology", add
	label def authorization 140 "Biology (specialized)", add
	label def authorization 150 "Business", add
	label def authorization 160 "Chemistry", add
	label def authorization 170 "Chemistry (specialized)", add
	label def authorization 180 "English", add
	label def authorization 190 "Foundational-Level General Science", add
	label def authorization 200 "Foundational-Level Mathematics", add
	label def authorization 210 "Geoscience", add
	label def authorization 220 "Geoscience (specialized)", add
	label def authorization 230 "Health Science", add
	label def authorization 240 "Home Economics", add
	label def authorization 250 "Industrial and Technology", add
	label def authorization 260 "Languages Other Than English", add
	label def authorization 270 "Life Science", add
	label def authorization 280 "Mathematics", add
	label def authorization 290 "Music", add
	label def authorization 300 "Physical Education", add
	label def authorization 310 "Physical Science", add
	label def authorization 320 "Physics", add
	label def authorization 330 "Physics (specialized)", add
	label def authorization 340 "Social Science", add
	label def authorization 350 "Career Technical Education/Vocational", add
	label def authorization 360 "Adult Education", add
	label def authorization 370 "English Language Development (ELD) ONLY", add
	label def authorization 375 "English Language Development (ELD) AND Specially Designed Academic Instruction in English (SDAIE)", add
	label def authorization 380 "Primary Language Instruction (BCLAD or equivalents) and SDAIE and ELD", add
	label def authorization 390 "Reading Specialist/Certificate", add
	label def authorization 400 "Special Designated Subjects (driver education, driver training, ROTC, basic military drill, Aviation flight, or ground instruction)", add
	label def authorization 410 "Special Education", add
	label def authorization 420 "Specially Designed Academic Instruction in English (SDAIE) ONLY", add
	label def authorization 999 "No authorization found for specified credential and time period", add
	rename authorizationtype authorization
	label val authorization authorization
	label var authorization "The specific authorization (s) included in the credential issued by the CCTC"

	label var filecreated "Date that the file was created"

	gen date_created = date(filecreated, "MDY")
	format date_created %td
	label var date_created "Date that the file was created"
	drop filecreated

	gen year = `fall_year' + 1
	label var year "Year of Spring Semester"

	order year recid credential authorization
	sort year recid credential authorization
	compress
	label data "California Department of Education Spring `=`fall_year' + 1' Staff Credential Records"
	save $datadir_clean/cde/staffcred/staffcred_`=`fall_year' + 1'_clean.dta, replace
}


timer off 1
timer list
cap log close clean_staffcred
translate $logdir/data_prep/schl_chars/clean_staffcred.smcl $logdir/data_prep/schl_chars/clean_staffcred.log, replace
