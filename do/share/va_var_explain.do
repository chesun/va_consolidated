/*------------------------------------------------------------------------------
do/share/va_var_explain.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    variance-explained regression by VA component.  Paper producer (figures + tables) for the VA paper.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Reads CHAIN VA outputs from $estimates_dir/va_cfr_all_<version>/<x>
    (Step 3 batches 3a-3d) + sample data from LEGACY $vaprojdir/data/
    va_samples_v1/<x> (sample data not yet relocated; out of Step 10 scope).
    Writes paper-shipping outputs to $tables_dir/share/<x> + $figures_dir/share/<x>
    (CANONICAL).

INPUTS (verified via grep on file body)
    $consolidated_dir/do/va/helpers/macros_va.doh  (helper include)
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'.dta  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`va_ctrl'_ct.ster  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`va_ctrl'_ct_p.ster  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/va_est_dta/va_`outcome'_`sample'_sp_`va_ctrl'_ct.dta  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/va_var_explain.smcl (via log using)
    $logdir/share/va_var_explain.smcl + $logdir/share/va_var_explain.log (translate)
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'.dta
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/va_var_explain.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                      -> removed (absolute paths)
      log_files/share/<x>.smcl (rel + abs forms)         -> $logdir/<x>.smcl  (CANONICAL)
      include $vaprojdir/do_files/sbac/<x>.doh           -> include $consolidated_dir/do/{va/helpers,samples}/<x>.doh
        (per Step 1/2 helper relocation; covers macros_va, drift_limit, create_diff_school_prop, create_prior_scores_v1/v2, merge_loscore, merge_sib, merge_lag2_ela, merge_va_smp_acs, create_va_g11_sample_v1/v2, create_va_g11_out_sample_v1/v2)
      $estimates_dir/va_cfr_all_<v>/<x> -> $estimates_dir/va_cfr_all_<v>/<x> (CHAIN read from Step 3)
      $estimates_dir/va_cfr_all_<v>/<x> -> $estimates_dir/va_cfr_all_<v>/<x> (CHAIN read; predecessor stored intermediate regsave dtas under tables/, consolidated relocates under $estimates_dir/)
      $vaprojdir/figures/share/<x> -> $figures_dir/share/<x> (CANONICAL paper-shipping)
      $vaprojdir/tables/share/<x> -> $tables_dir/share/<x> (CANONICAL paper-shipping)
      $vaprojdir/data/va_samples_v1/<x> -> kept LEGACY (sample data; out of Step 10 scope)
      translate (multi-line ABS form) -> $logdir/<x> (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10a
    Sister files (this batch): base_sum_stats_tab.do, kdensity.do, reg_out_va_tab.do, sample_counts_tab.do, svyindex_tab.do, va_scatter.do, va_spec_fb_tab_all.do, va_var_explain_tab.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* school level regressions of enrollment VA on both Math and ELA VA (without controls) to
calculate explained variance */
********************************************************************************

*****************************************************
* First created by Christina Sun May 31, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/va_var_explain.do
*/

/* CHANGE LOG:
07/20/2023: 
1. added kitchen sink with distance to controls in restricted sample 
 */

set tracedepth 1
set trace on

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).

 cap log close _all

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/share"
cap mkdir "$tables_dir/share/va"
cap mkdir "$tables_dir/share/va/check"
cap mkdir "$tables_dir/share/va/pub"
cap mkdir "$estimates_dir"

 log using "$logdir/share/va_var_explain.smcl", replace text

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
 local las_sample_controls b a ls las lasd

