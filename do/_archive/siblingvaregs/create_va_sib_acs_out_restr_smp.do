********************************************************************************
/* do file to create college enrollment VA restricted sample that
only has observations with sibling controls and ACS controls. */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 2. 2022 *************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/create_va_sib_acs_out_restr_smp

 */


/* CHANGE LOG:

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
log using $projdir/log/share/siblingvaregs/create_va_sib_acs_out_restr_smp.smcl, replace

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

//load the outcome VA grade 11 sample
use `va_g11_out_dataset', clear

//merge on to sibling outcomes crosswalk to get sibling enrollment controls
merge m:1 state_student_id using `sibling_out_xwalk', nogen keep(1 3)


// keep the sibling controls sample for 2yr and 4yr sibling enrollment controls
keep if sibling_2y_4y_controls_sample==1

compress
label data "Outcome VA with Sibling Control Sample"
tempfile va_g11_out_sibling_dataset
save `va_g11_out_sibling_dataset'

// call do helper file to merge onto ACS controls. Be sure to specify correct arguments
do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh outcome `va_g11_out_sibling_dataset' va_g11_out_sibling_dataset create_sample none


//merge on test score VA to create deep knowledge VA sample
foreach outcome in enr enr_2year enr_4year {
  foreach subject in ela math {
    //merge in the test score VA from the sibling ACS restricted sample
    merge m:1 cdscode year using ///
    $vaprojdir/data/sib_acs_restr_smp/test_score_va/va_`subject'_sib_acs.dta, ///
    nogen keep(1 3) keepusing(va_`subject'_*)

    //create to use indicator for outcome subject combinations
    gen touse_`outcome'_`subject'_og = touse_g11_`outcome'
    // indicator equals 1 for obs in the to use outcome sample, and with nonmissing subject VA
    replace touse_`outcome'_`subject'_og = 0 if mi(va_`subject'_og)
  }

  // deep knowledge touse indicator using the original specification test score VA
  gen touse_`outcome'_dk = 0
  // dk touse indicator equals 1 if obs is in outcome VA sample and both ela and math VA are nonmissing
  replace touse_`outcome'_dk = 1 if touse_`outcome'_ela_og == 1 & touse_`outcome'_math_og == 1
}






// saving the restricted sample dataset
compress
label data "Outcome VA Restrcited Sample with Sibling Controls and Census Controls"
save $vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta, replace







timer off 1
timer list

set trace off

//change directory back to my own personal directory
cd $projdir 

log close
translate $projdir/log/share/siblingvaregs/create_va_sib_acs_out_restr_smp.smcl $projdir/log/share/siblingvaregs/create_va_sib_acs_out_restr_smp.log, replace
