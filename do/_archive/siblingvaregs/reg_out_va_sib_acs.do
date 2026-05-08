********************************************************************************
/* regress enrollment outcomes on test score VA estimates (4 specifications)
from the Sibling acs restricted sample to study test score VA persistence. */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 4, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/reg_out_va_sib_acs

 */

 /* CHANGE LOG
5/10/2022: Added code for regressing outcome on test score VA interactedsf with
prior score deciles
5/22/2022: Added code fo regressions by SED status
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
log using $projdir/log/share/siblingvaregs/reg_out_va_sib_acs.smcl, replace

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

foreach subject in ela math {
  //merge to test score VA estimates dataset
  merge m:1 cdscode year using ///
   $vaprojdir/data/sib_acs_restr_smp/test_score_va/va_`subject'_sib_acs.dta ///
   , nogen keep(1 3) keepusing(va_*)

  // standardize the VA estimates into z scores
  foreach va of varlist va_* {
    sum `va'
    replace `va' = `va' - r(mean)
    replace `va' = `va' / r(sd)
  }
}


********** regress enrollment outcomes on test score value added
/* no peer effectsm no tfx, using the standard controls in primary VA specification */

foreach outcome in enr enr_2year enr_4year {
  // regress outcomes on each test score VA individually
  di "Dependent Var = `outcome'"

  // regressing on single subject VA, 4 VA specifications
  foreach subject in ela math {
    di "Subject = `subject'"

    foreach control in og acs sib both {
      di "test score VA with `control' controls"

      reg `outcome' va_`subject'_`control' ///
        i.year ///
        `school_controls' ///
        `demographic_controls' ///
        `ela_score_controls' ///
        `math_score_controls' ///
        if touse_g11_`subject'==1 ///
        , cluster(school_id)
      //add mean of yvar to stored results
      estadd ysumm, mean
      estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_`subject'_`control'.ster, replace
    }
  }

  //regressing on both subject VAs, 4 VA specifications
  foreach control in og acs sib both {
    di "test score VA with `control' controls"

    reg `outcome' va_ela_`control' va_math_`control' ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
      if touse_g11_ela==1 & touse_g11_math==1 ///
      , cluster(school_id)
    //add mean of yvar to stored results
    estadd ysumm, mean
    estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_ela_math_`control'.ster, replace
  }

}



********** Regress outcome on test score VA: heterogeneity by prior score deciles
/* no peer effectsm no tfx */

//merge on prior score quantiles
merge m:1 state_student_id using ///
  $vaprojdir/data/sbac/prior_decile_original_sample.dta, keep(1 3)


foreach outcome in enr enr_2year enr_4year {
  di "Dependent Var = `outcome'"

  // regress outcomes on single test score VA interacted with prior score decile by subject
  // 3 outcomes, 2 subject VAs, 2 prior scores, 4 VA specifications = 48 regressions
  foreach subject in ela math {
    di "VA Subject = `subject'"

    foreach control in og acs sib both {
      di "`subject' test score VA with `control' controls"

        foreach prior_subject in ela math {
          di "interaction with prior `prior_subject' score deciles"

          reg `outcome' c.va_`subject'_`control'#i.prior_`prior_subject'_z_score_xtile ///
            i.year ///
            `school_controls' ///
            `demographic_controls' ///
            `ela_score_controls' ///
            `math_score_controls' ///
            if touse_g11_`subject'==1 ///
            , cluster(cdscode)
          estadd ysumm, mean

          estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'.ster, replace
      }
    }
  }

  // both subject VA interacted with prior score deciles
  // 3 outcomes, 2 prior subjects, 4 specifications = 24 regressions
  foreach control in og acs sib both {
    di "both ELA and Math VA with `control' controls"

    foreach prior_subject in ela math {
      di "interaction with prior `prior_subject' score deciles"

      reg `outcome' c.va_ela_`control'#i.prior_`prior_subject'_z_score_xtile c.va_math_`control'#i.prior_`prior_subject'_z_score_xtile ///
        i.year ///
        `school_controls' ///
        `demographic_controls' ///
        `ela_score_controls' ///
        `math_score_controls' ///
        if touse_g11_ela==1 & touse_g11_math==1 ///
        , cluster(cdscode)
      estadd ysumm, mean

      estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_ela_math_`control'_x_prior_`prior_subject'.ster, replace

    }

  }
}




********** Regress outcome on test score VA: heterogeneity by priro score by socioeconomic disadvantage status
/* no peer effectsm no tfx */
foreach outcome in enr enr_2year enr_4year {
  di "Dependent Var = `outcome'"

  // regress outcomes on single test score VA interacted with prior score decile by subject by SED status
  // 3 outcomes, 2 subject VAs, 2 prior scores, 2 SED status, 4 VA specifications = 96 regressions
  foreach subject in ela math {
    di "VA Subject = `subject'"

    foreach control in og acs sib both {
      di "`subject' test score VA with `control' controls"

        foreach prior_subject in ela math {
          di "interaction with prior `prior_subject' score deciles"

          // SED = 1
          reg `outcome' c.va_`subject'_`control'#i.prior_`prior_subject'_z_score_xtile ///
            i.year ///
            `school_controls' ///
            `demographic_controls' ///
            `ela_score_controls' ///
            `math_score_controls' ///
            if touse_g11_`subject'==1 & econ_disadvantage==1 ///
            , cluster(cdscode)
          estadd ysumm, mean

          estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'_sed1.ster, replace


          // SED = 0
          reg `outcome' c.va_`subject'_`control'#i.prior_`prior_subject'_z_score_xtile ///
            i.year ///
            `school_controls' ///
            `demographic_controls' ///
            `ela_score_controls' ///
            `math_score_controls' ///
            if touse_g11_`subject'==1 & econ_disadvantage==0 ///
            , cluster(cdscode)
          estadd ysumm, mean

          estimates save $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'_sed0.ster, replace

      }
    }
  }
}




timer off 1
timer list

set trace off
cd $projdir

log close
translate $projdir/log/share/siblingvaregs/reg_out_va_sib_acs.smcl $projdir/log/share/siblingvaregs/reg_out_va_sib_acs.log, replace
