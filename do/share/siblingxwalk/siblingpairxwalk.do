/*------------------------------------------------------------------------------
do/share/siblingxwalk/siblingpairxwalk.do — Phase 1a §3.3 step 10 batch 10c relocation
================================================================================

PURPOSE
    produce sibling-pair crosswalk dataset for downstream regs.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'
    (or as a helper `include'd by sister scripts).

INPUTS (verified via grep on file body)
    $datadir_clean/siblingxwalk/siblingpairxwalk  (CHAIN read)
    $datadir_clean/siblingxwalk/uniquelinkedfamilyclean  (CHAIN read)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/siblingxwalk/siblingpairxwalk
    $datadir_clean/siblingxwalk/uniquesiblingpairxwalk
    $logdir/siblingpairxwalk.smcl (via log using)
    $logdir/siblingpairxwalk.smcl + $logdir/siblingpairxwalk.log (translate)

RELOCATION (per plan v3 §3.3 step 10 batch 10c, applied 2026-05-08)
    Source: caschls/do/share/siblingxwalk/siblingpairxwalk.do
    Path repointing applied (script-based methodology):
      $projdir/log/share/<sub>/* -> $logdir/* (CANONICAL; flattened from nested predecessor)
      $projdir/out/txt/outcomesumstats/* -> $output_dir/txt/outcomesumstats/* (txt-format log destination for nsc_codebook)
      $projdir/dta/sibling* -> $datadir_clean/sibling* (CANONICAL chain — sibling crosswalks)
      $projdir/dta/schoolchar/* -> $datadir_clean/schoolchar/* (CANONICAL — mattschlchar outputs consumed by Table 8 producers)
      $projdir/dta/<other>/* -> $caschls_projdir/dta/<other>/* (LEGACY-static raw reads)
      $projdir/out/* -> $output_dir/* (intermediate CANONICAL)
      translate (single-line ABS form) -> $logdir/* (CANONICAL)
      /home/research/ca_ed_lab/msnaven/* (mattschlchar dormant rebuild) -> kept verbatim per ADR-0013 + ADR-0021
    Predecessor's `log using' upgraded to consolidated convention.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10c
    Sister files (this batch): nsc_codebook.do, k12_nsc2019_merge.doh, siblingmatch.do, uniquefamily.do, allvaregs.do, mattschlchar.do


ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* create a dataset with all pairwise combinations of siblings and their state student IDs.
Same combination with different orders are different observations. */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************

***this resulting dataset can be used to merge siblings into a dataset with sibling pairs
cap log close _all
clear all
set more off
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/siblingxwalk"


log using "$logdir/siblingpairxwalk.smcl", replace text

use $datadir_clean/siblingxwalk/uniquelinkedfamilyclean, clear

/* make tempfile for merging with joinby command */
drop year numsiblings street_address_line_one street_address_line_two city state zip_code
rename state_student_id sibling_state_student_id
rename first_name sibling_first_name
rename last_name sibling_last_name
rename birth_date sibling_birth_date
rename middle_intl sibling_middle_intl

label var sibling_state_student_id "Sibling State Student ID"
label var sibling_first_name "Sibling First Name"
label var sibling_last_name "Sibling Last Name"
label var sibling_birth_date "Sibling Birth Date"
label var sibling_middle_intl "Sibling Middle Initial"

tempfile formerge
save `formerge'

use $datadir_clean/siblingxwalk/uniquelinkedfamilyclean, clear
drop year numsiblings street_address_line_one street_address_line_two city state zip_code
joinby ufamilyid using `formerge'

/* drop observations where self joins on self */
drop if state_student_id == sibling_state_student_id

order ufamilyid state_student_id sibling_state_student_id


save $datadir_clean/siblingxwalk/siblingpairxwalk, replace




*******create unique sibling pairs by dropping permutations
//load the pairwise combination of siblings dataset
use $datadir_clean/siblingxwalk/siblingpairxwalk, clear
egen pairorder1 = concat(state_student_id sibling_state_student_id)
egen pairorder2 = concat(sibling_state_student_id state_student_id)

//pairorder1 has pairs in ascending order
replace pairorder1 = pairorder2 if state_student_id > sibling_state_student_id

//remove duplicate permutations within family
bysort ufamilyid pairorder1: gen i = _n
keep if i==1

drop pairorder1 pairorder2 i


//distance between birth dates for sibling pairs
gen birth_date_distance = abs(birth_date - sibling_birth_date)

bysort ufamilyid: egen avg_birth_date_distance_family = mean(birth_date_distance)

replace avg_birth_date_distance_family = avg_birth_date_distance_family/365
label var avg_birth_date_distance_family "Average distance of birth dates in family in years"


label data "Unique sibling pairs after dropping duplicate permutations"

save $datadir_clean/siblingxwalk/uniquesiblingpairxwalk, replace


log close
translate $logdir/siblingpairxwalk.smcl $logdir/siblingpairxwalk.log, replace
