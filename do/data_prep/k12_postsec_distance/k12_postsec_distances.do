/*------------------------------------------------------------------------------
do/data_prep/k12_postsec_distance/k12_postsec_distances.do — Phase 1a §3.3 step 9 batch 9c relocation
================================================================================

PURPOSE
    MAIN: build K12-postsec distance file using IPEDS HD2021 + CDE pubschls + geodist; produces $datadir_clean/k12_postsec_distance/clean/k12_postsec_{distance,mindistance}.dta.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.
    MAIN entry for batch 9c; calls `run hd2021.do' as sub-script (loads
    IPEDS HD 2021 into memory).  Does NOT call reconcile_cdscodes.do;
    that file is orphan in BOTH predecessor and consolidated pipelines
    (preserved per ADR-0021 verbatim; not invoked by anyone).

INPUTS (verified via grep on file body)
    $consolidated_dir/do/data_prep/k12_postsec_distance/hd2021.do  (sub-script via `run')
    $datadir_clean/k12_postsec_distance/clean/k12_postsec_distance  (CHAIN read; from k12_postsec_distance.dta save earlier in this same script)
    $distance_dtadir/raw/pubschls.txt  (LEGACY raw — fallback if URL fetch fails)
    https://www.cde.ca.gov/schooldirectory/report  (LEGACY external URL — primary K12 directory source)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/k12_postsec_distance/clean/k12_postsec_distance
    $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance
    $logdir/data_prep/k12_postsec_distance/k12_postsec_distances.smcl (via log using)
    $logdir/data_prep/k12_postsec_distance/k12_postsec_distances.smcl + $logdir/data_prep/k12_postsec_distance/k12_postsec_distances.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9c, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/k12_postsec_distance/k12_postsec_distances.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                          -> removed (absolute paths)
      log_files/k12_postsec_distance/<x> (absolute form)       -> $logdir/<x>  (CANONICAL)
      include $vaprojdir/do_files/sbac/macros_va.doh         -> include $consolidated_dir/do/va/helpers/macros_va.doh
      include $vaprojdir/do_files/k12_postsec_distance/<x>.doh -> include $consolidated_dir/do/data_prep/k12_postsec_distance/<x>.doh
      run/do $vaprojdir/do_files/k12_postsec_distance/<x>     -> run/do $consolidated_dir/do/data_prep/k12_postsec_distance/<x>
      $distance_dtadir/clean/k12_postsec_distance             -> $datadir_clean/k12_postsec_distance/clean/k12_postsec_distance  (CANONICAL chain)
      $distance_dtadir/clean/k12_postsec_mindistance          -> $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance  (CANONICAL chain)
      save, replace (reconcile_cdscodes.do; in-place after use) -> explicit save $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance.dta, replace
      translate (multi-line ///) ABS form                     -> translate $logdir/<x>  (CANONICAL)
      $distance_dtadir/raw/<x> (LEGACY raw)                     -> kept LEGACY (predecessor raw IPEDS / CDE inputs)
      $vaprojdir/data/k12_postsec_distance/raw/<x>              -> kept LEGACY (raw inputs; equivalent to $distance_dtadir/raw/<x>)

    SECURITY SCRUB applied: OpenCage API key (revoked 2026-04-30 per T1-5)
    in commented `opencagegeo' line of k12_postsec_distances.do replaced
    with placeholder "REVOKED-2026-04-30".  Predecessor file in
    cde_va_project_fork still retains the key; consolidated does not.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9c
    Sister files (this batch): check_merge.do, merge_k12_postsec_dist.doh, hd2021.do, reconcile_cdscodes.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/



/* Program to get distances from K12 schools in CDE directory to postsecondary institutions.
Also gets a school-level file with min distance to different types of colleges */

/* created by Paco Martorell
Edited and added to VA project repo by Christina Sun
First added 03/24/2023 */

/* to run this do file:
do $consolidated_dir/do/data_prep/k12_postsec_distance/k12_postsec_distances.do
 */

 /* CHANGE LOG (CHRISTINA SUN):
*/

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
cap log close _all
clear all

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/k12_postsec_distance"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/k12_postsec_distance"
cap mkdir "$datadir_clean/k12_postsec_distance/clean"

