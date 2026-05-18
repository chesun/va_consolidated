/*------------------------------------------------------------------------------
do/va/reg_out_va_dk_all_fig.do — Phase 1a §3.3 step 3 batch 3c2 relocation
================================================================================

PURPOSE
    Build paper-shipping figures of DK VA heterogeneity by prior-score deciles.  Reads .ster from reg_out_va_dk_all.do; writes .gph + .pdf.

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after batch 3c1 utilities.

OUTPUTS (CANONICAL per ADR-0021 sandbox)
    $figures_dir/va_cfr_all_v[12]/{het_reg_dk_prior_score,het_reg_combined_panels/dk_va}/<...>.pdf + $output_dir/gph_files/va_cfr_all_v[12]/het_reg_dk_prior_score/<...>.gph
    $logdir/va/reg_out_va_dk_all_fig.smcl + .log

RELOCATION (per plan v3 §3.3 step 3 batch 3c2, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/sbac/reg_out_va_dk_all_fig.do
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
/* create figures for regressions of enrollment outcomes on Deep Knowledge VA from
the second round of VA estimates, heterogeneity by prior score deciles.
Samples: base and kitchen sink  */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun November 20, 2022
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/sbac/reg_out_va_dk_all_fig.do
 */

/* CHANGE LOG:
12/14/2022: changed combined panels, added transparency to graphs

12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math
 */

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$figures_dir"
cap mkdir "$figures_dir/va_cfr_all_v1"
cap mkdir "$figures_dir/va_cfr_all_v2"
cap mkdir "$output_dir"
cap mkdir "$output_dir/gph_files"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cd $vaprojdir

cap log close reg_out_va_dk_all_fig

log using "$logdir/va/reg_out_va_dk_all_fig.smcl", replace text name(reg_out_va_dk_all_fig)

