/*------------------------------------------------------------------------------
do/share/demographics/parentcoverageanalysis.do — Phase 1a §3.3 step 10 batch 10b relocation
================================================================================

PURPOSE
    diagnostic: parent CalSCHLS coverage analysis — produces diagnostic graphs.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Diagnostic — not paper-shipping; produces .png graphs under
    $output_dir/graph/pooleddiagnostics/.

INPUTS (verified via grep on file body)
    $caschls_projdir/dta/demographics/analysis/parent/parentdemo`year'analysis  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/demographics/parentcoverageanalysis.smcl (via log using)
    $logdir/share/demographics/parentcoverageanalysis.smcl + $logdir/share/demographics/parentcoverageanalysis.log (translate)
    $output_dir/graph/svycoverage/parentcoverage/parent`year'/gr`i'resprate.png

RELOCATION (per plan v3 §3.3 step 10 batch 10b, applied 2026-05-08)
    Source: caschls/do/share/demographics/parentcoverageanalysis.do
    Path repointing applied (script-based methodology):
      $projdir/log/share/demographics/<x> -> $logdir/<x>  (CANONICAL)
      $projdir/dta/demographics/<x>       -> $caschls_projdir/dta/demographics/<x>  (LEGACY-static raw demographics)
      $projdir/out/graph/<x>              -> $output_dir/graph/<x>  (CANONICAL intermediate diagnostic; not paper-shipping)
      translate (single-line ABS form)  -> $logdir/<x>  (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag; `name(...)' suffix preserved if present.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10b
    Sister files (this batch): elemcoverageanalysis.do, pooledsecanalysis.do, seccoverageanalysis.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
******************* create graphs for parent demographics **********************
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************

/* this do file creates graphs by comparing survey sample against enrollment data
for parent demographics datasets to investigate the survey sample representativrness  */
cap log close _all
clear
set more off
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
cap mkdir "$logdir/share/demographics"
cap mkdir "$output_dir"
cap mkdir "$output_dir/graph"
cap mkdir "$output_dir/graph/svycoverage"
cap mkdir "$output_dir/graph/svycoverage/parentcoverage"


log using "$logdir/share/demographics/parentcoverageanalysis.smcl", replace text

grstyle init  //initializes the grstyle package
grstyle set plain   //set graph background to plain
grstyle set color Set1, opacity(50): histogram //use Set1 color palette (red and blue) for histogram bars fill color and set opacity to 50%
grstyle set color white, opacity(25): histogram_line //set color white and opacity 25% for histogram bar outline color

local years `" "1415" "1516" "1617" "1718" "1819" "' //local macro for elementary dataset years

foreach year of local years {
  use $caschls_projdir/dta/demographics/analysis/parent/parentdemo`year'analysis, clear

  local grades `" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "' //local macro for kids' grades in parent survey, kindergarten enrollment not included so omit
  foreach i of local grades {
    /* create and export frequency histograms for distribution of response rate in grade i */
    histogram svygr`i'resprate, freq
    graph export $output_dir/graph/svycoverage/parentcoverage/parent`year'/gr`i'resprate.png, replace
  }
}

grstyle clear // sets off grstyle

log close
translate $logdir/share/demographics/parentcoverageanalysis.smcl $logdir/share/demographics/parentcoverageanalysis.log, replace 
