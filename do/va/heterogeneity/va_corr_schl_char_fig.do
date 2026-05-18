/*------------------------------------------------------------------------------
do/va/heterogeneity/va_corr_schl_char_fig.do — Phase 1a §3.3 step 4 relocation
================================================================================

PURPOSE
    Build paper-shipping figures of VA distribution by school characteristics (scatter against continuous chars; density plots over locale + charter status).  Reads `va_all_schl_char.dta` (merged dataset built by va_het.do).

INVOKED FROM
    `do/main.do' Phase 3 (run_va_estimation block); after batch 3c1 utilities
    (which produce the merged va_<outcome>_all.dta dataset this batch consumes).

INPUTS (verified via grep)
    CANONICAL:
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_all.dta — from merge_va_est.do (batch 3c1)
      $estimates_dir/va_cfr_all_v[12]/va_est_dta/va_all_schl_char.dta — from this batch's va_het.do (output -> input chain)
    LEGACY (Step 9 deferred CDE data):
      $vaprojdir/data/sch_char.dta — school characteristics 1999-current panel
      $vaprojdir/data/sch_char_2018.dta — 2018 snapshot for cross-section regressions

OUTPUTS (CANONICAL per ADR-0021 sandbox; verified via grep on the file body)
    $figures_dir/va_cfr_all_v[12]/va_het/va_<outcome>_{scatter_<het_char>,density_locale,density_charter}_<sample>_sp_<va_ctrl>_ct[_p].pdf
    $logdir/va/heterogeneity/va_corr_schl_char_fig.smcl + .log

RELOCATION (per plan v3 §3.3 step 4, applied 2026-05-08)
    Source: cde_va_project_fork/do_files/va_het/va_corr_schl_char_fig.do
    Path repointing applied via script-based sed pass:
      $vaprojdir/log_files/va_het/<x> -> $logdir/<x>
      $vaprojdir/estimates/<x> -> $estimates_dir/<x>
      $vaprojdir/tables/<x> -> $tables_dir/<x>
      $vaprojdir/figures/<x> -> $figures_dir/<x>
      $vaprojdir/do_files/sbac/macros_va*.doh -> $consolidated_dir/do/va/helpers/<x> (absolute per batch 2c)
      $vaprojdir/data/sch_char[_2018].dta KEPT LEGACY (Step 9 CDE data deferred)

ADRs: 0004 (canonical pipeline), 0009 (v1 canonical), 0021 (sandbox; description convention)
ORIGINAL CHANGE LOG preserved verbatim below.
------------------------------------------------------------------------------*/


/* create figures for correlation of VA with school characteristics:
- charter status: charter
- pct econ disadvantage: prop_ecn_disadv
- pct black/hispanic: enr_black_hisp_prop
- urban/rural status: locale_coarse

For categorical variables: kernel density plot
For continuous variables: scatter plot
 */

/* To run this do file, execute:
do $vaprojdir/do_files/va_het/va_corr_schl_char_fig.do
 */


/*  CHANGE LOG:
1/17/2024: only use 2019 school chars 
*/

* --- output-directory prep (CANONICAL) ---------------------------------------
cap mkdir "$figures_dir"
cap mkdir "$figures_dir/va_cfr_all_v1"
cap mkdir "$figures_dir/va_cfr_all_v1/va_het"
cap mkdir "$figures_dir/va_cfr_all_v2"
cap mkdir "$figures_dir/va_cfr_all_v2/va_het"
cap mkdir "$logdir"


cap mkdir "$logdir/va"
cap mkdir "$logdir/va/heterogeneity"
cd $vaprojdir

log close _all

log using "$logdir/va/heterogeneity/va_corr_schl_char_fig.smcl", replace text

di as text _n "{hline 80}"
di as text "va_corr_schl_char_fig.do — RUN START: `c(current_date)' `c(current_time)'"
di as text "{hline 80}"
 

graph drop _all
set more off
set varabbrev off
set graphics off
set scheme s1color
set seed 1984


local date1 = c(current_date)
local time1 = c(current_time)

// include project macros
include $consolidated_dir/do/va/helpers/macros_va.doh
include $consolidated_dir/do/va/helpers/macros_va_all_samples_controls.doh

local factor_het_char charter locale_coarse
local cont_het_char prop_ecn_disadv enr_black_hisp_prop

local b_sample_controls b 
local las_sample_controls las 

foreach version in v1 v2 {
    di "VA version: `version'"

    use $estimates_dir/va_cfr_all_`version'/va_est_dta/va_all.dta, clear 
    merge m:1 cdscode using $vaprojdir/data/sch_char_2018.dta, nogen keep(1 3)



    foreach va_outcome in ela math enr enr_2year enr_4year {
        di "VA outcome: `va_outcome'"

        foreach sample in b las {
            di "VA sample: `sample'"

            if "`sample'" == "las" {
                local peer _p
                local peer_yn "Y"
            } 
            else {
                local peer
                local peer_yn "N"
            }
            foreach va_ctrl of local `sample'_sample_controls {
                di "VA controls: `va_ctrl'"

                /* correlation between VA and continuous school chars */
                foreach het_char of local cont_het_char {
                    corr va_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer' `het_char'
                    local cor_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer': di %5.3f r(rho)
                    /* scatter plot */
                    binscatter va_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer' `het_char' ///
                        , ytitle("``va_outcome'_str' VA") xtitle("``het_char'_str'") ///
                        yline(0) xline(0) ///
                        note("Correlation Coefficient: `cor_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer''")
                    graph export $figures_dir/va_cfr_all_`version'/va_het/va_`va_outcome'_scatter_`het_char'_`sample'_sp_`va_ctrl'_ct`peer'.pdf, replace

                }


                /* kernel density for VA by categorical school chars */

                // locale
                twoway ///
                    (kdensity va_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer' if locale_coarse == 1) ///
                    (kdensity va_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer' if locale_coarse == 2, lpattern(dash)) ///
                    (kdensity va_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer' if locale_coarse == 3, lpattern("-..")) ///
                    (kdensity va_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer' if locale_coarse == 4, lpattern(shortdash)) ///
                    , xtitle("``va_outcome'_str' VA") ///
                    title("Kernel Density by Locale") ///
                    legend(label(1 "City") label(2 "Suburban") label(3 "Town") label(4 "Rural"))
                    
                graph export $figures_dir/va_cfr_all_`version'/va_het/va_`va_outcome'_density_locale_`sample'_sp_`va_ctrl'_ct`peer'.pdf, replace

                // charter
                twoway ///
                    (kdensity va_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer' if charter == 0) ///
                    (kdensity va_`va_outcome'_`sample'_sp_`va_ctrl'_ct`peer' if charter == 1, lpattern("-..")) ///
                    , ytitle("``va_outcome'_str' VA") ///
                    title("Kernel Density by Charter Status") ///
                    legend(label(1 "Non-Charter") label(2 "Charter"))

                graph export $figures_dir/va_cfr_all_`version'/va_het/va_`va_outcome'_density_charter_`sample'_sp_`va_ctrl'_ct`peer'.pdf, replace

                }

            }
        }
    }











local date2 = c(current_date)
local time2 = c(current_time)

di "do file start time: `date1' `time1' "
di "do file end time: `date2' `time2' "

cap log close
cap translate "$logdir/va/heterogeneity/va_corr_schl_char_fig.smcl" ///
    "$logdir/va/heterogeneity/va_corr_schl_char_fig.log", replace

* Restore CWD to $consolidated_dir for subsequent main.do invocations.
cd "$consolidated_dir"

* end of file
