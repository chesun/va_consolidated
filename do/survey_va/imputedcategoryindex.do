/*------------------------------------------------------------------------------
do/survey_va/imputedcategoryindex.do — Phase 1a §3.3 step 7 relocation
================================================================================

PURPOSE
    Build climate/quality/support indices from imputed CalSCHLS QOI items (linear sums of QOI means). Per ADR-0010: 9/15/4 items per index. Per ADR-0011: sums→means fix scheduled for Phase 1b §4.2 (currently sums; verbatim preserved).

INVOKED FROM
    `do/main.do' Phase 5 (run_survey_va block).  Per plan v3 §3.3 step 7
    + ADR-0011 (sums→means fix scheduled for Phase 1b §4.2; bodies verbatim
    in this relocation).

INPUTS (verified via grep on file body)
    $datadir_clean/survey_va/imputedallsvyqoimeans.dta (CANONICAL; from imputation.do this batch)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/survey_va/categoryindex/imputedcategoryindex.dta — indices + bivariate VA regressions; $estimates_dir/survey_va/factor/imputed/<...>.dta — per-cell regsave; $estimates_dir/survey_va/factor/imputed/vaindex_imputedregs_all.dta — combined; $output_dir/csv/factoranalysis/imputed/vaindex_imputedregs_all.xlsx — Excel export
    $logdir/survey_va/imputedcategoryindex.smcl + .log

RELOCATION (per plan v3 §3.3 step 7, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/imputedcategoryindex.do
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
/* creates a linear index for each question cateogry using imputed data: school climate, teacher staff quality,
student support, student motivation. Then run bivariate VA regressions on each index var */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************


/*
to run this do file:
do $consolidated_dir/do/survey_va/imputedcategoryindex
 */


/* CHANGE LOG:
11/21/2022: Rewrote code for using new VA estimates
 */

cap log close _all
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/survey_va"
cap mkdir "$datadir_clean/survey_va/categoryindex"
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/survey_va"
cap mkdir "$estimates_dir/survey_va/factor"
cap mkdir "$estimates_dir/survey_va/factor/imputed"
cap mkdir "$output_dir"
cap mkdir "$output_dir/csv"
cap mkdir "$output_dir/csv/factoranalysis"
cap mkdir "$output_dir/csv/factoranalysis/imputed"
cap mkdir "$logdir"


cap mkdir "$logdir/survey_va"
log using "$logdir/survey_va/imputedcategoryindex.smcl", replace text

di as text _n "{hline 80}"
di as text "imputedcategoryindex.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


use $datadir_clean/survey_va/imputedallsvyqoimeans, clear

local climatevars parentqoi16mean_pooled parentqoi17mean_pooled parentqoi27mean_pooled secqoi22mean_pooled secqoi23mean_pooled secqoi24mean_pooled secqoi26mean_pooled secqoi27mean_pooled  secqoi29mean_pooled
local qualityvars parentqoi30mean_pooled parentqoi31mean_pooled parentqoi32mean_pooled parentqoi33mean_pooled parentqoi34mean_pooled secqoi28mean_pooled secqoi35mean_pooled secqoi36mean_pooled secqoi37mean_pooled secqoi38mean_pooled secqoi39mean_pooled secqoi40mean_pooled staffqoi20mean_pooled staffqoi24mean_pooled staffqoi87mean_pooled
local supportvars parentqoi15mean_pooled parentqoi64mean_pooled staffqoi10mean_pooled staffqoi128mean_pooled
/* local motivationvars secqoi31mean_pooled secqoi32mean_pooled secqoi33mean_pooled secqoi34mean_pooled */

/* generate linear index by summing the variables in each category */
gen climateindex = 0

foreach climatevar of local climatevars {
  replace climateindex = climateindex + `climatevar'
}

gen qualityindex = 0

foreach qualityvar of local qualityvars {
  replace qualityindex =  qualityindex + `qualityvar'
}

gen supportindex = 0

foreach supportvar of local supportvars {
  replace supportindex = supportindex + `supportvar'
}



// local macro for index vars
local indexvars climateindex qualityindex supportindex

//generate standardized z scores for variables
foreach var of varlist va* {
  sum `var'
  replace `var' = (`var' - r(mean))/r(sd)
}

foreach i of local indexvars {
  sum `i'
  gen z_`i' = (`i' - r(mean))/r(sd)
}




//-------------------------------------------------------------
// bivariate regression of VA z scores on index z scores
 /* 1. base sample base contro, no peer effects
 2. leave out score - sibling - acs sample, kitchen sink controls, peer effects */
//-------------------------------------------------------------

// macros for different VA estimates to be used in each sample
local b_sample_controls b
local las_sample_controls las


foreach va_outcome in ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year {

      foreach sample in b las {
        foreach control of local `sample'_sample_controls {
          //macro for whether to use the VA estimates with peer effects
          if "`sample'" == "b" {
            local peer
            local peer_yn "N"
          }
          if "`sample'" == "las" {
            local peer "_p"
            local peer_yn "Y"

          }

            local append replace

            foreach index of local indexvars {

              qui reg va_`va_outcome'_`sample'_sp_`control'_ct`peer' z_`index'

              regsave using $estimates_dir/survey_va/factor/imputed/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_index ///
                , `append' ///
                table(va_`va_outcome'_`sample'_sp_`control'_ct`peer', format(%7.2f) parentheses(stderr) asterisk()) ///
                addlabel(va, `va_outcome', sample, `sample', control, `control', peer, `peer_yn')


              local append append
            }
          }

        }
}



//save dataset
save $datadir_clean/survey_va/categoryindex/imputedcategoryindex, replace

//-----------------------------------------------------------
//merge the va index reg datasets to produce combined table
//-----------------------------------------------------------


local merge_command use
local merge_options clear

foreach va_outcome in ela math enr enr_2year enr_4year dk_enr dk_enr_2year dk_enr_4year {
  di "va: `va_outcome'"
  foreach sample in b las {
    di "sample: `sample'"
    foreach control of local `sample'_sample_controls {
      //macro for whether to use the VA estimates with peer effects
      if "`sample'" == "b" {
        local peer
        local peer_yn "N"
      }
      if "`sample'" == "las" {
        local peer "_p"
        local peer_yn "Y"
      }

      di "peer controls in VA estimates (empty if no peer, _p if peer): `peer'"


      `merge_command' $estimates_dir/survey_va/factor/imputed/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_index, `merge_options'

      local merge_command "merge 1:1 var using"
      local merge_options nogen
    }
  }
}


save $estimates_dir/survey_va/factor/imputed/vaindex_imputedregs_all, replace

export excel using $output_dir/csv/factoranalysis/imputed/vaindex_imputedregs_all, replace firstrow(variables)




cap log close
translate $logdir/survey_va/imputedcategoryindex.smcl $logdir/survey_va/imputedcategoryindex.log, replace
