/*------------------------------------------------------------------------------
do/data_prep/qoiclean/secondary/secqoiclean1819_1718_1516.do — Phase 1a §3.3 step 9 batch 9e relocation
================================================================================

PURPOSE
    QOI (Question Of Interest) cleaning for secondary CalSCHLS, year 1819_1718_1516.
    Cleans Likert survey items + computes school-level pooled means.
    Year-by-year worker file (1 of 10 sister files in this batch).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.  Chain
    consumer: reads renamed CalSCHLS yearly data produced by
    renamedata.do (batch 9d) earlier in main.do invocation order.

INPUTS (verified via grep on file body)
    $datadir_clean/calschls/secondary/sec`year'  (CHAIN read across {1516,1718,1819}; from renamedata batch 9d)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/calschls/qoiclean/secondary/secqoiclean`year'
    $logdir/secqoiclean1819_1718_1516.smcl (via log using)
    $logdir/secqoiclean1819_1718_1516.smcl + $logdir/secqoiclean1819_1718_1516.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9e, applied 2026-05-08)
    Source: caschls/do/build/buildanalysisdata/qoiclean/secondary/secqoiclean1819_1718_1516.do
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
/* clean secondary (high school) 1819, 1718, and 1516 survey questions of interest
because their qoi numbers are exactly the same, and generate
analysis vars such as pct disagree/agree etc. */
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
cap mkdir "$datadir_clean/calschls/qoiclean/secondary"

log using "$logdir/secqoiclean1819_1718_1516.smcl", replace text

/* ssc install elabel, replace //install the elabel package for easy renaming of labels
ssc install labutil2, replace //package to help with managing value labels because stata sucks in that regard
ssc install labundef, replace //package to list value labels unused in memory */


local years `" "1516" "1718" "1819" "'

foreach year of local years {

use $datadir_clean/calschls/secondary/sec`year', clear
keep cdscode a22 a23 a24 a25 a26 a27 a28 a29 a30 a31 a32 a33 a34 a35 a36 a37 a38 a39 a40 //only keep questions of interest
//rename questions of interest using question numbers in 1819 as stasndard
foreach i of numlist 22/40 {
  rename a`i' qoi`i'
}
elabel rename (a*) (qoi*) //rename the value labels to reflect the variable name change
labdu , delete //delete all value labels not associated with variables

/* count the total number of responses in each school */
sort cdscode
by cdscode: gen totalresp = _N
label var totalresp "total number of responses at each school including missing"


*********** clean qoi 22-34 as they have the same response options *************
/* value labels qoi 22- 34:
1 strongly disagree
2 disagree
3 neither disagree nor disagree
4 agree
5 strongly agree

Recode:
-2 strongly disagree
-1 disagree
0 neutral
1 agree
2 strongly agree
*/


/* recode qoi 22-34 */
foreach i of numlist 22/34 {
  replace qoi`i' = qoi`i' - 3
}


/* generate dummies for each response option for qoi 22-34*/
foreach i of numlist 22/34 {
  gen strdisagree`i' = 0
  replace strdisagree`i' = 1 if qoi`i' == -2

  gen disagree`i' = 0
  replace disagree`i' = 1 if qoi`i' == -1

  gen neither`i' = 0
  replace neither`i' = 1 if qoi`i' == 0

  gen agree`i' = 0
  replace agree`i' = 1 if qoi`i' == 1

  gen stragree`i' = 0
  replace stragree`i' = 1 if qoi`i' == 2

  gen missing`i' = 0
  replace missing`i' = 1 if missing(qoi`i')
}

////////////////////////////////////////////////////////////////////////////////
*********************************** Aside **************************************
/* a snippet of code to check the dummies are correct and the total number for
each response option plus missing add up to the total number of responses using qoi22*/
/* by cdscode: egen check1 = total(strdisagree22)
by cdscode: egen check2 = total(disagree22)
by cdscode: egen check3 = total(neither22)
by cdscode: egen check4 = total(agree22)
by cdscode: egen check5 = total(stragree22)
by cdscode: egen check6 = total(missing22)
gen check = check1 + check2 + check3 + check4 + check5 + check6
gen checkdiscrep = totalresp - check //check if they add up to the total number of responses
tab checkdiscrep //result: all values = 0. Great success! dummies are correct and add up
drop check* //drop all the temp vars generated in this snippet  */
////////////////////////////////////////////////////////////////////////////////


*********** clean qoi 35-40 as they have the same response options *************
/* value labels for qoi 35-40
 1 not at all true
 2 a little true
 3 pretty much true
 4 very much true

 recode:
-2 not at all true
-1 a little true
1 pretty much true
2 very much true
 */

 /* recode qoi 35-40 */
 foreach i of numlist 35/40 {
   replace qoi`i' = qoi`i' - 3 if qoi`i' == 1 | qoi`i' == 2
   replace qoi`i' = qoi`i' - 2 if qoi`i' == 3 | qoi`i' == 4
 }

