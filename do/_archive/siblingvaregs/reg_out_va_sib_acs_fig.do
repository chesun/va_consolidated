********************************************************************************
/* Creates figures for regressions of enrollment outcomes on test score VA
interacted with prior score deciles from the restricted sibling census sample */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on May 12, 2022 ***************************

/* To run this do file:

do $projdir/do/share/siblingvaregs/reg_out_va_sib_acs_fig

 */

/* CHANGE LOG
5/23/2022: Added code to create individual figures and combined panels for regressions
by prior score by SED status heterogeneity

11/28/2022: debugged code snippet gen xtile = subinstr()
need to make 2 colors for figures with both VA het by prior score  
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
log using $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_fig.smcl, replace

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

********** assign outcome on test score VA regression coefficients to scalars
foreach outcome in enr enr_2year enr_4year {
  di "LHS = `outcome'"

  foreach subject in ela math {
    di "RHS VA subject = `subject'"

    foreach control in og acs sib both {
      di "RHS VA control = `control'"

      // pull the regression estimates from regressing outcome on only one subject VA
      estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_`subject'_`control'.ster

      // assign a tempname to a local macro name
      tempname `outcome'_va_`subject'_`control'
      // assign the coefficient value from the regression to a scalar
      scalar ``outcome'_va_`subject'_`control'' = _b[va_`subject'_`control']

    }
  }


  foreach control in og acs sib both {
    // pull the regression estimates from regressing outcome on both subject VAs
    estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/reg_`outcome'_va_ela_math_`control'.ster

    //assign tempname
    // naming convention: coefficient of outcome on both va (with specified controls) regression, coefficient on ela term
    tempname `outcome'_va_both_`control'_ela
    tempname `outcome'_va_both_`control'_math
    //assign the coefficient value to scalar with the name
    scalar ``outcome'_va_both_`control'_ela' = _b[va_ela_`control']
    scalar ``outcome'_va_both_`control'_math' = _b[va_math_`control']

  }
}


********** make figures for prior score heterogeneity regressions

foreach outcome in enr enr_2year enr_4year {
  di "LHS = `outcome'"

  // regression of outcome on single test score VA interacted with prior score decile by prior subject
  // 3 outcomes, 2 subject VAs, 2 prior scores, 4 VA specifications = 48 regressions

  foreach subject in ela math {
    di "VA Subject = `subject'"

    foreach control in og acs sib both {
      di "`subject' test score VA with `control' controls"

      foreach prior_subject in ela math {
        di "interaction with prior `prior_subject' score deciles"

        // pull the estimates from regression of outcome on single subject VA interacted with single prior subject score decile
        estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'.ster
        // convert estimation results into a dataset
        parmest, norestore
        // keep only the interaction parameters
        keep if strpos(parm, "prior_`prior_subject'_z_score_xtile#c.va_`subject'_`control'") != 0
        // generate a var that is the decile number of the prior score, from 1 to 10
        gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")-1), "b", "", .)
        // convert xtile var into a numeric var
        destring xtile, replace

        // twoway graph 1) bar graph of coefficient estimates 2) rcap for 90% CI
        // draw horizontal yline at the coefficient estimate from regression with only the subject VA, no interaction
        twoway ///
          (bar estimate xtile) ///
          (rcap min95 max95 xtile) ///
          , yline(`=``outcome'_va_`subject'_`control''') ///
          legend(off) ///
          ytitle("Coefficient Estimate") ///
          xtitle("Prior ``prior_subject'_str' Score Decile") ///
          title("LHS = ``outcome'_str'; RHS = ``subject'_str' VA w/ ``control'_str' Controls # Prior ``prior_subject'_str' Decile" ///
          , size(vsmall))


        graph export $vaprojdir/figures/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'.pdf, replace
        graph export $projdir/out/graph//siblingvaregs/persistence/sib_acs_restr_smp/het_reg_prior_score/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'.pdf, replace

        // redraw the graph to be used for combining into panels
        twoway ///
          (bar estimate xtile) ///
          (rcap min95 max95 xtile) ///
          , yline(`=``outcome'_va_`subject'_`control''') ///
          legend(off) ///
          ytitle("Coefficient Estimate") ///
          xtitle("Prior ``prior_subject'_str' Score Decile") ///
          title("Restricted Sample, ``control'_str' Controls", size(vsmall)) ///
          saving($vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject', replace)
      }
    }
  }


  // regression of outcome on both test score VAs interacted with prior score decile by prior subject
  // 3 outcomes, 2 prior subjects, 4 specifications = 24 regressions
  foreach control in og acs sib both {
    di "`subject' test score VA with `control' controls"

    foreach prior_subject in ela math {
      di "interaction with prior `prior_subject' score deciles"

      // pull the regression estimates
      estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_ela_math_`control'_x_prior_`prior_subject'.ster
      // convert to dataset
      parmest, norestore
      // keep only interaction parameters
      keep if strpos(parm, "prior_`prior_subject'_z_score_xtile#c.va_ela_`control'")!=0 | strpos(parm, "prior_`prior_subject'_z_score_xtile#c.va_math_`control'")!=0
      // create a var that is the decile number of the prior score, from 1 to 10
      gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")-1), "b", "", .)
      // convert xtile var into a numeric var
      destring xtile, replace

      // two way graph
      // yline 1: coefficient estimate of ELA VA from regression with both subject VA without interactions
      // yline 2: coefficient estimate of Math VA from regression with both subject VA without interactions
      twoway ///
        (bar estimate xtile) ///
        (rcap min95 max95 xtile) ///
        , yline(`=``outcome'_va_both_`control'_ela'')  ///
        yline(`=``outcome'_va_both_`control'_math'') ///
        legend(off) ///
        ytitle(Coefficient Estimate) ///
        xtitle("Prior ``prior_subject'_str' Score Decile") ///
        title("LHS = ``outcome'_str'; RHS = Both VA w/ ``control'_str' Controls # Prior ``prior_subject'_str' Decile" ///
        , size(vsmall))

      graph export $vaprojdir/figures/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_both_`control'_x_prior_`prior_subject'.pdf, replace
      graph export $projdir/out/graph//siblingvaregs/persistence/sib_acs_restr_smp/het_reg_prior_score/het_reg_`outcome'_va_both_`control'_x_prior_`prior_subject'.pdf, replace
    }
  }


}



********** combine het by prior score decile figures into panels
/* Original sample,
restricted sample with original controls,
restricted sample with sibling controls,
restricted sample with both sibling and census controls: 4 graphs in one panel */

