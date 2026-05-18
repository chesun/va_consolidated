/*------------------------------------------------------------------------------
do/share/va_var_explain_tab.do — Phase 1a §3.3 step 10 batch 10a relocation
================================================================================

PURPOSE
    variance-explained table from var-explain regression results.  Paper producer (figures + tables) for the VA paper.

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
    $tables_dir/share/va/check/va_var_explain_`version'.tex  (LEGACY)
    $tables_dir/share/va/pub/va_var_explain_`version'.tex  (LEGACY)
    $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/va_var_explain_tab.smcl (via log using)
    $logdir/share/va_var_explain_tab.smcl + $logdir/share/va_var_explain_tab.log (translate)
    $tables_dir/share/va/check/va_var_explain_`version'.tex
    $tables_dir/share/va/pub/va_var_explain_`version'.tex

RELOCATION (per plan v3 §3.3 step 10 batch 10a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/share/va_var_explain_tab.do
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
    Sister files (this batch): base_sum_stats_tab.do, kdensity.do, reg_out_va_tab.do, sample_counts_tab.do, svyindex_tab.do, va_scatter.do, va_spec_fb_tab_all.do, va_var_explain.do, corr_dk_score_va.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* create a table of the total college VA "explained" by test score VA by
comparing DK VA and college VA variance */
********************************************************************************

*****************************************************
* First created by Christina Sun May 18, 2023
*****************************************************

/* To run this do file, type:
do $vaprojdir/do_files/share/va_var_explain_tab.do
*/

/* CHANGE LOG:
 */

set tracedepth 1
set trace on

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).

 cap log close _all

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
cap mkdir "$tables_dir"
cap mkdir "$tables_dir/share"
cap mkdir "$tables_dir/share/va"
cap mkdir "$tables_dir/share/va/check"
cap mkdir "$tables_dir/share/va/pub"
cap mkdir "$estimates_dir"

 log using "$logdir/share/va_var_explain_tab.smcl", replace text

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

 foreach version in v1 v2 {
   foreach outcome in enr_2year enr_4year {
     use $estimates_dir/va_cfr_all_`version'/reg_out_va/reg_va_`outcome'_va_both_all.dta, clear
     // keep only one copy of observation per sample control peer combo
     bysort va_sample va_control peer_controls: keep if _n==1
     keep va_sample va_control peer_controls var_va var_va_dk dk_total_ratio unexplained outcome

     gen column=.
     replace column=1 if va_sample=="b" & va_control=="b" & peer_controls==0
     replace column=2 if va_sample=="las" & va_control=="b" & peer_controls==0
     replace column=3 if va_sample=="las" & va_control=="b" & peer_controls==1
     replace column=4 if va_sample=="las" & va_control=="a" & peer_controls==1
     replace column=5 if va_sample=="las" & va_control=="las" & peer_controls==1

     keep if column!=.
     foreach var of varlist var_va var_va_dk dk_total_ratio unexplained {
       tostring `var', force format(%10.4f) replace
     }
     tostring peer_controls, force replace

     replace va_sample="Base" if va_sample=="b"
     replace va_sample="Restricted" if va_sample=="las"
     replace va_control="Base" if va_control=="b"
     replace va_control="Base + ACS" if va_control=="a"
     replace va_control="Base + LO score + sib + ACS" if va_control=="las"
     replace peer_controls="Yes" if peer_controls=="1"
     replace peer_controls="No" if peer_controls=="0"

     foreach v of varlist va_sample va_control peer_controls var_va var_va_dk dk_total_ratio unexplained {
       rename `v' entry`v'
     }

     reshape long entry, i(column) j(row) string
     keep entry row column
     reshape wide entry, i(row) j(column)

     gen roworder=.

     replace roworder=1 if row=="var_va"
     replace roworder=2 if row=="var_va_dk"
     replace roworder=3 if row=="dk_total_ratio"
     replace roworder=4 if row=="unexplained"
     replace roworder=5 if row=="va_sample"
     replace roworder=6 if row=="va_control"
     replace roworder=7 if row=="peer_controls"

     sort roworder
     drop roworder

     replace row="Sample" if row=="va_sample"
     replace row="Controls" if row=="va_control"
     replace row="Peer Controls" if row=="peer_controls"
     replace row="Total Var" if row=="var_va"
     replace row="Var Net of Test Score VA" if row=="var_va_dk"
     replace row="Net Var/Total Var" if row=="dk_total_ratio"
     replace row="1 - $ R^2 $" if row=="unexplained"


     tempfile `outcome'_`version'
     save ``outcome'_`version''
   }

   use `enr_2year_`version'', clear
   insobs 1, before(1)
   replace row="Panel A: 2 Year Enrollment" if _n==1
   drop if row=="Sample" | row=="Controls" | row=="Peer Controls"

   append using `enr_4year_`version''
   insobs 1, after(5)
   replace row="Panel B: 4 Year Enrollment" if _n==6

   local texsave_options_combined autonumber nonames replace nofix ///
    hlines(1 4 5 5 6 9 10 10)

   // a folder for checking the tables
   texsave using "$tables_dir/share/va/check/va_var_explain_`version'.tex", `texsave_options_combined'
   // publication ready tales
   texsave using "$tables_dir/share/va/pub/va_var_explain_`version'.tex", frag `texsave_options_combined'


 }





set trace off







 local date2 = c(current_date)
 local time2 = c(current_time)

 di "Start date time: `date1' `time1'"
 di "End date time: `date2' `time2'"

 log close
 translate $logdir/share/va_var_explain_tab.smcl $logdir/share/va_var_explain_tab.log, replace