/* generate dummies for each response option for qoi 35-40*/
 foreach i of numlist 35/40 {
   gen nottrue`i' = 0
   replace nottrue`i' = 1 if qoi`i' == -2

   gen littletrue`i' = 0
   replace littletrue`i' = 1 if qoi`i' == -1

   gen prettytrue`i' = 0
   replace prettytrue`i' = 1 if qoi`i' == 1

   gen verytrue`i' = 0
   replace verytrue`i' = 1 if qoi`i' == 2

   gen missing`i' = 0
   replace missing`i' = 1 if missing(qoi`i')
 }

/* collapse the dataset, resulting dataset has mean for each qoi, total number of responses, and number of responses for each option in each question */
 collapse (mean) qoi* totalresp (sum) strdisagree* disagree* neither* agree* stragree* missing* nottrue* littletrue* prettytrue* verytrue*, by(cdscode)

/* a snipppet of code to confirm the collapse worked as intended, same idea as the previous check */
/* gen check = strdisagree22 + disagree22 + neither22 + agree22 + stragree22 + missing22
gen checkdiscrep = totalresp - check
tab checkdiscrep //results: all values = 0. Very nice!
drop check checkdiscrep */

************************ relabel all the vars **********************************
/* label all the vars */
label var qoi22 "Mean of Q: I feel close to people at this school"
label var qoi23 "Mean of Q: I am happy to be at this school"
label var qoi24 "Mean of Q: I feel like I am part of this school"
label var qoi25 "Mean of Q: The teachers at this school treat students fairly"
label var qoi26 "Mean of Q: I feel safe in my school"
label var qoi27 "Mean of Q: My school is usually clean and tidy"
label var qoi28 "Mean of Q: Teachers communicate with parents... expected to learn..."
label var qoi29 "Mean of Q: Parents feel welcome to participate at this school"
label var qoi30 "Mean of Q: School staff take parent concerns seriously"
label var qoi31 "Mean of Q: I try hard to make sure that I am good at my schoolwork"
label var qoi32 "Mean of Q: I try hard at school because I am interested in my work"
label var qoi33 "Mean of Q: I work hard to try to understand new things at school"
label var qoi34 "Mean of Q: I am always trying to do better in my schoolwork"

label var qoi35 "Mean of Q: There is... who really cares about me"
label var qoi36 "Mean of Q: There is... who tells me when I do a good job"
label var qoi37 "Mean of Q: There is... who notices when I’m not there"
label var qoi38 "Mean of Q: There is... who always wants me to do my best"
label var qoi39 "Mean of Q: There is... who listens to me when I have something to say"
label var qoi40 "Mean of Q: There is... who believes that I will be a success"

label var totalresp "total number of responses in the school including missing"

/* rename the qoi vars to reflect they are now averages */
rename qoi* qoi*mean

/* label vars for the number of response for each option */
foreach i of numlist 22/34 {
  label var strdisagree`i' "number of people choosing strongly disagree for qoi`i'"
  label var disagree`i' "number of people choosing disagree for qoi`i'"
  label var neither`i' "number of people choosing neither disagree or agree for qoi`i'"
  label var agree`i' "number of people choosing agree for qoi`i'"
  label var stragree`i' "number of people choosing strongly agree for qoi`i'"
  label var missing`i' "number of missing responses for qoi`i'"
}

foreach i of numlist 35/40 {
  label var nottrue`i' "number of people choosing not at all true for qoi`i'"
  label var littletrue`i' "number of people choosing a little true for qoi`i'"
  label var prettytrue`i' "number of people choosing pretty much true for qoi`i'"
  label var verytrue`i' "number of people choosing very much true for qoi`i'"
  label var missing`i' "number of missing responses for qoi`i'"
}


********************* generate percentage agree/disagree etc *******************

/* first, generate the net total responses for each question excluding missing */
foreach i of numlist 22/40 {
  gen nettotalresp`i' = totalresp - missing`i'
  label var nettotalresp`i' "net total responses for qoi`i' excluding missing "
}

/* generate pct disagree/agree for qoi 22-34 */
foreach i of numlist 22/34 {
  gen pctdisagree`i' = (strdisagree`i' + disagree`i')/nettotalresp`i'
  label var pctdisagree`i' "percent strongly disagree or disagree in qoi`i'"
  gen pctagree`i' = (stragree`i' + agree`i')/nettotalresp`i'
  label var pctagree`i' "percent strongly agree or agree in qoi`i'"
  gen pctneither`i' = neither`i'/nettotalresp`i'
  label var pctneither`i' "percent neither disagree nor agree in qoi`i'"
}

/* generate pct no true/true for qoi 35-40 */
foreach i of numlist 35/40 {
  gen pctnottrue`i' = nottrue`i'/nettotalresp`i'
  label var pctnottrue`i' "percent not true in qoi`i'"
  gen pcttrue`i' = (littletrue`i' + prettytrue`i' + verytrue`i')/nettotalresp`i'
  label var pcttrue`i' "percent a little true, pretty much true, and very much true in qoi`i'"
}



/* generate a year var to prepare for constructing a panel */
gen year = `year'


label data "cleaned secondary `year' survey questions of interest with percent disagree/agree etc."
compress
save $datadir_clean/calschls/qoiclean/secondary/secqoiclean`year', replace

}

log close
translate $logdir/secqoiclean1819_1718_1516.smcl $logdir/secqoiclean1819_1718_1516.log, replace