// 3 outcomes, 2 VA subjects, 2 prior subjects = 12 panels
foreach outcome in enr enr_2year enr_4year {
  di "LHS outcome = `outcome'"

  foreach subject in ela math {
    di "VA Subject = `subject'"

    foreach prior_subject in ela math {
      di "interaction with prior `prior_subject' score deciles"

      graph combine ///
        $vaprojdir/gph_files/sbac/reg_`outcome'_va_`subject'_hetero_prior_`prior_subject'.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_og_x_prior_`prior_subject'.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_sib_x_prior_`prior_subject'.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_both_x_prior_`prior_subject'.gph ///
        , xcommon ycommon ///
        title("Regression of ``outcome'_str' on ``subject'_str' VA Interacted with Prior ``prior_subject'_str' Decile", size(small))

      graph export $vaprojdir/figures/va_sib_acs/combined_panels/het_reg_prior_score/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'.pdf, replace
      graph export $projdir/out/graph//siblingvaregs/persistence/sib_acs_restr_smp/combined_panels/het_reg_prior_score/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'.pdf, replace




    }
  }
}


********** make individual figures for heterogeneity by prior score decile by SED status
foreach outcome in enr enr_2year enr_4year {
  di "Dependent Var = `outcome'"

  foreach subject in ela math {
    di "VA Subject = `subject'"

    foreach control in og acs sib both {
      di "`subject' test score VA with `control' controls"

      foreach prior_subject in ela math {
        di "interaction with prior `prior_subject' score deciles"

        foreach sed_status in 0 1 {
          di "SED status = `sed_status'"

          estimates use $vaprojdir/estimates/sib_acs_restr_smp/persistence/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'_sed`sed_status'.ster

          // convert estimation results into a dataset
          parmest, norestore
          // keep only the interaction parameters
          keep if strpos(parm, "prior_`prior_subject'_z_score_xtile#c.va_`subject'_`control'") != 0
          // generate a var that is the decile number of the prior score, from 1 to 10
          gen xtile = subinstr(substr(parm, 1, strpos(parm, ".")), "b", "", .)
          // convert xtile var into a numeric var
          destring xtile, replace

          twoway ///
            (bar estimate xtile) ///
            (rcap min95 max95 xtile) ///
            , yline(`=``outcome'_va_`subject'_`control''') ///
            legend(off) ///
            ytitle("Coefficient Estimate") ///
            xtitle("Prior ``prior_subject'_str' Score Decile") ///
            title("LHS = ``outcome'_str'; RHS = ``subject'_str' VA w/ ``control'_str' Controls # Prior ``prior_subject'_str' Decile, SED Status = `sed_status'" ///
            , size(vsmall))


          graph export $vaprojdir/figures/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'_sed`sed_status'.pdf, replace
          graph export $projdir/out/graph//siblingvaregs/persistence/sib_acs_restr_smp/het_reg_prior_score/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'_sed`sed_status'.pdf, replace

          // redraw the graph to be used for combining into panels
          twoway ///
            (bar estimate xtile) ///
            (rcap min95 max95 xtile) ///
            , yline(`=``outcome'_va_`subject'_`control''') ///
            legend(off) ///
            xtitle("Prior ``prior_subject'_str' Score Decile, SED = `sed_status'") ///
            title("Restricted Sample, ``control'_str' Controls", size(vsmall)) ///
            saving($vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_`control'_x_prior_`prior_subject'_sed`sed_status', replace)


        }

      }
    }
  }
}



