/*------------------------------------------------------------------------------
do/data_prep/prepare/enrollmentclean.do — Phase 1a §3.3 step 9 batch 9d relocation
================================================================================

PURPOSE
    clean CDE annual enrollment 2014-15..2018-19; produces $datadir_clean/enrollment/schoollevel/enr<year>.dta (5 files; consumed by poolgr11enr in chain).

INVOKED FROM
    `do/main.do' Phase 1 (DATA PREP) under flag `do_data_prep'.

INPUTS (verified via grep on file body)
    $caschls_projdir/dta/enrollment/raw/`enrdata'  (LEGACY)

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on file body)
    $datadir_clean/enrollment/schoollevel/`enrdata'
    $logdir/data_prep/prepare/enrollmentclean.smcl (via log using)
    $logdir/data_prep/prepare/enrollmentclean.smcl + $logdir/data_prep/prepare/enrollmentclean.log (translate)

RELOCATION (per plan v3 §3.3 step 9 batch 9d, applied 2026-05-08)
    Source: caschls/do/build/prepare/enrollmentclean.do
    Path repointing applied (script-based methodology):
      $projdir/log/build/prepare/<x>                    -> $logdir/<x>  (CANONICAL)
      $projdir/dta/enrollment/schoollevel/<x> (read OR write) -> $datadir_clean/enrollment/schoollevel/<x>  (CANONICAL chain)
      $projdir/dta/enrollment/raw/<x> (read)             -> $caschls_projdir/dta/enrollment/raw/<x>  (LEGACY raw)
      $clndtadir/<sub>/<x> (write only)                -> $datadir_clean/calschls/<sub>/<x>  (CANONICAL chain)
      $clndtadir/<sub>/<x> (read of pre-existing)      -> kept LEGACY (e.g., $clndtadir/staff/staff0414)
      $rawdtadir/<x> (read)                              -> kept LEGACY (CalSCHLS survey raw inputs)
      translate (multi-line OR single-line)            -> translate $logdir/<x>  (CANONICAL)
    Predecessor's `log using' upgraded to consolidated convention with
    double-quotes + `text' flag (per Step 7 indexalpha precedent).
    `name(...)' suffix (used by poolgr11enr/enrollmentclean/renamedata/
    splitstaff0414) preserved.

SETTINGS REQUISITE
    settings.do edited in this batch to add LEGACY-READ-ONLY globals
    `$rawdtadir' (CalSCHLS restricted raw survey data) and `$clndtadir'
    (CalSCHLS restricted clean data, pre-existing — used for read of
    staff0414 in splitstaff0414.do).  No write-eligible target via
    those globals; writes go to $datadir_clean/calschls/<x> CANONICAL.

REFERENCES
    ADRs:   0021 (sandbox; description convention)
    Plan:   v3 §3.3 step 9 batch 9d
    Sister files (this batch): poolgr11enr.do, renamedata.do, splitstaff0414.do

ORIGINAL HEADER preserved verbatim below.
------------------------------------------------------------------------------*/


********************************************************************************
******************** this cleans CDE enrollment datasets *************************
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu ********************
********************************************************************************
cap log close _all
clear
set more off

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$logdir"
cap mkdir "$logdir/data_prep"
cap mkdir "$logdir/data_prep/prepare"
cap mkdir "$datadir_clean"
cap mkdir "$datadir_clean/enrollment"
cap mkdir "$datadir_clean/enrollment/schoollevel"

log using "$logdir/data_prep/prepare/enrollmentclean.smcl", replace text name(enrollmentclean)

local enrdtaname `" "enr1415" "enr1516" "enr1617" "enr1718" "enr1819" "'  //create a local macro for raw enrollment dataset names

foreach enrdata of local enrdtaname {

use $caschls_projdir/dta/enrollment/raw/`enrdata', clear

/* set trace on //turn on trace for debugging */

gen byte female = 0 //generate a dummy var female to replace string var gender
replace female = 1 if gender == "F"


local grades 1 2 3 4 5 6 7 8 9 10 11 12 //generate a local macro for grades


/* generate total enrollment by grade for each school */
sort cdscode
foreach i of local grades {
  by cdscode: egen gr`i'enr = total(gr`i'enrl) //generate var for total grade i enrollment in each school
  label var gr`i'enr "total enrollment in grade `i'"
}

