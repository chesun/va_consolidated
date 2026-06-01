/*------------------------------------------------------------------------------
do/survey_va/mattschlchar.do — Phase 1a §3.3 step 10 batch 10c relocation
================================================================================

PURPOSE
    Christina-authored wrapper (despite name) — produces $datadir_clean/schoolchar/schlcharpooledmeans.dta consumed by Table 8 panels (per ADR-0013; clean=0 gate; rebuild path dormant).

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'
    (or as a helper `include'd by sister scripts).

INPUTS (verified via grep on file body)
    $datadir_raw/upstream/mattschlchar  (VENDORED — already-cleaned school-char file, per ADR-0023; provisions the CHAIN file under clean==0)
    $datadir_clean/schoolchar/elprop  (CHAIN read)
    $datadir_clean/schoolchar/mattschlchar  (CHAIN read; provisioned from the vendored copy above under clean==0)
    $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta  (LEGACY)
    /home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char  (LEGACY hardcoded; per ADR-0013 dormant rebuild branch — source no longer accessible)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/schoolchar/elprop
    $datadir_clean/schoolchar/mattschlchar
    $datadir_clean/schoolchar/schlcharpooledmeans
    $logdir/survey_va/mattschlchar.smcl (via log using)
    $logdir/survey_va/mattschlchar.smcl + $logdir/survey_va/mattschlchar.log (translate)

RELOCATION (per plan v3 §3.3 step 10 batch 10c, applied 2026-05-08)
    Source: caschls/do/share/factoranalysis/mattschlchar.do
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
    Sister files (this batch): nsc_codebook.do, k12_nsc2019_merge.doh, siblingmatch.do, siblingpairxwalk.do, uniquefamily.do, allvaregs.do
    ADR-0013: mattschlchar.do is Christina-authored despite filename; clean=0 gate kept; rebuild branch dormant.

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* clean and pull school characteristics from the dataset created by Matt Naven, for use in
VA regressions with index + school characteristics  */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close mattschlchar
clear all
set more off
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/survey_va"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/schoolchar"
cap mkdir "$datadir_raw/upstream"


log using "$logdir/survey_va/mattschlchar.smcl", replace text name(mattschlchar)

// a macro toggle for cleaning the raw data from Matt's folder
local clean = 0
if `clean' == 1 {
  use /home/research/ca_ed_lab/msnaven/common_core_va/data/sch_char, clear

  rename enr_total enrtotal
  label var enrtotal "total enrollment"

  rename enr_minority_prop minorityenrprop
  label var minorityenrprop "proportion of minority enrollment"

  rename enr_male_prop maleenrprop
  label var maleenrprop "proportion of male enrollment"

  rename frpm_prop freemealprop
  label var freemealprop "proportion eleigible for free or reduced price meals"

  drop el_prop

  rename male_prop maleteachprop
  label var maleteachprop "proportion of male teachers"

  rename eth_minority_prop minoritystaffprop
  label var minoritystaffprop "proportion of minority staff"

  rename new_teacher_prop newteachprop
  label var newteachprop "proportion of teachers with less than or equal to 3 years experience"

  rename credential_full_prop fullcredprop
  label var fullcredprop "proprotion of full credential"

  rename fte_teach fteteach
  label var fteteach "number of FTE teachers"

  rename fte_admin fteadmin
  label var fteadmin "number of FTE administrators"

  rename fte_pupil ftepupil
  label var ftepupil "number of FTE pupils"

  rename fte_teach_pc fteteachperstudent
  label var fteteachperstudent "FTE teacher per student"

  rename fte_admin_pc fteadminperstudent
  label var fteadminperstudent "FTE admin per student"

  rename fte_pupil_pc fteserviceperstudent
  label var fteserviceperstudent "FTE pupil service per student"

  label data "School Characterstics data by Matt Naven, cleaned by Che Sun"

  save $datadir_clean/schoolchar/mattschlchar, replace
}

// if cannot access Matt's folder, read the vendored copy of the already-cleaned
// dataset.  The clean==1 rebuild branch above is permanently dormant (ADR-0013)
// and its raw source (Matt's user dir) is no longer accessible, so the cleaned
// mattschlchar.dta is vendored into the consolidated sandbox per ADR-0023.
// Provision the CHAIN file at $datadir_clean/schoolchar/mattschlchar from the
// vendored raw copy so the downstream `use' at the consumption block below finds it.
// To (re)vendor on Scribe (one-time / fresh-setup):
//   cp $caschls_projdir/dta/schoolchar/mattschlchar.dta $datadir_raw/upstream/mattschlchar.dta
if `clean' == 0 {
        di "macro clean is toggled to 0"

    noi cap copy "$caschls_projdir/dta/schoolchar/mattschlchar.dta" ///
        "$consolidated_dir/data/raw/upstream/mattschlchar.dta"
  use $datadir_raw/upstream/mattschlchar, clear
  save $datadir_clean/schoolchar/mattschlchar, replace
}

//create elprop by collapsing student test score data to avoid missing data problem in the CDE school level dataset
use cdscode year limited_eng_prof all_students_sample ///
if all_students_sample==1 & inrange(year, 2015, 2017) ///
using $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta, clear
collapse elprop = limited_eng_prof, by(cdscode year)
collapse elprop, by(cdscode)
drop if missing(cdscode)
label var elprop "proportion of English Leaners"
compress
label data "Proportion of English Learners from collapsing student level test score dataset"
save $datadir_clean/schoolchar/elprop, replace



use $datadir_clean/schoolchar/mattschlchar, clear

// keep observations from 14-15 to 16-17 to condition on the same year as VA estimates since year is the year of spring semester
keep if inrange(year, 2015, 2017)
drop if missing(cdscode)

drop enrtotal fteteach fteadmin ftepupil

collapse *prop fte*, by(cdscode)

merge 1:1 cdscode using $datadir_clean/schoolchar/elprop
//keep only merged obs
keep if _merge==3
drop _merge

label data "Pooled average over 14-15 to 16-17 school characteristics data"
compress
save $datadir_clean/schoolchar/schlcharpooledmeans, replace


cap log close mattschlchar
translate $logdir/survey_va/mattschlchar.smcl $logdir/survey_va/mattschlchar.log, replace
