/*------------------------------------------------------------------------------
do/survey_va/indexhorserace.do — Phase 1a §3.3 step 7 relocation
================================================================================

PURPOSE
    Horse-race regressions: VA on multiple indices simultaneously (climate vs quality vs support). Identifies which index has strongest association with VA.

INVOKED FROM
    `do/main.do' Phase 5 (run_survey_va block).  Per plan v3 §3.3 step 7
    + ADR-0011 (sums→means fix scheduled for Phase 1b §4.2; bodies verbatim
    in this relocation).

INPUTS (verified via grep on file body)
    $datadir_clean/survey_va/categoryindex/<type>categoryindex.dta (CANONICAL; type ∈ {imputed, compcase}, from imputed/compcase category index do files)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $output_dir/csv/factoranalysis/indexhorserace/va_<va_outcome>_<sample>_sp_<control>_ct[_p]_<type>.dta — per-cell regsave; $output_dir/csv/factoranalysis/indexhorserace/<type>horserace.csv — combined Excel-style export
    $logdir/survey_va/indexhorserace.smcl + .log

RELOCATION (per plan v3 §3.3 step 7, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/indexhorserace.do
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
for both complete case and imputed data  */
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
cap mkdir "$output_dir/csv/factoranalysis/indexhorserace"
cap mkdir "$logdir"


cap mkdir "$logdir/survey_va"
log using "$logdir/survey_va/indexhorserace.smcl", replace text

di as text _n "{hline 80}"
di as text "indexhorserace.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


////////////////////////////////////////////////////////////////////////////////


foreach type in compcase imputed {

  use $datadir_clean/survey_va/categoryindex/`type'categoryindex, clear

  //local macro for z score index vars
  local indexsdvars z_climateindex z_qualityindex z_supportindex


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


                qui reg va_`va_outcome'_`sample'_sp_`control'_ct`peer' `indexsdvars'

                regsave using $output_dir/csv/factoranalysis/indexhorserace/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_`type' ///
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


        `merge_command' $output_dir/csv/factoranalysis/indexhorserace/va_`va_outcome'_`sample'_sp_`control'_ct`peer'_`type', `merge_options'

        local merge_command "merge 1:1 var using"
        local merge_options nogen
      }
    }
  }

  export excel using $output_dir/csv/factoranalysis/indexhorserace/`type'horserace.csv, replace firstrow(variables)


}





cap log close
translate $logdir/survey_va/indexhorserace.smcl $logdir/survey_va/indexhorserace.log, replace
