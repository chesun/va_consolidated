/*------------------------------------------------------------------------------
do/share/siblingxwalk/uniquefamily.do — Phase 1a §3.3 step 10 batch 10c relocation
================================================================================

PURPOSE
    produce unique-family identifier crosswalk.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'
    (or as a helper `include'd by sister scripts).

INPUTS (verified via grep on file body)
    $datadir_clean/siblingxwalk/k12_xwalk_name_address_year  (CHAIN read)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/siblingxwalk/ufamilyxwalk
    $datadir_clean/siblingxwalk/uniquelinkedfamilyclean
    $datadir_clean/siblingxwalk/uniquelinkedfamilyraw
    $logdir/uniquefamily.smcl (via log using)
    $logdir/uniquefamily.smcl + $logdir/uniquefamily.log (translate)
    $output_dir/graph/siblingxwalk/numsiblingdist.png

RELOCATION (per plan v3 §3.3 step 10 batch 10c, applied 2026-05-08)
    Source: caschls/do/share/siblingxwalk/uniquefamily.do
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
    Sister files (this batch): nsc_codebook.do, k12_nsc2019_merge.doh, siblingmatch.do, siblingpairxwalk.do, allvaregs.do, mattschlchar.do


ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* use the sibling crosswalk dataset conditional on same year and create unique family ID
to link siblings from the same family across years and delete duplicates  */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************

/* to run this do file:
do $projdir/do/share/siblingxwalk/uniquefamily.do
 */
cap log close _all
clear all
set more off
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/sibling"


log using "$logdir/uniquefamily.smcl", replace text

use $datadir_clean/siblingxwalk/k12_xwalk_name_address_year, clear

/* install ssc package that group observations by the connected components of two variables  */
/* ssc install group_twoway, replace */

/* convert to string to match variable format of state student ID in order to run group_twoway */
tostring siblings_name_address_year, replace format("%17.0f")
/* make family ID and state student ID disjoint to avoid error with command
https://haghish.com/statistics/stata-blog/stata-programming/download/group_twoway.html  */
replace siblings_name_address_year = "family"+siblings_name_address_year

/* this creates a group for all students that are linked to each other through the same family across years.
This command links observations that are connected through famnily ID and student ID. So if two siblings are observed in the same year
but one of them is observed in another year with another sibling, they will be linked together. This also links siblings even if they move*/
group_twoway siblings_name_address_year state_student_id, generate(ufamilyid)

bysort ufamilyid: replace numsiblings = _N-1
save $datadir_clean/siblingxwalk/uniquelinkedfamilyraw, replace

/* keep one copy per student */
duplicates report state_student_id
duplicates drop state_student_id, force

bysort ufamilyid: replace numsiblings = _N-1
label var ufamilyid "unique family ID after linking all siblings in same family"

/* Note: for large number of siblings the reason could be cousins/other relatives with the same
last name lived in the same address at a certain point so that links all of the cousins etc */
drop siblings_name_address_year
order ufamilyid year numsiblings state_student_id first_name  last_name birth_date street_address_line_one street_address_line_two city state zip_code
hist numsiblings
graph export $output_dir/graph/siblingxwalk/numsiblingdist.png, replace
save $datadir_clean/siblingxwalk/uniquelinkedfamilyclean, replace

//artificial cutoff of max 10 children per family, anything above that likely to be matching error
drop if numsiblings >= 9
keep ufamilyid numsiblings state_student_id first_name last_name birth_date

rename numsiblings numsiblings_exclude_sef
gen numsiblings_total = numsiblings_exclude_sef + 1
label var numsiblings_total "Total number of siblings in the family"

//order the siblings within a family by birth order, oldest sibling is first born so has birth order 1, etc.
sort ufamilyid birth_date
by ufamilyid: gen birth_order = _n
label var birth_order "Order of birth in the family"

//number of older siblings
gen numsiblings_older = birth_order - 1
label var numsiblings_older "Number of older siblings"

gen sibling_full_sample = 1
label var sibling_full_sample "Indicator for the entire matched siblings sample"

compress
label data "dataset with unique family ID for each SSID, family size capped at 10 children"
save $datadir_clean/siblingxwalk/ufamilyxwalk, replace


log close
translate $logdir/uniquefamily.smcl $logdir/uniquefamily.log, replace 
