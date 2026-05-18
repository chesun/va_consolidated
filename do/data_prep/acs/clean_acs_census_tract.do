/*------------------------------------------------------------------------------
do/data_prep/acs/clean_acs_census_tract.do — Phase 1a §3.3 step 9 batch 9a relocation
================================================================================

PURPOSE
    Clean the 2010-2013 ACS census-tract subject tables (S0601, S1501,
    S1702, S1901) using 5-year estimates and append the four years into
    a single panel.  Produces the canonical census-tract-level ACS
    cleaned dataset consumed by downstream school-level merges.

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $vaprojdir/data/public_access/raw/acs/subject_tables/<year>/5yr/ACSST5Y<year>.<S>_data_with_overlays.csv
        — LEGACY raw public ACS data (4 subject tables × 4 years = 16 csv files)
    $consolidated_dir/do/va/helpers/macros_va.doh (include; CANONICAL — relocated step 1)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/acs/acs_ca_census_tract_clean_<year>.dta  (4 yearly files)
    $datadir_clean/acs/acs_ca_census_tract_clean.dta         (combined panel)
    $logdir/data_prep/acs/clean_acs_census_tract.smcl + .log

RELOCATION (per plan v3 §3.3 step 9 batch 9a, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/acs/clean_acs_census_tract.do
    Path repointing applied via sed pass + targeted Edit:
      cd $vaprojdir                                       -> removed (absolute paths used; per [LEARN:workflow] batch 2c)
      log_files/acs/<x>                                     -> $logdir/<x>  (CANONICAL)
      include do_files/sbac/macros_va.doh                 -> include $consolidated_dir/do/va/helpers/macros_va.doh  (CANONICAL — macros_va.doh relocated step 1)
      using data/public_access/raw/acs/<x>                  -> using $vaprojdir/data/public_access/raw/acs/<x>  (LEGACY raw, absolute)
      data/public_access/clean/acs/<x>                      -> $datadir_clean/acs/<x>  (CANONICAL chain)
      translate log_files/acs/<x>                           -> translate $logdir/<x>  (CANONICAL)
    Predecessor's commented-out `$projdir/dta/common_core_va/acs/...` save
    line (line 346 of original; now line ~352) preserved verbatim per
    ADR-0021 (commented; not active code).
    Predecessor's `log using` upgraded to consolidated convention with
    double-quotes + `text' flag (per Step 7 indexalpha precedent).

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9a
    Sister: acs_2017_gen_dict.do (this batch)

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
/* This is an updated version of clean_acs_ca_census_tract_old.do that accounts
for changed variable names due to new ACS subject table naming conventions.
This do file cleans the 2010 to 2013 ACS subject tables S0601, S1501, S1702,
and S1901 at the census tract level using 5 year estimates */
********************************************************************************
********************************************************************************
/* updated by Che Sun, February 23, 2022 */
/* ucsun@ucdavis.edu */
********************************************************************************

/* To run this do file, type:
do $vaprojdir/do_files/acs/clean_acs_census_tract
*/

* CANONICAL: cd removed; relocated paths now absolute (per batch 2c lesson, [LEARN:workflow] absolute-after-cd discipline 2026-05-07).



clear all
graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
cap log close clean_acs_census_tract

* --- output-directory prep (CANONICAL) -------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/acs"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/acs"

log using "$logdir/data_prep/acs/clean_acs_census_tract.smcl", replace text name(clean_acs_census_tract)

di as text _n "{hline 80}"
di as text "clean_acs_census_tract.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"


set seed 1984

timer on 1


//include the VA project macros do helper file
include $consolidated_dir/do/va/helpers/macros_va.doh

#delimit ;
#delimit cr
macro list





