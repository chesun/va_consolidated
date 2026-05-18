/*------------------------------------------------------------------------------
do/share/reg_out_va_tab.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    outcome-on-VA regression coefficient table.  Paper producer (figures + tables) for the VA paper.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Reads CHAIN VA outputs from $estimates_dir/va_cfr_all_<version>/<x>
    (Step 3 batches 3a-3d) + sample data from LEGACY $vaprojdir/data/
    va_samples_v1/<x> (sample data not yet relocated; out of Step 10 scope).
    Writes paper-shipping outputs to $tables_dir/share/<x> + $figures_dir/share/<x>
    (CANONICAL).

INPUTS (verified via grep on file body)
    $consolidated_dir/do/va/helpers/drift_limit.doh  (helper include)
    $consolidated_dir/do/va/helpers/macros_va.doh  (helper include)
    $tables_dir/share/va/check/persistence_both_subject.tex  (LEGACY)
    $tables_dir/share/va/check/persistence_single_subject.tex  (LEGACY)
    $tables_dir/share/va/pub/persistence_both_subject.tex  (LEGACY)
    $tables_dir/share/va/pub/persistence_single_subject.tex  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_out_`subject'_m.dta  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_out_both_m.dta  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/reg_out_va_tab.smcl (via log using)
    $logdir/share/reg_out_va_tab.smcl + $logdir/share/reg_out_va_tab.log (translate)
    $tables_dir/share/va/check/persistence_both_subject.tex
    $tables_dir/share/va/check/persistence_single_subject.tex
    $tables_dir/share/va/pub/persistence_both_subject.tex
    $tables_dir/share/va/pub/persistence_single_subject.tex
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_out_`subject'_m.dta
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_out_both_m.dta

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/reg_out_va_tab.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                      -> removed (absolute paths)
      log_files/share/<x>.smcl (rel + abs forms)         -> $logdir/<x>.smcl  (CANONICAL)
      include $vaprojdir/do_files/sbac/<x>.doh           -> include $consolidated_dir/do/{va/helpers,samples}/<x>.doh
        (per Step 1/2 helper relocation; covers macros_va, drift_limit, create_diff_school_prop, create_prior_scores_v1/v2, merge_loscore, merge_sib, merge_lag2_ela, merge_va_smp_acs, create_va_g11_sample_v1/v2, create_va_g11_out_sample_v1/v2)
      $estimates_dir/va_cfr_all_<v>/<x> -> $estimates_dir/va_cfr_all_<v>/<x> (CHAIN read from Step 3)
      $estimates_dir/va_cfr_all_<v>/<x> -> $estimates_dir/va_cfr_all_<v>/<x> (CHAIN read; predecessor stored intermediate regsave dtas under tables/, consolidated relocates under $estimates_dir/)
      $vaprojdir/figures/share/<x> -> $figures_dir/share/<x> (CANONICAL paper-shipping)
      $vaprojdir/tables/share/<x> -> $tables_dir/share/<x> (CANONICAL paper-shipping)
      $vaprojdir/data/va_samples_v1/<x> -> kept LEGACY (sample data; out of Step 10 scope)
      translate (multi-line ABS form) -> $logdir/<x> (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10a
    Sister files (this batch): base_sum_stats_tab.do, kdensity.do, sample_counts_tab.do, svyindex_tab.do, va_scatter.do, va_spec_fb_tab_all.do, va_var_explain.do, va_var_explain_tab.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* create persistence tables for publication: regressing enrollment outcomes
on value added. 2 year and 4 year enrollment
Sample/control combos:
1. base sample base controls, no peer
2. kitchen sink sample base controls, no peer
3. kitchen sink sample base controls, peer
4. kitchen sink sample kitchen sink controls, peer

all with matching controls between va and persistence reg */
********************************************************************************

*****************************************************
* First created by Christina Sun February 7, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/reg_out_va_tab.do
 */

