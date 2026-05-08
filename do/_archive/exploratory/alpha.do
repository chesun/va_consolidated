version 16.0
********************************************************************************
/* Cronbach's alpha test for survey qois */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************

/* To run this do file

do $projdir/do/share/factoranalysis/alpha

*/

/* CHANGE LOG
6/5/2022: Added code to write alpha output to excel
*/

cap log close _all
clear all
set more off
graph drop _all

/* set trace on */

log using $projdir/log/share/factoranalysis/alpha.smcl, replace

/* Alpha for surveys  */

/* secondary */
use $projdir/dta/buildanalysisdata/analysisready/secanalysisready, clear

/* std: standardize items in the scale to mean 0, variance 1
item: display item-test and item-rest correlations*/
alpha *mean_pooled, std item

putexcel set $projdir/out/csv/factoranalysis/alpha.xlsx, sheet("alpha_sec", replace) replace

putexcel A1 = ("Secondary Survey QOI") A2 = ("Cronbach's Alpha") B2 = (r(alpha))
putexcel A4=("Item") B4=("Item Test Correlation") C4=("Item Rest Correlation") ///
  D4=("Inter-Item Correlation") E4=("Alpha Excluding Item")

//transpose the return matrices
matrix item_test = r(ItemTestCorr)'
matrix item_rest = r(ItemRestCorr)'
matrix inter_item = r(MeanInterItemCorr)'
matrix alpha_ex_item = r(Alpha)'

putexcel A5=matrix(item_test) ///
  , rownames
putexcel C5=matrix(item_rest) ///
  D5=matrix(inter_item) ///
  E5=matrix(alpha_ex_item)

clear matrix

putexcel save

/* parent */
use $projdir/dta/buildanalysisdata/analysisready/parentanalysisready, clear
alpha *mean_pooled, std item

// use the open option so that stata writes to working memory, otherwise there are problems with changes not saving 
putexcel set $projdir/out/csv/factoranalysis/alpha.xlsx, sheet("alpha_parent", replace) modify open

putexcel A1 = ("Parent Survey QOI") A2 = ("Cronbach's Alpha") B2= (r(alpha))
putexcel A4=("Item") B4=("Item Test Correlation") C4=("Item Rest Correlation") ///
  D4=("Inter-Item Correlation") E4=("Alpha Excluding Item")

//transpose the return matrices
matrix item_test = r(ItemTestCorr)'
matrix item_rest = r(ItemRestCorr)'
matrix inter_item = r(MeanInterItemCorr)'
matrix alpha_ex_item = r(Alpha)'

putexcel A5=matrix(item_test) ///
  , rownames
putexcel C5=matrix(item_rest) ///
  D5=matrix(inter_item) ///
  E5=matrix(alpha_ex_item)

clear matrix

putexcel save


/* staff */
use $projdir/dta/buildanalysisdata/analysisready/staffanalysisready, clear
alpha *mean_pooled, std item

putexcel set $projdir/out/csv/factoranalysis/alpha.xlsx, sheet("alpha_staff", replace) modify open

putexcel A1 = ("Staff Survey QOI") A2 = ("Cronbach's Alpha") B2 = (r(alpha))
putexcel A4=("Item") B4=("Item Test Correlation") C4=("Item Rest Correlation") ///
  D4=("Inter-Item Correlation") E4=("Alpha Excluding Item")

//transpose the return matrices
matrix item_test = r(ItemTestCorr)'
matrix item_rest = r(ItemRestCorr)'
matrix inter_item = r(MeanInterItemCorr)'
matrix alpha_ex_item = r(Alpha)'

putexcel A5=matrix(item_test) ///
  , rownames
putexcel C5=matrix(item_rest) ///
  D5=matrix(inter_item) ///
  E5=matrix(alpha_ex_item)

clear matrix

putexcel save

/* Alpha for question classifications  */
use $projdir/dta/allsvyfactor/allsvyqoimeans, clear

//School Climate
alpha parentqoi9mean_pooled parentqoi16mean_pooled parentqoi17mean_pooled parentqoi27mean_pooled secqoi22mean_pooled secqoi23mean_pooled secqoi24mean_pooled secqoi25mean_pooled secqoi26mean_pooled secqoi27mean_pooled secqoi28mean_pooled secqoi29mean_pooled secqoi30mean_pooled staffqoi20mean_pooled staffqoi24mean_pooled staffqoi41mean_pooled staffqoi44mean_pooled staffqoi64mean_pooled staffqoi87mean_pooled staffqoi98mean_pooled, std item

