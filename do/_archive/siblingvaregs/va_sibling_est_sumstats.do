********************************************************************************
/* sum stats for the test score VA estimates with additional demographic control
for has at least one older sibling who enrolled in college (2 year, 4 year) */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on 10/27, 2021 ***************************

/* To run this do file:
do $projdir/do/share/siblingvaregs/va_sibling_est_sumstats
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
log using $projdir/log/share/siblingvaregs/va_sibling_est_sumstats.smcl, replace

//run the do helper file to set the local macros
include `vaprojdofiles'/sbac/macros_va.doh

#delimit ;
#delimit cr
macro list


timer on 1

// 11th Grade (8th Grade ELA Controls, 6th Grade Math Controls)
**************** Two Way Kernel Density for ELA and Math
foreach subject in ela math {

    use $projdir/dta/common_core_va/test_score_va/va_g11_`subject'_sibling.dta, clear
    sort school_id year
  	xtset school_id year

    * Normalize to have mean zero
  	foreach v of varlist va_* {
  		sum `v', meanonly
  		replace `v' = `v' - r(mean)
  	}

    sum va_cfr_g11_`subject'
    local mean_`subject' = 0
    local sd_`subject' : di %4.3f = r(sd)

    /* sum va_cfr_g11_`subject'_peer
    local mean_`subject'_peer = 0
    local sd_`subject'_peer : di %4.3f = r(sd) */

    tempfile va_`subject'
    save `va_`subject''

}


  use `va_ela', clear
  merge 1:1 cdscode year using `va_math', nogen

  corr va_cfr_g11_ela va_cfr_g11_ela_nosibctrl
  local corr_coef_ela_sibling : di %5.3f r(rho)

  corr va_cfr_g11_math va_cfr_g11_math_nosibctrl
  local corr_coef_math_sibling : di %5.3f r(rho)

  tempfile va_ela_math_sibling
  save `va_ela_math_sibling'


  *************** two way scatter plot of VA with and without sibling controls
  ***ELA
  twoway ///
  (scatter va_cfr_g11_ela va_cfr_g11_ela_nosibctrl) ///
  (lfit va_cfr_g11_ela va_cfr_g11_ela_nosibctrl) ///
  (function y = x), ///
  ytitle("ELA VA with Sibling Control") ///
  xtitle("ELA VA without Sibling Control") ///
  title("Scatter Plot of ELA VA with and without Sibling Control") ///
  legend(label(1 "ELA VA") label(3 "45 degree line") ) ///
  note("Correlation Coefficient = `corr_coef_ela_sibling' ")

  graph export $projdir/out/graph/siblingvaregs/test_score_va/scatter_va_cfr_g11_ela_sibling.pdf, replace


  ***math
  twoway ///
  (scatter va_cfr_g11_math va_cfr_g11_math_nosibctrl) ///
  (lfit va_cfr_g11_math va_cfr_g11_math_nosibctrl) ///
  (function y = x), ///
  ytitle("Math VA with Sibling Control") ///
  xtitle("Math VA without Sibling Control") ///
  title("Scatter Plot of Math VA with and without Sibling Control") ///
  legend(label(1 "Math VA") label(3 "45 degree line") ) ///
  note("Correlation Coefficient = `corr_coef_math_sibling' ")

  graph export $projdir/out/graph/siblingvaregs/test_score_va/scatter_va_cfr_g11_math_sibling.pdf, replace









  **** No Peer Controls
  twoway ///
  	(kdensity va_cfr_g11_ela) ///
  	(kdensity va_cfr_g11_math) ///
    , ytitle("Density") xtitle("Value Added") ///
    title("11th Grade Test Score VA") ///
  	legend(label(1 "ELA") label(2 "Math")) ///
    note("Mean (Standard Deviation) = `mean_ela' (`sd_ela')" ///
  	"Mean (Standard Deviation) = `mean_math' (`sd_math')")
    graph export $projdir/out/graph/siblingvaregs/test_score_va/kdensity_va_cfr_g11_sibling.pdf, replace

/*
  ****  Peer Controls
  twoway ///
  	(kdensity va_cfr_g11_ela_peer) ///
  	(kdensity va_cfr_g11_math_peer) ///
    , ytitle("Density") xtitle("Value Added") ///
    title("11th Grade Test Score VA") ///
  	legend(label(1 "ELA") label(2 "Math")) ///
    note("Mean (Standard Deviation) = `mean_ela_peer' (`sd_ela_peer')" ///
  	"Mean (Standard Deviation) = `mean_math_peer' (`sd_math_peer')")
    graph export $projdir/out/graph/siblingvaregs/test_score_va/kdensity_va_cfr_g11_peer_sibling.pdf, replace
 */



