/*------------------------------------------------------------------------------
do/share/va_scatter.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    VA scatter plots — score vs outcome VA, multiple specifications.  Paper producer (figures + tables) for the VA paper.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Reads CHAIN VA outputs from $estimates_dir/va_cfr_all_<version>/*
    (Step 3 batches 3a-3d) + sample data from LEGACY $vaprojdir/data/
    va_samples_v1/* (sample data not yet relocated; out of Step 10 scope).
    Writes paper-shipping outputs to $tables_dir/share/* + $figures_dir/share/*
    (CANONICAL).

INPUTS (verified via grep on file body)
    $consolidated_dir/do/va/helpers/drift_limit.doh  (helper include)
    $consolidated_dir/do/va/helpers/macros_va.doh  (helper include)
    $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta  (LEGACY)
    $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.gph  (LEGACY)
    $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.gph  (LEGACY)
    $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.gph  (LEGACY)
    $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.gph  (LEGACY)
    $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.gph  (LEGACY)
    $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.gph  (LEGACY)
    $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.gph  (LEGACY)
    $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.gph  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $figures_dir/share/va/`version'/het_reg_distance_va_`subject'_x_prior_`subject'_combined_`version'.pdf
    $figures_dir/share/va/`version'/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.pdf
    $figures_dir/share/va/`version'/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.pdf
    $figures_dir/share/va/`version'/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.pdf
    $figures_dir/share/va/`version'/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.pdf
    $figures_dir/share/va/`version'/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.pdf
    $figures_dir/share/va/`version'/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.pdf
    $figures_dir/share/va/`version'/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.pdf
    $figures_dir/share/va/`version'/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.pdf
    $figures_dir/share/va/`version'/het_reg_va_`subject'_x_prior_`subject'_combined_`version'.pdf
    $figures_dir/share/va/`version'/va_`outcome'_`subject'_scatter_b_sp_b_ct_`version'_nw.pdf
    $figures_dir/share/va/`version'/va_`outcome'_`subject'_scatter_b_sp_b_ct_`version'_wt.pdf
    $figures_dir/share/va/`version'/va_`outcome'_`subject'_scatter_las_sp_las_ct_p_`version'_nw.pdf
    $figures_dir/share/va/`version'/va_`outcome'_`subject'_scatter_las_sp_las_ct_p_`version'_wt.pdf
    $figures_dir/share/va/`version'/va_`va_outcome'_scatter_b_vs_las_sp_b_ct_`version'_nw.pdf
    ... +21 more (see body grep)

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/va_scatter.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                      -> removed (absolute paths)
      log_files/share/<x>.smcl (rel + abs forms)         -> $logdir/<x>.smcl  (CANONICAL)
      include $vaprojdir/do_files/sbac/<x>.doh           -> include $consolidated_dir/do/{va/helpers,samples}/<x>.doh
        (per Step 1/2 helper relocation; covers macros_va, drift_limit, create_diff_school_prop, create_prior_scores_v1/v2, merge_loscore, merge_sib, merge_lag2_ela, merge_va_smp_acs, create_va_g11_sample_v1/v2, create_va_g11_out_sample_v1/v2)
      $estimates_dir/va_cfr_all_<v>/* -> $estimates_dir/va_cfr_all_<v>/* (CHAIN read from Step 3)
      $estimates_dir/va_cfr_all_<v>/* -> $estimates_dir/va_cfr_all_<v>/* (CHAIN read; predecessor stored intermediate regsave dtas under tables/, consolidated relocates under $estimates_dir/)
      $vaprojdir/figures/share/* -> $figures_dir/share/* (CANONICAL paper-shipping)
      $vaprojdir/tables/share/* -> $tables_dir/share/* (CANONICAL paper-shipping)
      $vaprojdir/data/va_samples_v1/* -> kept LEGACY (sample data; out of Step 10 scope)
      translate (multi-line ABS form) -> $logdir/* (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10a
    Sister files (this batch): base_sum_stats_tab.do, kdensity.do, reg_out_va_tab.do, sample_counts_tab.do, svyindex_tab.do, va_spec_fb_tab_all.do, va_var_explain.do, va_var_explain_tab.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* 1) scatter plots for VA correlation, weighted by number of students contributing
to VA estimates
2) persistence het graphs */
********************************************************************************

*****************************************************
* First created by Christina Sun February 20, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/va_scatter.do
 */

/* CHANGE LOG:
03/13/2023:
added code for figure 3 alt: ELA vs Math VA scatter plot
fixed title issues
 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
cap log close _all

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/share"
cap mkdir "$tables_dir/share/va"
cap mkdir "$tables_dir/share/va/check"
cap mkdir "$tables_dir/share/va/pub"
cap mkdir "$tables_dir/share/survey"
cap mkdir "$tables_dir/share/survey/check"
cap mkdir "$tables_dir/share/survey/pub"
cap mkdir "$figures_dir"
cap mkdir "$figures_dir/share"
cap mkdir "$figures_dir/share/va"

log using "$logdir/va_scatter.smcl", replace text

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


local date1 = c(current_date)
local time1 = c(current_time)


include $consolidated_dir/do/va/helpers/macros_va.doh
include $consolidated_dir/do/va/helpers/drift_limit.doh



/* need to save number of observation vars in VA estimation do files */


