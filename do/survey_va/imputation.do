/*------------------------------------------------------------------------------
do/survey_va/imputation.do — Phase 1a §3.3 step 7 relocation
================================================================================

PURPOSE
    Multiply-impute missing CalSCHLS QOI items in the merged survey dataset (allsvyqoimeans). Uses Stata mi commands.

INVOKED FROM
    `do/main.do' Phase 5 (run_survey_va block).  Per plan v3 §3.3 step 7
    + ADR-0011 (sums→means fix scheduled for Phase 1b §4.2; bodies verbatim
    in this relocation).

INPUTS (verified via grep on file body)
    $datadir_clean/survey_va/allsvyqoimeans (CHAIN read from Step 11 allsvymerge.do)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/survey_va/imputedallsvyqoimeans.dta — imputed dataset for downstream indexing
    $logdir/imputation.smcl + .log

RELOCATION (per plan v3 §3.3 step 7, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/imputation.do
    Path repointing applied via script-based sed pass:
      $projdir/log/share/factoranalysis/* -> $logdir/*
      $projdir/dta/allsvyfactor/imputedallsvyqoimeans -> $datadir_clean/survey_va/imputedallsvyqoimeans (chain output)
      $projdir/dta/allsvyfactor/categoryindex/* -> $datadir_clean/survey_va/categoryindex/* (chain output)
      $projdir/out/dta/factor/* -> $estimates_dir/survey_va/factor/* (CANONICAL chain estimates)
      $projdir/out/csv/factoranalysis/* -> $output_dir/csv/factoranalysis/* (intermediate exploratory; not paper-shipping)
      $projdir/out/graph/factoranalysis/* -> $output_dir/graph/factoranalysis/* (intermediate exploratory)
      $projdir/dta/<other>/* -> $caschls_projdir/dta/<other>/* (LEGACY-static reads from caschls predecessor)
      $projdir/do/share/factoranalysis/<x>.do[h] -> $consolidated_dir/do/survey_va/<x>.do[h] (within-batch relocations)

ADRs: 0010 (paper alpha 9/15/4), 0011 (sums→means Phase 1b deferred),
      0013 (mattschlchar gate kept; consumed by indexreg/indexhorse with demo),
      0021 (sandbox; description convention)
ORIGINAL CHANGE LOG preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* impute missing values in allsvyqoimeans.dta */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************

/* change log:
12/19/2024: correct spelling error in supportimputedummies local macro */

cap log close _all
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/survey_va"
cap mkdir "$logdir"


log using "$logdir/imputation.smcl", replace text

di as text _n "{hline 80}"
di as text "imputation.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


use $datadir_clean/survey_va/allsvyqoimeans, clear

local allqoivars parentqoi9mean_pooled parentqoi15mean_pooled parentqoi16mean_pooled parentqoi17mean_pooled parentqoi27mean_pooled parentqoi30mean_pooled parentqoi31mean_pooled parentqoi32mean_pooled parentqoi33mean_pooled parentqoi34mean_pooled parentqoi64mean_pooled ///
secqoi22mean_pooled secqoi23mean_pooled secqoi24mean_pooled secqoi25mean_pooled secqoi26mean_pooled secqoi27mean_pooled secqoi28mean_pooled secqoi29mean_pooled secqoi30mean_pooled secqoi31mean_pooled secqoi32mean_pooled secqoi33mean_pooled secqoi34mean_pooled secqoi35mean_pooled secqoi36mean_pooled secqoi37mean_pooled secqoi38mean_pooled secqoi39mean_pooled secqoi40mean_pooled ///
staffqoi10mean_pooled staffqoi20mean_pooled staffqoi24mean_pooled staffqoi41mean_pooled staffqoi44mean_pooled staffqoi64mean_pooled staffqoi87mean_pooled staffqoi98mean_pooled staffqoi103mean_pooled staffqoi104mean_pooled staffqoi105mean_pooled staffqoi109mean_pooled staffqoi111mean_pooled staffqoi112mean_pooled staffqoi128mean_pooled

