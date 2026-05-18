/*------------------------------------------------------------------------------
do/data_prep/qoiclean/staff/staffqoiclean1617_1516.do — Phase 1a §3.3 step 9 batch 9e relocation
================================================================================

PURPOSE
    QOI (Question Of Interest) cleaning for staff CalSCHLS, year 1617_1516.
    Cleans Likert survey items + computes school-level pooled means.
    Year-by-year worker file (1 of 10 sister files in this batch).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Chain
    consumer: reads renamed CalSCHLS yearly data produced by
    renamedata.do (batch 9d) earlier in main.do invocation order.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/staff/staff`year'  (CHAIN read across {1516,1617}; from renamedata batch 9d)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/qoiclean/staff/staffqoiclean`year'
    $logdir/data_prep/qoiclean/staff/staffqoiclean1617_1516.smcl (via log using)
    $logdir/data_prep/qoiclean/staff/staffqoiclean1617_1516.smcl + $logdir/data_prep/qoiclean/staff/staffqoiclean1617_1516.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9e, applied 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/qoiclean/staff/staffqoiclean1617_1516.do
    Path repointing applied (script-based methodology):
      $projdir/log/build/buildanalysisdata/qoiclean/<sub>/<x>.smcl
        -> $logdir/<x>.smcl  (CANONICAL — flattened from nested predecessor structure)
      $projdir/dta/buildanalysisdata/qoiclean/<sub>/<x>
        -> $datadir_clean/calschls/qoiclean/<sub>/<x>  (CANONICAL chain output)
      $clndtadir/<sub>/<x> (read) -> $datadir_clean/calschls/<sub>/<x>
        (CHAIN read; produced by renamedata batch 9d in same Stata session)
      translate (single-line ABS form) -> $logdir/<x> (CANONICAL)

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9e (final batch of Step 9)
    Sister files (this batch): 9 other qoiclean files (parent×4, secondary×3, staff×3)

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* clean staff 1617 survey questions of interest and generate analysis vars
such as pct disagree/agree etc. */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************
cap log close _all
clear all
set more off
set varabbrev off, perm //set variable abbreviation permanently off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/qoiclean"
cap mkdir "$logdir/data_prep/qoiclean/staff"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/calschls"
cap mkdir "$datadir_clean/calschls/qoiclean"
cap mkdir "$datadir_clean/calschls/qoiclean/staff"

log using "$logdir/data_prep/qoiclean/staff/staffqoiclean1617_1516.smcl", replace text

/* the code for cleaning 1516 and 1617 is exactly the same, so use the same code to clean them */
local years `" "1516" "1617" "'

foreach year of local years {
  use $datadir_clean/calschls/staff/staff`year', clear

  /* Note: 1617 dataset does not have qoi 24 and 64
  The qoi in this dataset are qoi 10 20 41 44 87 98 103-105 109 111 112 128*/

  keep cdscode q10 q20 q42 q72 q113 q66 q44 q45 q46 q50 q52 q53 hpdcs13 //keep questions of interest

  //delete all value labels not associated with variables
  labdu , delete
  //rename questions of interest using question numbers in 1819 as standard
  /* rename the later questions to avoid var name conflict */
  rename q44 q103
  elabel rename q44 q103
  rename q45 q104
  elabel rename q45 q104
  rename q46 q105
  elabel rename q46 q105
  rename q50 q109
  elabel rename q50 q109
  rename q52 q111
  elabel rename q52 q111
  rename q53 q112
  elabel rename q53 q112
  rename hpdcs13 q128
  elabel rename hpdcs13 q128

  rename q42 q41
  elabel rename q42 q41
  rename q72 q44
  elabel rename q72 q44
  rename q113 q87
  elabel rename q113 q87
  rename q66 q98
  elabel rename q66 q98

  /* Note: 1617 dataset does not have qoi 24 and 64 */
  foreach i of numlist 10 20 41 44 87 98 103/105 109 111 112 128 {
    rename q`i' qoi`i'
    elabel rename q`i' qoi`i' //rename the value labels to be consistent with var name change
  }

  /* count the total number of responses in each school */
  sort cdscode
  by cdscode: gen totalresp = _N
  label var totalresp "total number of responses at each school including missing"



  ***************************** clean qoi 10 20 44 87 ****************************
  /* value labels for qoi 10 20 41 44 87:
  1 strongly agree
  2 agree
  3 disagree
  4 strongly disagree
  5 not applicable

  value label for qoi41 in 1617 and 1516 is different from 1819 and 1718, but we can treat them equivalently:
  1 nearly all adults
  2 most adults
  3 some adults
  4 few adults
  5 almost none
  Here treat 1 and 2 as agree, 3 as not applicable, and 4-5 as disagree

  recode:
  -2 strongly disagree
  -1 disagree
  0 not applicable
  1 agree
  2 strongly agree
  */


  /* recode qoi 10 20 44 87 */
  foreach i of numlist 10 20 44 87 {
    gen qoi`i'temp =.
    replace qoi`i'temp = -2 if qoi`i' == 4
    replace qoi`i'temp = -1 if qoi`i' == 3
    replace qoi`i'temp =  0 if qoi`i' == 5
    replace qoi`i'temp =  1 if qoi`i' == 2
    replace qoi`i'temp =  2 if qoi`i' == 1

    drop qoi`i'
    rename qoi`i'temp qoi`i'
  }


  /* recode qoi 41 in 1617 */
  gen qoi41temp = .
  replace qoi41temp = 3 - qoi41

  drop qoi41
  rename qoi41temp qoi41


  /* generate dummies for each response option */
  foreach i of numlist 10 20 41 44 87 {
    gen stragree`i' = 0
    replace stragree`i' = 1 if qoi`i' == 2

    gen agree`i' = 0
    replace agree`i' = 1 if qoi`i' == 1

    gen disagree`i' = 0
    replace disagree`i' = 1 if qoi`i' == -1

    gen strdisagree`i' = 0
    replace strdisagree`i' = 1 if qoi`i' == -2

    gen neither`i' = 0
    replace neither`i' = 1 if qoi`i' == 0

    gen missing`i' = 0
    replace missing`i' = 1 if missing(qoi`i')
  }


