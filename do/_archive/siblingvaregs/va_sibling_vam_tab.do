********************************************************************************
/* do file to create output tables for the regression coefficients from the
vam regressions using sibling test score and postsecondary outcome  VA with
sibling controls  */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on April 14. 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sibling_vam_tab

 */

clear all
set more off
set varabbrev off
set scheme s1color
//capture log close: Stata should not complain if there is no log open to close
cap log close _all


/* file path macros  */
include $projdir/do/share/siblingvaregs/vafilemacros.doh
/* estimates macros  */
include $projdir/do/share/siblingvaregs/vaestmacros.doh

//change directory to common_core_va project directory
cd $vaprojdir

//starting log file
log using $projdir/log/share/siblingvaregs/va_sibling_vam_tab.smcl, replace

//run the do helper file to set the local macros
include `vaprojdofiles'/sbac/macros_va.doh

#delimit ;
#delimit cr
macro list


timer on 1


/* Test score VA coefficients table  */
foreach subject in ela math {
  estimates use ``subject'_sibling_vam'
  eststo
}

esttab using $projdir/out/csv/siblingvaregs/vam/test_score_sibling_vam.csv ///
, replace nonumbers se(%4.3f) b(%5.3f) ///
title("VAM Output for Test Score VA with Sibling Controls")

eststo clear


/* postsecondary outcome VA coefficients table  */
 foreach outcome in enr enr_2year enr_4year {
   estimates use ``outcome'_sibling_vam'
   eststo
 }

 esttab using $projdir/out/csv/siblingvaregs/vam/outcome_sibling_vam.csv ///
 , replace nonumbers se(%4.3f) b(%5.3f) ///
 title("VAM Output for Postsecondary VA with Sibling Controls")

 eststo clear



timer off 1
timer list

//change directory back to my own personal directory 
cd $projdir

log close
translate $projdir/log/share/siblingvaregs/va_sibling_vam_tab.smcl $projdir/log/share/siblingvaregs/va_sibling_vam_tab.log, replace
