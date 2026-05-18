/*------------------------------------------------------------------------------
do/share/demographics/elemcoverageanalysis.do — Phase 1a §3.3 step 10 batch 10b relocation
================================================================================

PURPOSE
    diagnostic: elementary CalSCHLS coverage analysis (response rates by subgroup) — produces diagnostic graphs.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Diagnostic — not paper-shipping; produces .png graphs under
    $output_dir/graph/pooleddiagnostics/.

INPUTS (verified via grep on file body)
    $caschls_projdir/dta/demographics/analysis/elementary/elemdemo`i'analysis  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/demographics/elemcoverageanalysis.smcl (via log using)
    $logdir/share/demographics/elemcoverageanalysis.smcl + $logdir/share/demographics/elemcoverageanalysis.log (translate)
    $output_dir/graph/svycoverage/elemcoverage/elem`i'/gr`j'femaledif.png
    $output_dir/graph/svycoverage/elemcoverage/elem`i'/gr`j'maledif.png
    $output_dir/graph/svycoverage/elemcoverage/elem`i'/gr`j'resprate.png

RELOCATION (per plan v3 §3.3 step 10 batch 10b, applied 2026-05-08)
    Source: caschls/do/share/demographics/elemcoverageanalysis.do
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
    Sister files (this batch): parentcoverageanalysis.do, pooledsecanalysis.do, seccoverageanalysis.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
***************** create graphs for elementary demographics *********************
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************

/* this do file creates graphs by comparing survey sample against enrollment data
for elementary demographics datasets to investigate the survey sample representativrness  */

//install grstyle package for easy graphic settings and palettes & colrspace package for color palette settings
//ssc instasll grstyle
//ssc install palettes
//ssc install colrspace

//grstyle documentation: http://repec.sowi.unibe.ch/stata/grstyle/help-grstyle-set.html
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
cap mkdir "$output_dir/graph/svycoverage/elemcoverage"


log using "$logdir/share/demographics/elemcoverageanalysis.smcl", replace text name(elemcoverageanalysis)

local years `" "1415" "1516" "1617" "1718" "1819" "' //local macro for elementary dataset years

grstyle init  //initializes the grstyle package
grstyle set plain   //set graph background to plain
grstyle set color Set1, opacity(50): histogram //use Set1 color palette (red and blue) for histogram bars fill color and set opacity to 50%
grstyle set color white, opacity(25): histogram_line //set color white and opacity 25% for histogram bar outline color

foreach i of local years {
  use $caschls_projdir/dta/demographics/analysis/elementary/elemdemo`i'analysis, clear

  local elemgrades 3 4 5 6 //create a local macro for the grades in the elementary survey data
  foreach j of local elemgrades {

    /* create and export frequency histograms for distribution of response rate in grade i */
    histogram svygr`j'resprate, freq
    graph export $output_dir/graph/svycoverage/elemcoverage/elem`i'/gr`j'resprate.png, replace

    /* create and export frequency histograms for distribution of male and female percentage difference between survey sample and enrollment data */
    histogram femalegr`j'dif, freq
    graph export $output_dir/graph/svycoverage/elemcoverage/elem`i'/gr`j'femaledif.png,replace
    histogram malegr`j'dif, freq
    graph export $output_dir/graph/svycoverage/elemcoverage/elem`i'/gr`j'maledif.png, replace
  }


}

grstyle clear // sets off grstyle


log close elemcoverageanalysis
translate $logdir/share/demographics/elemcoverageanalysis.smcl $logdir/share/demographics/elemcoverageanalysis.log, replace 
