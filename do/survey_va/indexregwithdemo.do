/*------------------------------------------------------------------------------
do/survey_va/indexregwithdemo.do — Phase 1a §3.3 step 7 relocation
================================================================================

PURPOSE
    Bivariate VA-on-index regressions controlling for school demographics. Companion to indexhorseracewithdemo.do; paper Table 8 Panel A.

INVOKED FROM
    `do/main.do' Phase 5 (run_survey_va block).  Per plan v3 §3.3 step 7
    + ADR-0011 (sums→means fix scheduled for Phase 1b §4.2; bodies verbatim
    in this relocation).

INPUTS (verified via grep on file body)
    $datadir_clean/survey_va/categoryindex/<type>categoryindex.dta (CANONICAL); $datadir_clean/schoolchar/schlcharpooledmeans.dta (CHAIN read from Step 10 mattschlchar.do) + $datadir_clean/schoolchar/testscorecontrols.dta (CHAIN read from Step 11 testscore.do)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $estimates_dir/survey_va/factor/indexbivarwithdemo/<type>/<...>_index.dta — per-cell regsave; $datadir_clean/survey_va/categoryindex/<type>indexwithdemo.dta — merged dataset; $estimates_dir/survey_va/factor/indexbivarwithdemo/<type>_index_bivar_wdemo.dta — combined; $output_dir/csv/factoranalysis/indexbivarwithdemo/<type>_index_bivar_wdemo.xlsx — Excel
    $logdir/survey_va/indexregwithdemo.smcl + .log

RELOCATION (per plan v3 §3.3 step 7, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/indexregwithdemo.do
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
/* Bivariate VA regressions on each category index with school demographics from Matt Naven's data as controls */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************

/* CHANGE LOG:
11/27/2022: Rewrote code for using new VA estimates
 */

/* to run this do file:

do $consolidated_dir/do/survey_va/indexregwithdemo

 */

cap log close indexregwithdemo
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/survey_va"
cap mkdir "$datadir_clean/survey_va/categoryindex"
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/survey_va"
cap mkdir "$estimates_dir/survey_va/factor"
cap mkdir "$estimates_dir/survey_va/factor/indexbivarwithdemo"
cap mkdir "$output_dir"
cap mkdir "$output_dir/csv"
cap mkdir "$output_dir/csv/factoranalysis"
cap mkdir "$output_dir/csv/factoranalysis/indexbivarwithdemo"
cap mkdir "$logdir"


cap mkdir "$logdir/survey_va"
log using "$logdir/survey_va/indexregwithdemo.smcl", replace text name(indexregwithdemo)

di as text _n "{hline 80}"
di as text "indexregwithdemo.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"





////////////////////////////////////////////////////////////////////////////////
/* both complete case analysis and imputed data  */

local datatype compcase imputed

foreach type of local datatype {
  use $datadir_clean/survey_va/categoryindex/`type'categoryindex, clear

  //merge with pooled average enrollment characteristics over 1415-1718 constructed from Matt Naven's data
  //keep only merged observations or unmatched master observations
  merge 1:1 cdscode using $datadir_clean/schoolchar/schlcharpooledmeans, keep(1 3) nogen


  merge 1:1 cdscode using $datadir_clean/schoolchar/testscorecontrols, keep(1 3) nogen




  // local macro for index vars
  local indexvars climateindex qualityindex supportindex

  //local macro for demographics vars
  local demovars minorityenrprop maleenrprop freemealprop elprop maleteachprop minoritystaffprop newteachprop fullcredprop fteteachperstudent fteadminperstudent fteserviceperstudent

  //local macro for SBAC test scores
  local scorevars avg_gr6math_zscore avg_gr8ela_zscore

  //log transform the demo vars, adding 0.0000001 does not affect interpretation because it is small compared to variable values
  foreach i of local demovars {
    gen ln_`i' = log(`i'+ 0.0000001)
  }

/*
  foreach i of local demovars {
    sum `i'
    gen z_`i' = (`i' - r(mean))/r(sd)
  }

  local zdemovars z_minorityenrprop z_maleenrprop z_freemealprop z_elprop z_maleteachprop z_minoritystaffprop z_newteachprop z_fullcredprop z_fteteachperstudent z_fteadminperstudent z_fteserviceperstudent
 */



  //-------------------------------------------------------------
  // bivariate regressions va z scores on index z scores and demographics controls
  // regress va vars on index vars, have one file for each index to save N in the dataset

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

        local append_macro replace

        foreach index of local indexvars {
          reg va_`va_outcome'_`sample'_sp_`control'_ct`peer' z_`index' ln_* `scorevars'

          regsave using $estimates_dir/survey_va/factor/indexbivarwithdemo/`type'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_index ///
            , `append_macro' ///
            table(va_`va_outcome'_`sample'_sp_`control'_ct`peer', format(%7.2f) parentheses(stderr) asterisk()) ///
            addlabel(va, `va_outcome', sample, `sample', control, `control', peer, `peer_yn')

          local append_macro append

        }
      }
    }
  }




  //save dataset
  compress
  save $datadir_clean/survey_va/categoryindex/`type'indexwithdemo, replace



/* set trace on */



    //merge the va index reg datasets to produce combined table
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


          `merge_command' $estimates_dir/survey_va/factor/indexbivarwithdemo/`type'/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_index, `merge_options'

          local merge_command "merge 1:1 var using"
          local merge_options nogen
        }
      }
    }

    save $estimates_dir/survey_va/factor/indexbivarwithdemo/`type'_index_bivar_wdemo, replace
    export excel using $output_dir/csv/factoranalysis/indexbivarwithdemo/`type'_index_bivar_wdemo, replace firstrow(variables)
  }

set trace off


cap log close indexregwithdemo
translate $logdir/survey_va/indexregwithdemo.smcl $logdir/survey_va/indexregwithdemo.log, replace