local climatevars parentqoi9mean_pooled parentqoi16mean_pooled parentqoi17mean_pooled parentqoi27mean_pooled secqoi22mean_pooled secqoi23mean_pooled secqoi24mean_pooled secqoi25mean_pooled secqoi26mean_pooled secqoi27mean_pooled secqoi28mean_pooled secqoi29mean_pooled secqoi30mean_pooled staffqoi20mean_pooled staffqoi24mean_pooled staffqoi41mean_pooled staffqoi44mean_pooled staffqoi64mean_pooled staffqoi87mean_pooled staffqoi98mean_pooled
local qualityvars parentqoi30mean_pooled parentqoi31mean_pooled parentqoi32mean_pooled parentqoi33mean_pooled parentqoi34mean_pooled secqoi35mean_pooled secqoi36mean_pooled secqoi37mean_pooled secqoi38mean_pooled secqoi39mean_pooled secqoi40mean_pooled staffqoi103mean_pooled staffqoi104mean_pooled staffqoi105mean_pooled staffqoi109mean_pooled staffqoi111mean_pooled staffqoi112mean_pooled
local supportvars parentqoi15mean_pooled parentqoi64mean_pooled staffqoi10mean_pooled staffqoi128mean_pooled
local motivationvars secqoi31mean_pooled secqoi32mean_pooled secqoi33mean_pooled secqoi34mean_pooled


/* Note: NEED TO ADD VAR LABELS */

// generate an indicator for imputed qoi vars and assign a local macro for the imputation indicator dummies for each category
local climateimputedummies
foreach i of local climatevars {
  gen imputed`i' = 0
  replace imputed`i' = 1 if missing(`i')
  label var imputed`i' "dummy for whether variable `i' is imputed"
  local addvar imputed`i'
  local climateimputedummies: list climateimputedummies | addvar
}

local qualityimputedummies
foreach i of local qualityvars {
  gen imputed`i' = 0
  replace imputed`i' = 1 if missing(`i')
  label var imputed`i' "dummy for whether variable `i' is imputed"
  local addvar imputed`i'
  local qualityimputedummies: list qualityimputedummies | addvar
}

local supportimputedummies
foreach i of local supportvars {
  gen imputed`i' = 0
  replace imputed`i' = 1 if missing(`i')
  label var imputed`i' "dummy for whether variable `i' is imputed"
  local addvar imputed`i'
  local supportimputedummies: list supportimputedummies | addvar
}

local motivationimputedummies
foreach i of local motivationvars {
  gen imputed`i' = 0
  replace imputed`i' = 1 if missing(`i')
  label var imputed`i' "dummy for whether variable `i' is imputed"
  local addvar imputed`i'
  local motivationimputedummies: list motivationimputedummies | addvar
}


// impute missing values of each variable using nonmissing sample mean
foreach i of local allqoivars {
  egen mean`i' = mean(`i')
  replace `i' = mean`i' if missing(`i')
  drop mean`i'
}


********************************************************************************
/* Regress each var on other vars in each category and imputed dummies; predict y hat and replace missing with y hat */
// do this for climate vars
local xdummies
foreach i of local climatevars {
  local xvars: list climatevars - i
  local minusvar imputed`i'
  local xdummies: list climateimputedummies - minusvar
  reg `i' `xvars' `xdummies'
  predict hat_`i'
  replace `i' = hat_`i' if imputed`i' == 1
  drop hat_`i'
}


// do this for quality vars
local xdummies
foreach i of local qualityvars {
  local xvars: list qualityvars - i
  local minusvar imputed`i'
  local xdummies: list qualityimputedummies - minusvar
  reg `i' `xvars' `xdummies'
  predict hat_`i'
  replace `i' = hat_`i' if imputed`i' == 1
  drop hat_`i'
}


// do this for support vars
local xdummies
foreach i of local supportvars {
  local xvars: list supportvars - i
  local minusvar imputed`i'
  local xdummies: list supportimputedummies - minusvar
  reg `i' `xvars' `xdummies'
  predict hat_`i'
  replace `i' = hat_`i' if imputed`i' == 1
  drop hat_`i'
}


// do this for motivation vars
local xdummies
foreach i of local motivationvars {
  local xvars: list motivationvars - i
  local minusvar imputed`i'
  local xdummies: list motivationimputedummies - minusvar
  reg `i' `xvars' `xdummies'
  predict hat_`i'
  replace `i' = hat_`i' if imputed`i' == 1
  drop hat_`i'
}


save $datadir_clean/survey_va/imputedallsvyqoimeans, replace

cap log close
translate $logdir/imputation.smcl $logdir/imputation.log, replace
