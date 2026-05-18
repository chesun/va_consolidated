/*------------------------------------------------------------------------------
do/data_prep/responserate/parentresponserate.do — Phase 1a §3.3 step 9 batch 9g relocation
================================================================================

PURPOSE
    compute CalSCHLS parent survey response rates by school; reads CHAIN trimparentdemo<year>; writes $datadir_clean/calschls/responserate/parentresponserate.dta (consumed by batch 9f parentpooling).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Order:
    trimsecdemo -> secresponserate -> trimparentdemo -> parentresponserate
    (mirrors predecessor master.do:220-229).

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1415  (CHAIN read)
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1516  (CHAIN read)
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1617  (CHAIN read)
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1718  (CHAIN read)
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1819  (CHAIN read)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/responserate/parentresponserate
    $logdir/data_prep/responserate/parentresponserate.smcl (via log using)
    $logdir/data_prep/responserate/parentresponserate.smcl + $logdir/data_prep/responserate/parentresponserate.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9g — extension batch added 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/responserate/parentresponserate.do
    Path repointing applied (script-based methodology):
      $projdir/log/build/buildanalysisdata/responserate/<x> -> $logdir/<x> (CANONICAL)
      $projdir/dta/buildanalysisdata/demotrim/<sub>/<x> -> $datadir_clean/calschls/demotrim/<sub>/<x> (CANONICAL chain)
      $projdir/dta/buildanalysisdata/responserate/<x> -> $datadir_clean/calschls/responserate/<x> (CANONICAL output for batch 9f)
      $projdir/dta/demographics/<sub>/<x> (read) -> $caschls_projdir/dta/demographics/<sub>/<x> (LEGACY raw)
      translate -> $logdir/<x> (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9g (extension; named-scope decision: include
        per Christina 2026-05-08 — chain prerequisite for batch 9f poolingdata)
    Sister files (this batch): trimsecdemo.do, secresponserate.do, trimparentdemo.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* merging trimmed parent demographics to generate conditional response rates */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************
cap log close parentresponserate
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/responserate"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/calschls"
cap mkdir "$datadir_clean/calschls/responserate"

log using "$logdir/data_prep/responserate/parentresponserate.smcl", replace text name(parentresponserate)

use $datadir_clean/calschls/demotrim/parent/trimparentdemo1415, replace
merge 1:1 cdscode using $datadir_clean/calschls/demotrim/parent/trimparentdemo1516
/* matched: 346. not matched: 952 (from master: 389, from using: 363) */

drop _merge
merge 1:1 cdscode using $datadir_clean/calschls/demotrim/parent/trimparentdemo1617
/* matched: 559. not matched: 1278 (from master: 739, from using: 539) */

drop _merge
merge 1:1 cdscode using $datadir_clean/calschls/demotrim/parent/trimparentdemo1718
/* matched: 955. not matched: 1426 (from master: 882, from using: 544) */

drop _merge
merge 1:1 cdscode using $datadir_clean/calschls/demotrim/parent/trimparentdemo1819
/* matched: 1266. not matched: 1285 (from master: 1115, from using: 170) */

drop _merge

local grades `" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "' //local macro for grades
//recode the missing values for survey response as 0 since unmatched means there were no responses for that year
foreach i of local grades {
  replace svygr`i'_1415 = 0 if svygr`i'_1415 == .
  replace svygr`i'_1516 = 0 if svygr`i'_1516 == .
  replace svygr`i'_1617 = 0 if svygr`i'_1617 == .
  replace svygr`i'_1718 = 0 if svygr`i'_1718 == .
  replace svygr`i'_1819 = 0 if svygr`i'_1819 == .
}


/* generate indicators for which year each school had survey responses */
local years `" "1415" "1516" "1617" "1718" "1819" "' //local macro for survey years
//generate total survey responses for grades 1-12
foreach year of local years {
  gen svy`year' = svygr1_`year' + svygr2_`year' + svygr3_`year' + svygr4_`year' + svygr5_`year' + svygr6_`year' ///
  + svygr7_`year' + svygr8_`year' + svygr9_`year' + svygr10_`year' + svygr11_`year' + svygr12_`year'
  label var svy`year' "total survey response for grades 1-12 households in year `year'"
}
//generate total enrollment for grades 1-12
foreach year of local years {
  gen enr`year' = enrgr1_`year' + enrgr2_`year' + enrgr3_`year' + enrgr4_`year' + enrgr5_`year' + enrgr6_`year' ///
  + enrgr7_`year' + enrgr8_`year' + enrgr9_`year' + enrgr10_`year' + enrgr11_`year' + enrgr12_`year'
  label var enr`year' "total enrollment in grades 1-12 in year `year'"
}
//generate indicators for which years the school has survey responses
foreach year of local years {
  gen has`year' = 0
  replace has`year' = 1 if svy`year' > 0
  label var has`year' "has survey response in year `year'"
}

//generate overall response rate for each school including only years with survey responses
gen denomtemp = 0 //generate a temp var for the denominator of response rate
gen numertemp = 0 //generate a temp var for the numerator of response rate
//add up the number of survey responses and enrollment from all years with survey response
foreach year of local years {
  replace denomtemp = denomtemp + enr`year' if has`year' == 1
  replace numertemp = numertemp + svy`year' if has`year' == 1
}
//generate the pooled response rate only including years with responses
gen pooledrr = numertemp/denomtemp
label var pooledrr "pooled response rate for grades 1-12"
drop denomtemp numertemp

//generate pooled response rate for grades 9 and 11 for each school including only years with survey responses
gen denomtemp = 0 //generate a temp var for the denominator of response rate
gen numertemp = 0 //generate a temp var for the numerator of response rate
//add up the number of survey responses in grades 9 and 11 and enrollment for grades 9 and 11 from all years with survey response
foreach year of local years {
  replace denomtemp = denomtemp + enrgr9_`year' + enrgr11_`year' if has`year' == 1
  replace numertemp = numertemp + svygr9_`year' + svygr11_`year' if has`year' == 1
}
//generate the pooled response rate only including years with responses
gen pooledrr_gr9and11 = numertemp/denomtemp
label var pooledrr_gr9and11 "pooled response rate for grades 9 and 11"
drop denomtemp numertemp

label data "parent survey response numbers by grade year with pooled response rates"
compress
save $datadir_clean/calschls/responserate/parentresponserate, replace

cap log close parentresponserate
translate $logdir/data_prep/responserate/parentresponserate.smcl $logdir/data_prep/responserate/parentresponserate.log, replace
