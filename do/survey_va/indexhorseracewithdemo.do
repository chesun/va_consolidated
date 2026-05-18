/*------------------------------------------------------------------------------
do/survey_va/indexhorseracewithdemo.do — Phase 1a §3.3 step 7 relocation
================================================================================

PURPOSE
    Horse-race regressions controlling for school demographics (Christina + Matt-pooled school chars + lagged test scores). Paper Table 8 Panel B.

INVOKED FROM
    `do/main.do' Phase 5 (run_survey_va block).  Per plan v3 §3.3 step 7
    + ADR-0011 (sums→means fix scheduled for Phase 1b §4.2; bodies verbatim
    in this relocation).

INPUTS (verified via grep on file body)
    $datadir_clean/survey_va/categoryindex/<type>categoryindex.dta (CANONICAL); $datadir_clean/schoolchar/schlcharpooledmeans.dta (CHAIN read from Step 10 mattschlchar.do); $datadir_clean/schoolchar/testscorecontrols.dta (CHAIN read from Step 11 testscore.do)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $estimates_dir/survey_va/factor/indexhorsewithdemo/<type>/va_<...>.dta — per-cell regsave; $estimates_dir/survey_va/factor/indexhorsewithdemo/<type>_index_horse_wdemo.dta — combined; $output_dir/csv/factoranalysis/indexhorsewithdemo/<type>_index_horse_wdemo.csv — Excel
    $logdir/survey_va/indexhorseracewithdemo.smcl + .log

RELOCATION (per plan v3 §3.3 step 7, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/indexhorseracewithdemo.do
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
/* Linear regressions of VA vars on all 3 index vars in a "horse race" type regression
with school demographic controls for both complete case and imputed data  */
********************************************************************************
********************************************************************************
*************** written by Christina Sun. Email: ucsun@ucdavis.edu *************
********************************************************************************


/* CHANGE LOG:
 */

/* to run this do file:

do $consolidated_dir/do/survey_va/indexhorseracewithdemo

 */

cap log close _all

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/survey_va"
cap mkdir "$estimates_dir/survey_va/factor"
cap mkdir "$estimates_dir/survey_va/factor/indexhorsewithdemo"
cap mkdir "$output_dir"
cap mkdir "$output_dir/csv"
cap mkdir "$output_dir/csv/factoranalysis"
cap mkdir "$output_dir/csv/factoranalysis/indexhorsewithdemo"
cap mkdir "$logdir"


cap mkdir "$logdir/survey_va"
log using "$logdir/indexhorsewithdemo.smcl", replace text

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


local date1 = c(current_date)
local time1 = c(current_time)


local datatype compcase imputed

foreach type of local datatype {
  use $datadir_clean/survey_va/categoryindex/`type'categoryindex, clear
  //merge with pooled average enrollment characteristics over 1415-1718 constructed from Matt Naven's data
  //keep only merged observations or unmatched master observations
  merge 1:1 cdscode using $datadir_clean/schoolchar/schlcharpooledmeans, keep(1 3) nogen

  merge 1:1 cdscode using $datadir_clean/schoolchar/testscorecontrols, keep(1 3) nogen

  // local macro for index vars
  local indexsdvars z_climateindex z_qualityindex z_supportindex

  //local macro for demographics vars
  local demovars minorityenrprop maleenrprop freemealprop elprop maleteachprop minoritystaffprop newteachprop fullcredprop fteteachperstudent fteadminperstudent fteserviceperstudent

  //local macro for SBAC test scores
  local scorevars avg_gr6math_zscore avg_gr8ela_zscore

  //log transform the demo vars, adding 0.0000001 does not affect interpretation because it is small compared to variable values
  foreach i of local demovars {
    gen ln_`i' = log(`i'+ 0.0000001)
  }


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


                qui reg va_`va_outcome'_`sample'_sp_`control'_ct`peer' `indexsdvars' ln_* `scorevars'

                regsave using $estimates_dir/survey_va/factor/indexhorsewithdemo/`type'/va_`va_outcome'_`sample'_sp_`control'_ct`peer' ///
                  , replace ///
                  table(va_`va_outcome'_`sample'_sp_`control'_ct`peer', format(%7.2f) parentheses(stderr) asterisk()) ///
                  addlabel(va, `va_outcome', sample, `sample', control, `control', peer, `peer_yn')



            }

          }
  }


  //-----------------------------------------------------------
  //merge the va index horse race reg datasets to produce combined table
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


        `merge_command' $estimates_dir/survey_va/factor/indexhorsewithdemo/`type'/va_`va_outcome'_`sample'_sp_`control'_ct`peer', `merge_options'

        local merge_command "merge 1:1 var using"
        local merge_options nogen
      }
    }
  }


  save $estimates_dir/survey_va/factor/indexhorsewithdemo/`type'_index_horse_wdemo, replace

  export excel using $output_dir/csv/factoranalysis/indexhorsewithdemo/`type'_index_horse_wdemo.csv, replace firstrow(variables)

}

















local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close
cap translate "$logdir/indexhorsewithdemo.smcl" ///
  "$logdir/indexhorsewithdemo.log", replace