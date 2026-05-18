/*------------------------------------------------------------------------------
do/va/reg_out_va_all_tab.do — Phase 1a §3.3 step 3 batch 3c2 relocation
================================================================================

PURPOSE
    Build paper-shipping CSV tables of outcome-VA regressions (single-subject + both-subjects). Reads .ster from reg_out_va_all.do; writes esttab CSVs to $tables_dir/va_cfr_all_v[12]/reg_out_va/.

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after batch 3c1 utilities.

OUTPUTS (CANONICAL per ADR-0021 sandbox)
    $tables_dir/va_cfr_all_v[12]/reg_out_va/{reg_<outcome>_va,reg_out_va_ela_math,het_reg_<...>}.csv
    $logdir/va/reg_out_va_all_tab.smcl + .log

RELOCATION (per plan v3 §3.3 step 3 batch 3c2, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/sbac/reg_out_va_all_tab.do
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
/* create tables for regressions of enrollment outcomes on test score VA from
the second round of VA estimates. Samples: base and kitchen sink  */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun November 20, 2022
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/sbac/reg_out_va_all_tab.do
 */

/* CHANGE LOG:
12/08/2022: added models with most saturated controls in non-het tables
12/14/2022: remove kitchen sink sample + loscores and sibling controls; add
columns for regressions with matching controls in the second stage

12/29/2022: added loop for v1 and v2 versions of VA samples
v1: original prior score controls for ELA and Math
v2: same prior score controls for ELA and math
 */

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/va_cfr_all_v1"
cap mkdir "$tables_dir/va_cfr_all_v1/reg_out_va"
cap mkdir "$tables_dir/va_cfr_all_v2"
cap mkdir "$tables_dir/va_cfr_all_v2/reg_out_va"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cd $vaprojdir

cap log close reg_out_va_all_tab
clear all

log using "$logdir/va/reg_out_va_all_tab.smcl", replace text name(reg_out_va_all_tab)

di as text _n "{hline 80}"
di as text "reg_out_va_all_tab.do — RUN START: `c(current_date)' `c(current_time)'"
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
local las_sample_controls b a las

//macros for esttab options
#delimit ;

local esttab_format_keep
  replace se(%4.3f) b(%5.3f) keep(va_*)
  ;

local esttab_format
replace se(%4.3f) b(%5.3f)
;

local esttab_order_va
  order(va_*)
  ;

local esttab_order_het
  order(?.prior*va*)
  ;

local esttab_scalars
	scalars(
  va_peer_controls
  reg_controls
  va_sample
  va_control
	"ymean Y Mean"
	"r2 $ R^2 $"
	)
	sfmt(
	%12.3gc
	%12.3g
	%12.3gc
	)
	;

local esttab_mtitles
  mtitles(
    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"

    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"
)
  ;

local esttab_mgroups
  mgroups( "Base Sample Base Controls"
  "Kitchen Sink Sample Base Controls"
  "Kitchen Sink Sample Kitchen Sink Controls"
  "Base Sample Base Controls"
  "Kitchen Sink Sample Base Controls"
  "Kitchen Sink Sample Kitchen Sink Controls",
  pattern(
    1 0 0 0 1 0 0 0 1 0 0 0
    1 0 0 0 1 0 0 0 1 0 0 0
  ) )
  ;


local esttab_mtitles_both_subjects
  mtitles(
    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"

    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"

    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"
    "No Peer" "No Peer" "Peer" "Peer"

  )
  depvars
  ;

local esttab_mgroups_both_subjects
  mgroups(
    "Base Sample Base Controls"
    "Kitchen Sink Sample Base Controls"
    "Kitchen Sink Sample Kitchen Sink Controls"
    "Base Sample Base Controls"
    "Kitchen Sink Sample Base Controls"
    "Kitchen Sink Sample Kitchen Sink Controls"
    "Base Sample Base Controls"
    "Kitchen Sink Sample Base Controls"
    "Kitchen Sink Sample Kitchen Sink Controls"
  ,
  pattern(
    1 0 0 0 1 0 0 0 1 0 0 0
    1 0 0 0 1 0 0 0 1 0 0 0
    1 0 0 0 1 0 0 0 1 0 0 0
    )
  )
  ;

#delimit cr

/* set trace on */

