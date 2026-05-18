/*------------------------------------------------------------------------------
do/survey_va/factor.do — Phase 1a §3.3 step 7 relocation
================================================================================

PURPOSE
    Exploratory factor analysis of CalSCHLS survey QOI items (sec/parent/staff). Produces eigen plots + factor-loading tables.

INVOKED FROM
    `do/main.do' Phase 5 (run_survey_va block).  Per plan v3 §3.3 step 7
    + ADR-0011 (sums→means fix scheduled for Phase 1b §4.2; bodies verbatim
    in this relocation).

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/analysisready/secanalysisready  (CHAIN read; from Step 9f poolingdata/secpooling.do)
    $datadir_clean/calschls/analysisready/parentanalysisready  (CHAIN read; from Step 9f poolingdata/parentpooling.do)
    $datadir_clean/calschls/analysisready/staffanalysisready  (CHAIN read; from Step 9f poolingdata/mergegr11enr.do)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $output_dir/graph/factoranalysis/{sec,parent,staff}screeplot.png — scree plots; $output_dir/csv/factoranalysis/{sec,parent,staff}factoreigen1.csv — eigen tables (intermediate exploratory; not paper-shipping)
    $logdir/survey_va/factor.smcl + .log

RELOCATION (per plan v3 §3.3 step 7, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/factor.do
    Path repointing applied via script-based sed pass:
      $projdir/log/share/factoranalysis/<x> -> $logdir/<x>
      $projdir/dta/allsvyfactor/imputedallsvyqoimeans -> $datadir_clean/survey_va/imputedallsvyqoimeans (chain output)
      $projdir/dta/allsvyfactor/categoryindex/<x> -> $datadir_clean/survey_va/categoryindex/<x> (chain output)
      $caschls_projdir/dta/buildanalysisdata/analysisready/<x> -> $datadir_clean/calschls/analysisready/<x> (CHAIN read from Step 9f poolingdata producers; was LEGACY pre-flight-D fix 2026-05-16)
      $projdir/out/dta/factor/<x> -> $estimates_dir/survey_va/factor/<x> (CANONICAL chain estimates)
      $projdir/out/csv/factoranalysis/<x> -> $output_dir/csv/factoranalysis/<x> (intermediate exploratory; not paper-shipping)
      $projdir/out/graph/factoranalysis/<x> -> $output_dir/graph/factoranalysis/<x> (intermediate exploratory)
      $projdir/dta/<other>/<x> -> $caschls_projdir/dta/<other>/<x> (LEGACY-static reads from caschls predecessor)
      $projdir/do/share/factoranalysis/<x>.do[h] -> $consolidated_dir/do/survey_va/<x>.do[h] (within-batch relocations)

ADRs: 0010 (paper alpha 9/15/4), 0011 (sums→means Phase 1b deferred),
      0013 (mattschlchar gate kept; consumed by indexreg/indexhorse with demo),
      0021 (sandbox; description convention)
ORIGINAL CHANGE LOG preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* exploratory factor analysis for secondary, parent, and staff surveys questions of interest */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close _all
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$output_dir"
cap mkdir "$output_dir/csv"
cap mkdir "$output_dir/csv/factoranalysis"
cap mkdir "$output_dir/graph"
cap mkdir "$output_dir/graph/factoranalysis"
cap mkdir "$logdir"


cap mkdir "$logdir/survey_va"
log using "$logdir/survey_va/factor.smcl", replace text

di as text _n "{hline 80}"
di as text "factor.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/* use principal factoring method because data is not multinormal */
// estout with factor: http://repec.org/bocode/e/estout/advanced.html#advanced404

/* Uniqueness is the variance that is ‘unique’ to the variable and not shared with other
variables. It is equal to 1 – communality (variance that is shared with other variables)
Notice that the greater ‘uniqueness’ the lower the relevance of the variable in the
factor model. */

/* secondary */
use $datadir_clean/calschls/analysisready/secanalysisready, clear

/* standardize qoi mean vars into z scores */
foreach i of numlist 22/40 {
  sum qoi`i'mean_pooled
  gen qoi`i'mean_z = (qoi`i'mean_pooled - r(mean))/r(sd)
}

factor *mean_z
esttab e(L) using $output_dir/csv/factoranalysis/secfactorall.csv, nogap noobs nonumber nomtitle replace //export factor loadings table for all factors
screeplot, yline(1)
graph export $output_dir/graph/factoranalysis/secscreeplot.png, replace
//set minimum eigenvalue to 1
factor *mean_z, mineigen(1) //2 factors with eigenvalue above 1
esttab using $output_dir/csv/factoranalysis/secfactoreigen1.csv, cells("L[1](t label(Factor 1)) L[2](t label(Factor 2)) Psi[Uniqueness]") nogap noobs nonumber nomtitle replace


/* parent */
use $datadir_clean/calschls/analysisready/parentanalysisready, clear

/* standardize qoi mean vars into z scores */
foreach i of numlist 9 15/17 27 30/34 64 {
  sum qoi`i'mean_pooled
  gen qoi`i'mean_z = (qoi`i'mean_pooled - r(mean))/r(sd)
}

factor *mean_z
esttab e(L) using $output_dir/csv/factoranalysis/parentfactorall.csv, nogap noobs nonumber nomtitle replace
screeplot, yline(1)
graph export $output_dir/graph/factoranalysis/parentscreeplot.png, replace
factor *mean_z, mineigen(1) //1 factor with eigenvalue above 1
esttab using $output_dir/csv/factoranalysis/parentfactoreigen1.csv, cells("L[1](t label(Factor 1)) Psi[Uniqueness]") nogap noobs nonumber nomtitle replace



/* staff */
use $datadir_clean/calschls/analysisready/staffanalysisready, clear

/* standardize qoi mean vars into z scores */
foreach i of numlist 10 20 24 41 44 64 87 98 103/105 109 111 112 128 {
  sum qoi`i'mean_pooled
  gen qoi`i'mean_z = (qoi`i'mean_pooled - r(mean))/r(sd)
}

factor *mean_z
esttab e(L) using $output_dir/csv/factoranalysis/stafffactorall.csv, nogap noobs nonumber nomtitle replace
screeplot, yline(1)
graph export $output_dir/graph/factoranalysis/staffscreeplot.png, replace
factor *mean_z, mineigen(1) //3 factors with eigenvalue above 1
esttab using $output_dir/csv/factoranalysis/stafffactoreigen1.csv, cells("L[1](t label(Factor 1)) L[2](t label(Factor 2)) L[3](t label(Factor 3)) Psi[Uniqueness]") nogap noobs nonumber nomtitle replace


/* note: standardizing into z score is unnecessary. Doesn't change factor analysis results,
since factors are explaining the variance */


cap log close
translate $logdir/survey_va/factor.smcl $logdir/survey_va/factor.log, replace
