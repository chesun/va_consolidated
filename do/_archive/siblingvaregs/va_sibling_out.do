********************************************************************************
/* do file to run enrollment outcome VA regressions with sibling effects.
Include as controls the dummies for
1) has an older sibling enrolled in 2 year
2) has an older sibling enrolled in 4 year

Comment on family fixed effects: Too many fixed effects, not enough observations. */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on Nov 3, 2021 ***************************

/* To run this do file:
for origianl drift limit
do $projdir/do/share/siblingvaregs/va_sibling_out 0

otherwise set a number if encounting an error

do $projdir/do/share/siblingvaregs/va_sibling_out 2

 */



/* Change log:
1.6.2022: updated do file to reconcile server file path changes, re-ran
with drift limit = 2. Still produces an error if drift limit = 3

March 31, 2022:
- Added code for the vam command to save the point estimates from
the vam regressions. .ster files are saved to VA project folder.
- Also commented out the TFX regs and the peer effects regs since they are not
used for siblings.
- Moved spec tests to right after the vam commands so that the indep var names
are all the same for ease of making coefficient tables
- Added var renaming gymnastics for fb test so that the indep var names
are all the same for ease of making coefficient tables
*/



//install VAM package to estimate value added models a la Chetty, Freidman, and Rockoff
/* ssc install vam, replace  */
clear all
set more off
set varabbrev off
set scheme s1color
//capture log close: Stata should not complain if there is no log open to close
cap log close _all

args setlimit

/* file path macros for datasets and folders */
include $projdir/do/share/siblingvaregs/vafilemacros.doh

//change directory to common_core_va project directory
cd $vaprojdir

//starting log file
log using $projdir/log/share/siblingvaregs/va_sibling_out.smcl, replace

//run the do helper file to set the local macros
include `vaprojdofiles'/sbac/macros_va.doh

#delimit ;
#delimit cr
macro list


timer on 1


//load the VA grade 11 college outcomes sample
use `va_g11_out_dataset', clear

//merge on to sibling outcomes crosswalk to get sibling enrollment controls
merge m:1 state_student_id using `sibling_out_xwalk', nogen keep(1 3)

drop if mi(has_older_sibling_enr_2year)
drop if mi(has_older_sibling_enr_4year)

compress
tempfile va_g11_out_sibling_dataset
save `va_g11_out_sibling_dataset'