/* generate total enrollment by grade and sex for each school */
foreach i of local grades {
  bysort cdscode female: egen gr`i'enrsex = total(gr`i'enrl) //gnerate a temp variable for group total enrollment by grade for each school and sex combination

  gen gr`i'femaleenrtemp = 0 //generate a tewmp var for total female enrollment in grade i, this var is 0 if the female var == 0
  replace gr`i'femaleenrtemp = gr`i'enrsex if female == 1

  gen gr`i'maleenrtemp = 0  //generate a temp var for total male enrollment in grade i, this var is = if the female var == 1
  replace gr`i'maleenrtemp = gr`i'enrsex if female == 0


  bysort cdscode: egen gr`i'femaleenr = max(gr`i'femaleenrtemp) //generate a var for female enrollment in grade i for each school by populating 0 entries in the temp female enrollment var above
  label var gr`i'femaleenr "total female enrollment in grade `i'"

  bysort cdscode: egen gr`i'maleenr = max(gr`i'maleenrtemp) //generate a var for male enrollment in grade i for each school by populating 0 entries in the temp male enrollment var above
  label var gr`i'maleenr "total female enrollment in grade `i'"
}

/* generate total enrollment by grade and ethnicity for each school
value label for ethnicity:
Code 0 = Not reported
Code 1 = American Indian or Alaska Native, Not Hispanic
Code 2 = Asian, Not Hispanic
Code 3 = Pacific Islander, Not Hispanic
Code 4 = Filipino, Not Hispanic
Code 5 = Hispanic or Latino
Code 6 = African American, not Hispanic
Code 7 = White, not Hispanic
Code 8 = Two or More Races, Not Hispanic */

foreach i of local grades {
  bysort cdscode ethnicity: egen gr`i'enrethnic = total(gr`i'enrl) //gnerate a temp variable for group total enrollment by grade for each school and ethnicity combination

  gen gr`i'noethnicenrtemp = 0 //generate a temp var for total enrollment for unreported ethnicity in grade i
  replace gr`i'noethnicenrtemp = gr`i'enrethnic if ethnicity == 0

  gen gr`i'nativeenrtemp = 0 //generate a temp var for total enrollment for native american (American Indian or Alaska Native, Not Hispanic) in grade i
  replace gr`i'nativeenrtemp = gr`i'enrethnic if ethnicity == 1

  gen gr`i'asianenrtemp = 0 //gemerate a temp var for total enrollment of asian students in grade i
  replace gr`i'asianenrtemp = gr`i'enrethnic if ethnicity == 2

  gen gr`i'pacificenrtemp = 0 //generate a temp var for total enrollment of pacific islanders in grade i
  replace gr`i'pacificenrtemp = gr`i'enrethnic if ethnicity == 3

  gen gr`i'filipinoenrtemp = 0 //generate a temp var for total enrollment of Filipinos in grade i
  replace gr`i'filipinoenrtemp = gr`i'enrethnic if ethnicity == 4

  gen gr`i'hispanicenrtemp = 0 //generate a temp var for total enrollment of Hispanics in grade i
  replace gr`i'hispanicenrtemp = gr`i'enrethnic if ethnicity == 5

  gen gr`i'blackenrtemp = 0 //generate a temp var for total enrollment of African Americans in grade i
  replace gr`i'blackenrtemp = gr`i'enrethnic if ethnicity == 6

  gen gr`i'whiteenrtemp = 0 //generate a temp var for total enrollment of whites in grade i
  replace gr`i'whiteenrtemp = gr`i'enrethnic if ethnicity == 7

  gen gr`i'mixedenrtemp = 0 //generate a temp var for total enrollment of two or more races (not hispanic) ion grade i
  replace gr`i'mixedenrtemp = gr`i'enrethnic if ethnicity == 8

  bysort cdscode: egen gr`i'noethnicenr = max(gr`i'noethnicenrtemp) //generate a var for enrollment of unreported ethnicity in grade i for each school by populating 0 entries in the temp var of no ethnicity enrollment above
  bysort cdscode: egen gr`i'nativeenr = max(gr`i'nativeenrtemp) //generate a var for enrollment of native americans in grade i for each school by populating 0 entries in the temp var of native american enrollment above
  bysort cdscode: egen gr`i'asianenr = max(gr`i'asianenrtemp) //generate a var for enrollment of Asians in grade i for each school
  bysort cdscode: egen gr`i'pacificenr = max(gr`i'pacificenrtemp) //generate a var for enrollment of Pacific Islanders in grade i for each school
  bysort cdscode: egen gr`i'filipinoenr = max( gr`i'filipinoenrtemp) //generate a var for enrollment of Filipinos in grade i for each school
  bysort cdscode: egen gr`i'hispanicenr = max(gr`i'hispanicenrtemp) //generate a var for enrollment of Hispanics in grade i for each school
  bysort cdscode: egen gr`i'blackenr = max(gr`i'blackenrtemp) //generate a var for enrollment of African Americans in grade i for each school
  bysort cdscode: egen gr`i'whiteenr = max(gr`i'whiteenrtemp) //generate a var for enrollment of Whites in grade i for each school
  bysort cdscode: egen gr`i'mixedenr = max(gr`i'mixedenrtemp) //generate a var for enrollment of students of two or more races (not Hispanic) in grade i for each school


  label var gr`i'noethnicenr "total enrollment of unreported ethnicity in grade `i'"
  label var gr`i'nativeenr "total enrollment of Native American in grade `i'"
  label var gr`i'asianenr "total enrollment of Asians in grade `i'"
  label var gr`i'pacificenr "total enrollment of Pacific Islanders in grade `i'"
  label var gr`i'filipinoenr "total enrollment of Filipinos in grade `i'"
  label var gr`i'hispanicenr "total enrollment of Hispanics in grade `i'"
  label var gr`i'blackenr "total enrollment of African Americans in grade `i'"
  label var gr`i'whiteenr "total enrollment of Whites in grade `i'"
  label var gr`i'mixedenr "total enrollment of students of two or more races (not Hispanic) in grade `i'"

}


