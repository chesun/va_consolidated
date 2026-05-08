/*------------------------------------------------------------------------------
do/data_prep/k12_postsec_distance/merge_k12_postsec_dist.doh — Phase 1a §3.3 step 9 batch 9c relocation
================================================================================

PURPOSE
    helper: merge k12-postsec mindistance variables onto current loaded VA dataset.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.
    Helper / diagnostic file.

INPUTS (verified via grep on file body)
    $consolidated_dir/do/data_prep/k12_postsec_distance/merge_k12_postsec_dist.doh  (helper / sister script)
    $consolidated_dir/do/va/helpers/macros_va.doh  (helper / sister script)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    (none persistent — diagnostic / labels-in-memory only)

RELOCATION (per plan v3 §3.3 step 9 batch 9c, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/k12_postsec_distance/merge_k12_postsec_dist.doh
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
    Sister files (this batch): check_merge.do, hd2021.do, k12_postsec_distances.do, reconcile_cdscodes.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* do helper file to merge k-12 distance to postsecondary institutions to VA dataset 
used in do files that create VA samples */
********************************************************************************

*****************************************************
* First created by Christina (Che) Sun April 11, 2023
* ucsun@ucdavis.edu
*****************************************************

/* To run this do helper file in a do file, include:
include $consolidated_dir/do/data_prep/k12_postsec_distance/merge_k12_postsec_dist.doh
 */

/* CHANGE LOG:
 */


// include the macros
include $consolidated_dir/do/va/helpers/macros_va.doh


merge m:1 cdscode using $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance,  keepusing(mindist*) nogen keep(1 3)
