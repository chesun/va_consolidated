/*------------------------------------------------------------------------------
do/data_prep/responserate/trimparentdemo.do — Phase 1a §3.3 step 9 batch 9g relocation
================================================================================

PURPOSE
    trim CalSCHLS parent demographic data per year (1415-1819); produces $datadir_clean/calschls/demotrim/parent/trimparentdemo<year>.dta (5 yearly files; consumed by parentresponserate).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Order:
    trimsecdemo -> secresponserate -> trimparentdemo -> parentresponserate
    (mirrors predecessor master.do:220-229).

INPUTS (verified via grep on file body)
    $caschls_projdir/dta/demographics/parent/parentdemo1415  (LEGACY)
    $caschls_projdir/dta/demographics/parent/parentdemo1516  (LEGACY)
    $caschls_projdir/dta/demographics/parent/parentdemo1617  (LEGACY)
    $caschls_projdir/dta/demographics/parent/parentdemo1718  (LEGACY)
    $caschls_projdir/dta/demographics/parent/parentdemo1819  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1415
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1516
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1617
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1718
    $datadir_clean/calschls/demotrim/parent/trimparentdemo1819
    $logdir/trimparentdemo.smcl (via log using)
    $logdir/trimparentdemo.smcl + $logdir/trimparentdemo.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9g — extension batch added 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/responserate/trimparentdemo.do
    Path repointing applied (script-based methodology):
      $projdir/log/build/buildanalysisdata/responserate/* -> $logdir/* (CANONICAL)
      $projdir/dta/buildanalysisdata/demotrim/<sub>/* -> $datadir_clean/calschls/demotrim/<sub>/* (CANONICAL chain)
      $projdir/dta/buildanalysisdata/responserate/* -> $datadir_clean/calschls/responserate/* (CANONICAL output for batch 9f)
      $projdir/dta/demographics/<sub>/* (read) -> $caschls_projdir/dta/demographics/<sub>/* (LEGACY raw)
      translate -> $logdir/* (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9g (extension; named-scope decision: include
        per Christina 2026-05-08 — chain prerequisite for batch 9f poolingdata)
    Sister files (this batch): trimsecdemo.do, secresponserate.do, parentresponserate.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* trim demographics data for parent survey and rename vars to prepare for
generating conditional response rate datasets */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************
cap log close _all
clear all
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/calschls"
cap mkdir "$datadir_clean/calschls/demotrim"
cap mkdir "$datadir_clean/calschls/demotrim/parent"

log using "$logdir/trimparentdemo.smcl", replace text

/* rename variables in the secondary demographics datasets to indicate year, keep only vars needed to calculate response rates */
local grades `" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "' //local macro for grades

use $caschls_projdir/dta/demographics/parent/parentdemo1415, replace
keep cdscode svygr1 svygr2 svygr3 svygr4 svygr5 svygr6 svygr7 svygr8 svygr9 svygr10 svygr11 svygr12 ///
gr1enr gr2enr gr3enr gr4enr gr5enr gr6enr gr7enr gr8enr gr9enr gr10enr gr11enr gr12enr
//renaming vars to indicate the year of the dataset to prepare for merging with other years later
foreach i of local grades {
  rename svygr`i' svygr`i'_1415
  rename gr`i'enr enrgr`i'_1415
  label var svygr`i'_1415 "number of grade `i' household responses in 1415"
  label var enrgr`i'_1415 "grade `i' enrollment in 1415"
}
label data "trimmed parent demographics 1415 including only survey responses and enrollment for grades 1-12"
compress
save $datadir_clean/calschls/demotrim/parent/trimparentdemo1415, replace


use $caschls_projdir/dta/demographics/parent/parentdemo1516, replace
keep cdscode svygr1 svygr2 svygr3 svygr4 svygr5 svygr6 svygr7 svygr8 svygr9 svygr10 svygr11 svygr12 ///
gr1enr gr2enr gr3enr gr4enr gr5enr gr6enr gr7enr gr8enr gr9enr gr10enr gr11enr gr12enr
foreach i of local grades {
  rename svygr`i' svygr`i'_1516
  rename gr`i'enr enrgr`i'_1516
  label var svygr`i'_1516 "number of grade `i' household responses in 1516"
  label var enrgr`i'_1516 "grade `i' enrollment in 1516"
}
label data "trimmed parent demographics 1516 including only survey responses and enrollment for grades 1-12"
compress
save $datadir_clean/calschls/demotrim/parent/trimparentdemo1516, replace


use $caschls_projdir/dta/demographics/parent/parentdemo1617, replace
keep cdscode svygr1 svygr2 svygr3 svygr4 svygr5 svygr6 svygr7 svygr8 svygr9 svygr10 svygr11 svygr12 ///
gr1enr gr2enr gr3enr gr4enr gr5enr gr6enr gr7enr gr8enr gr9enr gr10enr gr11enr gr12enr
foreach i of local grades {
  rename svygr`i' svygr`i'_1617
  rename gr`i'enr enrgr`i'_1617
  label var svygr`i'_1617 "number of grade `i' household responses in 1617"
  label var enrgr`i'_1617 "grade `i' enrollment in 1617"
}
label data "trimmed parent demographics 1617 including only survey responses and enrollment for grades 1-12"
compress
save $datadir_clean/calschls/demotrim/parent/trimparentdemo1617, replace


use $caschls_projdir/dta/demographics/parent/parentdemo1718, replace
keep cdscode svygr1 svygr2 svygr3 svygr4 svygr5 svygr6 svygr7 svygr8 svygr9 svygr10 svygr11 svygr12 ///
gr1enr gr2enr gr3enr gr4enr gr5enr gr6enr gr7enr gr8enr gr9enr gr10enr gr11enr gr12enr
foreach i of local grades {
  rename svygr`i' svygr`i'_1718
  rename gr`i'enr enrgr`i'_1718
  label var svygr`i'_1718 "number of grade `i' household responses in 1718"
  label var enrgr`i'_1718 "grade `i' enrollment in 1718"
}
label data "trimmed parent demographics 1718 including only survey responses and enrollment for grades 1-12"
compress
save $datadir_clean/calschls/demotrim/parent/trimparentdemo1718, replace


use $caschls_projdir/dta/demographics/parent/parentdemo1819, replace
keep cdscode svygr1 svygr2 svygr3 svygr4 svygr5 svygr6 svygr7 svygr8 svygr9 svygr10 svygr11 svygr12 ///
gr1enr gr2enr gr3enr gr4enr gr5enr gr6enr gr7enr gr8enr gr9enr gr10enr gr11enr gr12enr
foreach i of local grades {
  rename svygr`i' svygr`i'_1819
  rename gr`i'enr enrgr`i'_1819
  label var svygr`i'_1819 "number of grade `i' household responses in 1819"
  label var enrgr`i'_1819 "grade `i' enrollment in 1819"
}
label data "trimmed parent demographics 1819 including only survey responses and enrollment for grades 1-12"
compress
save $datadir_clean/calschls/demotrim/parent/trimparentdemo1819, replace

log close
translate $logdir/trimparentdemo.smcl $logdir/trimparentdemo.log, replace 
