/*------------------------------------------------------------------------------
do/share/demographics/pooledsecanalysis.do — Phase 1a §3.3 step 10 batch 10b relocation
================================================================================

PURPOSE
    diagnostic: pooled secondary CalSCHLS analysis — produces diagnostic graphs.

INVOKED FROM
    `do/main.do' Phase 6 (PAPER OUTPUTS) under flag `do_paper_outputs'.
    Diagnostic — not paper-shipping; produces .png graphs under
    $output_dir/graph/pooleddiagnostics/.

INPUTS (verified via grep on file body)
    $caschls_projdir/dta/demographics/pooled/pooledsecdiagnostics  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $logdir/share/demographics/pooledsecanalysis.smcl (via log using)
    $logdir/share/demographics/pooledsecanalysis.smcl + $logdir/share/demographics/pooledsecanalysis.log (translate)
    $output_dir/graph/pooleddiagnostics/secondary/pooledasianrr.png
    $output_dir/graph/pooleddiagnostics/secondary/pooledblackrr.png
    $output_dir/graph/pooleddiagnostics/secondary/pooledfemalerr.png
    $output_dir/graph/pooleddiagnostics/secondary/pooledhispanicrr.png
    $output_dir/graph/pooleddiagnostics/secondary/pooledrr.png
    $output_dir/graph/pooleddiagnostics/secondary/pooledwhiterr.png

RELOCATION (per plan v3 §3.3 step 10 batch 10b, applied 2026-05-08)
    Source: caschls/do/share/demographics/pooledsecanalysis.do
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
    Sister files (this batch): elemcoverageanalysis.do, parentcoverageanalysis.do, seccoverageanalysis.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
***************** create graphs for secondary pooled diagnostics *********************
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************
cap log close _all
clear
set more off
* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/share"
cap mkdir "$logdir/share/demographics"
cap mkdir "$output_dir"
cap mkdir "$output_dir/graph"
cap mkdir "$output_dir/graph/pooleddiagnostics"
cap mkdir "$output_dir/graph/pooleddiagnostics/elementary"
cap mkdir "$output_dir/graph/pooleddiagnostics/parent"
cap mkdir "$output_dir/graph/pooleddiagnostics/secondary"


log using "$logdir/share/demographics/pooledsecanalysis.smcl", replace text

use $caschls_projdir/dta/demographics/pooled/pooledsecdiagnostics, replace

grstyle init  //initializes the grstyle package
grstyle set plain   //set graph background to plain
grstyle set color Set1, opacity(50): histogram //use Set1 color palette (red and blue) for histogram bars fill color and set opacity to 50%
grstyle set color white, opacity(25): histogram_line //set color white and opacity 25% for histogram bar outline color

//create and export frequency histogram for pooled response rate (pooled across grades 9 and 11 and all 5 years)
histogram pooledrr, freq
graph export $output_dir/graph/pooleddiagnostics/secondary/pooledrr.png, replace

//create and export frequency histogram for pooled female response rate
histogram pooledfemalerr, freq
graph export $output_dir/graph/pooleddiagnostics/secondary/pooledfemalerr.png, replace

//create and export frequency histograms for pooled response rates for 4 races/ethnicities

//generate checks to see if survey responses are more than enrollment
gen checkhispanic = 0
replace checkhispanic = 1 if svyhispanictotal > enrhispanictotal
gen checkasian = 0
replace checkasian = 1 if svyasiantotal > enrasiantotal
gen checkblack = 0
replace checkblack = 1 if svyblacktotal > enrblacktotal
gen checkwhite = 0
replace checkwhite = 1 if svywhitetotal > enrwhitetotal

drop if checkhispanic == 1
drop if checkasian == 1
drop if checkblack == 1
drop if checkwhite == 1

histogram pooledhispanicrr, freq
graph export $output_dir/graph/pooleddiagnostics/secondary/pooledhispanicrr.png, replace

histogram pooledasianrr, freq
graph export $output_dir/graph/pooleddiagnostics/secondary/pooledasianrr.png, replace

histogram pooledblackrr, freq
graph export $output_dir/graph/pooleddiagnostics/secondary/pooledblackrr.png, replace

histogram pooledwhiterr, freq
graph export $output_dir/graph/pooleddiagnostics/secondary/pooledwhiterr.png, replace




grstyle clear // sets off grstyle


log close
translate $logdir/share/demographics/pooledsecanalysis.smcl $logdir/share/demographics/pooledsecanalysis.log, replace 
