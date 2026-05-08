********************************************************************************
/* regress enrollment outcomes on deep knowledge VA estimates (4 specifications)
from the Sibling acs restricted sample to study test score VA persistence. */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 4, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/reg_out_va_sib_acs_dk

 */

/* CHANGE LOG
5/10/2022: Added code for regressing outcome on dk VA interactedsf with
prior score deciles
6/2/2022: Updated code to use prior score deciles from original sample

*/

clear all
set more off
set varabbrev off
set scheme s1color
//capture log close: Stata should not complain if there is no log open to close
cap log close _all

/* set trace on
set tracedepth 2 */

//starting log file
log using $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_dk.smcl, replace

/* change directory to common_core_va project directory for all value added
do files because some called subroutines written by Matt may use relative file paths  */
cd $vaprojdir

/* file path macros for datasets */
include $projdir/do/share/siblingvaregs/vafilemacros.doh

//run Matt's do helper file to set the local macros for VA project
include $vaprojdir/do_files/sbac/macros_va.doh

macro list

//startomg timer
timer on 1


********************************************************************************
* begin main code

// load the resctricted outcome sample with sibling and acs controls
use $vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta, clear

// merge in dk VA dataset
foreach outcome in enr enr_2year enr_4year {
  //merge to test score VA estimates dataset
  merge m:1 cdscode year using ///
   $vaprojdir/data/sib_acs_restr_smp/outcome_va/va_`outcome'_sib_acs_dk.dta ///
   , nogen keep(1 3) keepusing(va_*)
 // standardize the VA estimates into z scores
 foreach va of varlist va_* {
   sum `va'
   replace `va' = `va' - r(mean)
   replace `va' = `va' / r(sd)
 }
}

********** regress enrollment outcomes on all 3 deep knowledge outcome value added
/* no tfx, no peer effects */

foreach outcome in enr enr_2year enr_4year {
  di "LHS = `outcome', RHS = All 3 enrollment outcomes"

  //regressing on all 3 outcome VA's
  foreach control in og acs sib both {
    di "Deep Knowledge VA with `control' controls"

    reg `outcome' va_enr_`control'_dk va_enr_2year_`control'_dk va_enr_4year_`control'_dk ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
      if touse_enr_dk==1 & touse_enr_2year_dk==1 & touse_enr_4year_dk==1 ///
      , cluster(school_id)
    //add mean of yvar to stored results
    estadd ysumm, mean
    estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_allenr_`control'_dk.ster, replace
  }
}


********** regress enrollment outcomes on deep knowledge VA, matching outcomes on LHS and RHS
/* no tfx, no peer effects */

foreach outcome in enr enr_2year enr_4year {
  di "LHS = `outcome'"

  foreach control in og acs sib both {
        di "RHS: Deep Knowledge VA with `control' controls"

        reg `outcome' va_`outcome'_`control'_dk ///
          i.year ///
          `school_controls' ///
          `demographic_controls' ///
          `ela_score_controls' ///
          `math_score_controls' ///
          if touse_`outcome'_dk==1 ///
          , cluster(school_id)
        //add mean of yvar to stored results
        estadd ysumm, mean
        estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_`outcome'_`control'_dk.ster, replace
  }
}




********** regress enrollment outcomes on dk va interacted with prior score deciles
/* no tfx, no peer effects, matching outcome on LHS and RHS */

//merge on prior score quantiles
merge m:1 state_student_id using ///
  $vaprojdir/data/sbac/prior_decile_original_sample.dta, keep(1 3)

// 3 outcomes, 4 DK VA specifications, 2 prior subjects = 24 regressions
foreach outcome in enr enr_2year enr_4year {
    di "LHS = `outcome'"

    foreach control in og acs sib both {
      di "RHS DK VA: Deep Knowledge VA with `control' controls"

      foreach prior_subject in ela math {
        di "interaction with prior `prior_subject' score deciles "

        reg `outcome' c.va_`outcome'_`control'_dk#i.prior_`prior_subject'_z_score_xtile ///
          i.year ///
          `school_controls' ///
          `demographic_controls' ///
          `ela_score_controls' ///
          `math_score_controls' ///
          if touse_`outcome'_dk==1 ///
          , cluster(cdscode)
        estadd ysumm, mean

        estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_`outcome'_`control'_dk_x_prior_`prior_subject'.ster, replace

      }
    }
}





timer off 1
timer list

set trace off
cd $projdir
log close
translate $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_dk.smcl $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_dk.log, replace
