/*------------------------------------------------------------------------------
do/data_prep/poolingdata/mergegr11enr.do — Phase 1a §3.3 step 9 batch 9f relocation
================================================================================

PURPOSE
    merge gr11 enrollment weight onto parent/sec analysisready datasets; reads CHAIN poolgr11enr (batch 9d) + analysisready (batch 9f sister); updates analysisready in-place.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Order:
    secpooling -> parentpooling -> staffpooling -> mergegr11enr -> clean_va
    (mirrors predecessor master.do:302-341).  Depends on batches 9d
    (poolgr11enr), 9e (qoiclean/<sub>/<year>), and 9g (responserate)
    earlier in main.do invocation order.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/analysisready/parentanalysisready  (CHAIN read)
    $datadir_clean/calschls/analysisready/secanalysisready  (CHAIN read)
    $datadir_clean/calschls/poolingdata/staffpooledstats  (CHAIN read)
    $datadir_clean/enrollment/schoollevel/poolgr11enr  (CHAIN read)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/analysisready/staffanalysisready
    $logdir/data_prep/poolingdata/mergegr11enr.smcl (via log using)
    $logdir/data_prep/poolingdata/mergegr11enr.smcl + $logdir/data_prep/poolingdata/mergegr11enr.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9f — extension batch added 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/poolingdata/mergegr11enr.do
    Path repointing applied (script-based methodology):
      $projdir/log/build/buildanalysisdata(/poolingdata)?/<x>.smcl -> $logdir/<x>.smcl
      $projdir/dta/buildanalysisdata/qoiclean/<sub>/<x> -> $datadir_clean/calschls/qoiclean/<sub>/<x>  (CHAIN read from batch 9e)
      $projdir/dta/buildanalysisdata/responserate/<x> -> $datadir_clean/calschls/responserate/<x>  (CHAIN read from batch 9g)
      $projdir/dta/enrollment/schoollevel/<x> -> $datadir_clean/enrollment/schoollevel/<x>  (CHAIN read from batch 9d)
      $projdir/dta/buildanalysisdata/poolingdata/<x> -> $datadir_clean/calschls/poolingdata/<x>  (CANONICAL chain output)
      $projdir/dta/buildanalysisdata/analysisready/<x> -> $datadir_clean/calschls/analysisready/<x>  (CANONICAL chain output; consumed by survey-VA in do/survey_va/)
      $projdir/dta/buildanalysisdata/va/<x> -> $datadir_clean/calschls/va/<x>  (CANONICAL chain output)
      translate (single + multi-line forms; predecessor `clean_va.do' had `build//buildanalysisdata' double-slash) -> $logdir/<x> (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9f (extension; named-scope decision: include
        per Christina 2026-05-08)
    Sister files (this batch): secpooling.do, parentpooling.do, staffpooling.do, clean_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* merge pooled analysis datasets with grade 11 enrollment for use as regression weights */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close _all
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/poolingdata"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/calschls"
cap mkdir "$datadir_clean/calschls/analysisready"

log using "$logdir/data_prep/poolingdata/mergegr11enr.smcl", replace text

/* merge gr11 enrollment with parent pooled dataset */
use $datadir_clean/calschls/analysisready/parentanalysisready, clear
merge 1:1 cdscode using $datadir_clean/enrollment/schoollevel/poolgr11enr, keepusing(gr11enr_mean)
drop if _merge == 2 //drop unmatched observations from the enrollment dataset
drop _merge

save, replace



/* merge gr11 enrollment with secondary pooled dataset */
use $datadir_clean/calschls/analysisready/secanalysisready, clear
merge 1:1 cdscode using $datadir_clean/enrollment/schoollevel/poolgr11enr, keepusing(gr11enr_mean)
drop if _merge == 2 //drop unmatched observations from the enrollment dataset
drop _merge

save, replace



/* merge gr11 enrollment with staff pooled dataset */
use $datadir_clean/calschls/poolingdata/staffpooledstats, clear
merge 1:1 cdscode using $datadir_clean/enrollment/schoollevel/poolgr11enr, keepusing(gr11enr_mean)
drop if _merge == 2 //drop unmatched observations from the enrollment dataset
drop _merge

save $datadir_clean/calschls/analysisready/staffanalysisready, replace


log close
translate $logdir/data_prep/poolingdata/mergegr11enr.smcl $logdir/data_prep/poolingdata/mergegr11enr.log, replace 