/* do not need to weight by # observations contributing to VA estimates because
plotting VA from same sample, therefore same observations */

/* set trace on */

foreach version in v1 v2 {

  use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta, clear

  // scatter plots of single outcome VA switching sample or control
  foreach va_outcome in ela math enr_2year enr_4year {
    //------------------------------------------------------------------------------
    // Figure 1: same sample, change controls
    // y axis: kutchen sink sample base control no peer
    // x axis: kitchen sink sample kitchen sink control woth peer
    //------------------------------------------------------------------------------

    //------------------------------------------------------------------------
    // create macros for correlation coefficients
    //------------------------------------------------------------------------
    corr va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_las_ct_p
    local corr_`va_outcome'_1: di %5.3f r(rho)

    //------------------------------------------------------------------------
    // create macros for regression coefficients
    //------------------------------------------------------------------------
    reg va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_las_ct_p
    local b_`va_outcome'_1: di %5.3f _b[va_`va_outcome'_las_sp_las_ct_p]


    //------------------------------------------------------------------------
    // scatter plot
    //------------------------------------------------------------------------
    // weighted
    twoway (scatter va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_las_ct_p [aw=n_g11_`va_outcome'_las_sp], msymbol(o) mcolor(%20)) ///
      (lfit va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_las_ct_p) ///
      , ytitle("Base Specification", margin(medium) size(small)) ///
      xtitle("Full Specification with Peer Controls", size(small)) ///
      title("``va_outcome'_str' VA Correlation") ///
      legend(label(1 "``va_outcome'_str' VA") label(2 "Fitted line")) ///
      note("Sample: Fully Restricted (Base + Leave Out Score + ACS + Sibling)" ///
      "Correlation Coefficient = `corr_`va_outcome'_1'" ///
      "Fitted line slope = `b_`va_outcome'_1'")

    // export single panel figure
    graph export $figures_dir/share/va/`version'/va_`va_outcome'_scatter_las_sp_b_vs_las_ct_p_`version'_wt.pdf, replace

    // unweighted
    twoway (scatter va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_las_ct_p) ///
      (lfit va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_las_ct_p) ///
      , ytitle("Base Specification", margin(medium) size(small)) ///
      xtitle("Full Specification with Peer Controls", size(small)) ///
      title("``va_outcome'_str' VA Correlation") ///
      legend(label(1 "``va_outcome'_str' VA") label(2 "Fitted line")) ///
      note("Sample: Fully Restricted (Base + Leave Out Score + ACS + Sibling)" ///
      "Correlation Coefficient = `corr_`va_outcome'_1'" ///
      "Fitted line slope = `b_`va_outcome'_1'")

    // export single panel figure
    graph export $figures_dir/share/va/`version'/va_`va_outcome'_scatter_las_sp_b_vs_las_ct_p_`version'_nw.pdf, replace


    // redraw the graph with different titles to be used for combining into panels
    twoway (scatter va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_las_ct_p ///
      ,  msize(small) ) ///
      (lfit va_`va_outcome'_las_sp_b_ct va_`va_outcome'_las_sp_las_ct_p) ///
      , title("``va_outcome'_str' VA Correlation", size(small)) ///
      legend(off) ytitle("") xtitle("") ///
      note( "Correlation Coefficient = `corr_`va_outcome'_1'" ///
      "Fitted line slope = `b_`va_outcome'_1'") ///
      saving($output_dir/gph_files/va_cfr_all_`version'/va_`va_outcome'_scatter_las_sp_b_vs_las_ct_p_`version'_nw, replace)

    //------------------------------------------------------------------------------
    // Figure 2: same control, change sample
    // y axis: base sample base control no peer
    // x axis: kitchen sink sample base ontrol no peer
    //------------------------------------------------------------------------------

    //------------------------------------------------------------------------
    // create macros for correlation coefficients
    //------------------------------------------------------------------------
    corr va_`va_outcome'_b_sp_b_ct va_`va_outcome'_las_sp_b_ct
    local corr_`va_outcome'_2: di %5.3f r(rho)

    //------------------------------------------------------------------------
    // create macros for regression coefficients
    //------------------------------------------------------------------------
    reg va_`va_outcome'_b_sp_b_ct va_`va_outcome'_las_sp_b_ct
    local b_`va_outcome'_2: di %5.3f _b[va_`va_outcome'_las_sp_b_ct]


    //------------------------------------------------------------------------
    // scatter plot
    //------------------------------------------------------------------------
    // weighted
    twoway (scatter va_`va_outcome'_b_sp_b_ct va_`va_outcome'_las_sp_b_ct [aw=n_g11_`va_outcome'_b_sp + n_g11_`va_outcome'_las_sp], msymbol(o) mcolor(%20)) ///
      (lfit va_`va_outcome'_b_sp_b_ct va_`va_outcome'_las_sp_b_ct) ///
      , ytitle("Base Sample", margin(medium) size(small)) ///
      xtitle("Fully Restricted Sample", size(small)) ///
      title("``va_outcome'_str' VA Correlation") ///
      legend(label(1 "``va_outcome'_str' VA") label(2 "Fitted line")) ///
      note("Controls: Base controls without peer controls" ///
      "Correlation Coefficient = `corr_`va_outcome'_2'" ///
      "Fitted line slope = `b_`va_outcome'_2'")


    graph export $figures_dir/share/va/`version'/va_`va_outcome'_scatter_b_vs_las_sp_b_ct_`version'_wt.pdf, replace

    // unweighted
    twoway (scatter va_`va_outcome'_b_sp_b_ct va_`va_outcome'_las_sp_b_ct) ///
      (lfit va_`va_outcome'_b_sp_b_ct va_`va_outcome'_las_sp_b_ct) ///
      , ytitle("Base Sample", margin(medium) size(small)) ///
      xtitle("Fully Restricted Sample", size(small)) ///
      title("``va_outcome'_str' VA Correlation") ///
      legend(label(1 "``va_outcome'_str' VA") label(2 "Fitted line")) ///
      note("Controls: Base controls without peer controls" ///
      "Correlation Coefficient = `corr_`va_outcome'_2'" ///
      "Fitted line slope = `b_`va_outcome'_2'")


    graph export $figures_dir/share/va/`version'/va_`va_outcome'_scatter_b_vs_las_sp_b_ct_`version'_nw.pdf, replace


    // redraw the graph with different titles to be used for combining into panels
    twoway (scatter va_`va_outcome'_b_sp_b_ct va_`va_outcome'_las_sp_b_ct ///
            , msize(small) ) ///
      (lfit va_`va_outcome'_b_sp_b_ct va_`va_outcome'_las_sp_b_ct) ///
      , title("``va_outcome'_str' VA Correlation", size(small)) ///
      legend(off) ytitle("") xtitle("") ///
      note("Correlation Coefficient = `corr_`va_outcome'_2'" ///
      "Fitted line slope = `b_`va_outcome'_2'") ///
      saving($output_dir/gph_files/va_cfr_all_`version'/va_`va_outcome'_scatter_b_vs_las_sp_b_ct_`version'_nw, replace)


    //------------------------------------------------------------------------------
    // Figure 2 alt: same control, change sample
    // y axis: base sample base control with peer
    // x axis: kitchen sink sample cbase ontrol with peer
    //------------------------------------------------------------------------------

    //------------------------------------------------------------------------
    // create macros for correlation coefficients
    //------------------------------------------------------------------------
    corr va_`va_outcome'_b_sp_b_ct_p va_`va_outcome'_las_sp_b_ct_p
    local corr_`va_outcome'_2alt: di %5.3f r(rho)

    //------------------------------------------------------------------------
    // create macros for regression coefficients
    //------------------------------------------------------------------------
    reg va_`va_outcome'_b_sp_b_ct_p va_`va_outcome'_las_sp_b_ct_p
    local b_`va_outcome'_2alt: di %5.3f _b[va_`va_outcome'_las_sp_b_ct_p]


    //------------------------------------------------------------------------
    // scatter plot
    //------------------------------------------------------------------------
    // weighted
    twoway (scatter va_`va_outcome'_b_sp_b_ct_p va_`va_outcome'_las_sp_b_ct_p [aw=n_g11_`va_outcome'_b_sp + n_g11_`va_outcome'_las_sp], msymbol(o) mcolor(%20)) ///
      (lfit va_`va_outcome'_b_sp_b_ct_p va_`va_outcome'_las_sp_b_ct_p) ///
      , ytitle("Base Sample", margin(medium) size(small)) ///
      xtitle("Fully Restricted Sample", size(small)) ///
      title("``va_outcome'_str' VA Correlation") ///
      legend(label(1 "``va_outcome'_str' VA") label(2 "Fitted line")) ///
      note("Controls: Base controls with peer controls" ///
      "Correlation Coefficient = `corr_`va_outcome'_2alt'" ///
      "Fitted line slope = `b_`va_outcome'_2alt'")

    graph export $figures_dir/share/va/`version'/va_`va_outcome'_scatter_b_vs_las_sp_b_ct_p_`version'_wt.pdf, replace

    // unweighted
    twoway (scatter va_`va_outcome'_b_sp_b_ct_p va_`va_outcome'_las_sp_b_ct_p ) ///
      (lfit va_`va_outcome'_b_sp_b_ct_p va_`va_outcome'_las_sp_b_ct_p) ///
      , ytitle("Base Sample", margin(medium) size(small)) ///
      xtitle("Fully Restricted Sample", size(small)) ///
      title("``va_outcome'_str' VA Correlation") ///
      legend(label(1 "``va_outcome'_str' VA") label(2 "Fitted line")) ///
      note("Controls: Base controls with peer controls" ///
      "Correlation Coefficient = `corr_`va_outcome'_2alt'" ///
      "Fitted line slope = `b_`va_outcome'_2alt'")

    graph export $figures_dir/share/va/`version'/va_`va_outcome'_scatter_b_vs_las_sp_b_ct_p_`version'_nw.pdf, replace

    // redraw the graph with different titles to be used for combining into panels
    twoway (scatter va_`va_outcome'_b_sp_b_ct_p va_`va_outcome'_las_sp_b_ct_p ///
            ,  msize(small) ) ///
      (lfit va_`va_outcome'_b_sp_b_ct_p va_`va_outcome'_las_sp_b_ct_p) ///
      , title("``va_outcome'_str' VA Correlation", size(small)) ///
      legend(off) ytitle("") xtitle("") ///
      note(  "Correlation Coefficient = `corr_`va_outcome'_2alt'" ///
      "Fitted line slope = `b_`va_outcome'_2alt'") ///
      saving($output_dir/gph_files/va_cfr_all_`version'/va_`va_outcome'_scatter_b_vs_las_sp_b_ct_p_`version'_nw, replace)

  }

  //------------------------------------------------------------------------------
  // combining figure 1 and figure 2 panels
  //------------------------------------------------------------------------------

  // figure 1
  graph combine ///
    $output_dir/gph_files/va_cfr_all_`version'/va_ela_scatter_las_sp_b_vs_las_ct_p_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_math_scatter_las_sp_b_vs_las_ct_p_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_scatter_las_sp_b_vs_las_ct_p_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_enr_4year_scatter_las_sp_b_vs_las_ct_p_`version'_nw.gph ///
    ,      title("VA Correlation in Fully Restricted Sample") ///
    note("Y-axis: base specification with peer controls" ///
    "X-axis: full specification with peer controls")

  graph export $figures_dir/share/va/`version'/va_combined_scatter_las_sp_b_vs_las_ct_p_`version'_nw.pdf, replace


  // figure 2
  graph combine ///
    $output_dir/gph_files/va_cfr_all_`version'/va_ela_scatter_b_vs_las_sp_b_ct_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_math_scatter_b_vs_las_sp_b_ct_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_scatter_b_vs_las_sp_b_ct_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_enr_4year_scatter_b_vs_las_sp_b_ct_`version'_nw.gph ///
    ,      title("VA Correlation in Base Specification, No Peer Controls") ///
    note("Y-axis: base sample" ///
    "X-axis: fully restricted sample")

  graph export $figures_dir/share/va/`version'/va_combined_scatter_b_vs_las_sp_b_ct_`version'_nw.pdf, replace


  // figure 2 alt
  graph combine ///
    $output_dir/gph_files/va_cfr_all_`version'/va_ela_scatter_b_vs_las_sp_b_ct_p_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_math_scatter_b_vs_las_sp_b_ct_p_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_scatter_b_vs_las_sp_b_ct_p_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_enr_4year_scatter_b_vs_las_sp_b_ct_p_`version'_nw.gph ///
    ,      title("VA Correlation in Base Specification with Peer Controls") ///
    note("Y-axis: base sample" ///
    "X-axis: fully restricted sample")

  graph export $figures_dir/share/va/`version'/va_combined_scatter_b_vs_las_sp_b_ct_p_`version'_nw.pdf, replace


  // scatter plots of different outcome VAs against each other

  //------------------------------------------------------------------------------
  // Figure 3: 2 year vs 4 year VA,
  // y axis: 2 year VA
  // x axis: 4 Year VA
  //------------------------------------------------------------------------------

  // Panel 1: base sample base control no peer
  corr va_enr_2year_b_sp_b_ct va_enr_4year_b_sp_b_ct
  local corr_enr_2year_4year_1: di %5.3f r(rho)

  reg va_enr_2year_b_sp_b_ct va_enr_4year_b_sp_b_ct
  local b_enr_2year_4year_1: di %5.3f _b[va_enr_4year_b_sp_b_ct]

  // weighted
  twoway (scatter va_enr_2year_b_sp_b_ct va_enr_4year_b_sp_b_ct [aw=n_g11_enr_2year_b_sp], msymbol(o) mcolor(%20)) ///
    (lfit va_enr_2year_b_sp_b_ct va_enr_4year_b_sp_b_ct) ///
    , ytitle("2-Year Enrollment", margin(medium) size(small)) ///
    xtitle("4-Year Enrollment", size(small)) ///
    title("Base Sample VA Correlation") ///
    legend(label(1 "VA") label(2 "Fitted line")) ///
    note("Controls: Base controls without peer controls" ///
    "Correlation Coefficient = `corr_enr_2year_4year_1'" ///
    "Fitted line slope = `corr_enr_2year_4year_1'")

  graph export $figures_dir/share/va/`version'/va_enr_2year_4year_scatter_b_sp_b_ct_`version'_wt.pdf, replace

  // unweighted
  twoway (scatter va_enr_2year_b_sp_b_ct va_enr_4year_b_sp_b_ct) ///
    (lfit va_enr_2year_b_sp_b_ct va_enr_4year_b_sp_b_ct) ///
    , ytitle("2-Year Enrollment", margin(medium) size(small)) ///
    xtitle("4-Year Enrollment", size(small)) ///
    title("Base Sample VA Correlation") ///
    legend(label(1 "VA") label(2 "Fitted line")) ///
    note("Controls: Base controls without peer controls" ///
    "Correlation Coefficient = `corr_enr_2year_4year_1'" ///
    "Fitted line slope = `corr_enr_2year_4year_1'")

  graph export $figures_dir/share/va/`version'/va_enr_2year_4year_scatter_b_sp_b_ct_`version'_nw.pdf, replace

  // redraw the graph with different titles to be used for combining into panels
  twoway (scatter va_enr_2year_b_sp_b_ct va_enr_4year_b_sp_b_ct ///
    ,  msize(small) ) ///
    (lfit va_enr_2year_b_sp_b_ct va_enr_4year_b_sp_b_ct) ///
    , title("Base Sample", size(small)) ///
    legend(off) ytitle("") xtitle("") ///
    note( "Controls: Base controls without peer controls" ///
     "Correlation Coefficient = `corr_enr_2year_4year_1'" ///
    "Fitted line slope = `corr_enr_2year_4year_1'", size(tiny)) ///
    saving($output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_4year_scatter_b_sp_b_ct_`version'_nw, replace)



  // panel 2: las sample, las controls with peer
  corr va_enr_2year_las_sp_las_ct_p va_enr_4year_las_sp_las_ct_p
  local corr_enr_2year_4year_2: di %5.3f r(rho)

  reg va_enr_2year_las_sp_las_ct_p va_enr_4year_las_sp_las_ct_p
  local b_enr_2year_4year_2: di %5.3f _b[va_enr_4year_las_sp_las_ct_p]

  // weighted
  twoway (scatter va_enr_2year_las_sp_las_ct_p va_enr_4year_las_sp_las_ct_p [aw=n_g11_enr_2year_las_sp], msymbol(o) mcolor(%20)) ///
    (lfit va_enr_2year_las_sp_las_ct_p va_enr_4year_las_sp_las_ct_p) ///
    , ytitle("2-Year Enrollment", margin(medium) size(small)) ///
    xtitle("4-Year Enrollment", size(small)) ///
    title("Fully Restricted Sample VA Correlation") ///
    legend(label(1 "VA") label(2 "Fitted line")) ///
    note("Controls: Full specification with peer controls" ///
    "Correlation Coefficient = `corr_enr_2year_4year_2'" ///
    "Fitted line slope = `b_enr_2year_4year_2'")

  graph export $figures_dir/share/va/`version'/va_enr_2year_4year_scatter_las_sp_las_ct_p_`version'_wt.pdf, replace

  // unweighted
  twoway (scatter va_enr_2year_las_sp_las_ct_p va_enr_4year_las_sp_las_ct_p) ///
    (lfit va_enr_2year_las_sp_las_ct_p va_enr_4year_las_sp_las_ct_p) ///
    , ytitle("2-Year Enrollment", margin(medium) size(small)) ///
    xtitle("4-Year Enrollment", size(small)) ///
    title("Fully Restricted Sample VA Correlation") ///
    legend(label(1 "VA") label(2 "Fitted line")) ///
    note("Controls: Full specification with peer controls" ///
    "Correlation Coefficient = `corr_enr_2year_4year_2'" ///
    "Fitted line slope = `b_enr_2year_4year_2'")

  graph export $figures_dir/share/va/`version'/va_enr_2year_4year_scatter_las_sp_las_ct_p_`version'_nw.pdf, replace

  // redraw the graph with different titles to be used for combining into panels
  twoway (scatter va_enr_2year_las_sp_las_ct_p va_enr_4year_las_sp_las_ct_p ///
    ,  msize(small) ) ///
    (lfit va_enr_2year_las_sp_las_ct_p va_enr_4year_las_sp_las_ct_p) ///
    , title("Fully Restricted Sample", size(small)) ///
    legend(off) ytitle("") xtitle("") ///
    note( "Controls: Full specification with peer controls" ///
    "Correlation Coefficient = `corr_enr_2year_4year_2'" ///
    "Fitted line slope = `b_enr_2year_4year_2'", size(tiny)) ///
    saving($output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_4year_scatter_las_sp_las_ct_p_`version'_nw, replace)


  // combining figure 3 panels
  graph combine ///
    $output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_4year_scatter_b_sp_b_ct_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_4year_scatter_las_sp_las_ct_p_`version'_nw.gph ///
    , title("2-Year vs. 4-Year Enrollment VA Correlation") ///
    note("Y-axis: 2-year enrollment" ///
    "X-axis: 4-year enrollment")

  graph export $figures_dir/share/va/`version'/va_enr_2year_4year_scatter_combined_`version'_nw.pdf, replace



  //------------------------------------------------------------------------------
  // Figure 3 alt: ELA vs Math VA,
  // y axis: ELA VA
  // x axis: Math VA
  //------------------------------------------------------------------------------

  // Panel 1: base sample base control no peer
  corr va_ela_b_sp_b_ct va_math_b_sp_b_ct
  local corr_ela_math_1: di %5.3f r(rho)

  reg va_ela_b_sp_b_ct va_math_b_sp_b_ct
  local b_ela_math_1: di %5.3f _b[va_math_b_sp_b_ct]

  // weighted
  twoway (scatter va_ela_b_sp_b_ct va_math_b_sp_b_ct [aw=n_g11_ela_b_sp], msymbol(o) mcolor(%20)) ///
    (lfit va_ela_b_sp_b_ct va_math_b_sp_b_ct) ///
    , xtitle("Math", margin(medium) size(small)) ///
    ytitle("ELA", size(small)) ///
    title("Base Sample VA Correlation") ///
    legend(label(1 "VA") label(2 "Fitted line")) ///
    note("Controls: Base controls without peer controls" ///
    "Correlation Coefficient = `corr_ela_math_1'" ///
    "Fitted line slope = `corr_ela_math_1'")

  graph export $figures_dir/share/va/`version'/va_ela_math_scatter_b_sp_b_ct_`version'_wt.pdf, replace

  // unweighted
  twoway (scatter va_ela_b_sp_b_ct va_math_b_sp_b_ct) ///
    (lfit va_ela_b_sp_b_ct va_math_b_sp_b_ct) ///
    , xtitle("Math", margin(medium) size(small)) ///
    ytitle("ELA", size(small)) ///
    title("Base Sample VA Correlation") ///
    legend(label(1 "VA") label(2 "Fitted line")) ///
    note("Controls: Base controls without peer controls" ///
    "Correlation Coefficient = `corr_ela_math_1'" ///
    "Fitted line slope = `corr_ela_math_1'")

  graph export $figures_dir/share/va/`version'/va_ela_math_scatter_b_sp_b_ct_`version'_nw.pdf, replace

  // redraw the graph with different titles to be used for combining into panels
  twoway (scatter va_ela_b_sp_b_ct va_math_b_sp_b_ct ///
    ,  msize(small) ) ///
    (lfit va_ela_b_sp_b_ct va_math_b_sp_b_ct) ///
    , title("Base Sample", size(small)) ///
    legend(off) ytitle("") xtitle("") ///
    note( "Controls: Base controls without peer controls" ///
     "Correlation Coefficient = `corr_ela_math_1'" ///
    "Fitted line slope = `corr_ela_math_1'", size(tiny)) ///
    saving($output_dir/gph_files/va_cfr_all_`version'/va_ela_math_scatter_b_sp_b_ct_`version'_nw, replace)



  // panel 2: las sample, las controls with peer
  corr va_ela_las_sp_las_ct_p va_math_las_sp_las_ct_p
  local corr_ela_math_2: di %5.3f r(rho)

  reg va_ela_las_sp_las_ct_p va_math_las_sp_las_ct_p
  local b_ela_math_2: di %5.3f _b[va_math_las_sp_las_ct_p]

  // weighted
  twoway (scatter va_ela_las_sp_las_ct_p va_math_las_sp_las_ct_p [aw=n_g11_ela_las_sp], msymbol(o) mcolor(%20)) ///
    (lfit va_ela_las_sp_las_ct_p va_math_las_sp_las_ct_p) ///
    , xtitle("Math", margin(medium) size(small)) ///
    ytitle("ELA", size(small)) ///
    title("Fully Restricted Sample VA Correlation") ///
    legend(label(1 "VA") label(2 "Fitted line")) ///
    note("Controls: Full specification with peer controls" ///
    "Correlation Coefficient = `corr_ela_math_2'" ///
    "Fitted line slope = `b_ela_math_2'")

  graph export $figures_dir/share/va/`version'/va_ela_math_scatter_las_sp_las_ct_p_`version'_wt.pdf, replace

  // unweighted
  twoway (scatter va_ela_las_sp_las_ct_p va_math_las_sp_las_ct_p) ///
    (lfit va_ela_las_sp_las_ct_p va_math_las_sp_las_ct_p) ///
    , xtitle("Math", margin(medium) size(small)) ///
    ytitle("ELA", size(small)) ///
    title("Fully Restricted Sample VA Correlation") ///
    legend(label(1 "VA") label(2 "Fitted line")) ///
    note("Controls: Full specification with peer controls" ///
    "Correlation Coefficient = `corr_ela_math_2'" ///
    "Fitted line slope = `b_ela_math_2'")

  graph export $figures_dir/share/va/`version'/va_ela_math_scatter_las_sp_las_ct_p_`version'_nw.pdf, replace

  // redraw the graph with different titles to be used for combining into panels
  twoway (scatter va_ela_las_sp_las_ct_p va_math_las_sp_las_ct_p ///
    ,  msize(small) ) ///
    (lfit va_ela_las_sp_las_ct_p va_math_las_sp_las_ct_p) ///
    , title("Fully Restricted Sample", size(small)) ///
    legend(off) ytitle("") xtitle("") ///
    note( "Controls: Full specification with peer controls" ///
    "Correlation Coefficient = `corr_ela_math_2'" ///
    "Fitted line slope = `b_ela_math_2'", size(tiny)) ///
    saving($output_dir/gph_files/va_cfr_all_`version'/va_ela_math_scatter_las_sp_las_ct_p_`version'_nw, replace)


  // combining figure 3 panels
  graph combine ///
    $output_dir/gph_files/va_cfr_all_`version'/va_ela_math_scatter_b_sp_b_ct_`version'_nw.gph ///
    $output_dir/gph_files/va_cfr_all_`version'/va_ela_math_scatter_las_sp_las_ct_p_`version'_nw.gph ///
    , title("ELA vs. Math VA Correlation") ///
    note("Y-axis: ELA" ///
    "X-axis: Math")

  graph export $figures_dir/share/va/`version'/va_ela_math_scatter_combined_`version'_nw.pdf, replace

















  //------------------------------------------------------------------------------
  // Figure 4a: 2 year and 4 year VA against ELA VA
  // Figure 4b: 2 year and 4 year VA against math VA
  // y axis: enrollment
  // x axis: ELA
  //------------------------------------------------------------------------------

  foreach outcome in enr_2year enr_4year {

    foreach subject in ela math {
      // base sample base controls no peer
      corr va_`outcome'_b_sp_b_ct va_`subject'_b_sp_b_ct
      local corr_`outcome'_`subject'_b_sp: di %5.3f r(rho)

      reg va_`outcome'_b_sp_b_ct va_`subject'_b_sp_b_ct
      local b_`outcome'_`subject'_b_sp: di %5.3f _b[va_`subject'_b_sp_b_ct]

      // weighted
      twoway (scatter va_`outcome'_b_sp_b_ct va_`subject'_b_sp_b_ct [aw=n_g11_`outcome'_b_sp], msymbol(o) mcolor(%20)) ///
        (lfit va_`outcome'_b_sp_b_ct va_`subject'_b_sp_b_ct) ///
        , title("``outcome'_str' vs. ``subject'_str' VA Correlation") ///
        ytitle("``outcome'_str'") ///
        xtitle("``subject'_str'") ///
        legend(label(1 "VA") label(2 "Fitted line")) ///
        note("Sample: Base Sample. Controls: Base Controls without Peer Controls" ///
        "Correlation Coefficient = `corr_`outcome'_`subject'_b_sp'" ///
        "Fitted line slope = `b_`outcome'_`subject'_b_sp'")

      graph export $figures_dir/share/va/`version'/va_`outcome'_`subject'_scatter_b_sp_b_ct_`version'_wt.pdf, replace

      // unweighted
      twoway (scatter va_`outcome'_b_sp_b_ct va_`subject'_b_sp_b_ct ) ///
        (lfit va_`outcome'_b_sp_b_ct va_`subject'_b_sp_b_ct) ///
        , title("``outcome'_str' vs. ``subject'_str' VA Correlation") ///
        ytitle("``outcome'_str'") ///
        xtitle("``subject'_str'") ///
        legend(label(1 "VA") label(2 "Fitted line")) ///
        note("Sample: Base Sample. Controls: Base Controls without Peer Controls" ///
        "Correlation Coefficient = `corr_`outcome'_`subject'_b_sp'" ///
        "Fitted line slope = `b_`outcome'_`subject'_b_sp'")

      graph export $figures_dir/share/va/`version'/va_`outcome'_`subject'_scatter_b_sp_b_ct_`version'_nw.pdf, replace

      // redraw the graph with different titles to be used for combining into panels
      twoway (scatter va_`outcome'_b_sp_b_ct va_`subject'_b_sp_b_ct ///
        , msize(small) ) ///
        (lfit va_`outcome'_b_sp_b_ct va_`subject'_b_sp_b_ct) ///
        , title("``outcome'_str'", size(small)) ///
        legend(off) ytitle("") xtitle("") ///
        note("Sample: Base Sample." ///
        "Controls: Base Controls without Peer Controls" ///
        "Correlation Coefficient = `corr_`outcome'_`subject'_b_sp'" ///
        "Fitted line slope = `b_`outcome'_`subject'_b_sp'", size(tiny)) ///
        saving($output_dir/gph_files/va_cfr_all_`version'/va_`outcome'_`subject'_scatter_b_sp_b_ct_`version'_nw, replace)




      // las sample las controls with peer
      corr va_`outcome'_las_sp_las_ct_p va_`subject'_las_sp_las_ct_p
      local corr_`outcome'_`subject'_las_sp: di %5.3f r(rho)

      reg va_`outcome'_las_sp_las_ct_p va_`subject'_las_sp_las_ct_p
      local b_`outcome'_`subject'_las_sp: di %5.3f _b[va_`subject'_las_sp_las_ct_p]

      // weighted
      twoway (scatter va_`outcome'_las_sp_las_ct_p va_`subject'_las_sp_las_ct_p [aw=n_g11_`outcome'_las_sp], msymbol(o) mcolor(%20)) ///
        (lfit va_`outcome'_las_sp_las_ct_p va_`subject'_las_sp_las_ct_p) ///
        , title("``outcome'_str' vs. ``subject'_str' VA Correlation") ///
        ytitle("``outcome'_str'") ///
        xtitle("``subject'_str'") ///
        legend(label(1 "VA") label(2 "Fitted line")) ///
        note("Sample: Full Restricted Sample." ///
        "Controls: Full Specification with Peer Controls" ///
        "Correlation Coefficient = `corr_`outcome'_`subject'_las_sp'" ///
        "Fitted line slope = `b_`outcome'_`subject'_las_sp'")

      graph export $figures_dir/share/va/`version'/va_`outcome'_`subject'_scatter_las_sp_las_ct_p_`version'_wt.pdf, replace

      // unweighted
      twoway (scatter va_`outcome'_las_sp_las_ct_p va_`subject'_las_sp_las_ct_p)  ///
        (lfit va_`outcome'_las_sp_las_ct_p va_`subject'_las_sp_las_ct_p) ///
        , title("``outcome'_str' vs. ``subject'_str' VA Correlation") ///
        ytitle("``outcome'_str'") ///
        xtitle("``subject'_str'") ///
        legend(label(1 "VA") label(2 "Fitted line")) ///
        note("Sample: Full Restricted Sample." ///
        "Controls: Full Specification with Peer Controls" ///
        "Correlation Coefficient = `corr_`outcome'_`subject'_las_sp'" ///
        "Fitted line slope = `b_`outcome'_`subject'_las_sp'")

      graph export $figures_dir/share/va/`version'/va_`outcome'_`subject'_scatter_las_sp_las_ct_p_`version'_nw.pdf, replace

      // redraw the graph with different titles to be used for combining into panels
      twoway (scatter va_`outcome'_las_sp_las_ct_p va_`subject'_las_sp_las_ct_p ///
      , msize(small)) ///
        (lfit va_`outcome'_las_sp_las_ct_p va_`subject'_las_sp_las_ct_p) ///
        , title("``outcome'_str'", size(small)) ///
        legend(off) ytitle("") xtitle("") ///
        note("Sample: Full Restricted Sample." ///
        "Controls: Full Specification with Peer Controls" ///
        "Correlation Coefficient = `corr_`outcome'_`subject'_las_sp'" ///
        "Fitted line slope = `b_`outcome'_`subject'_las_sp'", size(tiny)) ///
        saving($output_dir/gph_files/va_cfr_all_`version'/va_`outcome'_`subject'_scatter_las_sp_las_ct_p_`version'_nw, replace)


    }

  }

  // combine figure 4a and 4b panels
  foreach subject in ela math {

      graph combine ///
        $output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_`subject'_scatter_b_sp_b_ct_`version'_nw.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/va_enr_2year_`subject'_scatter_las_sp_las_ct_p_`version'_nw.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/va_enr_4year_`subject'_scatter_b_sp_b_ct_`version'_nw.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/va_enr_4year_`subject'_scatter_las_sp_las_ct_p_`version'_nw.gph ///
        ,          title("Enrollment vs. ``subject'_str' VA Correlation")

      graph export $figures_dir/share/va/`version'/va_enr_2year_4year_`subject'_scatter_combined_`version'_nw.pdf, replace
  }


  //------------------------------------------------------------------------------
  // Figure 5a: 2 year and 4 year enrollmenet on ELA VA, heterogeneity by prior ELA
  // Figure 5b: 2 year and 4 year enrollmenet on math VA, heterogeneity by prior math
  // y axis: enrollment
  // x axis: ELA
  //------------------------------------------------------------------------------
  foreach subject in ela math {
    // without distance controls
      // export individual figures
      graph use $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.gph
      graph export $figures_dir/share/va/`version'/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.pdf, replace

      graph use $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.gph
      graph export $figures_dir/share/va/`version'/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.pdf, replace

      graph use $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.gph
      graph export $figures_dir/share/va/`version'/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.pdf, replace

      graph use $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.gph
      graph export $figures_dir/share/va/`version'/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.pdf, replace

      // combine figures into one panel
      graph combine ///
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_b_ct_m.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_las_ct_p_m.gph ///
        , xcommon ycommon 
        /* title("Enrollment on ``subject'_str' VA interacted with w/ prior ``subject'_str' score decile", size(small)) */

      graph export $figures_dir/share/va/`version'/het_reg_va_`subject'_x_prior_`subject'_combined_`version'.pdf, replace





      // with distance controls

      graph use $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.gph
      graph export $figures_dir/share/va/`version'/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.pdf, replace

      graph use $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.gph
      graph export $figures_dir/share/va/`version'/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.pdf, replace

      graph use $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.gph
      graph export $figures_dir/share/va/`version'/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.pdf, replace

      graph use $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.gph
      graph export $figures_dir/share/va/`version'/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.pdf, replace

      // combine figures into one panel
      graph combine ///
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_b_sp_bd_ct_m.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_2year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.gph ///
        $output_dir/gph_files/va_cfr_all_`version'/het_reg_prior_score/het_reg_enr_4year_va_`subject'_x_prior_`subject'_las_sp_lasd_ct_p_m.gph ///
        , xcommon ycommon 
        /* title("Enrollment on ``subject'_str' VA interacted with w/ prior ``subject'_str' score decile", size(small)) */


      graph export $figures_dir/share/va/`version'/het_reg_distance_va_`subject'_x_prior_`subject'_combined_`version'.pdf, replace


  }

}




set trace off



local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

log close
translate $logdir/va_scatter.smcl $logdir/va_scatter.log, replace
