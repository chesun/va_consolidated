********************************************************************************
/* create a regression output table for forecast bias tests for test score VA,
outcome VA and DK VA  on the sibling census restricted sample. 4 VA specifications */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
*********************** First written on May 7, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sib_acs_fb_test_tab.do

 */


/* CHANGE LOG

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
log using $projdir/log/share/siblingvaregs/va_sib_acs_fb_test_tab.smcl, replace

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
*start main code


********* test score VA forecast bias test table
foreach subject in ela math {
  // original specification, leave out var = census controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/fb_test_`subject'_acs_og.ster
  eststo

  // original specification, leave out var = sibling controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/fb_test_`subject'_sib_og.ster
  eststo

  // with census controls, leave out var = sibling controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/fb_test_`subject'_sib_acs.ster
  eststo

  // with sibling controls, leave out var = census controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/fb_test_`subject'_acs_sib.ster
  eststo
}

esttab using ///
  $projdir/out/csv/siblingvaregs/fb_test/sib_acs_restr_smp/fb_test_sib_acs_restr_smp_score.csv ///
  , replace nonumbers se(%4.3f) b(%5.3f) ///
  title("Forecast Bias Tests for Test Score VA on Sibling Census Restricted Sample") ///
  mtitles("Original w/ Census Leave Out" "Original w/ Sibling Leave Out" ///
    "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out" ///
    "Original w/ Census Leave Out" "Original w/ Sibling Leave Out" ///
    "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out" ) ///
  mgroups("ELA" "Math", pattern(1 0 0 0 1 0 0 0) )

eststo clear



********* enrollment outcome VA forecast bias test table
foreach outcome in enr enr_2year enr_4year {
  // original specification, leave out var = census controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_acs_og.ster
  eststo

  // original specification, leave out var = sibling controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_sib_og.ster
  eststo

  // with census controls, leave out var = sibling controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_sib_acs.ster
  eststo

  // with sibling controls, leave out var = census controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_acs_sib.ster
  eststo
}

esttab using ///
  $projdir/out/csv/siblingvaregs/fb_test/sib_acs_restr_smp/fb_test_sib_acs_restr_smp_outcome.csv ///
  , replace nonumbers se(%4.3f) b(%5.3f) ///
  title("Forecast Bias Tests for Outcome VA on Sibling Census Restricted Sample") ///
  mtitles("Original w/ Census Leave Out" "Original w/ Sibling Leave Out" ///
    "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out" ///
    "Original w/ Census Leave Out" "Original w/ Sibling Leave Out" ///
    "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out" ///
    "Original w/ Census Leave Out" "Original w/ Sibling Leave Out" ///
    "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out") ///
  mgroups("Overall Enrollment" "2 Year Enrollment" "4 Year Enrollment", pattern(1 0 0 0 1 0 0 0 1 0 0 0) )

eststo clear



********* deep knowledge outcome VA forecast bias test table
foreach outcome in enr enr_2year enr_4year {
  // original specification, leave out var = census controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_acs_og_dk.ster
  eststo

  // original specification, leave out var = sibling controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_sib_og_dk.ster
  eststo

  // with census controls, leave out var = sibling controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_sib_acs_dk.ster
  eststo

  // with sibling controls, leave out var = census controls
  estimates use $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_acs_sib_dk.ster
  eststo
}


esttab using ///
  $projdir/out/csv/siblingvaregs/fb_test/sib_acs_restr_smp/fb_test_sib_acs_restr_smp_outcome_dk.csv ///
  , replace nonumbers se(%4.3f) b(%5.3f) ///
  title("Forecast Bias Tests for Deep Knowledge VA on Sibling Census Restricted Sample") ///
  mtitles("Original w/ Census Leave Out" "Original w/ Sibling Leave Out" ///
    "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out" ///
    "Original w/ Census Leave Out" "Original w/ Sibling Leave Out" ///
    "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out" ///
    "Original w/ Census Leave Out" "Original w/ Sibling Leave Out" ///
    "Census w/ Sibling Leave Out" "Sibling w/ Census Leave Out") ///
  mgroups("Overall Enrollment" "2 Year Enrollment" "4 Year Enrollment", pattern(1 0 0 0 1 0 0 0 1 0 0 0) )

eststo clear





timer off 1
timer list

set trace off
cd $projdir

log close
translate $projdir/log/share/siblingvaregs/va_sib_acs_fb_test_tab.smcl $projdir/log/share/siblingvaregs/va_sib_acs_fb_test_tab.log, replace
