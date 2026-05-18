/*------------------------------------------------------------------------------
do/data_prep/schl_chars/cds_nces_xwalk.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    build CDS<->NCES school-id crosswalk from CDE pubschls + NCES EDGE_GEOCODE.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/cde/pubschls.txt  (LEGACY raw — CDE public-school directory)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/cds_nces_id_xwalk.dta

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/cds_nces_xwalk.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                    -> removed (absolute paths)
      log_files/schl_chars/<x> (relative or absolute)    -> $logdir/<x>  (CANONICAL)
      include do_files/sbac/macros_va.doh              -> include $consolidated_dir/do/va/helpers/macros_va.doh
      $vaprojdir/data/public_access/clean/cde/<x>        -> $datadir_clean/cde/<x>  (CANONICAL chain; absolute form)
      $vaprojdir/data/public_access/clean/nces/<x>       -> $datadir_clean/nces/<x>  (CANONICAL chain; absolute form)
      data/public_access/clean/cde/<x>                   -> $datadir_clean/cde/<x>  (CANONICAL chain; relative form post-cd)
      data/public_access/clean/nces/<x>                  -> $datadir_clean/nces/<x>  (CANONICAL chain; relative form post-cd)
      data/sch_char.dta (relative; clean_sch_char only) -> $datadir_clean/sch_char.dta  (CANONICAL master)
      translate log_files/schl_chars/<x> (rel or abs)    -> translate $logdir/<x>  (CANONICAL)
      $vaprojdir/data/public_access/raw/<x>              -> kept LEGACY (raw inputs)
      $vaprojdir/data/restricted_access/clean/<x>        -> kept LEGACY (restricted; out of scope)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag (per Step 7 indexalpha precedent).

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9b
    Sister files (this batch): clean_locale.do, clean_elsch.do, clean_enr.do, clean_frpm.do, clean_staffcred.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_charter.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


/* create crosswalk for CDS code to NCES school ID */

/* to run this do file:
do $vaprojdir/do_files/schl_chars/cds_nces_xwalk.do
 */

/* Note: cdscode in this dataset is unique, but nces_id is not */


* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
log close _all



* --- output-directory prep + log open (CANONICAL) ----------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/schl_chars"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/cde"

log using "$logdir/data_prep/schl_chars/cds_nces_xwalk.smcl", replace text

di as text _n "{hline 80}"
di as text "cds_nces_xwalk.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"
graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984

/* import raw public school datafile */
import delimited $vaprojdir/data/public_access/raw/cde/pubschls.txt, delimiters("\t") clear

keep cdscode nces*

foreach var of varlist nces* {
    replace `var' = "" if `var'== "No Data"
}

keep if !missing(ncesschool) & !missing(ncesdist)

/* convert cdscode to string */
tostring cdscode, replace format("%14.0f")
/* add leading zeros to cdscodes which are only 13 digits */
replace cdscode = "0" + cdscode if strlen(cdscode) == 13

gen nces_id = ncesdist + ncesschool 
label var nces_id "12 digit NCES district and school ID"


save $datadir_clean/cde/cds_nces_id_xwalk.dta, replace
cap log close
translate $logdir/data_prep/schl_chars/cds_nces_xwalk.smcl $logdir/data_prep/schl_chars/cds_nces_xwalk.log, replace