// get r^2
foreach version in v1 v2 {
  // load the dataset with all school level VA estimates
  use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta, clear

  // standardize VA estimates into z score
  foreach va of varlist va_* {
    sum `va'
    replace `va' = `va' - r(mean)
    replace `va' = `va' / r(sd)
  }

  foreach sample in b las {
    di "sample: `sample'"

    foreach outcome in enr enr_2year enr_4year {
      di "LHS : `outcome' VA"

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

          di "RHS VA subject: both ELA and math"

          if "`peer'"=="" {
            reg va_`outcome'_`sample'_sp_`control'_ct`peer' ///
              va_ela_`sample'_sp_`control'_ct`peer' ///
              va_math_`sample'_sp_`control'_ct`peer' ///
               [aw=n_g11_`outcome'_`sample'_sp]

            estadd ysumm, mean
            estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'.ster, replace


            regsave using $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'.dta, replace ///
              pval addlabel(outcome, "`outcome' VA", subject, "ELA and Math", sample, `sample', control, `control', peer, `peer_yn')
          }
          if "`peer'"=="_p" {
            reg va_`outcome'_`sample'_sp_`control'_ct`peer' ///
              va_ela_`sample'_sp_`control'_ct`peer' ///
              va_math_`sample'_sp_`control'_ct`peer' ///
               [aw=n_g11_`outcome'_`sample'_sp]

            estadd ysumm, mean
            estimates save $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'.ster, replace


            regsave using $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'.dta, replace ///
              pval addlabel(outcome, "`outcome' VA", subject, "ELA and Math", sample, `sample', control, `control', peer, `peer_yn')
          }





      }


    }

  }
}

//----------------------------------------------------------------
// use regsave to create dta dataset table using regressions from above
// only variance and r2 are of interest
//----------------------------------------------------------------

foreach outcome in enr enr_2year enr_4year {

  local append_macro replace

  di "outcome: `outcome'"
  foreach sample in b las {
    di "outcome sample: `sample'"
    foreach va_ctrl of local `sample'_sample_controls {
      di "VA control: `va_ctrl'"

      //----------------------------------
      // create macros for variance
      //----------------------------------
      // load the VA estimates for the current sample and control combo
      use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_`outcome'_`sample'_sp_`va_ctrl'_ct.dta, clear
      sort school_id year
      xtset school_id year
      //calculate sd of va estimates without peer controls
      sum va_cfr_g11_`outcome'
      local sd_va = r(sd)
      local var_va = (r(sd))^2
      // sd of va estimates with peer controls
      sum va_cfr_g11_`outcome'_peer
      local sd_va_peer = r(sd)
      local var_va_peer = (r(sd))^2


      // calculate sd and var of DK VA estimates without peer controls
      sum va_cfr_g11_`outcome'_dk
      local sd_va_dk = r(sd)
      local var_va_dk = (r(sd))^2
      // with peer controls
      sum va_cfr_g11_`outcome'_dk_peer
      local sd_va_dk_peer = r(sd)
      local var_va_dk_peer = (r(sd))^2

      // dk va variance/total VA variance
      local dk_total_ratio = `var_va_dk'/`var_va'
      local dk_total_ratio_peer = `var_va_dk_peer'/`var_va_peer'


      // load estimates from regressing enrollment VA on both subject VAs, no peer, matching controls in second stage
      estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`va_ctrl'_ct.ster
      /* local r2_reg_out_both: di %4.3f = e(r2) */

      regsave using $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta, ///
        ci addlabel( var_va, `var_va', var_va_dk, `var_va_dk', ///
        dk_total_ratio, `dk_total_ratio', ///
        va_control, `va_ctrl', ///
        va_sample, `sample', outcome, `outcome', peer_controls, 0) `append_macro'

      local append_macro append

      // load estimates from regressing enrollment on both subject VAs, with peer
      estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_ela_math_`sample'_sp_`va_ctrl'_ct_p.ster
      /* local r2_reg_out_both_peer: di %4.3f = e(r2) */

      regsave using $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta, ///
        ci addlabel(var_va,`var_va_peer', var_va_dk, `var_va_dk_peer', ///
        dk_total_ratio, `dk_total_ratio_peer', ///
        va_control, `va_ctrl', ///
        va_sample, `sample', outcome, `outcome', peer_controls, 1) append


    }
  }

  use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta, clear
  drop if var=="_cons"
  gen unexplained=1-r2
  order va_sample va_control peer_controls dk_total_ratio unexplained r2 coef ci_lower ci_upper
  sort va_sample va_control peer_controls
  label var dk_total_ratio "DK variance/outcome VA variance"
  /* gen b2 = coef^2
  gen rho2_sigma2_lambda_ela = b2*var_va */
  save, replace

  di "`outcome' regsave table saved"

}

}





  local date2 = c(current_date)
  local time2 = c(current_time)

  di "Start date time: `date1' `time1'"
  di "End date time: `date2' `time2'"

 log close
 translate $logdir/share/va_var_explain.smcl $logdir/share/va_var_explain.log, replace
