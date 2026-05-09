/*------------------------------------------------------------------------------
do/share/siblingxwalk/siblingmatch.do — Phase 1a §3.3 step 10 batch 10c relocation
================================================================================

PURPOSE
    build sibling-match (cdscode-pair) crosswalk for VA estimation.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'
    (or as a helper `include'd by sister scripts).

INPUTS (verified via grep on file body)
    $cstdtadir/cst_`year'  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/siblingxwalk/k12_xwalk_name_address
    $datadir_clean/siblingxwalk/k12_xwalk_name_address_year
    $logdir/siblingmatch.smcl (via log using)
    $logdir/siblingmatch.smcl + $logdir/siblingmatch.log (translate)

RELOCATION (per plan v3 §3.3 step 10 batch 10c, applied 2026-05-08)
    Source: caschls/do/share/siblingxwalk/siblingmatch.do
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
    Sister files (this batch): nsc_codebook.do, k12_nsc2019_merge.doh, siblingpairxwalk.do, uniquefamily.do, allvaregs.do, mattschlchar.do


ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* Use CST data to match students with their siblings. Code taken mostly from
do file by Matt Naven  */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close _all
clear all
set more off
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/siblingxwalk"


log using "$logdir/siblingmatch.smcl", replace text

//append all years of CST datasets, from 2004 to 2013
foreach year of numlist 2004 (1) 2013 {
  append using $cstdtadir/cst_`year', keep (state_student_id birth_date year ///
  first_name middle_intl last_name ///
  street_address_line_one street_address_line_two city state zip_code)
}

//drop observations with missing street address line 1. Note that missing() does not work since some observations have one character such as Y or 0
drop if strlen(street_address_line_one) <= 1
drop if missing(state_student_id)
tempfile master
save `master'


********************************************************************************
/* Match siblings based on last name, address, and year. This rules out cases
where someone with the same last name moves to the same address after the previous
student moves out */
local matchonsameyear = 1
if `matchonsameyear' == 1 {

  use `master', clear

  /* check for duplicates. Do not need middle initial and zip code to be the same to count as duplicates, because
  middle initial has 38.56% missing and zip code has 7.36% missing, whereas city and state have around 0.01% and 0% missing, respectively.
  This avoids treating the same person with and w/o middle initial or zip code as different people
  Q: what if 2 people with same last and first names but different middle initial and born on the same day are twins? */
  duplicates report state_student_id year street_address_line_one street_address_line_two city state
  /* only keep one observation per state student ID, year, name, and address*/
  duplicates drop state_student_id year street_address_line_one street_address_line_two city state, force



  /* generate family groups based on last name, address, and year. Treat missing
  as any other variables and group observations with match vars missing into the same family */
  egen long siblings_name_address_year = group(year last_name street_address_line_one street_address_line_two city state zip_code), mi
  /* tostring siblings_name_address_year, replace format("%17.0f") */

  /* drop if no siblings */
  bysort siblings_name_address_year: drop if _N==1

  //generate a variable for number of siblings for each student
  bysort siblings_name_address_year: gen numsiblings = _N-1
  label var numsiblings "number of siblings excluding self"


  // Save data
  order siblings_name_address_year year numsiblings state_student_id first_name  last_name birth_date street_address_line_one street_address_line_two city state zip_code
  sort siblings_name_address_year year
  label var siblings_name_address_year "family ID after matching on name address and year"
  compress

  label data "CST data siblings crosswalk matching on same year, last name, and address"

  save $datadir_clean/siblingxwalk/k12_xwalk_name_address_year, replace
}

/* duplicates report state_student_id birth_date first_name last_name street_address_line_one street_address_line_two city state zip_code
duplicates report state_student_id birth_date first_name last_name street_address_line_one street_address_line_two city state */


********************************************************************************
/* Match siblings based on last name and address */
local matchacrossyears = 1
if `matchacrossyears' == 1 {
  use `master', clear

  /* check for duplicates and keep one observation per state student ID, last name, and address*/
  duplicates report state_student_id street_address_line_one street_address_line_two city state
  duplicates drop state_student_id street_address_line_one street_address_line_two city state, force

  // Group observations if they match on last name, and address
  egen long siblings_name_address = group(last_name street_address_line_one street_address_line_two city state zip_code), mi
  /* tostring siblings_name_address, replace format("%17.0f") */

  // Drop if no siblings
  bysort siblings_name_address: drop if _N==1

  //generate a variable for number of siblings for each student
  bysort siblings_name_address: gen numsiblings = _N-1
  label var numsiblings "number of siblings excluding self"

  //save data
  order siblings_name_address numsiblings state_student_id first_name last_name birth_date street_address_line_one street_address_line_two city state zip_code
  sort siblings_name_address
  label var siblings_name_address "family ID after matching on name and address"
  compress

  label data "CST data siblings crosswalk matching on same last name and address"

  save $datadir_clean/siblingxwalk/k12_xwalk_name_address, replace
}

log close
translate $logdir/siblingmatch.smcl $logdir/siblingmatch.log, replace 
