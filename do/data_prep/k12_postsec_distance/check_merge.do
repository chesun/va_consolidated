/*------------------------------------------------------------------------------
do/data_prep/k12_postsec_distance/check_merge.do — Phase 1a §3.3 step 9 batch 9c relocation
================================================================================

PURPOSE
    verify k12_postsec mindistance merges cleanly with score_b sample (sanity check, diagnostic only).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.
    Helper / diagnostic file.

INPUTS (verified via grep on file body)
    $vaprojdir/data/va_samples_v1/score_b.dta  (LEGACY read — VA sample for diagnostic merge check)
    $consolidated_dir/do/va/helpers/macros_va.doh  (consolidated helper; via include)
    $consolidated_dir/do/data_prep/k12_postsec_distance/merge_k12_postsec_dist.doh  (consolidated helper; via include — does the actual mindistance merge)
    $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance.dta  (CHAIN read; merged in via the include above)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/data_prep/k12_postsec_distance/check_merge.smcl (via log using)
    $logdir/data_prep/k12_postsec_distance/check_merge.smcl + $logdir/data_prep/k12_postsec_distance/check_merge.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9c, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/k12_postsec_distance/check_merge.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                          -> removed (absolute paths)
      log_files/k12_postsec_distance/<x> (absolute form)       -> $logdir/<x>  (CANONICAL)
      include $vaprojdir/do_files/sbac/macros_va.doh         -> include $consolidated_dir/do/va/helpers/macros_va.doh
      include $vaprojdir/do_files/k12_postsec_distance/<x>.doh -> include $consolidated_dir/do/data_prep/k12_postsec_distance/<x>.doh
      run/do $vaprojdir/do_files/k12_postsec_distance/<x>     -> run/do $consolidated_dir/do/data_prep/k12_postsec_distance/<x>
      $distance_dtadir/clean/k12_postsec_distance             -> $datadir_clean/k12_postsec_distance/clean/k12_postsec_distance  (CANONICAL chain)
      $distance_dtadir/clean/k12_postsec_mindistance          -> $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance  (CANONICAL chain)
      save, replace (reconcile_cdscodes.do; in-place after use) -> explicit save $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance.dta, replace
      translate (multi-line ///) ABS form                     -> translate $logdir/<x>  (CANONICAL)
      $distance_dtadir/raw/<x> (LEGACY raw)                     -> kept LEGACY (predecessor raw IPEDS / CDE inputs)
      $vaprojdir/data/k12_postsec_distance/raw/<x>              -> kept LEGACY (raw inputs; equivalent to $distance_dtadir/raw/<x>)

    SECURITY SCRUB applied: OpenCage API key (revoked 2026-04-30 per T1-5)
    in commented `opencagegeo' line of k12_postsec_distances.do replaced
    with placeholder "REVOKED-2026-04-30".  Predecessor file in
    cde_va_project_fork still retains the key; consolidated does not.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9c
    Sister files (this batch): merge_k12_postsec_dist.doh, hd2021.do, k12_postsec_distances.do, reconcile_cdscodes.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


// check the schools in the VA base sample not merged to the distance dataset

/*
do $consolidated_dir/do/data_prep/k12_postsec_distance/check_merge.do

 */

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"

cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/k12_postsec_distance"
log using "$logdir/data_prep/k12_postsec_distance/check_merge.smcl", replace text name(check_merge)

include $consolidated_dir/do/va/helpers/macros_va.doh

use $vaprojdir/data/va_samples_v1/score_b.dta, clear

merge m:1 cdscode using $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance, keepusing(mindist*)

tab cdscode year if _merge==1

cap log close check_merge
translate $logdir/data_prep/k12_postsec_distance/check_merge.smcl $logdir/data_prep/k12_postsec_distance/check_merge.log, replace
