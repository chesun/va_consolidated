********************************************************************************
/* Creates figures for regressions of enrollment outcomes on deep knowledge VA
interacted with prior score deciles from the restricted sibling census sample */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 14, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/reg_out_va_sib_acs_dk_fig

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
log using $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_dk_fig.smcl, replace

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

********** assign non-het outcome on dk va regression coefficients to scalars
foreach outcome in enr enr_2year enr_4year {
  di "LHS outcome = RHS DK outcome = `outcome'"

  foreach control in og acs sib both {
    di "RHS VA control = `control'"

    //pull the regreession estimates from outcome on only dk VA, matching outcomes
    estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_`outcome'_`control'_dk.ster

    // assign a tempname to a local macro name
    tempname `outcome'_va_`outcome'_dk_`control'
    // assign the coefficient value from the regression to a scalar
    scalar ``outcome'_va_`outcome'_dk_`control'' = _b[va_`outcome'_`control'_dk]
  }
}


********** make individual figures for outcome on dk VA by prior score decile heterogeneity
foreach outcome in enr enr_2year enr_4year {
  di "LHS outcome = RHS DK outcome = `outcome'"

  foreach control in og acs sib both {
    di "RHS DK VA: Deep Knowledge VA with `control' controls"

    foreach prior_subject in ela math {
      di "interaction with prior `prior_subject' score deciles "

      estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_`outcome'_`control'_dk_x_prior_`prior_subject'.ster
      // convert estimation results into a dataset
      parmest, norestore
      // keep only the interaction parameters
      keep if strpos(parm, "prior_`prior_subject'_z_score_xtile#c.va_`outcome'_`control'_dk") != 0
      // generate a var that is the decile number of the prior score, from 1 to 10
      gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")), "b", "", .)
      // convert xtile var into a numeric var
      destring xtile, replace

      twoway ///
        (bar estimate xtile) ///
        (rcap min95 max95 xtile) ///
        , yline(`=``outcome'_va_`outcome'_dk_`control''') ///
        legend(off) ///
        ytitle("Coefficient Estimate") ///
        xtitle("Prior ``prior_subject'_str' Score Decile") ///
        title("LHS = ``outcome'_str'; RHS = ``outcome'_str' DK VA w/ ``control'_str' Controls # Prior ``prior_subject'_str' Decile" ///
        , size(vsmall))

      graph export $vaprojdir/figures/va_sib_acs/het_reg_dk_prior_score/het_reg_`outcome'_va_`outcome'_`control'_dk_x_prior_`prior_subject'.pdf, replace
      graph export $projdir/out/graph//siblingvaregs/persistence/sib_acs_restr_smp/het_reg_dk_prior_score/het_reg_`outcome'_va_`outcome'_`control'_dk_x_prior_`prior_subject'.pdf, replace

      // redraw the graph to be used for combining into panels
      twoway ///
        (bar estimate xtile) ///
        (rcap min95 max95 xtile) ///
        , yline(`=``outcome'_va_`outcome'_dk_`control''') ///
        legend(off) ///
        ytitle("Coefficient Estimate") ///
        xtitle("Prior ``prior_subject'_str' Score Decile") ///
        title("Restricted Sample, ``control'_str' Controls", size(vsmall)) ///
        saving($vaprojdir/gph_files/va_sib_acs/het_reg_dk_prior_score/het_reg_`outcome'_va_`outcome'_`control'_dk_x_prior_`prior_subject', replace)
    }
  }
}


********** combine figures into panels
/* Original sample,
restricted sample with original controls,
restricted sample with sibling controls,
restricted sample with both sibling and census controls: 4 graphs in one panel */

// 3 outcomes, 2 prior subjects = 6 graphs
foreach outcome in enr enr_2year enr_4year {
  di "LHS outcome = RHS DK outcome = `outcome'"

  foreach prior_subject in ela math {
    di "interaction with prior `prior_subject' score deciles "

    graph combine ///
      $vaprojdir/gph_files/sbac/reg_`outcome'_va_cfr_g11_`outcome'_dk_hetero_prior_`prior_subject'.gph ///
      $vaprojdir/gph_files/va_sib_acs/het_reg_dk_prior_score/het_reg_`outcome'_va_`outcome'_og_dk_x_prior_`prior_subject'.gph ///
      $vaprojdir/gph_files/va_sib_acs/het_reg_dk_prior_score/het_reg_`outcome'_va_`outcome'_sib_dk_x_prior_`prior_subject'.gph ///
      $vaprojdir/gph_files/va_sib_acs/het_reg_dk_prior_score/het_reg_`outcome'_va_`outcome'_both_dk_x_prior_`prior_subject'.gph ///
      , xcommon ycommon ///
      title("Regression of ``outcome'_str' on ``outcome'_str' DK VA Interacted with Prior ``prior_subject'_str' Decile", size(small))

    graph export $vaprojdir/figures/va_sib_acs/combined_panels/het_reg_dk_prior_score/het_reg_`outcome'_va_`outcome'_dk_x_prior_`prior_subject'.pdf, replace
    graph export $projdir/out/graph//siblingvaregs/persistence/sib_acs_restr_smp/combined_panels/het_reg_dk_prior_score/het_reg_`outcome'_va_`outcome'_dk_x_prior_`prior_subject'.pdf, replace




  }
}







timer off 1
timer list

set trace off
cd $projdir

log close
translate $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_dk_fig.smcl $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_dk_fig.log, replace
