/*------------------------------------------------------------------------------
do/survey_va/pcascore.do — Phase 1a §3.3 step 7 relocation
================================================================================

PURPOSE
    PCA scoreplot for survey factor analysis (companion to factor.do).

INVOKED FROM
    `do/main.do' Phase 5 (run_survey_va block).  Per plan v3 §3.3 step 7
    + ADR-0011 (sums→means fix scheduled for Phase 1b §4.2; bodies verbatim
    in this relocation).

INPUTS (verified via grep on file body)
    $caschls_projdir/dta/buildanalysisdata/analysisready/{sec,parent,staff}analysisready.dta (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $output_dir/graph/factoranalysis/pcascore/{sec,parent,staff[pc1|pc2]}pcascore.png
    $logdir/pcascore.smcl + .log

RELOCATION (per plan v3 §3.3 step 7, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/pcascore.do
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
/* creates principal component scores from pca for all 3 surveys */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close _all
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$output_dir"
cap mkdir "$output_dir/graph"
cap mkdir "$output_dir/graph/factoranalysis"
cap mkdir "$output_dir/graph/factoranalysis/pcascore"
cap mkdir "$logdir"


log using "$logdir/pcascore.smcl", replace text

di as text _n "{hline 80}"
di as text "pcascore.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


/* creating pca compiste score for secondary survey */
use $caschls_projdir/dta/buildanalysisdata/analysisready/secanalysisready, clear

pca *mean_pooled
predict pc1, score
histogram pc1, freq
graph export $output_dir/graph/factoranalysis/pcascore/secpcascore.png, replace


/* creating pca compiste score for parent survey */
use $caschls_projdir/dta/buildanalysisdata/analysisready/parentanalysisready, clear

pca *mean_pooled
predict pc1, score
histogram pc1, freq
graph export $output_dir/graph/factoranalysis/pcascore/parentpcascore.png, replace


/* creating pca compiste score for staff survey */
use $caschls_projdir/dta/buildanalysisdata/analysisready/staffanalysisready, clear

pca *mean_pooled
predict pc1 pc2, score
histogram pc1, freq
graph export $output_dir/graph/factoranalysis/pcascore/staffpc1score.png, replace
histogram pc1, freq
graph export $output_dir/graph/factoranalysis/pcascore/staffpc2score.png, replace


cap log close
translate $logdir/pcascore.smcl $logdir/pcascore.log, replace 