log using "$logdir/data_prep/k12_postsec_distance/k12_postsec_distances.smcl", replace text


net install geodist, from(http://fmwww.bc.edu/RePEc/bocode/g) replace
ssc install opencagegeo, replace

clear

********************************
* Step 1: Read in raw data
********************************

/* (1a) Higher ed: raw data is the "Directory Information" IPEDS file and was downloaded 3/20/23 from https://nces.ed.gov/ipeds/datacenter/DataFiles.aspx?gotoReportId=7&fromIpeds=true
*/

run $consolidated_dir/do/data_prep/k12_postsec_distance/hd2021
keep if stabbr=="CA"
drop if c21ugprf==0 /* graduate ed exclusive */
keep if pseflag==1 /* only active in 2021 */
drop if iclevel==3 /* drop the less than 2 years institutions */
drop if instcat==6 /* not degree granting */
drop if c18basic==10 & control==1 /* drop 2 public health focussed institutions */
tab iclevel control
tab sector
drop if sector==0 /* admin unit */
tab iclevel control

gen csu=(f1sysnam=="California State University")
count if csu==1
assert r(N)==23
gen uc=(f1sysnam=="University of California")
gen pub4yr=(csu==1 | uc==1)
count if uc==1
assert r(N)==9

tab instnm if uc==0 & csu==0 & control==1
tab f1sysnam if uc==0 & csu==0 & control==1
assert r(N)==115
gen ccc=(uc==0 & csu==0 & control==1)
gen any_nonprof_4yr=(control~=3 & iclevel==1)
 *** 115 CC's, one less than 116 listed on CA CC. I think the calbright online is not in 2021 IPEDS??
 /*  any_nonprof_4yr > pub4yr = csu + uc */
rename longitud longitude
keep unitid instnm csu uc ccc any_nonprof_4yr pub4yr latitude longitude
gen one=1
tempfile highered
save `highered'
local hn=_N



/* (1b) K12: raw data downloaded 3/20/23 and stored as pubschls.txt. Code below pulls directly from url
*/

// may encounter CDE server error for this webpage, in which case use data on disk
capture import delimited "https://www.cde.ca.gov/schooldirectory/report?rid=dl1&tp=txt", clear

if _rc!=0 {
	import delimited $distance_dtadir/raw/pubschls.txt, clear
}

/* import delimited $distance_dtadir/raw/CDESchoolDirectoryExport.txt, clear */


tempfile allk12
save `allk12'

// keep only traditional high schools
/* keep if soctype=="High Schools (Public)" | soctype=="High Schools In 1 School Dist. (Public)" | soctype=="Junior High Schools (Public)" | soctype=="K-12 Schools (Public)" */


keep cdscode latitude longitude
destring latitude longitude, replace force
gen mi_geo_coord = 0
replace mi_geo_coord = 1 if mi(latitude) | mi(longitude)

////////////////////////////////////////////////////////////////////////////////
/* opencagegeo if mi_geo_coord==1, key("REVOKED-2026-04-30") */

rename l* k12l*
gen one=1
local k12n=_N

********************************
* Step 2: create all the combos of K12 and higher ed
********************************

joinby one using `highered'
assert _N==`k12n'*`hn'


********************************
* Step 3: compute distance to colleges
********************************

geodist latitude longitude k12latitude k12longitude, gen(distance) miles

save $datadir_clean/k12_postsec_distance/clean/k12_postsec_distance, replace

foreach coll in uc csu pub4yr any_nonprof_4yr ccc {
	gen mindist_`coll'=distance if `coll'==1
}

collapse (min) mindist_*, by(cdscode)
/* merge 1:1 cdscode using `allk12', keep(1 3) nogen */

// convert the 14 digit cdscode from float to string
tostring cdscode, generate(cdscodestr) format("%15.0f")
drop cdscode
rename cdscodestr cdscode
// replace back leading zeros lost in the conversion
replace cdscode = "0" + cdscode if strlen(cdscode)==13

save $datadir_clean/k12_postsec_distance/clean/k12_postsec_mindistance, replace


log close
translate $logdir/data_prep/k12_postsec_distance/k12_postsec_distances.smcl $logdir/data_prep/k12_postsec_distance/k12_postsec_distances.log, replace