/* Note: include qoi 41 with the rest in creating statistics for agree/disagree after recoding of values
  /<x> note: mean of qoi41 is not comparable to later years <x>
  gen all41 = 0
  replace all41 = 1 if qoi41 == 1

  gen most41 = 0
  replace most41 = 1 if qoi41 == 2

  gen some41 = 0
  replace some41 = 1 if qoi41 == 3

  gen few41 = 0
  replace few41 = 1 if qoi41 == 4

  gen none41 = 0
  replace none41 = 1 if qoi41 == 5

  gen missing41 = 0
  replace missing41 = 1 if missing(qoi41)
  */




  ******************************* clean qoi128 ***********************************
  /* change the values for each response option to bring it in line with above qois
  and make it possible to compare averages with previous qois */
  /* original value label for qoi128:
  1 strongly agree
  2 agree
  3 neither agree nor disagree
  4 disagree
  5 strongly disagree

  recode:
  -2 strongly disagree
  -1 disagree
  0 neither
  1 agree
  2 strongly agree */
  gen qoi128temp =.
  replace qoi128temp = 3 - qoi128

  drop qoi128
  rename qoi128temp qoi128

  label drop qoi128 //delete the original qoi128 value label
  label define qoi128 2 "Strongly agree" 1 "Agree" -1 "Disagree" -2 "Strongly disagree" 0 "Neither agree nor disagree"
  label values qoi128 qoi128

  /* generate dummies for each response option in qoi128 */
  gen stragree128 = 0
  replace stragree128 = 1 if qoi128 == 2

  gen agree128 = 0
  replace agree128 = 1 if qoi128 == 1

  gen disagree128 = 0
  replace disagree128 = 1 if qoi128 == -1

  gen strdisagree128 = 0
  replace strdisagree128 = 1 if qoi128 == -2

  gen neither128 = 0
  replace neither128 = 1 if qoi128 == 0

  gen missing128 = 0
  replace missing128 = 1 if missing(qoi128)


  ****************************** clean qoi 98 ************************************
  /* value lables for qoi 98:
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


  ***************************clean qoi 103-105 109 111 112************************
  /* value labels for qoi 103-105 109 111 112:
  1 yes
  2 no
  3 not applicable

  recode:
  1 no
  0 not applicable
  -1 yes
  This is because no means don't need more support so it's good
  yes is bad
  */

  /* recode qoi 103-105 109 111 112 */
  foreach i of numlist 103/105 109 111 112 {
    replace qoi`i' = -1 if qoi`i' == 1
    replace qoi`i' =  0 if qoi`i' == 3
    replace qoi`i' =  1 if qoi`i' == 2
  }

  foreach i of numlist 103/105 109 111 112 {
    gen yes`i' = 0
    replace yes`i' = 1 if qoi`i' == -1

    gen no`i' = 0
    replace no`i' = 1 if qoi`i' == 1

    gen notapp`i' = 0
    replace notapp`i' = 1 if qoi`i' == 0

    gen missing`i' = 0
    replace missing`i' = 1 if missing(qoi`i')
  }



  /* collapse the dataset, resulting dataset has mean for each qoi, total number of responses, and number of responses for each option in each question */
  collapse (mean) qoi* totalresp (sum) stragree* agree* disagree* strdisagree* neither* insig98 mild98 moderate98 severe98 yes* no* missing*, by(cdscode)
  /* NOTE: no* includes notapp* and none*, including both in collapse will case name conflict error. This literally took me an hour to debug. -__-*/


  ************************ relabel all the vars **********************************
  foreach i of numlist 10 20 41 44 87 98 103/105 109 111 112 128 {
    label var qoi`i' "mean of qoi`i'"
  }

  label var totalresp "total number of responses in the school including missing"

  /* rename the qoi vars to reflect they are now averages */
  rename qoi* qoi*mean

  /* label vars for the number of response for each option */
  foreach i of numlist 10 20 41 44 87 98 103/105 109 111 112 128 {
    label var missing`i' "number of missing responses for qoi`i'"
  }

  /* label the response options for 10 20 44 87  */
  foreach i of numlist 10 20 44 87 128{
    label var strdisagree`i' "number of people choosing strongly disagree for qoi`i'"
    label var disagree`i' "number of people choosing disagree for qoi`i'"
    label var agree`i' "number of people choosing agree for qoi`i'"
    label var stragree`i' "number of people choosing strongly agree for qoi`i'"
    label var neither`i' "number of people choosing not applicable for qoi`i'"
  }
