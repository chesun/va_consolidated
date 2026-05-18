/*------------------------------------------------------------------------------
do/survey_va/allsvymerge.do — Phase 1a §3.3 step 11 RELOCATION (formerly deferred)
================================================================================

PURPOSE
    MERGE active: rename + merge parent/sec/staff CalSCHLS qoimeans into single allsvyqoimeans dataset (consumed by Step 7 imputation + compcasecategoryindex).

INVOKED FROM
    `do/main.do' Phase 5 (SURVEY VA) under flag `do_survey_va'.  RELOCATED
    from caschls/do/share/factoranalysis/allsvymerge.do per Step 11 disposition
    decision 2026-05-08 (originally deferred from Step 7; recategorized
    from "exploratory" to ACTIVE chain producer after disposition audit
    confirmed downstream Step 7 consumers).  Order: this script runs
    BEFORE the survey-VA scripts that consume its output.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/va/va_pooled_all.dta  (CHAIN read; from Step 9f clean_va.do)
    $datadir_clean/calschls/analysisready/parentanalysisready  (CHAIN read)
    $datadir_clean/calschls/analysisready/secanalysisready  (CHAIN read)
    $datadir_clean/calschls/analysisready/staffanalysisready  (CHAIN read)
    $datadir_clean/survey_va/formerge/parentqoimeans  (CHAIN read)
    $datadir_clean/survey_va/formerge/secqoimeans  (CHAIN read)
    $datadir_clean/survey_va/formerge/staffqoimeans  (CHAIN read)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/survey_va/allsvyqoimeans
    $datadir_clean/survey_va/formerge/parentqoimeans
    $datadir_clean/survey_va/formerge/secqoimeans
    $datadir_clean/survey_va/formerge/staffqoimeans
    $logdir/survey_va/allsvymerge.smcl + .log

RELOCATION (per plan v3 §3.3 step 11 — extension batch added 2026-05-08)
    Source: caschls/do/share/factoranalysis/allsvymerge.do
    Path repointing applied:
      $projdir/log/share/factoranalysis/<x> -> $logdir/<x> (CANONICAL)
      $projdir/dta/allsvyfactor/<x> -> $datadir_clean/survey_va/<x> (CANONICAL chain — consumed by Step 7)
      $projdir/dta/schoolchar/<x> -> $datadir_clean/schoolchar/<x> (CANONICAL chain — consumed by Step 7)
      $projdir/dta/buildanalysisdata/analysisready/<x> -> $datadir_clean/calschls/analysisready/<x> (CANONICAL chain from Step 9f)
      $projdir/dta/<other>/<x> -> $caschls_projdir/dta/<other>/<x> (LEGACY-static raw)
      translate -> $logdir/<x> (CANONICAL)

CROSS-STEP CHAIN COORDINATION
    Step 7 files updated to read CHAIN paths:
      imputation.do:66 + compcasecategoryindex.do:86 — read $datadir_clean/survey_va/allsvyqoimeans (was $caschls_projdir/dta/allsvyfactor/allsvyqoimeans LEGACY)
      indexregwithdemo.do:98 + indexhorseracewithdemo.do:93 — read $datadir_clean/schoolchar/testscorecontrols (was $caschls_projdir/dta/schoolchar/testscorecontrols LEGACY)

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 11 (deferred → resolved 2026-05-08)
    Sister files (this batch): testscore.do, allsvyfactor.do (archived per ADR-0010)

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* rename variables in surveys and merge all surveys for overall factor analysis, keeping
only the qoimean variables */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************

/* CHANGE LOG:
11/21/2022: Rewrote code for using new VA estimates

12/19/2024: remove VA from analysis ready data when renaming, merge in again after merging survey datasets together

 */
 
cap log close _all
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/survey_va"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/survey_va"
cap mkdir "$datadir_clean/survey_va/formerge"

log using "$logdir/survey_va/allsvymerge.smcl", replace text

/* rename vars and prep parentanalysisready.dta for merging */
use $datadir_clean/calschls/analysisready/parentanalysisready, clear

/* keep only the qoimean vars  and va to be used in factor analysis */
keep cdscode qoi* 

/* rename variables and drop common vars to prepare for merging across surveys */
rename qoi* parentqoi*

save $datadir_clean/survey_va/formerge/parentqoimeans, replace


/* rename vars in secanalysisready.dta and prep for merging */
use $datadir_clean/calschls/analysisready/secanalysisready, clear

keep cdscode qoi* 
rename qoi* secqoi*

save $datadir_clean/survey_va/formerge/secqoimeans, replace


/* rename vars in staffanalysisready.dta and prep for merging */
use $datadir_clean/calschls/analysisready/staffanalysisready, clear

keep cdscode qoi* 
rename qoi* staffqoi*

save $datadir_clean/survey_va/formerge/staffqoimeans, replace



/* merge all surveys */
use $datadir_clean/survey_va/formerge/parentqoimeans, clear
merge 1:1 cdscode using $datadir_clean/survey_va/formerge/secqoimeans, nogen 
merge 1:1 cdscode using $datadir_clean/survey_va/formerge/staffqoimeans, nogen 

// merge on VA 
merge 1:1 cdscode using $datadir_clean/calschls/va/va_pooled_all.dta, keep(1 3) nogen 

save $datadir_clean/survey_va/allsvyqoimeans, replace


log close
translate $logdir/survey_va/allsvymerge.smcl $logdir/survey_va/allsvymerge.log, replace
