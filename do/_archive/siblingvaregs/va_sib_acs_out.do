********************************************************************************
/* do file to create college enrollment VA estimates on the restricted sample that
only has observations with sibling controls and ACS controls, without teacher
fixed effects or peer effects. There are 4 differentVA specifications:
1. Primary specification without sibling controls or ACS controls
2. Primary specification plus ACS controls
3. Primary specification plus sibling controls
4. Primary Specificationv plus ACS and sibling controls */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 2. 2022 *************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sib_acs_out

 */


/* CHANGE LOG:

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
log using $projdir/log/share/siblingvaregs/va_sib_acs_out.smcl, replace

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

local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)


********************************************************************************
********************************************************************************
/* Outcome VA, 4 specifications  */

foreach outcome in enr enr_2year enr_4year {
  // load the resctricted sample with sibling and acs controls
  use $vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta if touse_g11_`outcome'==1, clear

  ********************************************************************************
  /* Primary outcome va specification, no tfx, no peer fx, no sibling ctrl, no acs ctrl */
  ********************************************************************************
  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
    ) ///
    data(merge tv score_r) ///
    driftlimit(`drift_limit') ///
    estimates($vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_og.ster, replace)

  // rename the va estimates and the residuals
  rename tv va_`outcome'_og
  rename score_r `outcome'_r_og
  label var va_`outcome'_og "``outcome'_str' VA OG Specification"
  label var `outcome'_r_og "Outcome Residual from ``outcome'_str' VA OG Specification"

  *******************
  // specification test: regress outcome residuals on va estimates
  reg `outcome'_r_og va_`outcome'_og, cluster(school_id)

  // save spec test estimates
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_og.ster, replace



  ********************************************************************************
  /* Outcome VA, no tfx, no peer fx, no sibling ctrl, with acs ctrl */
  ********************************************************************************
  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
      `census_controls' ///
    ) ///
    data(merge tv score_r) ///
    driftlimit(`drift_limit') ///
    estimates($vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_acs.ster, replace)

  // rename va estimates and score residuals
  rename tv va_`outcome'_acs
  rename score_r `outcome'_r_acs
  label var va_`outcome'_acs "``outcome'_str' VA with Census Controls"
  label var `outcome'_r_acs "Outcome Residual from ``outcome'_str' VA with Census Controls"


  *******************
  // specification test: regress outcome residuals on va estimates
  reg `outcome'_r_acs va_`outcome'_acs, cluster(school_id)

  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_acs.ster, replace


  *******************
  // forecast bias test for ACS leave out vars

  // difference in outcome residuals
  gen `outcome'_r_d_og_acs = `outcome'_r_og - `outcome'_r_acs
  // fb test
  reg `outcome'_r_d_og_acs va_`outcome'_og, cluster(school_id)
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_acs_og.ster, replace




  ********************************************************************************
  /* Outcome VA, no tfx, no peer fx, with sibling ctrl, no acs ctrl */
  ********************************************************************************
  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
      `sibling_controls' ///
    ) ///
    data(merge tv score_r) ///
    driftlimit(`drift_limit') ///
    estimates($vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_sib.ster, replace)

  //rename va estimates sand score residuals
  rename tv va_`outcome'_sib
  rename score_r `outcome'_r_sib
  label var va_`outcome'_sib "``outcome'_str' VA with Sibling Controls"
  label var `outcome'_r_sib "Outcome Residual from ``outcome'_str' VA with Sibling Controls"


  *******************
  // specification test: regress outcome residuals on va estimates
  reg `outcome'_r_sib va_`outcome'_sib, cluster(school_id)

  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_sib.ster, replace


  *******************
  // forecast bias test for sibling controls as leave out vars
  // difference in outcome residuals
  gen `outcome'_r_d_og_sib = `outcome'_r_og - `outcome'_r_sib
  // fb test
  reg `outcome'_r_d_og_sib va_`outcome'_og, cluster(school_id)
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_sib_og.ster, replace




  ********************************************************************************
  /* Outcome VA, no tfx, no peer fx, with sibling ctrl, with acs ctrl */
  ********************************************************************************
  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
      `sibling_controls' ///
      `census_controls' ///
    ) ///
    data(merge tv score_r) ///
    driftlimit(`drift_limit') ///
    estimates($vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_both.ster, replace)

  //rename va estimates sand outcome residuals
  rename tv va_`outcome'_both
  rename score_r `outcome'_r_both
  label var va_`outcome'_both "``outcome'_str' VA with Sibling and Census Controls"
  label var `outcome'_r_both "Outcome Residual from ``outcome'_str' VA with Sibling and Census Controls"


  *******************
  // specification test: regress outcome residuals on va estimates
  reg `outcome'_r_both va_`outcome'_both, cluster(school_id)

  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_both.ster, replace


  *******************
  // forecast bias test for sibling controls as leave out vars against specification with only census controls
  // difference in outcome residuals with census controls and residuals with both census and sibling controls
  gen `outcome'_r_d_acs_both = `outcome'_r_acs - `outcome'_r_both
  // fb test
  reg `outcome'_r_d_acs_both va_`outcome'_acs, cluster(school_id)
  //naming convention: forecast bias test for leave out variables being sibling controls, against VA with only acs controls
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_sib_acs.ster, replace


  *******************
  // forecast bias test for census controls as leave out vars against specification with only sibling controls
  // difference in outcome residuals with census controls and residuals with both census and sibling controls
  gen `outcome'_r_d_sib_both = `outcome'_r_sib - `outcome'_r_both
  // fb test
  reg `outcome'_r_d_sib_both va_`outcome'_sib, cluster(school_id)
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_acs_sib.ster, replace





  ********* Save VA estimates
  collapse (firstnm) va_* ///
    (mean) `outcome'* ///
    (sum) n_g11_`outcome' = touse_g11_`outcome' ///
    , by(school_id cdscode grade year)
  // save to VA project data folder
  save $vaprojdir/data/sib_acs_restr_smp/outcome_va/va_`outcome'_sib_acs.dta, replace

}





timer off 1
timer list

//change directory back to my own personal directory
cd $projdir

log close
translate $projdir/log/share/siblingvaregs/va_sib_acs_out.smcl $projdir/log/share/siblingvaregs/va_sib_acs_out.log, replace
