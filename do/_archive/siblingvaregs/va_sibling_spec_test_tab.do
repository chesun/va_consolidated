********************************************************************************
/* do file to create a regression output table for spec tests for test score VA
and enrollment VA on different samples */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on Sep 22, 2021 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sibling_spec_test_tab.do


 */


 //install VAM package to estimate value added models a la Chetty, Freidman, and Rockoff
 /* ssc install vam, replace  */
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
 log using $projdir/log/share/siblingvaregs/va_sibling_spec_test_tab.smcl, replace

 //run the do helper file to set the local macros
 include `vaprojdofiles'/sbac/macros_va.doh

 #delimit ;
 #delimit cr
 macro list


 timer on 1



********************************************************************************
********* test score VA Spec test table without peer controls



foreach subject in ela math {
  //original VA, original sample
  estimates use ``subject'_spec_va'
  eststo
  test _b[va_cfr_g11_`subject'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`subject'
  estadd matrix test_p = test_p


  //original VA, leave out var L4 test score sample
  estimates use ``subject'_spec_va_l4'
  eststo
  test _b[va_cfr_g11_`subject'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`subject'
  estadd matrix test_p = test_p


  //original VA, leave out census tract sample
  estimates use ``subject'_spec_va_census'
  eststo
  test _b[va_cfr_g11_`subject'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`subject'
  estadd matrix test_p = test_p


  //original VA, sibling sample
  estimates use ``subject'_spec_va_sibling_og'
  eststo
  test _b[va_cfr_g11_`subject'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`subject'
  estadd matrix test_p = test_p


  //sibling VA, sibling sample
  estimates use ``subject'_spec_va_sibling'
  eststo
  test _b[va_cfr_g11_`subject'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`subject'
  estadd matrix test_p = test_p



  esttab using $projdir/out/csv/siblingvaregs/spec_test/spec_test_`subject'.csv ///
  , replace nonumbers  ///
  cells(b(fmt(%5.3f) pvalue(test_p) star) se(fmt(%4.3f) par)) ///
  mtitles("Original" "L4 Score Sample" "Census Sample" "Sibling Sample" "Sib Sample w/ Sib Ctrls") ///
  title("Spec Tests for ``subject'_str' VA")

  eststo clear

}





********************************************************************************
********* enrollment VA Spec test table without peer controls
foreach outcome in enr enr_2year enr_4year  {
  //original VA, original sample
  estimates use ``outcome'_spec_va'
  eststo
  test _b[va_cfr_g11_`outcome'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'
  estadd matrix test_p = test_p

  //original VA, leave out var L4 test score sample
  estimates use ``outcome'_spec_va_l4'
  eststo
  test _b[va_cfr_g11_`outcome'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'
  estadd matrix test_p = test_p

  //original VA, leave out census tract sample
  estimates use ``outcome'_spec_va_census'
  eststo
  test _b[va_cfr_g11_`outcome'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'
  estadd matrix test_p = test_p

  //original VA, sibling sample
  estimates use ``outcome'_spec_va_sibling_og'
  eststo
  test _b[va_cfr_g11_`outcome'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'
  estadd matrix test_p = test_p

  //sibling VA, sibling sample
  estimates use ``outcome'_spec_va_sibling'
  eststo
  test _b[va_cfr_g11_`outcome'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'
  estadd matrix test_p = test_p

  //outcome VA without sibling controls on sibling census sample
  estimates use "$vaprojdir/estimates/sibling_va/outcome_va/spec_test_`outcome'_census_nosib_noacs.ster"
  eststo
  test _b[va_`outcome'_nosib_noacs] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'
  estadd matrix test_p = test_p

  //outcome VA with sibling controls on sibling census sample
  estimates use "$vaprojdir/estimates/sibling_va/outcome_va/spec_test_`outcome'_census_noacs.ster"
  eststo
  test _b[va_`outcome'_noacs] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'
  estadd matrix test_p = test_p



  esttab using $projdir/out/csv/siblingvaregs/spec_test/spec_test_`outcome'.csv ///
  , replace nonumbers  ///
  cells(b(fmt(%5.3f) pvalue(test_p) star) se(fmt(%4.3f) par)) ///
  mtitles("Original" "L4 Score Sample" "Census Sample" "Sibling Sample" "Sib Sample w/ Sib Ctrls" "Sibling Census Sample" "Sib-Cens with Sib Ctrls") ///
  title("Spec Tests for ``outcome'_str' VA")

  eststo clear

}




 timer off 1
 timer list
 log close

 cd $projdir


 translate $projdir/log/share/siblingvaregs/va_sibling_spec_test_tab.smcl ///
 $projdir/log/share/siblingvaregs/va_sibling_spec_test_tab.log, replace
