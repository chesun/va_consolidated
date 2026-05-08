/*------------------------------------------------------------------------------
do/data_prep/qoiclean/staff/staffqoiclean1819_1718.do — Phase 1a §3.3 step 9 batch 9e relocation
================================================================================

PURPOSE
    QOI (Question Of Interest) cleaning for staff CalSCHLS, year 1819_1718.
    Cleans Likert survey items + computes school-level pooled means.
    Year-by-year worker file (1 of 10 sister files in this batch).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Chain
    consumer: reads renamed CalSCHLS yearly data produced by
    renamedata.do (batch 9d) earlier in main.do invocation order.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/staff/staff`year'  (CHAIN read across {1718,1819}; from renamedata batch 9d)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/qoiclean/staff/staffqoiclean`year'
    $logdir/staffqoiclean1819_1718.smcl (via log using)
    $logdir/staffqoiclean1819_1718.smcl + $logdir/staffqoiclean1819_1718.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9e, applied 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/qoiclean/staff/staffqoiclean1819_1718.do
    Path repointing applied (script-based methodology):
      $projdir/log/build/buildanalysisdata/qoiclean/<sub>/<x>.smcl
        -> $logdir/<x>.smcl  (CANONICAL — flattened from nested predecessor structure)
      $projdir/dta/buildanalysisdata/qoiclean/<sub>/<x>
        -> $datadir_clean/calschls/qoiclean/<sub>/<x>  (CANONICAL chain output)
      $clndtadir/<sub>/<x> (read) -> $datadir_clean/calschls/<sub>/<x>
        (CHAIN read; produced by renamedata batch 9d in same Stata session)
      translate (single-line ABS form) -> $logdir/* (CANONICAL)

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9e (final batch of Step 9)
    Sister files (this batch): 9 other qoiclean files (parent×4, secondary×3, staff×3)

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* clean staff 1819 and 1718 survey questions of interest and generate analysis vars
such as pct disagree/agree etc. */
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
cap mkdir "$datadir_clean/calschls/qoiclean"
cap mkdir "$datadir_clean/calschls/qoiclean/staff"

log using "$logdir/staffqoiclean1819_1718.smcl", replace text

