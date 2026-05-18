/*------------------------------------------------------------------------------
do/data_prep/poolingdata/parentpooling.do — Phase 1a §3.3 step 9 batch 9f relocation
================================================================================

PURPOSE
    pool parent CalSCHLS qoiclean across years; reads CHAIN qoiclean/parent/<year> + responserate/parentresponserate; writes $datadir_clean/calschls/poolingdata/parentpooledstats + $datadir_clean/calschls/analysisready/parentanalysisready.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Order:
    secpooling -> parentpooling -> staffpooling -> mergegr11enr -> clean_va
    (mirrors predecessor master.do:302-341).  Depends on batches 9d
    (poolgr11enr), 9e (qoiclean/<sub>/<year>), and 9g (responserate)
    earlier in main.do invocation order.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/qoiclean/parent/parentqoiclean1415  (CHAIN read)
    $datadir_clean/calschls/qoiclean/parent/parentqoiclean1516  (CHAIN read)
    $datadir_clean/calschls/qoiclean/parent/parentqoiclean1617  (CHAIN read)
    $datadir_clean/calschls/qoiclean/parent/parentqoiclean1718  (CHAIN read)
    $datadir_clean/calschls/qoiclean/parent/parentqoiclean1819  (CHAIN read)
    $datadir_clean/calschls/responserate/parentresponserate  (CHAIN read)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/analysisready/parentanalysisready
    $datadir_clean/calschls/poolingdata/parentpooledstats
    $logdir/data_prep/poolingdata/parentpooling.smcl (via log using)
    $logdir/data_prep/poolingdata/parentpooling.smcl + $logdir/data_prep/poolingdata/parentpooling.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9f — extension batch added 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/poolingdata/parentpooling.do
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
    Sister files (this batch): secpooling.do, staffpooling.do, mergegr11enr.do, clean_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* merging all years of parent cleaned qoi data and calculate pooled stats */
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

log using "$logdir/data_prep/poolingdata/parentpooling.smcl", replace text

/* first append all years to make a pnael dataset to calculate pooled stats */
use $datadir_clean/calschls/qoiclean/parent/parentqoiclean1819, clear

append using $datadir_clean/calschls/qoiclean/parent/parentqoiclean1718

append using $datadir_clean/calschls/qoiclean/parent/parentqoiclean1617

append using $datadir_clean/calschls/qoiclean/parent/parentqoiclean1516

append using $datadir_clean/calschls/qoiclean/parent/parentqoiclean1415

drop if missing(cdscode) //there are 3 observations with missing cdscode

/* calculate the wieghted average of qoi means pooled over years
ignore missing values */

sort cdscode year

foreach i of numlist 9 15/17 27 30/34 64 {
  by cdscode: egen qoi`i'mean_pooled =  wtmean(qoi`i'mean), weight(nettotalresp`i')
}

/* generate the pct agree/disagree/don't know for qoi 9 15/17 27 30/34 */
foreach i of numlist 9 15/17 27 30/34 {
  by cdscode: egen pctagree`i'_pooled = wtmean(pctagree`i'), weight(nettotalresp`i')
  by cdscode: egen pctdisagree`i'_pooled = wtmean(pctdisagree`i'), weight(nettotalresp`i')
  by cdscode: egen pctdontknow`i'_pooled = wtmean(pctdontknow`i'), weight(nettotalresp`i')
}

/* generate the pct well/okay/notwell/dontknow for qoi64 */
by cdscode: egen pctwell64_pooled = wtmean(pctwell64), weight(nettotalresp64)
by cdscode: egen pctokay64_pooled = wtmean(pctokay64), weight(nettotalresp64)
by cdscode: egen pctnotwell64_pooled = wtmean(pctnotwell64), weight(nettotalresp64)
by cdscode: egen pctdontknow64_pooled = wtmean(pctdontknow64), weight(nettotalresp64)


collapse (mean) *pooled (sum) nettotalresp* stragree* agree* disagree* strdisagree* dontknow* ///
verywell64 justokay64 notwell64 doesnotdo64 missing*, by(cdscode)

/* label the pooled qoi means and nettotalresp and missing*/
foreach i of numlist 9 15/17 27 30/34 64 {
  label var qoi`i'mean_pooled "weighted mean of qoi`i' responses over years for a given school"
  label var nettotalresp`i' "net total responses for qoi`i' excluding missing pooled over years"
  label var missing`i' "number of missing responses for qoi`i' pooled over years"
}

/* label the pooled percent agree/disagree vars */
foreach i of numlist 9 15/17 27 30/34 {
  label var pctagree`i'_pooled "weighted average percent agree/strongly agree in qoi`i' pooled over years"
  label var pctdisagree`i'_pooled "weighted average percent disagree/strongly disagree in qoi`i' pooled over years"
  label var pctdontknow`i'_pooled "weight average percent don't know in qoi`i' pooled over years"

  label var strdisagree`i' "total number of strongly disagree for qoi`i' pooled over years"
  label var disagree`i' "total number of disagree for qoi`i' pooled over years"
  label var dontknow`i' "total number of don't know for qoi`i' pooled over years"
  label var agree`i' "total number of agree for qoi`i' pooled over years"
  label var stragree`i' "total number of strongly agree for qoi`i' pooled over years"
}

label var pctwell64_pooled "weighted avg percent very well in qoi64 pooled over years"
label var pctokay64_pooled "weighted avg percent just okay in qoi64 pooled over years"
label var pctnotwell64_pooled "weighted avg percent not well or does not do at all in qoi64 pooled over years"

label var verywell64 "total number of very well for qoi64 pooled over years"
label var justokay64 "total number of just okay for qoi64 pooled over years"
label var notwell64 "total number of not well for qoi64 pooled over years"
label var doesnotdo64 "total number of does not do it at all for qoi64 pooled over years"
label var dontknow64 "total number of don't know for qoi64 pooled over years"

label data "weighted average parent qoi statistics pooled over years"
compress
save $datadir_clean/calschls/poolingdata/parentpooledstats, replace

/* merge with the response rate dataset */
merge 1:1 cdscode using $datadir_clean/calschls/responserate/parentresponserate
drop _merge

drop if missing(cdscode)

label data "parent pooled (over years) dataset ready for analysis with stats and response rates"
compress
save $datadir_clean/calschls/analysisready/parentanalysisready, replace


log close
translate $logdir/data_prep/poolingdata/parentpooling.smcl $logdir/data_prep/poolingdata/parentpooling.log, replace 
