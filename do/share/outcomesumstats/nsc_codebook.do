/*------------------------------------------------------------------------------
do/share/outcomesumstats/nsc_codebook.do — Phase 1a §3.3 step 10 batch 10c relocation
================================================================================

PURPOSE
    produce NSC outcomes codebook (txt log) — 2010-2017 + 2010-2018 versions.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'
    (or as a helper `include'd by sister scripts).

INPUTS (verified via grep on file body)
    $nscdtadir/nsc_2010_2017_clean  (LEGACY)
    $nscdtadir/nsc_2010_2018_clean  (LEGACY)
    $output_dir/txt/outcomesumstats/nsc_2010_2017_codebook.txt  (LEGACY)
    $output_dir/txt/outcomesumstats/nsc_2010_2018_codebook.txt  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $output_dir/txt/outcomesumstats/nsc_2010_2017_codebook.txt (via log using)
    $output_dir/txt/outcomesumstats/nsc_2010_2018_codebook.txt (via log using)

RELOCATION (per plan v3 §3.3 step 10 batch 10c, applied 2026-05-08)
    Source: caschls/do/share/outcomesumstats/nsc_codebook.do
    Path repointing applied (script-based methodology):
      $projdir/log/share/<sub>/<x> -> $logdir/<x> (CANONICAL; flattened from nested predecessor)
      $projdir/out/txt/outcomesumstats/<x> -> $output_dir/txt/outcomesumstats/<x> (txt-format log destination for nsc_codebook)
      $projdir/dta/sibling* -> $datadir_clean/sibling* (CANONICAL chain — sibling crosswalks)
      $projdir/dta/schoolchar/<x> -> $datadir_clean/schoolchar/<x> (CANONICAL — mattschlchar outputs consumed by Table 8 producers)
      $projdir/dta/<other>/<x> -> $caschls_projdir/dta/<other>/<x> (LEGACY-static raw reads)
      $projdir/out/<x> -> $output_dir/<x> (intermediate CANONICAL)
      translate (single-line ABS form) -> $logdir/<x> (CANONICAL)
      /home/research/ca_ed_lab/msnaven/<x> (mattschlchar dormant rebuild) -> kept verbatim per ADR-0013 + ADR-0021
    Predecessor's `log using' upgraded to consolidated convention.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10c
    Sister files (this batch): k12_nsc2019_merge.doh, siblingmatch.do, siblingpairxwalk.do, uniquefamily.do, allvaregs.do, mattschlchar.do


ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* create a txt file codebook for NSC clean datasets, both for 2010-2017
and 2010-2018 */
********************************************************************************
/* to run this do file, type:
do $projdir/do/share/outcomesumstats/nsc_codebook.do
 */

use $nscdtadir/nsc_2010_2017_clean, clear
quietly {
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
cap mkdir "$logdir/share/outcomesumstats"
cap mkdir "$output_dir"
cap mkdir "$output_dir/txt"
cap mkdir "$output_dir/txt/outcomesumstats"

    log using "$output_dir/txt/outcomesumstats/nsc_2010_2017_codebook.txt", text replace
    noisily codebook
    log close
}

use $nscdtadir/nsc_2010_2018_clean, clear
quietly {
    log using "$output_dir/txt/outcomesumstats/nsc_2010_2018_codebook.txt", text replace
    noisily codebook
    log close
}
