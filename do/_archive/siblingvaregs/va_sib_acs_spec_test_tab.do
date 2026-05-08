********************************************************************************
/* do file to create a regression output table for spec tests for test score VA
and outcome VA on the sibling census restricted sample. 4 VA specifications */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
*********************** First written on May 3, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sib_acs_spec_test_tab.do

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
log using $projdir/log/share/siblingvaregs/va_sib_acs_spec_test_tab.smcl, replace

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

********** test score VA spec test
foreach subject in ela math {
  // primary specification without sibling or acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/spec_test_`subject'_og.ster
  eststo
  test _b[va_`subject'_og] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`subject'_og
  estadd matrix test_p = test_p

  // without sibling controls, with acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/spec_test_`subject'_acs.ster
  eststo
  test _b[va_`subject'_acs] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`subject'_acs
  estadd matrix test_p = test_p

  // with sibling controls, without acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/spec_test_`subject'_sib.ster
  eststo
  test _b[va_`subject'_sib] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`subject'_sib
  estadd matrix test_p = test_p

  // with both sibling controls and acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/spec_test_`subject'_both.ster
  eststo
  test _b[va_`subject'_both] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`subject'_both
  estadd matrix test_p = test_p

}


  esttab using ///
    $projdir/out/csv/siblingvaregs/spec_test/sib_acs_restr_smp/spec_test_sib_acs_restr_smp_score.csv ///
    , replace nonumbers  ///
    cells(b(fmt(%5.3f) pvalue(test_p) star) se(fmt(%4.3f) par)) ///
    title("Specification Tests for Test Score VA on Sibling Census Restricted Sample") ///
    mtitles("Original Specification" "Census Controls" ///
      "Sibling Controls" "Sibling and Census Controls" ///
      "Original Specification" "Census Controls" ///
      "Sibling Controls" "Sibling and Census Controls") ///
    mgroups("ELA" "Math", pattern(1 0 0 0 1 0 0 0) )

  eststo clear


********** outcome VA spec test
foreach outcome in enr enr_2year enr_4year {
  // primary specification without sibling or acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_og.ster
  eststo
  test _b[va_`outcome'_og] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`outcome'_og
  estadd matrix test_p = test_p

  // without sibling controls, with acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_acs.ster
  eststo
  test _b[va_`outcome'_acs] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`outcome'_acs
  estadd matrix test_p = test_p

  // with sibling controls, without acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_sib.ster
  eststo
  test _b[va_`outcome'_sib] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`outcome'_sib
  estadd matrix test_p = test_p

  // with both sibling controls and acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_both.ster
  eststo
  test _b[va_`outcome'_both] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`outcome'_both
  estadd matrix test_p = test_p

}

esttab using ///
  $projdir/out/csv/siblingvaregs/spec_test/sib_acs_restr_smp/spec_test_sib_acs_restr_smp_outcome.csv ///
  , replace nonumbers  ///
  cells(b(fmt(%5.3f) pvalue(test_p) star) se(fmt(%4.3f) par)) ///
  title("Specification Tests for outcome VA on Sibling Census Restricted Sample") ///
  mtitles("Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ///
    "Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ///
    "Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ) ///
  mgroups("Overall Enrollment" "2 Year Enrollment" "4 Year Enrollment", pattern(1 0 0 0 1 0 0 0 1 0 0 0) )

eststo clear



********** deep knowledge outcome VA spec test
foreach outcome in enr enr_2year enr_4year {
  // primary specification without sibling or acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_og_dk.ster
  eststo
  test _b[va_`outcome'_og_dk] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`outcome'_og_dk
  estadd matrix test_p = test_p

  // without sibling controls, with acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_acs_dk.ster
  eststo
  test _b[va_`outcome'_acs_dk] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`outcome'_acs_dk
  estadd matrix test_p = test_p

  // with sibling controls, without acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_sib_dk.ster
  eststo
  test _b[va_`outcome'_sib_dk] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`outcome'_sib_dk
  estadd matrix test_p = test_p

  // with both sibling controls and acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_both_dk.ster
  eststo
  test _b[va_`outcome'_both_dk] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_`outcome'_both_dk
  estadd matrix test_p = test_p

}


esttab using ///
  $projdir/out/csv/siblingvaregs/spec_test/sib_acs_restr_smp/spec_test_sib_acs_restr_smp_outcome_dk.csv ///
  , replace nonumbers  ///
  cells(b(fmt(%5.3f) pvalue(test_p) star) se(fmt(%4.3f) par)) ///
  title("Specification Tests for Deep Knowledge VA on Sibling Census Restricted Sample") ///
  mtitles("Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ///
    "Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ///
    "Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ) ///
  mgroups("Overall Enrollment" "2 Year Enrollment" "4 Year Enrollment", pattern(1 0 0 0 1 0 0 0 1 0 0 0) )

eststo clear








timer off 1
timer list

set trace off

//change directory back to my own personal directory
cd $projdir

log close
translate $projdir/log/share/siblingvaregs/va_sib_acs_spec_test_tab.smcl $projdir/log/share/siblingvaregs/va_sib_acs_spec_test_tab.log, replace
