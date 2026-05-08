/*------------------------------------------------------------------------------
do/data_prep/schl_chars/clean_charter.do — Phase 1a §3.3 step 9 batch 9b relocation
================================================================================

PURPOSE
    clean CDE charter-status flag; produces $datadir_clean/cde/charter_status.dta.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/cde/CDESchoolDirectoryExport.txt  (LEGACY raw/restricted)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/cde/charter_status.dta
    $logdir/clean_charter.smcl (via log using)
    $logdir/clean_charter.smcl + $logdir/clean_charter.log

RELOCATION (per plan v3 §3.3 step 9 batch 9b, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/schl_chars/clean_charter.do
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
    Sister files (this batch): cds_nces_xwalk.do, clean_locale.do, clean_elsch.do, clean_enr.do, clean_frpm.do, clean_staffcred.do, clean_staffdemo.do, clean_staffschoolfte.do, clean_ecn_disadv.do, clean_sch_char.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


/* clean the exported data of all schools from CDE school directory 
to get charter school status  */

/* To run this do file, execute:
do $vaprojdir/do_files/schl_chars/clean_charter.do
 */

* CANONICAL: cd removed; relocated paths now absolute (per [LEARN:workflow] absolute-after-cd batch 2c).
log close _all



* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/cde"
graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


local date1 = c(current_date)
local time1 = c(current_time)


/* import raw school directory export tab delimited file */
if c(machine_type)=="Macintosh (Intel 64-bit)" {
    import delimited using "data_local/CDESchoolDirectoryExport.txt", delimiters("\t")
}
else {
    import delimited using $vaprojdir/data/public_access/raw/cde/CDESchoolDirectoryExport.txt, delimiters("\t") clear
    log using "$logdir/clean_charter.smcl", replace text

}

/* convert cdscode to string */
tostring cdscode, replace format("%14.0f")
/* add leading zeros to cdscodes which are only 13 digits */
replace cdscode = "0" + cdscode if strlen(cdscode) == 13

/* create a dummy for charter status */
gen charter = .
replace charter = 0 if charteryesno == "N"
replace charter = 1 if charteryesno == "Y"
label var charter "Charter school dummy"

/* create a dummy for public school status */
gen public = .
replace public = 0 if publicyesno == "N"
replace public = 1 if publicyesno == "Y"
label var public "Public school dummy"

keep cdscode opendate closeddate fundingtype charter public 

compress 

if c(machine_type)=="Macintosh (Intel 64-bit)" {
    save "data_local/charter_status.dta", replace
}
else {
    save $datadir_clean/cde/charter_status.dta, replace 
    
    local date2 = c(current_date)
    local time2 = c(current_time)

    di "do file start time: `date1' `time1' "
    di "do file end time: `date2' `time2' "

    log close
    translate $logdir/clean_charter.smcl $logdir/clean_charter.log, replace 
}


