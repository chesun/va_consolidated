********************************************************************************
/* do file to create deep knowledge college enrollment VA estimates on the
restricted sample that only has observations with sibling controls and ACS controls,
without teacher fixed effects or peer effects. The DK VA controls for ELA and math
VA on the same sample. There are 4 differentVA specifications:
1. Primary specification without sibling controls or ACS controls
2. Primary specification plus ACS controls
3. Primary specification plus sibling controls
4. Primary Specificationv plus ACS and sibling controls
*/
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 3. 2022 *************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sib_acs_out_dk

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
 log using $projdir/log/share/siblingvaregs/va_sib_acs_out_dk.smcl, replace

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
*start the main code

local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)

// deep knowledge controls for sibling acs restricted sample
local sib_acs_dk_controls va_ela_og va_math_og


********************************************************************************
********************************************************************************
/* Deep Knowledge Outcome VA controlling for ela and math VA, 4 specifications  */
foreach outcome in enr enr_2year enr_4year {
  // load the resctricted sample with sibling and acs controls and test score VA
  use $vaprojdir/data/va_samples/va_sib_acs_out_restr_smp.dta if touse_`outcome'_dk==1, clear


  ********************************************************************************
  /* Primary outcome DK va specification, no tfx, no peer fx, no sibling ctrl, no acs ctrl */
  ********************************************************************************
  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      `sib_acs_dk_controls' ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
    ) ///
    data(merge tv score_r) ///
    driftlimit(`drift_limit') ///
    estimates($vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_og_dk.ster, replace)

  // rename the va estimates and the residuals
  rename tv va_`outcome'_og_dk
  rename score_r `outcome'_r_og_dk
  label var va_`outcome'_og_dk "``outcome'_str' DK VA OG Specification"
  label var `outcome'_r_og_dk "Outcome Residual from ``outcome'_str' DK VA OG Specification"


  *******************
  // specification test: regress outcome residuals on va estimates
  reg `outcome'_r_og_dk va_`outcome'_og_dk, cluster(school_id)

  // save spec test estimates
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_og_dk.ster, replace




  ********************************************************************************
  /* Outcome DK VA, no tfx, no peer fx, no sibling ctrl, with acs ctrl */
  ********************************************************************************
  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      `sib_acs_dk_controls' ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
      `census_controls' ///
    ) ///
    data(merge tv score_r) ///
    driftlimit(`drift_limit') ///
    estimates($vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_acs_dk.ster, replace)

  // rename va estimates and score residuals
  rename tv va_`outcome'_acs_dk
  rename score_r `outcome'_r_acs_dk
  label var va_`outcome'_acs_dk "``outcome'_str' DK VA with Census Controls"
  label var `outcome'_r_acs_dk "Outcome Residual from ``outcome'_str' DK VA with Census Controls"


  *******************
  // specification test: regress outcome residuals on va estimates
  reg `outcome'_r_acs_dk va_`outcome'_acs_dk, cluster(school_id)

  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_acs_dk.ster, replace


  *******************
  // forecast bias test for ACS leave out vars

  // difference in outcome residuals
  gen `outcome'_r_d_og_acs_dk = `outcome'_r_og_dk - `outcome'_r_acs_dk
  // fb test
  reg `outcome'_r_d_og_acs_dk va_`outcome'_og_dk, cluster(school_id)
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_acs_og_dk.ster, replace



  ********************************************************************************
  /* Outcome DK VA, no tfx, no peer fx, with sibling ctrl, no acs ctrl */
  ********************************************************************************
  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      `sib_acs_dk_controls' ///
      i.year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
      `sibling_controls' ///
    ) ///
    data(merge tv score_r) ///
    driftlimit(`drift_limit') ///
    estimates($vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_sib_dk.ster, replace)

  //rename va estimates sand score residuals
  rename tv va_`outcome'_sib_dk
  rename score_r `outcome'_r_sib_dk
  label var va_`outcome'_sib_dk "``outcome'_str' DK VA with Sibling Controls"
  label var `outcome'_r_sib_dk "Outcome Residual from ``outcome'_str' DK VA with Sibling Controls"


  *******************
  // specification test: regress outcome residuals on va estimates
  reg `outcome'_r_sib_dk va_`outcome'_sib_dk, cluster(school_id)

  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_sib_dk.ster, replace


  *******************
  // forecast bias test for sibling controls as leave out vars
  // difference in outcome residuals
  gen `outcome'_r_d_og_sib_dk = `outcome'_r_og_dk - `outcome'_r_sib_dk
  // fb test
  reg `outcome'_r_d_og_sib_dk va_`outcome'_og_dk, cluster(school_id)
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_sib_og_dk.ster, replace




  ********************************************************************************
  /* Outcome DK VA, no tfx, no peer fx, with sibling ctrl, with acs ctrl */
  ********************************************************************************
  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      `sib_acs_dk_controls' ///
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
    estimates($vaprojdir/estimates/sib_acs_restr_smp/outcome_va/vam_`outcome'_both_dk.ster, replace)

  //rename va estimates sand outcome residuals
  rename tv va_`outcome'_both_dk
  rename score_r `outcome'_r_both_dk
  label var va_`outcome'_both_dk "``outcome'_str' DK VA with Sibling and Census Controls"
  label var `outcome'_r_both_dk "Outcome Residual from ``outcome'_str' DK VA with Sibling and Census Controls"


  *******************
  // specification test: regress outcome residuals on va estimates
  reg `outcome'_r_both_dk va_`outcome'_both_dk, cluster(school_id)

  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/spec_test_`outcome'_both_dk.ster, replace


  *******************
  // forecast bias test for sibling controls as leave out vars against specification with only census controls
  // difference in outcome residuals with census controls and residuals with both census and sibling controls
  gen `outcome'_r_d_acs_both_dk = `outcome'_r_acs_dk - `outcome'_r_both_dk
  // fb test
  reg `outcome'_r_d_acs_both_dk va_`outcome'_acs_dk, cluster(school_id)
  //naming convention: forecast bias test for leave out variables being sibling controls, against VA with only acs controls
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_sib_acs_dk.ster, replace

  *******************
  // forecast bias test for census controls as leave out vars against specification with only sibling controls
  // difference in outcome residuals with census controls and residuals with both census and sibling controls
  gen `outcome'_r_d_sib_both_dk = `outcome'_r_sib_dk - `outcome'_r_both_dk
  // fb test
  reg `outcome'_r_d_sib_both_dk va_`outcome'_sib_dk, cluster(school_id)
  estimates save $vaprojdir/estimates/sib_acs_restr_smp/outcome_va/fb_test_`outcome'_acs_sib_dk.ster, replace




  ********* Save VA estimates
  collapse (firstnm) va_* ///
    (mean) `outcome'* ///
    (sum) n_g11_`outcome'_dk = touse_`outcome'_dk ///
    , by(school_id cdscode grade year)
  // save to VA project data folder
  save $vaprojdir/data/sib_acs_restr_smp/outcome_va/va_`outcome'_sib_acs_dk.dta, replace


}








timer off 1
timer list

set trace off

//change directory back to my own personal directory
cd $projdir 

log close
translate $projdir/log/share/siblingvaregs/va_sib_acs_out_dk.smcl $projdir/log/share/siblingvaregs/va_sib_acs_out_dk.log, replace