//grop vars not needed for collapsing dataset
drop county district school ethnicity gender kdgtnenrl ///
gr1enrl gr2enrl gr3enrl gr4enrl gr5enrl gr6enrl gr7enrl gr8enrl ungrelemenrl gr9enrl gr10enrl gr11enrl gr12enrl ungrsecenrl totalenrl adult female ///
gr1enrsex gr1femaleenrtemp gr1maleenrtemp ///
gr2enrsex gr2femaleenrtemp gr2maleenrtemp ///
gr3enrsex gr3femaleenrtemp gr3maleenrtemp ///
gr4enrsex gr4femaleenrtemp gr4maleenrtemp ///
gr5enrsex gr5femaleenrtemp gr5maleenrtemp ///
gr6enrsex gr6femaleenrtemp gr6maleenrtemp ///
gr7enrsex gr7femaleenrtemp gr7maleenrtemp ///
gr8enrsex gr8femaleenrtemp gr8maleenrtemp ///
gr9enrsex gr9femaleenrtemp gr9maleenrtemp ///
gr10enrsex gr10femaleenrtemp gr10maleenrtemp ///
gr11enrsex gr11femaleenrtemp gr11maleenrtemp ///
gr12enrsex gr12femaleenrtemp gr12maleenrtemp ///
gr1enrethnic gr1noethnicenrtemp gr1nativeenrtemp gr1asianenrtemp gr1pacificenrtemp gr1filipinoenrtemp gr1hispanicenrtemp gr1blackenrtemp gr1whiteenrtemp gr1mixedenrtemp ///
gr2enrethnic gr2noethnicenrtemp gr2nativeenrtemp gr2asianenrtemp gr2pacificenrtemp gr2filipinoenrtemp gr2hispanicenrtemp gr2blackenrtemp gr2whiteenrtemp gr2mixedenrtemp ///
gr3enrethnic gr3noethnicenrtemp gr3nativeenrtemp gr3asianenrtemp gr3pacificenrtemp gr3filipinoenrtemp gr3hispanicenrtemp gr3blackenrtemp gr3whiteenrtemp gr3mixedenrtemp ///
gr4enrethnic gr4noethnicenrtemp gr4nativeenrtemp gr4asianenrtemp gr4pacificenrtemp gr4filipinoenrtemp gr4hispanicenrtemp gr4blackenrtemp gr4whiteenrtemp gr4mixedenrtemp ///
gr5enrethnic gr5noethnicenrtemp gr5nativeenrtemp gr5asianenrtemp gr5pacificenrtemp gr5filipinoenrtemp gr5hispanicenrtemp gr5blackenrtemp gr5whiteenrtemp gr5mixedenrtemp ///
gr6enrethnic gr6noethnicenrtemp gr6nativeenrtemp gr6asianenrtemp gr6pacificenrtemp gr6filipinoenrtemp gr6hispanicenrtemp gr6blackenrtemp gr6whiteenrtemp gr6mixedenrtemp ///
gr7enrethnic gr7noethnicenrtemp gr7nativeenrtemp gr7asianenrtemp gr7pacificenrtemp gr7filipinoenrtemp gr7hispanicenrtemp gr7blackenrtemp gr7whiteenrtemp gr7mixedenrtemp ///
gr8enrethnic gr8noethnicenrtemp gr8nativeenrtemp gr8asianenrtemp gr8pacificenrtemp gr8filipinoenrtemp gr8hispanicenrtemp gr8blackenrtemp gr8whiteenrtemp gr8mixedenrtemp ///
gr9enrethnic gr9noethnicenrtemp gr9nativeenrtemp gr9asianenrtemp gr9pacificenrtemp gr9filipinoenrtemp gr9hispanicenrtemp gr9blackenrtemp gr9whiteenrtemp gr9mixedenrtemp ///
gr10enrethnic gr10noethnicenrtemp gr10nativeenrtemp gr10asianenrtemp gr10pacificenrtemp gr10filipinoenrtemp gr10hispanicenrtemp gr10blackenrtemp gr10whiteenrtemp gr10mixedenrtemp ///
gr11enrethnic gr11noethnicenrtemp gr11nativeenrtemp gr11asianenrtemp gr11pacificenrtemp gr11filipinoenrtemp gr11hispanicenrtemp gr11blackenrtemp gr11whiteenrtemp gr11mixedenrtemp ///
gr12enrethnic gr12noethnicenrtemp gr12nativeenrtemp gr12asianenrtemp gr12pacificenrtemp gr12filipinoenrtemp gr12hispanicenrtemp gr12blackenrtemp gr12whiteenrtemp gr12mixedenrtemp

