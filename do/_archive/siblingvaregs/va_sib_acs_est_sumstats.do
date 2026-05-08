********************************************************************************
/* Creates correlation figures and difference density plots for test score VA
1) VA from original sample with og controls, VA with og controls in restricted sample
2) VA from Original Sample with og controls, VA with sib and acs controls in restricted sample
3) VA with og controls, VA estimates with sib and acs controls in restricted sample
 */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 14, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sib_acs_est_sumstats

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

/* set trace on */


//starting log file
log using $projdir/log/share/siblingvaregs/va_sib_acs_est_sumstats.smcl, replace

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


// merge original sample VA estimates with restricted sample VA estimates

foreach subject in ela math {
  use $vaprojdir/data/sbac/va_g11_`subject'.dta, clear
  sort school_id year

  tempfile va_`subject'_original
  save `va_`subject'_original'
}

// merge the original ELA and Math VA estimates
use `va_ela_original'
merge 1:1 cdscode year using `va_math_original', nogen

keep cdscode year va_cfr_g11_*


// merge on the sibling census restricted sample VA estimates
foreach subject in ela math {
  merge 1:1 cdscode year using ///
   $vaprojdir/data/sib_acs_restr_smp/test_score_va/va_`subject'_sib_acs.dta ///
   , nogen

  keep cdscode year va*
}

// create local macros for correlation coefficients
foreach subject in ela math {
  corr va_cfr_g11_`subject' va_`subject'_og
  // naming convention: correlation between original sample and restricted sample with og controls
  local corr_`subject'_original_restr_og : di %5.3f r(rho)

  corr va_cfr_g11_`subject' va_`subject'_both
  local corr_`subject'_original_restr_both : di %5.3f r(rho)

  corr va_`subject'_og va_`subject'_both
  local corr_`subject'_restr_og_both : di %5.3f r(rho)
}


********** 1) Original sample, og controls vs. Restricted sample, og controls

foreach subject in ela math {
  ***** correlation plot
  twoway ///
    (scatter va_cfr_g11_`subject' va_`subject'_og) ///
    (lfit va_cfr_g11_`subject' va_`subject'_og ) ///
    (function y = x, range(va_cfr_g11_`subject')) ///
    , ytitle("``subject'_str' VA from Original Sample", size(small)) ///
    xtitle("``subject'_str' VA from Restricted Sample with `og_str' Controls", size(small)) ///
    title("Comparison Scatter Plot of ``subject'_str' VA", size(small)) ///
    legend(label(1 "``subject'_str' VA") label(3 "45 degree line") ) ///
    note("Correlation Coefficient = `corr_`subject'_original_restr_og' ")

  graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/corr_va_`subject'_original_restr_og.pdf, replace
  graph export $projdir/out/graph/siblingvaregs/test_score_va/va_compare_sib_acs_restr_smp/corr_va_`subject'_original_restr_og.pdf, replace

  ***** difference density plot
  gen va_`subject'_original_restr_og_diff = va_`subject'_og - va_cfr_g11_`subject'

  twoway ///
    (hist va_`subject'_original_restr_og_diff, frequency color(navy)) ///
    , ytitle("Frequency") xtitle("Difference") ///
    title("``subject'_str' VA Difference between Original Sample and Restricted Sample with `og_str' Controls", size(vsmall))

  graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/hist_diff_va_`subject'_original_restr_og.pdf, replace
  graph export $projdir/out/graph/siblingvaregs/test_score_va/va_compare_sib_acs_restr_smp/hist_diff_va_`subject'_original_restr_og.pdf, replace
}


********** 2) Original sample, og controls vs. Restricted sample, both sib and census controls

foreach subject in ela math {
  ***** correlation plot
  twoway ///
    (scatter va_cfr_g11_`subject' va_`subject'_both) ///
    (lfit va_cfr_g11_`subject' va_`subject'_both ) ///
    (function y = x, range(va_cfr_g11_`subject')) ///
    , ytitle("``subject'_str' VA from Original Sample", size(small)) ///
    xtitle("``subject'_str' VA from Restricted Sample with `both_str' Controls", size(small)) ///
    title("Comparison Scatter Plot of ``subject'_str' VA", size(small)) ///
    legend(label(1 "``subject'_str' VA") label(3 "45 degree line") ) ///
    note("Correlation Coefficient = `corr_`subject'_original_restr_both' ")

  graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/corr_va_`subject'_original_restr_both.pdf, replace
  graph export $projdir/out/graph/siblingvaregs/test_score_va/va_compare_sib_acs_restr_smp/corr_va_`subject'_original_restr_both.pdf, replace

  ***** difference density plot
  gen va_`subject'_original_restr_both_diff = va_`subject'_both - va_cfr_g11_`subject'

  twoway ///
    (hist va_`subject'_original_restr_both_diff, frequency color(navy)) ///
    , ytitle("Frequency") xtitle("Difference") ///
    title("``subject'_str' VA Difference between Original Sample and Restricted Sample with `both_str' Controls", size(vsmall))

  graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/hist_diff_va_`subject'_original_restr_both.pdf, replace
  graph export $projdir/out/graph/siblingvaregs/test_score_va/va_compare_sib_acs_restr_smp/hist_diff_va_`subject'_original_restr_both.pdf, replace
}




********** 3) Restricted sample, og controls vs. Restricted sample, both sib and census controls
foreach subject in ela math {
  ***** correlation plot
  twoway ///
    (scatter va_`subject'_og va_`subject'_both) ///
    (lfit va_`subject'_og va_`subject'_both ) ///
    (function y = x, range(va_`subject'_og)) ///
    , ytitle("``subject'_str' VA from Restricted Sample with `og_str' Controls", size(small)) ///
    xtitle("``subject'_str' VA from Restricted Sample with `both_str' Controls", size(small)) ///
    title("Comparison Scatter Plot of ``subject'_str' VA", size(small)) ///
    legend(label(1 "``subject'_str' VA") label(3 "45 degree line") ) ///
    note("Correlation Coefficient = `corr_`subject'_restr_og_both' ")

  graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/corr_va_`subject'_restr_og_both.pdf, replace
  graph export $projdir/out/graph/siblingvaregs/test_score_va/va_compare_sib_acs_restr_smp/corr_va_`subject'_restr_og_both.pdf, replace

  ***** difference density plot
  gen va_`subject'_restr_og_both_diff = va_`subject'_both - va_`subject'_og

  twoway ///
    (hist va_`subject'_restr_og_both_diff, frequency color(navy)) ///
    , ytitle("Frequency") xtitle("Difference") ///
    title("``subject'_str' VA Difference between Restricted Sample with `og_str' Controls and with `both_str' Controls", size(vsmall))

  graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/hist_diff_va_`subject'_restr_og_both.pdf, replace
  graph export $projdir/out/graph/siblingvaregs/test_score_va/va_compare_sib_acs_restr_smp/hist_diff_va_`subject'_restr_og_both.pdf, replace
}














timer off 1
timer list

set trace off
cd $vaprojdir

log close
translate $projdir/log/share/siblingvaregs/va_sib_acs_est_sumstats.smcl ///
  $projdir/log/share/siblingvaregs/va_sib_acs_est_sumstats.log, replace
