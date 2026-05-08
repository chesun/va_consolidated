/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_locale.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean NCES urban-rural locale codes; produces $datadir_clean/nces/pubschls_locale.dta.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/nces/EDGE_GEOCODE_PUBLICSCH_1516.xlsx  (LEGACY raw — NCES EDGE Geographic Codes)
    $datadir_clean/cde/cds_nces_id_xwalk.dta  (CHAIN read; from this batch)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/nces/pubschls_locale.dta

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_locale.do
    Path repointing applied (script-based methodology):
      cd $vaprojdir                                    -> removed (absolute paths)
      log_files/schl_chars/* (relative or absolute)    -> $logdir/*  (CANONICAL)
      include do_files/sbac/macros_va.doh              -> include $consolidated_dir/do/va/helpers/macros_va.doh
      $vaprojdir/data/public_access/clean/cde/*        -> $datadir_clean/cde/*  (CANONICAL chain; absolute form)
      $vaprojdir/data/public_access/clean/nces/*       -> $datadir_clean/nces/*  (CANONICAL chain; absolute form)
      data/public_access/clean/cde/*                   -> $datadir_clean/cde/*  (CANONICAL chain; relative form post-cd)
      data/public_access/clean/nces/*                  -> $datadir_clean/nces/*  (CANONICAL chain; relative form post-cd)
      data/sch_char.dta (relative; clean_sch_char only) -> $datadir_clean/sch_char.dta  (CANONICAL master)
      translate log_files/schl_chars/* (rel or abs)    -> translate $logdir/*  (CANONICAL)
      $vaprojdir/data/public_access/raw/*              -> kept LEGACY (raw inputs)
      $vaprojdir/data/restricted_access/clean/*        -> kept LEGACY (restricted; out of scope)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag (per Step 7 indexalpha precedent).

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9b
    Sister files (this batch): cds_nces_xwalk.do, clean_elsch.do, clean_enr.do, clean_frpm.do, clean_staffcred.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_charter.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


/* create cleaned dataset for school urban/rural location */

/* to run this do file:
do $vaprojdir/do_files/schl_chars/clean_locale.do
 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
log close _all



* --- output-directory prep + log open (CANONICAL) ----------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/nces"

log using "$logdir/clean_locale.smcl", replace text

di as text _n "{hline 80}"
di as text "clean_locale.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"
graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984

/* import the raw 2015-16 public school data file from NCES */
import excel "$vaprojdir/data/public_access/raw/nces/EDGE_GEOCODE_PUBLICSCH_1516.xlsx", firstrow case(lower) clear

/* keep only California schools */
keep if lstate == "CA"

/* keep nces school id and locale type var */
keep ncessch locale15
rename ncessch nces_id
label var nces_id "12 digit NCES school ID"

rename locale15 locale_fine
label var locale_fine "detailed locale classification"

/* create a new var from locale variable into a coarser categorization */
/* 
The classifications include:
11 = City, Large: Territory inside an urbanized area and inside a principal city with population of 250,000
or more.
12 = City, Midsize: Territory inside an urbanized area and inside a principal city with population less than
250,000 and greater than or equal to 100,000.
13 = City, Small: Territory inside an urbanized area and inside a principal city with population less than
100,000.
21 = Suburban, Large: Territory outside a principal city and inside an urbanized area with population of
250,000 or more.
22 = Suburban, Midsize: Territory outside a principal city and inside an urbanized area with population
less than 250,000 and greater than or equal to 100,000.
23 = Suburban, Small: Territory outside a principal city and inside an urbanized area with population less
than 100,000.
31 = Town, Fringe: Territory inside an urban cluster that is less than or equal to 10 miles from an
urbanized area.
32 = Town, Distant: Territory inside an urban cluster that is more than 10 miles and less than or equal to
35 miles from an urbanized area.
33 = Town, Remote: Territory inside an urban cluster that is more than 35 miles from an urbanized area.
41 = Rural, Fringe: Census-defined rural territory that is less than or equal to 5 miles from an urbanized
area, as well as rural territory that is less than or equal to 2.5 miles from an urban cluster.
42 = Rural, Distant: Census-defined rural territory that is more than 5 miles but less than or equal to 25
miles from an urbanized area, as well as rural territory that is more than 2.5 miles but less than or equal
to 10 miles from an urban cluster.
43 = Rural, Remote: Census-defined rural territory that is more than 25 miles from an urbanized area
and is also more than 10 miles from an urban cluster.
 */


gen locale_coarse = .
replace locale_coarse = 1 if inlist(locale_fine, "11", "12", "13")
replace locale_coarse = 2 if inlist(locale_fine, "21", "22", "23")
replace locale_coarse = 3 if inlist(locale_fine, "31", "32", "33")
replace locale_coarse = 4 if inlist(locale_fine, "41", "42", "43")

label var locale_coarse "coarse locale categories"

label define  local_coarse_label 1 "City" 2 "Suburban" 3 "Town" 4 "Rural"
label values locale_coarse local_coarse_label


/* create value labels for fine locale */
destring locale_fine, replace

label define locale_fine_label 11 "City, large" 12 "City, Midsize" 13 "City, Small" ///
    21 "Suburban, Large" 22 "Suburban, Midsize" 23 "Suburban, Small" ///
    31 "Town, Fringe" 32 "Town, Distant" 33 "Town, Remote" ///
    41 "Rural, Fringe" 42 "Rural, Distant" 43 "Rural, Remote"
label values locale_fine locale_fine_label



// merge on cdscode 
/* Note: cdscode is unique but nces_id is not in the xwal */
merge 1:m nces_id using $datadir_clean/cde/cds_nces_id_xwalk.dta, nogen
drop if missing(cdscode)

compress 
save $datadir_clean/nces/pubschls_locale.dta, replace
cap log close
translate $logdir/clean_locale.smcl $logdir/clean_locale.log, replace
