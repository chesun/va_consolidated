/*------------------------------------------------------------------------------
do/survey_va/testscore.do — Phase 1a §3.3 step 11 RELOCATION (formerly deferred)
================================================================================

PURPOSE
    produce testscorecontrols dataset (6th + 8th grade test scores for Table 8 control set; consumed by Step 7 indexregwithdemo + indexhorseracewithdemo).

INVOKED FROM
    `do/main.do' Phase 5 (SURVEY VA) under flag `do_survey_va'.  RELOCATED
    from caschls/do/share/factoranalysis/testscore.do per Step 11 disposition
    decision 2026-05-08 (originally deferred from Step 7; recategorized
    from "exploratory" to ACTIVE chain producer after disposition audit
    confirmed downstream Step 7 consumers).  Order: this script runs
    BEFORE the survey-VA scripts that consume its output.

INPUTS (verified via grep on file body)
    $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_lag_test_scores_clean.dta  (LEGACY)
    $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/schoolchar/testscorecontrols
    $logdir/survey_va/testscore.smcl + .log

RELOCATION (per plan v3 §3.3 step 11 — extension batch added 2026-05-08)
    Source: caschls/do/share/factoranalysis/testscore.do
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
    Sister files (this batch): allsvymerge.do, allsvyfactor.do (archived per ADR-0010)

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* pull SBAC test score data from Matt dataset to create controls for index regressions using 6th and 8th grade test scores  */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close testscore
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/survey_va"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/schoolchar"

log using "$logdir/survey_va/testscore.smcl", replace text name(testscore)


// load up the subsample of students Matt is using. This includes grade 11 students in year 2015-2017 (year of the spring semester)
use merge_id_k12_test_scores state_student_id dataset cdscode grade year all_scores_sample ///
if grade==11 & dataset=="CAASPP" & inrange(year, 2015, 2017) & all_scores_sample==1 ///
using $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta, clear

// merge with the lagged test score data
merge 1:1 merge_id_k12_test_scores using $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_lag_test_scores_clean.dta
//only keep merged observations
keep if _merge == 3
drop _merge

/* use grade 7 ELA score for grade 8 in year 2017 due to missing data */
gen prior_gr8_zscore = L3_cst_ela_z_score if inrange(year, 2015, 2016)
replace prior_gr8_zscore = L4_cst_ela_z_score if year==2017

//keep only the 6th grade math score (L5) and 8th grade (L3) ELA score
keep state_student_id grade year cdscode merge_id_k12_test_scores dataset L5_cst_math_z_score prior_gr8_zscore

//collapse to get average test scores for each school per year
collapse L5_cst_math_z_score prior_gr8_zscore, by (cdscode year)

//collapse again to average across years
collapse avg_gr6math_zscore=L5_cst_math_z_score avg_gr8ela_zscore=prior_gr8_zscore, by(cdscode)

label var avg_gr6math_zscore "pooled avg 6th grade math z score for 11th graders in 2014-15 to 2016-17 "
label var avg_gr8ela_zscore "pooled avg 8th grade ELA z score for 11th graders in 2014-15 to 2016-17"

drop if missing(cdscode)

label data "SBAC 6th grade math and 8th grade ELA test score for 11 graders in 1415-1617"

save $datadir_clean/schoolchar/testscorecontrols, replace


cap log close testscore
translate $logdir/survey_va/testscore.smcl $logdir/survey_va/testscore.log, replace
