/*------------------------------------------------------------------------------
do/share/demographics/seccoverageanalysis.do — Phase 1a §3.3 step 10 batch 10b relocation
================================================================================

PURPOSE
    diagnostic: secondary CalSCHLS coverage analysis (response rates by subgroup) — produces diagnostic graphs.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Diagnostic — not paper-shipping; produces .png graphs under
    $output_dir/graph/pooleddiagnostics/.

INPUTS (verified via grep on file body)
    $caschls_projdir/dta/demographics/analysis/secondary/secdemo`year'analysis  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/seccoverageanalysis.smcl (via log using)
    $logdir/seccoverageanalysis.smcl + $logdir/seccoverageanalysis.log (translate)
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/asiangr`i'dif.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/blackgr`i'dif.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/femalegr`i'dif.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/gr`i'resprate.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/hispanicgr`i'dif.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/malegr`i'dif.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/mixedgr`i'dif.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/nativegr`i'dif.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/pacificgr`i'dif.png
    $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/whitegr`i'dif.png

RELOCATION (per plan v3 §3.3 step 10 batch 10b, applied 2026-05-08)
    Source: caschls/do/share/demographics/seccoverageanalysis.do
    Path repointing applied (script-based methodology):
      $projdir/log/share/demographics/* -> $logdir/*  (CANONICAL)
      $projdir/dta/demographics/*       -> $caschls_projdir/dta/demographics/*  (LEGACY-static raw demographics)
      $projdir/out/graph/*              -> $output_dir/graph/*  (CANONICAL intermediate diagnostic; not paper-shipping)
      translate (single-line ABS form)  -> $logdir/*  (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag; `name(...)' suffix preserved if present.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 10 batch 10b
    Sister files (this batch): elemcoverageanalysis.do, parentcoverageanalysis.do, pooledsecanalysis.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
***************** create graphs for secondary demographics *********************
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************

/* this do file creates graphs by comparing survey sample against enrollment data
for secondary demographics datasets to investigate the survey sample representativrness  */
cap log close _all
clear
set more off
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$output_dir"
cap mkdir "$output_dir/graph"
cap mkdir "$output_dir/graph/svycoverage"
cap mkdir "$output_dir/graph/svycoverage/seccoverage"


log using "$logdir/seccoverageanalysis.smcl", replace text

local years `" "1415" "1516" "1617" "1718" "1819" "' //local macro for elementary dataset years

grstyle init  //initializes the grstyle package
grstyle set plain   //set graph background to plain
grstyle set color Set1, opacity(50): histogram //use Set1 color palette (red and blue) for histogram bars fill color and set opacity to 50%
grstyle set color white, opacity(25): histogram_line //set color white and opacity 25% for histogram bar outline color

foreach year of local years {
  use $caschls_projdir/dta/demographics/analysis/secondary/secdemo`year'analysis, clear

  local secgrades `" "6" "7" "8" "9" "10" "11" "12" "' //generate a local macro for grades in the secondary datasets, excluding non traditional students for simplicity
  foreach i of local secgrades {
    /* create and export frequency histograms for distribution of response rate in grade i */
    histogram svygr`i'resprate, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/gr`i'resprate.png, replace

    /* create and export frequency histograms for distribution of male and female percentage difference between survey sample and enrollment data */
    histogram femalegr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/femalegr`i'dif.png, replace
    histogram malegr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/malegr`i'dif.png, replace

    /* create and export frequency histograms for distributions of percentage differences for each ethnicity between survey sample and enrollment data */
    histogram hispanicgr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/hispanicgr`i'dif.png, replace
    histogram nativegr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/nativegr`i'dif.png, replace
    histogram asiangr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/asiangr`i'dif.png, replace
    histogram blackgr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/blackgr`i'dif.png, replace
    histogram pacificgr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/pacificgr`i'dif.png, replace
    histogram whitegr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/whitegr`i'dif.png, replace
    histogram mixedgr`i'dif, freq
    graph export $output_dir/graph/svycoverage/seccoverage/sec`year'/gr`i'/mixedgr`i'dif.png, replace
  }

}

grstyle clear // sets off grstyle

log close
translate $logdir/seccoverageanalysis.smcl $logdir/seccoverageanalysis.log, replace 
