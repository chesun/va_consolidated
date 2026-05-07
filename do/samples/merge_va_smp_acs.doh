/*------------------------------------------------------------------------------
do/samples/merge_va_smp_acs.doh — ACS census-tract controls merger (do-script)
================================================================================

PURPOSE
    Merge ACS (American Community Survey) census-tract demographic controls
    onto a VA sample.  This script is called via `do' (not `include') with
    5 positional arguments — it runs in its OWN scope and re-includes
    macros_va.doh to set up the locals it needs.

    Pipeline shape:
      (1) Read the geocoded address-list crosswalk and build census_geocode tempfile.
      (2) Pull lagged-grade addresses from K12 for students at census_grade
          (typically grade 6) in the appropriate years.
      (3) Read the address-list and ACS census-tract data; build tempfiles.
      (4) Open the calling script's VA dataset; merge in lagged address ->
          address_id -> census_sct -> ACS controls.
      (5) Drop obs with missing census controls; build peer census characteristics.
      (6) Apply purpose-dependent restriction:
          - "create_va": keep only touse_g11_<va_name>==1 obs
          - "create_sample": leave dataset full
      (7) Caller's saved dataset is what we operated on (passed as `va_dataset_file').

ARGUMENTS (positional)
    1. va_type          — "test_score" or "outcome"
    2. va_dataset_file  — path to .dta to operate on (or `tempfile' macro from caller)
    3. va_dataset_name  — human-readable name for di output
    4. purpose          — "create_va" or "create_sample"
    5. va_name          — `subject' / `outcome' / "none"

INVOKED FROM
    `do/samples/create_score_samples.do' (test-score, 2 sites: `_a' and `_la' blocks)
    `do/samples/create_out_samples.do' (outcome, 2 sites: same)
    Called via `do' with the 5 positional args above.

INPUTS
    LEGACY (read-only per ADR-0021 sandbox principle):
      $vaprojdir/data/restricted_access/clean/crosswalks/address_list_census_batch_geocoded.csv
                                          — geocoded census-tract crosswalk
      $vaprojdir/data/restricted_access/clean/crosswalks/address_list.dta
                                          — full address list
      $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta
                                          — restricted K12 raw scores (for lagged-grade addresses)
      $vaprojdir/data/public_access/clean/acs/acs_ca_census_tract_clean.dta
                                          — ACS demographics by census tract × year
      $consolidated_dir/do/va/helpers/macros_va.doh
                                          — VA-pipeline locals (for `census_grade',
                                            `census_controls', etc.)

      The dataset passed via `va_dataset_file' is operated on in memory:
      - if a tempfile macro -> reads from caller's tempfile path
      - if a disk path -> reads from disk (CANONICAL `$datadir_clean' in our pipeline)

OUTPUTS
    None on disk (the script operates on the caller's dataset in memory; the
    caller writes via `save').  Tempfile saves are session-scoped and exempt
    from the sandbox rule per established convention.

    Modifies in-memory dataset:
      + census_sct, year_grade<census_grade>
      + ACS census-tract demographics (eth_*, educ_*, pov_*, inc_*)
      + peer_<var> for each tracked ACS variable (school-year mean excluding self)
      + census_controls_sample (byte indicator)
      + merge_lagged_address, merge_address_id, merge_census_geocode, merge_acs

ROLE IN ADR-0021 SANDBOX
    Reads LEGACY restricted-access K12 + geocoded crosswalks; writes ONLY to
    Stata tempfiles (session-scoped, auto-cleaned, exempt per established
    convention).  No persistent on-disk writes.  Sandbox-trivially clean.

RELOCATION HISTORY (per plan v3 §3.3 step 2 batch 2c, applied 2026-05-07)
    Source:      cde_va_project_fork/do_files/sbac/merge_va_smp_acs.doh (predecessor)
    Destination: do/samples/merge_va_smp_acs.doh (this file)
    Path repointing under ADR-0021 (analysis logic preserved verbatim):
      - L22 usage comment: $vaprojdir/do_files/sbac/merge_va_smp_acs.doh
                        -> $consolidated_dir/do/samples/merge_va_smp_acs.doh
      - L47 `include $vaprojdir/do_files/sbac/macros_va.doh'
         -> `include $consolidated_dir/do/va/helpers/macros_va.doh' (relocated 2026-04-30)
         (this is a `do'-scope script — needs its own macros_va include for locals)
      - All LEGACY `$vaprojdir/data/...' reads preserved (restricted-access K12 +
        crosswalks per ADR-0017; static run-time inputs).

ORIGINAL CHANGE LOG (preserved from predecessor; written by Christina (Che) Sun)
    First written by Christina (Che) Sun on April 27, 2022.
    2022-10-13: Created peer ACS characteristics.
    2026-05-07: Relocated to consolidated repo per plan v3 §3.3 step 2 batch 2c;
                macros_va include repointed to do/va/helpers/.

REFERENCES
    Plan: quality_reports/plans/2026-04-27_phase-1-consolidation-plan-v3.md §3.3 step 2
    ADRs: 0017 (Matt's files untouched — unrelated; this is Christina's),
          0021 (sandbox; description convention)
------------------------------------------------------------------------------*/

