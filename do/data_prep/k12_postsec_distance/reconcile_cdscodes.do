/*------------------------------------------------------------------------------
do/data_prep/k12_postsec_distance/reconcile_cdscodes.do — Phase 1a §3.3 step 9 batch 9c relocation
================================================================================

PURPOSE
    reconcile cdscode changes; updates $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance.dta in-place.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.
    Sub-script invoked from `k12_postsec_distances.do'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/k12_postsec_distance/raw/cdscode_changes.csv  (LEGACY raw — CDS code changes lookup)
    $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance  (CHAIN read; loaded via `use', updated in-place)

ORPHAN STATUS
    Per coder-critic round-1 finding on commit `4403758': this script is
    NOT invoked from `k12_postsec_distances.do' (the predecessor MAIN
    never called `do reconcile_cdscodes.do'); it is also NOT invoked
    from `do/main.do' Phase 1.  The script is preserved per ADR-0021
    verbatim but is currently orphan in both predecessor and consolidated
    pipelines.  Phase 1c §5.1 dead-code review will decide whether to
    archive (per ADR-0010 archive-convention) or wire into main.do.

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance.dta
    $logdir/reconcile_cdscodes.smcl (via log using)
    $logdir/reconcile_cdscodes.smcl + $logdir/reconcile_cdscodes.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9c, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/k12_postsec_distance/reconcile_cdscodes.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                          -> removed (absolute paths)
      log_files/k12_postsec_distance/* (absolute form)       -> $logdir/*  (CANONICAL)
      include $vaprojdir/do_files/sbac/macros_va.doh         -> include $consolidated_dir/do/va/helpers/macros_va.doh
      include $vaprojdir/do_files/k12_postsec_distance/<x>.doh -> include $consolidated_dir/do/data_prep/k12_postsec_distance/<x>.doh
      run/do $vaprojdir/do_files/k12_postsec_distance/<x>     -> run/do $consolidated_dir/do/data_prep/k12_postsec_distance/<x>
      $distance_dtadir/clean/k12_postsec_distance             -> $datadir_clean/k12_postsec_distance/clean/k12_postsec_distance  (CANONICAL chain)
      $distance_dtadir/clean/k12_postsec_mindistance          -> $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance  (CANONICAL chain)
      save, replace (reconcile_cdscodes.do; in-place after use) -> explicit save $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance.dta, replace
      translate (multi-line ///) ABS form                     -> translate $logdir/*  (CANONICAL)
      $distance_dtadir/raw/* (LEGACY raw)                     -> kept LEGACY (predecessor raw IPEDS / CDE inputs)
      $vaprojdir/data/k12_postsec_distance/raw/*              -> kept LEGACY (raw inputs; equivalent to $distance_dtadir/raw/*)

    SECURITY SCRUB applied: OpenCage API key (revoked 2026-04-30 per T1-5)
    in commented `opencagegeo' line of k12_postsec_distances.do replaced
    with placeholder "REVOKED-2026-04-30".  Predecessor file in
    cde_va_project_fork still retains the key; consolidated does not.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9c
    Sister files (this batch): check_merge.do, merge_k12_postsec_dist.doh, hd2021.do, k12_postsec_distances.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


/* reconcile cdscodes that don't match up between VA sample and CDE directory by
changing cdscodes in the pubschls file to match the unmatched schools' cdscodes
in the VA sample, 11 schools in total. Reason is closure or merge.

unmatched cdscodes in VA sample :
01611190130625
04614400121509
07617960132233
18641620135756
18641626010763
19101990109942
19756971996693
19768850132928
37770320134577
44697650100305
45701690129957


corresponding cdscodes from CDE:
01100170130625
04615070121509
07773540132233
18641960135756
18641546010763
19772890109942
19649071996693
19647330132928
37103710134577
44104470100305
45104540129957
*/

/* Edited and added to VA project repo by Christina Sun
First created 04/30/2023 */

/* to run this do file:
do $consolidated_dir/do/data_prep/k12_postsec_distance/reconcile_cdscodes.do
 */

 /* CHANGE LOG (CHRISTINA SUN):
*/

cap log close _all
clear all

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/k12_postsec_distance"
cap mkdir "$datadir_clean/k12_postsec_distance/clean"

log using "$logdir/reconcile_cdscodes.smcl", replace text


import delimited using $vaprojdir/data/k12_postsec_distance/raw/cdscode_changes.csv, clear

foreach v of varlist cdscode_va cdscode_cde {
  // convert the 14 digit cdscode from float to string
  tostring `v', generate(`v'_str) format("%15.0f")
  drop `v'
  rename `v'_str `v'

  // replace back leading zeros lost in the conversion
  replace `v' = "0" + `v' if strlen(`v')==13
}

rename cdscode_cde cdscode

tempfile cdscodes
save `cdscodes'

use $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance, clear

merge 1:1 cdscode using `cdscodes', nogen

replace cdscode = cdscode_va if cdscode_va!=""


save $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance.dta, replace
log close
translate $logdir/reconcile_cdscodes.smcl $logdir/reconcile_cdscodes.log, replace