/* the code for cleaning 1819 and 1718 is exactly the same, so use loop */
local years `" "1718" "1819" "'

foreach year of local years {
  use $datadir_clean/calschls/staff/staff`year', clear
  keep cdscode q10 q20 q24 q41 q44 q64 q87 q98 q103 q104 q105 q109 q111 q112 q128 //keep only questions of interest
  //rename the q  uestions of interest using question numbers in 1819 as standard
  foreach i of numlist 10 20 24 41 44 64 87 98 103/105 109 111 112 128 {
    rename q`i' qoi`i'
  }
  elabel rename (q*) (qoi*) //rename the value labels to reflect the variable name change
  labdu , delete //delete all value labels not associated with variables


  /* count the total number of responses in each school */
  sort cdscode
  by cdscode: gen totalresp = _N
  label var totalresp "total number of responses at each school including missing"

  /* clean qoi 10 20 24 41 44 64 87 128 as they have the same response options */
  /* value labels qoi 10, 20, 24, 41, 44, 64, 87, 128:
  1 strongly agree
  2 agree
  3 disagree
  4 strongly disagree

  recode:
  -2 strongly disagree
  -1 disagree
  1 agree
  2 strongly agree
  */


  /* recode qoi 10, 20, 24, 41, 44, 64, 87, 128 */
  foreach i of numlist 10 20 24 41 44 64 87 128 {
    gen qoi`i'temp =.
    replace qoi`i'temp = -2 if qoi`i' == 4
    replace qoi`i'temp = -1 if qoi`i' == 3
    replace qoi`i'temp =  1 if qoi`i' == 2
    replace qoi`i'temp =  2 if qoi`i' == 1

    drop qoi`i'
    rename qoi`i'temp qoi`i'
  }

  **** generate dummies for each response option for qoi 10 20 24 41 44 64 87 ****
  foreach i of numlist 10 20 24 41 44 64 87 128 {
    gen stragree`i' = 0
    replace stragree`i' = 1 if qoi`i' == 2

    gen agree`i' = 0
    replace agree`i' = 1 if qoi`i' == 1

    gen disagree`i' = 0
    replace disagree`i' = 1 if qoi`i' == -1

    gen strdisagree`i' = 0
    replace strdisagree`i' = 1 if qoi`i' == -2

    gen missing`i' = 0
    replace missing`i' = 1 if missing(qoi`i')
  }

  ****************************** clean qoi 98 **********************************
  /* value labels for qoi 98:
  1 insignificant problem
  2 mild problem
  3 moderate problem
  4 severe problem

  recode:
  -3 severe problem
  -2 moderate problem
  -1 mild problem
  1 insignificant problem
  */

  /* recode qoi 98 */
  gen qoi98temp = .
  replace qoi98temp = -3 if qoi98 == 4
  replace qoi98temp = -2 if qoi98 == 3
  replace qoi98temp = -1 if qoi98 == 2
  replace qoi98temp =  1 if qoi98 == 1

  drop qoi98
  rename qoi98temp qoi98


  gen insig98 = 0
  replace insig98 = 1 if qoi98 == 1

  gen mild98 = 0
  replace mild98 = 1 if qoi98 == -1

  gen moderate98 = 0
  replace moderate98 = 1 if qoi98 == -2

  gen severe98 = 0
  replace severe98 = 1 if qoi98 == -3

  gen missing98 = 0
  replace missing98 = 1 if missing(qoi98)

  *************************clean qoi 103-105 109 111 112************************
  /* value labels for qoi 103-105 109 111 112:
  1 yes
  2 no

  recode:
  1 no
  -1 yes
  This is because no means don't need more support so it's good
  yes is bad
  */

  /* recode qoi 103-105 109 111 112 */
  foreach i of numlist 103/105 109 111 112 {
    replace qoi`i' = -1 if qoi`i' == 1
    replace qoi`i' =  1 if qoi`i' == 2
  }

  foreach i of numlist 103/105 109 111 112 {
    gen yes`i' = 0
    replace yes`i' = 1 if qoi`i' == -1

    gen no`i' = 0
    replace no`i' = 1 if qoi`i' == 1

    gen missing`i' = 0
    replace missing`i' = 1 if missing(qoi`i')
  }

  /* collapse the dataset, resulting dataset has mean for each qoi, total number of responses, and number of responses for each option in each question */
  collapse (mean) qoi* totalresp (sum) stragree* agree* disagree* strdisagree* insig98 mild98 moderate98 severe98 yes* no* missing*, by(cdscode)


  ************************ relabel all the vars **********************************
  foreach i of numlist 10 20 24 41 44 64 87 98 103/105 109 111 112 128 {
    label var qoi`i' "mean of qoi`i'"
  }

  label var totalresp "totoal number of responses in the school including missing"

  /* rename the qoi vars to reflect they are now averages */
  rename qoi* qoi*mean

  /* label vars for the number of response for each option */
  foreach i of numlist 10 20 24 41 44 64 87 98 103/105 109 111 112 128 {
    label var missing`i' "number of missing responses for qoi`i'"
  }

  foreach i of numlist 10 20 24 41 44 64 87 128 {
    label var strdisagree`i' "number of people choosing strongly disagree for qoi`i'"
    label var disagree`i' "number of people choosing disagree for qoi`i'"
    label var agree`i' "number of people choosing agree for qoi`i'"
    label var stragree`i' "number of people choosing strongly agree for qoi`i'"
  }

  label var insig98 "number of people choosing insignificant problem for qoi98"
  label var mild98 "number of people choosing mild problem for qoi98"
  label var moderate98 "number of people choosing moderate problem for qoi98"
  label var severe98 "number of people choosing severe problem for qoi98"

  foreach i of numlist 103/105 109 111 112 {
    label var yes`i' "number of people choosing yes for qoi`i'"
    label var no`i' "number of people choosing no for qoi`i'"
  }


  ********************* generate percentage agree/disagree etc *******************
  /* first, generate the net total responses for each question excluding missing */
  foreach i of numlist 10 20 24 41 44 64 87 98 103/105 109 111 112 128 {
    gen nettotalresp`i' = totalresp - missing`i'
    label var nettotalresp`i' "net total responses for qoi`i' excluding missing "
  }

  /* generate percentage agree/disagree for qoi 10 20 24 41 44 64 87 128 */
  foreach i of numlist 10 20 24 41 44 64 87 128 {
    gen pctdisagree`i' = (strdisagree`i' + disagree`i')/nettotalresp`i'
    label var pctdisagree`i' "percent strongly disagree or disagree in qoi`i'"
    gen pctagree`i' = (stragree`i' + agree`i')/nettotalresp`i'
    label var pctagree`i' "percent strongly agree or agree in qoi`i'"
  }

  /* generate percentage small/big problem for qoi98 */
  gen pctsmallprob98 = (insig98 + mild98)/nettotalresp98
  gen pctbigprob98 = (moderate98 + severe98)/nettotalresp98
  label var pctsmallprob98 "percentage insignificant or mild problem for qoi98"
  label var pctbigprob98 "percentage moderate or severe problem for qoi98"

  /* generate percentage yes/no for qoi 103/105 109 111 112 */
  foreach i of numlist 103/105 109 111 112 {
    gen pctyes`i' = yes`i'/nettotalresp`i'
    label var pctyes`i' "percentage answering yes for qoi`i'"
    gen pctno`i' = no`i'/nettotalresp`i'
    label var pctno`i' "percentage answering no for qoi`i'"
  }

  /* generate a year var to prepare for constructing a panel */
  gen year = `year'

  label data "cleaned staff `year' survey questions of interest with percent disagree/agree etc."
  compress
  save $datadir_clean/calschls/qoiclean/staff/staffqoiclean`year', replace
}

log close
translate $logdir/staffqoiclean1819_1718.smcl $logdir/staffqoiclean1819_1718.log, replace 
