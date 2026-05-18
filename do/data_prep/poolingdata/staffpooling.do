/*------------------------------------------------------------------------------
do/data_prep/poolingdata/staffpooling.do — Phase 1a §3.3 step 9 batch 9f relocation
================================================================================

PURPOSE
    pool staff CalSCHLS qoiclean across years; reads CHAIN qoiclean/staff/<year>; writes $datadir_clean/calschls/poolingdata/staffpooledstats + $datadir_clean/calschls/analysisready/staffanalysisready.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Order:
    secpooling -> parentpooling -> staffpooling -> mergegr11enr -> clean_va
    (mirrors predecessor master.do:302-341).  Depends on batches 9d
    (poolgr11enr), 9e (qoiclean/<sub>/<year>), and 9g (responserate)
    earlier in main.do invocation order.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/qoiclean/staff/staffqoiclean1415  (CHAIN read)
    $datadir_clean/calschls/qoiclean/staff/staffqoiclean1516  (CHAIN read)
    $datadir_clean/calschls/qoiclean/staff/staffqoiclean1617  (CHAIN read)
    $datadir_clean/calschls/qoiclean/staff/staffqoiclean1718  (CHAIN read)
    $datadir_clean/calschls/qoiclean/staff/staffqoiclean1819  (CHAIN read)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/poolingdata/staffpooledstats
    $logdir/data_prep/poolingdata/staffpooling.smcl (via log using)
    $logdir/data_prep/poolingdata/staffpooling.smcl + $logdir/data_prep/poolingdata/staffpooling.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9f — extension batch added 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/poolingdata/staffpooling.do
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
    Sister files (this batch): secpooling.do, parentpooling.do, mergegr11enr.do, clean_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* merging all years of staff cleaned qoi data and calculate pooled stats */
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
cap mkdir "$datadir_clean/calschls/poolingdata"
cap mkdir "$datadir_clean/calschls/analysisready"

log using "$logdir/data_prep/poolingdata/staffpooling.smcl", replace text

/* first append all years to make a pnael dataset to calculate pooled stats */
use $datadir_clean/calschls/qoiclean/staff/staffqoiclean1819, clear
append using $datadir_clean/calschls/qoiclean/staff/staffqoiclean1718

append using $datadir_clean/calschls/qoiclean/staff/staffqoiclean1617

append using $datadir_clean/calschls/qoiclean/staff/staffqoiclean1516

append using $datadir_clean/calschls/qoiclean/staff/staffqoiclean1415

drop if missing(cdscode) //there is one observation with missing cdscode


/* calculate the weighted average of qoi means pooled over years
ignore missing values */
/* Note: collapse doesn't work because the weight is different for each variable, would have to write everything out */
sort cdscode year

foreach i of numlist 10 20 24 41 44 64 87 98 103/105 109 111 112 128 {
  by cdscode: egen qoi`i'mean_pooled =  wtmean(qoi`i'mean), weight(nettotalresp`i')
}

/* generate the percentage agree/disagree for qoi 10 20 24 41 44 64 87 128 */
foreach i of numlist 10 20 24 41 44 64 87 128 {
  by cdscode: egen pctagree`i'_pooled = wtmean(pctagree`i'), weight(nettotalresp`i')
  by cdscode: egen pctdisagree`i'_pooled = wtmean(pctdisagree`i'), weight(nettotalresp`i')
}

/* generate pooled weighted average percentage small/big problem for qoi98 */
by cdscode: egen pctsmallprob98_pooled = wtmean(pctsmallprob98), weight(nettotalresp98)
by cdscode: egen pctbigprob98_pooled = wtmean(pctbigprob98), weight(nettotalresp98)

/* generate pooled weighted percentage yes/no for qoi 103/105 109 111 112 */
foreach i of numlist 103/105 109 111 112 {
  by cdscode: egen pctyes`i'_pooled = wtmean(pctyes`i'), weight(nettotalresp`i')
  by cdscode: egen pctno`i'_pooled = wtmean(pctno`i'), weight(nettotalresp`i')
}

collapse (mean) *pooled (sum) nettotalresp* missing*, by(cdscode)

/* label the pooled qoi means and nettotalresp and missing*/
foreach i of numlist 10 20 24 41 44 64 87 98 103/105 109 111 112 128 {
  label var qoi`i'mean_pooled "weighted mean of qoi`i' responses over years for a given school"
  label var nettotalresp`i' "net total responses for qoi`i' excluding missing pooled over years"
  label var missing`i' "number of missing responses for qoi`i' pooled over years"
}

********************** label all the weighted pooled vars **********************
/* label the pooled percent agree/disagree vars */
foreach i of numlist 10 20 24 41 44 64 87 128 {
  label var pctagree`i'_pooled "weighted average percent agree/strongly agree in qoi`i' pooled over years"
  label var pctdisagree`i'_pooled "weighted average percent disagree/strongly disagree in qoi`i' pooled over years"
}

/* label the pooled percent small/big problem  for qoi98 */
label var pctsmallprob98_pooled "weighted avg percent insignificant or mild problem in qoi98 pooled over years"
label var pctbigprob98_pooled "weighted avg percent moderate or severe problem in qoi98 pooled over years"

/* label the pooled percent yes/no for qoi 103/105 109 111 112 */
foreach i of numlist 103/105 109 111 112 {
  label var pctyes`i'_pooled "weighted avg percent yes in qoi `i' pooled over years"
  label var pctno`i'_pooled "weighted avg percent no in qoi`i' pooled over years"
}




/* there is no staff response rate so cannot merge with the response rate dataset */

label data "weighted average staff qoi statistics pooled over years"
compress
save $datadir_clean/calschls/poolingdata/staffpooledstats, replace


log close
translate $logdir/data_prep/poolingdata/staffpooling.smcl $logdir/data_prep/poolingdata/staffpooling.log, replace 
