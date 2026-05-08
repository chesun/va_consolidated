********************************************************************************
/* do file to create output tables for the regression coefficients from the
vam regressions for test score VA and outcome VA on the sibling census
 restricted sample. 4 specifications  */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 3, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sib_acs_vam_tab

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
log using $projdir/log/share/siblingvaregs/va_sib_acs_vam_tab.smcl, replace

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

********** test score VA coefficients table
foreach subject in ela math {
  // primary specification without sibling or acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/vam_`subject'_og.ster
  eststo

  // primary specification without sibling control, with acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/vam_`subject'_acs.ster
  eststo

  // primary specification with sibling controls, withohut acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/vam_`subject'_sib.ster
  eststo

  // primary specification with sibling and acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/test_score_va/vam_`subject'_both.ster
  eststo
}

esttab using ///
  $projdir/out/csv/siblingvaregs/vam/sib_acs_restr_smp/test_score_sib_acs_restr_smp_vam.csv ///
  , replace nonumbers se(%4.3f) b(%5.3f) ///
  title("VAM Output for Test Score VA on Sibling Census Restricted Sample") ///
  mtitles("Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ///
    "Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls") ///
  mgroups("ELA" "Math", pattern(1 0 0 0 1 0 0 0) )


 eststo clear



********** outcome VA coefficients table
foreach outcome in enr enr_2year enr_4year {
  // primary specification without sibling or acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_og.ster
  eststo

  // primary specification without sibling control, with acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_acs.ster
  eststo

  // primary specification with sibling controls, withohut acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_sib.ster
  eststo

  // primary specification with sibling and acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_both.ster
  eststo
}


esttab using ///
  $projdir/out/csv/siblingvaregs/vam/sib_acs_restr_smp/outcome_sib_acs_restr_smp_vam.csv ///
  , replace nonumbers se(%4.3f) b(%5.3f) ///
  title("VAM Output for Outcome VA on Sibling Census Restricted Sample") ///
  mtitles("Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ///
    "Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ///
    "Original Specification" "Census Controls" ///
    "Sibling Controls" "Sibling and Census Controls" ) ///
  mgroups("Overall Enrollment" "2 Year Enrollment" "4 Year Enrollment", pattern(1 0 0 0 1 0 0 0 1 0 0 0) )

eststo clear



********** outcome deep knowledge VA coefficients
foreach outcome in enr enr_2year enr_4year {
  // primary specification without sibling or acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_og_dk.ster
  eststo

  // primary specification without sibling control, with acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_acs_dk.ster
  eststo

  // primary specification with sibling controls, withohut acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_sib_dk.ster
  eststo

  // primary specification with sibling and acs controls
  estimates use ///
    $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_both_dk.ster
  eststo
}

esttab using ///
  $projdir/out/csv/siblingvaregs/vam/sib_acs_restr_smp/outcome_dk_sib_acs_restr_smp_vam.csv ///
  , replace nonumbers se(%4.3f) b(%5.3f) ///
  title("VAM Output for Deep Knowledge Outcome VA on Sibling Census Restricted Sample") ///
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
translate $projdir/log/share/siblingvaregs/va_sib_acs_vam_tab.smcl $projdir/log/share/siblingvaregs/va_sib_acs_vam_tab.log, replace
