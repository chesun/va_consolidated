/*------------------------------------------------------------------------------
do/va/reg_out_va_dk_all.do — Phase 1a §3.3 step 3 batch 3c2 relocation
================================================================================

PURPOSE
    Regress postsecondary outcomes on Deep Knowledge VA (controlling for both ELA + Math VA from va_score_all output).  Heterogeneity by prior-score deciles only.  Two control sets per regression (base + matching-VA).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after batch 3c1 utilities.

OUTPUTS (CANONICAL per ADR-0021 sandbox)
    $estimates_dir/va_cfr_all_v[12]/reg_out_va/{reg_<outcome>_va_dk_<outcome>_<...>,het_reg_<outcome>_va_dk_<outcome>_x_prior_<subject>_<...>}.ster
    $logdir/va/reg_out_va_dk_all.smcl + .log

RELOCATION (per plan v3 §3.3 step 3 batch 3c2, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/sbac/reg_out_va_dk_all.do
    Path repointing applied via script-based sed pass (same as reg_out_va_all.do):
      $vaprojdir/log_files/sbac/<x> -> $logdir/<x>
      $vaprojdir/data/va_samples_* -> $datadir_clean/va_samples_*
      $vaprojdir/data/sbac/<x> -> $datadir_clean/sbac/<x>
      $vaprojdir/estimates/<x> -> $estimates_dir/<x>
      $vaprojdir/tables/<x> -> $tables_dir/<x>
      $vaprojdir/figures/<x> -> $figures_dir/<x>
      $vaprojdir/gph_files/<x> -> $output_dir/gph_files/<x>
      $vaprojdir/do_files/sbac/{macros_va,macros_va_all_samples_controls,drift_limit}.doh
        -> $consolidated_dir/do/va/helpers/<x> (absolute per batch 2c convention)

ADRs: 0004 (canonical pipeline), 0009 (v1 canonical), 0021 (sandbox; description convention)
ORIGINAL CHANGE LOG preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* regress enrollment outcomes on deep knowledge VA from the second round of VA
estimates. Samples: base and kitchen sink  */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun November 16, 2022
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/sbac/reg_out_va_dk_all.do
 */

/* CHANGE LOG:
12/08/2022: added regs with matching controls as VA controls

12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math
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

cap log close reg_out_va_dk_all

log using "$logdir/va/reg_out_va_dk_all.smcl", replace text name(reg_out_va_dk_all)

di as text _n "{hline 80}"
di as text "reg_out_va_dk_all.do — RUN START: `c(current_date)' `c(current_time)'"
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
local b_sample_controls b
local las_sample_controls b ls las


foreach version in v1 v2 {

  foreach sample in b las {
    // load outcome dataset
    use $datadir_clean/va_samples_`version'/out_`sample', clear

    // merge on the DK VA estimates
    foreach outcome in enr enr_2year enr_4year {
      merge m:1 cdscode year using ///
        $estimates_dir/va_cfr_all_`version'/va_est_dta/va_`outcome'_all.dta ///
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

    //----------------------------------------------------------------------------
    // regress enrollment on DK VA, matching left and right hand side outcome
    /*
    1. base sample: base sample base control VA
    2. kitchen sink sample:
      kitchen sink sample base control VA
      kitchen sink sample loscre + sibling control VA
      kitchen sink sample kitchen sink control VA

      each of the above VA: with and without peer controls
    */
    //----------------------------------------------------------------------------
    di "outcome sample: `sample'"
    foreach outcome in enr enr_2year enr_4year {
      di "dependent var: `outcome'"
      foreach control of local `sample'_sample_controls {
        di "VA control: `control'"
        // loop over VA estimates without peer and with peer controls
        forvalues i = 1/2 {
          if `i'==1 {
            local peer
          }
          if `i'==2 {
            local peer _p
          }

          di "peer controls in VA estimates (empty if no peer, _p if peer): `peer'"

          //-------------------------------------------------------------
          // enrollment on DK VA, matching left and right hand side outcome
          //-------------------------------------------------------------

          // only base controls in the regression
          reg `outcome' va_dk_`outcome'_`sample'_sp_`control'_ct`peer' ///
            i.year `b_controls' ///
            , cluster(school_id)

          estadd ysumm, mean

          estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_dk_`outcome'_`sample'_sp_`control'_ct`peer'.ster, replace

          // match controls to the VA estimation controls
          if "`peer'"=="" {
            reg `outcome' va_dk_`outcome'_`sample'_sp_`control'_ct`peer' ///
              i.year ``control'_spec_controls' ///
              , cluster(school_id)

              estadd ysumm, mean
              estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_dk_`outcome'_`sample'_sp_`control'_ct`peer'_m.ster, replace
          }
          if "`peer'"=="_p" {
            reg `outcome' va_dk_`outcome'_`sample'_sp_`control'_ct`peer' ///
              i.year ``control'_spec_controls' ///
              `peer_`control'_controls' ///
              , cluster(school_id)

              estadd ysumm, mean
              estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_dk_`outcome'_`sample'_sp_`control'_ct`peer'_m.ster, replace
          }


          //-------------------------------------------------------------
          // heterogeneity by prior score decile
          //-------------------------------------------------------------

          foreach prior_subject in ela math {
            di "interaction with prior `prior_subject' score deciles"

            // only base controls in the regression
            reg `outcome' ///
              c.va_dk_`outcome'_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
              i.year `b_controls' ///
              , cluster(school_id)

            estadd ysumm, mean
            estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'.ster, replace

            // match controls to the VA estimation controls
            if "`peer'"=="" {
              reg `outcome' ///
                c.va_dk_`outcome'_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
                i.year ``control'_spec_controls' ///
                , cluster(school_id)

                estadd ysumm, mean
                estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'_m.ster, replace
            }
            if "`peer'"=="_p" {
              reg `outcome' ///
                c.va_dk_`outcome'_`sample'_sp_`control'_ct`peer'#i.prior_`prior_subject'_z_score_xtile ///
                i.year ``control'_spec_controls' ///
                `peer_`control'_controls' ///
                , cluster(school_id)

                estadd ysumm, mean
                estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'_m.ster, replace
            }



          }




        }
      }
    }

  }





}
















local date2 = c(current_date)
local time2 = c(current_time)


di "Start date time /reg_out_va_dk_all.do: `date1' `time1'"
di "End date time: `date2' `time2'"


cap log close reg_out_va_dk_all
cap translate "$logdir/va/reg_out_va_dk_all.smcl" ///
  "$logdir/va/reg_out_va_dk_all.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