/* CHANGE LOG:
03/01/2023: added "frag" option to publication ready tables for use with \input command
removed stars from standard errors, added *** for coefficient <0.001
 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
cap log close reg_out_va_tab

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
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

log using "$logdir/share/reg_out_va_tab.smcl", replace text name(reg_out_va_tab)

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

local sp_ct_p_combos b_sp_b_ct las_sp_b_ct las_sp_b_ct_p las_sp_las_ct_p las_sp_lasd_ct_p




foreach version in v1 v2 {
  //----------------------------------------------------------------------------
  //  regressions on only 1 subject VA estimate
  //----------------------------------------------------------------------------

  // merge the regsave datasets for each subject


  foreach subject in ela math {
    local append_command use
    local append_option ", clear"

    foreach outcome in enr_2year enr_4year {
      foreach sample_control_peer of local sp_ct_p_combos {
        `append_command' "$estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_`subject'_`sample_control_peer'_m.dta" `append_option'

        keep if strpos(var, "va_`subject'")~=0

        local append_command "append using"
        local append_option
      }
    }

    save "$estimates_dir/va_cfr_all_`version'/reg_out_va/reg_out_`subject'_m.dta", replace



  }


  //----------------------------------------------------------------------------
  //  regressions on both subjects VA estimate
  //----------------------------------------------------------------------------
  local append_command use
  local append_option ", clear"

  foreach outcome in enr_2year enr_4year {
    foreach sample_control_peer of local sp_ct_p_combos {
      `append_command' "$estimates_dir/va_cfr_all_`version'/reg_out_va/reg_`outcome'_va_ela_math_`sample_control_peer'_m.dta" `append_option'

      local append_command "append using"
      local append_option
    }
  }
    keep if strpos(var, "va_ela")!=0 | strpos(var, "va_math")!=0
    save "$estimates_dir/va_cfr_all_`version'/reg_out_va/reg_out_both_m.dta", replace





**********************************************************************************



  //------------------------------------------------------------------
  //  rearrange the dataset into table format: single subject regs
  //------------------------------------------------------------------
  foreach subject in math ela {
    use "$estimates_dir/va_cfr_all_`version'/reg_out_va/reg_out_`subject'_m.dta", clear
    // column groups
    gen colgroup=1 if outcome=="enr_2year"
    replace colgroup=2 if outcome=="enr_4year"

    // column numbers in each column group
    gen column = (colgroup-1)*4 + 1 if sample=="b"
    replace column = (colgroup-1)*4 + 2 if sample=="las" & control=="b" & peer=="N"
    replace column = (colgroup-1)*4 + 3 if sample=="las" & control=="b" & peer=="Y"
    replace column = (colgroup-1)*4 + 4 if sample=="las" & control=="las"
    drop if column==.

    drop r2
    foreach var of varlist coef  stderr {
      tostring `var', force format(%10.3f) replace
    }
    replace stderr="("+ stderr+ ")"
    replace coef=coef+"*" if pval<.05
    replace coef=coef+"*" if pval<.01
    replace coef=coef+"*" if pval<.001

    tostring N, force replace format("%9.0fc")

    drop pval subject

    replace outcome="2-Year Enrollment" if outcome=="enr_2year"
    replace outcome="4-Year Enrollment" if outcome=="enr_4year"

    replace sample="Base" if sample=="b"
    replace sample="Restricted" if sample=="las"

    replace control="Base" if control=="b"
    replace control="Leave Out Score + ACS + Sibling" if control=="las"

    foreach var of varlist coef stderr N outcome sample control reg_control peer {
      rename `var' entry`var'
    }


    reshape long entry, i(column var) j(row) string



    gen rownumber=1 if row=="coef"
    replace rownumber=2 if row=="stderr"
    replace rownumber=3 if row=="N"
    replace rownumber=4 if row=="peer"
    replace rownumber=5 if row=="reg_control"
    replace rownumber=6 if row=="sample"
    replace rownumber=7 if row=="control"

    drop if rownumber==.
    drop var colgroup

    reshape wide entry, i(rownumber) j(column)

    gen subject="`subject'"

    replace row="``subject'_str' VA" if row=="coef"
    replace row="" if row=="stderr"
    replace row="Peer" if row=="peer"
    replace row="Regression Controls" if row=="reg_control"
    replace row="VA Sample" if row=="sample"
    replace row="VA Controls" if row=="control"


    sort rownumber
    order row entry*

    tempfile `subject'
    save ``subject''




  }

  append using `math'

  drop if rownumber>=4 & rownumber<=7 & subject=="ela"
  drop subject rownumber


  local single_texsave_options autonumber nonames replace size(footnotesize) hlines(3 -4) ///
    /* title("Regressing College Enrollment on Single Subject Test Score VA")  */ ///
    headerlines("& \multicolumn{4}{c}{2-Year Enrollment} & \multicolumn{4}{c}{4-Year Enrollment} " "\cmidrule(lr){2-5} \cmidrule(lr){6-9}")
    /* footnote("Standard errors in paranthesis. * \(p<0.05)\) ** \(p<0.01\) *** \(p<0.001\)") */

  // a folder for checking the tables
  texsave using "$tables_dir/share/va/check/persistence_single_subject.tex", `single_texsave_options'

  // folder for publication ready tables using the frag option for texsave
  texsave using "$tables_dir/share/va/pub/persistence_single_subject.tex", `single_texsave_options' frag





  //------------------------------------------------------------------
  //  rearrange the dataset into table format: both subjects regs
  //------------------------------------------------------------------

  use "$estimates_dir/va_cfr_all_`version'/reg_out_va/reg_out_both_m.dta", clear
  // column groups
  gen colgroup=1 if outcome=="enr_2year"
  replace colgroup=2 if outcome=="enr_4year"

  // column numbers in each column group
  gen column = (colgroup-1)*4 + 1 if sample=="b"
  replace column = (colgroup-1)*4 + 2 if sample=="las" & control=="b" & peer=="N"
  replace column = (colgroup-1)*4 + 3 if sample=="las" & control=="b" & peer=="Y"
  replace column = (colgroup-1)*4 + 4 if sample=="las" & control=="las"
  drop if column==.

  drop r2
  foreach var of varlist coef  stderr {
    tostring `var', force format(%10.3f) replace
  }
  replace stderr="("+ stderr+ ")"
  replace coef=coef+"*" if pval<.05
  replace coef=coef+"*" if pval<.01
  replace coef=coef+"*" if pval<.001



  tostring N, force replace format("%9.0fc")

  drop pval subject

  gen va_ela=1 if strpos(var, "va_ela")==1
  replace va_ela=0 if strpos(var, "va_math")==1


  replace outcome="2-Year Enrollment" if outcome=="enr_2year"
  replace outcome="4-Year Enrollment" if outcome=="enr_4year"

  replace sample="Base" if sample=="b"
  replace sample="Restricted" if sample=="las"

  replace control="Base" if control=="b"
  replace control="Leave Out Score + ACS + Sibling" if control=="las"

  foreach var of varlist coef stderr N outcome sample control reg_control peer {
    rename `var' entry`var'
  }



  reshape long entry, i(column var) j(row) string



  gen rowgroup=1 if va_ela==1
  replace rowgroup=2 if va_ela==0
  replace rowgroup=3 if row=="peer" | row=="reg_control" | row=="sample" | row=="control"

  gen rownumber=(rowgroup-1)*2 + 1 if row=="coef"
  replace rownumber=(rowgroup-1)*2 + 2 if row=="stderr"

  drop if va_ela==1 & (row=="peer" | row=="reg_control" | row=="sample" | row=="control" | row=="N")

  replace rownumber=5 if row=="N"
  replace rownumber=6 if rowgroup==3 & row=="peer"
  replace rownumber=7 if rowgroup==3 & row=="reg_control"
  replace rownumber=8 if rowgroup==3 & row=="sample"
  replace rownumber=9 if rowgroup==3 & row=="control"

  drop if rownumber==.
  drop var va_ela colgroup rowgroup

  reshape wide entry, i(rownumber) j(column)

  replace row="ELA VA" if rownumber==1
  replace row="Math VA" if rownumber==3
  replace row="" if row=="stderr"
  replace row="Peer" if row=="peer"
  replace row="Regression Controls" if row=="reg_control"
  replace row="VA Sample" if row=="sample"
  replace row="VA Controls" if row=="control"

  sort rownumber
  order row entry*
  drop rownumber



  local single_texsave_options autonumber nonames replace size(footnotesize) hlines(-4) ///
    title("Regressing College Enrollment on Both ELA and Math Test Score VA simultaneously") ///
    headerlines("& \multicolumn{4}{c}{2-Year Enrollment} & \multicolumn{4}{c}{4-Year Enrollment} " "\cmidrule(lr){2-5} \cmidrule(lr){6-9}") ///
    footnote("Standard errors in paranthesis. * \(p<0.05)\) ** \(p<0.01\) *** \(p<0.001\)")

  // a folder for checking the tables
  texsave using "$tables_dir/share/va/check/persistence_both_subject.tex", `single_texsave_options'

  // folder for publication ready tables using the frag option for texsave
  texsave using "$tables_dir/share/va/pub/persistence_both_subject.tex", `single_texsave_options' frag






}









local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close reg_out_va_tab
translate $logdir/share/reg_out_va_tab.smcl $logdir/share/reg_out_va_tab.log, replace
