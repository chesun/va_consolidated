/*------------------------------------------------------------------------------
do/data_prep/poolingdata/clean_va.do — Phase 1a §3.3 step 9 batch 9f relocation
================================================================================

PURPOSE
    clean VA estimates for survey-VA analysis; produces $datadir_clean/calschls/va/va_pooled_all.dta (chain output for survey-VA scripts in do/survey_va/).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Order:
    secpooling -> parentpooling -> staffpooling -> mergegr11enr -> clean_va
    (mirrors predecessor master.do:302-341).  Depends on batches 9d
    (poolgr11enr), 9e (qoiclean/<sub>/<year>), and 9g (responserate)
    earlier in main.do invocation order.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/analysisready/`svyname'analysisready  (CHAIN read)
    $datadir_clean/calschls/va/va_pooled_all.dta  (CHAIN read)
    $estimates_dir/va_cfr_all_v1/va_est_dta/va_`va_outcome'_all.dta  (CHAIN read; from do/va/merge_va_est.do — relocated Step 3 batch 3c1)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/va/va_pooled_all.dta
    $logdir/data_prep/poolingdata/clean_va.smcl (via log using)
    $logdir/data_prep/poolingdata/clean_va.smcl + $logdir/data_prep/poolingdata/clean_va.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9f — extension batch added 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/poolingdata/clean_va.do
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
    Sister files (this batch): secpooling.do, parentpooling.do, staffpooling.do, mergegr11enr.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* clean VA estimates to be used for survey data analysis, and merge to survey
analysis datasets */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun November 21, 2022
* this do file replaces poolingva.do and combineva.do
*****************************************************

/* To run this do file, type:
do $projdir/do/build//buildanalysisdata/poolingdata/clean_va.do
 */

/* CHANGE LOG:

 */



cap log close _all
graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/poolingdata"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/calschls"
cap mkdir "$datadir_clean/calschls/va"

log using "$logdir/data_prep/poolingdata/clean_va.smcl", replace text




local date1_va_scatter_plot = c(current_date)
local time1_va_scatter_plot = c(current_time)


//------------------------------------------------------------------------------
// collapse VA estimates to school level mean over the years 2015-2018
//------------------------------------------------------------------------------

foreach va_outcome in ela math enr enr_2year enr_4year {
  use $estimates_dir/va_cfr_all_v1/va_est_dta/va_`va_outcome'_all.dta, clear  // CHAIN read from do/va/merge_va_est.do (CANONICAL; relocated Step 3 batch 3c1)
  collapse (mean) va*, by(cdscode)

  tempfile va_`va_outcome'
  save `va_`va_outcome''
}

//------------------------------------------------------------------------------
// merge collapsed VA estimates
//------------------------------------------------------------------------------

// use a macro to store the command to initialize the data for merge
local merge_command use
local merge_options clear

foreach va_outcome in ela math enr enr_2year enr_4year {
  `merge_command' `va_`va_outcome'', `merge_options'
  local merge_command "merge 1:1 cdscode using"
  local merge_options nogen
}

label data "Pooled  School Level VA mean estimates for all test scores and enrollment over 2015-2018"
save $datadir_clean/calschls/va/va_pooled_all.dta, replace



//------------------------------------------------------------------------------
// merge collapsed VA estimates onto survey data
//------------------------------------------------------------------------------
foreach svyname in sec parent staff {
  use $datadir_clean/calschls/analysisready/`svyname'analysisready, clear
  merge 1:1 cdscode using $datadir_clean/calschls/va/va_pooled_all.dta, keep(1 3) nogen

  save, replace
}





local date2_va_scatter_plot = c(current_date)
local time2_va_scatter_plot = c(current_time)

di "Do file clean_va.do start date time: `date1_va_scatter_plot' `time1_va_scatter_plot'"
di "End date time: `date2_va_scatter_plot' `time2_va_scatter_plot'"


log close
translate $logdir/data_prep/poolingdata/clean_va.smcl $logdir/data_prep/poolingdata/clean_va.log, replace
