/*------------------------------------------------------------------------------
do/va/reg_out_va_all.do — regress postsec outcomes on score VA + heterogeneity
================================================================================

PURPOSE
    Regress postsecondary outcomes (enr / enr_2year / enr_4year) on test-score
    VA estimates (ELA, Math, both).  Heterogeneity by prior-score deciles
    (gated on $run_prior_score from do/settings.do; default 1 = on), race,
    sex, econ-disadvantage, charter, median-hh-income decile (las sample
    only).  Two control sets per regression: base + matching-VA-controls.

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after batch 3c1 utilities.

INPUTS (CANONICAL)
    $datadir_clean/va_samples_v[12]/out_<sample>.dta — outcome samples (batch 2b)
    $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_<subject>_all.dta — score VA (batch 3c1 merge_va_est)
    $datadir_clean/sbac/prior_decile_original_sample.dta — prior deciles (batch 3c1)
    $datadir_clean/sbac/census_income_decile_a_sample.dta — census income deciles (batch 3c1)
    LEGACY (read-only): $vaprojdir/data/public_access/clean/cde/charter_status.dta — Step 9 deferred

OUTPUTS (CANONICAL)
    $estimates_dir/va_cfr_all_v[12]/reg_out_va/reg_<...>.ster + _m.ster — regression estimates
    $estimates_dir/va_cfr_all_v[12]/reg_out_va/reg_<...>_m.dta — regsave summary
    $estimates_dir/va_cfr_all_v[12]/reg_out_va/het_reg_<...>.ster — heterogeneity estimates
    $logdir/va/reg_out_va_all.smcl + .log

RELOCATION (per plan v3 §3.3 step 3 batch 3c2, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/sbac/reg_out_va_all.do
    Path repointing applied via script-based sed pass:
      - $vaprojdir/log_files/sbac/<x> -> $logdir/<x> (CANONICAL)
      - $vaprojdir/data/va_samples_* -> $datadir_clean/va_samples_*
      - $vaprojdir/data/sbac/<x> -> $datadir_clean/sbac/<x>
      - $vaprojdir/estimates/<x> -> $estimates_dir/<x>
      - $vaprojdir/do_files/sbac/{macros_va,macros_va_all_samples_controls,drift_limit}.doh
        -> $consolidated_dir/do/va/helpers/<x> (absolute per batch 2c convention)
      - $vaprojdir/data/public_access/clean/cde/charter_status.dta KEPT LEGACY (Step 9 CDE data deferred)

ADRs: 0004 (canonical pipeline), 0009 (v1 canonical), 0021 (sandbox; description convention)
ORIGINAL CHANGE LOG preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* regress enrollment outcomes on test score VA from the second round of VA
estimates. Samples: base and kitchen sink  */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun November 16, 2022
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/sbac/reg_out_va_all.do
 */

/* CHANGE LOG:
12/08/2022: Add code for regressions with matching controls as VA


12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math

1/12/2024: heterogeneity by 
- race, 
- econ disadvantage, 
- sex, 
- census tract household median income
 */

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$estimates_dir"
cap mkdir "$estimates_dir/va_cfr_all_v1"
cap mkdir "$estimates_dir/va_cfr_all_v1/reg_out_va"
cap mkdir "$estimates_dir/va_cfr_all_v2"
cap mkdir "$estimates_dir/va_cfr_all_v2/reg_out_va"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cd $vaprojdir

cap log close reg_out_va_all

log using "$logdir/va/reg_out_va_all.smcl", replace text name(reg_out_va_all)

di as text _n "{hline 80}"
di as text "reg_out_va_all.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


local date1 = c(current_date)
local time1 = c(current_time)

include $consolidated_dir/do/va/helpers/macros_va.doh


// macros for different VA estimates to be used in each sample
local b_sample_controls b bd
local las_sample_controls b a ls las bd ad lsd lasd 