foreach year in 2010 2011 2012 2013 {

  ******************************************************************************
  * Education: Subject Table S1501 *
  ******************************************************************************

  import delimited using $vaprojdir/data/public_access/raw/acs/subject_tables/`year'/5yr/ACSST5Y`year'.S1501_data_with_overlays.csv, clear varnames(1) case(lower)

  //assigning var labels using the second row
  foreach v of varlist * {
  	label var `v' `"`=`v'[1]'"'
  	char `v'[varlabel] `"`=`v'[1]'"'
  }
  drop if _n==1

  //convert to numeric variables, and remove non-numeric characters specified in the ignore() option
  foreach v of varlist s* {
  	destring `v', replace ignore(",+(X)-*null")
  }

  *** Education level proportions
  // proportion of high school dropouts in 25 years and over population: (less than 9th grade + 9-12th grade)/total
  gen educ_hs_dropout_prop = (s1501_c01_007e + s1501_c01_008e) / s1501_c01_006e
  // proportion of high school graduates
  gen educ_deg_hs_prop = s1501_c01_009e / s1501_c01_006e
  // proportion of some college, no degree
  gen educ_some_college_prop = s1501_c01_010e / s1501_c01_006e
  // proportion of associate's degree
  gen educ_deg_2year_prop = s1501_c01_011e / s1501_c01_006e
  // proportion of bachelor's degree
  gen educ_deg_4year_prop = s1501_c01_012e / s1501_c01_006e
  // proportion of graduate or professional degree
  gen educ_deg_grad_prop = s1501_c01_013e / s1501_c01_006e
  // proportion of 4 year degree or more
  gen educ_deg_4year_plus_prop = (s1501_c01_012e + s1501_c01_013e) / s1501_c01_006e

  // temp var to check whether the data add up
  tempvar tot_prop
  gen `tot_prop' = (s1501_c01_007e + s1501_c01_008e + s1501_c01_009e + s1501_c01_010e + s1501_c01_011e + s1501_c01_012e + s1501_c01_012e + s1501_c01_013e) / s1501_c01_006e
  sum `tot_prop'

  keep educ* geo_id name
  rename geo_id geoid
  //generate the geoid2 var which is the last 11 digits of geoid
  gen geoid2 = substr(geoid, 10, 11)
  // the name var is the same as the old geodisplaylabel var, keep var name consistency
  rename name geodisplaylabel
  gen year = `year'
  order geoid geoid2 geodisplaylabel year
  //checks whether the geoid var uniquely identifies observations
  isid geoid
  tempfile education_`year'
  save `education_`year''


  ******************************************************************************
  * Poverty: Subject Table S1702 *
  ******************************************************************************
  import delimited using $vaprojdir/data/public_access/raw/acs/subject_tables/`year'/5yr/ACSST5Y`year'.S1702_data_with_overlays.csv, clear varnames(1) case(lower)

  foreach v of varlist * {
  	label var `v' `"`=`v'[1]'"'
  	char `v'[varlabel] `"`=`v'[1]'"'
  }
  drop if _n==1

  foreach v of varlist s* {
  	destring `v', replace ignore(",+(X)-*Nnull")
  }

  // total number of families with children under 18 years
  gen fam_child_lt18_tot = s1702_c01_002e
  // proportion of families with children under 18 years below poverty level
  gen pov_fam_child_lt18_pct = s1702_c02_002e

  keep geo_id name fam_child_lt18_tot pov_fam_child_lt18_pct
  rename geo_id geoid
  //generate the geoid2 var which is the last 11 digits of geoid
  gen geoid2 = substr(geoid, 10, 11)
  rename name geodisplaylabel
  gen year = `year'
  order geoid geoid2 geodisplaylabel year
  isid geoid
  tempfile poverty_`year'
  save `poverty_`year''


  ******************************************************************************
  * Income: Subject Table S1901 *
  ******************************************************************************
  import delimited using $vaprojdir/data/public_access/raw/acs/subject_tables/`year'/5yr/ACSST5Y`year'.S1901_data_with_overlays.csv, clear varnames(1) case(lower)

  foreach v of varlist * {
  	label var `v' `"`=`v'[1]'"'
  	char `v'[varlabel] `"`=`v'[1]'"'
  }
  drop if _n==1

  foreach v of varlist s* {
    destring `v', replace ignore(",+(X)-*Nnull")
  }

  *Note: all the variables for households income are in percentage points

  *** Households (c01)
  //percent of households with income less than $10k
  egen inc_lt10k_hh_pct = rowtotal(s1901_c01_002e), mi
  //percept of households with income < $15k
  egen inc_lt15k_hh_pct = rowtotal(s1901_c01_002e s1901_c01_003e), mi
  //percent of households with income < $25k
  egen inc_lt25k_hh_pct = rowtotal(s1901_c01_002e s1901_c01_003e s1901_c01_004e), mi
  //percent of households with income < $35k
  egen inc_lt35k_hh_pct = rowtotal(s1901_c01_002e s1901_c01_003e s1901_c01_004e s1901_c01_005e), mi
  //percent of households with income < $50k
  egen inc_lt50k_hh_pct = rowtotal(s1901_c01_002e s1901_c01_003e s1901_c01_004e s1901_c01_005e s1901_c01_006e), mi
  //percent of households with income < $75k
  egen inc_lt75k_hh_pct = rowtotal(s1901_c01_002e s1901_c01_003e s1901_c01_004e s1901_c01_005e s1901_c01_006e s1901_c01_007e), mi
  //percent of households with income < $100k
  egen inc_lt100k_hh_pct = rowtotal(s1901_c01_002e s1901_c01_003e s1901_c01_004e s1901_c01_005e s1901_c01_006e s1901_c01_007e s1901_c01_008e), mi
  //percent of households with income < $150k
  egen inc_lt150k_hh_pct = rowtotal(s1901_c01_002e s1901_c01_003e s1901_c01_004e s1901_c01_005e s1901_c01_006e s1901_c01_007e s1901_c01_008e s1901_c01_009e), mi
  //percent of households with income < $200k
  egen inc_lt200k_hh_pct = rowtotal(s1901_c01_002e s1901_c01_003e s1901_c01_004e s1901_c01_005e s1901_c01_006e s1901_c01_007e s1901_c01_008e s1901_c01_009e s1901_c01_010e), mi

  //household median income
  gen inc_median_hh = s1901_c01_012e
  //household mean income
  gen inc_mean_hh = s1901_c01_013e


  *** Families (c02)
  //percent of families with income less than $10k
  egen inc_lt10k_fam_pct = rowtotal(s1901_c02_002e), mi
  //percent of families with income less than $15k
  egen inc_lt15k_fam_pct = rowtotal(s1901_c02_002e s1901_c02_003e), mi
  //percent of families with income less than $25k
  egen inc_lt25k_fam_pct = rowtotal(s1901_c02_002e s1901_c02_003e s1901_c02_004e), mi
  //percent of families with income < $35k
  egen inc_lt35k_fam_pct = rowtotal(s1901_c02_002e s1901_c02_003e s1901_c02_004e s1901_c02_005e), mi
  //percent of families with income < $50k
  egen inc_lt50k_fam_pct = rowtotal(s1901_c02_002e s1901_c02_003e s1901_c02_004e s1901_c02_005e s1901_c02_006e), mi
  //percent of families with income < $75k
  egen inc_lt75k_fam_pct = rowtotal(s1901_c02_002e s1901_c02_003e s1901_c02_004e s1901_c02_005e s1901_c02_006e s1901_c02_007e), mi
  //percent of families with income < $100k
  egen inc_lt100k_fam_pct = rowtotal(s1901_c02_002e s1901_c02_003e s1901_c02_004e s1901_c02_005e s1901_c02_006e s1901_c02_007e s1901_c02_008e), mi
  //percent of families with income < $150k
  egen inc_lt150k_fam_pct = rowtotal(s1901_c02_002e s1901_c02_003e s1901_c02_004e s1901_c02_005e s1901_c02_006e s1901_c02_007e s1901_c02_008e s1901_c02_009e), mi
  //percent of families with income < $200k
  egen inc_lt200k_fam_pct = rowtotal(s1901_c02_002e s1901_c02_003e s1901_c02_004e s1901_c02_005e s1901_c02_006e s1901_c02_007e s1901_c02_008e s1901_c02_009e s1901_c02_010e), mi

  //families median income
  gen inc_median_fam = s1901_c02_012e
  //families mean income
  gen inc_mean_fam = s1901_c02_013e


  *** Married-Couple Families (c03)
  //percent of married-couple families with income less than $10k
  egen inc_lt10k_mcfam_pct = rowtotal(s1901_c03_002e), mi
  //percent of married-couple families with income less than $15k
  egen inc_lt15k_mcfam_pct = rowtotal(s1901_c03_002e s1901_c03_003e), mi
  //percent of married-couple families with income less than $25k
  egen inc_lt25k_mcfam_pct = rowtotal(s1901_c03_002e s1901_c03_003e s1901_c03_004e), mi
  //percent of married-couple families with income < $35k
  egen inc_lt35k_mcfam_pct = rowtotal(s1901_c03_002e s1901_c03_003e s1901_c03_004e s1901_c03_005e), mi
  //percent of married-couple families with income < $50k
  egen inc_lt50k_mcfam_pct = rowtotal(s1901_c03_002e s1901_c03_003e s1901_c03_004e s1901_c03_005e s1901_c03_006e), mi
  //percent of married-couple families with income < $75k
  egen inc_lt75k_mcfam_pct = rowtotal(s1901_c03_002e s1901_c03_003e s1901_c03_004e s1901_c03_005e s1901_c03_006e s1901_c03_007e), mi
  //percent of married-couple families with income < $100k
  egen inc_lt100k_mcfam_pct = rowtotal(s1901_c03_002e s1901_c03_003e s1901_c03_004e s1901_c03_005e s1901_c03_006e s1901_c03_007e s1901_c03_008e), mi
  //percent of married-couple families with income < $150k
  egen inc_lt150k_mcfam_pct = rowtotal(s1901_c03_002e s1901_c03_003e s1901_c03_004e s1901_c03_005e s1901_c03_006e s1901_c03_007e s1901_c03_008e s1901_c03_009e), mi
  //percent of married-couple families with income < $200k
  egen inc_lt200k_mcfam_pct = rowtotal(s1901_c03_002e s1901_c03_003e s1901_c03_004e s1901_c03_005e s1901_c03_006e s1901_c03_007e s1901_c03_008e s1901_c03_009e s1901_c03_010e), mi

  //married-couple families median income
  gen inc_median_mcfam = s1901_c03_012e
  //married-couple families mean income
  gen inc_mean_mcfam = s1901_c03_013e


  *** Non-Family Households (c04)
  //percent of non-family households with income less than $10k
  egen inc_lt10k_nonfamhh_pct = rowtotal(s1901_c04_002e), mi
  //percent of non-family households with income less than $15k
  egen inc_lt15k_nonfamhh_pct = rowtotal(s1901_c04_002e s1901_c04_003e), mi
  //percent of non-family households with income less than $25k
  egen inc_lt25k_nonfamhh_pct = rowtotal(s1901_c04_002e s1901_c04_003e s1901_c04_004e), mi
  //percent of non-family households with income < $35k
  egen inc_lt35k_nonfamhh_pct = rowtotal(s1901_c04_002e s1901_c04_003e s1901_c04_004e s1901_c04_005e), mi
  //percent of non-family households with income < $50k
  egen inc_lt50k_nonfamhh_pct = rowtotal(s1901_c04_002e s1901_c04_003e s1901_c04_004e s1901_c04_005e s1901_c04_006e), mi
  //percent of non-family households with income < $75k
  egen inc_lt75k_nonfamhh_pct = rowtotal(s1901_c04_002e s1901_c04_003e s1901_c04_004e s1901_c04_005e s1901_c04_006e s1901_c04_007e), mi
  //percent of non-family households with income < $100k
  egen inc_lt100k_nonfamhh_pct = rowtotal(s1901_c04_002e s1901_c04_003e s1901_c04_004e s1901_c04_005e s1901_c04_006e s1901_c04_007e s1901_c04_008e), mi
  //percent of non-family households with income < $150k
  egen inc_lt150k_nonfamhh_pct = rowtotal(s1901_c04_002e s1901_c04_003e s1901_c04_004e s1901_c04_005e s1901_c04_006e s1901_c04_007e s1901_c04_008e s1901_c04_009e), mi
  //percent of non-family households with income < $200k
  egen inc_lt200k_nonfamhh_pct = rowtotal(s1901_c04_002e s1901_c04_003e s1901_c04_004e s1901_c04_005e s1901_c04_006e s1901_c04_007e s1901_c04_008e s1901_c04_009e s1901_c04_010e), mi

  //non-family households median income
  gen inc_median_nonfamhh = s1901_c04_012e
  //non-family households mean income
  gen inc_mean_nonfamhh = s1901_c04_013e

  keep geo_id name inc*
  rename geo_id geoid
  //generate the geoid2 var which is the last 11 digits of geoid
  gen geoid2 = substr(geoid, 10, 11)
  rename name geodisplaylabel
  gen year = `year'
  order geoid geoid2 geodisplaylabel year
  isid geoid
  tempfile income_`year'
  save `income_`year''



  ******************************************************************************
  * Population: Subject Table S0601 *
  ******************************************************************************
  import delimited using $vaprojdir/data/public_access/raw/acs/subject_tables/`year'/5yr/ACSST5Y`year'.S0601_data_with_overlays.csv, clear varnames(1) case(lower)

  foreach v of varlist * {
  	di "`v'"
  	//fist observation in each column is the var label
  	label var `v' `"`=`v'[1]'"'
  	//define the var Characteristics
  	char `v'[varlabel] `"`=`v'[1]'"'
  }
  drop if _n==1

  foreach v of varlist s* {
  	destring `v', replace ignore(",+(X)-*Nnull")
  }

  //total population between 5 and 17 years old = total population * percent between 5-17
  gen pop_517_tot = s0601_c01_001e * (s0601_c01_003e / 100)
  //total population less than 18 years old
  gen pop_lt18_tot = (s0601_c01_001e * (s0601_c01_002e / 100)) + (s0601_c01_001e * (s0601_c01_003e / 100))
  //total native populaiton
  gen pop_native_tot = s0601_c02_001e + s0601_c03_001e + s0601_c04_001e
  //proportion of native population
  gen pop_native_prop = pop_native_tot / s0601_c01_001e

  //total native population between 5 and 17 years old
  gen pop_517_native_tot = (s0601_c02_001e * (s0601_c02_003e / 100)) + (s0601_c03_001e * (s0601_c03_003e / 100)) + (s0601_c04_001e * (s0601_c04_003e / 100))
  //proportion of native in the population between 5 and 17
  gen pop_517_native_prop = pop_517_native_tot / pop_517_tot

  //total native population less than 18 years old
  gen pop_lt18_native_tot = pop_517_native_tot + (s0601_c02_001e * (s0601_c02_002e / 100)) + (s0601_c03_001e * (s0601_c03_002e / 100)) + (s0601_c04_001e * (s0601_c04_002e / 100))
  //proportion of native in the population less than 18
  gen pop_lt18_native_prop = pop_lt18_native_tot / pop_lt18_tot

  sum pop_*

  //percentage of white
  gen eth_white_pct = s0601_c01_014e
  //percentage of black
  gen eth_black_pct = s0601_c01_015e
  //percentage of other race: lumping together American Indian, Native Hawaiian, one race- some other race, and two or more races
  egen eth_other_pct = rowtotal(s0601_c01_016e s0601_c01_018e s0601_c01_019e s0601_c01_020e)
  //percentage of Asian
  gen eth_asian_pct = s0601_c01_017e
  //percentage of Hispanic
  gen eth_hispanic_pct = s0601_c01_021e
  //percentage of non Hispanic white
  gen eth_white_nonhispanic_pct = s0601_c01_022e

  keep geo_id name pop_* eth_*
  rename geo_id geoid
  //generate the geoid2 var which is the last 11 digits of geoid
  gen geoid2 = substr(geoid, 10, 11)
  rename name geodisplaylabel
  gen year = `year'
  order geoid geoid2 geodisplaylabel year
  isid geoid
  tempfile population_`year'
  save `population_`year''



  ******************************************************************************
  * Merge all the subject tables of each year *
  ******************************************************************************
  use `population_`year'', clear
  merge 1:1 geoid using `education_`year'', keep(3)
  drop _merge
  merge 1:1 geoid using `poverty_`year'', keep(3)
  drop _merge
  merge 1:1 geoid using `income_`year'', keep(3)
  drop _merge

  compress
  order geoid geoid2 geodisplaylabel year
  sort geoid geoid2 year
  /* //save to my own folder while waiting for write access
  save $projdir/dta/common_core_va/acs/acs_ca_census_tract_clean_`year'.dta, replace */
  save $datadir_clean/acs/acs_ca_census_tract_clean_`year'.dta, replace

}

//append all the years of data
use $datadir_clean/acs/acs_ca_census_tract_clean_2010.dta, clear
append using $datadir_clean/acs/acs_ca_census_tract_clean_2011.dta
append using $datadir_clean/acs/acs_ca_census_tract_clean_2012.dta
append using $datadir_clean/acs/acs_ca_census_tract_clean_2013.dta
save $datadir_clean/acs/acs_ca_census_tract_clean.dta, replace








timer off 1
timer list
cap log close clean_acs_census_tract
translate $logdir/data_prep/acs/clean_acs_census_tract.smcl $logdir/data_prep/acs/clean_acs_census_tract.log, replace
