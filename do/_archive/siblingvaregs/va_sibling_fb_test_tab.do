********************************************************************************
/* do file to create a regression output table for forecast bias tests for test score VA
and enrollment VA on different samples */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on Jan 6, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sibling_fb_test_tab.do


 */


 clear all
 graph drop _all
 set more off
 set varabbrev off
 set graphics off
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
 log using $projdir/log/share/siblingvaregs/va_sibling_fb_test_tab.smcl, replace

 //run the do helper file to set the local macros
 include `vaprojdofiles'/sbac/macros_va.doh

 #delimit ;
 #delimit cr
 macro list


 timer on 1


 ********************************************************************************
 ********* test score VA forecast bias test table without peer controls

 foreach subject in ela math {
   //original VA, L4 test score leave out var sample
   estimates use ``subject'_fb_va_l4'
   eststo

   //original VA, census tract leave out var sample
   estimates use ``subject'_fb_va_census'
   eststo

   //original VA, sibling sample
   estimates use ``subject'_fb_va_sibling '
   eststo


   esttab using $projdir/out/csv/siblingvaregs/fb_test/fb_test_`subject'.csv ///
   , replace nonumbers se(%4.3f) b(%5.3f) ///
   mtitles("L4 Score Sample" "Census Sample" "Sibling Sample") ///
   title("Forecast Bias Tests for ``subject'_str' VA")

   eststo clear

 }


 ********************************************************************************
 ********* enrollment VA forecast bias test table without peer controls

 foreach outcome in enr enr_2year enr_4year {
   //original VA, L4 test score leave out var sample
   estimates use ``outcome'_fb_va_l4'
   eststo

   //original VA, census tract leave out var sample
   estimates use ``outcome'_fb_va_census'
   eststo

   //original VA, sibling sample
   estimates use ``outcome'_fb_va_sibling '
   eststo

   // Sibling census sample with census leave out var
   estimates use "$vaprojdir/estimates/sibling_va/outcome_va/fb_test_`outcome'_census.ster"
   eststo

   esttab using $projdir/out/csv/siblingvaregs/fb_test/fb_test_`outcome'.csv ///
   , replace nonumbers se(%4.3f) b(%5.3f) ///
   mtitles("L4 Score" "Census" "Sibling" "Sibling Census") ///
   title("Forecast Bias Tests for ``outcome'_str' VA")

   eststo clear
 }


 timer off 1
 timer list
 log close

 cd $projdir


 translate $projdir/log/share/siblingvaregs/va_sibling_fb_test_tab.smcl ///
 $projdir/log/share/siblingvaregs/va_sibling_fb_test_tab.log, replace