putexcel set $projdir/out/csv/factoranalysis/alpha.xlsx, sheet("alpha_school_climate", replace) modify open

putexcel A1 = ("School Climate Questions") A2 = ("Cronbach's Alpha") B2 = (r(alpha))
putexcel A4=("Item") B4=("Item Test Correlation") C4=("Item Rest Correlation") ///
  D4=("Inter-Item Correlation") E4=("Alpha Excluding Item")

//transpose the return matrices
matrix item_test = r(ItemTestCorr)'
matrix item_rest = r(ItemRestCorr)'
matrix inter_item = r(MeanInterItemCorr)'
matrix alpha_ex_item = r(Alpha)'

putexcel A5=matrix(item_test) ///
  , rownames
putexcel C5=matrix(item_rest) ///
  D5=matrix(inter_item) ///
  E5=matrix(alpha_ex_item)

clear matrix

putexcel save

//Teacher and Staff Quality
alpha parentqoi30mean_pooled parentqoi31mean_pooled parentqoi32mean_pooled parentqoi33mean_pooled parentqoi34mean_pooled secqoi35mean_pooled secqoi36mean_pooled secqoi37mean_pooled secqoi38mean_pooled secqoi39mean_pooled secqoi40mean_pooled staffqoi103mean_pooled staffqoi104mean_pooled staffqoi105mean_pooled staffqoi109mean_pooled staffqoi111mean_pooled staffqoi112mean_pooled, std item

putexcel set $projdir/out/csv/factoranalysis/alpha.xlsx, sheet("alpha_teacher_quality", replace) modify open

putexcel A1 = ("Teacher and Staff Quality Questions") A2 = ("Cronbach's Alpha") B2 = (r(alpha))
putexcel A4=("Item") B4=("Item Test Correlation") C4=("Item Rest Correlation") ///
  D4=("Inter-Item Correlation") E4=("Alpha Excluding Item")

//transpose the return matrices
matrix item_test = r(ItemTestCorr)'
matrix item_rest = r(ItemRestCorr)'
matrix inter_item = r(MeanInterItemCorr)'
matrix alpha_ex_item = r(Alpha)'

putexcel A5=matrix(item_test) ///
  , rownames
putexcel C5=matrix(item_rest) ///
  D5=matrix(inter_item) ///
  E5=matrix(alpha_ex_item)

clear matrix

putexcel save

//Support for Students
alpha parentqoi15mean_pooled parentqoi64mean_pooled staffqoi10mean_pooled staffqoi128mean_pooled, std item

putexcel set $projdir/out/csv/factoranalysis/alpha.xlsx, sheet("alpha_student_support", replace) modify open

putexcel A1 = ("Student Support Questions") A2 = ("Cronbach's Alpha") B2 = (r(alpha))
putexcel A4=("Item") B4=("Item Test Correlation") C4=("Item Rest Correlation") ///
  D4=("Inter-Item Correlation") E4=("Alpha Excluding Item")

//transpose the return matrices
matrix item_test = r(ItemTestCorr)'
matrix item_rest = r(ItemRestCorr)'
matrix inter_item = r(MeanInterItemCorr)'
matrix alpha_ex_item = r(Alpha)'

putexcel A5=matrix(item_test) ///
  , rownames
putexcel C5=matrix(item_rest) ///
  D5=matrix(inter_item) ///
  E5=matrix(alpha_ex_item)

clear matrix

putexcel save

//Student Motivation
alpha secqoi31mean_pooled secqoi32mean_pooled secqoi33mean_pooled secqoi34mean_pooled, std item

putexcel set $projdir/out/csv/factoranalysis/alpha.xlsx, sheet("alpha_student_motivation", replace) modify open

putexcel A1 = ("Student Motivation Questions") A2 = ("Cronbach's Alpha") B2 = (r(alpha))
putexcel A4=("Item") B4=("Item Test Correlation") C4=("Item Rest Correlation") ///
  D4=("Inter-Item Correlation") E4=("Alpha Excluding Item")

//transpose the return matrices
matrix item_test = r(ItemTestCorr)'
matrix item_rest = r(ItemRestCorr)'
matrix inter_item = r(MeanInterItemCorr)'
matrix alpha_ex_item = r(Alpha)'

putexcel A5=matrix(item_test) ///
  , rownames
putexcel C5=matrix(item_rest) ///
  D5=matrix(inter_item) ///
  E5=matrix(alpha_ex_item)

clear matrix


putexcel save
putexcel clear


set trace off


log close
translate $projdir/log/share/factoranalysis/alpha.smcl $projdir/log/share/factoranalysis/alpha.log, replace