foreach version in v1 v2 {

  foreach sample in b las {

    //------------------------------------------------------------------------------
    // create dataset needed for analysis:
    // standardize VA estimates into z scores and merge onto enrollment outcome sample
    //------------------------------------------------------------------------------

    // load the outcome sample
    use $datadir_clean/va_samples_`version'/out_`sample', clear

    foreach subject in ela math {
      // merge with the score VA estimates master dataset with all sample-control combinations
      merge m:1 cdscode year using ///
        $estimates_dir/va_cfr_all_`version'/va_est_dta/va_`subject'_all.dta ///
        , nogen keep(1 3) keepusing(va_*)


      // standardize VA estimates into z score
      foreach va of varlist va_* {
        sum `va'
        replace `va' = `va' - r(mean)
        replace `va' = `va' / r(sd)
      }
    }

    //merge on prior score quantiles calculated in the base sample
    merge m:1 state_student_id using ///
      $datadir_clean/sbac/prior_decile_original_sample.dta, keep(1 3)
    
    // merge on census tract income decile from the acs sample
    merge m:1 state_student_id using ///
      $datadir_clean/sbac/census_income_decile_a_sample.dta, nogen keep(1 3)

    // merge on school characteristics
    merge m:1 cdscode using $vaprojdir/data/public_access/clean/cde/charter_status.dta, keep(1 3) nogen


    //------------------------------------------------------------------------------
    // regress enrollment outcomes on test score VA:
    /*
    1. base sample: base sample base control VA
    2. kitchen sink sample:
      kitchen sink sample base control VA
      kitchen sink sample loscre + sibling control VA
      kitchen sink sample kitchen sink control VA

      each of the above VA: with and without peer controls
    */
    //------------------------------------------------------------------------------

    di "outcome sample: `sample'"
    foreach outcome in enr enr_2year enr_4year {
      di "dependent var: `outcome'"



      foreach control of local `sample'_sample_controls {
        di "VA control: `control'"

        // loop over VA estimates without peer and with peer controls
        forvalues i = 1/2 {
          if `i'==1 {
            local peer
            local peer_yn "N"
          }
          if `i'==2 {
            local peer _p
            local peer_yn "Y"
          }

          di "peer controls in VA estimates (empty if no peer, _p if peer): `peer'"

          //-------------------------------------------------------------
          // first regress outcome on only 1 subject VA estimate
          //-------------------------------------------------------------

          foreach subject in ela math {

            di "VA subject: `subject'"

            // only base controls in the regression
            reg `outcome' va_`subject'_`sample'_sp_`control'_ct`peer' ///
              i.year `b_controls' ///
              , cluster(school_id)

            //add mean of yvar to stored results
            estadd ysumm, mean
            estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'.ster, replace

            // match controls to the VA estimation controls
            if "`peer'"=="" {
              reg `outcome' va_`subject'_`sample'_sp_`control'_ct`peer' ///
                i.year ``control'_spec_controls' ///
                , cluster(school_id)

                estadd ysumm, mean
                estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'_m.ster, replace

                regsave using "$estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'_m.dta", replace ///
                  pval addlabel(outcome, `outcome', subject, `subject', sample, `sample', control, `control', reg_control, "Match VA", peer, `peer_yn')


            }
            if "`peer'"=="_p" {
              reg `outcome' va_`subject'_`sample'_sp_`control'_ct`peer' ///
                i.year ``control'_spec_controls' ///
                `peer_`control'_controls' ///
                , cluster(school_id)

                estadd ysumm, mean
                estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'_m.ster, replace

                regsave using "$estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'_m.dta", replace ///
                  pval addlabel(outcome, `outcome', subject, `subject', sample, `sample', control, `control', reg_control, "Match VA", peer, `peer_yn')

                local append_macro append


            }




          }

          //-------------------------------------------------------------
          // regress outcome on both ELA and Math test score VA
          //-------------------------------------------------------------

          di "VA subject: both ELA and math"

          // only base controls in the regression
          reg `outcome' va_ela_`sample'_sp_`control'_ct`peer' ///
            va_math_`sample'_sp_`control'_ct`peer' ///
            i.year `b_controls' ///
            , cluster(school_id)

          //add mean of yvar to stored results
          estadd ysumm, mean
          estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'.ster, replace

          // match controls to the VA estimation controls
          if "`peer'"=="" {
            reg `outcome' va_ela_`sample'_sp_`control'_ct`peer' ///
              va_math_`sample'_sp_`control'_ct`peer' ///
              i.year ``control'_spec_controls' ///
              , cluster(school_id)

              estadd ysumm, mean
              estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'_m.ster, replace

              regsave using $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'_m.dta, replace ///
                pval addlabel(outcome, `outcome', subject, "ELA and Math", sample, `sample', control, `control', reg_control, "Match VA", peer, `peer_yn')
          }
          if "`peer'"=="_p" {
            reg `outcome' va_ela_`sample'_sp_`control'_ct`peer' ///
              va_math_`sample'_sp_`control'_ct`peer' ///
              i.year ``control'_spec_controls' ///
              `peer_`control'_controls' ///
              , cluster(school_id)

              estadd ysumm, mean
              estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'_m.ster, replace

              regsave using $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'_m.dta, replace ///
                pval addlabel(outcome, `outcome', subject, "ELA and Math", sample, `sample', control, `control', reg_control, "Match VA", peer, `peer_yn')
          }


          //----------------------------------------------------------------------
          // expanded heterogeneity
          //----------------------------------------------------------------------



          foreach subject in ela math {
            // ---------------------------------------------------------------
            // single subject VA interacted with single subject prior score decile
            // ---------------------------------------------------------------
            * GATE: prior-score-decile heterogeneity. Single source of truth = $run_prior_score in
            * do/settings.do. Producer (reg_out_va_all.do / reg_out_va_dk_all.do) and ALL consumers
            * (<x>_tab.do, <x>_fig.do) MUST gate on the same global; a disabled producer otherwise leaves
            * consumers reading missing .ster -> r(601). [2026-05-28]
            if "$run_prior_score" != "0" {
              foreach prior_subject in ela math {
                  di "Heterogeneity: `subject' VA interacted with prior `prior_subject' score deciles"

                  // only base controls in the regression
                  reg `outcome' ///
                    c.va_`subject'_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
                    i.year `b_controls' ///
                    , cluster(school_id)

                  estadd ysumm, mean
                  estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'.ster, replace


                  // match controls to the VA estimation controls
                  if "`peer'"=="" {
                    reg `outcome' ///
                      c.va_`subject'_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
                      i.year ``control'_spec_controls' ///
                      , cluster(school_id)

                      estadd ysumm, mean
                      estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'_m.ster, replace
                  }
                  if "`peer'"=="_p" {
                    reg `outcome' ///
                      c.va_`subject'_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
                      i.year ``control'_spec_controls' ///
                      `peer_`control'_controls' ///
                      , cluster(school_id)

                      estadd ysumm, mean
                      estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'_m.ster, replace
                  }

              }
            }
            

            // ---------------------------------------------------------------
            // single subject VA interacted with race, sex, econ disadvantage, charter, and median hh income decile
            // ---------------------------------------------------------------
            /* if las sample */
            if "`sample'" == "las" {
              local het_char_vars race male econ_disadvantage charter inc_median_hh_xtile
            } 
            else {
              local het_char_vars race male econ_disadvantage charter

            }

            foreach het_char of local het_char_vars {
              di "Heterogeneity: `subject' VA interacted with `het_char'"
              // only base controls in the regression
            
              reg `outcome' ///
                c.va_`subject'_`sample'_sp_`control'_ct`peer'#i.`het_char' ///
                i.year `b_controls' ///
                , cluster(school_id)

              estadd ysumm, mean
              estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_`subject'_x_`het_char'_`sample'_sp_`control'_ct`peer'.ster, replace
            
              
              // match controls to the VA estimation controls
              if "`peer'"=="" {
                reg `outcome' ///
                  c.va_`subject'_`sample'_sp_`control'_ct`peer'#i.`het_char' ///
                  i.year ``control'_spec_controls' ///
                  , cluster(school_id)

                  estadd ysumm, mean
                  estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_`subject'_x_`het_char'_`sample'_sp_`control'_ct`peer'_m.ster, replace
              }
              if "`peer'"=="_p" {
                reg `outcome' ///
                  c.va_`subject'_`sample'_sp_`control'_ct`peer'#i.`het_char' ///
                  i.year ``control'_spec_controls' ///
                  `peer_`control'_controls' ///
                  , cluster(school_id)

                  estadd ysumm, mean
                  estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_`subject'_x_`het_char'_`sample'_sp_`control'_ct`peer'_m.ster, replace
              }
            
            }


          }

        // both subject VAs interacted with single subject prior score decile
        foreach prior_subject in ela math {
          di "Heterogeneity: Both ELA and Math VA interacted with prior `prior_subject' score deciles"

          // only base controls in the regression
          reg `outcome' ///
            c.va_ela_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
            c.va_math_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
            i.year `b_controls' ///
            , cluster(school_id)

          estadd ysumm, mean
          estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_ela_math_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'.ster, replace

          // match controls to the VA estimation controls
          if "`peer'"=="" {
            reg `outcome' ///
              c.va_ela_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
              c.va_math_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
              i.year ``control'_spec_controls' ///
              , cluster(school_id)

              estadd ysumm, mean
              estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_ela_math_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'_m.ster, replace
          }
          if "`peer'"=="_p" {
            reg `outcome' ///
              c.va_ela_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
              c.va_math_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
              i.year ``control'_spec_controls' ///
              `peer_`control'_controls' ///
              , cluster(school_id)

              estadd ysumm, mean
              estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_ela_math_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'_m.ster, replace
          }

        }



        }
      }
    }






  }


}











local date2 = c(current_date)
local time2 = c(current_time)


di "Start date time /reg_out_va_all.do: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close reg_out_va_all
cap translate "$logdir/va/reg_out_va_all.smcl" ///
  "$logdir/va/reg_out_va_all.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
