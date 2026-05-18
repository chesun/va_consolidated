/*------------------------------------------------------------------------------
do/survey_va/indexalpha.do — Phase 1a §3.3 step 7 relocation
================================================================================

PURPOSE
    Compute Cronbach's alpha for the climate/quality/support indices on complete-case data. Per ADR-0010: 9/15/4 alpha values feed paper footnote (currently footnote says 20/17/4 — paper-text fix DEFERRED post-handoff per Christina 2026-05-07).

INVOKED FROM
    `do/main.do' Phase 5 (run_survey_va block).  Per plan v3 §3.3 step 7
    + ADR-0011 (sums→means fix scheduled for Phase 1b §4.2; bodies verbatim
    in this relocation).

INPUTS (verified via grep on file body)
    $datadir_clean/survey_va/categoryindex/compcasecategoryindex.dta (CANONICAL; from compcasecategoryindex.do this batch)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    Console output only (alpha printed to log); no .dta or .csv produced. $logdir/survey_va/indexalpha.smcl + .log
    $logdir/survey_va/indexalpha.smcl + .log

RELOCATION (per plan v3 §3.3 step 7, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/indexalpha.do
    Path repointing applied via script-based sed pass:
      $projdir/log/share/factoranalysis/<x> -> $logdir/<x>
      $projdir/dta/allsvyfactor/imputedallsvyqoimeans -> $datadir_clean/survey_va/imputedallsvyqoimeans (chain output)
      $projdir/dta/allsvyfactor/categoryindex/<x> -> $datadir_clean/survey_va/categoryindex/<x> (chain output)
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
/* Cronbach's alpha for the 4 index categories */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close indexalpha
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"


cap mkdir "$logdir/survey_va"
log using "$logdir/survey_va/indexalpha.smcl", replace text name(indexalpha)

di as text _n "{hline 80}"
di as text "indexalpha.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


use $datadir_clean/survey_va/categoryindex/compcasecategoryindex, clear

local climatevars parentqoi16mean_pooled parentqoi17mean_pooled parentqoi27mean_pooled secqoi22mean_pooled secqoi23mean_pooled secqoi24mean_pooled secqoi26mean_pooled secqoi27mean_pooled  secqoi29mean_pooled
local qualityvars parentqoi30mean_pooled parentqoi31mean_pooled parentqoi32mean_pooled parentqoi33mean_pooled parentqoi34mean_pooled secqoi28mean_pooled secqoi35mean_pooled secqoi36mean_pooled secqoi37mean_pooled secqoi38mean_pooled secqoi39mean_pooled secqoi40mean_pooled staffqoi20mean_pooled staffqoi24mean_pooled staffqoi87mean_pooled
local supportvars parentqoi15mean_pooled parentqoi64mean_pooled staffqoi10mean_pooled staffqoi128mean_pooled
/* local motivationvars secqoi31mean_pooled secqoi32mean_pooled secqoi33mean_pooled secqoi34mean_pooled */
/* Cronbach's alpha for the school climate index */
alpha `climatevars', std item

/* Cronbach's alpha for teacher and staff quality index */
alpha `qualityvars', std item

/* Cronbach's alpha for counseling support index */
alpha `supportvars', std item


cap log close indexalpha
translate $logdir/survey_va/indexalpha.smcl $logdir/survey_va/indexalpha.log, replace 