********************************************************************************
/* do helper file to merge census tract controls to VA sample. Arguments need
to be set for
-- what type of VA, test score or outcome
-- which VA dataset file is being merged to using the tempfile macro in calling file
-- the name for the tempfile being merged to, using a string
-- what purpose does the calling do file have, create VA estimates or create VA sample
-- what is the exact name for the VA being created, what subject or outcome

If purpose is create_va, this produces a dataset with obs that has non-missing
census controls, and that are in the touse sample for the corresponding VA estimation

See comments above the args command for details on how to set arguments */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on April 27. 2022 *************************


/* To call this do helper file:

do $consolidated_dir/do/samples/merge_va_smp_acs.doh

AND ADD NECESSARY ARGUMENTS

 */

/* CHANGE LOG
10/13/2022: create peer acs Characteristics
 */

/*
-- set va_type to either test_score or outcome
-- If merging to a temp dataset, set va_dataset_file to `va_g11_dataset', `va_g11_out_dataset', `va_g11_sibling_dataset',
or `va_g11_out_sibling_dataset'. MUST pass as macros to give file location.
If merging to a dataset on disc, set va_dataset_file to the file path
-- set va_dataset_name to any of the options in va_dataset_file but without macro quotes
If using dataset on disc, set to dataset name
-- set purpose to create_va or create_sample
-- set va_name to `subject' or `outcome' or none
*/


args va_type va_dataset_file va_dataset_name purpose va_name

//run Matt's do helper file to set the local macros for VA project
include $consolidated_dir/do/va/helpers/macros_va.doh

import delimited $vaprojdir/data/restricted_access/clean/crosswalks/address_list_census_batch_geocoded.csv ///
  , delimiter(tab) varnames(1) case(lower) stringcols(_all) clear
rename id address_id
gen census_sct = statefp + countyfp + tract
keep address_id census_sct
compress
tempfile census_geocode
save `census_geocode'

use merge_id_k12_test_scores state_student_id student_id cdscode year grade ///
  street_address_line_one street_address_line_two city state zip_code ///
  using $vaprojdir/data/restricted_access/clean/k12_test_scores/k12_test_scores_clean.dta, clear
//keep students in grade 6 in years 2010-2013 to match with census. the census_grade macro is set to 6
keep if grade==`census_grade' & inrange(year, ``va_type'_min_year'-(11-`census_grade'), ``va_type'_max_year'-(11-`census_grade'))
drop if mi(state_student_id)
duplicates tag state_student_id, gen(dup_ssid)
egen year_min = min(year) if dup_ssid!=0, by(state_student_id)
drop if year!=year_min & dup_ssid!=0
duplicates drop state_student_id, force
rename year year_grade`census_grade'
keep state_student_id student_id year_grade`census_grade' street_address_line_one street_address_line_two city state zip_code
compress
tempfile lagged_address
save `lagged_address'

use $vaprojdir/data/restricted_access/clean/crosswalks/address_list.dta, clear
keep address_id street_address_line_one city state zip_code
duplicates drop
compress
tempfile address_id
save `address_id'

use $vaprojdir/data/public_access/clean/acs/acs_ca_census_tract_clean.dta, clear
rename year year_grade`census_grade'
compress
tempfile lagged_acs
save `lagged_acs'


use `va_dataset_file', clear
merge m:1 state_student_id using `lagged_address' ///
  , keep(3) keepusing(street_address_line_one city state zip_code year_grade`census_grade') gen(merge_lagged_address)
merge m:1 street_address_line_one city state zip_code using `address_id' ///
  , keep(3) gen(merge_address_id)
merge m:1 address_id using `census_geocode' ///
  , keep(3) gen(merge_census_geocode)
rename census_sct geoid2

merge m:1 geoid2 year_grade`census_grade' using `lagged_acs' ///
  , keep(3) gen(merge_acs)
rename geoid2 census_sct
foreach v of varlist `census_controls' {
  drop if mi(`v')
}

// create a sample indicator for obs with census controls
gen byte census_controls_sample = 1

// create peer census characteristics
foreach var in eth_asian_pct eth_hispanic_pct eth_black_pct educ_hs_dropout_prop ///
  educ_deg_4year_plus_prop pov_fam_child_lt18_pct inc_median_hh {
    rangestat (mean) `var', interval(year, 0, 0) by(cdscode) excludeself
    rename `var'_mean peer_`var'
  }


if "`purpose'" == "create_va" {
  // only keep obs needed for the current VA estimation
  keep if touse_g11_`va_name'==1
  di "ACS controls merged successfully to `va_dataset_name'"
  di "Ready to create VA estimates for `va_name'"
}
else if "`purpose'" == "create_sample" {
  di "VA sample including ACS controls created"
}
