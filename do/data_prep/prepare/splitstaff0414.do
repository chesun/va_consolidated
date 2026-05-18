/*------------------------------------------------------------------------------
do/data_prep/prepare/splitstaff0414.do — Phase 1a §3.3 step 9 batch 9d relocation
================================================================================

PURPOSE
    split pre-existing $clndtadir/staff/staff0414 by year; produces $datadir_clean/calschls/staff/staff<year>.dta.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/staff/staff0414  (CHAIN read; from renamedata.do this batch — runs first per main.do invocation order)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/staff/staff`i'
    $logdir/data_prep/prepare/splitstaff0414.smcl (via log using)
    $logdir/data_prep/prepare/splitstaff0414.smcl + $logdir/data_prep/prepare/splitstaff0414.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9d, applied 2026-05-08)
    Source: caschls/do/build/prepare/splitstaff0414.do
    Path repointing applied (script-based methodology):
      $projdir/log/build/prepare/<x>                    -> $logdir/<x>  (CANONICAL)
      $projdir/dta/enrollment/schoollevel/<x> (read OR write) -> $datadir_clean/enrollment/schoollevel/<x>  (CANONICAL chain)
      $projdir/dta/enrollment/raw/<x> (read)             -> $caschls_projdir/dta/enrollment/raw/<x>  (LEGACY raw)
      $clndtadir/<sub>/<x> (write only)                -> $datadir_clean/calschls/<sub>/<x>  (CANONICAL chain)
      $clndtadir/<sub>/<x> (read of pre-existing)      -> kept LEGACY (e.g., $clndtadir/staff/staff0414)
      $rawdtadir/<x> (read)                              -> kept LEGACY (CalSCHLS survey raw inputs)
      translate (multi-line OR single-line)            -> translate $logdir/<x>  (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag (per Step 7 indexalpha precedent).
    `name(...)' suffix (used by poolgr11enr/enrollmentclean/renamedata/
    splitstaff0414) preserved.

SETTINGS REQUISITE
    settings.do edited in this batch to add LEGACY-READ-ONLY globals
    `$rawdtadir' (CalSCHLS restricted raw survey data) and `$clndtadir'
    (CalSCHLS restricted clean data, pre-existing — used for read of
    staff0414 in splitstaff0414.do).  No write-eligible target via
    those globals; writes go to $datadir_clean/calschls/<x> CANONICAL.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9d
    Sister files (this batch): enrollmentclean.do, poolgr11enr.do, renamedata.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
**********split staff0414.dta into 10 dastasets, 1 for each school year*********
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************
cap log close splitstaff0414
clear
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/prepare"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/calschls"
cap mkdir "$datadir_clean/calschls/staff"

log using "$logdir/data_prep/prepare/splitstaff0414.smcl", replace text name(splitstaff0414)

use $datadir_clean/calschls/staff/staff0414, clear  // CHAIN read from renamedata.do (same-batch producer; see plan v3 §3.3 step 9 batch 9d invocation order)

gen str tempyear = "" //generate a temp string var for ease of writing short file names
replace tempyear = "0405" if schlyear == 2004.2005
replace tempyear = "0506" if schlyear == 2005.2006
replace tempyear = "0607" if schlyear == 2006.2007
replace tempyear = "0708" if schlyear == 2007.2008
replace tempyear = "0809" if schlyear == 2008.2009
replace tempyear = "0910" if schlyear == 2009.2010
replace tempyear = "1011" if schlyear == 2010.2011
replace tempyear = "1112" if schlyear == 2011.2012
replace tempyear = "1213" if schlyear == 2012.2013
replace tempyear = "1314" if schlyear == 2013.2014

local years `" "0405" "0506" "0607" "0708" "0809" "0910" "1011" "1112" "1213" "1314" "' //a local macro for storing years

preserve //write a copy of the data in memory to disk to restore later

foreach i of local years {
  keep if tempyear == "`i'"
  save $datadir_clean/calschls/staff/staff`i', replace
  restore, preserve //retore the data without erasing the backup copy on disk
}

restore

log close splitstaff0414 //close the current log file for this do file
translate $logdir/data_prep/prepare/splitstaff0414.smcl $logdir/data_prep/prepare/splitstaff0414.log, replace 
