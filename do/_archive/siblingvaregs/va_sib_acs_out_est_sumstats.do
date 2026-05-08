********************************************************************************
/* Creates correlation figures and difference density plots for outcome VA
1) VA from original sample with og controls, VA with og controls in restricted sample
2) VA from Original Sample with og controls, VA with sib and acs controls in restricted sample
3) VA with og controls, VA estimates with sib and acs controls in restricted sample
 */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 14, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sib_acs_out_est_sumstats

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
log using $projdir/log/share/siblingvaregs/va_sib_acs_out_est_sumstats.smcl, replace

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
foreach outcome in enr enr_2year enr_4year {
	use $vaprojdir/data/sbac/va_g11_`outcome'.dta, clear
	sort school_id year

	tempfile va_`outcome'_original
	save `va_`outcome'_original'
}

use `va_enr_original', clear
merge 1:1 cdscode year using `va_enr_2year_original', nogen
merge 1:1 cdscode year using `va_enr_4year_original', nogen

keep cdscode year va_cfr_g11_*

//drop the peer and outcome VA's to avoid too long var name causing trouble
drop va*peer va*ela va*math


// merge on the sibling census restricted sample VA estimates
foreach outcome in enr enr_2year enr_4year {
  merge 1:1 cdscode year using ///
    $vaprojdir/data/sib_acs_restr_smp/outcome_va/va_`outcome'_sib_acs.dta, nogen

  keep cdscode year va*
}

// create local macros for correlation coefficients
foreach outcome in enr enr_2year enr_4year {
  corr va_cfr_g11_`outcome' va_`outcome'_og
  // naming convention: correlation between original sample and restricted sample with og controls
  local corr_`outcome'_og_restr_og : di %5.3f r(rho)

  corr va_cfr_g11_`outcome' va_`outcome'_both
  local corr_`outcome'_og_restr_both : di %5.3f r(rho)

  corr va_`outcome'_og va_`outcome'_both
  local corr_`outcome'_restr_og_both : di %5.3f r(rho)
}



********** 1) Original sample, og controls vs. Restricted sample, og controls
********** 2) Original sample, og controls vs. Restricted sample, both sib and census controls

foreach outcome in enr enr_2year enr_4year {
  foreach control in og both {
    ***** correlation plot
    twoway ///
      (scatter va_cfr_g11_`outcome' va_`outcome'_`control') ///
      (lfit va_cfr_g11_`outcome' va_`outcome'_`control' ) ///
      (function y = x, range(va_cfr_g11_`outcome')) ///
      , ytitle("``outcome'_str' VA from Original Sample", size(small)) ///
      xtitle("``outcome'_str' VA from Restricted Sample with ``control'_str' Controls", size(small)) ///
      title("Comparison Scatter Plot of ``outcome'_str' VA", size(small)) ///
      legend(label(1 "``outcome'_str' VA") label(3 "45 degree line") ) ///
      note("Correlation Coefficient = `corr_`outcome'_og_restr_`control'' ")

    graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/corr_va_`outcome'_og_restr_`control'.pdf, replace
    graph export $projdir/out/graph/siblingvaregs/outcome_va/va_compare_sib_acs_restr_smp/corr_va_`outcome'_og_restr_`control'.pdf, replace

    ***** difference density plot
    gen va_`outcome'_og_restr_`control'_diff = va_`outcome'_`control' - va_cfr_g11_`outcome'

    twoway ///
      (hist va_`outcome'_og_restr_`control'_diff, frequency color(navy)) ///
      , ytitle("Frequency") xtitle("Difference") ///
      title("``outcome'_str' VA Difference between Original Sample and Restricted Sample with ``control'_str' Controls", size(vsmall))

    graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/hist_diff_va_`outcome'_og_restr_`control'.pdf, replace
    graph export $projdir/out/graph/siblingvaregs/outcome_va/va_compare_sib_acs_restr_smp/hist_diff_va_`outcome'_og_restr_`control'.pdf, replace
  }
}



********** 3) Restricted sample, og controls vs. Restricted sample, both sib and census controls
foreach outcome in enr enr_2year enr_4year {
  ***** correlation plot
  twoway ///
    (scatter va_`outcome'_og va_`outcome'_both) ///
    (lfit va_`outcome'_og va_`outcome'_both ) ///
    (function y = x, range(va_`outcome'_og)) ///
    , ytitle("``outcome'_str' VA from Restricted Sample with `og_str' Controls", size(small)) ///
    xtitle("``outcome'_str' VA from Restricted Sample with `both_str' Controls", size(small)) ///
    title("Comparison Scatter Plot of ``outcome'_str' VA", size(small)) ///
    legend(label(1 "``outcome'_str' VA") label(3 "45 degree line") ) ///
    note("Correlation Coefficient = `corr_`outcome'_restr_og_both' ")

  graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/corr_va_`outcome'_restr_og_both.pdf, replace
  graph export $projdir/out/graph/siblingvaregs/outcome_va/va_compare_sib_acs_restr_smp/corr_va_`outcome'_restr_og_both.pdf, replace

  ***** difference density plot
  gen va_`outcome'_restr_og_both_diff = va_`outcome'_both - va_`outcome'_og

  twoway ///
    (hist va_`outcome'_restr_og_both_diff, frequency color(navy)) ///
    , ytitle("Frequency") xtitle("Difference") ///
    title("``outcome'_str' VA Difference between Restricted Sample with `og_str' Controls and with `both_str' Controls", size(vsmall))

  graph export $vaprojdir/figures/va_sib_acs/va_compare_sib_acs_restr_smp/hist_diff_va_`outcome'_restr_og_both.pdf, replace
  graph export $projdir/out/graph/siblingvaregs/outcome_va/va_compare_sib_acs_restr_smp/hist_diff_va_`outcome'_restr_og_both.pdf, replace
}





timer off 1
timer list

set trace off
cd $vaprojdir

log close
translate $projdir/log/share/siblingvaregs/va_sib_acs_out_est_sumstats.smcl ///
  $projdir/log/share/siblingvaregs/va_sib_acs_out_est_sumstats.log, replace
