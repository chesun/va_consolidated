/*------------------------------------------------------------------------------
do/share/va_spec_fb_tab_all.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    VA specification + forecast-bias test summary table (all-outcomes combined).  Paper producer (figures + tables) for the VA paper.

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
    $tables_dir/share/va/check/va_`va_outcome'_`version'.tex  (LEGACY)
    $tables_dir/share/va/check/va_out_`version'.tex  (LEGACY)
    $tables_dir/share/va/check/va_score_`version'.tex  (LEGACY)
    $tables_dir/share/va/pub/va_out_`version'.tex  (LEGACY)
    $tables_dir/share/va/pub/va_score_`version'.tex  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/fb_test/fb_`va_outcome'_all.dta  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/spec_test/spec_`va_outcome'_all.dta  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/va_spec_fb_tab_all.smcl (via log using)
    $logdir/share/va_spec_fb_tab_all.smcl + $logdir/share/va_spec_fb_tab_all.log (translate)
    $tables_dir/share/va/check/va_`va_outcome'_`version'.tex
    $tables_dir/share/va/check/va_out_`version'.tex
    $tables_dir/share/va/check/va_score_`version'.tex
    $tables_dir/share/va/pub/va_out_`version'.tex
    $tables_dir/share/va/pub/va_score_`version'.tex

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/va_spec_fb_tab_all.do
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
    Sister files (this batch): base_sum_stats_tab.do, kdensity.do, reg_out_va_tab.do, sample_counts_tab.do, svyindex_tab.do, va_scatter.do, va_var_explain.do, va_var_explain_tab.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* VA tables: including standard deviation of VA, forecast bias, specification tests;
one for each outcome:
1. ELA
2. Math
3. 2 year enrollment
4. 4 year enrollment
 (should we stack scores together and outcomes together?)

 Sample-control combinations:
 1. Base sample base control, no peer
 2. LAS sample base control, no peer
 3. LAS sample base control with peer
 4. LAS sample base+acs control with peer
 5. LAS sample base+LAS control with peer
 */
********************************************************************************

*****************************************************
* First created by Christina Sun March 1, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/va_spec_fb_tab_all.do
 */