********** combine het by prior score decile by SED Status figures into panels
/* Original sample,
restricted sample with original controls,
restricted sample with sibling controls,
restricted sample with both sibling and census controls,
each by SED == 1 and SED == 1: 8 graphs in one panel */

// 3 outcomes, 2 VA subjects, 2 prior subjects = 12 panels
foreach outcome in enr enr_2year enr_4year {
  di "LHS outcome = `outcome'"

  foreach subject in ela math {
    di "VA Subject = `subject'"

    foreach prior_subject in ela math {
      di "interaction with prior `prior_subject' score deciles"

      graph combine ///
        $vaprojdir/gph_files/sbac/reg_`outcome'_va_cfr_g11_`subject'_hetero_prior_`prior_subject'_sed0.gph ///
        $vaprojdir/gph_files/sbac/reg_`outcome'_va_cfr_g11_`subject'_hetero_prior_`prior_subject'_sed1.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_og_x_prior_`prior_subject'_sed0.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_og_x_prior_`prior_subject'_sed1.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_sib_x_prior_`prior_subject'_sed0.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_sib_x_prior_`prior_subject'_sed1.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_both_x_prior_`prior_subject'_sed0.gph ///
        $vaprojdir/gph_files/va_sib_acs/het_reg_prior_score/het_reg_`outcome'_va_`subject'_both_x_prior_`prior_subject'_sed1.gph ///
        , xcommon ycommon ///
        title("Regression of ``outcome'_str' on ``subject'_str' VA Interacted with Prior ``prior_subject'_str' Decile by SED Status", size(small))

      graph export $vaprojdir/figures/va_sib_acs/combined_panels/het_reg_prior_score/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'_sed.pdf, replace
      graph export $projdir/out/graph//siblingvaregs/persistence/sib_acs_restr_smp/combined_panels/het_reg_prior_score/het_reg_`outcome'_va_`subject'_x_prior_`prior_subject'_sed.pdf, replace




    }
  }
}




timer off 1
timer list

cd $projdir
set trace off

log close
translate $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_fig.smcl $projdir/log/share/siblingvaregs/reg_out_va_sib_acs_fig.log, replace
