********************************************************************************
/* output regression estimates from regressing enrollment outcomes on test score
VA from the restricted sibling census sample to csv files */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 10, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/reg_out_va_sib_acs_tab

 */

/* CHANGE LOG

*/

clear all
graph drop _all
set more off
set varabbrev off
set scheme s1color
//capture log close: Stata should not complain if there is no log open to close
cap log close _all

/* set trace on
set tracedepth 2 */

//starting log file
log using $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_tab.smcl, replace

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

//macros for esttab options
#delimit ;

local esttab_format
  replace nonumbers se(%4.3f) b(%5.3f)
  ;

local esttab_order_va
  order(va_*)
  ;

local esttab_order_het
  order(?.prior*va*)
  ;

local esttab_scalars
	scalars(
	"ymean Y Mean"
	"r2 $ R^2 $"
	"N Observations"
	)
	sfmt(
	%12.3gc
	%12.3g
	%12.3gc
	)
	noobs
	;

local esttab_mtitles
  mtitles("Original w/ Census Leave Out" "Original w/ Sibling Leave Out"
  "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out"
  "Original w/ Census Leave Out" "Original w/ Sibling Leave Out"
  "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out"
  "Original w/ Census Leave Out" "Original w/ Sibling Leave Out"
  "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out")
  ;

local esttab_mgroups
  mgroups( "Overall Enrollment" "2 Year Enrollment" "4 Year Enrollment",
  pattern(1 0 0 0 1 0 0 0 1 0 0 0) )
  ;

#delimit cr


********** estimates from regressing enrollment on test score VA
/* no peer effectsm no tfx */

// only one subject test score VA on the RHS
foreach subject in ela math {
  di "only `subject' VA on the RHS"

  foreach outcome in enr enr_2year enr_4year {
    di "Dependent Var = `outcome'"

    foreach control in og acs sib both {
      di "RHS = `subject' test score VA with `control' controls"

      estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_`subject'_`control'.ster
      eststo
    }
  }

  esttab using ///
    $projdir/out/csv/siblingvaregs/persistence/sib_acs_restr_smp/reg_out_score_va/reg_outcome_va_`subject'.csv ///
    , `esttab_format' `esttab_order_va' `esttab_scalars' `esttab_mtitles' `esttab_mgroups' ///
    title ("Regression of Outcome on ``subject'_str' VA on Sibling Census Restricted Sample")

  eststo clear
}



/*

// only math score VA on the RHS
foreach outcome in enr enr_2year enr_4year {
  di "Dependent Var = `outcome'"

  foreach control in og acs sib both {
    di "test score VA with `control' controls"

    estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_math_`control'.ster
    eststo
  }
}

esttab using ///
  $projdir/out/csv/siblingvaregs/persistence/sib_acs_restr_smp/reg_outcome_va_math.csv ///
  , `esttab_format' `esttab_scalars' `esttab_mtitles' `esttab_mgroups' ///
  title ("Regression of Outcome on Math VA on Sibling Census Restricted Sample")

eststo clear */



// both ELA and math VA on RHS
foreach outcome in enr enr_2year enr_4year {
  di "Dependent Var = `outcome'"

  foreach control in og acs sib both {
    di "test score VA with `control' controls"

    estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_ela_math_`control'.ster
    eststo
  }
}

esttab using ///
  $projdir/out/csv/siblingvaregs/persistence/sib_acs_restr_smp/reg_out_score_va/reg_outcome_va_ela_math.csv ///
  , `esttab_format' `esttab_order_va' `esttab_scalars' `esttab_mtitles' `esttab_mgroups' ///
  title ("Regression of Outcome on ELA and Math VA on Sibling Census Restricted Sample")

eststo clear





********** estimates from regressing outcome on test score VA interacted with prior score deciles
/* no peer effectsm no tfx */

// estimates from regressing outcome on single subject test score VA interacted with prior score decile by subject

foreach subject in ela math {
  di "RHS VA Subject = `subject'"

  foreach prior_subject in ela math {
    di "interaction with prior `prior_subject' score deciles"

    foreach outcome in enr enr_2year enr_4year {
      di "Dependent Var = `outcome'"

      foreach control in og acs sib both {
        di "VA with `control' controls"

        estimates use ///
          $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'.ster
        eststo
      }
    }

    esttab using ///
      $projdir/out/csv/siblingvaregs/persistence/sib_acs_restr_smp/reg_out_score_va/het_reg_outcome_va_`subject'_x_prior_`prior_subject'.csv ///
      , `esttab_format' `esttab_order_het' `esttab_scalars' `esttab_mtitles' `esttab_mgroups' ///
      title ("Regression of Outcome on ``subject'_str' VA interacted with prior `prior_subject' score deciles on Sibling Census Restricted Sample")

    eststo clear
  }
}


// both subject VA interacted with prior score deciles by subject
foreach prior_subject in ela math {
  di "interaction with prior `prior_subject' score deciles"

  foreach outcome in enr enr_2year enr_4year {
    di "Dependent Var = `outcome'"

    foreach control in og acs sib both {
      di "VA with `control' controls"

      estimates use ///
        $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_ela_math_`control'_x_prior_`prior_subject'.ster
      eststo
    }
  }

  esttab using ///
    $projdir/out/csv/siblingvaregs/persistence/sib_acs_restr_smp/reg_out_score_va/het_reg_outcome_va_ela_math_x_prior_`prior_subject'.csv ///
    , `esttab_format' `esttab_order_het' `esttab_scalars' `esttab_mtitles' `esttab_mgroups' ///
    title ("Regression of Outcome on both ELA and Math VA interacted with prior `prior_subject' score deciles on Sibling Census Restricted Sample")

  eststo clear
}




timer off 1
timer list

cd $projdir
set trace off

log close
translate $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_tab.smcl $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_tab.log, replace
