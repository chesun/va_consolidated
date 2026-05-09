********************************************************************************
/* exploratory factor analysis for merge dataset with all 3 survey qoi means */
********************************************************************************
********************************************************************************
*************** written by Che Sun. Email: ucsun@ucdavis.edu *******************
********************************************************************************
cap log close _all
clear all
set more off

log using $projdir/log/share/factoranalysis/allsvyfactor.smcl, replace

/* use principal factoring method because data is not multinormal */
// estout with factor: http://repec.org/bocode/e/estout/advanced.html#advanced404

use $projdir/dta/allsvyfactor/allsvyqoimeans, clear

factor *mean_pooled
esttab e(L) using $projdir/out/csv/factoranalysis/allsvy/allsvyfactor.csv, nogap noobs nonumber nomtitle replace //export factor loadings table for all factors
screeplot, yline(1)
graph export $projdir/out/graph/factoranalysis/allsvy/allsvyscreeplot.png, replace
//set minimum eigenvalue to 1
factor *mean_pooled, mineigen(1) //6 factors with eigenvalue above 1
esttab using $projdir/out/csv/factoranalysis/allsvy/allsvyfactoreigen1.csv, cells("L[1](t label(Factor 1)) L[2](t label(Factor 2)) L[3](t label(Factor 3)) L[4](t label(Factor 4)) L[5](t label(Factor 5)) L[6](t label(Factor 6)) Psi[Uniqueness]") nogap noobs nonumber nomtitle replace


log close
translate $projdir/log/share/factoranalysis/allsvyfactor.smcl $projdir/log/share/factoranalysis/allsvyfactor.log, replace 