di as text _n "{hline 80}"
di as text "reg_out_va_dk_all_fig.do — RUN START: `c(current_date)' `c(current_time)'"
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

  //------------------------------------------------------------------------------
  // assign non-heterogeneity DK regression coefficients to scalars
  //------------------------------------------------------------------------------

  foreach sample in b las {
    di "outcome sample: `sample'"
    foreach control of local `sample'_sample_controls {
      di "VA control: `control'"
      foreach outcome in enr enr_2year enr_4year {
        // matching LHS and RHS outcome
        di "y var: `outcome'. x var: `outcome' dk va"

          // loop over VA estimates without peer and with peer controls
          forvalues i = 1/2 {
            if `i'==1 {
              local peer
            }
            if `i'==2 {
              local peer _p
            }
            di "peer controls in VA estimates (empty if no peer, _p if peer): `peer'"

            // estimate from outcome regs with base controls
            est use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_dk_`outcome'_`sample'_sp_`control'_ct`peer'.ster

            tempname `outcome'_`sample'_`control'`peer'
            scalar ``outcome'_`sample'_`control'`peer'' = _b[va_dk_`outcome'_`sample'_sp_`control'_ct`peer']

            // estimates from outcome regs with matching controls as used in VA estimation
            est use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_dk_`outcome'_`sample'_sp_`control'_ct`peer'_m.ster
            tempname `outcome'_`sample'_`control'`peer'_m
            scalar ``outcome'_`sample'_`control'`peer'_m' = _b[va_dk_`outcome'_`sample'_sp_`control'_ct`peer']

        }
      }
    }
  }


  //------------------------------------------------------------------------------
  // make figures for heterogeneity regression by prior score decile
  //------------------------------------------------------------------------------

  foreach sample in b las {
    di "outcome sample: `sample'"
    foreach control of local `sample'_sample_controls {
      di "VA control: `control'"
      foreach outcome in enr enr_2year enr_4year {
        // matching LHS and RHS outcome
        di "y var: `outcome'. x var: `outcome' dk va"

          // loop over VA estimates without peer and with peer controls
          forvalues i = 1/2 {
            if `i'==1 {
              local peer
              local peer_str "without"
            }
            if `i'==2 {
              local peer _p
              local peer_str "with"
            }
            di "peer controls in VA estimates (empty if no peer, _p if peer): `peer'"

            foreach prior_subject in ela math {
              di "interaction with prior `prior_subject' score decile"


              forvalues i = 1/2 {
                if `i'==1 {
                  local match
                  local match_str "base"
                }
                if `i'==2 {
                  local match _m
                  local match_str "matching"
                }

                est use $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'`match'.ster
                parmest, norestore
                // keep only the interaction parameters
                keep if strpos(parm, "prior_`prior_subject'_z_score_xtile#c.va_dk_`outcome'_`sample'_sp_`control'_ct`peer'") != 0
                // create a var that is the decile number
                gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")-1), "b", "", .)
                // convert xtile var into a numeric var
                destring xtile, replace

                #delimit ;
                twoway
                  (bar estimate xtile, color(%50))
                  (rcap min95 max95 xtile, color(%50))
                  , yline(`=``outcome'_`sample'_`control'`peer'`match''', lcolor(%30))
                  yline(0, lcolor(black%30))
                  yscale(range(0))
                  legend(off)
                  ytitle("Coefficient Estimate")
                  xtitle("Prior ``prior_subject'_str' Score Decile")
                  title("``outcome'_str' on ``outcome'_str' DK VA (`peer_str' peer controls) interacted with w/ prior ``prior_subject'_str' Score Decile"
                  , size(vsmall))
                  subtitle("``sample'_str' sample and ``control'_str' controls", size(vsmall))
                ;
                #delimit cr

                graph export $figures_dir/va_cfr_all_`version'/het_reg_dk_prior_score/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'`match'.pdf, replace




                // redraw the graph again with different titles to be used for combining into panels
                #delimit ;
                twoway
                  (bar estimate xtile, color(%50))
                  (rcap min95 max95 xtile, color(%50))
                  , yline(`=``outcome'_`sample'_`control'`peer'`match''', lcolor(%30))
                  yline(0, lcolor(black%30))
                  yscale(range(0))
                  legend(off)
                  ytitle("Coefficient Estimate")
                  xtitle("Prior ``prior_subject'_str' Score Decile")
                  title("``sample'_str' sample and ``control'_str' controls"
                  , size(vsmall))
                  subtitle("VA `peer_str' peer controls. Reg has `match_str' VA controls", size(vsmall))
                  saving($output_dir/gph_files/va_cfr_all_`version'/het_reg_dk_prior_score/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'`match', replace)
                ;
                #delimit cr


              }




            }


        }
      }
    }
  }


  //------------------------------------------------------------------------------
  // combine figures for heterogeneity regression by prior score decile into panels
  // only include b sample b ct, p/np and las sample las control, p/np
  //------------------------------------------------------------------------------
  foreach outcome in enr enr_2year enr_4year {
    di "y var: `outcome'. x var: `outcome' dk va"
    foreach prior_subject in ela math {
      di "interaction with prior `prior_subject' score decile"

      #delimit ;
      graph combine
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_dk_prior_score/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_b_sp_b_ct.gph
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_dk_prior_score/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_b_sp_b_ct_p_m.gph
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_dk_prior_score/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_las_sp_las_ct.gph
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_dk_prior_score/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_las_sp_las_ct_p_m.gph
        , xcommon ycommon
        title("``outcome'_str' on ``outcome'_str' DK VA interacted with w/ prior ``prior_subject'_str' Score Decile", size(small))
        ;
      #delimit cr

      graph export $figures_dir/va_cfr_all_`version'/het_reg_combined_panels/dk_va/het_reg_`outcome'_va_dk_`outcome'_x_prior_`prior_subject'_combined.pdf, replace



    }
  }

}















local date2 = c(current_date)
local time2 = c(current_time)


di "Start date time /reg_out_va_dk_all_fig.do: `date1' `time1'"
di "End date time: `date2' `time2'"


cap log close reg_out_va_dk_all_fig
cap translate "$logdir/va/reg_out_va_dk_all_fig.smcl" ///
  "$logdir/va/reg_out_va_dk_all_fig.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