*************** correlation with original VA estimates
//load orignal VA dataset and merge ELA with math
foreach subject in ela math {
	use data/sbac/va_g11_`subject'.dta, clear
  sort school_id year

	tempfile va_`subject'_original
	save `va_`subject'_original'
}

use `va_ela_original'
merge 1:1 cdscode year using `va_math_original', nogen

keep cdscode year va_cfr_g11_*
rename va* va*_original

merge 1:1 cdscode year using `va_ela_math_sibling', nogen

corr va_cfr_g11_ela va_cfr_g11_ela_original
local corr_coef_ela_original : di %5.3f r(rho)

corr va_cfr_g11_math va_cfr_g11_math_original
local corr_coef_math_original : di %5.3f r(rho)


*************** two way scatter plot of VA with sibling control and original VA
***ELA
twoway ///
(scatter va_cfr_g11_ela va_cfr_g11_ela_original) ///
(lfit va_cfr_g11_ela va_cfr_g11_ela_original) ///
(function y = x), ///
ytitle("ELA VA with Sibling Control") ///
xtitle("Original ELA VA") ///
title("Scatter Plot of ELA VA with Sibling Control and Original") ///
legend(label(1 "ELA VA") label(3 "45 degree line") ) ///
note("Correlation Coefficient = `corr_coef_ela_original' ")

graph export $projdir/out/graph/siblingvaregs/test_score_va/scatter_va_cfr_g11_ela_original.pdf, replace


***math
twoway ///
(scatter va_cfr_g11_math va_cfr_g11_math_original) ///
(lfit va_cfr_g11_math va_cfr_g11_math_original) ///
(function y = x), ///
ytitle("Math VA with Sibling Control") ///
xtitle("Original Math VA") ///
  title("Scatter Plot of Math VA with Sibling Control and Original") ///
legend(label(1 "Math VA") label(3 "45 degree line") ) ///
note("Correlation Coefficient = `corr_coef_math_original' ")

graph export $projdir/out/graph/siblingvaregs/test_score_va/scatter_va_cfr_g11_math_original.pdf, replace












**************************************************
//specification tests
*****No peer controls
foreach subject in ela math {

    estimates use $projdir/est/siblingvaregs/test_score_va/spec_test_va_cfr_g11_`subject'_sibling.ster

    test _b[va_cfr_g11_`subject'] = 1
    matrix test_p = r(p)
  	matrix rownames test_p = pvalue
  	matrix colnames test_p = va_cfr_g11_`subject'
  	estadd matrix test_p = test_p

    local slope : di %5.3f _b[va_cfr_g11_`subject']
  	local std_err : di %4.3f _se[va_cfr_g11_`subject']
  	binscatter sbac_g11_`subject'_r va_cfr_g11_`subject' ///
  		[aw = n_g11_`subject'] ///
  		, ytitle("11th Grade Score") xtitle("Value Added") ///
      title("11th Grade ``subject'_str' Specification Test") ///
  		yline(0) xline(0) ///
  		yscale(range(-.3 .3)) xscale(range(-.3 .3)) ylabel(-.3 (0.1) .3) xlabel(-.3 (0.1) .3) ///
  		note("Slope (Standard Error) = `slope' (`std_err')")
  	graph export $projdir/out/graph/siblingvaregs/test_score_va/spec_test_va_cfr_g11_`subject'_sibling.pdf, replace

/*
******* with peer controls
    estimates use $projdir/est/siblingvaregs/test_score_va/spec_test_va_cfr_g11_`subject'_peer_sibling.ster

    test _b[va_cfr_g11_`subject'_peer] = 1
    matrix test_p = r(p)
  	matrix rownames test_p = pvalue
  	matrix colnames test_p = va_cfr_g11_`subject'_peer
  	estadd matrix test_p = test_p

  	local slope : di %5.3f _b[va_cfr_g11_`subject'_peer]
  	local std_err : di %4.3f _se[va_cfr_g11_`subject'_peer]
  	binscatter sbac_g11_`subject'_r_peer va_cfr_g11_`subject'_peer ///
  		[aw = n_g11_`subject'] ///
  		, ytitle("11th Grade Score") xtitle("Value Added") ///
      title("11th Grade ``subject'_str' Specification Test") ///
  		yline(0) xline(0) ///
  		yscale(range(-.3 .3)) xscale(range(-.3 .3)) ylabel(-.3 (0.1) .3) xlabel(-.3 (0.1) .3) ///
  		note("Slope (Standard Error) = `slope' (`std_err')")
    graph export $projdir/out/graph/siblingvaregs/test_score_va/spec_test_va_cfr_g11_`subject'_peer_sibling.pdf, replace */


}









timer off 1
timer list
log close

cd $projdir


translate $projdir/log/share/siblingvaregs/va_sibling_est_sumstats.smcl ///
$projdir/log/share/siblingvaregs/va_sibling_est_sumstats.log, replace
