/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_elsch.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean CDE English-learner school-level data per year; produces $datadir_clean/cde/elsch/elsch_<year>_clean.dta (consumed by clean_sch_char via append).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/cde/elsch/elsch`fall_year_stub'.txt  (LEGACY raw)
    $consolidated_dir/do/va/helpers/macros_va.doh  (consolidated helper)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/elsch/elsch_`=`fall_year' + 1'_clean.dta
    $logdir/clean_elsch.smcl (via log using)
    $logdir/clean_elsch.smcl + $logdir/clean_elsch.log

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_elsch.do
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
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_enr.do, clean_frpm.do, clean_staffcred.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_charter.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


version 16.1
cap log close _all
clear all
********************************************************************************
* Description *
/*
This do file cleans the English Learners data.

Data Location: https://www.cde.ca.gov/ds/ad/fileselsch.asp
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
cap mkdir "$datadir_clean/cde/elsch"

log using "$logdir/clean_elsch.smcl", replace text


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
* Import data
forvalues fall_year = `= `test_score_min_year' - 1' (1) `= `test_score_max_year' - 1' {
	di "Fall Year = `fall_year'"

	local fall_year_stub = substr(string(`fall_year'), 3, 2)

	import delimited $vaprojdir/data/public_access/raw/cde/elsch/elsch`fall_year_stub'.txt, delimiters(tab) varnames(1) case(lower) stringcols(1 5) encoding(ISO-8859-1) clear

	rename cds cdscode
	gen year = `fall_year' + 1
	label var year "Year of Spring Semester"

	order cdscode year language
	sort cdscode year language
	compress
	label data "California Department of Education Spring `=`fall_year' + 1' English Learners"
	save $datadir_clean/cde/elsch/elsch_`=`fall_year' + 1'_clean.dta, replace
}


timer off 1
timer list
log close
translate $logdir/clean_elsch.smcl $logdir/clean_elsch.log, replace
