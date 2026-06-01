/*------------------------------------------------------------------------------
do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh — Phase 1a §3.3 step 10 batch 10c relocation
================================================================================

PURPOSE
    helper: merge K12 outcomes with NSC 2019-new postsecondary outcomes.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'
    (or as a helper `include'd by sister scripts).

INPUTS (verified via grep on file body)
    /home/research/ca_ed_lab/msnaven/data/public_access/clean/k12_public_schools/k12_public_schools_clean.dta  (LEGACY hardcoded; per ADR-0013 dormant rebuild branch)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/outcomesumstats/k12_nsc_2019_final_merge
    $datadir_clean/outcomesumstats/k12_nsc_2019_provisional_merge

RELOCATION (per plan v3 §3.3 step 10 batch 10c, applied 2026-05-08)
    Source: caschls/do/share/outcomesumstats/nsc2019new/k12_nsc2019_merge.doh
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
    Sister files (this batch): nsc_codebook.do, siblingmatch.do, siblingpairxwalk.do, uniquefamily.do, allvaregs.do, mattschlchar.do


ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* Merge K-12 data with the NSC 2019 provisional and final outcome crosswalk daatasets */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
*****************************10/13/2021****************************************

********************************************************************************

use merge_id_k12_test_scores all_students_sample first_scores_sample dataset ///
test cdscode state_student_id year grade	///
using `k12_test_scores_dir'/k12_test_scores_clean.dta, clear
compress
tempfile k12
save `k12'

/* merge k-12 test score with NSC 2019 provisional outcome crosswalk */
use `k12', clear
gen k12_nsc_match = 0

merge m:1 state_student_id using `nsc2019provisonalxwalk', gen(merge_k12_nsc) keep(1 3)
replace k12_nsc_match = 1 if merge_k12_nsc==3
drop merge_k12_nsc

//merge on conventional school status
merge m:1 cdscode using /home/research/ca_ed_lab/msnaven/data/public_access/clean/k12_public_schools/k12_public_schools_clean.dta, ///
gen(merge_public_schools) keepusing(conventional_school) keep(1 3)
compress
label data "K-12 test score merged to NSC 2019 Provisional dataset outcomes"
* --- output-directory prep (CANONICAL; fragment cannot assume caller made dirs) ---
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/outcomesumstats"
save $datadir_clean/outcomesumstats/k12_nsc_2019_provisional_merge, replace

/* merge k-12 test score with NSC 2019 final outcome crosswalk */
use `k12', clear
gen k12_nsc_match = 0

merge m:1 state_student_id using `nsc2019finalxwalk', gen(merge_k12_nsc) keep(1 3)
replace k12_nsc_match = 1 if merge_k12_nsc==3
drop merge_k12_nsc

//merge on conventional school status
merge m:1 cdscode using /home/research/ca_ed_lab/msnaven/data/public_access/clean/k12_public_schools/k12_public_schools_clean.dta, ///
gen(merge_public_schools) keepusing(conventional_school) keep(1 3)
compress
label data "K-12 test score merged to NSC 2019 final dataset outcomes"
save $datadir_clean/outcomesumstats/k12_nsc_2019_final_merge, replace
