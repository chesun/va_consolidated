********************************************************************************
/* do file to run forecast bias test on sibling long run outcomes VA sample, using
census tract variables as leave out variables . */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on April 14. 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/va_sibling_out_forecast_bias

 */

 /* CHANGE LOG
4/28/2022: Updated code that merge acs controls. Put the subroutine into a do helper
file in the common core VA proj dir, $vaprojdir/do_files/sbac/merge_va_smp_acs.doh,
just call it when needed. Be sure to specify the correct arguments. There are 5 args for the do heper file.
  */

clear all
set more off
set varabbrev off
set scheme s1color
//capture log close: Stata should not complain if there is no log open to close
cap log close _all

/* set trace on
set tracedepth 1 */


/* file path macros for datasets */
include $projdir/do/share/siblingvaregs/vafilemacros.doh

//change directory to common_core_va project directory
cd $vaprojdir

//starting log file
log using $projdir/log/share/siblingvaregs/va_sibling_out_forecast_bias.smcl, replace

//run the do helper file to set the local macros
include `vaprojdofiles'/sbac/macros_va.doh

#delimit ;
#delimit cr
macro list


timer on 1



********************************************************************************

//load the VA grade 11 college outcomes sample
use `va_g11_out_dataset', clear

//merge on to sibling outcomes crosswalk to get sibling enrollment controls
merge m:1 state_student_id using `sibling_out_xwalk', nogen keep(1 3)

// keep the sibling controls sample for 2yr and 4yr sibling enrollment controls 
keep if sibling_2y_4y_controls_sample==1

compress
tempfile va_g11_out_sibling_dataset
save `va_g11_out_sibling_dataset'



********************************************************************************
*********** VA estimates for sibling VA sample matched to census tract sample
********************************************************************************

local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)



foreach outcome in enr enr_2year enr_4year {

  *************** Census Tract Forecast Bias Test for Sibling Long Run Outcome VA
  // call do helper file to merge onto ACS controls. Be sure to specify correct arguments
   do $vaprojdir/do_files/sbac/merge_va_smp_acs.doh outcome `va_g11_out_sibling_dataset' va_g11_out_sibling_dataset create_va `outcome'



  **************** College Outcome VA without sibling controls
  ************** No peer controls
  ************* No TFX
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
    estimates($vaprojdir/estimates/sibling_va/outcome_va/vam_`outcome'_census_nosib_noacs.ster, replace)
  rename tv va_`outcome'_nosib_noacs
  rename score_r `outcome'_r_nosib_noacs

  ***** Spec Test: no peer controls, no tfx, no sibling controls
  reg `outcome'_r_nosib_noacs va_`outcome'_nosib_noacs, cluster(school_id)
  //save to my personal folder
  estimates save $projdir/est/siblingvaregs/outcome_va/spec_test_`outcome'_census_nosib_noacs.ster, replace
  //save to va project folder
  estimates save $vaprojdir/estimates/sibling_va/outcome_va/spec_test_`outcome'_census_nosib_noacs.ster, replace




  **************** College Outcome VA with sibling controls
  ************** No peer controls
  ************* No TFX

  vam `outcome' ///
    , teacher(school_id) year(year) class(school_id) ///
    controls( ///
      i.year ///
      i.has_older_sibling_enr_2year ///
      i.has_older_sibling_enr_4year ///
      `school_controls' ///
      `demographic_controls' ///
      `ela_score_controls' ///
      `math_score_controls' ///
    ) ///
    data(merge tv score_r) ///
    driftlimit(`drift_limit') ///
    estimates($vaprojdir/estimates/sibling_va/outcome_va/vam_`outcome'_census_noacs.ster, replace)

    rename tv va_`outcome'_noacs
    rename score_r `outcome'_r_noacs

    ***** Spec Test: no peer controls, no tfx, with sibling controls
    reg `outcome'_r_noacs va_`outcome'_noacs, cluster(school_id)
    //save to my personal folder
    estimates save $projdir/est/siblingvaregs/outcome_va/spec_test_`outcome'_census_noacs.ster, replace
    //save to va project folder
    estimates save $vaprojdir/estimates/sibling_va/outcome_va/spec_test_`outcome'_census_noacs.ster, replace



    **************** College Outcome VA with sibling controls and census controls
    ************** No peer controls
    ************* No TFX
    vam `outcome' ///
      , teacher(school_id) year(year) class(school_id) ///
      controls( ///
        i.year ///
        i.has_older_sibling_enr_2year ///
        i.has_older_sibling_enr_4year ///
        `school_controls' ///
        `demographic_controls' ///
        `ela_score_controls' ///
        `math_score_controls' ///
        `census_controls' ///
      ) ///
      data(merge tv score_r) ///
      driftlimit(`drift_limit') ///
      estimates($vaprojdir/estimates/sibling_va/outcome_va/vam_`outcome'_sib_census.ster, replace)

      rename tv va_`outcome'_sib_census
      rename score_r `outcome'_r_sib_census


      ***** Forecast bias test for sibling census sample: census controls as leave out var
      gen `outcome'_r_d = `outcome'_r_noacs - `outcome'_r_sib_census
      reg `outcome'_r_d va_`outcome'_noacs, cluster(school_id)
      estimates save $projdir/est/siblingvaregs/outcome_va/fb_test_`outcome'_census.ster, replace
      estimates save $vaprojdir/estimates/sibling_va/outcome_va/fb_test_`outcome'_census.ster, replace


      **************** Save Value Added Estimates
      collapse (firstnm) va_* ///
        (mean) `outcome'* ///
        (sum) n_g11_`outcome' = touse_g11_`outcome' ///
        , by(school_id cdscode grade year)
      //save to my personal folder
      save $projdir/dta/common_core_va/outcome_va/va_g11_`outcome'_sibling_census.dta, replace
      //save to VA project folder
      save $vaprojdir/data/sibling_va/outcome_va/va_g11_`outcome'_sibling_census.dta, replace

}









timer off 1
timer list

log close
translate $projdir/log/share/siblingvaregs/va_sibling_out_forecast_bias.smcl $projdir/log/share/siblingvaregs/va_sibling_out_forecast_bias.log, replace
