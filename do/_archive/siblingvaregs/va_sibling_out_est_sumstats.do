********************************************************************************
/* sum stats for the enrollment VA estimates with additional demographic control
for has at least one older sibling who enrolled in college (2 year, 4 year) */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on Nov 3, 2021 ***************************

/* To run this do file:
do $projdir/do/share/siblingvaregs/va_sibling_out_est_sumstats
 */

/* ssc install binscatter, replace */

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

//change directory to common_core_va project directory
cd $vaprojdir

//starting log file
log using $projdir/log/share/siblingvaregs/va_sibling_out_est_sumstats.smcl, replace

//run the do helper file to set the local macros
include `vaprojdofiles'/sbac/macros_va.doh

#delimit ;
#delimit cr
macro list


timer on 1


//this does not include the code necessary for deep knowledge sum stats
foreach outcome in enr enr_2year enr_4year {
  use $projdir/dta/common_core_va/outcome_va/va_g11_`outcome'_sibling.dta, clear
  sort school_id year
	xtset school_id year


  * Normalize to have mean zero
  foreach v of varlist va_* {
    sum `v', meanonly
    replace `v' = `v' - r(mean)
  }
  sum va_cfr_g11_`outcome'
  local mean_`outcome' = 0
  local sd_`outcome' : di %4.3f = r(sd)
/*
  sum va_cfr_g11_`outcome'_peer
  local mean_`outcome'_peer = 0
  local sd_`outcome'_peer : di %4.3f = r(sd)
 */


  tempfile va_`outcome'
  save `va_`outcome''
}


use `va_enr'
merge 1:1 cdscode year using `va_enr_2year', nogen
merge 1:1 cdscode year using `va_enr_4year', nogen


tempfile va_enr_merged_sibling
save `va_enr_merged_sibling'


*************** two way scatter plot of VA with and without sibling controls

foreach outcome in enr enr_2year enr_4year {
  //get correlation of VA estimates with and without sibling controls and store in macro
  corr va_cfr_g11_`outcome' va_cfr_g11_`outcome'_nosibctrl
  local corr_coef_`outcome'_sibling : di %5.3f r(rho)

  twoway ///
  (scatter va_cfr_g11_`outcome' va_cfr_g11_`outcome'_nosibctrl) ///
  (lfit va_cfr_g11_`outcome' va_cfr_g11_`outcome'_nosibctrl) ///
  (function y = x), ///
  ytitle("``outcome'_str' VA with Sibling Control") ///
  xtitle("``outcome'_str' VA without Sibling Control") ///
  title("Scatter Plot of ``outcome'_str' VA with and without Sibling Control") ///
  legend(label(1 "``outcome'_str' VA") label(3 "45 degree line") ) ///
  note("Correlation Coefficient = `corr_coef_`outcome'_sibling' ")

  graph export $projdir/out/graph/siblingvaregs/outcome_va/scatter_va_cfr_g11_`outcome'_sibling.pdf, replace


}





*************** correlation with original VA estimates
//load orignal VA dataset and merge the different outcomes
foreach outcome in enr enr_2year enr_4year {
	use data/sbac/va_g11_`outcome'.dta, clear
	sort school_id year

	tempfile va_`outcome'_original
	save `va_`outcome'_original'
}


use `va_enr_original', clear
merge 1:1 cdscode year using `va_enr_2year_original', nogen
merge 1:1 cdscode year using `va_enr_4year_original', nogen

keep cdscode year va_cfr_g11_*
//drop the peer and subject VA's to avoid too long var name causing trouble
drop va*peer va*ela va*math
rename va* va*_original

//merge on the VA estimates with sibling controls
merge 1:1 cdscode year using `va_enr_merged_sibling', nogen

//two way scatter plot of VA with sibling control and original VA
foreach outcome in enr enr_2year enr_4year {
  //get correlation of VA estimates with and without sibling controls and store in macro
  corr va_cfr_g11_`outcome' va_cfr_g11_`outcome'_original
  local corr_coef_`outcome'_original : di %5.3f r(rho)

  twoway ///
  (scatter va_cfr_g11_`outcome' va_cfr_g11_`outcome'_original) ///
  (lfit va_cfr_g11_`outcome' va_cfr_g11_`outcome'_original) ///
  (function y = x), ///
  ytitle("``outcome'_str' VA with Sibling Control") ///
  xtitle("Original ``outcome'_str' VA") ///
  title("Scatter Plot of ``outcome'_str' VA and Original") ///
  legend(label(1 "``outcome'_str' VA") label(3 "45 degree line") ) ///
  note("Correlation Coefficient = `corr_coef_`outcome'_original' ")

  graph export $projdir/out/graph/siblingvaregs/outcome_va/scatter_va_cfr_g11_`outcome'_original.pdf, replace

}

















**************** Kernel Density
******** Overall Value Added
**** No Peer Controls
twoway ///
	(kdensity va_cfr_g11_enr) ///
	(kdensity va_cfr_g11_enr_2year) ///
	(kdensity va_cfr_g11_enr_4year) ///
	, ytitle("Density") xtitle("Value Added") ///
  title("Postsecondary Overall Value Added with Sibling Controls") ///
	legend(label(1 "Enroll Any") label(2 "Enroll 2-Year") label(3 "Enroll 4-Year")) ///
	note("Enroll Any Mean (Standard Deviation) = `mean_enr' (`sd_enr')" ///
	"Enroll 2-Year Mean (Standard Deviation) = `mean_enr_2year' (`sd_enr_2year')" ///
	"Enroll 4-Year Mean (Standard Deviation) = `mean_enr_4year' (`sd_enr_4year')")
  graph export $projdir/out/graph/siblingvaregs/outcome_va/kdensity_va_cfr_g11_enrollment_sibling.pdf, replace


