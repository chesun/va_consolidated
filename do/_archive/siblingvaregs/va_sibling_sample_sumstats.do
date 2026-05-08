********************************************************************************
/* do file to create sum stats for the test score VA sibling samples */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************** First written on Sep 22, 2021 ***************************

/* To run this do file:
do $projdir/do/share/siblingvaregs/va_sibling_sample_sumstats
 */

clear all
set more off
set varabbrev off
//capture log close: Stata should not complain if there is no log open to close
cap log close _all

/* file path macros  */
include $projdir/do/share/siblingvaregs/vafilemacros.doh

//change directory to matt directory to reconcile the use of directories in his doh and do file
cd `vaprojdir'

//starting log file
log using $projdir/log/share/siblingvaregs/va_sibling_sample_sumstats.smcl, replace

//run the do helper file to set the local macros
include `vaprojdofiles'/sbac/macros_va.doh

#delimit ;
#delimit cr
macro list


timer on 1

********************************************************************************
/* Add family fixed effects as an additional demographic control in SBAC
VA estimation */

//load the VA grade 11 sample
use `va_g11_dataset', clear

//merge on to ufamilyxwalk in order to use unique family ID for FE
merge m:1 state_student_id using `sibling_out_xwalk'
drop _merge


compress
tempfile va_g11_sibling_dataset
save `va_g11_sibling_dataset'




//check the average distance between siblings
//in the full sibling sample
use $projdir/dta/siblingxwalk/uniquesiblingpairxwalk, clear

//collapse to family level to only keep the average birth date distance in family
collapse (mean) avg_birth_date_distance_family, by(ufamilyid)

sum avg_birth_date_distance_family

//in the sibling test score VA sample
//merge average sibling birth date distance in family to test score VA sibling dataset

merge 1:m ufamilyid using `va_g11_sibling_dataset'

sum avg_birth_date_distance_family ///
if grade == 11 & touse_g11_ela==1 & sibling_full_sample == 1

sum avg_birth_date_distance_family ///
if grade == 11 & touse_g11_math==1 & sibling_full_sample == 1




use `va_g11_sibling_dataset', clear
//check the number of families in this sample
di "number of families in the full sibling sample matched to the g11 va sample"

di "ELA"
egen family_temp = group(ufamilyid) ///
if grade == 11 & touse_g11_ela==1 & sibling_full_sample == 1
sum family_temp
drop family_temp

di "Math"
egen family_temp = group(ufamilyid) ///
if grade == 11 & touse_g11_math==1 & sibling_full_sample == 1
sum family_temp
drop family_temp

di "number of families in the sibling outcome sample matched to the g11 va sample"
di "(have at least one older sibling matched to postsecondary outcomes)"

di "ELA"
egen family_temp = group(ufamilyid) ///
if grade == 11 & touse_g11_ela==1 & sibling_out_sample == 1
sum family_temp
drop family_temp

di "Math"
egen family_temp = group(ufamilyid) ///
if grade == 11 & touse_g11_math==1 & sibling_out_sample == 1
sum family_temp
drop family_temp


//check the number of obs by year
tab year if grade == 11 & touse_g11_ela==1 & sibling_full_sample == 1

tab year if grade == 11 & touse_g11_math==1 & sibling_full_sample == 1








timer off 1
timer list 
log close
translate $projdir/log/share/siblingvaregs/va_sibling_sample_sumstats.smcl ///
$projdir/log/share/siblingvaregs/va_sibling_sample_sumstats.log, replace
