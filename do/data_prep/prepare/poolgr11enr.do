/*------------------------------------------------------------------------------
do/data_prep/prepare/poolgr11enr.do — Phase 1a §3.3 step 9 batch 9d relocation
================================================================================

PURPOSE
    pool grade-11 enrollment across 5 years; computes school avg used as regression weight; reads CHAIN $datadir_clean/enrollment/schoollevel/enr<year>.dta (from enrollmentclean).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $datadir_clean/enrollment/schoollevel/enr1415  (CHAIN read; from this batch)
    $datadir_clean/enrollment/schoollevel/enr1516  (CHAIN read; from this batch)
    $datadir_clean/enrollment/schoollevel/enr1617  (CHAIN read; from this batch)
    $datadir_clean/enrollment/schoollevel/enr1718  (CHAIN read; from this batch)
    $datadir_clean/enrollment/schoollevel/enr1819  (CHAIN read; from this batch)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/enrollment/schoollevel/poolgr11enr
    $logdir/data_prep/prepare/poolgr11enr.smcl (via log using)
    $logdir/data_prep/prepare/poolgr11enr.smcl + $logdir/data_prep/prepare/poolgr11enr.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9d, applied 2026-05-08)
    Source: caschls/do/build/prepare/poolgr11enr.do
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
    Sister files (this batch): enrollmentclean.do, renamedata.do, splitstaff0414.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* poole grade 11 enrollment over years and calculate average for use as regression weights */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close poolgr11enr
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/prepare"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/enrollment"
cap mkdir "$datadir_clean/enrollment/schoollevel"

log using "$logdir/data_prep/prepare/poolgr11enr.smcl", replace text name(poolgr11enr)

/* append the datasets */
use $datadir_clean/enrollment/schoollevel/enr1819, clear
append using $datadir_clean/enrollment/schoollevel/enr1718
append using $datadir_clean/enrollment/schoollevel/enr1617
append using $datadir_clean/enrollment/schoollevel/enr1516
append using $datadir_clean/enrollment/schoollevel/enr1415

/* collapse to get avg grade 11 enrollment over years */
collapse (mean) gr11enr, by(cdscode)
rename gr11enr gr11enr_mean
label var gr11enr_mean "average grade 11 enrollment over years"

save $datadir_clean/enrollment/schoollevel/poolgr11enr, replace


cap log close poolgr11enr
translate $logdir/data_prep/prepare/poolgr11enr.smcl $logdir/data_prep/prepare/poolgr11enr.log, replace 