/*
  **** Peer Controls
  twoway ///
  	(kdensity va_cfr_g11_enr_peer) ///
  	(kdensity va_cfr_g11_enr_2year_peer) ///
  	(kdensity va_cfr_g11_enr_4year_peer) ///
  	, ytitle("Density") xtitle("Value Added") ///
    title("Postsecondary Overall Value Added with Sibling Controls") ///
  	legend(label(1 "Enroll Any") label(2 "Enroll 2-Year") label(3 "Enroll 4-Year")) ///
  	note("Enroll Any Mean (Standard Deviation) = `mean_enr_peer' (`sd_enr_peer')" ///
  	"Enroll 2-Year Mean (Standard Deviation) = `mean_enr_2year_peer' (`sd_enr_2year_peer')" ///
  	"Enroll 4-Year Mean (Standard Deviation) = `mean_enr_4year_peer' (`sd_enr_4year_peer')")
    graph export $projdir/out/graph/siblingvaregs/outcome_va/kdensity_va_cfr_g11_enrollment_peer_sibling.pdf, replace

 */

//note: skipped the kdensity plots for each individual outcome VA





foreach outcome in enr enr_2year enr_4year {
  ******** Specification Test
  **** No Peer Controls
  estimates use $projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_sibling.ster
  eststo spec_g11_`outcome'
  test _b[va_cfr_g11_`outcome'] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'
  estadd matrix test_p = test_p

  local slope : di %5.3f _b[va_cfr_g11_`outcome']
  local std_err : di %4.3f _se[va_cfr_g11_`outcome']
  binscatter g11_`outcome'_r va_cfr_g11_`outcome' ///
    [aw = n_g11_`outcome'] ///
    , ytitle("``outcome'_str'") xtitle("Value Added") ///
    title("``outcome'_str' Specification Test") ///
    yline(0) xline(0) ///
    yscale(range(-.3 .3)) xscale(range(-.3 .3)) ylabel(-.3 (0.1) .3) xlabel(-.3 (0.1) .3) ///
    note("Slope (Standard Error) = `slope' (`std_err')")
  graph export $projdir/out/graph/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_sibling.pdf, replace

/* 
  **** Peer Controls
  estimates use $projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_peer_sibling.ster
  eststo spec_g11_`outcome'_peer
  test _b[va_cfr_g11_`outcome'_peer] = 1
  matrix test_p = r(p)
  matrix rownames test_p = pvalue
  matrix colnames test_p = va_cfr_g11_`outcome'_peer
  estadd matrix test_p = test_p

  local slope : di %5.3f _b[va_cfr_g11_`outcome'_peer]
  local std_err : di %4.3f _se[va_cfr_g11_`outcome'_peer]
  binscatter g11_`outcome'_r_peer va_cfr_g11_`outcome'_peer ///
    [aw = n_g11_`outcome'] ///
    , ytitle("``outcome'_str'") xtitle("Value Added") title("``outcome'_str' Specification Test") ///
    yline(0) xline(0) ///
    yscale(range(-.3 .3)) xscale(range(-.3 .3)) ylabel(-.3 (0.1) .3) xlabel(-.3 (0.1) .3) ///
    note("Slope (Standard Error) = `slope' (`std_err')")
  graph export $projdir/out/graph/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_peer_sibling.pdf, replace
 */

}




cd $projdir



timer off 1
timer list
log close

translate $projdir/log/share/siblingvaregs/va_sibling_out_est_sumstats.smcl ///
$projdir/log/share/siblingvaregs/va_sibling_out_est_sumstats.log, replace