********************************************************************************
*********** VA estimates for VA samples matched to siblings sample
********************************************************************************
if `setlimit' == 0 {
  local drift_limit = max(`test_score_max_year' - `test_score_min_year' - 1, 1)
}
else {
  local drift_limit = `setlimit'
}

foreach outcome in enr enr_2year enr_4year {
  use `va_g11_out_sibling_dataset' if touse_g11_`outcome'==1 & sibling_out_sample == 1, clear

  ***********************Overall value added
  **** No Peer Controls
  ** No TFX
    ***without sibling college going controls
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
      estimates($vaprojdir/estimates/sibling_va/outcome_va/vam_cfr_g11_`outcome'_nosibctrl.ster, replace)

    //rename the first time to make sure indep var names for spec test are all the same
    rename tv va_cfr_g11_`outcome'
    rename score_r g11_`outcome'_r

    **************** Specification Test
    *************** No Peer Controls
    ****** sibling sample without sibling controls
    reg g11_`outcome'_r va_cfr_g11_`outcome', cluster(school_id)
    //save to my personal folder
    estimates save $projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_sibling_nocontrol.ster, replace
    //save to va project folder
    estimates save $vaprojdir/estimates/sibling_va/outcome_va/spec_test_va_cfr_g11_`outcome'_sibling_nocontrol.ster, replace

    //rename again to distinguish between nocontrol and with control va estimates
    rename va_cfr_g11_`outcome' va_cfr_g11_`outcome'_nosibctrl
    rename g11_`outcome'_r g11_`outcome'_r_nosibctrl


    *** with sibling controls
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
      estimates($vaprojdir/estimates/sibling_va/outcome_va/vam_cfr_g11_`outcome'.ster, replace)
    rename tv va_cfr_g11_`outcome'
    rename score_r g11_`outcome'_r

    **************** Specification Test
    *************** No Peer Controls
    ****** sibling sample with sibling controls
    reg g11_`outcome'_r va_cfr_g11_`outcome', cluster(school_id)
    //save to my personal folder
    estimates save $projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_sibling.ster, replace
    //save to va project folder
    estimates save $vaprojdir/estimates/sibling_va/outcome_va/spec_test_va_cfr_g11_`outcome'_sibling.ster, replace






/*

  ** TFX
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
		tfx_resid(school_id) ///
		data(merge tv score_r) ///
		driftlimit(`drift_limit')
	rename tv va_tfx_g11_`outcome'
	drop score_r

  corr va_cfr_g11_`outcome' va_tfx_g11_`outcome'

 */
















  **** Peer Controls
	** No TFX

    /* ***without sibling college going controls
    vam `outcome' ///
      , teacher(school_id) year(year) class(school_id) ///
      controls( ///
        i.year ///
        `school_controls' ///
        `demographic_controls' ///
        `ela_score_controls' ///
        `math_score_controls' ///
        `peer_demographic_controls' ///
        `peer_ela_score_controls' ///
        `peer_math_score_controls' ///
      ) ///
      data(merge tv score_r) ///
      driftlimit(`drift_limit')
    rename tv
    rename score_r

    //with sibling controls
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
  			`peer_demographic_controls' ///
  			`peer_ela_score_controls' ///
  			`peer_math_score_controls' ///
  		) ///
  		data(merge tv score_r) ///
  		driftlimit(`drift_limit')
  	rename tv va_cfr_g11_`outcome'_peer
  	rename score_r g11_`outcome'_r_peer

	** TFX
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
			`peer_demographic_controls' ///
			`peer_ela_score_controls' ///
			`peer_math_score_controls' ///
		) ///
		tfx_resid(school_id) ///
		data(merge tv score_r) ///
		driftlimit(`drift_limit')
	rename tv va_tfx_g11_`outcome'_peer
	drop score_r

	corr va_cfr_g11_`outcome'_peer va_tfx_g11_`outcome'_peer
 */



********************************************************************************
  **************** Specification Test

  /* **** Peer Controls
  reg g11_`outcome'_r_peer va_cfr_g11_`outcome'_peer, cluster(school_id)
  estimates save $projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_peer_sibling.ster, replace

 */


  *** no peer controls

  /* *** with peer controls
  reg g11_`outcome'_r_nosibctrl_peer va_cfr_g11_`outcome'_nosibctrl_peer, cluster(school_id)
  estimates save $projdir/est/siblingvaregs/outcome_va/spec_test_va_cfr_g11_`outcome'_peer_sibling_nocontrol.ster, replace */

  **************Do we need deep knowledge VA with sibling controls?? No.




  ******************************************************************************
  /* CFR Forecast Bias Test */
  ***** leave out variable is sibling controls


  **no peer controls
  gen g11_`outcome'_r_d = g11_`outcome'_r_nosibctrl - g11_`outcome'_r

  //var rename gymnastics to make sure the indep var names are all the same when making tables later
  rename va_cfr_g11_`outcome' va_cfr_g11_`outcome'_temp
  rename va_cfr_g11_`outcome'_nosibctrl va_cfr_g11_`outcome'

  reg g11_`outcome'_r_d va_cfr_g11_`outcome', cluster(school_id)
  //save to my personal folder
  estimates save $projdir/est/siblingvaregs/outcome_va/fb_test_va_cfr_g11_`outcome'_sibling.ster, replace
  //save to va project folder
  estimates save $vaprojdir/estimates/sibling_va/outcome_va/fb_test_va_cfr_g11_`outcome'_sibling.ster, replace

  //roll back the rename gymnastics to restore original var names
  rename va_cfr_g11_`outcome' va_cfr_g11_`outcome'_nosibctrl
  rename va_cfr_g11_`outcome'_temp va_cfr_g11_`outcome'


  /* ** with peer controls
  gen g11_`outcome'_r_d_peer = g11_`outcome'_r_nosibctrl_peer - g11_`outcome'_r_peer
  reg g11_`outcome'_r_d_peer va_cfr_g11_`outcome'_nosibctrl_peer, cluster(school_id)
  estimates save $projdir/est/siblingvaregs/outcome_va/fb_test_va_cfr_g11_`outcome'_sibling_peer.ster, replace
 */



  **************** Save Value Added Estimates
  collapse (firstnm) va_* ///
    (mean) g11_`outcome'* ///
    (sum) n_g11_`outcome' = touse_g11_`outcome' ///
    , by(school_id cdscode grade year)
  //save to my personal folder
  save $projdir/dta/common_core_va/outcome_va/va_g11_`outcome'_sibling.dta, replace
  //save to VA project folder
  save $vaprojdir/data/sibling_va/outcome_va/va_g11_`outcome'_sibling.dta, replace


}









timer off 1
timer list
log close

//change directory back
cd $projdir

//translate the log file to a text log file
translate $projdir/log/share/siblingvaregs/va_sibling_out.smcl ///
 $projdir/log/share/siblingvaregs/va_sibling_out.log, replace