/* CHANGE LOG:

 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
cap log close va_spec_fb_tab_all

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

log using "$logdir/share/va_spec_fb_tab_all.smcl", replace text name(va_spec_fb_tab_all)

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984

// program to replace row text
cap program drop _all
program drop _all
program define rplc
	replace row="`1'" if row=="`2'"
end


local date1 = c(current_date)
local time1 = c(current_time)


include $consolidated_dir/do/va/helpers/macros_va.doh
include $consolidated_dir/do/va/helpers/drift_limit.doh

foreach version in v1 v2 {
  //------------------------------------------------------------------------------
  // Making VA table
  //------------------------------------------------------------------------------

  foreach va_outcome in ela math enr_2year enr_4year {

    //---------------------------------------------------------------
    // first set up forecast bias test results
    //---------------------------------------------------------------
    use $estimates_dir/va_cfr_all_`version'/fb_test/fb_`va_outcome'_all.dta, clear

		gen column=1 if va_sample=="b" & va_control=="b" & peer_controls==0
    replace column=2 if va_sample=="las" & va_control=="b" & peer_controls==0
    replace column=3 if va_sample=="las" & va_control=="b" & peer_controls==1
    replace column=4 if va_sample=="las" & va_control=="a" & peer_controls==1
		replace column=5 if va_sample=="las" & va_control=="las" & peer_controls==1
		replace column=6 if va_sample=="las" & va_control=="lasd" & peer_controls==1


    tab column
    keep if column!=.

    gen keeper=1 if va_control=="b" & inlist(fb_var, "l", "a", "s", "d")
    replace keeper=1 if va_control=="a" & inlist(fb_var, "l", "s", "d")
		replace keeper=1 if va_control=="las" & inlist(fb_var, "d")

    keep if keeper==1

    keep column fb_var f_stat_lovar coef stderr pval

    foreach var of varlist coef stderr {
      tostring `var', force format(%10.3f) replace
    }
    tostring f_stat_lovar, force format(%10.1f) replace
    replace stderr="("+ stderr+ ")"
    replace coef=coef+"*" if pval<.05
    replace coef=coef+"*" if pval<.01
    replace coef=coef+"*" if pval<.001
    replace f_stat_lovar="{"+f_stat_lovar+"}"

    foreach var of varlist f_stat_lovar coef stderr {
      rename `var' entry`var'
    }

    reshape long entry, i(column fb_var) j(row) string
    drop pval
    reshape wide entry, i(fb_var row) j(column)

  	gen rowgroup=1*(fb_var=="l")+2*(fb_var=="s")+3*(fb_var=="a")+4*(fb_var=="d")
    gen rowgroup2=1*(row=="coef")+2*(row=="stderr")+3*(row=="f_stat_lovar")

    sort rowgroup rowgroup2

    drop row
    rename fb_var row
    keep row entry1-entry5

    gen obs=_n
    sort row obs
    by row: replace row="" if _n>1
    sort obs
    drop obs

    tempfile fb_`va_outcome'_`version'
  	save `fb_`va_outcome'_`version''

    //---------------------------------------------------------------
    // then set up specification test results
    //---------------------------------------------------------------

    use $estimates_dir/va_cfr_all_`version'/spec_test/spec_`va_outcome'_all.dta, clear

    gen column=1 if va_sample=="b" & va_control=="b" & peer_controls==0
    replace column=2 if va_sample=="las" & va_control=="b" & peer_controls==0
    replace column=3 if va_sample=="las" & va_control=="b" & peer_controls==1
    replace column=4 if va_sample=="las" & va_control=="a" & peer_controls==1
    replace column=5 if va_sample=="las" & va_control=="las" & peer_controls==1
		replace column=6 if va_sample=="las" & va_control=="lasd" & peer_controls==1

    keep if column!=.
    foreach var of varlist coef sd_va stderr {
  		tostring `var', force format(%10.3f) replace
  	}
  	replace stderr="("+ stderr+ ")"
    replace coef=coef+"*" if pval<.05
    replace coef=coef+"*" if pval<.01
    replace coef=coef+"*" if pval<.001
  	tostring peer_controls, force replace

    replace va_sample="Base" if va_sample=="b"
    replace va_sample="Restricted" if va_sample=="las"
    replace va_control="Base" if va_control=="b"
    replace va_control="Base + ACS" if va_control=="a"
    replace va_control="Base + LO score + sib + ACS" if va_control=="las"
		replace va_control="Base + LO score + sib + ACS + Distance" if va_control=="lasd"

    replace peer_controls="Yes" if peer_controls=="1"
    replace peer_controls="No" if peer_controls=="0"

    rename sd_va entrysd_va
  	rename coef entryspec_coef
  	rename stderr entryspec_stderr
  	rename peer_controls entrypeer_controls
  	rename va_sample entryva_sample
  	rename va_control entryva_control

    reshape long entry, i(column) j(row) string
    keep entry row column
    reshape wide entry, i(row) j(column)

    gen roworder = 1*(row=="va_sample")+2*(row=="va_control")+3*(row=="peer_controls") ///
      + 4*(row=="sd_va") + 5*(row=="spec_coef") + 6*(row=="spec_stderr")

    sort roworder
    drop roworder

    tempfile spec_`va_outcome'_`version'
    save `spec_`va_outcome'_`version''

    //append fb test results
    append using `fb_`va_outcome'_`version''

    rplc "Sample" "va_sample"
    rplc "Controls" "va_control"
    rplc "Peer Controls" "peer_controls"
    rplc "SD of VA" "sd_va"
    rplc "Spec Test" "spec_coef"
  	rplc "" "spec_stderr"
  	rplc "FB: LO Score" "l"
  	rplc "FB: Sibling" "s"
  	rplc "FB: ACS" "a"
		rplc "FB: Distance" "d"

    tempfile va_table_`va_outcome'_`version'
    save `va_table_`va_outcome'_`version''

    local texsave_options_single autonumber nonames replace size(footnotesize) hlines(3) ///
      title("``va_outcome'_str' Value Added") ///
      footnote("Standard errors in paranthesis. * \(p<0.05)\) ** \(p<0.01\) *** \(p<0.001\)")
    // a folder for checking the tables
    texsave using "$tables_dir/share/va/check/va_`va_outcome'_`version'.tex", `texsave_options_single'
		// publication ready tables
		texsave using "$tables_dir/share/va/check/va_`va_outcome'_`version'.tex", frag `texsave_options_single'

  }

  //------------------------------------------------------------------------------
  // stack the test score VA and the enrollment VA
  //------------------------------------------------------------------------------


  use `va_table_ela_`version'', clear
  insobs 1, before(1)
  replace row="Panel A: ELA" if _n==1

  append using `va_table_math_`version''
  insobs 1, after(19)
  replace row="Panel B: Math" if _n==20

  local texsave_options_combined autonumber nonames replace size(footnotesize) ///
		hlines(1 4 19 19 20 23) ///
    title("Test Score Value Added") ///
    footnote("Standard errors in paranthesis. * \(p<0.05)\) ** \(p<0.01\) *** \(p<0.001\)")

  // a folder for checking the tables
  texsave using "$tables_dir/share/va/check/va_score_`version'.tex", `texsave_options_combined'
  // publication ready tables
  texsave using "$tables_dir/share/va/pub/va_score_`version'.tex", frag `texsave_options_combined'


  use `va_table_enr_2year_`version'', clear
  insobs 1, before(1)
  replace row="Panel A: 2 Year Enrollment" if _n==1

  append using `va_table_enr_4year_`version''
  insobs 1, after(19)
  replace row="Panel B: 4 Year Enrollment" if _n==20

  local texsave_options_combined autonumber nonames replace size(footnotesize) ///
  hlines(1 4 19 19 20 23)
    /* title("College Enrollment Value Added") ///
    footnote("Standard errors in paranthesis. * \(p<0.05)\) ** \(p<0.01\) *** \(p<0.001\)") */

  // a folder for checking the tables
  texsave using "$tables_dir/share/va/check/va_out_`version'.tex", `texsave_options_combined'
  // publication ready tales
  texsave using "$tables_dir/share/va/pub/va_out_`version'.tex", frag `texsave_options_combined'





}

















local date2 = c(current_date)
local time2 = c(current_time)

di "Start date time: `date1' `time1'"
di "End date time: `date2' `time2'"

cap log close va_spec_fb_tab_all
translate $logdir/share/va_spec_fb_tab_all.smcl $logdir/share/va_spec_fb_tab_all.log, replace
