/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_ecn_disadv.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean CDE economic-disadvantage school-level data; produces $datadir_clean/cde/ecn_disadv.dta.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean  (LEGACY restricted; out of Step 9 scope)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/ecn_disadv.dta
    $logdir/clean_ecn_disadv.smcl (via log using)
    $logdir/clean_ecn_disadv.smcl + $logdir/clean_ecn_disadv.log

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_ecn_disadv.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                    -> removed (absolute paths)
      log_files/schl_chars/* (relative or absolute)    -> $logdir/*  (CANONICAL)
      include do_files/sbac/macros_va.doh              -> include $consolidated_dir/do/va/helpers/macros_va.doh
      $vaprojdir/data/public_access/clean/cde/*        -> $datadir_clean/cde/*  (CANONICAL chain; absolute form)
      $vaprojdir/data/public_access/clean/nces/*       -> $datadir_clean/nces/*  (CANONICAL chain; absolute form)
      data/public_access/clean/cde/*                   -> $datadir_clean/cde/*  (CANONICAL chain; relative form post-cd)
      data/public_access/clean/nces/*                  -> $datadir_clean/nces/*  (CANONICAL chain; relative form post-cd)
      data/sch_char.dta (relative; clean_sch_char only) -> $datadir_clean/sch_char.dta  (CANONICAL master)
      translate log_files/schl_chars/* (rel or abs)    -> translate $logdir/*  (CANONICAL)
      $vaprojdir/data/public_access/raw/*              -> kept LEGACY (raw inputs)
      $vaprojdir/data/restricted_access/clean/*        -> kept LEGACY (restricted; out of scope)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag (per Step 7 indexalpha precedent).

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9b
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_elsch.do, clean_enr.do, clean_frpm.do, clean_staffcred.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_charter.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


/* create a cleaned dataset of proportion of econ disadvantage status in schools */

/* to run this do file:
do $vaprojdir/do_files/schl_chars/clean_ecn_disadv.do
 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
log close _all


graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/cde"

log using "$logdir/clean_ecn_disadv.smcl", replace text

/* import sbac data */
use cdscode year econ_disadvantage ///
    using $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean ///
    if year >= 2015, clear

collapse econ_disadvantage, by(cdscode year)

rename econ_disadvantage prop_ecn_disadv
label var prop_ecn_disadv "Proportion of economic disadvantaged students"


compress 
save $datadir_clean/cde/ecn_disadv.dta, replace 




log close 
translate $logdir/clean_ecn_disadv.smcl $logdir/clean_ecn_disadv.log, replace 