/*
  /<x> label the response options for qoi41 <x>
  label var all41 "number of people choosing nearly all adults for qoi41"
  label var most41 "number of people choosing most adults for qoi41"
  label var some41 "number of people choosing some adults for qoi41"
  label var few41 "number of people choosing few adults for qoi41"
  label var none41 "number of people choosing almost none for qoi41"

  /<x> label the response options for 128  <x>
  foreach i of numlist 128 {
    label var strdisagree`i' "number of people choosing strongly disagree for qoi`i'"
    label var disagree`i' "number of people choosing disagree for qoi`i'"
    label var agree`i' "number of people choosing agree for qoi`i'"
    label var stragree`i' "number of people choosing strongly agree for qoi`i'"
    label var neither`i' "number of people choosing neither agree nor disagree for qoi`i'"
  } */

  /* label the response options for qoi98 */
  label var insig98 "number of people choosing insignificant problem for qoi98"
  label var mild98 "number of people choosing mild problem for qoi98"
  label var moderate98 "number of people choosing moderate problem for qoi98"
  label var severe98 "number of people choosing severe problem for qoi98"

  /* label the response options for qoi 103-105 109 111 112 */
  foreach i of numlist 103/105 109 111 112 {
    label var yes`i' "number of people choosing yes for qoi`i'"
    label var no`i' "number of people choosing no for qoi`i'"
    label var notapp`i' "number of people choosing not applicable for qoi`i'"
  }


  ********************* generate percentage agree/disagree etc *******************
  /* first, generate the net total responses for each question excluding missing */
  foreach i of numlist 10 20 41 44 87 98 103/105 109 111 112 128 {
    gen nettotalresp`i' = totalresp - missing`i'
    label var nettotalresp`i' "net total responses for qoi`i' excluding missing "
  }

  /* generate percentage agree/disagree for qoi 10 20 44 87 */
  foreach i of numlist 10 20 41 44 87 128 {
    gen pctdisagree`i' = (strdisagree`i' + disagree`i')/nettotalresp`i'
    label var pctdisagree`i' "percent strongly disagree or disagree in qoi`i'"
    gen pctagree`i' = (stragree`i' + agree`i')/nettotalresp`i'
    label var pctagree`i' "percent strongly agree or agree in qoi`i'"
    gen pctneither`i' = neither`i'/nettotalresp`i'
    label var pctneither`i' "percent not applicable in qoi`i'"
  }

/*
  /<x> Note: treat all and most as agree, some few and none as disagree in qoi41 <x>
  gen pctagree41 = (all41 + most41)/nettotalresp41
  label var pctagree41 "percent all or most adults in qoi41, equivlent to agree"
  gen pctdisagree41 = (some41 + few41 + none41)/nettotalresp41
  label var pctdisagree41 "percent some, few, or none in qoi41, equivalent to disagree" */
/*
  /<x> generate percentage agree/disagree for qoi 128 <x>
  foreach i of numlist 128 {
    gen pctdisagree`i' = (strdisagree`i' + disagree`i')/nettotalresp`i'
    label var pctdisagree`i' "percent strongly disagree or disagree in qoi`i'"
    gen pctagree`i' = (stragree`i' + agree`i')/nettotalresp`i'
    label var pctagree`i' "percent strongly agree or agree in qoi`i'"
    gen pctneither`i' = neither`i'/nettotalresp`i'
    label var pctneither`i' "percent not applicable in qoi`i'"
  } */

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
    gen pctnotapp`i' = notapp`i'/nettotalresp`i'
    label var pctnotapp`i' "percent not applicable in qoi`i'"
  }

  /* generate a year var to prepare for constructing a panel */
  gen year = `year'

  label data "cleaned staff `year' survey questions of interest with percent disagree/agree etc."
  compress
  save $datadir_clean/calschls/qoiclean/staff/staffqoiclean`year', replace

}


log close
translate $logdir/data_prep/qoiclean/staff/staffqoiclean1617_1516.smcl $logdir/data_prep/qoiclean/staff/staffqoiclean1617_1516.log, replace 