foreach version in v1 v2 {

  //------------------------------------------------------------------------------
  // enrollment on single subject test score VA
  //------------------------------------------------------------------------------

  foreach outcome in enr enr_2year enr_4year {
    di "outcome: `outcome'"

    foreach subject in ela math {
      di "subject: `subject'"

      foreach sample in b las {
        di "outcome sample: `sample'"

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

            // base controls in the second stage
            estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'.ster
            estadd local va_peer_controls "`peer_yn'"
            estadd local reg_controls "base"
            estadd local va_sample "``sample'_str'"
            estadd local va_control "``control'_str'"
            eststo


            // matching controls in the second stage
            estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample'_sp_`control'_ct`peer'_m.ster
            estadd local va_peer_controls "`peer_yn'"
            estadd local reg_controls "match VA"
            estadd local va_sample "``sample'_str'"
            estadd local va_control "``control'_str'"
            eststo

            local renamelist `renamelist' va_`subject'_`sample'_sp_`control'_ct`peer' va_`subject'

          }
        }

      }

      /* // add the most saturated VA model with most saturated regression controls
      estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_las_sp_las_ct_p_m.ster
      estadd local va_peer_controls "Y"
      estadd local reg_controls "match VA"
      eststo

      local renamelist `renamelist' va_`subject'_las_sp_las_ct_p va_`subject' */

    }

    #delimit ;
    esttab using
      $tables_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va.csv
      , `esttab_format_keep' `esttab_order_va' `esttab_scalars' `esttab_mgroups' `esttab_mtitles'
      rename(`renamelist')
      title("Regressing ``outcome'_str' on Score VA")
      ;
    #delimit cr

    eststo clear

    macro drop _renamelist
  }



  //------------------------------------------------------------------------------
  // enrollment on both subject test score VAs
  //------------------------------------------------------------------------------


  //----------------------------------------------------------------
  // use estpost to make excel table
  //----------------------------------------------------------------
  foreach outcome in enr enr_2year enr_4year {
    di "outcome: `outcome'"


      foreach sample in b las {
        di "outcome sample: `sample'"

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

            // base controls in second stage regression
            estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'.ster
            estadd local va_peer_controls "`peer_yn'"
            estadd local reg_controls "base"
            estadd local va_sample "``sample'_str'"
            estadd local va_control "``control'_str'"
            eststo

            // matching controls in second stage regression
            estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample'_sp_`control'_ct`peer'_m.ster
            estadd local va_peer_controls "`peer_yn'"
            estadd local reg_controls "match VA"
            estadd local va_sample "``sample'_str'"
            estadd local va_control "``control'_str'"
            eststo

            local renamelist `renamelist' va_ela_`sample'_sp_`control'_ct`peer' va_ela va_math_`sample'_sp_`control'_ct`peer' va_math




          }
        }

      }
  /*
      // add the most saturated VA model with most saturated regression controls
      estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_las_sp_las_ct_p_m.ster
      estadd local va_peer_controls "Y"
      estadd local reg_controls "match VA"
      eststo

      local renamelist `renamelist' ///
        va_ela_las_sp_las_ct_p va_ela ///
        va_math_las_sp_las_ct_p va_math
   */


  }

  #delimit ;
  esttab using
    $tables_dir/va_cfr_all_`version'/reg_out_va/reg_out_va_ela_math.csv
    , `esttab_format_keep' `esttab_order_va' `esttab_scalars' `esttab_mgroups_both_subjects' `esttab_mtitles_both_subjects'
    rename(`renamelist')
    title("Regressing Enrollment on Both ELA and Math VA")
    ;
  #delimit cr

  eststo clear

  macro drop _renamelist


  //------------------------------------------------------------------------------
  // enrollment on single subject test score VA, heterogeneity by prior score decile
  //------------------------------------------------------------------------------

  /* foreach outcome in enr enr_2year enr_4year {
    di "outcome: `outcome'"

    foreach subject in ela math {
      di "subject: `subject'"

      foreach prior_subject in ela math {
        di "prior subject: `prior_subject'"

        foreach sample in b las {
          di "outcome sample: `sample'"

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


              estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'.ster
              estadd local va_peer_controls "`peer_yn'"
              estadd local va_sample "``sample'_str'"
              estadd local va_control "``control'_str'"
              eststo





            }
          }

        }


          #delimit ;
          esttab using
            $tables_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'.csv
            , `esttab_format' `esttab_order_het' `esttab_scalars' `esttab_mgroups' `esttab_mtitles'
            title("Regressing ``outcome'_str' on `subject' VA interaction with prior `prior_subject'")
            ;
          #delimit cr

          eststo clear


      }



    }

  }
 */


  //------------------------------------------------------------------------------
  // enrollment on both subject test score VA, heterogeneity by prior score decile
  //------------------------------------------------------------------------------

  /* foreach outcome in enr enr_2year enr_4year {
    di "outcome: `outcome'"


      foreach prior_subject in ela math {
        di "prior subject: `prior_subject'"

        foreach sample in b las {
          di "outcome sample: `sample'"

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


              estimates use $estimates_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_ela_math_x_prior_`prior_subject'_`sample'_sp_`control'_ct`peer'.ster
              estadd local va_peer_controls "`peer_yn'"
              estadd local va_sample "``sample'_str'"
              estadd local va_control "``control'_str'"
              eststo





            }
          }

        }


          #delimit ;
          esttab using
            $tables_dir/va_cfr_all_`version'/reg_out_va/het_reg_`outcome'_va_ela_math_x_prior_`prior_subject'.csv
            , `esttab_format' `esttab_order_het' `esttab_scalars' `esttab_mgroups' `esttab_mtitles'
            title("Regressing ``outcome'_str' on ELA and Math VA interaction with prior `prior_subject'")
            ;
          #delimit cr

          eststo clear


      }


  } */


}



set trace off


local date2 = c(current_date)
local time2 = c(current_time)


di "Start date time /reg_out_va_all_fig.do: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close reg_out_va_all_tab
cap translate "$logdir/va/reg_out_va_all_tab.smcl" ///
  "$logdir/va/reg_out_va_all_tab.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
