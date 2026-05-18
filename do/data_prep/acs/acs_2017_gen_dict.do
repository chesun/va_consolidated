/*------------------------------------------------------------------------------
do/data_prep/acs/acs_2017_gen_dict.do — Phase 1a §3.3 step 9 batch 9a relocation
================================================================================

PURPOSE
    Build data dictionaries (.dta + .csv) for the 2017 ACS subject tables
    (S0601, S1501, S1702, S1901) using `descsave'.  These dictionaries map
    obscure "hc*"-style variable names to their human-readable labels so
    subsequent ACS cleaning can reference labels instead of codes.

    Diagnostic / lookup output — not paper-shipping; not consumed by any
    consolidated downstream as a runtime input.  Companion to
    `clean_acs_census_tract.do' (this batch) which cleans 2010-2013 ACS
    under the new naming convention.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Standalone
    executable; no upstream dependencies inside the consolidated pipeline.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/acs/subject_tables/2017/ACS_17_5YR_<S>_with_ann.csv
        — LEGACY raw public ACS data (4 subject tables: S0601, S1501,
          S1702, S1901)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $output_dir/csv/acs/2017/acs_2017_<S>_dict.dta  (4 dictionary dta files)
    $output_dir/csv/acs/2017/acs_2017_<S>_dict.csv  (4 dictionary csv files)
        — Diagnostic / lookup; not paper-shipping; per `gph_files'-routing
          convention generalized to intermediate output ([LEARN:workflow]).
    $logdir/data_prep/acs/acs_2017_gen_dict.smcl + .log

RELOCATION (per plan v3 §3.3 step 9 batch 9a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/acs/acs_2017_gen_dict.do
    Path repointing applied:
      $projdir/out/csv/acs/2017/<x> -> $output_dir/csv/acs/2017/<x>  (intermediate diagnostic)
      $vaprojdir/data/public_access/raw/acs/<x> -> kept LEGACY (raw inputs)
    Predecessor had no `log using' / `translate'; consolidated convention
    adds them per ADR-0021 description-convention precedent (Step 7 batch).

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9a
    Sister: clean_acs_census_tract.do (this batch)

DEPENDENCIES (Stata packages)
    descsave (ssc; install via `ssc install descsave, replace' if absent)

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* do file to create data dictionaries for the old 2017 ACS subject tables with
old var naming conventions such as hc* */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
*****************************  2/15/2022   *************************************
********************************************************************************

/* to run this do file, run
do $vaprojdir/do_files/acs/acs_2017_gen_dict

OR if you are not Che, run
cd "/home/research/ca_ed_lab/projects/common_core_va"
do do_files/acs/acs_2017_gen_dict
 */

/* NOTE: install descsave package from ssc before running this do file
ssc install descsave, replace  */


 clear all
 set more off
 set varabbrev off
 set scheme s1color
 //capture log close: Stata should not complain if there is no log open to close
 cap log close _all

 * --- output-directory prep (CANONICAL) --------------------------------------
 cap mkdir "$output_dir"
 cap mkdir "$output_dir/csv"
 cap mkdir "$output_dir/csv/acs"
 cap mkdir "$output_dir/csv/acs/2017"
 cap mkdir "$logdir"

 cap mkdir "$logdir/data_prep"
 cap mkdir "$logdir/data_prep/acs"
 log using "$logdir/data_prep/acs/acs_2017_gen_dict.smcl", replace text

 di as text _n "{hline 80}"
 di as text "acs_2017_gen_dict.do — RUN START: `c(current_date)' `c(current_time)'"
 di as text "{hline 80}"



 foreach subject in S0601 S1501 S1702 S1901 {
   import delimited using $vaprojdir/data/public_access/raw/acs/subject_tables/2017/ACS_17_5YR_`subject'_with_ann.csv, clear varnames(1) case(lower)

   foreach v of varlist * {
   	label var `v' `"`=`v'[1]'"'
   	char `v'[varlabel] `"`=`v'[1]'"'
   }
   drop if _n==1

   descsave, list(name varlab) norestore saving($output_dir/csv/acs/2017/acs_2017_`subject'_dict.dta, replace)

   export delimited using $output_dir/csv/acs/2017/acs_2017_`subject'_dict.csv, replace
 }


    //while waiting for write access to project folder, write files to my personal folder to checck them
   /* export delimited using $vaprojdir/data/public_access/raw/acs/subject_tables/2017/acs_2017_`subject'_dict.csv, replace */

cap log close
translate $logdir/data_prep/acs/acs_2017_gen_dict.smcl $logdir/data_prep/acs/acs_2017_gen_dict.log, replace