/* This block of code copies each variable label to a local macro for every variable in the dataset */
foreach v of var * {
  local l`v' : variable label `v'
      if `"`l`v''"' == "" {
	local l`v' "`v'"
	}
 }


ds cdscode, not //list all variables except for cdscode so that I can call local macro r(varlist) in the following collapse command

collapse (mean) `r(varlist)', by(cdscode) //collapse all variables listed above in the dataset to get school level enrollment numbers

/* This block of code relabels the variables using the previous local macro that holds the variable labels*/
foreach v of var * {
	label var `v' "`l`v''"
 }

// generate vars for total female and male enrollment in the school
gen femaleenrtotal = 0
foreach i of local grades {
  replace femaleenrtotal = femaleenrtotal + gr`i'femaleenr
}

gen maleenrtotal = 0
foreach i of local grades {
  replace maleenrtotal = maleenrtotal + gr`i'maleenr
}

label var femaleenrtotal "total female enrollment from grade 1 to 12"
label var maleenrtotal "total male enrollment from grade 1 to 12"


//generate vars for total black, white, and hispanic enrollment in the school
gen blackenrtotal = 0
foreach i of local grades {
  replace blackenrtotal = blackenrtotal + gr`i'blackenr
}

gen whiteenrtotal = 0
foreach i of local grades {
  replace whiteenrtotal = whiteenrtotal + gr`i'whiteenr
}

gen hispanicenrtotal = 0
foreach i of local grades {
  replace hispanicenrtotal = hispanicenrtotal + gr`i'hispanicenr
}

label var blackenrtotal "total black enrollment from grade 1 to 12"
label var whiteenrtotal "total white enrollment from grade 1 to 12"
label var hispanicenrtotal "total hispanic enrollment from grade 1 to 12"



compress //compress dataset to save space
save $datadir_clean/enrollment/schoollevel/`enrdata', replace

}

/* set trace off //turn off trace to end debugging */

/* if enrollment for ethnicity and sex combination is desired: new var gradexasianfemale = gradex if female and asian */

log close enrollmentclean
translate $logdir/data_prep/prepare/enrollmentclean.smcl $logdir/data_prep/prepare/enrollmentclean.log, replace 
